---
tags: [deployment, tower, isaac-sim, go2, simulation]
status: active
related: [tower_sim_datalake_setup.md, laptop_isaac_sim_development.md]
summary: >
  Quick start guide for launching Unitree Go2 robot in Isaac Sim on Tower after installation.
---

# Tower: Go2 Isaac Sim Quick Start

**Purpose**: Launch the Unitree Go2 quadruped robot in NVIDIA Isaac Sim on Tower for simulation and testing.

---

## Prerequisites

- ✅ Tower setup complete (`sim_and_data_lake_setup.sh` run successfully)
- ✅ Isaac Sim 4.5.0 + Isaac Lab installed
- ✅ Driver 535.129+ installed
- ✅ `go2_omniverse` repository cloned to `~/workspace/go2_omniverse`

---

## Quick Launch (After First-Time Setup)

```bash
# On Tower
cd ~/workspace/go2_omniverse
./run_sim.sh
```

**Controls**:
- **W** - Move forward
- **A** - Turn left  
- **S** - Move backward
- **D** - Turn right
- **ESC** - Exit simulation

---

## First-Time Setup

The `go2_omniverse` repository requires building two ROS2 workspaces before first use.

### Step 1: Run Setup Script

Copy this script to Tower and run it **once**:

```bash
# On Tower, create setup script
cat > ~/setup_go2_sim.sh << 'EOF'
#!/bin/bash
# Complete setup for go2_omniverse on Tower

set -e

echo "🚀 Setting up go2_omniverse for Isaac Sim..."
echo ""

# Activate Isaac Lab environment
source ~/.robot-simrc
conda activate env_isaaclab

cd ~/workspace/go2_omniverse

# 1. Install missing Python package (empy for ROS2 message generation)
echo "📦 Installing empy..."
pip install empy

# 2. Initialize rosdep if needed
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    echo "🔧 Initializing rosdep..."
    sudo rosdep init
fi
rosdep update

# 3. Source ROS2 Humble
source /opt/ros/humble/setup.bash

# 4. Build IsaacSim-ros_workspaces (ROS2 bridge packages)
echo "🔨 Building IsaacSim ROS2 workspace..."
cd IsaacSim-ros_workspaces/humble_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
source install/setup.bash
cd ../..

# 5. Build go2_omniverse_ws (Go2 interfaces)
echo "🔨 Building go2_omniverse workspace..."
cd go2_omniverse_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
source install/setup.bash
cd ..

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎮 To launch Go2 simulation, run:"
echo "   ./run_sim.sh"
EOF

chmod +x ~/setup_go2_sim.sh

# Run setup
~/setup_go2_sim.sh
```

**Duration**: ~5-10 minutes (builds ROS2 packages)

### Step 2: Verify Setup

```bash
# Check that workspaces built successfully
ls -la ~/workspace/go2_omniverse/IsaacSim-ros_workspaces/humble_ws/install/
ls -la ~/workspace/go2_omniverse/go2_omniverse_ws/install/

# Should show ROS2 packages:
# - go2_interfaces
# - isaac_ros_messages
# - etc.
```

---

## Launch Options

### Default Launch (Single Go2 with Camera)

```bash
cd ~/workspace/go2_omniverse
./run_sim.sh
```

### Custom Launch Options

**Recommended Method**: Edit `run_sim.sh` and run it:

```bash
cd ~/workspace/go2_omniverse
nano run_sim.sh  # Uncomment --custom_env line and modify options
./run_sim.sh
```

**Direct Python Launch** (requires `LD_PRELOAD` for ROS2 compatibility):

```bash
# Activate environment
source ~/.robot-simrc
conda activate env_isaaclab
cd ~/workspace/go2_omniverse

# CRITICAL: Set LD_PRELOAD to avoid libstdc++ conflicts with ROS2
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6

# Multiple robots
python main.py --robot_amount 4 --robot go2 --device cuda --enable_cameras

# Different environment (office)
python main.py --robot go2 --device cuda --custom_env office --enable_cameras

# Headless mode (no GUI, faster)
python main.py --robot go2 --device cuda --headless

# G1 humanoid robot instead of Go2
python main.py --robot g1 --device cuda --enable_cameras
```

