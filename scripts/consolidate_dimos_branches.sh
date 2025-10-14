#!/bin/bash
# Consolidate divergent DIMOS branches
# Rebases fix/webrtc-instant-commands-and-progress onto dev

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}DIMOS Branch Consolidation${NC}"
echo "=========================================="
echo ""
echo "This script will:"
echo "  1. Rebase fix/webrtc-instant-commands-and-progress onto dev"
echo "  2. Resolve conflicts (tokenizer, logger)"
echo "  3. Create consolidated branch with all fixes"
echo ""
echo -e "${YELLOW}WARNING: This modifies git history!${NC}"
echo "A backup branch will be created first."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

# Must be run from ShadowHound submodule directory
if [ ! -d ".git" ] || [ ! -f "../../../.gitmodules" ]; then
    echo -e "${RED}❌ Error: Must run from src/dimos-unitree/ directory${NC}"
    echo "Usage: cd /workspaces/shadowhound/src/dimos-unitree && bash consolidate.sh"
    exit 1
fi

echo ""
echo -e "${BOLD}Step 1: Create backup branch${NC}"
git branch backup-fix-webrtc-$(date +%Y%m%d-%H%M%S) fix/webrtc-instant-commands-and-progress
echo -e "${GREEN}✓${NC} Backup created"
echo ""

echo -e "${BOLD}Step 2: Fetch latest from origin${NC}"
git fetch origin
echo -e "${GREEN}✓${NC} Fetched"
echo ""

echo -e "${BOLD}Step 3: Checkout fix/webrtc branch${NC}"
git checkout fix/webrtc-instant-commands-and-progress
echo -e "${GREEN}✓${NC} On fix/webrtc-instant-commands-and-progress"
echo ""

echo -e "${BOLD}Step 4: Begin rebase onto dev${NC}"
echo "This may require conflict resolution..."
echo ""

if git rebase origin/dev; then
    echo ""
    echo -e "${GREEN}✓${NC} Rebase completed successfully (no conflicts)"
else
    echo ""
    echo -e "${YELLOW}⚠ Conflicts detected${NC}"
    echo ""
    echo "Common conflicts and resolutions:"
    echo ""
    echo "1. ${BOLD}Tokenizer conflict${NC} (dimos/agents/openai_agent.py)"
    echo "   Resolution: Keep dev's tokenizer factory, remove fix/webrtc's fallback"
    echo ""
    echo "2. ${BOLD}Logger conflict${NC}"
    echo "   Resolution: Keep dev's module-level logger"
    echo ""
    echo "3. ${BOLD}Navigation skills${NC}"
    echo "   Resolution: Keep full skill set (remove temp reduction)"
    echo ""
    echo "To resolve:"
    echo "  1. Edit conflicted files (shown above)"
    echo "  2. git add <resolved-files>"
    echo "  3. git rebase --continue"
    echo ""
    echo "To abort:"
    echo "  git rebase --abort"
    echo ""
    echo "After resolving conflicts, re-run this script to continue"
    exit 1
fi

echo ""
echo -e "${BOLD}Step 5: Interactive rebase to clean history${NC}"
echo "Remove temp commits (e73cc86: skill reduction)"
echo ""
read -p "Run interactive rebase to clean history? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "In the editor:"
    echo "  - Change 'pick' to 'drop' for: e73cc86 (Temp: Reduce to 5 nav2 skills)"
    echo "  - Change 'pick' to 'reword' to improve any commit messages"
    echo "  - Save and exit"
    echo ""
    git rebase -i origin/dev
fi

echo ""
echo -e "${BOLD}Step 6: Push consolidated branch${NC}"
echo "This requires force push (history was rewritten)"
echo ""
read -p "Push to origin? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin fix/webrtc-instant-commands-and-progress --force-with-lease
    echo -e "${GREEN}✓${NC} Pushed to origin"
else
    echo -e "${YELLOW}⚠${NC} Skipped push - you can push later with:"
    echo "  git push origin fix/webrtc-instant-commands-and-progress --force-with-lease"
fi

echo ""
echo "=========================================="
echo -e "${BOLD}${GREEN}✅ Consolidation Complete!${NC}"
echo "=========================================="
echo ""
echo "What was done:"
echo "  • Rebased fix/webrtc onto dev"
echo "  • Resolved conflicts (if any)"
echo "  • Cleaned commit history"
echo "  • Pushed consolidated branch"
echo ""
echo "Next steps:"
echo "  1. Test the consolidated branch"
echo "  2. Update ShadowHound submodule pointer"
echo "  3. Submit PR to upstream DIMOS"
echo ""
echo "Backup branch: backup-fix-webrtc-YYYYMMDD-HHMMSS"
echo "Restore with: git checkout backup-fix-webrtc-YYYYMMDD-HHMMSS"
echo ""
