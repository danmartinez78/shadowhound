#!/bin/bash
# Quick script to update Tower's go2_omniverse to use danmartinez78 fork

set -e

echo "================================================"
echo "  Update Tower go2_omniverse to Fork"
echo "================================================"
echo ""

REPO_DIR="$HOME/workspace/go2_omniverse"

if [ ! -d "$REPO_DIR" ]; then
    echo "ERROR: $REPO_DIR does not exist"
    echo "Please run the full setup script first"
    exit 1
fi

echo "Updating go2_omniverse repository..."
cd "$REPO_DIR"

# Show current remote
echo ""
echo "Current remote:"
git remote -v | grep origin

# Update remote to your fork
echo ""
echo "Updating remote to danmartinez78/go2_omniverse..."
git remote set-url origin https://github.com/danmartinez78/go2_omniverse.git

# Verify
echo ""
echo "New remote:"
git remote -v | grep origin

# Fetch latest from fork
echo ""
echo "Fetching latest from fork..."
git fetch origin

# Checkout added_copter branch
echo ""
echo "Checking out added_copter branch..."
git checkout added_copter

# Pull latest changes
echo ""
echo "Pulling latest changes..."
git pull origin added_copter

# Update submodules
echo ""
echo "Updating submodules..."
git submodule update --init --recursive

echo ""
echo "✅ Successfully updated to danmartinez78/go2_omniverse fork!"
echo ""
echo "Branch: added_copter"
echo "Remote: https://github.com/danmartinez78/go2_omniverse.git"
echo ""
echo "You can now make changes and push to your fork."
