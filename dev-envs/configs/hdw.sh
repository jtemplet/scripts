#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ITERM_PYTHON="$HOME/Library/Application Support/iTerm2/iterm2env-3.14/versions/3.14.0/bin/python3"

"$ITERM_PYTHON" "$SCRIPT_DIR/dev_env.py" \
  --name "Health Data Warehouse" \
  --project ~/Dev/health-data-warehouse \
  --profile personal \
  --vscode-workspace ~/Dev/health-data-warehouse/hdw.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "db:PostgreSQL:.:psql -h localhost -U jtempleton health_data_warehouse" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:bd ready" \
         "general:General:.:"
