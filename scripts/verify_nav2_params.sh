#!/bin/bash
# Verify Nav2 parameters are correctly loaded with robot0 frame IDs
# Run this AFTER launching ./test_autonomy.sh

set -e

ROBOT_NS="${ROBOT_NAMESPACE:-robot0}"

echo "=========================================="
echo "Verifying Nav2 Parameters for /${ROBOT_NS}"
echo "=========================================="
echo ""

# Check if nodes are running
echo "1. Checking if Nav2 nodes are running..."
if ros2 node list | grep -q "/${ROBOT_NS}/"; then
    echo "   ✅ Nav2 nodes found under /${ROBOT_NS}/"
else
    echo "   ❌ No Nav2 nodes found under /${ROBOT_NS}/"
    echo "   Make sure ./test_autonomy.sh is running!"
    exit 1
fi
echo ""

# Check controller_server frame parameters (THE CRITICAL FIX)
echo "2. Checking controller_server frame parameters..."
ROBOT_BASE=$(ros2 param get /${ROBOT_NS}/controller_server robot_base_frame 2>/dev/null | grep -oP "String value is: '\K[^']+")
ODOM_FRAME=$(ros2 param get /${ROBOT_NS}/controller_server odom_frame 2>/dev/null | grep -oP "String value is: '\K[^']+")

if [[ "$ROBOT_BASE" == "${ROBOT_NS}/base_link" ]]; then
    echo "   ✅ robot_base_frame: $ROBOT_BASE"
else
    echo "   ❌ robot_base_frame: $ROBOT_BASE (expected ${ROBOT_NS}/base_link)"
fi

if [[ "$ODOM_FRAME" == "${ROBOT_NS}/odom" ]]; then
    echo "   ✅ odom_frame: $ODOM_FRAME"
else
    echo "   ❌ odom_frame: $ODOM_FRAME (expected ${ROBOT_NS}/odom)"
fi
echo ""

# Check local_costmap frame parameters
echo "3. Checking local_costmap frame parameters..."
# Nav2 versions differ on node naming: try both /robot0/local_costmap and /robot0/local_costmap/local_costmap
LOCAL_GLOBAL=$(ros2 param get /${ROBOT_NS}/local_costmap/local_costmap global_frame 2>/dev/null | grep -oP "String value is: '\K[^']+" || \
               ros2 param get /${ROBOT_NS}/local_costmap global_frame 2>/dev/null | grep -oP "String value is: '\K[^']+")
LOCAL_BASE=$(ros2 param get /${ROBOT_NS}/local_costmap/local_costmap robot_base_frame 2>/dev/null | grep -oP "String value is: '\K[^']+" || \
             ros2 param get /${ROBOT_NS}/local_costmap robot_base_frame 2>/dev/null | grep -oP "String value is: '\K[^']+")

if [[ "$LOCAL_GLOBAL" == "${ROBOT_NS}/odom" ]]; then
    echo "   ✅ global_frame: $LOCAL_GLOBAL"
else
    echo "   ❌ global_frame: $LOCAL_GLOBAL (expected ${ROBOT_NS}/odom)"
    echo "      Run: ros2 param set /${ROBOT_NS}/local_costmap/local_costmap global_frame ${ROBOT_NS}/odom"
fi

if [[ "$LOCAL_BASE" == "${ROBOT_NS}/base_link" ]]; then
    echo "   ✅ robot_base_frame: $LOCAL_BASE"
else
    echo "   ❌ robot_base_frame: $LOCAL_BASE (expected ${ROBOT_NS}/base_link)"
    echo "      Run: ros2 param set /${ROBOT_NS}/local_costmap/local_costmap robot_base_frame ${ROBOT_NS}/base_link"
fi
echo ""

# Check bt_navigator frame parameters
echo "4. Checking bt_navigator frame parameters..."
BT_GLOBAL=$(ros2 param get /${ROBOT_NS}/bt_navigator global_frame 2>/dev/null | grep -oP "String value is: '\K[^']+")
BT_BASE=$(ros2 param get /${ROBOT_NS}/bt_navigator robot_base_frame 2>/dev/null | grep -oP "String value is: '\K[^']+")

if [[ "$BT_GLOBAL" == "${ROBOT_NS}/odom" ]]; then
    echo "   ✅ global_frame: $BT_GLOBAL"
else
    echo "   ❌ global_frame: $BT_GLOBAL (expected ${ROBOT_NS}/odom)"
fi

if [[ "$BT_BASE" == "${ROBOT_NS}/base_link" ]]; then
    echo "   ✅ robot_base_frame: $BT_BASE"
else
    echo "   ❌ robot_base_frame: $BT_BASE (expected ${ROBOT_NS}/base_link)"
fi
echo ""

# Check TF tree
echo "5. Checking TF tree for ${ROBOT_NS} frames..."
if ros2 run tf2_ros tf2_echo ${ROBOT_NS}/odom ${ROBOT_NS}/base_link --timeout 2.0 &>/dev/null; then
    echo "   ✅ TF transform available: ${ROBOT_NS}/odom → ${ROBOT_NS}/base_link"
else
    echo "   ❌ TF transform NOT available: ${ROBOT_NS}/odom → ${ROBOT_NS}/base_link"
    echo "   Check if Isaac Sim is publishing TF on Tower!"
fi
echo ""

# Check scan topic
echo "6. Checking scan topic..."
if ros2 topic info /${ROBOT_NS}/scan 2>/dev/null | grep -q "Type: sensor_msgs/msg/LaserScan"; then
    echo "   ✅ /${ROBOT_NS}/scan topic exists (LaserScan)"
else
    echo "   ❌ /${ROBOT_NS}/scan topic NOT found"
fi
echo ""

# Check costmap topics
echo "7. Checking costmap topics..."
if ros2 topic list | grep -q "/${ROBOT_NS}/local_costmap/costmap"; then
    echo "   ✅ /${ROBOT_NS}/local_costmap/costmap topic exists"
else
    echo "   ⚠️  /${ROBOT_NS}/local_costmap/costmap NOT found (may still be initializing)"
fi

if ros2 topic list | grep -q "/${ROBOT_NS}/global_costmap/costmap"; then
    echo "   ✅ /${ROBOT_NS}/global_costmap/costmap topic exists"
else
    echo "   ⚠️  /${ROBOT_NS}/global_costmap/costmap NOT found (may still be initializing)"
fi
echo ""

echo "=========================================="
echo "Verification Complete!"
echo "=========================================="
echo ""
echo "If you see ❌ errors above, check:"
echo "  1. Is Isaac Sim running on Tower?"
echo "  2. Did you pull commit 14bd34d and rebuild?"
echo "  3. Are there errors in the Nav2 logs?"
echo ""
echo "To see Nav2 logs:"
echo "  ros2 node info /${ROBOT_NS}/controller_server"
echo "  ros2 topic echo /${ROBOT_NS}/local_costmap/costmap --once"
