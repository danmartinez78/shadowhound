# go2_omniverse Namespace Implementation Plan

**Date**: October 22, 2025  
**Repository**: https://github.com/danmartinez78/go2_omniverse  
**Branch**: `feature/configurable-namespace` (to be created)  
**Status**: 🔍 Investigation Complete → Ready for Implementation

---

## Investigation Results

### ✅ Namespace Hardcoding Located

**File**: `ros2.py`  
**Class**: `RobotBaseNode`  
**Location**: Lines 220-253 (approximately)

**Current Implementation** (hardcoded `robot{i}` pattern):

```python
class RobotBaseNode(Node):
    def __init__(self, num_envs):
        super().__init__("go2_driver_node")
        qos_profile = QoSProfile(depth=10)

        self.joint_pub = []
        self.go2_state_pub = []
        self.go2_lidar_L1_pub = []
        self.go2_lidar_extra_pub = []
        self.odom_pub = []
        self.imu_pub = []

        for i in range(num_envs):
            self.joint_pub.append(
                self.create_publisher(JointState, f"robot{i}/joint_states", qos_profile)
            )
            self.go2_state_pub.append(
                self.create_publisher(Go2State, f"robot{i}/go2_states", qos_profile)
            )
            self.odom_pub.append(
                self.create_publisher(Odometry, f"robot{i}/odom", qos_profile)
            )
            self.imu_pub.append(
                self.create_publisher(Imu, f"robot{i}/imu", qos_profile)
            )
            self.go2_lidar_L1_pub.append(
                self.create_publisher(
                    PointCloud2, f"robot{i}/point_cloud2_L1", qos_profile
                )
            )
            self.go2_lidar_extra_pub.append(
                self.create_publisher(
                    PointCloud2, f"robot{i}/point_cloud2_extra", qos_profile
                )
            )
```

**Also in TF Frames** (lines 280-310 approximately):

```python
def publish_odom(self, base_pos, base_rot, robot_num):
    # ...
    odom_trans.child_frame_id = f"robot{robot_num}/base_link"
    # ...
    UnitreeL1_trans.header.frame_id = f"robot{robot_num}/base_link"
    UnitreeL1_trans.child_frame_id = f"robot{robot_num}/UnitreeL1_link"
    # ...
    lidar_trans.header.frame_id = f"robot{robot_num}/base_link"
    lidar_trans.child_frame_id = f"robot{robot_num}/lidar_link"
    # ...
    odom_topic.child_frame_id = f"robot{robot_num}/base_link"
```

**Also in Joint Names** (line 260 approximately):

```python
def publish_joints(self, joint_names_lst, joint_state_lst, robot_num):
    joint_state_names_formated = []
    for joint_name in joint_names_lst:
        joint_state_names_formated.append(f"robot{robot_num}/" + joint_name)
```

---

## Scope Assessment: ⭐ **MINIMAL** (1-2 hours)

### Files to Modify: **3 files**

1. **`cli_args.py`** - Add `--robot_namespace` argument (~5 lines)
2. **`omniverse_sim.py`** - Pass namespace to RobotBaseNode (~3 lines)
3. **`ros2.py`** - Accept and use custom namespace (~30 lines)

**Total**: ~38 lines of changes

---

## Implementation Plan

### Phase 1: Add CLI Argument (5 minutes)

**File**: `cli_args.py`

**Add new argument**:

```python
def add_rsl_rl_args(parser):
    # ... existing arguments ...
    
    parser.add_argument(
        "--robot_namespace",
        type=str,
        default="",  # Empty string = use robot0, robot1, robot2 pattern
        help="Custom robot namespace (e.g., 'tachi', 'ghost'). "
             "If empty, uses 'robot0', 'robot1', etc. for multi-robot. "
             "For single robot with custom name, pass namespace here."
    )
```

**Behavior**:
- `--robot_namespace ""` (default) → `robot0`, `robot1`, `robot2` (current behavior)
- `--robot_namespace tachi` → `/tachi/*` topics (single robot)
- `--robot_namespace tachi,ghost,motoko` → `/tachi/*`, `/ghost/*`, `/motoko/*` (multi-robot)

