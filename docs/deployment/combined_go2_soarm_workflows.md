---
tags: [deployment, integration, go2, so-arm-101, mobile-manipulation, workflows]
status: draft
related: [go2_ros2_sdk_tower_integration.md, tower_lerobot_soarm101_setup.md]
summary: >
  Integration patterns for combining Unitree Go2 navigation with SO-ARM 101 manipulation on Tower.
---

# Combined Go2 + SO-ARM Workflows

## Overview

This guide explores integration patterns for combining **Unitree Go2 quadruped navigation** with **SO-ARM 101 robotic arm manipulation** into unified mobile manipulation workflows.

**Status**: ⚠️ **Conceptual** - Integration layer not yet implemented

**Purpose**: Document potential workflows and integration architecture for future development.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Tower (Coordination & Data)                                │
│                                                             │
│  ┌───────────────┐              ┌──────────────────┐       │
│  │  ROS2 Bridge  │◄────────────►│  LeRobot Manager │       │
│  │  (go2_driver) │              │  (soarm_control) │       │
│  └───────┬───────┘              └────────┬─────────┘       │
│          │                               │                 │
│          │  ┌─────────────────────────┐  │                 │
│          └─►│  Task Coordinator       │◄─┘                 │
│             │  (mobile_manipulation)  │                    │
│             └─────────┬───────────────┘                    │
│                       │                                    │
│                       ▼                                    │
│             ┌─────────────────────┐                        │
│             │  MinIO + MLflow     │                        │
│             │  (shared data)      │                        │
│             └─────────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
           ↑                              ↑
           │                              │
    ┌──────┴─────┐                ┌──────┴──────┐
    │  Unitree   │                │  SO-ARM 101 │
    │    Go2     │                │   (USB)     │
    │ (Network)  │                │             │
    └────────────┘                └─────────────┘
```

---

## Integration Patterns

### Pattern 1: Sequential Operations

**Description**: Go2 navigates to location, then SO-ARM performs manipulation.

**Example**: Fetch-and-place task
1. Go2 navigates to object location
2. Go2 stops and holds position
3. SO-ARM (mounted on Go2 or nearby) picks up object
4. Go2 navigates to destination
5. SO-ARM places object

**Implementation**:
```python
# Pseudo-code (not yet implemented)
from shadowhound_mission_agent import MissionCoordinator
from lerobot.robot import SO101Robot

coordinator = MissionCoordinator()

# Define mission
mission = {
    "steps": [
        {"type": "navigate", "robot": "go2", "goal": {"x": 2.0, "y": 1.0}},
        {"type": "wait", "duration": 1.0},
        {"type": "manipulate", "robot": "soarm", "action": "pick_object"},
        {"type": "navigate", "robot": "go2", "goal": {"x": 0.0, "y": 0.0}},
        {"type": "manipulate", "robot": "soarm", "action": "place_object"}
    ]
}

# Execute
coordinator.execute_mission(mission)
```

**Data Collection**:
```python
# Record synchronized data to MinIO
import boto3
from datetime import datetime

s3 = boto3.client('s3', endpoint_url='http://tower:9000')

# Go2 sensor data
s3.upload_file(
    '/tmp/go2_odom.bag',
    'mobile-manipulation',
    f'missions/{mission_id}/go2_odometry.bag'
)

# SO-ARM demonstration data
s3.upload_file(
    '/tmp/soarm_episode.hdf5',
    'mobile-manipulation',
    f'missions/{mission_id}/soarm_manipulation.hdf5'
)
```

### Pattern 2: Coordinated Control

**Description**: Go2 and SO-ARM operate simultaneously with coordination.

**Example**: Mobile manipulation with dynamic base
1. Go2 tracks moving target
2. SO-ARM reaches for object while Go2 moves
3. Go2 adjusts position based on SO-ARM reach
4. SO-ARM grasps object during movement

**Implementation**:
```python
# Pseudo-code (not yet implemented)
from threading import Thread

