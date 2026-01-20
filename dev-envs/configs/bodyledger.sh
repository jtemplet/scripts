#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ITERM_PYTHON="$HOME/Library/Application Support/iTerm2/iterm2env-3.14/versions/3.14.0/bin/python3"

"$ITERM_PYTHON" "$SCRIPT_DIR/dev_env.py" \
  --name "Bodyledger iOS" \
  --project ~/Dev/bodyledger-ios \
  --profile personal \
  --vscode-workspace ~/Dev/bodyledger-ios/bodyledger.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:bd ready" \
         "general:General:.:"
