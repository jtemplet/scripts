# Personal Development Scripts

A collection of standalone utility scripts for streamlining various development tasks.

## Contents

### Development Environment Launcher (`dev-envs/`)

Unified system for launching complete development environments. One Alfred command sets up iTerm2 with project-specific tabs and opens VSCode with the correct workspace.

**Why**: Eliminates the repetitive manual setup of opening multiple tabs, navigating to directories, and launching VSCode every time you start working on a project.

See [dev-envs/CLAUDE.md](dev-envs/CLAUDE.md) for detailed documentation.

**Usage via Alfred** (recommended):
- `open work` - LoanLabs development (7 tabs: Dev Server, Claude, Linear, MariaDB, Test/Lint, Beads, General)
- `open bodyledger` - Bodyledger iOS
- `open hdw` - Health Data Warehouse
- `open orryx` - Orryx
- `open scripts` - This repository

**Usage via Terminal**:
```bash
~/local/src/scripts/dev-envs/configs/work.sh
~/local/src/scripts/dev-envs/configs/bodyledger.sh
```

**Install Alfred Workflow**:
```bash
open ~/local/src/scripts/dev-envs/alfred/dev-environments.alfredworkflow
```

### HAML/Tailwind Utilities

- **haml_tailwind_sorter.rb** - Sorts Tailwind CSS classes in HAML files according to Tailwind's official ordering

### Markdown Utilities

- **find_duplicate_markdown_files.py** - Finds duplicate markdown files using SHA256 fingerprinting, outputs to SQLite database
- **find_replace_frontmatter_attribute.rb** - Bulk rename YAML frontmatter attributes across markdown files (creates `.bak` backups)

### Docker/GitHub Utilities

- **docker-ghcr-login.sh** - GitHub Container Registry authentication
- **patch_ghcr_secret_with_new_gh_pat.fish** - Update GHCR secrets with new GitHub PAT

### Development Tools

- **diffmerge.sh** - Visual diff tool wrapper
- **meld_diff.py** - Meld diff tool integration
- **java_find**, **ruby_find** - Language-specific file search utilities
- **getRubyTimestamps** - Ruby timestamp extraction

## Architecture

Each script is self-contained with no interdependencies. Scripts are organized by purpose rather than language. Most scripts include usage instructions when run without arguments.

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Requirements

- **Ruby**: For `.rb` scripts
- **Python 3**: For `.py` scripts
- **iTerm2**: With Python API enabled (Preferences → General → Magic)
- **Alfred** (with Powerpack): For `open <project>` workflow
- **linear-cli**: `npm install -g @linear/cli` (for work environment Linear tab)
- **Fish Shell**: For `.fish` scripts