def go2_control_loop():
    """Go2 tracks target while considering arm reach."""
    while not mission_complete:
        target_pose = get_target_location()
        arm_reach = get_soarm_reach_estimate()
        
        # Adjust goal to keep target in arm's workspace
        adjusted_goal = adjust_for_arm_workspace(target_pose, arm_reach)
        
        go2.move_to(adjusted_goal)
        time.sleep(0.1)

def soarm_control_loop():
    """SO-ARM reaches for object considering base motion."""
    while not mission_complete:
        object_pose = get_object_pose()
        base_velocity = go2.get_velocity()
        
        # Compensate for base motion
        arm_goal = compensate_for_base_motion(object_pose, base_velocity)
        
        soarm.move_to(arm_goal)
        time.sleep(0.01)  # Higher frequency for arm control

# Run both loops
Thread(target=go2_control_loop).start()
Thread(target=soarm_control_loop).start()
```

**Challenges**:
- **Timing synchronization**: Go2 (50Hz) vs SO-ARM (100Hz+)
- **Coordinate transforms**: Base frame → arm base → end effector
- **Vibration compensation**: Go2 movement affects SO-ARM accuracy

### Pattern 3: Shared Perception

**Description**: Both robots contribute sensor data for unified perception.

**Example**: Object search and grasp
1. Go2 cameras scan environment (wide FOV)
2. Detected objects fed to SO-ARM policy
3. SO-ARM wrist camera provides close-up view
4. Combined perception guides manipulation

**Implementation**:
```python
# Pseudo-code (not yet implemented)
from sensor_msgs.msg import Image
from lerobot.perception import ObjectDetector

class SharedPerception:
    def __init__(self):
        # Subscribe to Go2 cameras
        self.go2_cam_sub = rospy.Subscriber(
            '/go2/camera/image_raw',
            Image,
            self.go2_camera_callback
        )
        
        # Subscribe to SO-ARM wrist camera
        self.soarm_cam_sub = rospy.Subscriber(
            '/soarm/wrist_camera/image_raw',
            Image,
            self.soarm_camera_callback
        )
        
        self.detector = ObjectDetector()
        
    def go2_camera_callback(self, msg):
        """Process wide-FOV navigation camera."""
        detections = self.detector.detect(msg)
        
        # Update object locations in world frame
        for obj in detections:
            self.object_map[obj.id] = self.transform_to_world(obj.pose)
    
    def soarm_camera_callback(self, msg):
        """Process close-up wrist camera for grasping."""
        grasp_pose = self.detector.estimate_grasp_pose(msg)
        
        # Refine object pose with wrist camera data
        if grasp_pose:
            self.current_grasp_target = grasp_pose
```

**Data Fusion**:
```python
# Store multi-modal sensor data in MinIO
mission_data = {
    "timestamp": datetime.now().isoformat(),
    "go2_cameras": {
        "front": "s3://missions/{id}/go2_front_camera.mp4",
        "side": "s3://missions/{id}/go2_side_camera.mp4"
    },
    "soarm_cameras": {
        "wrist": "s3://missions/{id}/soarm_wrist_camera.mp4"
    },
    "go2_odometry": "s3://missions/{id}/go2_odom.bag",
    "soarm_states": "s3://missions/{id}/soarm_joint_states.hdf5",
    "detections": "s3://missions/{id}/object_detections.json"
}

