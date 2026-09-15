# Mac setup

Brings a Mac to Jason's working environment in one command, instead of
discovering the missing pieces one failed command at a time.

```bash
~/Dev/scripts/mac-setup/setup-machine.sh
```

Safe to re-run. `--list` prints the steps; naming steps runs only those
(`setup-machine.sh brew fish`).

## Why this exists

The fish config and the gitconfig call binaries by name and declare none of
them. On a fresh Mac each one fails separately, and the failures are not always
legible as a missing dependency:

- `bat` absent makes **`cat` itself fail**, because `binary_overrides.fish`
  aliases `cat` to `bat`. Every script that reads a file breaks at once.
- `rbenv` absent used to run `exit 1` inside `conf.d/rbenv.fish`. A `conf.d`
  file is sourced during startup, so that abandoned the rest of it, which
  aborted a `fisher` run mid-write and **deleted `fish_plugins`**.
- `fzf` absent makes `wtrm` fail with `Unknown command`.

`Brewfile` is the missing declaration. Every entry is something a tracked
config file names.

## What it deliberately leaves to you

| Not done | Why |
|---|---|
| Creating the account, setting the login shell | Needs sudo. fish must be installed **before** it becomes a login shell, or the account cannot log in. |
| `sudo chmod -R g+w /opt/homebrew` | Needs sudo, and only on a machine where another user owns Homebrew. Run it **first** — doing it later leaves the tree owned by two users and then neither can install. |
| `gh auth login`, `claude` sign-in | Your credentials, entered by you. |
| Copying `~/.claude` | It holds `.credentials.json`. A token is minted per machine, never carried. |
| Language runtimes for a repo | `mise` owns those, installed by that repo's own `./lola bootstrap` from `.tool-versions`. |

## The one gap

`~/.config/wt/` is in no repository, so this script cannot fetch it. Without it
`wtls`, `wtnew`, `wtst`, `wtstack` and `wtreview` are silently absent — the
`wt*` functions that live in `fish_config` still work, which makes the gap hard
to spot. Copy it from a machine that has it:

```bash
rsync -a ~/.config/wt/ <newmachine>:.config/wt/
```

Putting that directory in the `dotfiles` repo would close this.

## Order that works on a shared machine

1. An admin installs fish, then creates the account with fish as its shell.
2. `sudo chmod -R g+w /opt/homebrew` — before anything else installs.
3. `gh auth login`.
4. This script.
5. `rsync` the `wt` directory and the `~/.claude` subset from another machine.
6. Clone the work repo, `./lola bootstrap`, `./lola setup`.

Steps 1 and 2 are the only ones needing a password.

## Traps worth remembering

- **Never run `fisher`** against `fish_config`. The repo commits the plugin
  files, so a clone already delivers them and fisher refuses to overwrite files
  it does not own. One of its three plugins, `rbenv/fish-rbenv`, is 404
  upstream, so `fisher update` can never succeed anywhere.
- **Never install ruby, node or pnpm by hand for a repo mise manages.** A
  hand-installed copy lands ahead of mise's shims in PATH and the repo builds
  against the wrong version without saying so.
- **Never `chown` a shared Homebrew to yourself.** Homebrew suggests it; it
  transfers the whole tree and breaks the other user. `chmod -R g+w` grants the
  `admin` group write without changing ownership.
- **ssh carries no locale.** Without `LANG`, tmux rewrites every non-ASCII
  character to `_` and box-drawing interfaces render as garbage. `config.fish`
  sets a UTF-8 default when nothing else did.
