#!/usr/bin/env fish

set -l RED '\033[0;31m'
set -l GREEN '\033[0;32m'
set -l YELLOW '\033[1;33m'
set -l BLUE '\033[0;34m'
set -l NC '\033[0m'

echo "======================================"
echo "Setting up beads_viewer workspaces"
echo "======================================"
echo ""

# Find all projects with .beads directories
set -l projects (find ~/local/src ~/Dev -maxdepth 2 -type d -name ".beads" 2>/dev/null | sed 's/\/.beads$//')

set -l success_count 0
set -l fail_count 0
set -l skip_count 0

for project in $projects
    set -l project_name (basename $project)

    echo ""
    echo -e "$YELLOW━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$NC"
    echo -e "$YELLOW Processing: $project_name $NC"
    echo -e "$YELLOW━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$NC"

    cd $project

    # A bd repo keeps its database in one of three directory layouts, or
    # declares itself in metadata.json. Never a .db file: that is the
    # pre-cutover SQLite one bd init leaves behind.
    if not test -d .beads/embeddeddolt -o -d .beads/dolt -o -d .beads/proxieddb
        echo -e "$RED  ⚠️  No bd database found, skipping$NC"
        set skip_count (math $skip_count + 1)
        continue
    end

    # bd info reports the database and a count, but not the prefix, and
    # `bd config get issue-prefix` reads "(not set)" even where config.yaml
    # defines it. Read the file, then fall back to a real issue id.
    echo "  [1/4] Detecting prefix..."
    set -l prefix_output (grep -E '^issue-prefix:' .beads/config.yaml 2>/dev/null | head -1 | sed -E 's/^issue-prefix:[[:space:]]*//')
    if test -z "$prefix_output"
        set prefix_output (bd list --all --json 2>/dev/null | jq -r '.[0].id // ""' | sed -E 's/-[^-]+$//')
    end

    if test -z "$prefix_output"
        echo -e "$RED  ⚠️  Could not detect prefix, skipping$NC"
        set skip_count (math $skip_count + 1)
        continue
    end

    set -l prefix $prefix_output
    echo -e "$GREEN  ✓ Prefix: $prefix$NC"

    # Get issue count
    echo "  [2/4] Counting issues..."
    set -l issue_count (bd list --all --json 2>/dev/null | jq '. | length' 2>/dev/null)

    if test -z "$issue_count"
        set issue_count "unknown"
    end

    echo -e "$GREEN  ✓ Issues: $issue_count$NC"

    # Create .bv directory
    echo "  [3/4] Creating .bv directory..."
    mkdir -p .bv
    echo -e "$GREEN  ✓ Created .bv/$NC"

    # Create workspace.yml
    echo "  [4/4] Creating workspace.yml..."

    echo "# beads_viewer workspace configuration
# Generated automatically for bd (beads) repositories

# Project metadata
name: $project_name
description: beads workspace for $project_name

# Prefix only. bd keeps its database in .beads/embeddeddolt/, which is
# gitignored and which bv cannot read; bv reads the JSONL export below.
database:
  prefix: $prefix

# JSONL configuration. bd never refreshes this on its own, so it is only
# as current as the last 'bd export -o .beads/issues.jsonl'.
jsonl:
  path: .beads/issues.jsonl

# Display settings
display:
  max_title_length: 80
  show_closed: false
  group_by_status: true

# Priority labels
priority:
  labels:
    0: \"P0 - Critical\"
    1: \"P1 - High\"
    2: \"P2 - Medium\"
    3: \"P3 - Low\"
    4: \"P4 - Backlog\"

# Status labels
status:
  labels:
    open: \"Open\"
    in_progress: \"In Progress\"
    blocked: \"Blocked\"
    closed: \"Closed\"

# Type labels
type:
  labels:
    bug: \"🐛 Bug\"
    feature: \"✨ Feature\"
    task: \"📋 Task\"
    epic: \"🎯 Epic\"
    chore: \"🔧 Chore\"" > .bv/workspace.yml

    echo -e "$GREEN  ✓ Created workspace.yml$NC"

    # Add .bv to .gitignore if not already there
    if test -f .gitignore
        if not grep -q '^.bv/$' .gitignore
            echo ".bv/" >> .gitignore
            echo -e "$GREEN  ✓ Added .bv/ to .gitignore$NC"
        end
    else
        echo ".bv/" > .gitignore
        echo -e "$GREEN  ✓ Created .gitignore with .bv/$NC"
    end

    set success_count (math $success_count + 1)
    echo -e "$GREEN  ✅ Successfully configured$NC"
end

echo ""
echo "======================================"
echo "Summary"
echo "======================================"
echo -e "$GREEN  ✓ Successful: $success_count$NC"
echo -e "$YELLOW  ⊘ Skipped: $skip_count$NC"
echo -e "$RED  ✗ Failed: $fail_count$NC"
echo ""

if test $success_count -gt 0
    echo "You can now run 'bv' in any configured project!"
    echo ""
    echo "Example:"
    echo "  cd ~/Dev/health-data-warehouse"
    echo "  bv"
end
