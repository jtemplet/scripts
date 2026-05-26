#!/usr/bin/env python3
"""
Unified development environment launcher for Ghostty.

Creates Ghostty tabs and opens VSCode workspace based on configuration.

Usage:
    python3 ghostty_dev_env.py \
        --name "Project Name" \
        --project ~/Dev/project \
        --profile work|personal \
        --vscode-workspace ~/Dev/project/project.code-workspace \
        --tabs "id:Title:subdir:command" "id:Title:subdir:command"

Tab format: id:Title:subdir:command
    - id: unique identifier (unused, for readability)
    - Title: tab title shown in the terminal
    - subdir: subdirectory relative to project (. = project root)
    - command: command to run (empty = just cd)
"""

import argparse
import os
import subprocess
import sys
import time
import traceback


def parse_tab(tab_spec: str, project_path: str) -> dict:
    parts = tab_spec.split(":", 3)
    if len(parts) < 3:
        raise ValueError(f"Invalid tab spec: {tab_spec}")

    tab_id = parts[0]
    title = parts[1]
    subdir = parts[2]
    command = parts[3] if len(parts) > 3 else ""

    if subdir == ".":
        directory = project_path
    else:
        directory = os.path.join(project_path, subdir)

    return {
        "id": tab_id,
        "title": title,
        "directory": directory,
        "command": command,
    }


def parse_args():
    parser = argparse.ArgumentParser(description="Launch development environment")
    parser.add_argument("--name", required=True, help="Window title")
    parser.add_argument("--project", required=True, help="Project directory path")
    parser.add_argument("--profile", choices=["work", "personal"], required=True)
    parser.add_argument("--vscode-workspace", required=True, help="VSCode workspace file")
    parser.add_argument("--tabs", nargs="+", required=True, help="Tab specifications")
    return parser.parse_args()


def run_applescript(script: str):
    result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"AppleScript warning: {result.stderr.strip()}")


def send_command(text: str):
    """Copy text to clipboard, paste into the active Ghostty tab, and press Return."""
    subprocess.run(["pbcopy"], input=text.encode(), check=True)
    run_applescript("""
        tell application "System Events"
            tell process "Ghostty"
                keystroke "v" using command down
                key code 36
            end tell
        end tell
    """)
    time.sleep(0.3)


def create_environment(args):
    print(f"Starting {args.name} environment...")

    project_path = os.path.expanduser(args.project)
    tabs = [parse_tab(spec, project_path) for spec in args.tabs]

    run_applescript('tell application "Ghostty" to activate')
    time.sleep(0.5)

    # Open a new window
    run_applescript("""
        tell application "System Events"
            tell process "Ghostty"
                keystroke "n" using command down
            end tell
        end tell
    """)
    time.sleep(0.8)
    print(f"Opened new Ghostty window for '{args.name}'")

    for i, tab_config in enumerate(tabs):
        print(f"Creating {tab_config['title']} tab...")

        if i > 0:
            run_applescript("""
                tell application "System Events"
                    tell process "Ghostty"
                        keystroke "t" using command down
                    end tell
                end tell
            """)
            time.sleep(0.5)

        cmd = f"cd {tab_config['directory']}"
        if tab_config["command"]:
            cmd += f" && {tab_config['command']}"

        send_command(cmd)

    # Open VSCode
    workspace_path = os.path.expanduser(args.vscode_workspace)
    if os.path.exists(workspace_path):
        print(f"Opening VSCode workspace: {workspace_path}")
        subprocess.run(["code", workspace_path], check=True)
    else:
        print(f"Warning: VSCode workspace not found: {workspace_path}")
        print(f"Opening project folder instead: {project_path}")
        subprocess.run(["code", project_path], check=True)

    print("Environment setup complete!")


def main():
    args = parse_args()
    try:
        create_environment(args)
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
