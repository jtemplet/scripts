# Unified Development Environment Launcher

## Problem

Current iTerm2 automation has one Python script per project, leading to:
- Code duplication across 5+ scripts
- Manual creation of new scripts for each project
- No VSCode integration
- No Alfred integration for quick launching

## Solution

Three-layer architecture:

```
Alfred Workflows    →  "open work", "open bodyledger", etc.
        ↓
Shell Scripts       →  work.sh, bodyledger.sh (config + launcher)
        ↓
Python Module       →  dev_env.py (single file, all iTerm2 logic)
```

## File Structure

```
iterm2/
├── dev_env.py              # Core module
├── configs/
│   ├── work.sh
│   ├── bodyledger.sh
│   ├── hdw.sh
│   ├── orryx.sh
│   └── scripts.sh
└── alfred/
    └── dev-environments.alfredworkflow
```

## Tab Layouts

### Work Environment (7 tabs)

| Tab | Name | Directory | Command |
|-----|------|-----------|---------|
| 1 | Dev Server | platform/app | `./bin/dev` |
| 2 | Claude | platform | `claude-work && claude` |
| 3 | Linear | platform | `linear issue list --mine --status 'In Progress' 'Todo'` |
| 4 | MariaDB | platform | `mysql -u root -p loan_os_development` |
| 5 | Test/Lint | platform/app | (none) |
| 6 | Beads | platform | `bd ready` |
| 7 | General | platform | (none) |

### Personal with Database (HDW) - 6 tabs

| Tab | Name | Directory | Command |
|-----|------|-----------|---------|
| 1 | Claude | project root | `claude-personal && claude` |
| 2 | Git | project root | `git status` |
| 3 | PostgreSQL | project root | `psql -h localhost -U jtempleton health_data_warehouse` |
| 4 | Test/Lint | project root | (none) |
| 5 | Beads | project root | `bd ready` |
| 6 | General | project root | (none) |

### Personal without Database (Bodyledger, Orryx, Scripts) - 5 tabs

| Tab | Name | Directory | Command |
|-----|------|-----------|---------|
| 1 | Claude | project root | `claude-personal && claude` |
| 2 | Git | project root | `git status` |
| 3 | Test/Lint | project root | (none) |
| 4 | Beads | project root | `bd ready` |
| 5 | General | project root | (none) |

## Config Script Format

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

python3 "$SCRIPT_DIR/dev_env.py" \
  --name "Project Name" \
  --project ~/Dev/project-path \
  --profile work|personal \
  --vscode-workspace ~/Dev/project-path/project.code-workspace \
  --tabs "id:Title:subdir:command" \
         "id:Title:subdir:command"
```

Tab format: `id:Title:subdir:command`
- `subdir` relative to project (`.` = root)
- Empty command = just cd to directory

## VSCode Workspaces

| Project | Workspace File | Status |
|---------|----------------|--------|
| loanlabs (work) | `~/Dev/loanlabs.ai/platform/loanlabs.code-workspace` | Exists |
| bodyledger-ios | `~/Dev/bodyledger-ios/bodyledger.code-workspace` | Create |
| health-data-warehouse | `~/Dev/health-data-warehouse/hdw.code-workspace` | Create |
| orryx | `~/Dev/orryx/orryx.code-workspace` | Create |
| scripts | `~/local/src/scripts/scripts.code-workspace` | Create |

## Alfred Workflow

Single workflow with keywords:
- `open work` → `configs/work.sh`
- `open bodyledger` → `configs/bodyledger.sh`
- `open hdw` → `configs/hdw.sh`
- `open orryx` → `configs/orryx.sh`
- `open scripts` → `configs/scripts.sh`

## Dependencies

- `linear-cli`: `npm install -g @linear/cli`
- Existing: Python 3, iTerm2, `iterm2` Python module

## Cleanup

Delete after migration:
- `rails_work_dev_env.py`
- `personal_dev_env-bodyledger-ios.py`
- `personal_dev_env-health-data-warehouse.py`
- `personal_dev_env-orryx.py`
- `personal_dev_env-scripts-dev.py`

## Implementation Order

1. Install linear-cli dependency
2. Create `dev_env.py` core module
3. Create config shell scripts
4. Create VSCode workspace files
5. Create Alfred workflow
6. Test all environments
7. Delete old scripts
