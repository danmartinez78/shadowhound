---
tags: [simulation, architecture, hardware]
status: complete
related: 
  - ../networking/networking_hub.md
  - ../hardware/unitree_go2_specs.md
summary: >
  Explains the data flow from physical Go2 robot hardware through go2_driver_node
  to ROS2 topics, and how Isaac Sim replaces this in simulation.
---

# Robot Data Flow Architecture

## Purpose

This document explains how sensor data flows from the physical Unitree Go2 robot to ROS2 topics, the role of `go2_driver_node`, and how Isaac Sim replaces this pipeline in simulation.

---

## Physical Robot Architecture

### Complete Data Flow

```
┌─────────────────────────────────────────────────────────┐
│  Physical Go2 Robot (192.168.x.x)                       │
│  ┌──────────┐  ┌─────┐  ┌────────┐  ┌────────┐        │
│  │ IMU      │  │LiDAR│  │ Camera │  │ Motors │        │
│  └────┬─────┘  └──┬──┘  └───┬────┘  └───┬────┘        │
│       │           │          │           │              │
│       └───────────┴──────────┴───────────┘              │
│                   │                                      │
│       ┌───────────▼──────────┐                          │
│       │ Unitree Firmware     │                          │
│       │ (onboard computer)   │                          │
│       └───────────┬──────────┘                          │
└───────────────────┼──────────────────────────────────────┘
                    │
                    │ Connection Layer
                    │ (WebRTC or CycloneDDS)
                    ▼
┌───────────────────────────────────────────────────────────┐
│  Your Laptop (192.168.10.167)                             │
│  ┌────────────────────────────────────────────────────┐  │
│  │  go2_driver_node (ROS2)                            │  │
│  │  ┌──────────────────┐                              │  │
│  │  │ Connection Layer │ ← Receives proprietary data  │  │
│  │  │ (WebRTC/DDS)     │                              │  │
│  │  └────────┬─────────┘                              │  │
│  │           │                                         │  │
│  │  ┌────────▼────────┐                               │  │
│  │  │ Data Converter  │ ← Decodes & transforms       │  │
│  │  └────────┬────────┘                               │  │
│  │           │                                         │  │
│  │  ┌────────▼────────┐                               │  │
│  │  │ ROS2 Publishers │ ← Publishes standard topics  │  │
│  │  └────────┬────────┘                               │  │
│  └───────────┼─────────────────────────────────────────┘  │
│              │                                            │
│     ┌────────┴────────┐                                  │
│     ▼                 ▼                                  │
│  /odom            /imu                                   │
│  /go2_states      /joint_states                          │
│  /camera/image_raw /scan                                 │
└──────────────────────────────────────────────────────────┘
```

---

## Connection Modes

### WebRTC Mode (WiFi)

**Use Case**: Full functionality with high-level API commands

**Data Path**:
1. Robot sensors → Unitree firmware
2. Firmware packages data as binary messages
3. **WebRTC connection** (encrypted, WiFi)
4. `go2_driver_node` receives via WebRTC data channel
5. Decodes binary → converts to ROS2 messages
6. Publishes standard topics

**Code Location**: `go2_robot_sdk/infrastructure/webrtc/go2_connection.py`

```python
def on_data_channel_message(self, message: Union[str, bytes]) -> None:
    """Robot sends binary sensor data through WebRTC"""
    if isinstance(message, bytes):
        # Decompress and decode binary message from robot
        msgobj = legacy_deal_array_buffer(message, perform_decode=self.decode_lidar)
    
    # Forward to driver node for ROS2 publishing
    if self.on_message:
        self.on_message(message, msgobj, self.robot_num)
```

**Publishes**:
- `/odom` (nav_msgs/Odometry)
- `/imu` (go2_interfaces/IMU)
- `/go2_states` (go2_interfaces/Go2State)
- `/joint_states` (sensor_msgs/JointState)
- `/camera/image_raw` (sensor_msgs/Image)
- `/point_cloud2` (sensor_msgs/PointCloud2)

**Capabilities**:
- ✅ All sensor data
- ✅ High-level API (sit, stand, wave, dance)
- ✅ Video streaming
- ✅ Works over WiFi (no cables)