# Upload to MLflow as experiment artifact
mlflow.log_dict(mission_data, "mission_metadata.json")
```

---

## Physical Integration Options

### Option 1: Mounted Arm (Future Hardware)

**Description**: SO-ARM 101 permanently mounted on Go2 back.

**Pros**:
- ✅ True mobile manipulation
- ✅ Single unified robot
- ✅ Compact footprint

**Cons**:
- ❌ Reduces Go2 payload capacity
- ❌ Affects Go2 center of gravity
- ❌ Requires custom mounting bracket
- ❌ Power sharing challenges (7.4V for arm, battery drain)

**Mechanical Requirements**:
- Custom 3D-printed mounting plate for Go2 back
- Vibration dampening (Go2 movement affects arm precision)
- Cable management (USB + power routing)
- Weight balance (SO-ARM ~500g + motors)

**Electrical Requirements**:
- Separate 7.4V battery for SO-ARM (Go2 battery not accessible)
- USB hub for motor bus adapters
- Cable strain relief (moving joints)

### Option 2: Stationary Arm with Mobile Base

**Description**: SO-ARM at fixed station, Go2 brings objects to it.

**Pros**:
- ✅ No mechanical integration needed
- ✅ Arm has stable platform (better precision)
- ✅ Independent power supplies
- ✅ Easier to implement

**Cons**:
- ❌ Limited workspace (arm's reach from station)
- ❌ Requires precise Go2 positioning
- ❌ Not truly mobile manipulation

**Workflow**:
1. Go2 picks up object (gripper attachment on Go2)
2. Go2 navigates to SO-ARM station
3. Go2 positions object in arm's workspace
4. SO-ARM performs manipulation
5. Go2 retrieves result and returns

### Option 3: Coordinated Separate Robots

**Description**: Go2 and SO-ARM operate in same environment but separately.

**Pros**:
- ✅ No hardware modifications
- ✅ Independent operations
- ✅ Can work in parallel on different tasks

**Cons**:
- ❌ Not integrated
- ❌ Requires collision avoidance
- ❌ Limited coordination

**Use Case**: Research environment where both robots collect data independently.

---

## Data Management

### Unified Dataset Format

Store combined Go2 + SO-ARM missions in MinIO:

```
s3://mobile-manipulation/
├── missions/
│   ├── {mission_id}/
│   │   ├── metadata.json              # Mission description
│   │   ├── go2/
│   │   │   ├── odometry.bag           # ROS2 bag with /odom, /imu
│   │   │   ├── camera_front.mp4       # Compressed video
│   │   │   ├── camera_side.mp4
│   │   │   └── joint_states.csv       # Go2 leg positions
│   │   ├── soarm/
│   │   │   ├── demonstrations.hdf5    # LeRobot format
│   │   │   ├── wrist_camera.mp4       # Manipulation view
│   │   │   └── joint_states.csv       # Arm positions
│   │   └── synchronized/
│   │       ├── timestamps.csv         # Sync both robots
│   │       └── object_detections.json # Shared perception
│   └── ...
└── models/
    ├── go2_navigation/                # Go2-specific policies
    ├── soarm_manipulation/            # SO-ARM-specific policies
    └── coordinated/                   # Combined policies
        └── mobile_manipulation_v1.pth
```

### MLflow Experiment Structure

```python
import mlflow

mlflow.set_tracking_uri("http://tower:5001")

# Create experiment for mobile manipulation
mlflow.set_experiment("mobile_manipulation")

with mlflow.start_run(run_name="fetch_and_place_v1"):
    # Log parameters
    mlflow.log_params({
        "go2_policy": "nav2_costmap",
        "soarm_policy": "ACT",
        "coordination": "sequential",
        "mission_duration": 120.0  # seconds
    })
    
    # Log metrics
    mlflow.log_metrics({
        "success_rate": 0.85,
        "go2_nav_accuracy": 0.95,
        "soarm_grasp_success": 0.90,
        "total_time": 118.5
    })
    
    # Log artifacts
    mlflow.log_artifact("s3://mobile-manipulation/missions/001/metadata.json")
    mlflow.log_artifact("models/coordinated/mobile_manipulation_v1.pth")
```

---

## Training Workflows

### Stage 1: Independent Training

Train each robot separately:

**Go2 Navigation**:
```bash
# Use Isaac Sim for Go2 training
cd ~/workspace/IsaacLab
./isaaclab.sh -p source/standalone/workflows/rsl_rl/train.py \
  --task Go2-Navigate-v0 \
  --num_envs 4096

