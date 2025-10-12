#!/bin/bash
# Quick sync script to pull changes from GitHub to laptop host
# Run this ON THE LAPTOP HOST: /home/daniel/shadowhound/
#
# CRITICAL: This script is for PULLING changes only, never for making edits!
# DO NOT edit files in src/dimos-unitree/ - it's a git submodule

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ShadowHound Laptop Host Sync"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check we're on the laptop host
if [ ! -d "/home/daniel/shadowhound" ]; then
    echo "❌ This script must run on the laptop host at /home/daniel/shadowhound"
    echo "   You appear to be in a different environment"
    exit 1
fi

cd /home/daniel/shadowhound

echo "📍 Current location: $(pwd)"
echo ""

# Show current status
echo "1️⃣  Checking current status..."
git status --short

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo ""
    echo "⚠️  You have uncommitted changes on laptop host!"
    echo ""
    git status --short
    echo ""
    echo "Options:"
    echo "  1) Stash changes and continue (recommended)"
    echo "  2) Abort and let me commit manually"
    echo "  3) Discard all local changes (DANGEROUS)"
    echo ""
    read -p "Choose [1-3]: " choice
    
    case $choice in
        1)
            echo "📦 Stashing changes..."
            if git stash push -m "Auto-stash before sync at $(date)"; then
                echo "✅ Changes stashed"
                STASHED=true
            else
                echo "❌ Failed to stash"
                exit 1
            fi
            ;;
        2)
            echo "🛑 Aborting. Please commit or stash your changes first."
            echo ""
            echo "To stash: git stash"
            echo "To commit: git add . && git commit -m 'your message'"
            exit 0
            ;;
        3)
            echo "⚠️  WARNING: This will discard ALL local changes!"
            read -p "Are you absolutely sure? Type 'yes' to confirm: " confirm
            if [ "$confirm" = "yes" ]; then
                git reset --hard HEAD
                git clean -fd
                echo "✅ Local changes discarded"
            else
                echo "🛑 Aborted"
                exit 0
            fi
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
fi
echo ""

# Show current commit
echo "Current commit:"
git log -1 --oneline
echo ""

# Fetch latest
echo "2️⃣  Fetching latest from GitHub..."
git fetch origin
echo ""

# Pull main repo
echo "3️⃣  Pulling shadowhound updates..."
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "   Branch: $CURRENT_BRANCH"

if git pull origin "$CURRENT_BRANCH"; then
    echo "✅ Shadowhound updated"
else
    echo "⚠️  Pull failed - you may have uncommitted changes"
    echo ""
    git status
    exit 1
fi
echo ""

# Update submodules (including DIMOS)
echo "4️⃣  Updating submodules (including DIMOS)..."

# Stash submodule changes if any
cd src/dimos-unitree
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "   ⚠️  DIMOS submodule has uncommitted changes"
    if git stash push -m "Auto-stash DIMOS before sync at $(date)"; then
        echo "   📦 DIMOS changes stashed"
        DIMOS_STASHED=true
    fi
fi
cd ../..

if git submodule update --init --remote; then
    echo "✅ Submodules updated"
else
    echo "⚠️  Submodule update had issues"
fi

# Restore DIMOS stash if needed
if [ "$DIMOS_STASHED" = true ]; then
    cd src/dimos-unitree
    if git stash pop; then
        echo "   ✅ DIMOS changes restored"
    else
        echo "   ⚠️  DIMOS stash conflicts - run manually: cd src/dimos-unitree && git stash pop"
    fi
    cd ../..
fi
echo ""

# Check DIMOS submodule status
echo "5️⃣  DIMOS submodule status:"
cd src/dimos-unitree
echo "   Location: $(pwd)"
echo "   Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "   Commit: $(git log -1 --oneline)"
cd ../..
echo ""

# Clear Python cache
echo "6️⃣  Clearing Python cache..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
echo "✅ Python cache cleared"
echo ""

# Check if exception file has the fix
echo "7️⃣  Verifying DIMOS exception fix..."
EXCEPTION_FILE="src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py"
if grep -q "self.args\[0\]" "$EXCEPTION_FILE"; then
    echo "✅ DIMOS exception bug fix is present"
else
    echo "⚠️  DIMOS exception fix NOT found - file may need manual update"
    echo "   Expected: self.args[0] instead of self.message"
fi
echo ""

# Show new commit
echo "8️⃣  Updated to commit:"
git log -1 --oneline
echo ""

# Restore stashed changes if we stashed
if [ "$STASHED" = true ]; then
    echo "9️⃣  Restoring your stashed changes..."
    echo ""
    if git stash pop; then
        echo "✅ Changes restored"
        echo ""
        echo "⚠️  Note: Review for any merge conflicts!"
        git status --short
    else
        echo "⚠️  Conflicts while restoring stash!"
        echo "   Your changes are still in the stash"
        echo "   Run: git stash list"
        echo "   Then: git stash pop (after resolving conflicts)"
    fi
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sync complete!"
echo ""
echo "Next steps:"
echo "  1. Review changes above"
echo "  2. Run: ./start.sh"
echo "  3. Test mission agent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
