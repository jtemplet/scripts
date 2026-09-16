#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

python3 "$SCRIPT_DIR/ghostty_dev_env.py" \
  --name "Agentic Dev Workbench" \
  --project ~/local/src/templeton-agentic-dev-workbench \
  --profile personal \
  --vscode-workspace ~/local/src/templeton-agentic-dev-workbench/templeton-agentic-dev-workbench.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:br ready" \
         "general:General:.:"