**Available Options**:
- `--robot_amount N` - Number of robots (default: 1)
- `--robot go2|g1` - Robot type (Go2 quadruped or G1 humanoid)
- `--device cuda|cpu` - Compute device
- `--enable_cameras` - Enable camera sensors
- `--custom_env office|warehouse` - Custom environment (place USD files in `envs/` directory)
- `--headless` - Run without GUI (faster)

**⚠️ Important**: When launching via `python main.py` directly (not using `run_sim.sh`), you **must** set `LD_PRELOAD` first:
```bash
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
```
This forces the system's `libstdc++.so.6` to load before conda's older version, preventing ROS2 import errors (`GLIBCXX_3.4.30 not found`).

---

## ROS2 Integration

The simulation publishes ROS2 topics that can be used with ShadowHound mission agent.

### Published Topics

```bash
# On Tower, in another terminal
source /opt/ros/humble/setup.bash
ros2 topic list

# Expected topics:
# /camera/image_raw          - Front camera (sensor_msgs/Image)
# /camera/camera_info        - Camera calibration
# /odom                      - Robot odometry (nav_msgs/Odometry)
# /imu                       - IMU data (sensor_msgs/Imu)
# /joint_states              - Joint positions (sensor_msgs/JointState)
# /scan                      - LiDAR 2D scan (sensor_msgs/LaserScan)
# /cmd_vel                   - Velocity commands (geometry_msgs/Twist)
```

### Test Robot Control via ROS2

```bash
# In another terminal on Tower
source /opt/ros/humble/setup.bash

# Send velocity command to move robot forward
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.5}, angular: {z: 0.0}}" --once

# Robot should move forward in simulation!
```

---

## Connecting ShadowHound Mission Agent

You can run the ShadowHound mission agent on your **laptop** and connect it to the **simulated Go2 on Tower**.

### On Tower (Start Simulation)

```bash
cd ~/workspace/go2_omniverse
./run_sim.sh
```

### On Laptop (In Devcontainer)

```bash
# Set ROS_DOMAIN_ID to match Tower
export ROS_DOMAIN_ID=0  # Default domain (recommended)

# Set ROS_LOCALHOST_ONLY=0 to allow network communication
export ROS_LOCALHOST_ONLY=0

# Source ROS2
source /opt/ros/humble/setup.bash

# Launch mission agent (connects to Tower's simulated Go2)
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    agent_backend:=ollama \
    ollama_base_url:=http://192.168.50.10:11434 \
    ollama_model:=phi4:14b
```

**Result**: Mission agent sees simulated Go2 as if it were the real robot!

---

## Custom Environments

The repository includes custom environments for testing.

### Download Custom Environments

```bash
# Download from Google Drive (link in README)
# Place USD files in ~/workspace/go2_omniverse/envs/

# Available environments:
# - office.usd
# - warehouse.usd
```

### Launch with Custom Environment

```bash
python main.py --robot go2 --custom_env office --enable_cameras
```

**Note**: First launch with custom env takes 2-3 minutes to configure.

---

## Troubleshooting

### Error: "GLIBCXX_3.4.30 not found" or ROS2 Import Failures

