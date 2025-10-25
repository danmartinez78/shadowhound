#!/bin/bash
# Quick test launcher for simulation autonomy stack (Nav2, SLAM, etc.)
# No checks, no mission agent - just launches the ROS2 nodes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  Quick Autonomy Stack Test Launcher"
echo "========================================"
echo ""

# Source environment
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Source ROS2
if [ -f "/opt/ros/humble/setup.bash" ]; then
    source /opt/ros/humble/setup.bash
fi

# Source workspace
if [ -f "$SCRIPT_DIR/install/setup.bash" ]; then
    source "$SCRIPT_DIR/install/setup.bash"
fi

# Set ROS environment
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
export ROS_LOCALHOST_ONLY=${ROS_LOCALHOST_ONLY:-0}

# Don't force RMW implementation unless already set
if [ -z "${RMW_IMPLEMENTATION:-}" ]; then
    echo "Using default RMW implementation (FastDDS)"
else
    echo "Using RMW implementation: $RMW_IMPLEMENTATION"
fi

# Robot namespace
ROBOT_NS="${ROBOT_NAMESPACE:-robot0}"

echo ""
echo "Configuration:"
echo "  Robot namespace: $ROBOT_NS"
echo "  ROS Domain ID: $ROS_DOMAIN_ID"
echo "  ROS Localhost Only: $ROS_LOCALHOST_ONLY"
echo "  RMW: ${RMW_IMPLEMENTATION:-default}"
echo ""

# Launch file
LAUNCH_FILE="$SCRIPT_DIR/src/shadowhound_bringup/launch/sim_autonomy.launch.py"

if [ ! -f "$LAUNCH_FILE" ]; then
    echo "ERROR: Launch file not found: $LAUNCH_FILE"
    exit 1
fi

echo "Launching autonomy stack..."
echo "  Launch file: $LAUNCH_FILE"
echo "  Namespace: $ROBOT_NS"
echo ""
echo "Components launching:"
echo "  - Pointcloud to laserscan converter"
echo "  - Nav2 navigation stack"
echo "  - SLAM Toolbox"
echo "  - Foxglove Bridge"
echo "  - RViz2"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Launch with all visualization enabled
ros2 launch "$LAUNCH_FILE" \
    robot_namespace:="$ROBOT_NS" \
    rviz2:=True \
    nav2:=True \
    slam:=True \
    foxglove:=True

echo ""
echo "Autonomy stack stopped"
