#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

python3 "$SCRIPT_DIR/ghostty_dev_env.py" \
  --name "Scripts" \
  --project ~/local/src/scripts \
  --profile personal \
  --vscode-workspace ~/local/src/scripts/scripts.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:br ready" \
         "general:General:.:"
