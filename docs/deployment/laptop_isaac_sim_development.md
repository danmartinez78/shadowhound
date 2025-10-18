---
tags: [deployment, development, isaac-sim, laptop, tower, ros2]
status: complete
related: [tower_sim_datalake_setup.md, go2_ros2_sdk_tower_integration.md]
summary: >
  How to run the mission agent on your laptop while connecting to Isaac Sim running on Tower for development and testing.
---

# Laptop + Tower Isaac Sim Development Workflow

## Purpose

This guide explains how to run the **ShadowHound mission agent on your development laptop** while connecting to **Isaac Sim running on Tower** for sensor simulation and robot testing.

**Use Case**: Develop and debug mission agent code on your laptop with full IDE support, while using Tower's GPU for Isaac Sim physics simulation.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Laptop (Development Machine)                  │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  VS Code (devcontainer)                                    │ │
│  │  /workspaces/shadowhound/                                  │ │
│  │  - Edit Python code                                        │ │
│  │  - Debug with breakpoints                                  │ │
│  │  - Git commit/push                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│           ↓                                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  ROS2 Humble (in devcontainer)                             │ │
│  │  ROS_DOMAIN_ID=42                                          │ │
│  │  RMW_IMPLEMENTATION=rmw_cyclonedds_cpp                     │ │
│  │                                                              │ │
│  │  Running Nodes:                                             │ │
│  │  • mission_agent (shadowhound_mission_agent)               │ │
│  │  • (optional) rviz2 for visualization                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│           ↓                                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  ROS2 Topics (subscribing)                                 │ │
│  │  • /camera/image_raw       - From Isaac Sim               │ │
│  │  • /odom                   - Robot pose in sim             │ │
│  │  • /imu                    - Simulated IMU                 │ │
│  │  • /joint_states           - Joint positions               │ │
│  │  • /scan                   - LiDAR scan                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│           ↓                                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  ROS2 Topics (publishing)                                  │ │
│  │  • /cmd_vel                - Velocity commands to sim      │ │
│  └────────────────────────────────────────────────────────────┘ │
└───────────────────────────────┬───────────────────────────────┘
                                │
                        Network (DDS Discovery)
                        ROS_DOMAIN_ID=42
                                │
┌───────────────────────────────▼───────────────────────────────┐
│                    Tower (Simulation Server)                   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Isaac Sim 4.5 (running in headless or GUI mode)        │ │
│  │  - Unitree Go2 URDF loaded                               │ │
│  │  - Physics simulation (GPU accelerated)                  │ │
│  │  - Sensor simulation (camera, LiDAR, IMU)                │ │
│  │  - ROS2 bridge publishing sensor topics                  │ │
│  └──────────────────────────────────────────────────────────┘ │
│           ↓                                                     │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  ROS2 Topics (publishing from Isaac Sim)                 │ │
│  │  • /camera/image_raw       - Simulated camera (640x480)  │ │
│  │  • /odom                   - Ground truth pose           │ │
│  │  • /imu                    - Simulated IMU data          │ │
│  │  • /joint_states           - Joint feedback              │ │
│  │  • /scan                   - Simulated LiDAR 2D          │ │
│  └──────────────────────────────────────────────────────────┘ │
│           ↓                                                     │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  ROS2 Topics (subscribing in Isaac Sim)                  │ │
│  │  • /cmd_vel                - Apply to simulated robot    │ │
│  └──────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concept**: Both machines are on the same ROS2 network (via DDS multicast), so topics are automatically discovered and shared.

---

## Prerequisites

### On Laptop

- ✅ Ubuntu 22.04 (or devcontainer with ROS2 Humble)
- ✅ ShadowHound workspace cloned and built
- ✅ ROS2 Humble installed
- ✅ Network connectivity to Tower (same LAN: 192.168.x.x or 10.x.x.x)

### On Tower

- ✅ Tower setup complete (Isaac Sim installed via `sim_and_data_lake_setup.sh`)
- ✅ Isaac Lab installed
- ✅ ROS2 Humble installed
- ✅ Firewall configured to allow ROS2 DDS traffic

