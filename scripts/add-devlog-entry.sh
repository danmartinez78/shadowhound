#!/bin/bash
# ============================================================================
# ShadowHound DevLog Entry Helper
# ============================================================================
#
# This script helps create lightweight devlog entries for tracking development.
# For experimental/research work, it will guide you to create an experiment doc.
#
# Usage:
#   ./scripts/add-devlog-entry.sh
#   (Interactive prompts will guide you)
#
# New Pattern (Oct 14, 2025):
#   - Simple work → lightweight devlog entry (this script)
#   - Experimental work → experiment doc + devlog pointer (see experiments/README.md)
#
# ============================================================================

set -e

DEVLOG_FILE="docs/development/devlog.md"
EXPERIMENTS_DIR="docs/development/experiments"
TEMPLATE_FILE="$EXPERIMENTS_DIR/template_experiment.md"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}  📝 ShadowHound DevLog Entry Helper${NC}"
echo -e "${CYAN}============================================================================${NC}\n"

# Get today's date
TODAY=$(date +"%Y-%m-%d")
DAY_NAME=$(date +"%A")
DATE_SUFFIX=$(date +"%b%d_%Y" | tr '[:upper:]' '[:lower:]')

# Check if files exist
if [ ! -f "$DEVLOG_FILE" ]; then
    echo -e "${RED}Error: $DEVLOG_FILE not found!${NC}"
    exit 1
fi

echo -e "${GREEN}Creating entry for $TODAY ($DAY_NAME)${NC}\n"

# First, ask if this is experimental work
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Is this EXPERIMENTAL or RESEARCH-DRIVEN work?                     ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Experimental work includes:${NC}"
echo "  • Testing multiple approaches (e.g., trying 4 different LLM models)"
echo "  • Feature branch spanning multiple days with iteration"
echo "  • Extensive debugging or investigation"
echo "  • Need to document 'what we tried' not just 'what worked'"
echo ""
read -p "Is this experimental work? (y/n): " IS_EXPERIMENTAL
echo ""

if [ "$IS_EXPERIMENTAL" = "y" ] || [ "$IS_EXPERIMENTAL" = "Y" ]; then
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  For experimental work, you should create an EXPERIMENT DOC       ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Steps:${NC}"
    echo "  1. Create experiment doc: $EXPERIMENTS_DIR/{feature}_{topic}_${DATE_SUFFIX}.md"
    echo "  2. Use template: $TEMPLATE_FILE"
    echo "  3. Document: Context, Hypothesis, Experiments, Final Results"
    echo "  4. Return here to create lightweight devlog pointer"
    echo ""
    echo -e "${BLUE}See: $EXPERIMENTS_DIR/README.md for complete guide${NC}"
    echo ""
    echo -e "${YELLOW}Example experiment docs:${NC}"
    echo "  • local_llm_exploration_oct10_2025.md"
    echo "  • dimos_integration_oct05_2025.md"
    echo ""
    
    read -p "Create experiment doc filename (or Enter to skip): " EXP_FILENAME
    
    if [ -n "$EXP_FILENAME" ]; then
        EXP_PATH="$EXPERIMENTS_DIR/$EXP_FILENAME"
        if [ ! "$EXP_FILENAME" = *.md ]; then
            EXP_PATH="$EXP_PATH.md"
        fi
        
        if [ -f "$EXP_PATH" ]; then
            echo -e "${YELLOW}File already exists. Opening for editing...${NC}"
        else
            echo -e "${GREEN}Creating $EXP_PATH from template...${NC}"
            cp "$TEMPLATE_FILE" "$EXP_PATH"
            echo -e "${GREEN}✓ Created experiment doc${NC}"
        fi
        
        echo ""
        echo -e "${BLUE}Now opening experiment doc in your editor...${NC}"
        echo -e "${YELLOW}Edit the doc, then return here to create devlog pointer${NC}"
        echo ""
        read -p "Press Enter when ready to create devlog pointer..."
        
        EXPERIMENT_LINK="experiments/$EXP_FILENAME"
    else
        echo -e "${YELLOW}Skipping experiment doc creation.${NC}"
        echo -e "${YELLOW}Continuing with simple devlog entry...${NC}"
        echo ""
        EXPERIMENT_LINK=""
    fi
else
    EXPERIMENT_LINK=""
fi

# Activity type
echo -e "${BLUE}Activity Type:${NC}"
echo "  1) Feature       4) Documentation   7) Research"
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
    7) ACTIVITY_TYPE="Research" ;;
    8) ACTIVITY_TYPE="Refactor" ;;
    *) ACTIVITY_TYPE="Feature" ;;
esac

echo ""


# Time range (optional)
read -p "Time range (e.g., 'Evening' or '14:00-18:00') [Enter to skip]: " TIME_RANGE
echo ""

# Title
read -p "Activity title (brief description): " TITLE
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

# Brief description
read -p "Brief description (1-2 sentences of what was done): " DESCRIPTION
echo ""

# Key results (simplified, multi-line)
echo -e "${BLUE}Key results (press Enter twice when done):${NC}"
KEY_RESULTS=""
while IFS= read -r line; do
    [ -z "$line" ] && break
    KEY_RESULTS+="- $line\n"
done
echo ""