**Limitations**:
- ⚠️ Higher latency (~10-50ms)
- ⚠️ Requires robot on WiFi network
- ⚠️ WiFi IP different from Ethernet IP

---

### CycloneDDS Mode (Ethernet)

**Use Case**: Lower latency, basic control (no high-level API)

**Data Path**:
1. Robot sensors → Unitree firmware  
2. Firmware publishes **proprietary ROS2 topics**:
   - `/lowstate` (go2_interfaces/LowState)
   - `/utlidar/cloud` (sensor_msgs/PointCloud2)
   - `/utlidar/robot_pose` (geometry_msgs/PoseStamped)
3. **CycloneDDS** (UDP multicast, Ethernet)
4. `go2_driver_node` **subscribes** to proprietary topics
5. Converts to standard ROS2 format
6. Republishes standard topics

**Code Location**: `go2_driver_node.py` line 216

```python
# CycloneDDS support
if self.config.conn_type == 'cyclonedds':
    # SUBSCRIBE to robot's proprietary topics
    self.create_subscription(
        LowState, 'lowstate',  # ← Unitree proprietary format
        self._on_cyclonedds_low_state, qos_profile)
    self.create_subscription(
        PoseStamped, '/utlidar/robot_pose',
        self._on_cyclonedds_pose, qos_profile)
    self.create_subscription(
        PointCloud2, '/utlidar/cloud',
        self._on_cyclonedds_lidar, qos_profile)
```

**Publishes** (after conversion):
- `/odom` (nav_msgs/Odometry)
- `/imu` (go2_interfaces/IMU)
- `/go2_states` (go2_interfaces/Go2State)
- `/joint_states` (sensor_msgs/JointState)
- `/scan` (sensor_msgs/LaserScan) - converted from LiDAR

**Capabilities**:
- ✅ All sensor data
- ✅ Direct motor control (`/cmd_vel`)
- ✅ Very low latency (~1ms)
- ✅ Stable Ethernet connection