---

## Step 1: Configure Tower Firewall for ROS2 DDS

ROS2 uses **DDS (Data Distribution Service)** for topic communication, which requires specific UDP ports.

### On Tower

```bash
# Allow DDS multicast discovery (UDP 7400-7500)
sudo ufw allow from 192.168.0.0/16 to any port 7400:7500 proto udp comment 'ROS2 DDS Discovery'
sudo ufw allow from 10.0.0.0/8 to any port 7400:7500 proto udp comment 'ROS2 DDS Discovery'

# Allow DDS unicast data (UDP 7400-7500, TCP for some implementations)
sudo ufw allow from 192.168.0.0/16 to any port 7400:7500 proto tcp comment 'ROS2 DDS Data'
sudo ufw allow from 10.0.0.0/8 to any port 7400:7500 proto tcp comment 'ROS2 DDS Data'

# Reload firewall
sudo ufw reload

# Verify rules
sudo ufw status | grep DDS
```

**Expected Output**:
```
7400:7500/udp              ALLOW       192.168.0.0/16             # ROS2 DDS Discovery
7400:7500/udp              ALLOW       10.0.0.0/8                 # ROS2 DDS Discovery
7400:7500/tcp              ALLOW       192.168.0.0/16             # ROS2 DDS Data
7400:7500/tcp              ALLOW       10.0.0.0/8                 # ROS2 DDS Data
```

---

## Step 2: Configure ROS2 Environment (Both Machines)

**Critical**: Both machines must use the **same ROS_DOMAIN_ID** and **same RMW implementation**.

### On Tower

```bash
# Add to ~/.bashrc or Tower profile (~/.robot-simrc)
export ROS_DOMAIN_ID=0                               # Default (recommended)
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp         # CycloneDDS (recommended)
export CYCLONEDDS_URI='<CycloneDDS><Domain><General><NetworkInterfaceAddress>auto</NetworkInterfaceAddress></General></Domain></CycloneDDS>'

# Source profile
source ~/.robot-simrc  # or ~/.bashrc
```

### On Laptop

```bash
# Add to ~/.bashrc (or devcontainer startup)
export ROS_DOMAIN_ID=0                               # Default (recommended)
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CYCLONEDDS_URI='<CycloneDDS><Domain><General><NetworkInterfaceAddress>auto</NetworkInterfaceAddress></General></Domain></CycloneDDS>'

# Source ROS2 and workspace
source /opt/ros/humble/setup.bash
source ~/shadowhound/install/setup.bash  # Adjust path if in devcontainer
```

**Verify Configuration**:

```bash
# On both machines
echo $ROS_DOMAIN_ID        # Should be: 0 (default)
echo $RMW_IMPLEMENTATION   # Should be: rmw_cyclonedds_cpp
```

---

## Step 3: Start Isaac Sim on Tower

Isaac Sim can run in **GUI mode** (for visualization) or **headless mode** (for faster simulation).

### Option A: GUI Mode (with ROS2 bridge)

```bash
# On Tower
source ~/.robot-simrc
conda activate env_isaaclab

# Launch Isaac Sim with ROS2 bridge
cd ~/workspace/IsaacLab
./isaaclab.sh -p scripts/ros2_bridge_unitree_go2.py
```

**What this does**:
- Loads Unitree Go2 robot in Isaac Sim
- Starts ROS2 publishers for sensors (/camera/image_raw, /odom, /imu, /scan)
- Subscribes to /cmd_vel for robot control
- Publishes /joint_states for joint feedback

**Note**: You need to create `scripts/ros2_bridge_unitree_go2.py` (see below).

### Option B: Headless Mode (faster, no GUI)

```bash
# On Tower
source ~/.robot-simrc
conda activate env_isaaclab

# Launch headless
./isaaclab.sh --headless -p scripts/ros2_bridge_unitree_go2.py
```

**Performance**: Headless mode is 2-3x faster (no rendering overhead).

---

