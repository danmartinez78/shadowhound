---
tags: [dimos, submodule, patch, integration]
status: in-progress
related:
  - ./dimos_namespace_support_issue.md
summary: >
  Specific code changes required in DIMOS unitree submodule for namespace support.
---

# DIMOS Unitree Namespace Support - Implementation Guide

**Target**: `src/dimos-unitree/` submodule  
**Scope**: Add namespace parameter support for simulation environments  
**Status**: Pending implementation (issue tracked in `docs/issues/dimos_namespace_support_issue.md`)

---

## File 1: `dimos/robot/unitree/unitree_go2.py`

### Change 1.1: Add namespace parameter to `__init__`

**Location**: Constructor parameter list (around line 51)

**Current**:
```python
def __init__(
    self,
    ros_control: Optional[UnitreeROSControl] = None,
    ip=None,
    connection_method: WebRTCConnectionMethod = WebRTCConnectionMethod.LocalSTA,
    serial_number: str = None,
    output_dir: str = os.path.join(os.getcwd(), "assets", "output"),
    use_ros: bool = True,
    use_webrtc: bool = False,
    disable_video_stream: bool = False,
    mock_connection: bool = False,
    skills: Optional[Union[MyUnitreeSkills, AbstractSkill]] = None,
    spatial_memory_dir: str = None,
    spatial_memory_collection: str = "spatial_memory",
    new_memory: bool = False,
):
```

**Add this parameter**:
```python
    namespace: str = "",  # NEW: Namespace prefix for topics/frames (e.g., "robot0")
```

**Updated**:
```python
def __init__(
    self,
    ros_control: Optional[UnitreeROSControl] = None,
    ip=None,
    connection_method: WebRTCConnectionMethod = WebRTCConnectionMethod.LocalSTA,
    serial_number: str = None,
    output_dir: str = os.path.join(os.getcwd(), "assets", "output"),
    use_ros: bool = True,
    use_webrtc: bool = False,
    disable_video_stream: bool = False,
    mock_connection: bool = False,
    skills: Optional[Union[MyUnitreeSkills, AbstractSkill]] = None,
    spatial_memory_dir: str = None,
    spatial_memory_collection: str = "spatial_memory",
    new_memory: bool = False,
    namespace: str = "",  # NEW: Namespace prefix for topics/frames
):
```

### Change 1.2: Store namespace as instance variable

**Location**: Early in `__init__` body (after parameter validation)

**Add**:
```python
    # Store namespace for use in topic subscriptions and frame names
    self.namespace = namespace.rstrip("/") if namespace else ""
```

### Change 1.3: Update planner initialization for local planner

**Location**: Around line 167 where `VFHPurePursuitPlanner` is initialized

**Current**:
```python
        self.local_planner = VFHPurePursuitPlanner(
            get_costmap=self.ros_control.topic_latest("/local_costmap/costmap", Costmap),
            transform=self.ros_control,
            move_vel_control=self.ros_control.move_vel_control,
            robot_width=0.36,  # Unitree Go2 width in meters
            robot_length=0.6,  # Unitree Go2 length in meters
            max_linear_vel=0.5,
            lookahead_distance=1.0,
            visualization_size=500,  # 500x500 pixel visualization
        )
```

**Updated**:
```python
        # Build namespaced topic path for costmap
        local_costmap_topic = "local_costmap/costmap"
        if self.namespace:
            local_costmap_topic = f"{self.namespace}/{local_costmap_topic}"
        
        self.local_planner = VFHPurePursuitPlanner(
            get_costmap=self.ros_control.topic_latest(local_costmap_topic, Costmap),
            transform=self.ros_control,
            move_vel_control=self.ros_control.move_vel_control,
            robot_width=0.36,  # Unitree Go2 width in meters
            robot_length=0.6,  # Unitree Go2 length in meters
            max_linear_vel=0.5,
            lookahead_distance=1.0,
            visualization_size=500,  # 500x500 pixel visualization
        )
```

### Change 1.4: Update planner initialization for global planner

**Location**: Around line 180 where `AstarPlanner` is initialized

**Current**:
```python
        self.global_planner = AstarPlanner(
            conservativism=20,  # how close to obstacles robot is allowed to path plan
            set_local_nav=lambda path, stop_event=None, goal_theta=None: navigate_path_local(self, path, timeout=120.0, goal_theta=goal_theta, stop_event=stop_event),
            get_costmap=self.ros_control.topic_latest("map", Costmap),
            get_robot_pos=lambda: self.ros_control.transform_euler_pos("base_link"),
        )
```