# Export policy to MinIO
aws s3 cp policy.pth s3://models/go2_navigation/checkpoint_1000.pth
```

**SO-ARM Manipulation**:
```bash
# Use LeRobot for SO-ARM training
lerobot-train \
  --config-path lerobot/configs/policy/act_so101_real.yaml \
  --dataset-repo-id ${HF_USER}/pick_and_place \
  --output-dir /srv/robot-data/lerobot_policies

# Upload to MinIO
aws s3 cp output/policy.pth s3://models/soarm_manipulation/pick_place_v1.pth
```

### Stage 2: Sim-to-Real Transfer

1. Train navigation in Isaac Sim
2. Train manipulation with real SO-ARM demonstrations
3. Combine policies with coordination layer

```python
# Pseudo-code for combined policy
class MobileManipulationPolicy:
    def __init__(self):
        # Load pre-trained policies
        self.go2_policy = load_policy("s3://models/go2_navigation/checkpoint_1000.pth")
        self.soarm_policy = load_policy("s3://models/soarm_manipulation/pick_place_v1.pth")
        
        # Coordination layer (trainable)
        self.coordinator = CoordinationNet()
    
    def forward(self, observation):
        # Decompose observation
        go2_obs = observation['go2']  # Cameras, IMU, joint states
        soarm_obs = observation['soarm']  # Wrist camera, joint states
        
        # Get individual actions
        go2_action = self.go2_policy(go2_obs)
        soarm_action = self.soarm_policy(soarm_obs)
        
        # Coordinate actions
        combined_action = self.coordinator(go2_action, soarm_action, observation)
        
        return combined_action
```

### Stage 3: End-to-End Training (Future)

Train unified policy on combined robot:

```python
# Collect demonstrations with both robots
lerobot-record \
  --robot-config configs/combined/go2_soarm.yaml \
  --task mobile_pick_and_place \
  --num-episodes 100 \
  --output /srv/robot-data/mobile_manip_dataset

# Train end-to-end policy
python train_mobile_manipulation.py \
  --dataset /srv/robot-data/mobile_manip_dataset \
  --policy-type vla  # Vision-Language-Action model
  --output /srv/robot-data/models/mobile_manip_vla_v1
