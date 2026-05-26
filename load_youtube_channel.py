#!/usr/bin/env python3
"""Scrape YouTube channel videos and bulk-load into NotebookLM.

Two subcommands:
  scrape  - Fetch all videos from a YouTube channel via InnerTube API (no deps)
  load    - CURRENTLY DISABLED - requires integration with NotebookLM MCP tools

Usage:
  python3 load_channel.py scrape --channel "https://www.youtube.com/@LennysPodcast" --output /tmp/videos.json

  # For loading, use Claude Code's NotebookLM MCP tools instead of this script's load command

NOTE: The 'load' functionality requires modification to work with Claude Code's NotebookLM MCP server
instead of the unavailable 'notebooklm' Python package.
"""
import argparse
import asyncio
import json
import re
import sys
import time
import urllib.request


# =============================================================================
# Scrape: YouTube channel -> video list JSON
# =============================================================================

INNERTUBE_API = "https://www.youtube.com/youtubei/v1/browse"
INNERTUBE_HEADERS = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"}
INNERTUBE_CONTEXT = {
    "client": {"clientName": "WEB", "clientVersion": "2.20240101.00.00"}
}


def resolve_channel_id(channel_url: str) -> str:
    """Extract channel ID from a YouTube channel page."""
    req = urllib.request.Request(channel_url, headers={
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Accept-Language": "en-US,en;q=0.9",
    })
    html = urllib.request.urlopen(req).read().decode("utf-8")

    for pattern in [
        r'"channelId":"(UC[^"]+)"',
        r'"externalId":"(UC[^"]+)"',
        r'channel_id=(UC[^&"]+)',
    ]:
        m = re.search(pattern, html)
        if m:
            return m.group(1)

    raise ValueError(f"Could not find channel ID in {channel_url}")


def innertube_request(body: dict) -> dict:
    """Make an InnerTube API request."""
    data = json.dumps(body).encode()
    req = urllib.request.Request(INNERTUBE_API, data=data, headers=INNERTUBE_HEADERS)
    return json.loads(urllib.request.urlopen(req).read().decode())


def extract_videos(items: list) -> list[dict]:
    """Extract video info from InnerTube response items."""
    videos = []
    for item in items:
        vr = None
        if "richItemRenderer" in item:
            vr = item["richItemRenderer"].get("content", {}).get("videoRenderer")
        elif "gridVideoRenderer" in item:
            vr = item["gridVideoRenderer"]
        elif "videoRenderer" in item:
            vr = item["videoRenderer"]

        if not vr:
            continue

        vid_id = vr.get("videoId", "")
        title = ""
        for run in vr.get("title", {}).get("runs", []):
            title += run.get("text", "")
        if not title:
            title = vr.get("title", {}).get("simpleText", "")

        if vid_id and title:
            videos.append({
                "id": vid_id,
                "title": title,
                "length": vr.get("lengthText", {}).get("simpleText", ""),
                "views": vr.get("viewCountText", {}).get("simpleText", ""),
                "published": vr.get("publishedTimeText", {}).get("simpleText", ""),
                "url": f"https://www.youtube.com/watch?v={vid_id}",
            })
    return videos


def scrape_channel(channel_url: str) -> list[dict]:
    """Scrape all videos from a YouTube channel."""
    channel_id = resolve_channel_id(channel_url)
    print(f"Channel ID: {channel_id}", file=sys.stderr)

    body = {
        "context": INNERTUBE_CONTEXT,
        "browseId": channel_id,
        "params": "EgZ2aWRlb3PyBgQKAjoA",  # Videos tab
    }
    resp = innertube_request(body)

    all_videos = []
    tabs = resp.get("contents", {}).get("twoColumnBrowseResultsRenderer", {}).get("tabs", [])

    for tab in tabs:
        grid = tab.get("tabRenderer", {}).get("content", {}).get("richGridRenderer", {})
        if not grid:
            continue

        items = grid.get("contents", [])
        all_videos.extend(extract_videos(items))

        # Follow continuation tokens
        token = None
        for item in items:
            if "continuationItemRenderer" in item:
                token = (
                    item["continuationItemRenderer"]
                    ["continuationEndpoint"]
                    ["continuationCommand"]
                    ["token"]
                )

        page = 1
        while token and page < 100:
            cont_body = {"context": INNERTUBE_CONTEXT, "continuation": token}
            cont_resp = innertube_request(cont_body)

            token = None
            for action in cont_resp.get("onResponseReceivedActions", []):
                append_items = action.get("appendContinuationItemsAction", {}).get("continuationItems", [])
                all_videos.extend(extract_videos(append_items))

                for ci in append_items:
                    if "continuationItemRenderer" in ci:
                        token = (
                            ci["continuationItemRenderer"]
                            ["continuationEndpoint"]
                            ["continuationCommand"]
                            ["token"]
                        )

            page += 1
            print(f"\rPage {page}, videos: {len(all_videos)}", end="", file=sys.stderr)

    print(f"\nTotal: {len(all_videos)} videos", file=sys.stderr)
    return all_videos


# =============================================================================
# Load: video list JSON -> NotebookLM notebook
# =============================================================================

success_count = 0
fail_count = 0
errors = []


async def add_video(client, sem, i, total, video, notebook_id):
    """Add a single video to NotebookLM."""
    print("ERROR: add_video function disabled - requires MCP tool integration")
    pass


async def load_videos(videos_file: str, notebook_id: str, count: int, concurrency: int, skip: int):
    """Load videos into NotebookLM in parallel."""
    print("ERROR: This script requires modification to work with the NotebookLM MCP server.")
    print("The original 'notebooklm' Python package import is not available.")
    print("You need to modify this script to use Claude Code's NotebookLM MCP tools instead.")
    print("Consider using the NotebookLM MCP tools directly via Claude Code rather than this script.")
    sys.exit(1)


# =============================================================================
# CLI
# =============================================================================

def main():
    parser = argparse.ArgumentParser(description="YouTube channel -> NotebookLM loader")
    sub = parser.add_subparsers(dest="command", required=True)

    # scrape
    sp = sub.add_parser("scrape", help="Scrape videos from a YouTube channel")
    sp.add_argument("--channel", required=True, help="YouTube channel URL")
    sp.add_argument("--output", required=True, help="Output JSON file path")

    # load
    lp = sub.add_parser("load", help="Load videos into a NotebookLM notebook")
    lp.add_argument("--videos", required=True, help="Path to scraped videos JSON")
    lp.add_argument("--notebook", required=True, help="NotebookLM notebook ID")
    lp.add_argument("--count", type=int, default=200, help="Number of videos to load (default: 200)")
    lp.add_argument("--concurrency", type=int, default=20, help="Parallel requests (default: 20)")
    lp.add_argument("--skip", type=int, default=0, help="Skip N most recent videos (default: 0)")

    args = parser.parse_args()

    if args.command == "scrape":
        videos = scrape_channel(args.channel)
        with open(args.output, "w") as f:
            json.dump(videos, f, indent=2)
        print(f"Saved {len(videos)} videos to {args.output}")

    elif args.command == "load":
        t0 = time.time()
        asyncio.run(load_videos(args.videos, args.notebook, args.count, args.concurrency, args.skip))
        print(f"Elapsed: {time.time() - t0:.0f}s")


if __name__ == "__main__":
    main()
