# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Issue Tracking

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd dolt push          # Publish issues to the remote
```

## Session Completion

**When ending a work session**, complete ALL steps below. Work is NOT complete until `git push` succeeds.

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Push to remote**:

   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```

5. **Verify** - All changes committed AND pushed

**Rules:**

- Work is NOT complete until `git push` succeeds
- If push fails, resolve and retry until it succeeds

---

## Overview

This is a personal collection of standalone utility scripts for various development tasks. Each script is self-contained and can be run independently. The repository contains no build system, package manager, or test suite.

## Repository Structure

The codebase is organized by script purpose rather than by language:

- **HAML/Tailwind utilities**: Ruby scripts for processing HAML files with Tailwind CSS
- **Markdown utilities**: Python and Ruby scripts for analyzing and manipulating markdown files with YAML frontmatter
- **Development environment automation**: Unified Alfred/terminal launcher for Ghostty + VSCode environments (personal projects) and iTerm2 + VSCode (work)
- **Docker/GitHub utilities**: Shell and Fish scripts for container registry authentication
- **Diff/merge tools**: Shell scripts for visual diff tools

## Common Patterns

### Running Scripts

All scripts are designed to be executed directly from their location:

```bash
# Ruby scripts
ruby script_name.rb [arguments]

# Python scripts
python3 script_name.py [arguments]

# Shell scripts
./script_name.sh [arguments]
```

### Script Self-Documentation

Most scripts include usage instructions when run without arguments or with invalid arguments. Check the script's `if __FILE__ == $0` or `if __name__ == '__main__':` block for usage examples.

### Development Environment Automation

Located in `dev-envs/`, this unified system launches complete development environments via Alfred or terminal. One command sets up Ghostty tabs and opens VSCode.

**See [dev-envs/CLAUDE.md](dev-envs/CLAUDE.md) for documentation.**

Usage via Alfred:

- `open work` - LoanLabs development environment
- `open bodyledger`, `open atlas`, `open compass`, `open scripts` - Personal projects

Usage via terminal: `~/local/src/scripts/dev-envs/configs/work.sh`

## Key Scripts

- **haml_tailwind_sorter.rb**: Sorts Tailwind CSS classes in HAML files according to official Tailwind order
- **find_duplicate_markdown_files.py**: Scans a directory tree for duplicate markdown files using SHA256 fingerprinting, stores results in SQLite
- **find_replace_frontmatter_attribute.rb**: Bulk renames YAML frontmatter attributes in markdown files (creates `.bak` backups)

## Development Notes

- Scripts are standalone and have no interdependencies
- No shared library or common utilities module
- Each script manages its own dependencies and error handling
- Python scripts use standard library where possible
- Ruby scripts are self-contained classes or procedural code

## The author never handles tracker plumbing

Standing instruction from the repository owner, and it outranks any tracker workflow step in
this file.

1. **Never ask the author to run `bd export`, and never raise `.beads/issues.jsonl` with them.**
   That file is a passive export of the Dolt database, not something a person maintains. An agent
   that needs it current runs the export itself, silently, as part of whatever it was already
   doing.
2. **Never ask the author to sync the Dolt remote.** Syncing is a machine's job, not something a
   person should have to remember.
3. **Report tracker plumbing only when it fails.** A successful export is not news. A failed one
   is, because the beads then exist on one machine only.

This constrains agents, not `bd` itself. Automation that runs the export on its own is exactly
what these rules ask for. A checklist that tells a person to run it is what they forbid.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:970c3bf2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   bd dolt push
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->

<!-- BEGIN BEADS CODEX SETUP: generated by bd setup codex -->

