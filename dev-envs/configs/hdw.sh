#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

python3 "$SCRIPT_DIR/ghostty_dev_env.py" \
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