## Step 4: Create Isaac Sim ROS2 Bridge Script

Isaac Sim doesn't automatically publish ROS2 topics—you need a bridge script.

### Create `~/workspace/IsaacLab/scripts/ros2_bridge_unitree_go2.py`:

```python
#!/usr/bin/env python3
"""
Isaac Sim ROS2 Bridge for Unitree Go2

Publishes:
  - /camera/image_raw (sensor_msgs/Image) - Front camera
  - /odom (nav_msgs/Odometry) - Robot pose
  - /imu (sensor_msgs/Imu) - IMU data
  - /joint_states (sensor_msgs/JointState) - Joint positions
  - /scan (sensor_msgs/LaserScan) - LiDAR 2D scan

Subscribes:
  - /cmd_vel (geometry_msgs/Twist) - Velocity commands
"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from sensor_msgs.msg import Image, Imu, JointState, LaserScan
from nav_msgs.msg import Odometry
import numpy as np

# Isaac Sim imports
from omni.isaac.kit import SimulationApp
simulation_app = SimulationApp({"headless": False})  # Set True for headless

from omni.isaac.core import World
from omni.isaac.core.robots import Robot
from omni.isaac.core.utils.stage import add_reference_to_stage
from omni.isaac.sensor import Camera
import omni.isaac.core.utils.numpy.rotations as rot_utils

class IsaacSimROS2Bridge(Node):
    def __init__(self, world, robot):
        super().__init__('isaac_sim_ros2_bridge')
        self.world = world
        self.robot = robot
        
        # Publishers
        self.camera_pub = self.create_publisher(Image, '/camera/image_raw', 10)
        self.odom_pub = self.create_publisher(Odometry, '/odom', 10)
        self.imu_pub = self.create_publisher(Imu, '/imu', 10)
        self.joint_pub = self.create_publisher(JointState, '/joint_states', 10)
        self.scan_pub = self.create_publisher(LaserScan, '/scan', 10)
        
        # Subscriber
        self.cmd_vel_sub = self.create_subscription(
            Twist, '/cmd_vel', self.cmd_vel_callback, 10
        )
        
        self.get_logger().info('Isaac Sim ROS2 Bridge started')
        self.cmd_vel = Twist()
    
    def cmd_vel_callback(self, msg):
        """Apply velocity command to robot in simulation."""
        self.cmd_vel = msg
        # Apply to robot (implement based on your robot controller)
        # Example: self.robot.apply_action([msg.linear.x, msg.angular.z])
    
    def publish_camera(self):
        """Publish camera image."""
        # Get camera image from Isaac Sim
        # rgb = self.camera.get_rgba()[:, :, :3]  # Get RGB
        
        msg = Image()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'camera_link'
        msg.height = 480
        msg.width = 640
        msg.encoding = 'rgb8'
        msg.is_bigendian = False
        msg.step = 640 * 3
        # msg.data = rgb.flatten().tobytes()
        
        self.camera_pub.publish(msg)
    
    def publish_odom(self):
        """Publish odometry."""
        position, orientation = self.robot.get_world_pose()
        linear_vel, angular_vel = self.robot.get_linear_velocity(), self.robot.get_angular_velocity()
        
        msg = Odometry()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'odom'
        msg.child_frame_id = 'base_link'
        
        msg.pose.pose.position.x = float(position[0])
        msg.pose.pose.position.y = float(position[1])
        msg.pose.pose.position.z = float(position[2])
        
        msg.pose.pose.orientation.x = float(orientation[0])
        msg.pose.pose.orientation.y = float(orientation[1])
        msg.pose.pose.orientation.z = float(orientation[2])
        msg.pose.pose.orientation.w = float(orientation[3])
        
        msg.twist.twist.linear.x = float(linear_vel[0])
        msg.twist.twist.linear.y = float(linear_vel[1])
        msg.twist.twist.linear.z = float(linear_vel[2])
        
        self.odom_pub.publish(msg)
    
    def publish_imu(self):
        """Publish IMU data."""
        # Get IMU data from robot
        linear_accel = self.robot.get_linear_acceleration()
        angular_vel = self.robot.get_angular_velocity()
        _, orientation = self.robot.get_world_pose()
        
        msg = Imu()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'imu_link'
        
        msg.orientation.x = float(orientation[0])
        msg.orientation.y = float(orientation[1])
        msg.orientation.z = float(orientation[2])
        msg.orientation.w = float(orientation[3])
        
        msg.angular_velocity.x = float(angular_vel[0])
        msg.angular_velocity.y = float(angular_vel[1])
        msg.angular_velocity.z = float(angular_vel[2])
        
        msg.linear_acceleration.x = float(linear_accel[0])
        msg.linear_acceleration.y = float(linear_accel[1])
        msg.linear_acceleration.z = float(linear_accel[2])
        
        self.imu_pub.publish(msg)
    
    def publish_joint_states(self):
        """Publish joint states."""
        joint_positions = self.robot.get_joint_positions()
        joint_velocities = self.robot.get_joint_velocities()
        
        msg = JointState()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.name = [f'joint_{i}' for i in range(12)]  # Go2 has 12 joints
        msg.position = joint_positions.tolist()
        msg.velocity = joint_velocities.tolist()
        
        self.joint_pub.publish(msg)

def main():
    # Initialize Isaac Sim world
    world = World(stage_units_in_meters=1.0)
    
    # Load Unitree Go2 robot
    robot_path = "/Isaac/Robots/Unitree/Go2/go2.usd"  # Adjust path
    robot_prim_path = "/World/Go2"
    add_reference_to_stage(usd_path=robot_path, prim_path=robot_prim_path)
    
    robot = Robot(prim_path=robot_prim_path, name="go2")
    world.scene.add(robot)
    
    # Add camera (optional)
    # camera = Camera(prim_path=f"{robot_prim_path}/camera", ...)
    
    # Reset world
    world.reset()
    
    # Initialize ROS2
    rclpy.init()
    bridge = IsaacSimROS2Bridge(world, robot)
    
    # Simulation loop
    while simulation_app.is_running():
        world.step(render=True)
        
        if world.is_playing():
            # Publish topics at sim rate
            bridge.publish_odom()
            bridge.publish_imu()
            bridge.publish_joint_states()
            # bridge.publish_camera()  # Enable if camera configured
        
        rclpy.spin_once(bridge, timeout_sec=0)
    
    rclpy.shutdown()
    simulation_app.close()

if __name__ == "__main__":
    main()
```

