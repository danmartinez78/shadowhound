#!/bin/bash
# Quick sync script to pull changes from GitHub to laptop host
# Run this ON THE LAPTOP HOST: /home/daniel/shadowhound/

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
if git submodule update --init --remote; then
    echo "✅ Submodules updated"
else
    echo "⚠️  Submodule update had issues"
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

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sync complete!"
echo ""
echo "Next steps:"
echo "  1. Review changes above"
echo "  2. Run: ./start.sh"
echo "  3. Test mission agent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
