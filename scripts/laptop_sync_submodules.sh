#!/bin/bash
# Sync laptop host after vcs → git submodules conversion
# Run this on the laptop host at /home/daniel/shadowhound/

set -e  # Exit on error

REPO_DIR="/home/daniel/shadowhound"
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}ShadowHound Laptop Sync - Git Submodules Conversion${NC}"
echo "================================================================"
echo ""

# Check we're in the right directory
if [ ! -f "$REPO_DIR/.git/config" ]; then
    echo -e "${RED}❌ Error: Not in shadowhound repository${NC}"
    echo "Expected: $REPO_DIR"
    echo "Please cd to the shadowhound directory first"
    exit 1
fi

cd "$REPO_DIR"
echo -e "${GREEN}✓${NC} Repository found: $(pwd)"
echo ""

# Step 1: Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BOLD}Step 1: Check current branch${NC}"
echo "Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "feature/local-llm-support" ]; then
    echo -e "${YELLOW}⚠${NC} Not on feature/local-llm-support branch"
    read -p "Switch to feature/local-llm-support? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout feature/local-llm-support
        echo -e "${GREEN}✓${NC} Switched to feature/local-llm-support"
    else
        echo -e "${RED}❌ Aborted - wrong branch${NC}"
        exit 1
    fi
fi
echo ""

# Step 2: Check for uncommitted changes
echo -e "${BOLD}Step 2: Check for uncommitted changes${NC}"
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠${NC} You have uncommitted changes:"
    git status --short
    echo ""
    read -p "Stash changes and continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git stash save "Pre-submodule-conversion stash $(date +%Y%m%d-%H%M%S)"
        echo -e "${GREEN}✓${NC} Changes stashed"
    else
        echo -e "${RED}❌ Aborted - please commit or stash changes first${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} No uncommitted changes"
fi
echo ""

# Step 3: Check for local DIMOS changes
echo -e "${BOLD}Step 3: Check DIMOS submodule state${NC}"
if [ -d "src/dimos-unitree/.git" ]; then
    cd src/dimos-unitree
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}⚠${NC} DIMOS has uncommitted changes:"
        git status --short
        echo ""
        echo "These will be discarded (per submodule policy - never edit submodules)"
        read -p "Discard DIMOS changes? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git reset --hard HEAD
            git clean -fd
            echo -e "${GREEN}✓${NC} DIMOS changes discarded"
        else
            echo -e "${RED}❌ Aborted - please resolve DIMOS changes manually${NC}"
            cd "$REPO_DIR"
            exit 1
        fi
    else
        echo -e "${GREEN}✓${NC} DIMOS has no uncommitted changes"
    fi
    cd "$REPO_DIR"
else
    echo -e "${YELLOW}⚠${NC} DIMOS not initialized yet (will be after pull)"
fi
echo ""

# Step 4: Pull latest changes
echo -e "${BOLD}Step 4: Pull latest changes from GitHub${NC}"
git pull origin feature/local-llm-support
echo -e "${GREEN}✓${NC} Pulled latest commits"
echo ""

# Step 5: Check for .gitmodules
echo -e "${BOLD}Step 5: Verify .gitmodules exists${NC}"
if [ -f ".gitmodules" ]; then
    echo -e "${GREEN}✓${NC} .gitmodules file present"
    echo ""
    echo "Contents:"
    cat .gitmodules
else
    echo -e "${RED}❌ Error: .gitmodules not found${NC}"
    echo "This means the conversion wasn't pulled correctly"
    exit 1
fi
echo ""

# Step 6: Sync and initialize submodules
echo -e "${BOLD}Step 6: Initialize git submodules${NC}"
echo "This will clone DIMOS and all nested submodules (Go2 SDK, WebRTC)..."
echo ""

# Sync URLs from .gitmodules
git submodule sync
echo -e "${GREEN}✓${NC} Submodule URLs synced"

# Initialize all submodules recursively
git submodule update --init --recursive
echo -e "${GREEN}✓${NC} Submodules initialized"
echo ""

# Step 7: Verify Go2 SDK packages
echo -e "${BOLD}Step 7: Verify Go2 SDK packages${NC}"
GO2_SDK_DIR="src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk"
if [ -d "$GO2_SDK_DIR" ]; then
    echo "Checking for required packages..."
    PACKAGES=(
        "go2_interfaces"
        "unitree_go"
        "go2_robot_sdk"
        "coco_detector"
        "lidar_processor"
        "lidar_processor_cpp"
        "speech_processor"
    )
    
    ALL_FOUND=true
    for pkg in "${PACKAGES[@]}"; do
        if [ -d "$GO2_SDK_DIR/$pkg" ]; then
            echo -e "${GREEN}✓${NC} $pkg"
        else
            echo -e "${RED}✗${NC} $pkg (MISSING)"
            ALL_FOUND=false
        fi
    done
    
    if [ "$ALL_FOUND" = true ]; then
        echo ""
        echo -e "${GREEN}✓${NC} All Go2 SDK packages present"
    else
        echo ""
        echo -e "${RED}❌ Some Go2 SDK packages missing${NC}"
        echo "Try: git submodule update --init --recursive --force"
        exit 1
    fi
else
    echo -e "${RED}❌ Go2 SDK directory not found${NC}"
    exit 1
fi
echo ""

# Step 8: Check submodule status
echo -e "${BOLD}Step 8: Check submodule status${NC}"
git submodule status
echo ""

# Step 9: Check Python dependencies
echo -e "${BOLD}Step 9: Check Python dependencies${NC}"
echo "Checking for embeddings packages..."

MISSING_DEPS=()
python3 -c "import chromadb" 2>/dev/null || MISSING_DEPS+=("chromadb")
python3 -c "import langchain_chroma" 2>/dev/null || MISSING_DEPS+=("langchain-chroma")
python3 -c "import sentence_transformers" 2>/dev/null || MISSING_DEPS+=("sentence-transformers")

if [ ${#MISSING_DEPS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All embeddings dependencies installed"
else
    echo -e "${YELLOW}⚠${NC} Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    read -p "Install missing dependencies? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pip install chromadb langchain-chroma sentence-transformers
        echo -e "${GREEN}✓${NC} Dependencies installed"
    else
        echo -e "${YELLOW}⚠${NC} Skipped - agent will use graceful fallback (works without RAG)"
    fi
fi
echo ""

# Step 10: Summary
echo "================================================================"
echo -e "${BOLD}${GREEN}✅ Laptop Sync Complete!${NC}"
echo "================================================================"
echo ""
echo "What changed:"
echo "  • Switched from vcs to git submodules"
echo "  • DIMOS is now at: src/dimos-unitree/ (git submodule)"
echo "  • Go2 SDK nested in DIMOS (automatic with --recursive)"
echo "  • shadowhound.repos deleted (no longer needed)"
echo ""
echo "Next steps:"
echo "  1. Clean build: rm -rf build/ install/ log/"
echo "  2. Build workspace: ./start.sh"
echo "  3. Test mission agent"
echo ""
echo "Documentation:"
echo "  • Submodule policy: docs/submodule_policy.md"
echo "  • Full sync guide: docs/laptop_sync_after_conversion.md"
echo "  • Conversion summary: CONVERSION_COMPLETE.md"
echo ""
echo -e "${YELLOW}Remember: Never edit files in src/dimos-unitree/ directly!${NC}"
echo "See docs/submodule_policy.md for details."
echo ""
