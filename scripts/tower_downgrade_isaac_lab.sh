#!/bin/bash
# Downgrade Isaac Lab to v2.1.0 for go2_omniverse compatibility
# Run on Tower: bash ~/shadowhound/scripts/tower_downgrade_isaac_lab.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

say() { echo -e "${BLUE}==>${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
say "🔄 Downgrade Isaac Lab to v2.1.0 (go2_omniverse compatible)"
echo ""

# Check environment
if ! conda env list | grep -q env_isaaclab; then
    err "Isaac Lab environment not found"
fi

# Activate environment
say "Activating Isaac Lab environment..."
eval "$(conda shell.bash hook)"
conda activate env_isaaclab || err "Failed to activate env_isaaclab"
ok "Environment active"

# Check current version
say "Checking current Isaac Lab version..."
CURRENT_VERSION=$(python -c "import isaaclab; print(isaaclab.__version__)" 2>/dev/null || echo "unknown")
echo "Current version: $CURRENT_VERSION"

# Confirm downgrade
echo ""
warn "This will:"
warn "  1. Uninstall Isaac Lab 0.47.1"
warn "  2. Install Isaac Lab v2.1.0 (April 2025)"
warn "  3. Rebuild Isaac Lab extensions"
warn "  4. Take about 10-15 minutes"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    say "Cancelled by user"
    exit 0
fi

# Backup current installation marker
MARKER_DIR="$HOME/.config/robot-sim-install"
if [[ -f "$MARKER_DIR/isaac_lab_version.txt" ]]; then
    cp "$MARKER_DIR/isaac_lab_version.txt" "$MARKER_DIR/isaac_lab_version.backup"
    ok "Backed up version marker"
fi

# Navigate to Isaac Lab directory
cd ~/workspace/IsaacLab || err "IsaacLab directory not found"

# Save current branch/state
say "Saving current state..."
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# Fetch latest tags
say "Fetching Isaac Lab releases..."
git fetch --tags

# Checkout v2.1.0
say "Checking out Isaac Lab v2.1.0..."
git checkout v2.1.0 || err "Failed to checkout v2.1.0"
ok "Checked out v2.1.0"

# Reinstall Isaac Lab
say "Reinstalling Isaac Lab v2.1.0..."
./isaaclab.sh --install || err "Installation failed"
ok "Isaac Lab v2.1.0 installed"

# Verify version
say "Verifying installation..."
NEW_VERSION=$(python -c "import isaaclab; print(isaaclab.__version__)" 2>/dev/null || echo "unknown")
echo "New version: $NEW_VERSION"

if [[ "$NEW_VERSION" == "2.1.0" ]] || [[ "$NEW_VERSION" =~ ^2\.1\. ]]; then
    ok "Isaac Lab v2.1.0 installed successfully"
else
    warn "Version mismatch - got $NEW_VERSION, expected 2.1.0"
fi

# Update version marker
echo "v2.1.0" > "$MARKER_DIR/isaac_lab_version.txt"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "Downgrade complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Isaac Lab v2.1.0 is now installed (compatible with go2_omniverse)"
echo ""
echo "Next steps:"
echo "  1. Test Go2 simulation:"
echo "     cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo ""
echo "  2. If issues persist, check:"
echo "     python -c 'import rsl_rl; print(rsl_rl.__version__)'"
echo ""
echo "To restore latest version later:"
echo "  cd ~/workspace/IsaacLab"
echo "  git checkout main"
echo "  ./isaaclab.sh --install"
echo ""
