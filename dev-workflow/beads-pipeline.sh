#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# BEADS PIPELINE — Multi-Agent Workflow Orchestrator for beads_rust (br)
# ═══════════════════════════════════════════════════════════════════════════════
#
# WHY LABELS, NOT CUSTOM STATUSES:
#   bd only supports 5 statuses: open | in_progress | blocked | deferred | closed
#   We encode the pipeline stage in LABELS. The bd status tracks coarse state;
#   the label tracks where in the pipeline the bead actually is.
#
# WORKFLOW & LABEL STATE MACHINE:
#
#   ┌─────────┐   ┌─────────┐   ┌────────────────────┐   ┌──────────────┐   ┌───────┐   ┌──────────────────┐   ┌────────┐
#   │  open   │──▶│ coding  │──▶│ready_for_code_review│──▶│in_code_review│──▶│ready_ │──▶│   in_qa          │──▶│ready_  │
#   │(no label│   │ (label) │   │     (label)         │   │   (label)    │   │for_qa │   │   (label)        │   │for_    │
#   │ picked) │   │         │   │                     │   │              │   │(label)│   │                  │   │review) │
#   └─────────┘   └─────────┘   └────────────────────┘   └──────────────┘   └───────┘   └──────────────────┘   └────────┘
#        │              │                   │                     │               │                │                   │
#   pipeline       agent working      pipeline             agent working    pipeline       agent working        HUMAN
#   dispatches     (ignored)          dispatches           (ignored)        dispatches     (ignored)            approves
#   coding agent                      review agent                          QA agent                            → closed
#
#   bd status:  open ──────▶ in_progress ──────────────────────────────────────────────────────────────────▶ closed
#
# TRANSITIONS MADE BY AGENTS (at the end of their work):
#   Coding agent:  removes "coding",            adds "ready_for_code_review"
#   Review agent:  removes "in_code_review",    adds "ready_for_qa"
#   QA agent:      removes "in_qa",             adds "ready_for_review"
#
# TRANSITIONS MADE BY ORCHESTRATOR (on detection):
#   Sees open bead w/o labels:           sets in_progress, adds "coding",          dispatches coder
#   Sees "ready_for_code_review":        removes it,        adds "in_code_review", dispatches reviewer
#   Sees "ready_for_qa":                 removes it,        adds "in_qa",          dispatches QA
#
# HUMAN STEP (not automated):
#   Sees "ready_for_review" → runs approve-bead.sh → merges, removes worktree, closes bead
#
# ═══════════════════════════════════════════════════════════════════════════════
#
# USAGE:
#   export REPO_ROOT=/path/to/health-data-warehouse
#   export AGENT=claude_code          # or: gemini
#   bash scripts/beads-pipeline.sh
#
# ENVIRONMENT VARIABLES:
#   REPO_ROOT         Path to your git repo root (default: .)
#   AGENT             claude_code | gemini (default: claude_code)
#   POLL_INTERVAL     Seconds between polls (default: 5)
#   MAX_CONCURRENT    Max agents running simultaneously (default: 3)
#   AGENT_TIMEOUT     Minutes before a stuck agent is killed (default: 180 = 3hr)
#   PROMPT_DIR        Path to prompt templates (default: same dir as this script /prompts/)
#
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
REPO_ROOT="${REPO_ROOT:-.}"
AGENT="${AGENT:-claude_code}"
POLL_INTERVAL="${POLL_INTERVAL:-5}"
MAX_CONCURRENT="${MAX_CONCURRENT:-3}"
AGENT_TIMEOUT="${AGENT_TIMEOUT:-180}"            # minutes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_DIR="${PROMPT_DIR:-${SCRIPT_DIR}/prompts}"
WORKTREE_DIR="${REPO_ROOT}/worktrees"
STATE_DIR="${REPO_ROOT}/.beads-pipeline"
LOG_FILE="${STATE_DIR}/pipeline.log"
PID_DIR="${STATE_DIR}/pids"
# ─────────────────────────────────────────────────────────────────────────────