**Note**: This is a **template**. You'll need to:
1. Adjust robot USD path based on your Isaac Sim setup
2. Implement velocity command application (`cmd_vel_callback`)
3. Configure camera if needed
4. Add LiDAR sensor for `/scan` topic

**See also**: Isaac Lab examples in `~/workspace/IsaacLab/source/extensions/omni.isaac.lab/omni/isaac/lab/envs/`

---

## Step 5: Verify ROS2 Topic Visibility

### On Tower (after starting Isaac Sim)

```bash
# List topics published by Isaac Sim
ros2 topic list

# Expected output:
#   /camera/image_raw
#   /odom
#   /imu
#   /joint_states
#   /scan
#   /cmd_vel

# Check topic rates
ros2 topic hz /odom
ros2 topic hz /camera/image_raw
```

### On Laptop

```bash
# Verify you can see Tower's topics
ros2 topic list

# Expected: Same topics as Tower (DDS discovery worked!)

# Echo topic to verify data
ros2 topic echo /odom --once

# Monitor camera feed
ros2 run image_view image_view --ros-args --remap image:=/camera/image_raw
```

**Troubleshooting**: If topics not visible, see "Troubleshooting" section below.

---

## Step 6: Launch Mission Agent on Laptop

Now that Isaac Sim is publishing sensor topics, launch the mission agent on your laptop.

### Terminal 1 (Laptop): Source Workspace

```bash
cd ~/shadowhound  # Or /workspaces/shadowhound in devcontainer
source install/setup.bash
export ROS_DOMAIN_ID=0                    # Default (recommended)
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
```