```

---

## Implementation Roadmap

### Phase 1: Data Collection (Current)
- ✅ Go2 sensor logging to MinIO (implemented in go2_ros2_sdk_tower_integration.md)
- ✅ SO-ARM demonstration recording (implemented in LeRobot)
- ⏳ Synchronized timestamp alignment
- ⏳ Combined dataset format definition

### Phase 2: Independent Control (Next)
- ⏳ ROS2 bridge for SO-ARM (publish joint states to ROS topics)
- ⏳ Coordinate frame definitions (base_link → arm_base → end_effector)
- ⏳ Basic coordination script (sequential operations)
- ⏳ Safety checks (collision avoidance, workspace limits)

### Phase 3: Coordinated Control (Future)
- ⏳ Real-time synchronization layer
- ⏳ Shared perception pipeline
- ⏳ Dynamic coordination policies
- ⏳ Vibration compensation (if arm mounted on Go2)

### Phase 4: Learning-Based Integration (Research)
- ⏳ End-to-end mobile manipulation policies
- ⏳ Sim-to-real transfer with Isaac Sim + real SO-ARM
- ⏳ Multi-task learning (navigation + manipulation)
- ⏳ Language-conditioned control ("fetch the red cube")

---

## Example Use Cases

### 1. Warehouse Pick-and-Place
**Scenario**: Go2 navigates warehouse, SO-ARM picks items.

**Workflow**:
1. Natural language command: "Fetch item from shelf B3"
2. Go2 navigates to shelf B3 location
3. SO-ARM identifies target item (vision)
4. SO-ARM picks item from shelf
5. Go2 navigates to drop-off location
6. SO-ARM places item in bin

**Required Skills**:
- Go2: Navigation, localization, obstacle avoidance
- SO-ARM: Object detection, grasp planning, pick/place
- Coordination: Position synchronization, handoff timing

### 2. Table Clearing
**Scenario**: Go2 approaches table, SO-ARM clears objects.

**Workflow**:
1. Go2 detects table with camera
2. Go2 positions itself at table edge
3. SO-ARM scans table surface for objects
4. SO-ARM picks objects one by one
5. Go2 carries objects to bin
6. Repeat until table clear

**Required Skills**:
- Go2: Table detection, precise positioning
- SO-ARM: Multi-object segmentation, sequential grasping
- Coordination: Stable base during manipulation

### 3. Mobile Inspection
**Scenario**: Go2 navigates to inspection points, SO-ARM probes/measures.

**Workflow**:
1. Go2 follows inspection route
2. At each waypoint, Go2 stops
3. SO-ARM extends to inspection point
4. SO-ARM wrist camera captures images
5. SO-ARM uses tool (probe, sensor) if needed
6. Data uploaded to MinIO in real-time

**Required Skills**:
- Go2: Waypoint navigation, stable positioning
- SO-ARM: Precise positioning, tool use
- Coordination: Minimize base vibration during measurement

---

## Safety Considerations

### Hardware Safety

**Go2**:
- Emergency stop button accessible
- Maximum speed limits during manipulation
- Collision detection active
- Stable stance during arm operations

**SO-ARM**:
- Workspace limits enforced (no self-collision with Go2)
- Force limits on motors (prevent damage)
- Emergency stop cuts motor power
- Cable management prevents snagging

### Software Safety

**Monitoring**:
```python
class SafetyMonitor:
    def __init__(self):
        self.emergency_stop = False
        
    def check_go2_stability(self, imu_data):
        """Ensure Go2 is stable during manipulation."""
        if abs(imu_data.roll) > 15 or abs(imu_data.pitch) > 15:
            self.trigger_emergency_stop("Go2 unstable")
    
    def check_arm_workspace(self, arm_pose):
        """Ensure arm doesn't collide with Go2."""
        if self.is_collision(arm_pose, self.go2_geometry):
            self.trigger_emergency_stop("Arm collision risk")
    
    def check_battery_levels(self, go2_battery, arm_battery):
        """Warn if batteries low."""
        if go2_battery < 20 or arm_battery < 20:
            self.warn("Low battery - return to base")
    
    def trigger_emergency_stop(self, reason):
        """Stop all robots immediately."""
        self.emergency_stop = True
        self.go2.stop()
        self.soarm.disable_torque()
        logging.error(f"EMERGENCY STOP: {reason}")
```

---

## Development Tools

### Visualization

**RViz2** for combined visualization:
```bash
# Launch RViz with combined robot URDF
ros2 launch shadowhound_bringup visualize_combined.launch.py

# Topics to visualize:
# - /go2/odom (odometry)
# - /go2/camera/image_raw (camera)
# - /soarm/joint_states (arm pose)
# - /soarm/end_effector_pose (TCP)
# - /mobile_manip/workspace (visualization markers)
```

**Rerun.io** for multi-modal data:
```python
import rerun as rr

rr.init("mobile_manipulation", spawn=True)

# Log Go2 data
rr.log("go2/camera", rr.Image(go2_image))
rr.log("go2/pose", rr.Transform3D(go2_transform))

# Log SO-ARM data
rr.log("soarm/joint_states", rr.Scalar(joint_positions))
rr.log("soarm/wrist_camera", rr.Image(soarm_image))

# Log coordination
rr.log("coordination/status", rr.TextLog(f"Phase: {current_phase}"))
```

### Simulation Testing

**Isaac Sim + LeRobot sim envs** (separate, not yet integrated):

```bash
# Test Go2 navigation in Isaac Sim
cd ~/workspace/IsaacLab
./isaaclab.sh -p source/standalone/workflows/rsl_rl/play.py \
  --task Go2-Navigate-v0 \
  --checkpoint /srv/robot-data/models/go2_navigation/checkpoint_1000.pth

# Test SO-ARM manipulation in LeRobot sim env
lerobot-deploy \
  --env sim/so101 \
  --policy /srv/robot-data/lerobot_policies/pick_place_v1 \
  --num-episodes 10
