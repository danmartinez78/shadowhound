#!/bin/bash
# ============================================================================
# ShadowHound DevLog Entry Helper
# ============================================================================
#
# This script helps create structured devlog entries for tracking development
# activities. Agents and developers should use this after completing work.
#
# Usage:
#   ./scripts/add-devlog-entry.sh
#   (Interactive prompts will guide you)
#
# ============================================================================

set -e

DEVLOG_FILE="docs/development/devlog.md"
RECENT_WORK_FILE="docs/development/recent_work.md"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}  📝 ShadowHound DevLog Entry Helper${NC}"
echo -e "${CYAN}============================================================================${NC}\n"

# Get today's date
TODAY=$(date +"%Y-%m-%d")
DAY_NAME=$(date +"%A")

# Check if files exist
if [ ! -f "$DEVLOG_FILE" ]; then
    echo -e "${RED}Error: $DEVLOG_FILE not found!${NC}"
    echo -e "Please create the devlog file first."
    exit 1
fi

# Prompt for entry details
echo -e "${GREEN}Creating devlog entry for $TODAY ($DAY_NAME)${NC}\n"

# Activity type
echo -e "${BLUE}Activity Type:${NC}"
echo "  1) Feature       4) Documentation   7) Testing"
echo "  2) Fix           5) Infrastructure  8) Refactor"
echo "  3) Integration   6) Configuration"
read -p "Select type [1-8]: " TYPE_NUM

case $TYPE_NUM in
    1) ACTIVITY_TYPE="Feature" ;;
    2) ACTIVITY_TYPE="Fix" ;;
    3) ACTIVITY_TYPE="Integration" ;;
    4) ACTIVITY_TYPE="Documentation" ;;
    5) ACTIVITY_TYPE="Infrastructure" ;;
    6) ACTIVITY_TYPE="Configuration" ;;
    7) ACTIVITY_TYPE="Testing" ;;
    8) ACTIVITY_TYPE="Refactor" ;;
    *) ACTIVITY_TYPE="Feature" ;;
esac

echo ""

# Time range (optional)
read -p "Time range (e.g., '14:00-18:00') [Enter to skip]: " TIME_RANGE
echo ""

# Title
read -p "Activity title (e.g., 'DIMOS Integration Merge'): " TITLE
if [ -z "$TITLE" ]; then
    echo -e "${RED}Error: Title is required${NC}"
    exit 1
fi
echo ""

# Status
echo -e "${BLUE}Status:${NC}"
echo "  1) ✅ Complete"
echo "  2) 🔄 In Progress"
echo "  3) ⚠️  Blocked"
read -p "Select status [1-3]: " STATUS_NUM

case $STATUS_NUM in
    1) STATUS="✅ Complete" ;;
    2) STATUS="🔄 In Progress" ;;
    3) STATUS="⚠️ Blocked" ;;
    *) STATUS="✅ Complete" ;;
esac

echo ""

# Impact
read -p "Impact (what changed, why it matters): " IMPACT
echo ""

# Activities (multi-line)
echo -e "${BLUE}Activities (press Enter twice when done):${NC}"
ACTIVITIES=""
while IFS= read -r line; do
    [ -z "$line" ] && break
    ACTIVITIES+="- $line\n"
done
echo ""

# Commits (optional)
read -p "Commit hashes (space-separated) [Enter to skip]: " COMMITS
echo ""

# PR/Issue (optional)
read -p "PR or Issue number (e.g., '#21' or 'PR#21') [Enter to skip]: " PR_ISSUE
echo ""

# Files (optional, multi-line)
echo -e "${BLUE}Files created/updated [Enter twice when done]:${NC}"
FILES=""
while IFS= read -r line; do
    [ -z "$line" ] && break
    FILES+="- \`$line\`\n"
done
echo ""

# Decisions (optional)
read -p "Key decisions made [Enter to skip]: " DECISIONS
echo ""

# Discoveries (optional)
read -p "Discoveries or learnings [Enter to skip]: " DISCOVERIES
echo ""

# Notes (optional)
read -p "Additional notes [Enter to skip]: " NOTES
echo ""

# Build the entry
ENTRY="## $TODAY ($DAY_NAME)\n\n"
ENTRY+="### "
if [ -n "$TIME_RANGE" ]; then
    ENTRY+="$TIME_RANGE: "
