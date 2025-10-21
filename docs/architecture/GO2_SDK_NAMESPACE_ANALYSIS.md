---
tags: [architecture, namespacing, go2_ros2_sdk, analysis]
status: complete
related: [NAMESPACE_ALWAYS_ON_ARCHITECTURE.md, NAMESPACE_IMPLEMENTATION_STATUS.md]
summary: >
  Analysis of go2_ros2_sdk namespace support - GOOD NEWS: Multi-robot support already exists!
---

# go2_ros2_sdk Namespace Analysis

**Date**: 2025-10-21  
**Repository**: https://github.com/danmartinez78/go2_ros2_sdk (your fork)  
**Location**: `src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk/`

---

## 🎉 **DISCOVERY: Multi-Robot Namespace Support Already Exists!**

The go2_ros2_sdk **already has built-in multi-robot namespace support** via the `conn_mode` configuration!

### How It Works

**File**: `go2_robot_sdk/presentation/go2_driver_node.py` (lines 142-166)

```python
# Define topics depending on connection mode
if self.config.conn_mode == 'single':
    joint_topic = 'joint_states'
    robot_state_topic = 'go2_states'
    lidar_topic = 'point_cloud2'
    odom_topic = 'odom'
    imu_topic = 'imu'
    camera_topic = 'camera/image_raw'
    camera_info_topic = 'camera/camera_info'
    voxel_topic = '/utlidar/voxel_map_compressed'
else:
    prefix = f'robot{i}'
    joint_topic = f'{prefix}/joint_states'
    robot_state_topic = f'{prefix}/go2_states'
    lidar_topic = f'{prefix}/point_cloud2'
    odom_topic = f'{prefix}/odom'
    imu_topic = f'{prefix}/imu'
    camera_topic = f'{prefix}/camera/image_raw'
    camera_info_topic = f'{prefix}/camera/camera_info'
    voxel_topic = f'{prefix}/utlidar/voxel_map_compressed'
```

**Subscriber setup** (lines 196-218):
```python
if self.config.conn_mode == 'single':
    self.create_subscription(
        Twist, 'cmd_vel_out',
        lambda msg: self._on_cmd_vel(msg, "0"), qos_profile)
    self.create_subscription(
        WebRtcReq, 'webrtc_req',
        lambda msg: self._on_webrtc_req(msg, "0"), qos_profile)
else:
    for i in range(num_robots):
        self.create_subscription(
            Twist, f'robot{i}/cmd_vel_out',
            lambda msg, robot_id=str(i): self._on_cmd_vel(msg, robot_id), qos_profile)
        self.create_subscription(
            WebRtcReq, f'robot{i}/webrtc_req',
            lambda msg, robot_id=str(i): self._on_webrtc_req(msg, robot_id), qos_profile)
```

---

## 🤔 **Problem: Hardcoded Namespace Pattern**

### Current Limitations

1. **Hardcoded `robot0`, `robot1` prefixes**: Cannot use custom names like "tachi", "ghost", "motoko"
2. **No configurable namespace parameter**: `conn_mode` is binary (single vs multi), doesn't accept custom namespace
3. **No always-namespace mode**: `conn_mode='single'` publishes to root (`/odom`), not namespaced

### What We Need

**Goal**: Always use namespace, make it configurable

```python
# We want this:
robot_namespace = "tachi"  # Configurable!

# Publishers use namespace:
odom_topic = f'{robot_namespace}/odom'  # /tachi/odom
cmd_vel_topic = f'{robot_namespace}/cmd_vel_out'  # /tachi/cmd_vel_out
```

---

## 📝 **Scope of Changes Required**

### Option 1: Minimal Parameter Addition (RECOMMENDED)

**Complexity**: Low (2-3 hours)  
**Files Modified**: 2  
**Backward Compatible**: Yes  

**Changes**:

#### 1. Driver Node Parameter Addition
**File**: `go2_robot_sdk/presentation/go2_driver_node.py`

**Add parameter declaration** (line ~93):
```python
self.declare_parameters(
    namespace='',
    parameters=[
        ('robot_ip', robot_ip),
        ('token', token),
        ('conn_type', conn_type),
        ('robot_namespace', ''),  # NEW: Optional namespace
        ('enable_video', True),
        # ... rest
    ]
)
```

**Read parameter** (line ~102):
```python
config = RobotConfig.from_params(
    robot_ip=self.get_parameter('robot_ip').get_parameter_value().string_value,
    token=self.get_parameter('token').get_parameter_value().string_value,
    conn_type=self.get_parameter('conn_type').get_parameter_value().string_value,
    robot_namespace=self.get_parameter('robot_namespace').get_parameter_value().string_value,  # NEW
    # ... rest
)
```