---

### Phase 2: Update RobotBaseNode (30 minutes)

**File**: `ros2.py`

**Change 1**: Accept namespace parameter in `__init__`:

```python
class RobotBaseNode(Node):
    def __init__(self, num_envs, robot_namespaces=None):
        """
        Args:
            num_envs: Number of robot environments
            robot_namespaces: List of custom namespaces or None for default robot{i}
                             Examples: ["tachi"], ["tachi", "ghost", "motoko"]
        """
        super().__init__("go2_driver_node")
        qos_profile = QoSProfile(depth=10)

        # Generate namespaces
        if robot_namespaces is None or len(robot_namespaces) == 0:
            # Default behavior: robot0, robot1, robot2, etc.
            self.namespaces = [f"robot{i}" for i in range(num_envs)]
        elif len(robot_namespaces) == 1 and num_envs == 1:
            # Single robot with custom namespace
            self.namespaces = robot_namespaces
        elif len(robot_namespaces) == num_envs:
            # Multi-robot with custom namespaces
            self.namespaces = robot_namespaces
        else:
            raise ValueError(
                f"robot_namespaces length ({len(robot_namespaces)}) "
                f"must match num_envs ({num_envs}) or be 1 for single robot"
            )

        self.joint_pub = []
        self.go2_state_pub = []
        self.go2_lidar_L1_pub = []
        self.go2_lidar_extra_pub = []
        self.odom_pub = []
        self.imu_pub = []

        for i in range(num_envs):
            ns = self.namespaces[i]
            self.joint_pub.append(
                self.create_publisher(JointState, f"{ns}/joint_states", qos_profile)
            )
            self.go2_state_pub.append(
                self.create_publisher(Go2State, f"{ns}/go2_states", qos_profile)
            )
            self.odom_pub.append(
                self.create_publisher(Odometry, f"{ns}/odom", qos_profile)
            )
            self.imu_pub.append(
                self.create_publisher(Imu, f"{ns}/imu", qos_profile)
            )
            self.go2_lidar_L1_pub.append(
                self.create_publisher(
                    PointCloud2, f"{ns}/point_cloud2_L1", qos_profile
                )
            )
            self.go2_lidar_extra_pub.append(
                self.create_publisher(
                    PointCloud2, f"{ns}/point_cloud2_extra", qos_profile
                )
            )
        self.broadcaster = TransformBroadcaster(self, qos=qos_profile)
```

**Change 2**: Update `publish_joints` to use namespace:

```python
def publish_joints(self, joint_names_lst, joint_state_lst, robot_num):
    # Create message
    joint_state = JointState()
    joint_state.header.stamp = self.get_clock().now().to_msg()

    ns = self.namespaces[robot_num]
    joint_state_names_formated = []
    for joint_name in joint_names_lst:
        joint_state_names_formated.append(f"{ns}/" + joint_name)

    joint_state_formated = []
    for joint_state_val in joint_state_lst:
        joint_state_formated.append(joint_state_val.item())

    joint_state.name = joint_state_names_formated
    joint_state.position = joint_state_formated
    self.joint_pub[robot_num].publish(joint_state)
```

**Change 3**: Update `publish_odom` TF frame IDs:

```python
def publish_odom(self, base_pos, base_rot, robot_num):
    now = self.get_clock().now().to_msg()
    ns = self.namespaces[robot_num]

    odom_trans = TransformStamped()
    odom_trans.header.stamp = now
    odom_trans.header.frame_id = "odom"
    odom_trans.child_frame_id = f"{ns}/base_link"
    # ... (position/rotation unchanged)
    self.broadcaster.sendTransform(odom_trans)

    UnitreeL1_trans = TransformStamped()
    UnitreeL1_trans.header.stamp = now
    UnitreeL1_trans.header.frame_id = f"{ns}/base_link"
    UnitreeL1_trans.child_frame_id = f"{ns}/UnitreeL1_link"
    # ... (transform unchanged)
    self.broadcaster.sendTransform(UnitreeL1_trans)

    lidar_trans = TransformStamped()
    lidar_trans.header.stamp = now
    lidar_trans.header.frame_id = f"{ns}/base_link"
    lidar_trans.child_frame_id = f"{ns}/lidar_link"
    # ... (transform unchanged)
    self.broadcaster.sendTransform(lidar_trans)

    odom_topic = Odometry()
    odom_topic.header.stamp = now
    odom_topic.header.frame_id = "odom"
    odom_topic.child_frame_id = f"{ns}/base_link"
    # ... (pose unchanged)
    self.odom_pub[robot_num].publish(odom_topic)
```