### Terminal 2 (Laptop): Launch Mission Agent

```bash
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    mock_robot:=false \
    agent_backend:=cloud
```

**What happens**:
- Mission agent starts and subscribes to `/camera/image_raw` (from Isaac Sim on Tower)
- Agent publishes to `/cmd_vel` (consumed by Isaac Sim)
- Web UI available at `http://localhost:8080`

### Terminal 3 (Laptop): Send Mission Command

```bash
# Send test mission
ros2 topic pub --once /mission_command std_msgs/String \
    "data: 'Move forward 1 meter and stop'"
```

**Expected**:
1. Mission agent receives command
2. Generates skill plan (DIMOS)
3. Publishes velocity commands to `/cmd_vel`
4. Isaac Sim on Tower receives commands and moves robot
5. Mission agent receives updated `/odom` and `/camera/image_raw` from sim
6. Mission completes

---

## Step 7: Visualize with RViz2 (Optional)

Launch RViz2 on laptop to visualize sensor data:

```bash
# On Laptop
rviz2
```

**RViz2 Configuration**:
1. Set **Fixed Frame** to `odom`
2. Add displays:
   - **RobotModel** (topic: `/robot_description` if published)
   - **Camera** (topic: `/camera/image_raw`)
   - **LaserScan** (topic: `/scan`)
   - **Odometry** (topic: `/odom`)
   - **TF** (shows transforms)

**Save configuration**: File → Save Config As → `shadowhound_isaac.rviz`

---

## Architecture Diagram: Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                         Laptop Workflow                          │
└──────────────────────────────────────────────────────────────────┘

1. User sends mission command
      ↓
   /mission_command topic (Laptop → Laptop, local)
      ↓
2. mission_agent receives command
      ↓
3. mission_agent calls DIMOS to plan skills
      ↓
4. DIMOS executes skills, publishes /cmd_vel
      ↓
   /cmd_vel topic (Laptop → Tower, DDS multicast)
      ↓
5. Isaac Sim on Tower receives /cmd_vel
      ↓
6. Isaac Sim applies velocity to robot in physics sim
      ↓
7. Isaac Sim publishes updated sensor data
      ↓
   /odom, /camera/image_raw, /imu (Tower → Laptop, DDS multicast)
      ↓
8. mission_agent receives sensor data
      ↓
9. mission_agent updates mission state
      ↓
10. Loop back to step 4 until mission complete
```

---

## Performance Tuning

### Reduce Network Bandwidth (Camera Compression)

Isaac Sim camera at 30 Hz × 640×480 RGB = ~27 MB/s. Compress it:

**On Tower (Isaac Sim bridge)**:

```python
# Add to Isaac Sim bridge script
from sensor_msgs.msg import CompressedImage
import cv2

self.camera_compressed_pub = self.create_publisher(
    CompressedImage, '/camera/compressed', 10
)

def publish_camera_compressed(self):
    rgb = self.camera.get_rgba()[:, :, :3]
    
    # Compress to JPEG
    _, jpeg = cv2.imencode('.jpg', rgb, [cv2.IMWRITE_JPEG_QUALITY, 85])
    
    msg = CompressedImage()
    msg.header.stamp = self.get_clock().now().to_msg()
    msg.header.frame_id = 'camera_link'
    msg.format = 'jpeg'
    msg.data = jpeg.tobytes()
    
    self.camera_compressed_pub.publish(msg)
```

**On Laptop (mission agent)**:

Already subscribes to `/camera/compressed` (see `mission_agent.py`).

**Bandwidth Reduction**: ~27 MB/s → ~2 MB/s (13x reduction)

### Reduce Topic Rates

```python
# In Isaac Sim bridge
import time

last_camera_time = 0
camera_rate = 10  # Hz (instead of 30)

def publish_camera_compressed(self):
    global last_camera_time
    now = time.time()
    if now - last_camera_time < 1.0 / camera_rate:
        return  # Skip frame
    last_camera_time = now
    
    # ... publish camera ...