mkdir -p "$STATE_DIR" "$WORKTREE_DIR" "$PID_DIR"

# ─── Logging ─────────────────────────────────────────────────────────────────
log()   { printf '[%s] %-6s %s\n' "$(date -Iseconds)" "INFO" "$*" | tee -a "$LOG_FILE"; }
warn()  { printf '[%s] %-6s %s\n' "$(date -Iseconds)" "WARN" "$*" | tee -a "$LOG_FILE" >&2; }
error() { printf '[%s] %-6s %s\n' "$(date -Iseconds)" "ERROR" "$*" | tee -a "$LOG_FILE" >&2; }
# ─────────────────────────────────────────────────────────────────────────────

# ─── Utilities ───────────────────────────────────────────────────────────────
slugify() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-//; s/-$//'
}

branch_for() {
    # Derive branch name from bead ID + title
    local bead_id=$1
    local title
    title=$(cd "$REPO_ROOT" && bd show "$bead_id" --json | jq -r '(.[0].title // .title)')
    printf 'feature/%s-%s' "$bead_id" "$(slugify "$title")"
}

worktree_for() {
    printf '%s/%s' "$WORKTREE_DIR" "$1"
}

# ─── Concurrency Tracking ────────────────────────────────────────────────────
# We write PID files when dispatching agents. On each poll we reap finished
# processes and count what's still running.
active_agents() {
    local count=0
    for pid_file in "$PID_DIR"/*; do
        [[ -f "$pid_file" ]] || continue
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            ((count++)) || true
        else
            rm -f "$pid_file"   # Reap finished agent
        fi
    done
    printf '%d' "$count"
}

# Detect agents that have been running longer than AGENT_TIMEOUT minutes
reap_stuck_agents() {
    for pid_file in "$PID_DIR"/*; do
        [[ -f "$pid_file" ]] || continue
        local pid
        pid=$(cat "$pid_file")
        kill -0 "$pid" 2>/dev/null || continue   # Already dead

        # Get file mtime as start time
        local start_time now elapsed
        start_time=$(stat -f%m "$pid_file" 2>/dev/null || stat -c%Y "$pid_file" 2>/dev/null)
        now=$(date +%s)
        elapsed=$(( (now - start_time) / 60 ))

        if [[ $elapsed -gt $AGENT_TIMEOUT ]]; then
            warn "Agent PID $pid ($(basename "$pid_file")) stuck for ${elapsed}m (limit: ${AGENT_TIMEOUT}m). Killing."
            kill -TERM "$pid" 2>/dev/null || true
            sleep 2
            kill -KILL "$pid" 2>/dev/null || true
            rm -f "$pid_file"
        fi
    done
}
# ─────────────────────────────────────────────────────────────────────────────

# ─── Prompt Rendering ────────────────────────────────────────────────────────
# Uses python3 for safe multi-line substitution (handles newlines in descriptions,
# special characters in titles, etc.)
render_prompt() {
    local template=$1
    local bead_id=$2
    local info title branch description worktree

    info=$(cd "$REPO_ROOT" && bd show "$bead_id" --json)
    title=$(printf '%s' "$info" | jq -r '(.[0].title // .title)')
    branch=$(branch_for "$bead_id")
    description=$(printf '%s' "$info" | jq -r '.description // "No description provided."')
    worktree=$(worktree_for "$bead_id")

    # Export vars for python; python does the safe string replacement
    BEAD_ID="$bead_id" \
    TITLE="$title" \
    BRANCH="$branch" \
    DESCRIPTION="$description" \
    WORKTREE="$worktree" \
    REPO_ROOT="$REPO_ROOT" \
    python3 -c "
import os, sys
t = open(sys.argv[1]).read()
for key in ('BEAD_ID','TITLE','BRANCH','DESCRIPTION','WORKTREE','REPO_ROOT'):
    t = t.replace('{' + key.lower() + '}', os.environ.get(key, ''))
sys.stdout.write(t)
" "$template"
}
# ─────────────────────────────────────────────────────────────────────────────

# ─── Agent Dispatch ──────────────────────────────────────────────────────────
# Spawns the configured agent in the background within the feature worktree.
# The agent itself is responsible for updating labels when it finishes.
dispatch() {
    local bead_id=$1
    local prompt_template=$2
    local worktree stage agent_log prompt
    worktree=$(worktree_for "$bead_id")
    stage=$(basename "$prompt_template" .txt)
    agent_log="${STATE_DIR}/${bead_id}-${stage}.log"
    prompt=$(render_prompt "$prompt_template" "$bead_id")

    log "→ Dispatching [$stage] for $bead_id"

    case "$AGENT" in
        claude_code)
            # Claude Code: pipe the prompt via stdin, --no-confirmation for non-interactive
            (cd "$worktree" && printf '%s\n' "$prompt" | claude --no-confirmation 2>&1) > "$agent_log" &
            ;;
        gemini)
            (cd "$worktree" && gemini "$prompt" 2>&1) > "$agent_log" &
            ;;
        *)
            error "Unknown AGENT: '$AGENT'. Set AGENT=claude_code or AGENT=gemini"
            return 1
            ;;
    esac

    # Track the PID
    echo $! > "${PID_DIR}/${bead_id}-${stage}"
}
# ─────────────────────────────────────────────────────────────────────────────

# ─── Stage Handlers ──────────────────────────────────────────────────────────

# STAGE 0: New bead (open, unblocked, no workflow labels) → create worktree, dispatch coder
handle_new() {
    local bead_id=$1
    local worktree branch
    worktree=$(worktree_for "$bead_id")
    branch=$(branch_for "$bead_id")

    cd "$REPO_ROOT"

    # Create worktree + branch
    if [[ ! -d "$worktree" ]]; then
        log "Creating worktree: $worktree  branch: $branch"
        if ! git worktree add "$worktree" -b "$branch" 2>/dev/null; then
            # Branch might already exist from a previous interrupted run
            git worktree add "$worktree" "$branch" 2>/dev/null || {
                error "Failed to create worktree for $bead_id"
                return 1
            }
        fi
    fi

    # Transition: open → in_progress, add "coding" label
    bd update "$bead_id" --status in_progress
    bd update "$bead_id" --add-label coding
    bd export -o .beads/issues.jsonl 2>/dev/null || true

    dispatch "$bead_id" "${PROMPT_DIR}/coding.txt"
}

# STAGE 1: "ready_for_code_review" detected → dispatch reviewer
handle_code_review() {
    local bead_id=$1
    cd "$REPO_ROOT"

    bd update "$bead_id" --remove-label ready_for_code_review
    bd update "$bead_id" --add-label in_code_review
    bd export -o .beads/issues.jsonl 2>/dev/null || true

    dispatch "$bead_id" "${PROMPT_DIR}/code_review.txt"
}

# STAGE 2: "ready_for_qa" detected → dispatch QA
handle_qa() {
    local bead_id=$1
    cd "$REPO_ROOT"

    bd update "$bead_id" --remove-label ready_for_qa
    bd update "$bead_id" --add-label in_qa
    bd export -o .beads/issues.jsonl 2>/dev/null || true

    dispatch "$bead_id" "${PROMPT_DIR}/qa.txt"
}
# ─────────────────────────────────────────────────────────────────────────────

# ─── Main Polling Loop ───────────────────────────────────────────────────────
main() {
    log "=============================================="
    log " Beads Pipeline v1.0 — Starting"
    log "=============================================="
    log " REPO_ROOT      = $REPO_ROOT"
    log " AGENT          = $AGENT"
    log " POLL_INTERVAL  = ${POLL_INTERVAL}s"
    log " MAX_CONCURRENT = $MAX_CONCURRENT"
    log " AGENT_TIMEOUT  = ${AGENT_TIMEOUT}m"
    log " PROMPT_DIR     = $PROMPT_DIR"
    log " WORKTREE_DIR   = $WORKTREE_DIR"
    log "=============================================="

    # ── Pre-flight checks ──────────────────────────────────────────────────
    command -v br     >/dev/null 2>&1 || { error "br (beads_rust) not in PATH"; exit 1; }
    command -v jq     >/dev/null 2>&1 || { error "jq not in PATH"; exit 1; }
    command -v python3>/dev/null 2>&1 || { error "python3 not in PATH"; exit 1; }
    [[ -d "$PROMPT_DIR" ]]            || { error "Prompt dir missing: $PROMPT_DIR"; exit 1; }
    [[ -f "${PROMPT_DIR}/coding.txt" ]]       || { error "Missing: ${PROMPT_DIR}/coding.txt"; exit 1; }
    [[ -f "${PROMPT_DIR}/code_review.txt" ]]  || { error "Missing: ${PROMPT_DIR}/code_review.txt"; exit 1; }
    [[ -f "${PROMPT_DIR}/qa.txt" ]]           || { error "Missing: ${PROMPT_DIR}/qa.txt"; exit 1; }
    [[ -d "$REPO_ROOT/.git" ]]        || { error "$REPO_ROOT is not a git repo"; exit 1; }
    (cd "$REPO_ROOT" && bd list --json >/dev/null 2>&1) || { error "bd is not initialized in $REPO_ROOT"; exit 1; }

    while true; do
        # Reap stuck agents first
        reap_stuck_agents

        local running
        running=$(active_agents)

        if [[ "$running" -ge "$MAX_CONCURRENT" ]]; then
            log "At concurrency limit ($running/$MAX_CONCURRENT). Waiting."
            sleep "$POLL_INTERVAL"
            continue
        fi

        cd "$REPO_ROOT"

        # ── Fetch all issues in one shot ──────────────────────────────────
        local all_issues
        all_issues=$(bd list --all --json 2>/dev/null || echo '[]')

        # ── STAGE 2: ready_for_qa (later stages get priority) ─────────────
        local qa_ids
        qa_ids=$(printf '%s' "$all_issues" | jq -r '.[] | select(.labels != null) | select(.labels | index("ready_for_qa")) | .id' 2>/dev/null || true)
        for id in $qa_ids; do
            [[ "$running" -ge "$MAX_CONCURRENT" ]] && break
            handle_qa "$id"
            ((running++)) || true
        done

        # ── STAGE 1: ready_for_code_review ─────────────────────────────────
        local review_ids
        review_ids=$(printf '%s' "$all_issues" | jq -r '.[] | select(.labels != null) | select(.labels | index("ready_for_code_review")) | .id' 2>/dev/null || true)
        for id in $review_ids; do
            [[ "$running" -ge "$MAX_CONCURRENT" ]] && break
            handle_code_review "$id"
            ((running++)) || true
        done

        # ── STAGE 0: New open beads (unblocked, no workflow labels) ─────────
        # bd ready filters for open + unblocked. We additionally filter out
        # any bead that already has a workflow label (already in the pipeline).
        local ready_ids
        ready_ids=$(bd ready --json 2>/dev/null | jq -r '
            def workflow_labels: ["coding","ready_for_code_review","in_code_review","ready_for_qa","in_qa","ready_for_review"];
            .[] |
            select(
                (.labels // []) |
                [.[] | select(IN(workflow_labels[]))] |
                length == 0
            ) | .id
        ' 2>/dev/null || true)

        for id in $ready_ids; do
            [[ "$running" -ge "$MAX_CONCURRENT" ]] && break
            handle_new "$id"
            ((running++)) || true
        done

        # ── STATUS: Log beads awaiting human review ───────────────────────
        local human_ids
        human_ids=$(printf '%s' "$all_issues" | jq -r '.[] | select(.labels != null) | select(.labels | index("ready_for_review")) | "\(.id)  \(.title)"' 2>/dev/null || true)
        if [[ -n "$human_ids" ]]; then
            log "👋 Awaiting human review:"
            while IFS= read -r line; do
                log "   $line"
            done <<< "$human_ids"
        fi

        sleep "$POLL_INTERVAL"
    done
}

main "$@"
