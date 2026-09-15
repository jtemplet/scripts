#!/bin/bash
# Bring a Mac to Jason's working environment: shell, dotfiles, tools, agent config.
#
#   ./setup-machine.sh            # everything
#   ./setup-machine.sh --list     # show the steps and stop
#   ./setup-machine.sh brew fish  # only the named steps
#
# Safe to re-run: every step checks before it acts.
#
# What it does NOT do, and why:
#   * Create the account or set the login shell. Both need sudo, and fish must
#     be installed before it becomes a login shell or the account cannot log in.
#   * Fix a shared Homebrew. On a machine where another user owns /opt/homebrew,
#     run `sudo chmod -R g+w /opt/homebrew` FIRST. Doing it later leaves the
#     tree owned by two users, and then neither can install anything.
#   * Sign in to anything. gh and Claude Code each prompt for their own login.
#   * Copy any credential. Tokens are minted per machine, never carried.
set -euo pipefail

FISH_REPO="jtemplet/fish_config"
DOTFILES_REPO="jtemplet/dotfiles"
DOTFILES_DIR="$HOME/local/src/dotfiles"
BREWFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Brewfile"
BREW="/opt/homebrew/bin/brew"

STEPS=(brew fish dotfiles wt claude summary)

log()  { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
has()  { command -v "$1" >/dev/null 2>&1; }

step_brew() {
  log "Homebrew packages"
  [ -x "$BREW" ] || { echo "Homebrew missing. Install it from https://brew.sh first." >&2; exit 1; }
  if ! "$BREW" bundle check --file "$BREWFILE" >/dev/null 2>&1; then
    "$BREW" bundle --file "$BREWFILE"
  else
    note "already satisfied"
  fi
}

step_fish() {
  log "fish configuration"
  local dir="$HOME/.config/fish"
  if [ -d "$dir/.git" ]; then
    note "pulling $dir"
    git -C "$dir" pull --ff-only
  else
    # fish creates this directory on first launch; the clone needs it absent.
    [ -d "$dir" ] && mv "$dir" "$dir.pre-setup.$(date +%s)"
    mkdir -p "$HOME/.config"
    gh repo clone "$FISH_REPO" "$dir"
  fi
  note "Do NOT run fisher here. The repo commits the plugin files themselves,"
  note "so a clone already delivers them, and one of its plugins is 404 upstream."
}

step_dotfiles() {
  log "dotfiles"
  if [ -d "$DOTFILES_DIR/.git" ]; then
    git -C "$DOTFILES_DIR" pull --ff-only
  else
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    gh repo clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  # Tracked without the leading dot, symlinked into $HOME.
  link_dotfile "gitconfig"  "$HOME/.gitconfig"
  link_dotfile "gitignore"  "$HOME/.gitignore"
  link_dotfile "vimrc"      "$HOME/.vimrc"
  link_dotfile ".finicky.js" "$HOME/.finicky.js"

  # gitconfig carries the aliases and core.excludesfile; identity is per machine
  # only in that it must be set at all. A commit fails outright without it.
  if [ -z "$(git config --global user.email || true)" ]; then
    note "setting git identity"
    git config --global user.name "Jason Templeton"
    git config --global user.email "jason@loanlabs.ai"
  fi
}

link_dotfile() {
  local src="$DOTFILES_DIR/$1" dest="$2"
  [ -e "$src" ] || return 0
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    note "$dest already linked"
    return 0
  fi
  [ -e "$dest" ] && mv "$dest" "$dest.pre-setup.$(date +%s)"
  ln -s "$src" "$dest"
  note "linked $dest"
}

step_wt() {
  log "wt worktree tooling"
  local dir="$HOME/.config/wt"
  if [ -d "$dir" ]; then
    note "$dir present"
  else
    note "MISSING and this script cannot fetch it: ~/.config/wt is in no repo."
    note "Copy it from a machine that has it:"
    note "  rsync -a ~/.config/wt/ <thismachine>:.config/wt/"
    note "Without it, wtls, wtnew, wtst, wtstack and wtreview are absent."
  fi
}

step_claude() {
  log "Claude Code"
  if [ -x "$HOME/.local/bin/claude" ]; then
    note "installed: $("$HOME/.local/bin/claude" --version 2>/dev/null || echo unknown)"
  else
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  note "~/.claude config is NOT fetched here: it holds .credentials.json."
  note "Push the safe subset from another machine, then sign in on this one:"
  note "  rsync -a --exclude gstack ~/.claude/skills/ <thismachine>:.claude/skills/"
}

step_summary() {
  log "Remaining, each needing your own credentials"
  note "1. gh auth login   (add --scopes read:packages for GitHub Packages)"
  note "2. claude          (sign in once)"
  note "3. A factory checkout: ./lola bootstrap, then ./lola setup."
  note "   mise owns ruby/node/pnpm there. Do not install them by hand."
}

main() {
  if [ "${1:-}" = "--list" ]; then printf '%s\n' "${STEPS[@]}"; exit 0; fi
  local chosen=("$@")
  [ ${#chosen[@]} -eq 0 ] && chosen=("${STEPS[@]}")
  for s in "${chosen[@]}"; do
    if ! printf '%s\n' "${STEPS[@]}" | grep -qx "$s"; then
      echo "Unknown step: $s. Known steps: ${STEPS[*]}" >&2
      exit 2
    fi
    "step_$s"
  done
  log "Done."
}

main "$@"
