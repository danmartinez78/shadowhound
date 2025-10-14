#!/bin/bash
# ============================================================================
# ROS 2 DDS Direct Test Script
# ============================================================================
# Launch the go2_ros2_sdk driver using CycloneDDS (Ethernet) and verify topics.
#
# Prerequisites:
#   - Robot accessible over Ethernet/LAN with DDS discovery allowed
#   - RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
#   - (Optional) ROS_DOMAIN_ID set consistently
# ============================================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  ROS 2 DDS Direct Test (CycloneDDS)         ${NC}"
echo -e "${BLUE}=============================================${NC}"

# Source ROS and workspace
[ -f /opt/ros/humble/setup.bash ] && source /opt/ros/humble/setup.bash
[ -f install/setup.bash ] && source install/setup.bash

export CONN_TYPE=${CONN_TYPE:-cyclonedds}
export RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}

echo -e "${YELLOW}Environment:${NC}"
echo "  • CONN_TYPE: $CONN_TYPE"
echo "  • RMW_IMPLEMENTATION: $RMW_IMPLEMENTATION"
echo "  • ROS_DOMAIN_ID: ${ROS_DOMAIN_ID:-<default>}"

# Locate launch file
LAUNCH_FILE=""
if [ -f "launch/go2_sdk/robot.launch.py" ]; then
  LAUNCH_FILE="launch/go2_sdk/robot.launch.py"
elif [ -f "src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk/launch/robot.launch.py" ]; then
  LAUNCH_FILE="src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk/launch/robot.launch.py"
fi

if [ -z "$LAUNCH_FILE" ]; then
  echo -e "${RED}✗ Robot launch file not found${NC}"
  exit 1
fi

LOG_FILE="/tmp/dds_test_$(date +%Y%m%d_%H%M%S).log"
echo "Log: $LOG_FILE"

# Launch
ros2 launch "$LAUNCH_FILE" nav2:=false rviz2:=false > "$LOG_FILE" 2>&1 &
DRIVER_PID=$!

# Wait for topics
echo -n "Waiting for /go2_states"
for i in $(seq 1 30); do
  if ros2 topic list 2>/dev/null | grep -q "/go2_states"; then
    echo -e "\n${GREEN}✓ Topics detected${NC}"
    break
  fi
  if ! kill -0 $DRIVER_PID 2>/dev/null; then
    echo -e "\n${RED}✗ Driver exited unexpectedly${NC}"
    tail -30 "$LOG_FILE"
    exit 1
  fi
  echo -n "."
  sleep 1
  [ "$i" -eq 30 ] && echo -e "\n${RED}✗ Timeout waiting for topics${NC}" && exit 1
done

# Show topics
echo -e "${YELLOW}Sample topics:${NC}"
ros2 topic list | grep -E "go2_|camera|imu|odom" | sed 's/^/  /'

# Instructions
cat <<EOF

${BLUE}Next steps (in another terminal):${NC}
  source .shadowhound_env
  ros2 topic echo /go2_states --once
  ros2 topic hz /go2_states

${GREEN}Driver running. Press Ctrl+C here to stop.${NC}

=== Tail logs ===
EOF

tail -f -n 50 "$LOG_FILE"
