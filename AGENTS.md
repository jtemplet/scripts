# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Issue Tracking

This project uses **bd** (beads) for issue tracking. Run `br onboard` to get started.

```bash
br ready              # Find available work
br show <id>          # View issue details
br update <id> --status in_progress  # Claim work
br close <id>         # Complete work
br sync               # Sync with git
```

## Session Completion

**When ending a work session**, complete ALL steps below. Work is NOT complete until `git push` succeeds.

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Push to remote**:

   ```bash
   git pull --rebase
   br sync
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