**Update topic logic** (line ~142):
```python
# Get namespace from config (empty string if not set)
namespace = self.config.robot_namespace

# Define topics with optional namespace prefix
if namespace:
    # Always-namespace mode: /tachi/odom, /ghost/odom, etc.
    joint_topic = f'{namespace}/joint_states'
    robot_state_topic = f'{namespace}/go2_states'
    lidar_topic = f'{namespace}/point_cloud2'
    odom_topic = f'{namespace}/odom'
    imu_topic = f'{namespace}/imu'
    camera_topic = f'{namespace}/camera/image_raw'
    camera_info_topic = f'{namespace}/camera/camera_info'
    voxel_topic = f'{namespace}/utlidar/voxel_map_compressed'
else:
    # Legacy single-robot mode (backward compatible)
    joint_topic = 'joint_states'
    robot_state_topic = 'go2_states'
    # ... etc
```

**Update subscriber logic** (line ~196):
```python
if namespace:
    # Always-namespace mode
    self.create_subscription(
        Twist, f'{namespace}/cmd_vel_out',
        lambda msg: self._on_cmd_vel(msg, "0"), qos_profile)
    self.create_subscription(
        WebRtcReq, f'{namespace}/webrtc_req',
        lambda msg: self._on_webrtc_req(msg, "0"), qos_profile)
else:
    # Legacy mode
    self.create_subscription(
        Twist, 'cmd_vel_out',
        lambda msg: self._on_cmd_vel(msg, "0"), qos_profile)
    # ... etc
```

#### 2. RobotConfig Entity Update
**File**: `go2_robot_sdk/domain/entities.py` (likely)

**Add field**:
```python
@dataclass
class RobotConfig:
    robot_ip_list: List[str]
    token: str = ""
    conn_type: str = ""
    robot_namespace: str = ""  # NEW: Optional namespace
    enable_video: bool = True
    decode_lidar: bool = True
    # ... rest
```

#### 3. Launch File Update
**File**: `go2_robot_sdk/launch/robot_dimos.launch.py`

**Add parameter**:
```python
robot_namespace_arg = DeclareLaunchArgument(
    'robot_namespace',
    default_value='',  # Empty = legacy mode
    description='Robot namespace (e.g., tachi, ghost, motoko). Leave empty for single-robot mode.'
)

robot_namespace = LaunchConfiguration('robot_namespace')
```

**Pass to node**:
```python
go2_driver_node = Node(
    package='go2_robot_sdk',
    executable='go2_driver_node',
    name='go2_driver_node',
    output='screen',
    parameters=[
        {'robot_ip': robot_ip},
        {'conn_type': conn_type},
        {'robot_namespace': robot_namespace},  # NEW
        # ... rest
    ]
)
```

---

### Option 2: Remove Multi-Robot Logic (NOT RECOMMENDED)

**Complexity**: Medium (4-6 hours)  
**Backward Compatible**: No (breaks multi-robot users)  

Remove `conn_mode` logic entirely, always use `robot_namespace` parameter. This breaks existing multi-robot setups that rely on `robot0`, `robot1` prefixes.

**Why not recommended**: Breaks compatibility, more work, less flexible

---

## ✅ **Recommended Approach**

### Phase 1: Parameter Addition (2-3 hours)
1. Add `robot_namespace` parameter to driver node
2. Update `RobotConfig` entity
3. Modify topic naming logic (publishers + subscribers)
4. Update launch file
5. Test backward compatibility (no namespace = legacy mode)
6. Test new mode (`robot_namespace='tachi'`)

### Phase 2: Testing & Validation (1-2 hours)
1. **Legacy mode test**: Launch without namespace, verify `/odom`, `/cmd_vel` work
2. **Namespace mode test**: Launch with `robot_namespace:=tachi`, verify `/tachi/odom`, `/tachi/cmd_vel`
3. **Multi-robot test** (optional): Launch 2 instances with different namespaces

### Phase 3: Documentation & PR (1 hour)
1. Update README with namespace parameter usage
2. Create PR to upstream (if desired)
3. Document breaking changes (none - fully backward compatible)

**Total Estimated Time**: 4-6 hours

---

## 🎯 **Integration with ShadowHound**

### Shadowhound Launch File Update
**File**: `launch/shadowhound_full.launch.py`

