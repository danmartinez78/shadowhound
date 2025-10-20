#!/bin/bash
# Rollback the LiDAR config changes that broke Isaac Sim
# Run on Tower: bash ~/shadowhound/scripts/tower_rollback_lidar_config.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

say() { echo -e "${BLUE}==>${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

echo ""
error "Rolling back LiDAR config changes..."
echo ""

# Paths
ISAAC_SIM_BASE="$HOME/miniconda3/envs/env_isaaclab/lib/python3.10/site-packages/isaacsim"
SENSORS_RTX="$ISAAC_SIM_BASE/exts/isaacsim.sensors.rtx"

# Step 1: Restore original extension.toml
say "Step 1: Restoring original extension.toml..."

if [[ -f "$SENSORS_RTX/config/extension.toml.backup" ]]; then
    sudo cp -f "$SENSORS_RTX/config/extension.toml.backup" "$SENSORS_RTX/config/extension.toml"
    ok "Original extension.toml restored"
else
    warn "Backup not found: $SENSORS_RTX/config/extension.toml.backup"
    warn "You may need to reinstall Isaac Lab"
fi

# Step 2: Remove the Unitree config directory we created
say "Step 2: Removing Unitree LiDAR config directory..."

LIDAR_CONFIG_DIR="$SENSORS_RTX/data/lidar_configs/Unitree"

if [[ -d "$LIDAR_CONFIG_DIR" ]]; then
    sudo rm -rf "$LIDAR_CONFIG_DIR"
    ok "Removed: $LIDAR_CONFIG_DIR"
else
    warn "Directory doesn't exist: $LIDAR_CONFIG_DIR"
fi

# Step 3: Clean up any files in extscache
say "Step 3: Cleaning up extscache files..."

WRONG_LOCATIONS=(
    "$ISAAC_SIM_BASE/extscache/omni.sensors.nv.common-2.5.0-coreapi+lx64.r.cp310/data/lidar/Unitree_L1.json"
    "$ISAAC_SIM_BASE/extscache/omni.sensors.nv.common-2.5.0-coreapi+lx64.r.cp310/data/lidar/Unitree_L1_old.json"
)

for file in "${WRONG_LOCATIONS[@]}"; do
    if [[ -f "$file" ]]; then
        sudo rm -f "$file"
        ok "Removed: $file"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "Rollback complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
warn "The LiDAR sensor may not work correctly in the simulation."
echo "The simulation should now start without errors."
echo ""
echo "Try running the simulation:"
echo "  cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo ""
