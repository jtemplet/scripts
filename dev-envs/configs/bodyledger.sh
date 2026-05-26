#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

python3 "$SCRIPT_DIR/ghostty_dev_env.py" \
  --name "Bodyledger iOS" \
  --project ~/Dev/bodyledger-ios \
  --profile personal \
  --vscode-workspace ~/Dev/bodyledger-ios/bodyledger.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:bd ready" \
         "general:General:.:"
