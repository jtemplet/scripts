#!/bin/bash
# Build a tmux session on a remote host, then attach iTerm2 to it in control
# mode so each tmux window becomes a native iTerm tab.
#
#   tmux_remote_env.sh --host mini --session factory \
#                      --root /Users/jason/Code/factory \
#                      --windows "claude:.:claude" "test:rails:" "git:.:git status"
#
# --remote-shell picks the login shell used to build the session (default:
# fish), so PATH, mise, rbenv, and the like resolve the way an interactive
# session on that host would. Set it to the remote's actual login shell
# (zsh, bash) when fish is not installed there.
#
# Window spec: name:subdir:command   (subdir relative to --root, "." = root;
# empty command just lands you in the directory)
#
# Why this is not dev_env.py: under `tmux -CC` the windows belong to tmux on the
# remote host, and iTerm renders them as tabs. So nothing here scripts iTerm's
# tabs, and the session survives closing the laptop. Re-running attaches to the
# session that is already there rather than building a second one.
set -euo pipefail

HOST=""
SESSION=""
ROOT=""
WINDOWS=()
ATTACH=1
REMOTE_SHELL="fish"

usage() { sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --host)     HOST="$2"; shift 2 ;;
    --session)  SESSION="$2"; shift 2 ;;
    --root)     ROOT="$2"; shift 2 ;;
    --remote-shell) REMOTE_SHELL="$2"; shift 2 ;;
    --no-attach) ATTACH=0; shift ;;
    -h|--help)  usage 0 ;;
    --windows)  shift; while [ $# -gt 0 ] && [[ "$1" != --* ]]; do WINDOWS+=("$1"); shift; done ;;
    *) echo "Unknown argument: $1" >&2; usage 2 ;;
  esac
done

[ -n "$HOST" ]    || { echo "--host is required" >&2; exit 2; }
[ -n "$SESSION" ] || { echo "--session is required" >&2; exit 2; }
[ -n "$ROOT" ]    || { echo "--root is required" >&2; exit 2; }
[ ${#WINDOWS[@]} -gt 0 ] || { echo "--windows needs at least one spec" >&2; exit 2; }

# Build the remote script. Everything runs through a login shell so mise, fish
# functions and PATH are the ones an interactive session would get.
remote_script() {
  echo "set -e"
  echo "tmux has-session -t '$SESSION' 2>/dev/null && exit 0"
  local first=1
  for spec in "${WINDOWS[@]}"; do
    local name subdir command dir
    name="${spec%%:*}"
    local rest="${spec#*:}"
    subdir="${rest%%:*}"
    command="${rest#*:}"
    if [ "$subdir" = "." ]; then dir="$ROOT"; else dir="$ROOT/$subdir"; fi

    if [ "$first" = 1 ]; then
      echo "tmux new-session -d -s '$SESSION' -n '$name' -c '$dir'"
      first=0
    else
      echo "tmux new-window -t '$SESSION' -n '$name' -c '$dir'"
    fi
    # An explicitly named window must keep its name: automatic-rename would
    # otherwise relabel it from the running command on the next prompt.
    echo "tmux set-window-option -t '$SESSION:$name' automatic-rename off"
    [ -n "$command" ] && echo "tmux send-keys -t '$SESSION:$name' '$command' C-m"
  done
  echo "tmux select-window -t '$SESSION:$(echo "${WINDOWS[0]}" | cut -d: -f1)'"
}

echo "==> Ensuring tmux session '$SESSION' on $HOST"
remote_script | ssh "$HOST" "$REMOTE_SHELL -l -c 'bash -s'"

echo "==> Windows now on $HOST:"
ssh "$HOST" "$REMOTE_SHELL -l -c \"tmux list-windows -t '$SESSION' -F '    #{window_index}: #{window_name}'\""

if [ "$ATTACH" = 1 ]; then
  echo "==> Attaching iTerm2 in control mode"
  osascript <<APPLESCRIPT
tell application "iTerm2"
  create window with default profile command "ssh -t $HOST \"$REMOTE_SHELL -l -c 'tmux -CC attach -t $SESSION'\""
  activate
end tell
APPLESCRIPT
else
  echo "==> Skipping attach. Connect with:"
  echo "    ssh -t $HOST \"$REMOTE_SHELL -l -c 'tmux -CC attach -t $SESSION'\""
fi
