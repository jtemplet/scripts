# Development Environment Automation

This directory contains a unified system for launching development environments with Ghostty (personal projects) or iTerm2 (work) and VSCode.

## Architecture

```text
dev-envs/
├── ghostty_dev_env.py      # Core Python module (Ghostty automation, personal projects)
├── dev_env.py              # Core Python module (iTerm2 automation, work only)
├── configs/                # Environment configs (one per project)
│   ├── work.sh
│   ├── bodyledger.sh
│   ├── atlas.sh
│   ├── compass.sh
│   └── scripts.sh
└── alfred/
    └── dev-environments.alfredworkflow
```

## Usage

### Via Alfred (recommended)

- `open work` - LoanLabs development
- `open bodyledger` - Bodyledger iOS
- `open atlas` - Health Data Warehouse
- `open compass` - Compass
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

python3 "$SCRIPT_DIR/ghostty_dev_env.py" \
  --name "Project Name" \
  --project ~/Dev/project-path \
  --profile personal \
  --vscode-workspace ~/Dev/project-path/project.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "db:PostgreSQL:.:psql -h localhost -U user dbname" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:br ready" \
         "general:General:.:"
```

2. Add keyword to Alfred workflow

Tab format: `id:Title:subdir:command`

- `subdir` relative to project (`.` = root)
- Empty command = just cd to directory

## Dependencies

- Ghostty terminal installed (personal projects)
- iTerm2 with Python API enabled (work only)
- VSCode with `code` CLI installed
- linear-cli (`npm install -g @linear/cli`) for work environment