fi
ENTRY+="$TITLE\n"
ENTRY+="**Type**: $ACTIVITY_TYPE  \n"

if [ -n "$PR_ISSUE" ]; then
    ENTRY+="**PR/Issue**: $PR_ISSUE  \n"
fi

ENTRY+="**Status**: $STATUS  \n"
ENTRY+="**Impact**: $IMPACT\n\n"

if [ -n "$ACTIVITIES" ]; then
    ENTRY+="**Activities**:\n$ACTIVITIES\n"
fi

if [ -n "$COMMITS" ]; then
    ENTRY+="**Commits**: \n"
    for commit in $COMMITS; do
        ENTRY+="- \`$commit\`\n"
    done
    ENTRY+="\n"
fi

if [ -n "$FILES" ]; then
    ENTRY+="**Files Created/Updated**:\n$FILES\n"
fi

if [ -n "$DECISIONS" ]; then
    ENTRY+="**Decisions**:\n- $DECISIONS\n\n"
fi

if [ -n "$DISCOVERIES" ]; then
    ENTRY+="**Discoveries**:\n- $DISCOVERIES\n\n"
fi

if [ -n "$NOTES" ]; then
    ENTRY+="**Notes**: $NOTES\n\n"
fi

ENTRY+="---\n\n"

# Preview the entry
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}Preview:${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo -e "$ENTRY"
echo -e "${CYAN}============================================================================${NC}\n"

read -p "Add this entry to devlog? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${YELLOW}Entry cancelled${NC}"
    exit 0
fi

# Add entry to devlog (at the top, after front-matter)
# Find the line after the first "---" block (YAML front-matter)
export ENTRY
python3 - "$DEVLOG_FILE" <<'PYTHON'
import sys
from pathlib import Path
import os

devlog_path = Path(sys.argv[1])
entry = os.getenv("ENTRY")

content = devlog_path.read_text()
lines = content.split('\n')

# Find the end of YAML front-matter (second "---")
front_matter_end = -1
dash_count = 0
for i, line in enumerate(lines):
    if line.strip() == '---':
        dash_count += 1
        if dash_count == 2:
            front_matter_end = i
            break

if front_matter_end == -1:
    print("Error: Could not find end of YAML front-matter", file=sys.stderr)
    sys.exit(1)

# Insert entry after front-matter and any initial headers/text before first date entry
insert_pos = front_matter_end + 1

# Skip blank lines and headers until we find a date entry (## YYYY-MM-DD)
while insert_pos < len(lines):
    line = lines[insert_pos].strip()
    if line.startswith('## 20') and ' (' in line:  # Date entry like "## 2025-10-13 (Sunday)"
        break
    insert_pos += 1

# Insert the new entry
entry_lines = entry.split('\\n')
lines = lines[:insert_pos] + entry_lines + lines[insert_pos:]

# Write back
devlog_path.write_text('\n'.join(lines))
print(f"✓ Entry added to {devlog_path}")
PYTHON
unset ENTRY

echo -e "\n${GREEN}✓ Entry added to $DEVLOG_FILE${NC}\n"

# Ask if they want to commit
read -p "Commit changes? (y/n): " COMMIT_CHOICE
if [ "$COMMIT_CHOICE" = "y" ] || [ "$COMMIT_CHOICE" = "Y" ]; then
    git add "$DEVLOG_FILE"
    
    # Update recent_work.md if it exists and this is a major change
    if [ -f "$RECENT_WORK_FILE" ] && [ "$STATUS" = "✅ Complete" ]; then
        echo -e "${BLUE}This looks like a major completion. Update recent_work.md? (y/n):${NC}"
        read -p "> " UPDATE_RECENT
        if [ "$UPDATE_RECENT" = "y" ] || [ "$UPDATE_RECENT" = "Y" ]; then
            git add "$RECENT_WORK_FILE"
            echo -e "${YELLOW}Note: Please manually update $RECENT_WORK_FILE with this entry${NC}"
        fi
    fi

    COMMIT_MSG="docs(devlog): $TITLE"
    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}✓ Changes committed${NC}"
else
    echo -e "${YELLOW}Changes not committed. Remember to commit manually!${NC}"
fi

echo -e "\n${GREEN}✓ Done!${NC}"
echo -e "${BLUE}Tip: Agents should run this after completing any significant work${NC}\n"
