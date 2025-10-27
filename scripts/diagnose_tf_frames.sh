#!/bin/bash
# Quick diagnostic: Check if Isaac Sim is publishing TF frames

echo "=========================================="
echo "TF Frame Diagnostic"
echo "=========================================="
echo ""

echo "1. Checking /tf topic activity..."
timeout 2 ros2 topic hz /tf 2>/dev/null || echo "   ❌ /tf topic not publishing or no data"
echo ""

echo "2. Checking what frames exist in TF tree..."
timeout 2 ros2 topic echo /tf --once 2>/dev/null | grep "frame_id:" | head -20 || echo "   ❌ Could not read /tf topic"
echo ""

echo "3. Attempting to lookup robot0/odom → robot0/base_link transform..."
timeout 2 ros2 run tf2_ros tf2_echo robot0/odom robot0/base_link 2>&1 | head -10
echo ""

echo "4. Checking if Isaac Sim topics are available..."
ros2 topic list | grep robot0 | head -10
echo ""

echo "=========================================="
echo "Diagnostic complete"
echo "=========================================="
echo ""
echo "If /tf is not publishing or robot0/* frames don't exist:"
echo "  → Check that Isaac Sim is running on Tower"
echo "  → Verify Tower is publishing to ROS_DOMAIN_ID=0"
echo "  → Check network connectivity between laptop and Tower"