```

**Future**: Combined Isaac Sim environment with both robots.

---

## FAQ

### Q: Can SO-ARM be mounted on Go2 physically?

**A**: Not officially supported, but mechanically possible:
- SO-ARM weighs ~500g (motors + structure)
- Go2 payload capacity: ~3kg
- Would require custom mounting bracket
- Vibration from Go2 movement may affect arm precision
- Power integration challenge (separate 7.4V battery needed)

**Recommendation**: Start with stationary arm, evaluate mounted option later.

### Q: Do I need both robots for this to work?

**A**: No:
- Go2 alone: Navigation, inspection, delivery tasks
- SO-ARM alone: Stationary manipulation, tabletop tasks
- Combined: Mobile manipulation (fetch, warehouse, inspection)

Each robot has independent value.

### Q: What's the minimum viable combined workflow?

**A**: Sequential operations (Pattern 1):
1. Go2 navigates to location (ROS2 nav2)
2. ROS2 node signals "arrived" topic
3. SO-ARM script listens to topic, executes manipulation
4. SO-ARM publishes "complete" topic
5. Go2 navigates to next location

No complex coordination needed, just topic-based handoff.

### Q: Can policies be trained in simulation?

**A**: Partially:
- **Go2**: Yes (Isaac Sim has Unitree Go2 assets)
- **SO-ARM**: Limited (no official Isaac Sim asset, could import URDF)
- **Combined**: No (requires custom environment setup)

Best approach: Train independently (Go2 in sim, SO-ARM on real hardware), combine with coordination layer.

---

## Next Steps

### To Implement Combined Workflows

1. **Create ROS2 bridge for SO-ARM**:
   ```bash
   # New package: shadowhound_soarm_bridge
   ros2 pkg create shadowhound_soarm_bridge --build-type ament_python
   ```
   
2. **Define coordinate transforms**:
   ```xml
   <!-- robot_description.urdf -->
   <robot name="mobile_manipulation">
     <link name="base_link"/>  <!-- Go2 base -->
     <link name="arm_base"/>   <!-- SO-ARM base -->
     <link name="end_effector"/>  <!-- SO-ARM TCP -->
     
     <joint name="base_to_arm" type="fixed">
       <parent link="base_link"/>
       <child link="arm_base"/>
       <origin xyz="0.2 0 0.3" rpy="0 0 0"/>  <!-- Mounted on back -->
     </joint>
   </robot>
   ```

3. **Implement coordination node**:
   ```python
   # shadowhound_coordination/coordinator_node.py
   class CoordinationNode(Node):
       def __init__(self):
           super().__init__('coordination_node')
           self.go2_sub = self.create_subscription(Odometry, '/go2/odom', ...)
           self.soarm_sub = self.create_subscription(JointState, '/soarm/joint_states', ...)
           self.mission_pub = self.create_publisher(MissionStatus, '/mission/status', 10)
   ```

4. **Test with simple mission**:
   ```bash
   # Launch combined system
   ros2 launch shadowhound_bringup combined_system.launch.py
   
   # Run test mission
   ros2 run shadowhound_missions test_fetch_mission
   ```

### To Contribute

See repository issues tagged `mobile-manipulation` or `integration`.

---

## References

- **Go2 Integration**: [go2_ros2_sdk_tower_integration.md](go2_ros2_sdk_tower_integration.md)
- **SO-ARM Setup**: [tower_lerobot_soarm101_setup.md](tower_lerobot_soarm101_setup.md)
- **Tower Infrastructure**: [tower_sim_datalake_setup.md](tower_sim_datalake_setup.md)
- **LeRobot Docs**: https://huggingface.co/docs/lerobot
- **ROS2 Nav2**: https://navigation.ros.org/
- **Isaac Sim**: https://docs.omniverse.nvidia.com/isaacsim/

---

**Status**: This document is a **roadmap** for future development. Core infrastructure (Tower, Go2, SO-ARM) is operational independently. Integration layer is conceptual and requires implementation.