**Similar changes needed for**:
- `publish_imu()` - Update frame IDs
- `publish_lidar_L1()` - Update frame IDs
- `publish_lidar_extra()` - Update frame IDs

---

### Phase 3: Pass Namespace to RobotBaseNode (10 minutes)

**File**: `omniverse_sim.py`

**Find where RobotBaseNode is instantiated** (around line 250-300):

```python
def run_sim():
    # ... argument parsing ...
    args_cli = parser.parse_args()
    
    # Parse robot_namespace argument
    robot_namespaces = None
    if args_cli.robot_namespace:
        robot_namespaces = [ns.strip() for ns in args_cli.robot_namespace.split(',')]
    
    # ... simulation setup ...
    
    # Initialize ROS2 node with custom namespaces
    base_node = RobotBaseNode(args_cli.robot_amount, robot_namespaces=robot_namespaces)
```

---

### Phase 4: Update run_sim.sh (5 minutes)

**File**: `run_sim.sh`

**Add namespace environment variable support**:

```bash
#!/bin/bash

# Default namespace (empty = use robot0, robot1, etc.)
ROBOT_NAMESPACE=${ROBOT_NAMESPACE:-""}

# Activate conda environment
conda activate env_isaaclab

# Set LD_PRELOAD for Isaac Sim
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6

# Launch simulation with namespace
if [ -n "$ROBOT_NAMESPACE" ]; then
    python main.py --robot go2 --device cuda --enable_cameras --robot_namespace "$ROBOT_NAMESPACE"
else
    python main.py --robot go2 --device cuda --enable_cameras
fi
```

**Usage**:
```bash
# Default behavior (robot0)
./run_sim.sh

# Custom namespace
ROBOT_NAMESPACE=tachi ./run_sim.sh

# Multi-robot with custom names
ROBOT_NAMESPACE=tachi,ghost,motoko python main.py --robot_amount 3 --device cuda
```

---

## Testing Plan

### Test 1: Default Behavior (Backward Compatibility)

```bash
cd ~/workspace/go2_omniverse
python main.py --robot go2 --device cuda

# Expected topics:
ros2 topic list | grep robot0
# /robot0/odom
# /robot0/cmd_vel
# /robot0/joint_states
# /robot0/imu
# /robot0/point_cloud2_L1
```

✅ **Success Criteria**: Same topics as current implementation

---

### Test 2: Single Robot with Custom Namespace

```bash
python main.py --robot go2 --device cuda --robot_namespace tachi

# Expected topics:
ros2 topic list | grep tachi
# /tachi/odom
# /tachi/cmd_vel
# /tachi/joint_states
# /tachi/imu
# /tachi/point_cloud2_L1

# Expected TF frames:
ros2 run tf2_tools view_frames
# Should show: odom → tachi/base_link → tachi/UnitreeL1_link, tachi/lidar_link
```

✅ **Success Criteria**: All topics and frames use `tachi` namespace

---

### Test 3: Multi-Robot with Custom Namespaces

```bash
python main.py --robot_amount 3 --device cuda --robot_namespace tachi,ghost,motoko

# Expected topics:
ros2 topic list | grep -E "tachi|ghost|motoko"
# /tachi/odom, /ghost/odom, /motoko/odom
# /tachi/cmd_vel, /ghost/cmd_vel, /motoko/cmd_vel
# etc.
```

✅ **Success Criteria**: Each robot has its own custom namespace

---

### Test 4: Integration with ShadowHound Mission Agent

```bash
# On Tower
ROBOT_NAMESPACE=tachi ./run_sim.sh

# On Laptop
ros2 launch shadowhound_bringup shadowhound.launch.py robot_namespace:=tachi

# Verify mission agent connects to /tachi/* topics
ros2 topic info /tachi/cmd_vel
# Publishers: mission_agent
# Subscribers: IsaacSim
```

