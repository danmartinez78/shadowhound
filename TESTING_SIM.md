# Quick Start: Testing with Isaac Sim

**Branch:** `feature/laptop-sim-integration`

## Setup (One-Time)

### 1. On Tower: Start Isaac Sim
```bash
cd ~/workspace/go2_omniverse
./run_sim.sh
```

### 2. On Laptop: Setup Environment
```bash
cd ~/shadowhound

# Copy simulation config
cp .env.simulation .env

# Edit .env and add your OpenAI API key
nano .env
# Change: OPENAI_API_KEY=sk-proj-your-key-here
```

## Testing

### 1. Verify Topics Visible
```bash
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
source /opt/ros/humble/setup.bash

ros2 topic list | grep robot0
# Should see: /robot0/cmd_vel, /robot0/odom, /robot0/imu, etc.
```

### 2. Launch Mission Agent
```bash
cd ~/shadowhound
source install/setup.bash

ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    robot_mode:=simulation \
    agent_backend:=openai
```

### 3. Open Web Interface
```
http://localhost:8080
```

### 4. Visualize in RViz2
```bash
# In another terminal
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
source /opt/ros/humble/setup.bash

rviz2
# Add displays:
#   - PointCloud2: /robot0/point_cloud2_L1
#   - Image: /robot0/front_cam/rgb
#   - Odometry: /robot0/odom
```

## What Changed

### New Robot Modes
- `robot_mode:=mock` - Pure software mock (no hardware/sim)
- `robot_mode:=simulation` - Isaac Sim testing ✨ NEW
- `robot_mode:=hardware` - Real robot

### Environment Files
- `.env.development` - Mock mode (default)
- `.env.simulation` - Sim testing ✨ NEW
- `.env.hardware` - Real robot

### Topic Remapping
Launch file automatically maps topics:
```
Mission Agent → Simulation
/cmd_vel      → /robot0/cmd_vel
/odom         → /robot0/odom
/imu          → /robot0/imu
/camera/...   → /robot0/front_cam/rgb
```

## Troubleshooting

### No topics visible?
```bash
# Check network
ping 192.168.10.116  # Tower IP

# Check ROS config
echo $ROS_DOMAIN_ID  # Should be 0
echo $ROS_LOCALHOST_ONLY  # Should be 0

# On Tower, verify sim running
ros2 topic list | grep robot0
```

### Mission agent fails to launch?
```bash
# Check dependencies on laptop host (not devcontainer)
pip list | grep -E "(fastapi|openai|dimos)"

# Rebuild workspace
cd ~/shadowhound
colcon build --packages-select shadowhound_mission_agent
source install/setup.bash
```

### DIMOS skills not working?
This is **EXPECTED** in simulation mode. WebRTC API unavailable with CycloneDDS.
- ✅ Navigation works (/cmd_vel, /odom)
- ✅ Perception works (camera, LiDAR)
- ❌ High-level API (sit, stand, wave) unavailable

## Next Steps

1. Test mission execution via web UI
2. Send velocity commands
3. Monitor robot behavior in Isaac Sim
4. Test navigation stack integration

## Files Changed
- `src/shadowhound_mission_agent/launch/mission_agent.launch.py` - robot_mode parameter
- `.env.simulation` - Simulation configuration
- `.env.hardware` - Hardware configuration
- `.env.development` - Updated with ROBOT_MODE
- `docs/software/robot_modes.md` - Complete mode documentation