**Error**:
```
ImportError: /home/daniel/miniconda3/envs/env_isaaclab/bin/../lib/libstdc++.so.6: version `GLIBCXX_3.4.30' not found (required by /opt/ros/humble/local/lib/python3.10/dist-packages/rclpy/_rclpy_pybind11.cpython-310-x86_64-linux-gnu.so)
```

**Root Cause**: Conda's `libstdc++.so.6` is older than what ROS2 compiled extensions require.

**Solution**: Use `run_sim.sh` which handles this automatically, OR set `LD_PRELOAD` when using `python main.py`:
```bash
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
python main.py --robot go2 --device cuda --enable_cameras
```

This forces the system's newer `libstdc++` to load before conda's version.

### Error: "ModuleNotFoundError: No module named 'em'"

**Solution**:
```bash
conda activate env_isaaclab
pip install empy
```

### Error: "rosdep not initialized"

**Solution**:
```bash
sudo rosdep init
rosdep update
```

### Error: "No such file or directory: humble_ws"

**Solution**: Run the first-time setup script (Step 1 above).

### Isaac Sim Crashes or Freezes

**Check GPU**:
```bash
nvidia-smi  # Should show driver 535+, GPU active
```

**Check Memory**:
```bash
free -h  # Should have >8GB available
```

**Try Headless Mode**:
```bash
python main.py --robot go2 --device cuda --headless
```

### ROS2 Topics Not Visible

**Check ROS_DOMAIN_ID**:
```bash
echo $ROS_DOMAIN_ID  # Should match across machines
```

**Check Network**:
```bash
# Tower and laptop should be on same network
# Disable ROS_LOCALHOST_ONLY if connecting remotely
export ROS_LOCALHOST_ONLY=0
```

### RTX Rendering Warning

**Warning**: `HydraEngine rtx failed creating scene renderer`  
**Error**: `The currently installed NVIDIA graphics driver is unsupported`

These warnings occur when the NVIDIA driver is below the minimum recommended version (535.129). The simulation **will still run** but RTX features may be limited.

**Current status**:
- Tower driver: 535.18.02 (or 535.274.02)
- Minimum required: 535.129.03
- Status: ⚠️ Functional but outdated

**To update driver (optional)**:
```bash
# Check current version
nvidia-smi | grep "Driver Version"

# Update to latest (requires reboot)
sudo apt update
sudo apt install nvidia-driver-550  # Latest stable as of Oct 2025
sudo reboot
```

**If simulation doesn't start**:
1. Check GPU detected: `nvidia-smi` (should show RTX 4070 Ti)
2. Verify Isaac Sim installed: `python -c "import isaacsim"`
3. Check for X11 display issues (if using remote connection)

---

## Performance Tips

### Faster Simulation

1. **Use Headless Mode**: 2-3x faster without GUI
   ```bash
   python main.py --robot go2 --headless --device cuda
   ```

2. **Disable Cameras**: Saves GPU memory
   ```bash
   python main.py --robot go2  # No --enable_cameras flag
   ```

3. **Reduce Robot Count**: Single robot is faster
   ```bash
   python main.py --robot_amount 1  # Instead of 4
   ```

### Better Visual Quality

1. **Enable RTX Raytracing**: Better lighting (requires more GPU)
   - In Isaac Sim GUI: Viewport → Rendering → Enable RTX

2. **Higher Resolution Camera**: Edit `main.py` camera config

---

## Repository Structure

```
go2_omniverse/
├── main.py                    # Main simulation script
├── run_sim.sh                 # Launch script for Go2
├── run_sim_g1.sh              # Launch script for G1 humanoid
├── robots/
│   ├── copter/                # Crazyflie drone (added_copter branch)
│   └── g1/                    # Unitree G1 humanoid
├── IsaacSim-ros_workspaces/
│   └── humble_ws/             # ROS2 Humble workspace (bridge packages)
├── go2_omniverse_ws/
│   └── src/                   # Go2 ROS2 interfaces
├── Isaac_sim/
│   └── Unitree/               # LiDAR config generator
└── envs/                      # Custom USD environments (optional)
```

---

## Advanced Features

### VR Support

The repository supports VR with SteamVR. See README for setup instructions.

### Multiple Robots

```bash
# Spawn 4 Go2 robots
python main.py --robot_amount 4 --robot go2 --device cuda
```

### RL Training

The simulation supports reinforcement learning training with PPO algorithms.

---

## Next Steps

1. **Test Basic Launch**: `./run_sim.sh`
2. **Verify ROS2 Topics**: `ros2 topic list`
3. **Test Robot Control**: Send `/cmd_vel` commands
4. **Connect Mission Agent**: Launch agent on laptop
5. **Experiment with Environments**: Try office/warehouse

---

## References

- **go2_omniverse Repository**: https://github.com/abizovnuralem/go2_omniverse
- **Isaac Sim Docs**: https://docs.omniverse.nvidia.com/isaacsim/latest/
- **Isaac Lab Docs**: https://isaac-sim.github.io/IsaacLab/
- **ShadowHound Integration**: [laptop_isaac_sim_development.md](laptop_isaac_sim_development.md)

---

**Status**: Verified working with Isaac Sim 4.5.0, driver 535.274.02, RTX 4070 Ti

**Last Updated**: 2025-10-19
