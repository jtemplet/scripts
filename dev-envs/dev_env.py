#!/usr/bin/python3
"""
Unified development environment launcher.

Creates iTerm2 tabs and opens VSCode workspace based on configuration.

Usage:
    python3 dev_env.py \
        --name "Project Name" \
        --project ~/Dev/project \
        --profile work|personal \
        --vscode-workspace ~/Dev/project/project.code-workspace \
        --tabs "id:Title:subdir:command" "id:Title:subdir:command"

Tab format: id:Title:subdir:command
    - id: unique identifier (unused, for readability)
    - Title: tab title shown in iTerm2
    - subdir: subdirectory relative to project (. = project root)
    - command: command to run (empty = just cd)
"""

import argparse
import iterm2
import os
import subprocess
import sys
import traceback


def parse_tab(tab_spec: str, project_path: str) -> dict:
    """Parse a tab specification string into a dict."""
    parts = tab_spec.split(":", 3)
    if len(parts) < 3:
        raise ValueError(f"Invalid tab spec: {tab_spec}")
    
    tab_id = parts[0]
    title = parts[1]
    subdir = parts[2]
    command = parts[3] if len(parts) > 3 else ""
    
    # Resolve directory
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


async def create_environment(connection, args):
    """Create the iTerm2 environment with tabs."""
    try:
        print(f"Starting {args.name} environment...")
        app = await iterm2.async_get_app(connection)
        print("Connected to iTerm2")
        
        project_path = os.path.expanduser(args.project)
        
        # Create a new window
        window = await iterm2.Window.async_create(connection)
        await window.async_set_title(args.name)
        print(f"Created new window with title '{args.name}'")
        
        # Parse tab specifications
        tabs = [parse_tab(spec, project_path) for spec in args.tabs]
        
        # Create tabs
        for i, tab_config in enumerate(tabs):
            print(f"Creating {tab_config['title']} tab...")
            
            if i == 0:
                # Use the current tab for the first one
                tab = window.current_tab
            else:
                tab = await window.async_create_tab()
            
            await tab.async_set_title(tab_config["title"])
            session = tab.current_session
            
            # Change to directory
            await session.async_send_text(f"cd {tab_config['directory']}\n")
            
            # Run command if specified
            if tab_config["command"]:
                await session.async_send_text(f"{tab_config['command']}\n")
        
        # Open VSCode
        workspace_path = os.path.expanduser(args.vscode_workspace)
        if os.path.exists(workspace_path):
            print(f"Opening VSCode workspace: {workspace_path}")
            subprocess.run(["code", workspace_path], check=True)
        else:
            print(f"Warning: VSCode workspace not found: {workspace_path}")
            print(f"Opening project folder instead: {project_path}")
            subprocess.run(["code", project_path], check=True)
        
        # Focus on the first tab (Claude tab for personal, Dev Server for work)
        first_tab = window.tabs[0] if window.tabs else None
        if first_tab:
            await first_tab.async_select()
        
        print("Environment setup complete!")
        
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        sys.exit(1)


def main():
    args = parse_args()
    iterm2.run_until_complete(lambda conn: create_environment(conn, args))


if __name__ == "__main__":
    main()
