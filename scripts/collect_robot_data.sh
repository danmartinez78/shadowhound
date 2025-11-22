#!/bin/bash
# Robot Data Collection Script
# Launches robot with topic remapping and records bagfile for ODD analysis

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ROBOT_IP="${ROBOT_IP:-192.168.1.103}"
DURATION="${DURATION:-60}"  # Recording duration in seconds
OUTPUT_DIR="/home/daniel/go2_bags"
BAGFILE_NAME="collection_$(date +%Y%m%d_%H%M%S)"

# Required topics for ODD pipeline
REQUIRED_TOPICS=(
    "/robot0/odom"
    "/robot0/imu"
    "/robot0/joint_states"
    "/robot0/front_cam/rgb"
    "/robot0/point_cloud2_L1"
)

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}🎯 Robot Data Collection${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Robot IP: $ROBOT_IP"
echo "  Duration: ${DURATION}s"
echo "  Output: $OUTPUT_DIR/$BAGFILE_NAME"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Source workspace
echo -e "${YELLOW}📦 Sourcing workspace...${NC}"
source install/setup.bash

# Launch robot with remapping (in background)
echo -e "${YELLOW}🚀 Launching robot driver...${NC}"
ros2 launch robot_data_collection.launch.py robot_ip:=$ROBOT_IP &
LAUNCH_PID=$!

# Wait for topics to be available
echo -e "${YELLOW}⏳ Waiting for topics to become available...${NC}"
sleep 5

# Verify topics
echo -e "${YELLOW}🔍 Verifying required topics...${NC}"
MISSING_TOPICS=()
for topic in "${REQUIRED_TOPICS[@]}"; do
    if ros2 topic list | grep -q "^${topic}$"; then
        echo -e "  ${GREEN}✓${NC} $topic"
    else
        echo -e "  ${RED}✗${NC} $topic (MISSING)"
        MISSING_TOPICS+=("$topic")
    fi
done

if [ ${#MISSING_TOPICS[@]} -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ Missing ${#MISSING_TOPICS[@]} required topic(s)!${NC}"
    echo -e "${YELLOW}Killing launch...${NC}"
    kill $LAUNCH_PID
    exit 1
fi

echo ""
echo -e "${GREEN}✅ All required topics available!${NC}"
echo ""

# Record bagfile
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}🎬 Starting bagfile recording${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Move the robot around!${NC}"
echo "   The ODD pipeline requires actual motion data."
echo "   Recording for ${DURATION} seconds..."
echo ""

# Start recording
ros2 bag record \
    -o "$OUTPUT_DIR/$BAGFILE_NAME" \
    --storage mcap \
    --max-cache-size 0 \
    --include-hidden-topics \
    "${REQUIRED_TOPICS[@]}" \
    --duration $DURATION

# Stop launch
echo ""
echo -e "${YELLOW}🛑 Stopping robot driver...${NC}"
kill $LAUNCH_PID
wait $LAUNCH_PID 2>/dev/null || true

# Verify bagfile
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}📊 Bagfile Information${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

BAGFILE_PATH="$OUTPUT_DIR/$BAGFILE_NAME"
if [ -d "$BAGFILE_PATH" ]; then
    ros2 bag info "$BAGFILE_PATH"
    
    echo ""
    echo -e "${GREEN}✅ Data collection complete!${NC}"
    echo ""
    echo "  📁 Bagfile: $BAGFILE_PATH"
    echo "  📋 Topics: ${#REQUIRED_TOPICS[@]}"
    echo "  ⏱️  Duration: ${DURATION}s"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Verify bagfile contains motion data:"
    echo "     ros2 bag info $BAGFILE_PATH"
    echo ""
    echo "  2. Process with ODD pipeline:"
    echo "     python extract_windows.py --input $BAGFILE_PATH"
    echo ""
else
    echo -e "${RED}❌ Bagfile creation failed!${NC}"
    exit 1
fi
