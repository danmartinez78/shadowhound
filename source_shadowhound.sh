#!/bin/bash
# ============================================================================
# ShadowHound Environment Helper
# ============================================================================
#
# Source this file in any terminal to access the same ROS environment
# as the running ShadowHound system.
#
# Usage:
#   source source_shadowhound.sh
#
# Or add to your ~/.bashrc:
#   alias shadowhound='source ~/shadowhound/source_shadowhound.sh'
#
# ============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🐕 ShadowHound Environment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# First, try to load .env file (this is what start.sh uses)
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${GREEN}✓${NC} Loading environment from .env"
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Check if .shadowhound_env exists (created by start.sh at runtime)
if [ -f "$SCRIPT_DIR/.shadowhound_env" ]; then
    echo -e "${GREEN}✓${NC} Loading environment from .shadowhound_env"
    source "$SCRIPT_DIR/.shadowhound_env"
else
    # Fallback to default values if start.sh hasn't run yet
    echo -e "${YELLOW}⚠${NC} .shadowhound_env not found (start.sh hasn't run yet)"
    echo -e "${YELLOW}⚠${NC} Using default values"
    
    export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
    export ROBOT_IP=${ROBOT_IP:-192.168.10.167}
    export RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}
    export ROS_LOCALHOST_ONLY=${ROS_LOCALHOST_ONLY:-0}
    
    # Source ROS2
    if [ -f "/opt/ros/humble/setup.bash" ]; then
        source /opt/ros/humble/setup.bash
        echo -e "${GREEN}✓${NC} Sourced ROS2 Humble"
    else
        echo -e "${YELLOW}⚠${NC} ROS2 Humble not found"
    fi
    
    # Source workspace
    if [ -f "$SCRIPT_DIR/install/setup.bash" ]; then
        source "$SCRIPT_DIR/install/setup.bash"
        echo -e "${GREEN}✓${NC} Sourced workspace"
    else
        echo -e "${YELLOW}⚠${NC} Workspace not built (run: colcon build)"
    fi
fi

# If CycloneDDS config exists, set CYCLONEDDS_URI unless already set
if [ -z "${CYCLONEDDS_URI:-}" ] && [ -f "$SCRIPT_DIR/config/cyclonedds_network.xml" ]; then
    export CYCLONEDDS_URI="file://$SCRIPT_DIR/config/cyclonedds_network.xml"
    echo -e "${GREEN}✓${NC} Using CycloneDDS config: $CYCLONEDDS_URI"
fi

echo ""
echo "Environment:"
echo "  • ROS_DOMAIN_ID: $ROS_DOMAIN_ID"
echo "  • ROBOT_IP: $ROBOT_IP"
echo "  • RMW: $RMW_IMPLEMENTATION"
echo "  • ROS_LOCALHOST_ONLY: ${ROS_LOCALHOST_ONLY:-}"
echo "  • CYCLONEDDS_URI: ${CYCLONEDDS_URI:-}" 
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Common commands:"
echo "  ros2 node list              # List all nodes"
echo "  ros2 topic list             # List all topics"
echo "  ros2 topic echo /go2_states # Monitor robot state"
echo "  ros2 action list            # List action servers"
echo ""
