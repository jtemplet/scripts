#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# approve-bead.sh — Human final-review and merge for a pipeline bead
# ═══════════════════════════════════════════════════════════════════════════════
#
# Run this AFTER you have manually reviewed the code and are satisfied.
# It does the merge, cleans up the worktree, and closes the bead.
#
# USAGE:
#   cd /path/to/repo
#   bash scripts/approve-bead.sh bd-abc123
#
#   --dry-run     Show what would happen without doing it
#
# WHAT THIS DOES (in order):
#   1. Shows you the diff one more time (so it's fresh in your mind)
#   2. Merges the feature branch into main
#   3. Pushes main
#   4. Removes the git worktree
#   5. Deletes the feature branch (local + remote)
#   6. Removes the "ready_for_review" label, closes the bead
#   7. Refreshes the bd export (.beads/issues.jsonl)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Args ────────────────────────────────────────────────────────────────────
BEAD_ID="${1:?Usage: approve-bead.sh <bead-id> [--dry-run]}"
DRY_RUN=false
if [[ "${2:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-.}"
WORKTREE_DIR="${REPO_ROOT}/worktrees"
# ─────────────────────────────────────────────────────────────────────────────

# ─── Helpers ─────────────────────────────────────────────────────────────────
slugify() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-//; s/-$//'
}

run() {
    if [[ "$DRY_RUN" == true ]]; then
        printf '  [DRY-RUN] %s\n' "$*"
    else
        printf '  ▶ %s\n' "$*"
        eval "$@"
    fi
}
# ─────────────────────────────────────────────────────────────────────────────

cd "$REPO_ROOT"

# ─── Validate ────────────────────────────────────────────────────────────────
command -v bd >/dev/null 2>&1 || { echo "ERROR: bd not in PATH"; exit 1; }

BEAD_INFO=$(bd show "$BEAD_ID" --json 2>/dev/null) || {
    echo "ERROR: Bead $BEAD_ID not found."
    exit 1
}

TITLE=$(printf '%s' "$BEAD_INFO" | jq -r '(.[0].title // .title)')
LABELS=$(printf '%s' "$BEAD_INFO" | jq -r '((.[0].labels // .labels) // []) | .[]')
BRANCH="feature/${BEAD_ID}-$(slugify "$TITLE")"
WORKTREE="${WORKTREE_DIR}/${BEAD_ID}"

# Check that this bead is actually in "ready_for_review"
if ! printf '%s' "$LABELS" | grep -qx "ready_for_review"; then
    echo "ERROR: Bead $BEAD_ID does not have the 'ready_for_review' label."
    echo "Labels: $(printf '%s' "$BEAD_INFO" | jq -c '(.[0].labels // .labels)')"
    echo "Only run this on beads that have completed QA."
    exit 1
fi

# Check worktree exists
if [[ ! -d "$WORKTREE" ]]; then
    echo "ERROR: Worktree not found at $WORKTREE"
    exit 1
fi

# ─── Show the diff ───────────────────────────────────────────────────────────
printf '\n══════════════════════════════════════════════════════════\n'
printf '  Approving: %s — %s\n' "$BEAD_ID" "$TITLE"
printf '  Branch:    %s\n' "$BRANCH"
printf '══════════════════════════════════════════════════════════\n\n'

printf '── Diff (main..%s) ──────────────────────────────────\n' "$BRANCH"
git diff main..."$BRANCH" || true
printf '\n'

if [[ "$DRY_RUN" == true ]]; then
    printf '── DRY-RUN: Nothing will be changed. Here is what would happen:\n\n'
fi

# ─── Merge, clean up, close ──────────────────────────────────────────────────
run "git checkout main"
run "git merge --no-ff '$BRANCH' -m 'merge($BEAD_ID): $TITLE'"
run "git push origin main"
run "git worktree remove '$WORKTREE' --force"
run "git branch -D '$BRANCH'"
run "git push origin --delete '$BRANCH'"
run "bd update $BEAD_ID --remove-label ready_for_review"
run "bd close $BEAD_ID"
run "bd export -o .beads/issues.jsonl"

if [[ "$DRY_RUN" == false ]]; then
    printf '\n✅ %s merged, worktree removed, bead closed.\n' "$BEAD_ID"
fi
