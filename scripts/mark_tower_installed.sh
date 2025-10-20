#!/usr/bin/env bash
# Create marker files for existing Tower Isaac Sim installation
# This tells sim_and_data_lake_setup.sh to skip reinstalling working components

set -euo pipefail

MARKER_DIR="$HOME/.go2_stack_state"
mkdir -p "$MARKER_DIR"

echo "=== Creating marker files for existing installation ==="

# Base tools (apt packages already installed)
touch "$MARKER_DIR/base_tools_installed"
echo "✓ base_tools_installed"

# Dev tools (already have build-essential, git, etc)
touch "$MARKER_DIR/dev_tools_installed"
echo "✓ dev_tools_installed"

# NVIDIA driver (580.95.05 validated working)
touch "$MARKER_DIR/nvidia_driver_checked"
echo "✓ nvidia_driver_checked"

# Docker + NVIDIA runtime (already installed)
touch "$MARKER_DIR/docker_nvidia_installed"
echo "✓ docker_nvidia_installed"

# ROS2 Humble (complete workspace builds)
if [[ -f "/opt/ros/humble/setup.bash" ]]; then
    touch "$MARKER_DIR/ros2_installed"
    echo "✓ ros2_installed"
else
    echo "⚠ ROS2 not found at /opt/ros/humble - skipping marker"
fi

# Conda env site-packages path (needed for Isaac Lab detection)
if conda info --envs | grep -q env_isaaclab; then
    env_site=$(conda run -n env_isaaclab python3 -c "import site; print(site.getsitepackages()[0])" 2>/dev/null || echo "")
    if [[ -n "$env_site" ]]; then
        echo "$env_site" > "$MARKER_DIR/env_site.txt"
        echo "✓ env_site.txt: $env_site"
    fi
fi

# Isaac Lab (source install at ~/workspace/IsaacLab)
# Check for Isaac Lab directory and common files (setup.py, pyproject.toml, or source/ dir)
if [[ -d "$HOME/workspace/IsaacLab" ]] && \
   ( [[ -f "$HOME/workspace/IsaacLab/setup.py" ]] || \
     [[ -f "$HOME/workspace/IsaacLab/pyproject.toml" ]] || \
     [[ -d "$HOME/workspace/IsaacLab/source" ]] || \
     [[ -d "$HOME/workspace/IsaacLab/_isaac_sim" ]] ); then
    touch "$MARKER_DIR/isaac_lab_cloned"
    echo "✓ isaac_lab_cloned"
else
    echo "⚠ IsaacLab not found at ~/workspace/IsaacLab - skipping marker"
fi

# go2_omniverse (already cloned)
if [[ -d "$HOME/workspace/go2_omniverse" ]]; then
    touch "$MARKER_DIR/go2_omniverse_cloned"
    echo "✓ go2_omniverse_cloned"
else
    echo "⚠ go2_omniverse not found - skipping marker"
fi

# Go2 ROS2 workspaces built
if [[ -d "$HOME/workspace/go2_omniverse/go2_ros2_sdk/install" ]]; then
    touch "$MARKER_DIR/go2_workspaces_built"
    echo "✓ go2_workspaces_built"
fi

# Mark installation started (prevents warning about existing install)
date -Iseconds > "$MARKER_DIR/install_started.txt"
echo "✓ install_started.txt"

echo ""
echo "=== Marker files created ==="
echo "Location: $MARKER_DIR"
echo ""
echo "Now run: bash scripts/sim_and_data_lake_setup.sh install"
echo "It will skip simulation components and only install data lake."
