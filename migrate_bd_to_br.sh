#!/bin/bash
# migrate-beads-to-br.sh - Customized for Jason's setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
LOG_FILE="$HOME/beads-migration-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "======================================"
echo "beads → beads_rust Migration"
echo "Log: $LOG_FILE"
echo "======================================"
echo ""

# Verify br is installed
if ! command -v br &> /dev/null; then
    echo -e "${RED}Error: br not found.${NC}"
    exit 1
fi

echo -e "${BLUE}Using br: $(which br)${NC}"
echo -e "${BLUE}Version: $(br --version)${NC}"
echo ""

# Projects to migrate (your actual projects, excluding Claude caches)
PROJECTS=(
    "$HOME/local/src/fish_config"
    "$HOME/local/src/templeton-agentic-dev-workbench"
    "$HOME/local/src/jtemplet-superpowers"
    "$HOME/local/src/beads"
    "$HOME/local/src/jeffreysprompts.com"
    "$HOME/local/src/scripts"
    "$HOME/Dev/infra-builder"
    "$HOME/Dev/archive/randomtoast"
    "$HOME/Dev/bodyledger-ios"
    "$HOME/Dev/health-data-warehouse"
    "$HOME/Dev/jtemplet.github.com"
    "$HOME/Dev/compass"
)

migrate_project() {
    local PROJECT_PATH="$1"
    local PROJECT_NAME=$(basename "$PROJECT_PATH")
    
    echo ""
    echo "========================================="
    echo -e "${YELLOW}Migrating: $PROJECT_NAME${NC}"
    echo "Path: $PROJECT_PATH"
    echo "========================================="
    
    if [ ! -d "$PROJECT_PATH" ]; then
        echo -e "${RED}⚠️  Project not found, skipping${NC}"
        return 1
    fi
    
    if [ ! -d "$PROJECT_PATH/.beads" ]; then
        echo -e "${RED}⚠️  No .beads directory, skipping${NC}"
        return 1
    fi
    
    cd "$PROJECT_PATH"
    
    # Backup
    echo "[1/10] Creating backup..."
    if [ -d ".beads.backup" ]; then
        rm -rf ".beads.backup.old"
        mv ".beads.backup" ".beads.backup.old"
    fi
    cp -r .beads .beads.backup
    echo -e "${GREEN}✓ Backup: .beads.backup${NC}"
    
    # Snapshot with bd (while we still have it)
    echo "[2/10] Snapshotting with bd..."
    /opt/homebrew/bin/bd list --json > /tmp/bd_snapshot_$$.json 2>/dev/null || echo "[]" > /tmp/bd_snapshot_$$.json
    ORIGINAL_COUNT=$(jq '. | length' /tmp/bd_snapshot_$$.json 2>/dev/null || echo "0")
    echo "Original issues: $ORIGINAL_COUNT"
    
    # Check for worktrees
    echo "[3/10] Checking for beads-worktrees..."
    if [ -d ".git/beads-worktrees" ]; then
        echo -e "${YELLOW}⚠️  Found beads-worktrees (will be ignored by br)${NC}"
        find .git/beads-worktrees -type d -maxdepth 1 | tail -n +2 | sed 's|^|      - |'
        HAS_WORKTREES=true
    else
        echo "No worktrees"
        HAS_WORKTREES=false
    fi
    
    # Check for issues.jsonl
    echo "[4/10] Checking issues.jsonl..."
    if [ -f ".beads/issues.jsonl" ]; then
        JSONL_LINES=$(wc -l < .beads/issues.jsonl | tr -d ' ')
        JSONL_SIZE=$(ls -lh .beads/issues.jsonl | awk '{print $5}')
        echo "JSONL: $JSONL_LINES lines, $JSONL_SIZE"
    else
        echo -e "${RED}⚠️  No issues.jsonl found${NC}"
        return 1
    fi
    
    # Initialize br
    echo "[5/10] Initializing br..."
    br init 2>&1 | grep -E "Initialized|Created|Error" || true
    
    # Import issues
    echo "[6/10] Importing issues..."
    if br sync --import-only 2>&1 | grep -v "^$"; then
        echo -e "${GREEN}✓ Import completed${NC}"
    else
        echo -e "${RED}✗ Import had issues${NC}"
    fi
    
    # Verify
    echo "[7/10] Verifying migration..."
    MIGRATED_COUNT=$(br list --json 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
    echo "Migrated issues: $MIGRATED_COUNT"
    
    if [ "$ORIGINAL_COUNT" != "0" ] && [ "$ORIGINAL_COUNT" != "$MIGRATED_COUNT" ]; then
        DIFF=$((ORIGINAL_COUNT - MIGRATED_COUNT))
        if [ $DIFF -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Missing $DIFF issues (may be duplicates removed)${NC}"
        else
            echo -e "${YELLOW}⚠️  Got $((MIGRATED_COUNT - ORIGINAL_COUNT)) extra issues${NC}"
        fi
    else
        echo -e "${GREEN}✓ Counts match${NC}"
    fi
    
    # Test br functionality
    echo "[8/10] Testing br functionality..."
    READY_COUNT=$(br ready --json 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
    echo "Ready work: $READY_COUNT issues"
    
    # Clean up old bd artifacts
    echo "[9/10] Cleaning up bd artifacts..."
    rm -f .beads/bd.sock .beads/bd.pipe .beads/.exclusive-lock
    
    if [ "$HAS_WORKTREES" = true ]; then
        echo -e "${YELLOW}   Keeping .git/beads-worktrees for reference${NC}"
        echo -e "${YELLOW}   (br doesn't use worktrees - you now control git manually)${NC}"
    fi
    
    # Create/update .gitignore
    echo "[10/10] Updating .gitignore..."
    cat > .beads/.gitignore << 'EOF'
# beads_rust local files (do not commit)
beads.db
beads.db-*
bd.sock
bd.pipe
.exclusive-lock
EOF
    echo -e "${GREEN}✓ Created .beads/.gitignore${NC}"
    
    echo ""
    echo -e "${GREEN}✅ Migration complete: $PROJECT_NAME${NC}"
    echo "   Issues: $ORIGINAL_COUNT → $MIGRATED_COUNT"
    if [ "$HAS_WORKTREES" = true ]; then
        echo -e "   ${YELLOW}Had worktrees: Now ignored (manual git control)${NC}"
    fi
    echo ""
    
    rm -f /tmp/bd_snapshot_$$.json
    
    return 0
}

# Main loop
SUCCESSFUL=0
FAILED=0
SKIPPED=0

for PROJECT in "${PROJECTS[@]}"; do
    if migrate_project "$PROJECT"; then
        ((SUCCESSFUL++))
    else
        if [ -d "$PROJECT" ] && [ -d "$PROJECT/.beads" ]; then
            ((FAILED++))
        else
            ((SKIPPED++))
        fi
    fi
done

echo ""
echo "========================================="
echo "Migration Summary"
echo