**Current**:
```python
go2_sdk_launch = IncludeLaunchDescription(
    PythonLaunchDescriptionSource([...robot_dimos.launch.py...]),
    launch_arguments={
        "robot_ip": robot_ip,
        "conn_type": "webrtc",
        "use_optimized_lidar": "true",
    }.items(),
)
```

**After SDK update**:
```python
go2_sdk_launch = IncludeLaunchDescription(
    PythonLaunchDescriptionSource([...robot_dimos.launch.py...]),
    launch_arguments={
        "robot_ip": robot_ip,
        "conn_type": "webrtc",
        "robot_namespace": robot_namespace,  # NEW: Pass namespace through
        "use_optimized_lidar": "true",
    }.items(),
)
```

### Benefits
- ✅ **Consistent namespacing**: Hardware and sim both use `/tachi/*`
- ✅ **True parity**: Same topics in all modes
- ✅ **Multi-robot ready**: Can launch multiple robots with different names
- ✅ **Backward compatible**: Existing setups still work (empty namespace)

---

## 🚧 **Known Issues & Considerations**

### Issue 1: TF Frame Names
**Problem**: TF frames are hardcoded in launch file (`base_link`, `lidar_link`, etc.)

**File**: `robot_dimos.launch.py` (lines 173-197)

```python
base_to_lidar_tf = Node(
    package='tf2_ros',
    executable='static_transform_publisher',
    name='base_to_lidar_tf',
    arguments=['0', '0', '0.44', '0', '0', '0', 'base_link', 'lidar_link'],  # Hardcoded!
)
```

**Solution**: Update to use namespace prefix
```python
arguments=['0', '0', '0.44', '0', '0', '0', 
           f'{robot_namespace}/base_link' if robot_namespace else 'base_link',
           f'{robot_namespace}/lidar_link' if robot_namespace else 'lidar_link'],
```

### Issue 2: Voxel Map Topic
**Problem**: Voxel map uses absolute path `/utlidar/voxel_map_compressed` (note leading slash)

**Current** (line ~158):
```python
voxel_topic = '/utlidar/voxel_map_compressed'
# vs multi-robot:
voxel_topic = f'{prefix}/utlidar/voxel_map_compressed'
```

**Inconsistency**: Single mode uses absolute, multi-robot uses relative

**Solution**: Make consistent
```python
if namespace:
    voxel_topic = f'{namespace}/utlidar/voxel_map_compressed'
else:
    voxel_topic = 'utlidar/voxel_map_compressed'  # Remove leading slash
```

---

## 📊 **Change Summary**

| Component | Files | Lines Changed | Complexity |
|-----------|-------|---------------|------------|
| Driver Node | `go2_driver_node.py` | ~30 | Low |
| Config Entity | `entities.py` | ~2 | Trivial |
| Launch File | `robot_dimos.launch.py` | ~10 | Low |
| TF Publishers | `robot_dimos.launch.py` | ~15 | Low |
| **Total** | **3 files** | **~57 lines** | **Low** |

---

## 🎬 **Next Steps**

### Decision Point: Edit Now or Create Issue?

**Option A: Edit Now (Recommended)**
- ✅ You own the fork (can push directly)
- ✅ Small scope (~57 lines, 3 files)
- ✅ Low complexity (parameter plumbing)
- ✅ Can test immediately
- ✅ Unblocks Stage 3 today

**Option B: Create Issue**
- ✅ Good for community contribution
- ❌ Delays Stage 3 implementation
- ❌ Requires external contributor
- ❌ May need iteration/review cycles

### Recommendation: **Edit Now**

**Reasoning**:
1. Small, well-defined scope
2. You own the repo (no permission needed)
3. Can test and iterate quickly
4. Unblocks ShadowHound Stage 3 immediately
5. Can upstream to original repo later if desired

**Implementation Plan**:
1. Create feature branch: `feature/configurable-namespace`
2. Implement changes (~2-3 hours)
3. Test both modes (legacy + namespace)
4. Commit to your fork
5. Update dimos-unitree submodule reference
6. Complete ShadowHound Stage 3

---

## 🔗 **References**

- **go2_ros2_sdk Fork**: https://github.com/danmartinez78/go2_ros2_sdk
- **Original Upstream**: https://github.com/abizovnuralem/go2_ros2_sdk
- **ShadowHound Architecture**: `NAMESPACE_ALWAYS_ON_ARCHITECTURE.md`
- **Implementation Status**: `NAMESPACE_IMPLEMENTATION_STATUS.md`

---

**Conclusion**: go2_ros2_sdk already has 80% of what we need! Just needs a configurable namespace parameter instead of hardcoded `robot0` prefixes. Small, well-scoped change that's quick to implement and test.
