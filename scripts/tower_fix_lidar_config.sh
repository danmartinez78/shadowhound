#!/bin/bash
# Fix Unitree L1 LiDAR config for Isaac Lab v2.1.0
# Run on Tower: bash ~/shadowhound/scripts/tower_fix_lidar_config.sh
# 
# Based on go2_omniverse repo instructions:
# https://github.com/abizovnuralem/go2_omniverse

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

# Paths
GO2_ISAAC_SIM="$HOME/workspace/go2_omniverse/Isaac_sim"
ISAAC_SIM_BASE="$HOME/miniconda3/envs/env_isaaclab/lib/python3.10/site-packages/isaacsim"
SENSORS_RTX="$ISAAC_SIM_BASE/exts/isaacsim.sensors.rtx"

# Step 1: Replace extension.toml
say "Step 1: Replacing extension.toml..."

if [[ ! -f "$GO2_ISAAC_SIM/extension.toml" ]]; then
    warn "Source file not found: $GO2_ISAAC_SIM/extension.toml"
    exit 1
fi

if [[ ! -d "$SENSORS_RTX/config" ]]; then
    warn "Target directory not found: $SENSORS_RTX/config"
    exit 1
fi

# Backup original
if [[ -f "$SENSORS_RTX/config/extension.toml" ]] && [[ ! -f "$SENSORS_RTX/config/extension.toml.backup" ]]; then
    say "Backing up original extension.toml..."
    sudo cp "$SENSORS_RTX/config/extension.toml" "$SENSORS_RTX/config/extension.toml.backup"
    ok "Backup created"
fi

sudo cp -f "$GO2_ISAAC_SIM/extension.toml" "$SENSORS_RTX/config/extension.toml"
ok "extension.toml replaced"

# Step 2: Install Unitree_L1.json
say "Step 2: Installing Unitree_L1.json..."

LIDAR_CONFIG_SRC="$GO2_ISAAC_SIM/Unitree/Unitree_L1.json"
LIDAR_CONFIG_DIR="$SENSORS_RTX/data/lidar_configs/Unitree"

if [[ ! -f "$LIDAR_CONFIG_SRC" ]]; then
    warn "Source file not found: $LIDAR_CONFIG_SRC"
    exit 1
fi

# Create Unitree directory if it doesn't exist
if [[ ! -d "$LIDAR_CONFIG_DIR" ]]; then
    say "Creating directory: $LIDAR_CONFIG_DIR"
    sudo mkdir -p "$LIDAR_CONFIG_DIR"
fi

sudo cp -f "$LIDAR_CONFIG_SRC" "$LIDAR_CONFIG_DIR/Unitree_L1.json"
ok "Unitree_L1.json installed"

# Step 3: Clean up incorrectly placed files (from previous attempts)
say "Step 3: Cleaning up old incorrect files..."

WRONG_LOCATIONS=(
    "$ISAAC_SIM_BASE/extscache/omni.sensors.nv.common-2.5.0-coreapi+lx64.r.cp310/data/lidar/Unitree_L1.json"
    "$ISAAC_SIM_BASE/extscache/omni.sensors.nv.common-2.5.0-coreapi+lx64.r.cp310/data/lidar/Unitree_L1_old.json"
)

for file in "${WRONG_LOCATIONS[@]}"; do
    if [[ -f "$file" ]]; then
        say "Removing: $file"
        sudo rm -f "$file"
        ok "Removed"
    fi
done

# Verify
echo ""
say "Verifying installation..."

if [[ -f "$SENSORS_RTX/config/extension.toml" ]]; then
    ok "extension.toml: $SENSORS_RTX/config/extension.toml"
else
    warn "extension.toml not found!"
fi

if [[ -f "$LIDAR_CONFIG_DIR/Unitree_L1.json" ]]; then
    ok "Unitree_L1.json: $LIDAR_CONFIG_DIR/Unitree_L1.json"
else
    warn "Unitree_L1.json not found!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "LiDAR config fix complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Restart the simulation to use the new config:"
echo "  cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo ""