# Commits (required for completed work)
if [ "$STATUS" = "✅ Complete" ]; then
    read -p "Commit hashes (space-separated, e.g., 'abc123 def456'): " COMMITS
    if [ -z "$COMMITS" ]; then
        echo -e "${YELLOW}Warning: No commits provided${NC}"
    fi
else
    read -p "Commit hashes (space-separated) [Enter to skip]: " COMMITS
fi
echo ""

# Build the lightweight entry
ENTRY="### "
if [ -n "$TIME_RANGE" ]; then
    ENTRY+="$TIME_RANGE: "
fi
ENTRY+="$TITLE\n"
ENTRY+="**Type**: $ACTIVITY_TYPE\n"
ENTRY+="**Status**: $STATUS\n"

if [ -n "$EXPERIMENT_LINK" ]; then
    ENTRY+="**Experiment Doc**: [$EXPERIMENT_LINK]($EXPERIMENT_LINK)\n"
fi

ENTRY+="\n$DESCRIPTION\n\n"

if [ -n "$KEY_RESULTS" ]; then
    ENTRY+="**Key Results**:\n$KEY_RESULTS\n"
fi

if [ -n "$COMMITS" ]; then
    ENTRY+="**Commits**: "
    COMMIT_LIST=""
    for commit in $COMMITS; do
        if [ -z "$COMMIT_LIST" ]; then
            COMMIT_LIST="\`$commit\`"
        else
            COMMIT_LIST+=", \`$commit\`"
        fi
    done
    ENTRY+="$COMMIT_LIST\n"
fi

ENTRY+="\n---\n\n"

# Preview the entry
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}Preview:${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo ""
echo -e "${YELLOW}## $TODAY ($DAY_NAME)${NC}"
echo ""
echo -e "$ENTRY"
echo -e "${CYAN}============================================================================${NC}\n"

read -p "Add this entry to devlog? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${YELLOW}Entry cancelled${NC}"
    exit 0
fi

# Check if date header exists, if not we need to add it
NEEDS_DATE_HEADER=false
if ! grep -q "^## $TODAY ($DAY_NAME)" "$DEVLOG_FILE"; then
    NEEDS_DATE_HEADER=true
    echo -e "${BLUE}Note: Adding new date header for $TODAY${NC}"
fi

# Add entry to devlog
export ENTRY
export TODAY
export DAY_NAME
export NEEDS_DATE_HEADER
python3 - "$DEVLOG_FILE" <<'PYTHON'
import sys
from pathlib import Path
import os

devlog_path = Path(sys.argv[1])
entry = os.getenv("ENTRY")
today = os.getenv("TODAY")
day_name = os.getenv("DAY_NAME")
needs_date_header = os.getenv("NEEDS_DATE_HEADER") == "true"

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

# Skip the header/purpose section
insert_pos = front_matter_end + 1
while insert_pos < len(lines):
    line = lines[insert_pos].strip()
    if line.startswith('## 20') and ' (' in line:  # Found first date entry
        break
    insert_pos += 1

# Check if this date already exists
if needs_date_header:
    # Add date header + entry
    entry_lines = [f"## {today} ({day_name})", ""] + entry.split('\\n')
else:
    # Just add entry under existing date
    # Find the date header and add after it
    for i in range(insert_pos, len(lines)):
        if lines[i].strip() == f"## {today} ({day_name})":
            # Found the date, insert after it (skip blank line if present)
            insert_pos = i + 1
            if insert_pos < len(lines) and lines[insert_pos].strip() == '':
                insert_pos += 1
            break
    entry_lines = entry.split('\\n')

# Insert the entry
lines = lines[:insert_pos] + entry_lines + lines[insert_pos:]

# Write back
devlog_path.write_text('\n'.join(lines))
print(f"✓ Entry added to {devlog_path}")
PYTHON
unset ENTRY
unset TODAY
unset DAY_NAME
unset NEEDS_DATE_HEADER

echo -e "\n${GREEN}✓ Entry added to $DEVLOG_FILE${NC}\n"

# Ask if they want to commit
read -p "Commit changes? (y/n): " COMMIT_CHOICE
if [ "$COMMIT_CHOICE" = "y" ] || [ "$COMMIT_CHOICE" = "Y" ]; then
    FILES_TO_COMMIT="$DEVLOG_FILE"
    
    # If experiment doc was created, add it too
    if [ -n "$EXPERIMENT_LINK" ] && [ -f "$EXPERIMENTS_DIR/$EXPERIMENT_LINK" ]; then
        FILES_TO_COMMIT="$FILES_TO_COMMIT $EXPERIMENTS_DIR/$EXPERIMENT_LINK"
        echo -e "${BLUE}Including experiment doc in commit${NC}"
    fi
    
    git add $FILES_TO_COMMIT

    COMMIT_MSG="docs(devlog): $TITLE"
    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}✓ Changes committed${NC}"
else
    echo -e "${YELLOW}Changes not committed. Remember to commit manually!${NC}"
fi

echo -e "\n${GREEN}✓ Done!${NC}"
if [ -n "$EXPERIMENT_LINK" ]; then
    echo -e "${MAGENTA}Don't forget to fill in the experiment doc:${NC}"
    echo -e "  $EXPERIMENTS_DIR/$EXPERIMENT_LINK"
fi
echo -e "${BLUE}Pattern: Simple work → lightweight devlog, Experimental → experiment doc${NC}\n"
