#!/bin/bash
# Setup script for go2_omniverse Isaac Sim environment on Tower
# Run this ONCE after sim_and_data_lake_setup.sh completes

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
say "🚀 Setting up go2_omniverse for Isaac Sim on Tower"
echo ""

# Check environment
if ! conda env list | grep -q env_isaaclab; then
    err "Isaac Lab environment not found. Run sim_and_data_lake_setup.sh first."
fi

# Activate environment
say "Activating Isaac Lab environment..."
eval "$(conda shell.bash hook)"
conda activate env_isaaclab || err "Failed to activate env_isaaclab"
ok "Isaac Lab environment active"

# Navigate to go2_omniverse
GO2_DIR="$HOME/workspace/go2_omniverse"
if [ ! -d "$GO2_DIR" ]; then
    err "go2_omniverse not found at $GO2_DIR"
fi
cd "$GO2_DIR" || err "Failed to cd to $GO2_DIR"

# Initialize git submodules (contains IsaacSim-ros_workspaces)
say "Initializing git submodules..."
git submodule update --init --recursive
ok "Submodules initialized"

# 1. Install required Python packages for ROS2 builds
say "Installing ROS2 build dependencies..."
# CRITICAL: Uninstall any existing empy first to avoid conflicts
pip uninstall -y empy 2>/dev/null || true
# Install exact versions required by ROS2 Humble
pip install empy==3.3.4 catkin_pkg lark
# Verify empy version
python3 -c "import em; print(f'empy version: {em.__version__}')" || err "empy installation failed"
ok "Build dependencies installed (empy 3.3.4 verified)"

# 2. Initialize rosdep
say "Configuring rosdep..."
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
    ok "rosdep initialized"
else
    ok "rosdep already initialized"
fi
rosdep update
ok "rosdep updated"

# 3. Source ROS2
say "Sourcing ROS2 Humble..."
source /opt/ros/humble/setup.bash || err "Failed to source ROS2"
ok "ROS2 sourced"

# 4. Build IsaacSim workspace
say "Building IsaacSim ROS2 workspace..."
cd IsaacSim-ros_workspaces/humble_ws || err "Workspace not found"
rosdep install --from-paths src --ignore-src -r -y || true
colcon build --symlink-install
ok "IsaacSim workspace built"
source install/setup.bash
cd ../..

# 5. Build go2_omniverse workspace
say "Building go2_omniverse workspace..."
cd go2_omniverse_ws || err "Workspace not found"
rosdep install --from-paths src --ignore-src -r -y || true
colcon build --symlink-install
ok "go2_omniverse workspace built"
source install/setup.bash
cd ..

# Verify
say "Verifying..."
if [ -f "IsaacSim-ros_workspaces/humble_ws/install/setup.bash" ] && [ -f "go2_omniverse_ws/install/setup.bash" ]; then
    ok "Both workspaces built successfully"
else
    warn "One or more workspaces may have issues"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎮 Launch: cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo "📝 Controls: W/A/S/D, ESC to exit"
echo ""
