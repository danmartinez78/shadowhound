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
# CRITICAL: ROS2 uses system Python, not conda Python!
# But when conda env is active, it uses conda Python which searches system packages.
# We need empy in BOTH the conda env AND system Python to be safe.

say "Installing into system Python (ROS2 requirement)..."
sudo /usr/bin/python3 -m pip uninstall -y empy 2>/dev/null || true
sudo /usr/bin/python3 -m pip install empy==3.3.4
/usr/bin/python3 -c "import em; print(f'System Python empy: {em.__version__}')" || err "System empy installation failed"
ok "System Python: empy 3.3.4 installed"

# Also install into conda env (which is what colcon actually calls)
say "Installing into conda environment..."
pip uninstall -y empy 2>/dev/null || true
pip install empy==3.3.4 catkin_pkg lark

# Check for multiple empy installations
say "Checking for multiple empy installations..."
python3 -c "import em; print(f'empy version: {em.__version__}, location: {em.__file__}')"

# The issue: Isaac Lab may have installed empy 0.4.0 or 4.x somewhere
# We need to find and remove ALL other empy installations
say "Searching for conflicting empy installations..."
find $CONDA_PREFIX -name "em.py" -o -name "empy*" 2>/dev/null | grep -v "__pycache__" | grep -v ".pyc" || true

# Nuclear option: pip uninstall ALL empy variants and reinstall
say "Force reinstalling empy (removing all variants)..."
pip uninstall -y empy em empy-stubs 2>/dev/null || true
pip install --force-reinstall --no-deps empy==3.3.4
pip install catkin_pkg lark

python3 -c "import em; print(f'Conda Python empy: {em.__version__}')" || err "Conda empy installation failed"
ok "Conda environment: empy 3.3.4 + build tools installed"

# Install tf_transformations for go2_omniverse
say "Installing tf_transformations for simulation..."
pip install transforms3d
ok "tf_transformations installed"

# Verify the conda Python can actually import empy with correct version
say "Verifying empy is accessible..."
python3 -c "import em; assert hasattr(em, 'Interpreter'), 'Wrong empy version!'" || err "empy verification failed - wrong version!"
ok "empy 3.3.4 verified and accessible"

# Clean any previous failed builds
say "Cleaning previous build artifacts..."
rm -rf IsaacSim-ros_workspaces/humble_ws/build IsaacSim-ros_workspaces/humble_ws/install
rm -rf go2_omniverse_ws/build go2_omniverse_ws/install
ok "Build directories cleaned"

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
