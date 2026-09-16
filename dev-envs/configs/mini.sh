#!/bin/bash
# Factory development on Brew's Mac Mini, over ssh.
#
# The session lives on the mini, so closing the laptop does not end it. Running
# this again attaches to what is already there rather than rebuilding it.
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# No command on the dev window on purpose. work.sh starts ./bin/dev because
# that session dies with the terminal; this one does not, so an auto-started
# server would outlive every detach and sit there on a machine Brew shares.
# Start it yourself in that window with `./lola dev`.
"$SCRIPT_DIR/tmux_remote_env.sh" \
  --host mini \
  --session factory \
  --root /Users/jason/Code/factory \
  --windows "claude:.:claude" \
            "dev:.:" \
            "test:rails:" \
            "git:.:git status --short" \
            "beads:.:bd ready" \
            "general:.:"
