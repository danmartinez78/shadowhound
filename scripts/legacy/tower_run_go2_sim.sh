#!/usr/bin/env bash
#
# tower_run_go2_sim.sh - Launch Go2 simulation on Tower
#
# This script is designed for the Tower setup created by sim_and_data_lake_setup.sh
# which installs Isaac Sim 4.5.0 via pip and Isaac Lab v2.1.0
#
# Usage:
#   cd ~/workspace/go2_omniverse
#   bash ~/shadowhound/scripts/tower_run_go2_sim.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

say() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die() { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }
ok() { echo -e "${GREEN}[✓]${NC} $*"; }

# Configuration
CONDA_ROOT="${HOME}/miniconda3"
ENV_NAME="env_isaaclab"
ROS_DISTRO="humble"
WORKSPACE_ROOT="${HOME}/workspace"
ISAAC_LAB_DIR="${WORKSPACE_ROOT}/IsaacLab"
GO2_OMNIVERSE_DIR="${WORKSPACE_ROOT}/go2_omniverse"

# Validation
say "Validating environment..."

# Check conda
if [[ ! -d "$CONDA_ROOT" ]]; then
  die "Miniconda not found at $CONDA_ROOT. Run sim_and_data_lake_setup.sh install"
fi

# Check conda env
# shellcheck source=/dev/null
source "$CONDA_ROOT/etc/profile.d/conda.sh"
if ! conda env list | grep -q "^${ENV_NAME}"; then
  die "Conda environment '$ENV_NAME' not found. Run sim_and_data_lake_setup.sh install"
fi

# Check ROS2
if [[ ! -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]]; then
  die "ROS 2 $ROS_DISTRO not installed. Run sim_and_data_lake_setup.sh install"
fi

# Check Isaac Lab
if [[ ! -d "$ISAAC_LAB_DIR" ]]; then
  die "Isaac Lab not found at $ISAAC_LAB_DIR. Run sim_and_data_lake_setup.sh install"
fi

# Check go2_omniverse
if [[ ! -d "$GO2_OMNIVERSE_DIR" ]]; then
  die "go2_omniverse not found at $GO2_OMNIVERSE_DIR"
fi

ok "Environment validation passed"

# Activate conda environment
say "Activating conda environment: $ENV_NAME"
conda activate "$ENV_NAME"

# Verify Isaac Sim is available
if ! python -c "import isaacsim" 2>/dev/null; then
  die "Isaac Sim not importable in conda env. Check installation."
fi

ok "Isaac Sim available in conda environment"

# Set environment variables
export ROS_DISTRO="$ROS_DISTRO"
export ISAAC_LAB_PATH="$ISAAC_LAB_DIR"

# Source ROS2
say "Sourcing ROS 2 $ROS_DISTRO"
# shellcheck source=/dev/null
source "/opt/ros/${ROS_DISTRO}/setup.bash"

# Check if ROS2 workspaces are built
ISAAC_WS="${GO2_OMNIVERSE_DIR}/IsaacSim-ros_workspaces/humble_ws"
GO2_WS="${GO2_OMNIVERSE_DIR}/go2_omniverse_ws"

if [[ ! -f "$ISAAC_WS/install/setup.bash" ]]; then
  warn "Isaac ROS workspace not built at $ISAAC_WS"
  warn "Building workspace (this may take a few minutes)..."
  
  cd "$ISAAC_WS"
  colcon build --symlink-install || die "Failed to build Isaac ROS workspace"
  ok "Isaac ROS workspace built"
fi

if [[ ! -f "$GO2_WS/install/setup.bash" ]]; then
  warn "Go2 ROS workspace not built at $GO2_WS"
  warn "Building workspace..."
  
  cd "$GO2_WS"
  colcon build --symlink-install || die "Failed to build Go2 ROS workspace"
  ok "Go2 ROS workspace built"
fi

# Source built workspaces
say "Sourcing ROS 2 workspaces..."
# shellcheck source=/dev/null
source "$ISAAC_WS/install/setup.bash"
# shellcheck source=/dev/null
source "$GO2_WS/install/setup.bash"

ok "ROS 2 workspaces sourced"

# Change to go2_omniverse directory
cd "$GO2_OMNIVERSE_DIR"

# Launch simulation
say "Launching Go2 simulation..."
say "Python script: $GO2_OMNIVERSE_DIR/go2_gym/standalone/go2_isaac.py"

# Run with Isaac Sim
python go2_gym/standalone/go2_isaac.py

say "Simulation closed."
