#!/bin/bash#!/bin/bash

# Fix Unitree L1 LiDAR config for Isaac Lab v2.1.0# Fix Unitree L1 LiDAR config for Isaac Lab v2.1.0

# Run on Tower: bash ~/shadowhound/scripts/tower_fix_lidar_config.sh# Run on Tower: bash ~/shadowhound/scripts/tower_fix_lidar_config.sh

# 

# Based on go2_omniverse repo instructions:set -e

# https://github.com/abizovnuralem/go2_omniverse

# Colors

set -eGREEN='\033[0;32m'

BLUE='\033[0;34m'

# ColorsYELLOW='\033[1;33m'

GREEN='\033[0;32m'NC='\033[0m'

BLUE='\033[0;34m'

YELLOW='\033[1;33m'say() { echo -e "${BLUE}==>${NC} $1"; }

NC='\033[0m'ok() { echo -e "${GREEN}✓${NC} $1"; }

warn() { echo -e "${YELLOW}⚠${NC} $1"; }

say() { echo -e "${BLUE}==>${NC} $1"; }

ok() { echo -e "${GREEN}✓${NC} $1"; }echo ""

warn() { echo -e "${YELLOW}⚠${NC} $1"; }say "🔧 Installing Unitree L1 LiDAR config for Isaac Sim"

echo ""

echo ""

say "🔧 Installing Unitree L1 LiDAR config for Isaac Sim"# Check if go2_omniverse LiDAR configs exist

echo ""LIDAR_DIR="$HOME/workspace/go2_omniverse/Isaac_sim/Unitree"

LIDAR_CONFIG_NEW="$LIDAR_DIR/Unitree_L1.json"

# PathsLIDAR_CONFIG_OLD="$LIDAR_DIR/Unitree_L1_old.json"

GO2_ISAAC_SIM="$HOME/workspace/go2_omniverse/Isaac_sim"

ISAAC_SIM_BASE="$HOME/miniconda3/envs/env_isaaclab/lib/python3.10/site-packages/isaacsim"if [[ ! -d "$LIDAR_DIR" ]]; then

SENSORS_RTX="$ISAAC_SIM_BASE/exts/isaacsim.sensors.rtx"    warn "Unitree LiDAR directory not found: $LIDAR_DIR"

    exit 1

# Step 1: Replace extension.tomlfi

say "Step 1: Replacing extension.toml..."

if [[ ! -f "$LIDAR_CONFIG_OLD" ]]; then

if [[ ! -f "$GO2_ISAAC_SIM/extension.toml" ]]; then    warn "Unitree_L1_old.json not found: $LIDAR_CONFIG_OLD"

    warn "Source file not found: $GO2_ISAAC_SIM/extension.toml"    exit 1

    exit 1fi

fi

say "Found LiDAR configs in: $LIDAR_DIR"

if [[ ! -d "$SENSORS_RTX/config" ]]; then

    warn "Target directory not found: $SENSORS_RTX/config"# Find Isaac Sim LiDAR config directory

    exit 1ISAAC_SIM_BASE="/home/$USER/miniconda3/envs/env_isaaclab/lib/python3.10/site-packages/isaacsim"

fi

# Try multiple possible paths (Isaac Sim structure varies by version)

# Backup originalLIDAR_PATHS=(

if [[ -f "$SENSORS_RTX/config/extension.toml" ]] && [[ ! -f "$SENSORS_RTX/config/extension.toml.backup" ]]; then    "$ISAAC_SIM_BASE/extscache/omni.sensors.nv.common-2.5.0-coreapi+lx64.r.cp310/data/lidar"

    say "Backing up original extension.toml..."    "$ISAAC_SIM_BASE/extscache/omni.sensors.nv.common-*/data/lidar"

    sudo cp "$SENSORS_RTX/config/extension.toml" "$SENSORS_RTX/config/extension.toml.backup"    "$ISAAC_SIM_BASE/exts/isaacsim.sensors.rtx/data/lidar_configs"

    ok "Backup created")

fi

TARGET_DIR=""

sudo cp -f "$GO2_ISAAC_SIM/extension.toml" "$SENSORS_RTX/config/extension.toml"for path in "${LIDAR_PATHS[@]}"; do

ok "extension.toml replaced"    # Expand glob

    for expanded in $path; do

# Step 2: Install Unitree_L1.json        if [[ -d "$expanded" ]]; then

say "Step 2: Installing Unitree_L1.json..."            TARGET_DIR="$expanded"

            break 2

LIDAR_CONFIG_SRC="$GO2_ISAAC_SIM/Unitree/Unitree_L1.json"        fi

LIDAR_CONFIG_DIR="$SENSORS_RTX/data/lidar_configs/Unitree"    done

done

if [[ ! -f "$LIDAR_CONFIG_SRC" ]]; then

    warn "Source file not found: $LIDAR_CONFIG_SRC"if [[ -z "$TARGET_DIR" ]]; then

    exit 1    warn "Could not find Isaac Sim LiDAR config directory"

fi    warn "Tried:"

    for path in "${LIDAR_PATHS[@]}"; do

# Create Unitree directory if it doesn't exist        warn "  $path"

if [[ ! -d "$LIDAR_CONFIG_DIR" ]]; then    done

    say "Creating directory: $LIDAR_CONFIG_DIR"    exit 1

    sudo mkdir -p "$LIDAR_CONFIG_DIR"fi

fi

say "Found LiDAR config directory: $TARGET_DIR"

sudo cp -f "$LIDAR_CONFIG_SRC" "$LIDAR_CONFIG_DIR/Unitree_L1.json"

ok "Unitree_L1.json installed"# Copy both Unitree L1 configs (old and new versions)

say "Installing Unitree_L1_old.json..."

# Verifysudo cp -f "$LIDAR_CONFIG_OLD" "$TARGET_DIR/Unitree_L1_old.json"

echo ""ok "Unitree_L1_old.json installed"

say "Verifying installation..."

say "Installing Unitree_L1.json..."

if [[ -f "$SENSORS_RTX/config/extension.toml" ]]; thensudo cp -f "$LIDAR_CONFIG_NEW" "$TARGET_DIR/Unitree_L1.json"

    ok "extension.toml: $SENSORS_RTX/config/extension.toml"ok "Unitree_L1.json installed"

else

    warn "extension.toml not found!"# Verify

fiif [[ -f "$TARGET_DIR/Unitree_L1_old.json" ]] && [[ -f "$TARGET_DIR/Unitree_L1.json" ]]; then

    ok "Both LiDAR configs installed successfully"

if [[ -f "$LIDAR_CONFIG_DIR/Unitree_L1.json" ]]; then    echo ""

    ok "Unitree_L1.json: $LIDAR_CONFIG_DIR/Unitree_L1.json"    echo "Installed configs:"

else    echo "  $TARGET_DIR/Unitree_L1_old.json"

    warn "Unitree_L1.json not found!"    echo "  $TARGET_DIR/Unitree_L1.json"

fielse

    warn "Installation may have failed - configs not found"

echo ""    exit 1

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"fi

ok "LiDAR config fix complete!"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"echo ""

echo ""echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Restart the simulation to use the new config:"ok "LiDAR config fix complete!"

echo "  cd ~/workspace/go2_omniverse && ./run_sim.sh"echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""echo ""

echo "Restart the simulation to use the new config:"
echo "  cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo ""
