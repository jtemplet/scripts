# Development Environment Automation

This directory contains a unified system for launching development environments with Ghostty (personal projects) or iTerm2 (work) and VSCode.

## Architecture

```text
dev-envs/
├── ghostty_dev_env.py      # Core Python module (Ghostty automation, personal projects)
├── dev_env.py              # Core Python module (iTerm2 automation, work only)
├── tmux_remote_env.sh      # Core shell module (tmux on a remote host, over ssh)
├── configs/                # Environment configs (one per project)
│   ├── work.sh
│   ├── mini.sh
│   ├── bodyledger.sh
│   ├── atlas.sh
│   ├── compass.sh
│   └── scripts.sh
└── alfred/
    └── dev-environments.alfredworkflow
```

### Local versus remote

The two Python modules build tabs in a terminal on **this** Mac. Such a tab dies
with the terminal, which is why those configs start the dev server on launch.

`tmux_remote_env.sh` is for a project living on **another** machine. It builds a
tmux session there, then attaches iTerm2 in control mode (`tmux -CC`), which
turns each tmux window into a native iTerm tab — so it scripts no tabs itself.
Two consequences follow, and they are why it is a separate module:

- The session outlives the terminal, the ssh connection, and a closed laptop.
  Re-running its config **attaches** to what is already there.
- Nothing auto-starts a server, because a server would then outlive every
  detach and keep running on a machine somebody else shares.

## Usage

### Via Alfred (recommended)

- `open work` - LoanLabs development
- `open mini` - Factory on Brew's Mac Mini (remote tmux)
- `open bodyledger` - Bodyledger iOS
- `open atlas` - Health Data Warehouse
- `open compass` - Compass
- `open scripts` - Scripts repository

### Via Terminal

```bash
~/local/src/scripts/dev-envs/configs/work.sh
~/local/src/scripts/dev-envs/configs/bodyledger.sh
```

## Adding New Environments

1. Create a new config script in `configs/`:

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

python3 "$SCRIPT_DIR/ghostty_dev_env.py" \
  --name "Project Name" \
  --project ~/Dev/project-path \
  --profile personal \
  --vscode-workspace ~/Dev/project-path/project.code-workspace \
  --tabs "claude:Claude:.:claude-personal && claude" \
         "git:Git:.:git status" \
         "db:PostgreSQL:.:psql -h localhost -U user dbname" \
         "test:Test/Lint:.:" \
         "beads:Beads:.:br ready" \
         "general:General:.:"
```

2. Add keyword to Alfred workflow

Tab format: `id:Title:subdir:command`

- `subdir` relative to project (`.` = root)
- Empty command = just cd to directory

### For a project on a remote machine

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

"$SCRIPT_DIR/tmux_remote_env.sh" \
  --host mini \
  --session factory \
  --root /Users/jason/Code/factory \
  --windows "claude:.:claude" \
            "test:rails:" \
            "git:.:git status --short"
```

Window format: `name:subdir:command` — three fields, not the four above,
because a tmux window name is its title.

- `--host` is an ssh alias from `~/.ssh/config`.
- `--root` is the path on the **remote** machine.
- `--no-attach` builds the session and prints the attach command instead of
  opening iTerm. Useful from a script or when testing.

## Dependencies

- Ghostty terminal installed (personal projects)
- iTerm2 with Python API enabled (work only)
- VSCode with `code` CLI installed
- linear-cli (`npm install -g @linear/cli`) for work environment
