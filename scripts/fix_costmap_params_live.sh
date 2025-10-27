#!/bin/bash
# Quick fix: Set costmap frame parameters live (without restarting)
# Use this to test if frame ID mismatch is the root cause
# 
# If this fixes the warnings, the issue is parameter loading (which we've now fixed in YAML)
# After confirming this works, restart with the updated YAML for permanent fix

set -e

ROBOT_NS="${ROBOT_NAMESPACE:-robot0}"

echo "=========================================="
echo "Setting Costmap Frame Parameters Live"
echo "=========================================="
echo ""
echo "Robot namespace: ${ROBOT_NS}"
echo ""

# Try to set on both possible node names (single-key and double-key variants)
echo "Setting local_costmap parameters..."
ros2 param set /${ROBOT_NS}/local_costmap/local_costmap global_frame ${ROBOT_NS}/odom 2>/dev/null || \
    ros2 param set /${ROBOT_NS}/local_costmap global_frame ${ROBOT_NS}/odom

ros2 param set /${ROBOT_NS}/local_costmap/local_costmap robot_base_frame ${ROBOT_NS}/base_link 2>/dev/null || \
    ros2 param set /${ROBOT_NS}/local_costmap robot_base_frame ${ROBOT_NS}/base_link

echo "Setting global_costmap parameters..."
ros2 param set /${ROBOT_NS}/global_costmap/global_costmap global_frame ${ROBOT_NS}/odom 2>/dev/null || \
    ros2 param set /${ROBOT_NS}/global_costmap global_frame ${ROBOT_NS}/odom

ros2 param set /${ROBOT_NS}/global_costmap/global_costmap robot_base_frame ${ROBOT_NS}/base_link 2>/dev/null || \
    ros2 param set /${ROBOT_NS}/global_costmap robot_base_frame ${ROBOT_NS}/base_link

echo ""
echo "✅ Parameters set! Verifying..."
echo ""

# Verify
echo "Verification:"
ros2 param get /${ROBOT_NS}/local_costmap/local_costmap global_frame 2>/dev/null || \
    ros2 param get /${ROBOT_NS}/local_costmap global_frame

ros2 param get /${ROBOT_NS}/local_costmap/local_costmap robot_base_frame 2>/dev/null || \
    ros2 param get /${ROBOT_NS}/local_costmap robot_base_frame

echo ""
echo "=========================================="
echo "If controller warnings stopped, the fix worked!"
echo "The updated YAML (commit 0d295d1) makes this permanent."
echo "=========================================="
