#!/bin/bash
# Setup script for go2_omniverse Isaac Sim environment on Tower
# Run this ONCE after sim_and_data_lake_setup.sh completes
#
# This script:
# 1. Installs missing Python dependencies (empy)
# 2. Initializes rosdep for ROS2 package management
# 3. Builds IsaacSim ROS2 workspace
# 4. Builds go2_omniverse workspace with Go2 interfaces
#
# Usage:
#   On Tower: bash ~/shadowhound/scripts/tower_setup_go2_sim.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

say() { echo -e "${BLUE}==>${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
say "🚀 Setting up go2_omniverse for Isaac Sim on Tower"
echo ""

# Check we're on Tower (has Isaac Lab installed)
if ! conda env list | grep -q env_isaaclab; then
    err "Isaac Lab environment not found. Run sim_and_data_lake_setup.sh first."
fi

# Activate Isaac Lab environment
say "Activating Isaac Lab environment..."
eval "$(conda shell.bash hook)"
conda activate env_isaaclab || err "Failed to activate env_isaaclab"
ok "Isaac Lab environment active"

# Navigate to go2_omniverse
GO2_DIR="$HOME/workspace/go2_omniverse"
if [ ! -d "$GO2_DIR" ]; then
    err "go2_omniverse not found at $GO2_DIR. Installation incomplete?"
fi
cd "$GO2_DIR" || err "Failed to cd to $GO2_DIR"

# 1. Install missing Python package (em - empy templating)
echo "📦 Installing missing Python package 'empy==3.3.4'..."
pip install 'empy==3.3.4'# 2. Initialize rosdep if needed
say "Configuring rosdep..."
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
    ok "rosdep initialized"
else
    ok "rosdep already initialized"
fi
rosdep update --quiet
ok "rosdep updated"

# 3. Source ROS2 Humble
say "Sourcing ROS2 Humble..."
source /opt/ros/humble/setup.bash || err "Failed to source ROS2"
ok "ROS2 Humble sourced"

# 4. Build IsaacSim-ros_workspaces (ROS2 bridge packages)
say "Building IsaacSim ROS2 workspace..."
cd IsaacSim-ros_workspaces/humble_ws || err "IsaacSim workspace not found"

rosdep install --from-paths src --ignore-src -r -y --quiet 2>&1 | grep -v "^#" || true

if colcon build --symlink-install 2>&1 | tee /tmp/go2_build_isaac_ws.log; then
    ok "IsaacSim ROS2 workspace built successfully"
else
    err "Failed to build IsaacSim workspace. Check /tmp/go2_build_isaac_ws.log"
fi

source install/setup.bash
cd ../.. || err "Failed to return to go2_omniverse root"

# 5. Build go2_omniverse_ws (Go2 interfaces)
say "Building go2_omniverse workspace..."
cd go2_omniverse_ws || err "go2_omniverse_ws not found"

rosdep install --from-paths src --ignore-src -r -y --quiet 2>&1 | grep -v "^#" || true

if colcon build --symlink-install 2>&1 | tee /tmp/go2_build_go2_ws.log; then
    ok "go2_omniverse workspace built successfully"
else
    err "Failed to build go2_omniverse workspace. Check /tmp/go2_build_go2_ws.log"
fi

source install/setup.bash
cd .. || err "Failed to return to go2_omniverse root"

# Verify builds
say "Verifying builds..."
if [ -f "IsaacSim-ros_workspaces/humble_ws/install/setup.bash" ]; then
    ok "IsaacSim workspace install found"
else
    warn "IsaacSim workspace install not found"
fi

if [ -f "go2_omniverse_ws/install/setup.bash" ]; then
    ok "go2_omniverse workspace install found"
else
    warn "go2_omniverse workspace install not found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎮 To launch Go2 simulation:"
echo "   cd ~/workspace/go2_omniverse"
echo "   ./run_sim.sh"
echo ""
echo "📝 Controls:"
echo "   W/A/S/D - Move the robot"
echo "   ESC     - Exit simulation"
echo ""
echo "📚 Documentation:"
echo "   ~/shadowhound/docs/deployment/tower_go2_isaac_sim_quickstart.md"
echo ""
