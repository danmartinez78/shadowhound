#!/bin/bash
# Diagnose Nav2 and RViz2 launch issues

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}Nav2/RViz2 Diagnostic Script${NC}"
echo "=================================================="
echo ""

# 1. Check which launch file is being used
echo -e "${BOLD}1. Launch File Configuration${NC}"
if [ -n "$ROBOT_LAUNCH" ]; then
    echo "ROBOT_LAUNCH env var: $ROBOT_LAUNCH"
    if [ -f "$ROBOT_LAUNCH" ]; then
        echo -e "${GREEN}✓${NC} Launch file exists"
    else
        echo -e "${RED}✗${NC} Launch file not found!"
    fi
else
    echo "ROBOT_LAUNCH not set, would use default"
fi
echo ""

# 2. Check Nav2 installation
echo -e "${BOLD}2. Nav2 Installation${NC}"
if ros2 pkg list | grep -q "nav2_bringup"; then
    echo -e "${GREEN}✓${NC} nav2_bringup installed"
else
    echo -e "${RED}✗${NC} nav2_bringup NOT installed"
    echo "  Install with: sudo apt install ros-humble-nav2-bringup"
fi

if ros2 pkg list | grep -q "nav2_msgs"; then
    echo -e "${GREEN}✓${NC} nav2_msgs installed"
else
    echo -e "${RED}✗${NC} nav2_msgs NOT installed"
fi
echo ""

# 3. Check RViz2 installation
echo -e "${BOLD}3. RViz2 Installation${NC}"
if command -v rviz2 &> /dev/null; then
    echo -e "${GREEN}✓${NC} rviz2 command available"
else
    echo -e "${RED}✗${NC} rviz2 NOT installed"
    echo "  Install with: sudo apt install ros-humble-rviz2"
fi
echo ""

# 4. Check if Nav2 nodes are running
echo -e "${BOLD}4. Nav2 Nodes Status${NC}"
nav2_nodes=(
    "behavior_server"
    "controller_server"
    "planner_server"
    "bt_navigator"
)

for node in "${nav2_nodes[@]}"; do
    if ros2 node list 2>/dev/null | grep -q "$node"; then
        echo -e "${GREEN}✓${NC} $node running"
    else
        echo -e "${RED}✗${NC} $node NOT running"
    fi
done
echo ""

# 5. Check action servers
echo -e "${BOLD}5. Nav2 Action Servers${NC}"
if command -v python3 &> /dev/null; then
    python3 << 'EOF'
import rclpy
from rclpy.node import Node
from rclpy.action import ActionClient
from nav2_msgs.action import NavigateToPose, Spin
import sys

rclpy.init()
node = Node('diagnostic_node')

# Check NavigateToPose
nav_client = ActionClient(node, NavigateToPose, 'navigate_to_pose')
nav_available = nav_client.wait_for_server(timeout_sec=2.0)
nav_client.destroy()

# Check Spin
spin_client = ActionClient(node, Spin, 'spin')
spin_available = spin_client.wait_for_server(timeout_sec=2.0)
spin_client.destroy()

node.destroy_node()
rclpy.shutdown()

print(f"  {'✅' if nav_available else '❌'} /navigate_to_pose")
print(f"  {'✅' if spin_available else '❌'} /spin")

if not nav_available or not spin_available:
    sys.exit(1)
EOF
else
    echo "Python3 not available for action server check"
fi
echo ""

# 6. Check robot driver log
echo -e "${BOLD}6. Robot Driver Log (last 30 lines)${NC}"
if [ -f "/tmp/shadowhound_robot_driver.log" ]; then
    echo "----------------------------------------"
    tail -30 /tmp/shadowhound_robot_driver.log
    echo "----------------------------------------"
else
    echo -e "${YELLOW}⚠${NC} No robot driver log found at /tmp/shadowhound_robot_driver.log"
fi
echo ""

# 7. Check for error patterns
echo -e "${BOLD}7. Error Analysis${NC}"
if [ -f "/tmp/shadowhound_robot_driver.log" ]; then
    if grep -qi "error\|failed\|exception" /tmp/shadowhound_robot_driver.log; then
        echo -e "${RED}✗${NC} Errors found in log:"
        grep -i "error\|failed\|exception" /tmp/shadowhound_robot_driver.log | tail -10
    else
        echo -e "${GREEN}✓${NC} No obvious errors in log"
    fi
else
    echo "No log file to analyze"
fi
echo ""

# 8. Check DIMOS submodule commit
echo -e "${BOLD}8. DIMOS Submodule Status${NC}"
if [ -d "src/dimos-unitree/.git" ]; then
    cd src/dimos-unitree
    current_commit=$(git rev-parse --short HEAD)
    current_branch=$(git branch --show-current)
    echo "Current commit: $current_commit"
    echo "Current branch: $current_branch"
    
    # Check if it matches what ShadowHound expects
    cd ../..
    expected_commit=$(git ls-tree HEAD src/dimos-unitree | awk '{print $3}')
    expected_short=$(echo "$expected_commit" | cut -c1-7)
    
    if [ "$current_commit" = "$expected_short" ]; then
        echo -e "${GREEN}✓${NC} Submodule matches expected commit"
    else
        echo -e "${YELLOW}⚠${NC} Submodule mismatch!"
        echo "  Current:  $current_commit"
        echo "  Expected: $expected_short"
        echo "  This may cause issues. Run: git submodule update"
    fi
else
    echo -e "${RED}✗${NC} DIMOS submodule not initialized"
fi
echo ""

echo "=================================================="
echo -e "${BOLD}Diagnostic Complete${NC}"
echo ""
echo "Common issues:"
echo "  1. Nav2 not installed: sudo apt install ros-humble-navigation2"
echo "  2. Launch args not passed: Ensure nav2:=true rviz2:=true"
echo "  3. Config file issues: Check nav2_params.yaml exists"
echo "  4. Submodule mismatch: Run git submodule update"
echo ""