```

### Use CycloneDDS Tuning

Create `~/.cyclonedds.xml` on both machines:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<CycloneDDS xmlns="https://cdds.io/config">
  <Domain>
    <General>
      <NetworkInterfaceAddress>auto</NetworkInterfaceAddress>
      <MaxMessageSize>65500</MaxMessageSize>
    </General>
    <Internal>
      <Watermarks>
        <WhcHigh>500kB</WhcHigh>
      </Watermarks>
    </Internal>
  </Domain>
</CycloneDDS>
```

Then:
```bash
export CYCLONEDDS_URI=file://$HOME/.cyclonedds.xml
```

---

## Troubleshooting

### Issue: Topics Not Visible Between Machines

**Symptom**: `ros2 topic list` on laptop doesn't show Isaac Sim topics from Tower.

**Solutions**:

1. **Verify ROS_DOMAIN_ID matches**:
   ```bash
   # On both machines
   echo $ROS_DOMAIN_ID  # Should be 0 (default)
   ```

2. **Check firewall** (on Tower):
   ```bash
   sudo ufw status | grep 7400
   # Should show ALLOW from 192.168.0.0/16
   ```

3. **Test multicast** (on both machines):
   ```bash
   # Install multicast test tool
   sudo apt install iperf3
   
   # On Tower
   iperf3 -s -B 239.255.0.1
   
   # On Laptop
   iperf3 -c 239.255.0.1 -u -b 10M -t 10
   ```

4. **Check network connectivity**:
   ```bash
   # From laptop
   ping TOWER_IP
   traceroute TOWER_IP
   ```

5. **Try unicast mode** (fallback if multicast broken):
   ```bash
   # On both machines, add to ~/.bashrc
   export ROS_LOCALHOST_ONLY=0
   export ROS_STATIC_PEERS=TOWER_IP,LAPTOP_IP
   ```

### Issue: High Latency (>100ms)

**Symptom**: Delay between sending `/cmd_vel` and seeing robot move in sim.

**Solutions**:

1. Check network bandwidth:
   ```bash
   iperf3 -s  # On Tower
   iperf3 -c TOWER_IP  # On Laptop
   # Should show >100 Mbps on gigabit LAN
   ```

2. Reduce camera rate (see "Performance Tuning" above)

3. Use wired Ethernet instead of WiFi

4. Check Tower CPU/GPU load:
   ```bash
   # On Tower
   htop       # CPU usage
   nvidia-smi # GPU usage
   ```

### Issue: Camera Feed Not Showing

**Symptom**: `/camera/image_raw` topic exists but no data in RViz2.

**Solutions**:

1. Verify topic is publishing:
   ```bash
   ros2 topic hz /camera/image_raw
   # Should show ~10-30 Hz
   ```

2. Check message content:
   ```bash
   ros2 topic echo /camera/image_raw --once
   # Should show image dimensions
   ```

3. Verify image encoding:
   ```bash
   ros2 topic echo /camera/image_raw --once | grep encoding
   # Should be: rgb8 or bgr8
   ```

4. Try compressed topic instead:
   ```bash
   ros2 run image_view image_view --ros-args \
       --remap image:=/camera/compressed \
       --param image_transport:=compressed
   ```

### Issue: Mission Agent Can't Execute Skills

**Symptom**: Mission agent receives command but robot doesn't move in sim.

**Solutions**:

1. Verify mission agent is publishing `/cmd_vel`:
   ```bash
   ros2 topic echo /cmd_vel
   # Should show Twist messages when mission runs
   ```

2. Check Isaac Sim is subscribing:
   ```bash
   ros2 topic info /cmd_vel
   # Should show subscription from Isaac Sim bridge
   ```

3. Enable debug logging in mission agent:
   ```bash
   ros2 launch shadowhound_mission_agent mission_agent.launch.py \
       mock_robot:=false \
       --ros-args --log-level debug
   ```

4. Verify DIMOS skills are using correct topic names:
   ```python
   # In DIMOS robot configuration
   cmd_vel_topic = '/cmd_vel'  # Should match Isaac Sim subscription
   ```

