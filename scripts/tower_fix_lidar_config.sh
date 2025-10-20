#!/bin/bash
# Fix Unitree L1 LiDAR config for Isaac Lab v2.1.0
# Run on Tower: bash ~/shadowhound/scripts/tower_fix_lidar_config.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

say() { echo -e "${BLUE}==>${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

echo ""
say "🔧 Installing Unitree L1 LiDAR config for Isaac Sim"
echo ""

# Check if go2_omniverse LiDAR config exists (correct location)
LIDAR_CONFIG="$HOME/workspace/go2_omniverse/Isaac_sim/Unitree/L1.json"

if [[ ! -f "$LIDAR_CONFIG" ]]; then
    warn "Unitree L1 config not found in go2_omniverse"
    warn "Expected: $LIDAR_CONFIG"
    warn "Trying alternate locations..."
    
    # Try alternate locations
    if [[ -f "$HOME/workspace/go2_omniverse/repifis/l1.json" ]]; then
        LIDAR_CONFIG="$HOME/workspace/go2_omniverse/repifis/l1.json"
        ok "Found config at: $LIDAR_CONFIG"
    else
        warn "Could not find L1.json in any known location"
        exit 1
    fi
fi

say "Using LiDAR config: $LIDAR_CONFIG"

# Find Isaac Sim LiDAR config directory
ISAAC_SIM_BASE="/home/$USER/miniconda3/envs/env_isaaclab/lib/python3.10/site-packages/isaacsim"

# Try multiple possible paths (Isaac Sim structure varies by version)
LIDAR_PATHS=(
    "$ISAAC_SIM_BASE/extscache/omni.sensors.nv.common-2.5.0-coreapi+lx64.r.cp310/data/lidar"
    "$ISAAC_SIM_BASE/extscache/omni.sensors.nv.common-*/data/lidar"
    "$ISAAC_SIM_BASE/exts/isaacsim.sensors.rtx/data/lidar_configs"
)

TARGET_DIR=""
for path in "${LIDAR_PATHS[@]}"; do
    # Expand glob
    for expanded in $path; do
        if [[ -d "$expanded" ]]; then
            TARGET_DIR="$expanded"
            break 2
        fi
    done
done

if [[ -z "$TARGET_DIR" ]]; then
    warn "Could not find Isaac Sim LiDAR config directory"
    warn "Tried:"
    for path in "${LIDAR_PATHS[@]}"; do
        warn "  $path"
    done
    exit 1
fi

say "Found LiDAR config directory: $TARGET_DIR"

# Copy Unitree L1 config
say "Installing Unitree_L1.json..."
sudo cp -f "$LIDAR_CONFIG" "$TARGET_DIR/Unitree_L1.json"
ok "Unitree_L1.json installed"

# Verify
if [[ -f "$TARGET_DIR/Unitree_L1.json" ]]; then
    ok "LiDAR config installed successfully"
    echo ""
    echo "Config location: $TARGET_DIR/Unitree_L1.json"
else
    warn "Installation may have failed - config not found"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "LiDAR config fix complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Restart the simulation to use the new config:"
echo "  cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo ""
