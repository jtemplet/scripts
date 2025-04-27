#!/usr/bin/env python3
import iterm2
import sys
import traceback

async def main(connection):
    try:
        print("Starting iTerm2 automation script...")
        app = await iterm2.async_get_app(connection)
        print("Connected to iTerm2")

        orch_dir = "~/Dev/sovato-health/sovato-app"
        ########################
        # Tab 1: Dev Environment
        ########################
        print("Creating Dev Environment tab...")
        dev_tab = await app.current_window.async_create_tab()
        await dev_tab.async_set_title("Rails/Vite/Sidekiq Servers")
        await dev_tab.current_session.async_send_text(f"cd {orch_dir}\n")

        # Left Pane: Rails Server
        print("Setting up Rails server...")
        rails_pane = dev_tab.current_session
        await rails_pane.async_send_text("bundle exec rails server\n")

        # Right Pane: Split horizontally for Vite and Sidekiq
        print("Creating right pane...")
        right_pane = await rails_pane.async_split_pane(vertical=True)
        await right_pane.async_send_text(f"cd {orch_dir}\n")

        # Top Right: Vite Dev Server
        print("Setting up Vite dev server...")
        vite_pane = right_pane
        await vite_pane.async_send_text("bundle exec vite dev\n")

        # Bottom Right: Sidekiq
        print("Setting up Sidekiq...")
        sidekiq_pane = await right_pane.async_split_pane(vertical=False)
        await sidekiq_pane.async_send_text(f"cd {orch_dir}\n")
        await sidekiq_pane.async_send_text("bundle exec sidekiq -c 1\n")

        ########################
        # Tab 2: Rails Console
        ########################
        print("Rails console tab...")
        rails_console_tab = await app.current_window.async_create_tab()
        await rails_console_tab.async_set_title("Rails Console")
        await rails_console_tab.current_session.async_send_text(f"cd {orch_dir}\n")
        await rails_console_tab.current_session.async_send_text("clear\n")

        ########################
        # Tab 3: Git Ops
        ########################
        print("Creating Git tab...")
        git_tab = await app.current_window.async_create_tab()
        await git_tab.async_set_title("Git")
        await git_tab.current_session.async_send_text(f"cd {orch_dir}\n")
        await git_tab.current_session.async_send_text("clear\n")

        ########################
        # Tab 4: Database Console
        ########################
        print("Creating Database tab...")
        db_tab = await app.current_window.async_create_tab()
        await db_tab.async_set_title("Database")
        await db_tab.current_session.async_send_text(f"cd {orch_dir}\n")
        await db_tab.current_session.async_send_text("psql -h localhost -U jtempleton vuerails_development\n")

        ########################
        # Tab 5: Kubernetes Dev
        ########################
        print("Creating Kubernetes tab...")
        k8s_tab = await app.current_window.async_create_tab()
        await k8s_tab.async_set_title("Kubernetes")

        # Pane 1: Use Sandbox
        print("Setting up Kubernetes sandbox...")
        await k8s_tab.current_session.async_send_text(f"cd {orch_dir}\n")
        await k8s_tab.current_session.async_send_text("use-sandbox\n")

        # Pane 2: Create pane for helm
        print("Setting up helm...")
        helm_pane = await k8s_tab.current_session.async_split_pane(vertical=False)
        await helm_pane.async_send_text(f"cd {orch_dir}\n")
        await helm_pane.async_send_text("helm lint\n")

        print("Script completed successfully!")
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        sys.exit(1)

iterm2.run_until_complete(main)
