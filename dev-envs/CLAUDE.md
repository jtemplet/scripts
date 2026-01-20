# Development Environment Automation

This directory contains a unified system for launching development environments with iTerm2 and VSCode.

## Architecture

```
dev-envs/
├── dev_env.py              # Core Python module (iTerm2 automation)
├── configs/                # Environment configs (one per project)
│   ├── work.sh
│   ├── bodyledger.sh
│   ├── hdw.sh
│   ├── orryx.sh
│   └── scripts.sh
└── alfred/
    └── dev-environments.alfredworkflow
```

## Usage

### Via Alfred (recommended)
- `open work` - LoanLabs development
- `open bodyledger` - Bodyledger iOS
- `open hdw` - Health Data Warehouse
- `open orryx` - Orryx
- `open scripts` - Scripts repository

### Via Terminal
```bash
~/local/src/scripts/dev-envs/configs/work.sh
~/local/src/scripts/dev-envs/configs/bodyledger.sh
```

## Adding New Environments

1. Create a new config script in `configs/`:
```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ITERM_PYTHON="$HOME/Library/Application Support/iTerm2/iterm2env-3.14/versions/3.14.0/bin/python3"

"$ITERM_PYTHON" "$SCRIPT_DIR/dev_env.py" \
  --name "Project Name" \
  --project ~/Dev/project-path \
  --profile personal \
  --vscode-workspace ~/Dev/project-path/project.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "db:PostgreSQL:.:psql -h localhost -U user dbname" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:bd ready" \
         "general:General:.:"
```

2. Add keyword to Alfred workflow

Tab format: `id:Title:subdir:command`
- `subdir` relative to project (`.` = root)
- Empty command = just cd to directory

## Dependencies

- iTerm2 with Python API enabled (Preferences → General → Magic)
- iTerm2's bundled Python (used automatically via ITERM_PYTHON)
- VSCode with `code` CLI installed
- linear-cli (`npm install -g @linear/cli`) for work environment
