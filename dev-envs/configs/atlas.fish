#!/usr/bin/env fish
# Launch Atlas dev environment in Ghostty

set -l PROJECT "$HOME/Dev/atlas"

# Open VSCode workspace
code "$PROJECT/atlas.code-workspace" &

# Save clipboard so we can restore it after
set -l saved_clipboard (pbpaste 2>/dev/null)

# Each tab sets DEV_ENV_PROJECT so fish_title can prefix tab titles
set -l commands \
    "set -gx DEV_ENV_PROJECT Atlas; cd $PROJECT && claude-personal && claude" \
    "set -gx DEV_ENV_PROJECT Atlas; cd $PROJECT && br ready" \
    "set -gx DEV_ENV_PROJECT Atlas; cd $PROJECT && ./scripts/run_dev.sh" \
    "set -gx DEV_ENV_PROJECT Atlas; cd $PROJECT" \
    "set -gx DEV_ENV_PROJECT Atlas; cd $PROJECT"

# Launch a new Ghostty window
open -na Ghostty.app
sleep 1
osascript -e 'tell application "Ghostty" to activate'
sleep 0.5

for i in (seq (count $commands))
    if test $i -gt 1
        osascript -e 'tell application "System Events" to keystroke "t" using command down'
        sleep 0.3
    end

    # Clipboard paste is far more reliable than keystroke-per-character
    printf '%s' "$commands[$i]" | pbcopy
    osascript -e 'tell application "System Events" to keystroke "v" using command down'
    sleep 0.1
    osascript -e 'tell application "System Events" to key code 36'
    sleep 0.5
end

# Switch back to first tab
osascript -e 'tell application "System Events" to keystroke "1" using command down'

# Restore clipboard
printf '%s' "$saved_clipboard" | pbcopy