---

## Integration with Tower Data Lake (Optional)

While developing on laptop, you can still log data to Tower's MinIO/MLflow:

### On Laptop

```bash
# Configure Tower access
export AWS_ENDPOINT_URL=http://TOWER_IP:9000
export AWS_ACCESS_KEY_ID=<from Tower>
export AWS_SECRET_ACCESS_KEY=<from Tower>
export MLFLOW_TRACKING_URI=http://TOWER_IP:5001
export MLFLOW_S3_ENDPOINT_URL=http://TOWER_IP:9000

# Launch mission agent with logging enabled
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    mock_robot:=false \
    agent_backend:=cloud \
    enable_data_logging:=true
```

**What happens**:
- Mission agent logs to MLflow on Tower (experiments tracked)
- Camera frames uploaded to MinIO `sensor-data/laptop/`
- Trajectories saved for later analysis

**See**: `docs/deployment/go2_ros2_sdk_tower_integration.md` for logging patterns.

---

## Development Tips

### 1. Fast Iteration with Code Changes

**Workflow**:
1. Edit Python code in VS Code on laptop
2. Rebuild only changed package:
   ```bash
   colcon build --packages-select shadowhound_mission_agent --symlink-install
   source install/setup.bash
   ```
3. Restart mission agent (Isaac Sim keeps running on Tower)

**Tip**: Use `--symlink-install` so Python changes don't require rebuild.

### 2. Debug with Breakpoints

**VS Code launch.json**:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Mission Agent",
      "type": "python",
      "request": "launch",
      "module": "shadowhound_mission_agent.mission_agent",
      "env": {
        "ROS_DOMAIN_ID": "42",
        "RMW_IMPLEMENTATION": "rmw_cyclonedds_cpp"
      },
      "console": "integratedTerminal"
    }
  ]
}
```

**Usage**: Set breakpoint in `mission_agent.py`, press F5, send mission command, inspect state.

### 3. Mock Sensor Data (No Isaac Sim)

If Isaac Sim isn't available, publish mock topics:

```bash
# Terminal 1: Mock camera
ros2 run image_publisher image_publisher_node \
    ~/test_image.jpg --ros-args --remap image_raw:=/camera/image_raw

# Terminal 2: Mock odometry
ros2 topic pub /odom nav_msgs/Odometry \
    "header:
      stamp: {sec: 0, nanosec: 0}
      frame_id: 'odom'
    child_frame_id: 'base_link'
    pose:
      pose:
        position: {x: 0.0, y: 0.0, z: 0.0}
        orientation: {x: 0.0, y: 0.0, z: 0.0, w: 1.0}"
```

---

## Summary: Complete Workflow

1. **Tower**: Start Isaac Sim with ROS2 bridge (publishes sensor topics)
2. **Tower**: Firewall configured for DDS (ports 7400-7500)
3. **Both**: ROS_DOMAIN_ID=42, RMW=CycloneDDS
4. **Laptop**: Verify topic visibility (`ros2 topic list`)
5. **Laptop**: Launch mission agent (`ros2 launch shadowhound_mission_agent ...`)
6. **Laptop**: Send mission command (`ros2 topic pub /mission_command ...`)
7. **Watch**: Robot moves in Isaac Sim, agent logs to terminal/web UI
8. **Iterate**: Edit code on laptop, rebuild, restart agent (sim stays running)

---

## References

- Isaac Sim ROS2 Bridge: https://docs.omniverse.nvidia.com/isaacsim/latest/ros2_tutorials/index.html
- ROS2 DDS Security: https://docs.ros.org/en/humble/Tutorials/Advanced/Security/Introducing-ros2-security.html
- CycloneDDS Configuration: https://github.com/eclipse-cyclonedds/cyclonedds
- ShadowHound Mission Agent: `docs/software/packages/shadowhound_mission_agent/`

---

**Status**: Development workflow documented. Isaac Sim ROS2 bridge is a template—needs customization for your specific robot setup.
