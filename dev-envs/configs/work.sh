#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ITERM_PYTHON="$HOME/Library/Application Support/iTerm2/iterm2env-3.14/versions/3.14.0/bin/python3"

"$ITERM_PYTHON" "$SCRIPT_DIR/dev_env.py" \
  --name "LoanLabs Development" \
  --project ~/Dev/loanlabs.ai/platform \
  --profile work \
  --vscode-workspace ~/Dev/loanlabs.ai/platform/loanlabs.code-workspace \
  --tabs "dev:Dev Server:app:./bin/dev" \
         "claude:Claude:.:claude-work && claude" \
         "linear:Linear:.:linear-cli i list -a jason@loanlabs.ai" \
         "db:MariaDB:.:mysql -u root -p loan_os_development" \
         "test:Test/Lint:app:" \
         "beads:Beads:.:bd ready" \
         "general:General:.:"
