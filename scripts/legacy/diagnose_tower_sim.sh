#!/usr/bin/env bash
# Emergency diagnostic script - check Tower simulation state

set -euo pipefail

echo "=== Tower Simulation State Diagnostic ==="
echo ""

echo "1. Conda Environment Check:"
if conda env list | grep -q env_isaaclab; then
    echo "   ✓ env_isaaclab exists"
    echo "   Python packages:"
    conda run -n env_isaaclab pip list | grep -E "isaac|torch|empy|lark|transforms3d|catkin" || echo "   ⚠ No relevant packages found"
else
    echo "   ✗ env_isaaclab NOT FOUND"
fi
echo ""

echo "2. Isaac Lab Directory Check:"
if [[ -d "$HOME/workspace/IsaacLab" ]]; then
    echo "   ✓ IsaacLab directory exists"
    if [[ -f "$HOME/workspace/IsaacLab/setup.py" ]]; then
        echo "   ✓ setup.py exists"
    fi
    if [[ -d "$HOME/workspace/IsaacLab/_isaac_sim" ]]; then
        echo "   ✓ _isaac_sim subdirectory exists"
    fi
else
    echo "   ✗ IsaacLab directory NOT FOUND"
fi
echo ""

echo "3. Isaac Sim Install Check:"
ISAAC_SIM_DIR="$HOME/.local/share/ov/pkg/isaac-sim-4.5.0"
if [[ -d "$ISAAC_SIM_DIR" ]]; then
    echo "   ✓ Isaac Sim 4.5.0 directory exists"
    if [[ -f "$ISAAC_SIM_DIR/python.sh" ]]; then
        echo "   ✓ python.sh exists"
    fi
    if [[ -d "$ISAAC_SIM_DIR/exts/omni.isaac.sensor/data/lidar_configs" ]]; then
        echo "   ✓ LiDAR configs directory exists"
        ls "$ISAAC_SIM_DIR/exts/omni.isaac.sensor/data/lidar_configs" | head -5
    fi
else
    echo "   ✗ Isaac Sim 4.5.0 directory NOT FOUND"
fi
echo ""

echo "4. ROS2 Workspaces Check:"
if [[ -d "$HOME/workspace/go2_omniverse/go2_ros2_sdk" ]]; then
    echo "   ✓ go2_ros2_sdk exists"
    if [[ -d "$HOME/workspace/go2_omniverse/go2_ros2_sdk/install" ]]; then
        echo "   ✓ go2_ros2_sdk/install exists"
    else
        echo "   ⚠ go2_ros2_sdk/install NOT FOUND (workspace not built)"
    fi
fi

if [[ -d "$HOME/workspace/go2_omniverse/IsaacSim-ros_workspaces/humble_ws" ]]; then
    echo "   ✓ humble_ws exists"
    if [[ -d "$HOME/workspace/go2_omniverse/IsaacSim-ros_workspaces/humble_ws/install" ]]; then
        echo "   ✓ humble_ws/install exists"
    else
        echo "   ⚠ humble_ws/install NOT FOUND (workspace not built)"
    fi
fi
echo ""

echo "5. Test Isaac Sim Import:"
if command -v conda &> /dev/null; then
    if conda run -n env_isaaclab python -c "import isaacsim; print('✓ Isaac Sim import successful')" 2>&1; then
        :
    else
        echo "   ✗ Isaac Sim import FAILED"
    fi
else
    echo "   ⚠ conda not available"
fi
echo ""

echo "6. Markers Check:"
MARKER_DIR="$HOME/.go2_stack_state"
if [[ -d "$MARKER_DIR" ]]; then
    echo "   ✓ Marker directory exists"
    echo "   Markers present:"
    ls -1 "$MARKER_DIR" | sed 's/^/     - /'
else
    echo "   ⚠ Marker directory not found"
fi
echo ""

echo "=== End Diagnostic ==="
echo ""
echo "Copy this output and share with agent for diagnosis."
