#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ITERM_PYTHON="$HOME/Library/Application Support/iTerm2/iterm2env-3.14/versions/3.14.0/bin/python3"

"$ITERM_PYTHON" "$SCRIPT_DIR/dev_env.py" \
  --name "Fish Config" \
  --project ~/local/src/fish_config \
  --profile personal \
  --vscode-workspace ~/local/src/fish_config/fish_config.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:bd ready" \
         "general:General:.:"
