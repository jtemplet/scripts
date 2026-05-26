#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

python3 "$SCRIPT_DIR/ghostty_dev_env.py" \
  --name "Compass" \
  --project ~/Dev/compass \
  --profile personal \
  --vscode-workspace ~/Dev/compass/compass.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:br ready" \
         "general:General:.:"