✅ **Success Criteria**: Mission agent commands robot in sim using custom namespace

---

## Success Criteria

### ✅ Minimal Success (MVP)

- [x] Investigation complete (namespace hardcoding located)
- [ ] CLI argument added (`--robot_namespace`)
- [ ] RobotBaseNode accepts custom namespaces
- [ ] Single robot publishes to custom namespace (e.g., `/tachi/*`)
- [ ] TF frames use custom namespace
- [ ] Backward compatible (default = `robot0`)
- [ ] Tested on Tower with Isaac Sim
- [ ] Mission agent connects successfully

### ✅ Full Success

- [ ] Multi-robot custom namespaces working
- [ ] All ROS2 publishers use custom namespace
- [ ] All TF frames use custom namespace
- [ ] run_sim.sh supports `ROBOT_NAMESPACE` env var
- [ ] Documentation updated (README, quickstart)
- [ ] End-to-end testing with ShadowHound

### ✅ Stretch Goals

- [ ] Empty namespace support (`--robot_namespace ""` → no prefix like hardware)
- [ ] Upstream PR to abizovnuralem/go2_omniverse
- [ ] Camera topics use namespace (front_cam/rgb → {ns}/front_cam/rgb)
- [ ] Cmd_vel subscriber uses namespace

---

## Repository Setup

### Create Feature Branch

```bash
cd ~/workspace/go2_omniverse

# Make sure we're on added_copter
git checkout added_copter
git pull origin added_copter

# Create feature branch
git checkout -b feature/configurable-namespace

# Verify fork remote
git remote -v
# origin  https://github.com/danmartinez78/go2_omniverse (fetch)
# origin  https://github.com/danmartinez78/go2_omniverse (push)
```

---

## Implementation Checklist

- [x] Investigation complete (ros2.py namespace hardcoding located)
- [x] Fork exists (danmartinez78/go2_omniverse)
- [ ] Feature branch created (`feature/configurable-namespace`)
- [ ] Modify `cli_args.py` (add --robot_namespace argument)
- [ ] Modify `ros2.py` (RobotBaseNode namespace support)
- [ ] Modify `omniverse_sim.py` (pass namespace to RobotBaseNode)
- [ ] Modify `run_sim.sh` (environment variable support)
- [ ] Test 1: Default behavior (backward compatibility)
- [ ] Test 2: Single robot custom namespace
- [ ] Test 3: Multi-robot custom namespaces
- [ ] Test 4: Integration with ShadowHound
- [ ] Update Tower quickstart documentation
- [ ] Update shadowhound setup scripts (use our fork)
- [ ] Commit and push to origin/feature/configurable-namespace
- [ ] Create PR (if upstream contribution desired)

---

## Timeline Estimate

- **Phase 1** (CLI argument): 5 minutes
- **Phase 2** (RobotBaseNode): 30 minutes
- **Phase 3** (Pass namespace): 10 minutes
- **Phase 4** (run_sim.sh): 5 minutes
- **Testing**: 30 minutes
- **Documentation**: 20 minutes

**Total**: ~1.5 hours (minimal scope)

---

## Related Documentation

- **Namespace Migration Plan**: `docs/architecture/namespace_migration_plan.md`
- **Simulation Analysis**: `docs/development/SIM_NAMESPACE_ANALYSIS.md`
- **Tower Quickstart**: `docs/deployment/tower_go2_isaac_sim_quickstart.md`
- **Stage 2 Complete**: `docs/development/STAGE2_ALREADY_COMPLETE.md`

---

## Conclusion

**Status**: ✅ Investigation complete, ready for implementation

**Complexity**: ⭐ Minimal (1-2 hours)

**Risk**: Low (parameter-based, backward compatible)

**Value**: High (completes namespace migration architecture)

This implementation completes the namespace migration by ensuring Isaac Sim matches the ShadowHound/DIMOS architecture where all components use a configurable `robot_namespace` parameter consistently.

**Next Step**: Create feature branch and begin Phase 1 implementation.