**Limitations**:
- ❌ NO high-level API (sit/stand/wave don't work)
- ❌ Requires Ethernet cable
- ❌ No video streaming in CycloneDDS mode

---

## Why go2_driver_node is Always Needed (Physical Robot)

**Key Point**: The Unitree Go2 **never** publishes standard ROS2 topics directly. It always uses proprietary formats.

### WebRTC Mode
- Robot sends: **Binary WebRTC messages** (proprietary)
- Driver converts to: **Standard ROS2 topics**

### CycloneDDS Mode  
- Robot sends: **`/lowstate` (go2_interfaces/LowState)** (proprietary)
- Driver converts to: **`/odom`, `/imu`, `/go2_states`** (standard)

**Without go2_driver_node**, you would need to:
- Decode Unitree's proprietary binary format
- Handle WebRTC encryption/connection
- Convert LowState messages to standard types
- Manage robot state machine
- Handle firmware quirks

`go2_driver_node` is Unitree's **protocol translator**.

---

## Isaac Sim Architecture (Simulation)

### Why No Driver Needed

Isaac Sim **replaces the entire robot + driver pipeline**:

```
┌──────────────────────────────────────┐
│  Tower (Isaac Sim)                   │
│  ┌────────────────────────────────┐  │
│  │  Simulated Go2                 │  │
│  │  - Physics engine              │  │
│  │  - Synthetic sensors           │  │
│  │  - Joint simulation            │  │
│  └────────┬───────────────────────┘  │
│           │                           │
│  ┌────────▼───────────────────────┐  │
│  │  ROS2 Publishers               │  │
│  │  (built into Isaac Sim)        │  │
│  │  - Already standard format!    │  │
│  └────────┬───────────────────────┘  │
└───────────┼───────────────────────────┘
            │
            │ ROS2 Topics (CycloneDDS)
            │ /robot0 namespace
            ▼
┌───────────────────────────────────────┐
│  Your Laptop                          │
│  - Mission Agent (subscribes)         │
│  - Nav2 (for navigation)              │
│  - SLAM (for mapping)                 │
│  - (No driver needed!)                │
└───────────────────────────────────────┘
```

**Isaac Sim publishes directly**:
- `/robot0/odom` (nav_msgs/Odometry) ✅ Already standard!
- `/robot0/imu` (sensor_msgs/Imu) ✅ Already standard!
- `/robot0/front_cam/rgb` (sensor_msgs/Image) ✅ Already standard!
- `/robot0/joint_states` (sensor_msgs/JointState) ✅ Already standard!

No conversion needed → No driver needed!

---

## Topic Comparison

| Source | Topic Name | Message Type | Driver Needed? |
|--------|-----------|--------------|----------------|
| **Physical (WebRTC)** | *(binary WebRTC)* | Proprietary binary | ✅ YES |
| **Physical (CycloneDDS)** | `/lowstate` | go2_interfaces/LowState | ✅ YES |
| **Isaac Sim** | `/robot0/odom` | nav_msgs/Odometry | ❌ NO |

---

## Launch Configuration Differences

### Physical Robot (with driver)

```bash
ros2 launch go2_robot_sdk robot.launch.py \
    rviz2:=true \
    nav2:=true \
    slam:=true \
    foxglove:=true
```

**Launches**:
1. ✅ `go2_driver_node` - Connects to robot, publishes topics
2. ✅ Nav2 - Navigation stack
3. ✅ SLAM Toolbox - Mapping
4. ✅ Foxglove Bridge - Visualization
5. ✅ RViz2 - 3D visualization
6. ✅ Robot state publisher - TF transforms

### Isaac Sim (without driver)

```bash
# On Tower: Isaac Sim running (publishes /robot0/* topics)

# On Laptop:
ros2 launch shadowhound_bringup sim_autonomy.launch.py \
    rviz2:=true \
    nav2:=true \
    slam:=true \
    foxglove:=true
```

**Launches**:
1. ❌ ~~go2_driver_node~~ (sim replaces this!)
2. ✅ Nav2 - Navigation stack
3. ✅ SLAM Toolbox - Mapping  
4. ✅ Foxglove Bridge - Visualization
5. ✅ RViz2 - 3D visualization
6. ✅ Robot state publisher - TF transforms

**Key Difference**: Everything except the driver node!

---

## Performance Characteristics

### Physical Robot

| Mode | Latency | Bandwidth | Capabilities |
|------|---------|-----------|--------------|
| WebRTC | ~10-50ms | Medium | Full API + video |
| CycloneDDS | ~1ms | High | Basic control only |

### Isaac Sim

| Connection | Latency | Bandwidth | Capabilities |
|-----------|---------|-----------|--------------|
| Network ROS2 | ~5-10ms | High | All sensors + control |

---

## Troubleshooting

### "Why does my code work in sim but not on robot?"

**Check**: Are you subscribing to the correct topics?

- **Sim**: `/robot0/odom`
- **Robot**: `/odom` (standard) or need remapping

### "Robot not publishing topics!"

**Check**: Is `go2_driver_node` running?

```bash
ros2 node list | grep go2_driver
# Should see: /go2_driver_node

ros2 topic list | grep -E "odom|imu|go2_states"
# Should see standard topics
```

### "Sim topics not visible from laptop!"

**Check**: Network ROS2 configuration

```bash
# Both machines need:
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Verify connectivity
ros2 topic list | grep robot0
```

---

## References

- [Unitree Go2 SDK Documentation](https://github.com/unitreerobotics/unitree_ros2)
- [go2_ros2_sdk Architecture](../software/autodoc/go2_robot_sdk.md)
- [Network Configuration](../networking/networking_hub.md)
- [Isaac Sim Setup](isaac_sim_setup.md)

---

## Summary

**Physical Robot**: 
- Hardware → Unitree Firmware → **go2_driver_node** → Standard ROS2 topics
- Driver **required** for both WebRTC and CycloneDDS modes

**Isaac Sim**:
- Simulated hardware → **Isaac Sim ROS2 bridge** → Standard ROS2 topics  
- Driver **not needed** - sim is already ROS2-native

This architecture lets us develop and test autonomy code in simulation with the same ROS2 interface as the physical robot!