**Updated**:
```python
        # Build namespaced frame name for map costmap
        map_frame = "map"
        if self.namespace:
            map_frame = f"{self.namespace}/{map_frame}"
        
        # Build namespaced source frame for position query
        base_frame = "base_link"
        if self.namespace:
            base_frame = f"{self.namespace}/{base_frame}"
        
        self.global_planner = AstarPlanner(
            conservativism=20,  # how close to obstacles robot is allowed to path plan
            set_local_nav=lambda path, stop_event=None, goal_theta=None: navigate_path_local(self, path, timeout=120.0, goal_theta=goal_theta, stop_event=stop_event),
            get_costmap=self.ros_control.topic_latest(map_frame, Costmap),
            get_robot_pos=lambda: self.ros_control.transform_euler_pos(base_frame),
        )
```

### Change 1.5: Update `get_pose()` method

**Location**: Around line 187 in `get_pose()` method

**Current**:
```python
    def get_pose(self) -> Tuple[Tuple[float, float, float], Tuple[float, float, float]]:
        """
        Get the current pose (position and rotation) of the robot in the map frame.
        
        Returns:
            Tuple containing:
                - position: Tuple[float, float, float] (x, y, z)
                - rotation: Tuple[float, float, float] (roll, pitch, yaw) in radians
        """
        [position, rotation] = self.ros_control.transform_euler("base_link")

        return position, rotation
```

**Updated**:
```python
    def get_pose(self) -> Tuple[Tuple[float, float, float], Tuple[float, float, float]]:
        """
        Get the current pose (position and rotation) of the robot in the map frame.
        
        Returns:
            Tuple containing:
                - position: Tuple[float, float, float] (x, y, z)
                - rotation: Tuple[float, float, float] (roll, pitch, yaw) in radians
        """
        # Use namespaced frame if available
        base_frame = "base_link"
        if self.namespace:
            base_frame = f"{self.namespace}/{base_frame}"
        
        [position, rotation] = self.ros_control.transform_euler(base_frame)

        return position, rotation
```

### Change 1.6: Update docstring

**Location**: Constructor docstring (around line 60)

**Add to docstring**:
```python
            namespace: Namespace prefix for ROS topics and TF frames. Used for multi-robot
                or simulation scenarios where topics/frames are namespaced (e.g., "robot0"
                results in /robot0/local_costmap/costmap, robot0/base_link). Defaults to
                empty string (no namespace). Should not include leading or trailing slashes.
```

---

## File 2: `dimos/robot/ros_transform.py`

### Change 2.1: Add frame_namespace parameter to transform methods

**Location**: All transform methods that default to `target_frame="map"`

**Current** (all these methods):
```python
def transform_euler_pos(self, source_frame: str, target_frame: str = "map", timeout: float = 1.0):
    return to_euler_pos(self.transform(source_frame, target_frame, timeout))

def transform_euler_rot(self, source_frame: str, target_frame: str = "map", timeout: float = 1.0):
    return to_euler_rot(self.transform(source_frame, target_frame, timeout))

def transform_euler(self, source_frame: str, target_frame: str = "map", timeout: float = 1.0):
    res = self.transform(source_frame, target_frame, timeout)
    return to_euler(res)

def transform_point(self, point: Vector, source_frame: str, target_frame: str = "map", timeout: float = 1.0):
    # ... existing code ...

def transform_rot(self, rotation: Vector, source_frame: str, target_frame: str = "map", timeout: float = 1.0):
    # ... existing code ...

def transform_pose(self, position: Vector, rotation: Vector, source_frame: str, target_frame: str = "map", timeout: float = 1.0):
    # ... existing code ...
```

**Updated** (add optional `frame_namespace` parameter and apply it):
```python
def transform_euler_pos(self, source_frame: str, target_frame: str = "map", timeout: float = 1.0, frame_namespace: str = ""):
    source = source_frame
    target = target_frame
    if frame_namespace:
        source = f"{frame_namespace}/{source}".lstrip("/")
        target = f"{frame_namespace}/{target}".lstrip("/")
    return to_euler_pos(self.transform(source, target, timeout))

def transform_euler_rot(self, source_frame: str, target_frame: str = "map", timeout: float = 1.0, frame_namespace: str = ""):
    source = source_frame
    target = target_frame
    if frame_namespace:
        source = f"{frame_namespace}/{source}".lstrip("/")
        target = f"{frame_namespace}/{target}".lstrip("/")
    return to_euler_rot(self.transform(source, target, timeout))

def transform_euler(self, source_frame: str, target_frame: str = "map", timeout: float = 1.0, frame_namespace: str = ""):
    source = source_frame
    target = target_frame
    if frame_namespace:
        source = f"{frame_namespace}/{source}".lstrip("/")
        target = f"{frame_namespace}/{target}".lstrip("/")
    res = self.transform(source, target, timeout)
    return to_euler(res)

def transform_point(self, point: Vector, source_frame: str, target_frame: str = "map", timeout: float = 1.0, frame_namespace: str = ""):
    source = source_frame
    target = target_frame
    if frame_namespace:
        source = f"{frame_namespace}/{source}".lstrip("/")
        target = f"{frame_namespace}/{target}".lstrip("/")
    # ... rest of existing implementation using source and target instead of source_frame/target_frame ...

def transform_rot(self, rotation: Vector, source_frame: str, target_frame: str = "map", timeout: float = 1.0, frame_namespace: str = ""):
    source = source_frame
    target = target_frame
    if frame_namespace:
        source = f"{frame_namespace}/{source}".lstrip("/")
        target = f"{frame_namespace}/{target}".lstrip("/")
    # ... rest of existing implementation using source and target instead of source_frame/target_frame ...

def transform_pose(self, position: Vector, rotation: Vector, source_frame: str, target_frame: str = "map", timeout: float = 1.0, frame_namespace: str = ""):
    source = source_frame
    target = target_frame
    if frame_namespace:
        source = f"{frame_namespace}/{source}".lstrip("/")
        target = f"{frame_namespace}/{target}".lstrip("/")
    # ... rest of existing implementation using source and target instead of source_frame/target_frame ...
```

**Pattern**: For each method, add `frame_namespace: str = ""` parameter, then:
```python
if frame_namespace:
    source_frame = f"{frame_namespace}/{source_frame}".lstrip("/")
    target_frame = f"{frame_namespace}/{target_frame}".lstrip("/")
```

---

## File 3: `dimos/robot/robot.py`

### Change 3.1: Store and pass namespace

**Location**: Robot base class `__init__` and spatial memory initialization

**Add namespace storage**:
```python
    self.namespace = namespace  # Store for subclasses
```

**When initializing SpatialMemory** (around line 136):

Update the transform_provider closure to use namespaced frames:

```python
        # Define transform provider with namespace awareness
        def transform_provider():
            base_frame = "base_link"
            map_frame = "map"
            
            # Apply namespace if available
            if hasattr(self, 'namespace') and self.namespace:
                base_frame = f"{self.namespace}/{base_frame}"
                map_frame = f"{self.namespace}/{map_frame}"
            
            position, rotation = self.ros_control.transform_euler(
                source_frame=base_frame,
                target_frame=map_frame
            )
            if position is None or rotation is None:
                return {
                    "position": None,
                    "rotation": None
                }
            return {
                "position": position,
                "rotation": rotation
            }
```

---

## Backward Compatibility Verification

After implementation, verify:

```python
# Hardware mode (no namespace) - should work as before
robot_hw = UnitreeGo2(ros_control)
assert robot_hw.namespace == ""

# Simulation mode (with namespace)
robot_sim = UnitreeGo2(ros_control, namespace="robot0")
assert robot_sim.namespace == "robot0"

# Transform with namespace
pos1 = robot_hw.ros_control.transform_euler_pos("base_link")  # → /base_link
pos2 = robot_sim.ros_control.transform_euler_pos("base_link", frame_namespace="robot0")  # → /robot0/base_link
```

---

## Testing Recommendations

### Unit Tests

```python
def test_namespace_storage():
    """Namespace parameter is correctly stored."""
    robot = UnitreeGo2(ros_control, namespace="robot0")
    assert robot.namespace == "robot0"

def test_namespace_normalization():
    """Namespace is normalized (no trailing slash)."""
    robot1 = UnitreeGo2(ros_control, namespace="robot0")
    robot2 = UnitreeGo2(ros_control, namespace="robot0/")
    assert robot1.namespace == robot2.namespace == "robot0"

def test_empty_namespace():
    """Empty namespace works like before (backward compatible)."""
    robot = UnitreeGo2(ros_control)
    assert robot.namespace == ""
    # Verify planners initialize without namespace prefix
```

### Integration Tests

```python
def test_simulation_namespace():
    """UnitreeGo2 initializes in simulation mode with namespace."""
    # Setup: Mock ROS2 topics at /robot0/local_costmap/costmap
    robot = UnitreeGo2(ros_control, namespace="robot0")
    # Verify: Planner looks for /robot0/local_costmap/costmap
    # Should initialize successfully without timeout

def test_multi_robot():
    """Multiple robots can use different namespaces."""
    robot1 = UnitreeGo2(ros_control1, namespace="robot1")
    robot2 = UnitreeGo2(ros_control2, namespace="robot2")
    # Verify: Each robot uses its own topics and frames
```

---

## Deployment Notes

### For ShadowHound Mission Agent

After this is implemented in DIMOS, the mission agent can be simplified:

```python
# Before: Hacky workarounds in mission_executor.py
disable_video_stream=is_simulation,
self._fix_spatial_memory_transform_provider(robot_mode)

# After: Clean namespace parameter
self.robot = UnitreeGo2(
    ros_control=ros_control,
    ip=self.config.robot_ip,
    namespace="robot0" if robot_mode == "simulation" else "",
)
```

---

## Estimated Impact

- **Lines Changed**: ~80-100 across 3 files
- **Backward Compatibility**: 100% maintained (optional parameters)
- **Breaking Changes**: None
- **Testing Effort**: 2-3 hours
- **Implementation Effort**: 2-3 hours

---

**Note**: These changes should be made as a single coherent patch to the DIMOS submodule, not incrementally spread across mission_agent workarounds.
