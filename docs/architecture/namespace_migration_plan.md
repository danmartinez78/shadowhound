---
tags: [architecture, namespacing, simulation, multi-robot, planning]
status: draft
related: 
  - ../development/SESSION_HANDOFF_OCT21_2025.md
  - ../issues/dimos_namespace_support_issue.md
  - ../issues/dimos_namespace_support_implementation.md
summary: >
  Complete migration plan for namespace support across the entire ShadowHound stack
---

# Namespace Migration Plan

**Purpose**: Migrate entire ShadowHound stack to support ROS2 namespacing for multi-robot simulation  
**Scope**: All launch files, configuration files, and robot initialization  
**Priority**: HIGH - Required for simulation testing  
**Status**: Planning Phase

---

## Context

### Current Situation

**Problem**: ShadowHound is hardcoded for non-namespaced topics/frames
- Isaac Sim publishes `/robot0/*` topics (multi-robot capable)
- Mission agent expects non-namespaced topics (`/cmd_vel`, `/odom`, etc.)
- DIMOS library doesn't support namespaces (Issue #9 created, blocked)
- Temporary workarounds exist (topic remapping in launch files)

**Use Case**: 
- **Simulation only** - Isaac Sim uses namespaces for multi-robot support
- **Hardware does NOT need namespacing** - Real Go2 publishes standard ROS2 topics

---

## Architecture Goals

### Clean Namespace Switching

The system should support **three deployment modes** with clean configuration:

```
┌─────────────────────────────────────────────────────────────┐
│                   Deployment Mode                            │
├─────────────────────────────────────────────────────────────┤
│ 1. Hardware      → No namespace  (standard ROS2 topics)     │
│ 2. Simulation    → robot0 namespace (Isaac Sim compatible)  │
│ 3. Multi-Sim     → robot0, robot1, ... (future)             │
└─────────────────────────────────────────────────────────────┘
```

### Design Principles

1. **Parameter-Driven**: Single `robot_namespace` parameter controls everything
2. **No Code Duplication**: Same codebase for all modes
3. **Launch File Configuration**: Mode selection at launch, not build time
4. **Backward Compatible**: Hardware mode unchanged (namespace="")
5. **DIMOS-First**: Wait for DIMOS namespace support before implementing

---

## Migration Stages

### Stage 0: BLOCKED - DIMOS Namespace Support ⏳

**Status**: Waiting on DIMOS Issue #9 implementation  
**Blocker**: https://github.com/danmartinez78/dimos-unitree/issues/9

**What's Needed**:
- DIMOS `UnitreeGo2` accepts `namespace` parameter
- DIMOS planners use namespaced topics
- DIMOS transforms use namespaced frames

**When Complete**: Move to Stage 1

---

### Stage 1: Launch File Infrastructure ✅ (In Progress)

**Goal**: Create parameter-driven launch file structure

#### 1.1 Add Global Namespace Parameter

Create top-level namespace parameter in all launch files:

```python
# In shadowhound.launch.py, sim_autonomy.launch.py, mission_agent.launch.py
robot_namespace_arg = DeclareLaunchArgument(
    "robot_namespace",
    default_value="",
    description="Robot namespace (empty for hardware, 'robot0' for sim, etc.)"
)
```

#### 1.2 Create Mode Detection Helper

Add helper to determine namespace from robot_mode:

```python
# In launch/utils/namespace_utils.py (NEW FILE)
def get_namespace_from_mode(robot_mode: str) -> str:
    """
    Determine namespace based on robot mode.
    
    Args:
        robot_mode: 'hardware', 'simulation', or 'mock'
        
    Returns:
        Namespace string (empty for hardware/mock, 'robot0' for simulation)
    """
    if robot_mode == "simulation":
        return "robot0"
    return ""
```

#### 1.3 Update Launch File Hierarchy

**Current**: Three separate launch files with different purposes
```
shadowhound.launch.py        → Main entry point (mission agent only)
sim_autonomy.launch.py        → Autonomy stack for simulation
mission_agent.launch.py       → Mission agent + DIMOS integration
```

**Proposed**: Unified parameter passing

```python
# shadowhound.launch.py (top-level)
def generate_launch_description():
    robot_mode_arg = DeclareLaunchArgument("robot_mode", default_value="mock")
    robot_namespace_arg = DeclareLaunchArgument("robot_namespace", default_value="")
    
    # Compute namespace from mode if not explicitly set
    robot_namespace = LaunchConfiguration("robot_namespace")
    robot_mode = LaunchConfiguration("robot_mode")
    
    return LaunchDescription([
        robot_mode_arg,
        robot_namespace_arg,
        
        # Pass both to child launches
        IncludeLaunchDescription(
            PathJoinSubstitution([FindPackageShare("shadowhound_mission_agent"), "launch", "mission_agent.launch.py"]),
            launch_arguments={
                "robot_mode": robot_mode,
                "robot_namespace": robot_namespace,
            }.items()
        )
    ])
```

---

### Stage 2: Mission Agent Namespace Integration 🎯 (Next)

**Goal**: Make mission_executor.py namespace-aware

#### 2.1 Remove Topic Remapping Workarounds

**Current (Temporary Workaround)**:
```python
# mission_agent.launch.py - REMOVE THIS
remappings=[
    ("/cmd_vel", "/robot0/cmd_vel"),
    ("cmd_vel", "robot0/cmd_vel"),
    # ... 20+ remapping entries ...
]
```

**Proposed (Clean)**:
```python
# mission_agent.launch.py - AFTER DIMOS NAMESPACE SUPPORT
parameters=[
    {
        "robot_namespace": LaunchConfiguration("robot_namespace"),
        # ... other params ...
    }
]
# NO topic remapping needed!
```

#### 2.2 Update mission_executor.py

**Current**:
```python
# mission_executor.py (simplified)
self.robot = UnitreeGo2(
    ros_control=ros_control,
    ip=self.config.robot_ip,
)
```

**Proposed**:
```python
# mission_executor.py - AFTER DIMOS NAMESPACE SUPPORT
robot_namespace = self.get_parameter("robot_namespace").value
self.robot = UnitreeGo2(
    ros_control=ros_control,
    ip=self.config.robot_ip,
    namespace=robot_namespace,  # DIMOS will handle namespacing internally
)
```

---

### Stage 3: Configuration File Namespace Support 🔧

**Goal**: Make Nav2/SLAM configs namespace-aware

#### 3.1 Smart Config Selection

**Current**: Separate simulation config files
- `config/nav2_params_simulation.yaml` (hardcoded `robot0/` frames)
- `config/nav2_params.yaml` (no namespace)

**Problem**: Not flexible for multi-robot or different namespaces

**Proposed**: Parameter substitution in launch files

```python
# sim_autonomy.launch.py
def create_nav2_params(robot_namespace: str) -> dict:
    """Generate Nav2 parameters with namespace applied."""
    base_params = load_yaml("nav2_params.yaml")  # Template without namespace
    
    if robot_namespace:
        # Apply namespace to frame names
        apply_namespace_to_frames(base_params, robot_namespace)
    
    return base_params
```

**Alternative**: Use ROS2 parameter substitution (if supported by Nav2)

```yaml
# nav2_params_template.yaml
global_frame: $(var robot_namespace)/map
robot_base_frame: $(var robot_namespace)/base_link
odom_topic: $(var robot_namespace)/odom
```

#### 3.2 Frame Name Conventions

**Standard Pattern**: `{namespace}/{frame_name}`

```
Hardware (no namespace):
  - map
  - base_link
  - odom
  
Simulation (robot0):
  - robot0/map
  - robot0/base_link
  - robot0/odom
  
Multi-Robot (robot1, robot2):
  - robot1/map, robot2/map
  - robot1/base_link, robot2/base_link
```

---

### Stage 4: Multi-Robot Launch Architecture 🤖🤖 (Future)

**Goal**: Support launching multiple robots simultaneously

#### 4.1 Robot Instance Launch File

Create `robot_instance.launch.py` (composable):

```python
# robot_instance.launch.py (NEW)
def generate_launch_description():
    robot_namespace_arg = DeclareLaunchArgument("robot_namespace", default_value="robot0")
    robot_id_arg = DeclareLaunchArgument("robot_id", default_value="0")
    
    robot_namespace = LaunchConfiguration("robot_namespace")
    
    return LaunchDescription([
        robot_namespace_arg,
        robot_id_arg,
        
        # Mission agent for this robot
        Node(
            package="shadowhound_mission_agent",
            executable="mission_agent",
            namespace=robot_namespace,  # ROS2 node namespace
            parameters=[{
                "robot_namespace": robot_namespace,  # Topic/frame namespace
                # ...
            }]
        ),
        
        # Nav2 stack for this robot
        IncludeLaunchDescription(
            # ... Nav2 with namespace ...
        )
    ])
```

#### 4.2 Multi-Robot Orchestrator

Create `multi_robot.launch.py`:

```python
# multi_robot.launch.py (FUTURE)
def generate_launch_description():
    num_robots_arg = DeclareLaunchArgument("num_robots", default_value="2")
    
    # Launch multiple robot instances
    robot_launches = []
    for i in range(int(LaunchConfiguration("num_robots"))):
        robot_launches.append(
            IncludeLaunchDescription(
                PathJoinSubstitution([FindPackageShare("shadowhound_bringup"), "launch", "robot_instance.launch.py"]),
                launch_arguments={
                    "robot_namespace": f"robot{i}",
                    "robot_id": str(i),
                }.items()
            )
        )
    
    return LaunchDescription([num_robots_arg] + robot_launches)
```

---

## Implementation Checklist

### Prerequisites (Blocked)
- [ ] DIMOS Issue #9 implemented and merged
- [ ] DIMOS supports `namespace` parameter
- [ ] Update dimos-unitree submodule to latest

### Stage 1: Launch Infrastructure
- [ ] Add `robot_namespace` parameter to `shadowhound.launch.py`
- [ ] Add `robot_namespace` parameter to `sim_autonomy.launch.py`
- [ ] Add `robot_namespace` parameter to `mission_agent.launch.py`
- [ ] Create `launch/utils/namespace_utils.py` helper
- [ ] Test parameter passing through launch hierarchy

### Stage 2: Mission Agent Integration
- [ ] Remove topic remapping workarounds from `mission_agent.launch.py`
- [ ] Add `robot_namespace` parameter to mission_executor.py
- [ ] Pass namespace to `UnitreeGo2()` constructor
- [ ] Test hardware mode (namespace="")
- [ ] Test simulation mode (namespace="robot0")
- [ ] Update documentation

### Stage 3: Configuration Files
- [ ] Create Nav2 parameter template (no hardcoded frames)
- [ ] Create SLAM parameter template
- [ ] Implement dynamic parameter generation in launch files
- [ ] Test with different namespaces
- [ ] Validate TF tree correctness

### Stage 4: Multi-Robot (Future)
- [ ] Create `robot_instance.launch.py`
- [ ] Create `multi_robot.launch.py`
- [ ] Test 2-robot simulation
- [ ] Document multi-robot usage
- [ ] Add multi-robot mission coordination

---

## Testing Strategy

### Unit Tests

```python
# test_namespace_utils.py
def test_get_namespace_from_mode():
    assert get_namespace_from_mode("hardware") == ""
    assert get_namespace_from_mode("mock") == ""
    assert get_namespace_from_mode("simulation") == "robot0"
```

### Integration Tests

#### Test 1: Hardware Mode (Regression)
```bash
# Should work exactly as before
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=hardware

# Verify:
# - No namespace in topic names
# - Frames: map, base_link, odom
# - Robot initializes without timeout
```

#### Test 2: Simulation Mode (Single Robot)
```bash
# Should use robot0 namespace
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=simulation

# Verify:
# - Topics: /robot0/cmd_vel, /robot0/odom, etc.
# - Frames: robot0/map, robot0/base_link, robot0/odom
# - Robot initializes < 2 seconds (no blocking timeouts)
# - TF tree shows robot0/* frames
```

#### Test 3: Explicit Namespace Override
```bash
# Use custom namespace
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=simulation \
    robot_namespace:=my_robot

# Verify:
# - Topics use my_robot/* namespace
# - Frames use my_robot/* prefix
```

#### Test 4: Multi-Robot (Future)
```bash
# Launch 2 robots
ros2 launch shadowhound_bringup multi_robot.launch.py \
    num_robots:=2

# Verify:
# - robot0 and robot1 topics exist
# - Separate TF trees
# - No frame conflicts
```

---

## Success Criteria

### Stage 1 Complete When:
- ✅ All launch files accept `robot_namespace` parameter
- ✅ Parameter passing tested through entire launch hierarchy
- ✅ No breaking changes to hardware mode

### Stage 2 Complete When:
- ✅ Mission agent uses namespace parameter
- ✅ No topic remapping in launch files
- ✅ Hardware mode regression test passes
- ✅ Simulation mode initializes without timeouts
- ✅ All skills execute correctly in both modes

### Stage 3 Complete When:
- ✅ Nav2/SLAM configs are namespace-agnostic
- ✅ Dynamic parameter generation works
- ✅ TF frames resolve correctly in all modes
- ✅ Multi-namespace tested (robot0, robot1)

### Stage 4 Complete When:
- ✅ Multiple robots launch cleanly
- ✅ No topic/frame conflicts
- ✅ Independent mission execution per robot
- ✅ Documentation complete

---

## Migration Timeline

**Assumptions**: 
- DIMOS Issue #9 completed (prerequisite)
- 1 developer, full-time focus

```
Week 1: Stage 1 (Launch Infrastructure)
  Day 1-2: Parameter implementation
  Day 3-4: Testing and refinement
  Day 5:   Documentation

Week 2: Stage 2 (Mission Agent Integration)
  Day 1-2: Remove workarounds, add namespace parameter
  Day 3:   DIMOS integration
  Day 4-5: Testing (hardware + simulation)

Week 3: Stage 3 (Configuration Files)
  Day 1-2: Template creation
  Day 3-4: Dynamic generation implementation
  Day 5:   Testing and validation

Week 4: Stage 4 (Multi-Robot) - OPTIONAL
  Day 1-2: robot_instance.launch.py
  Day 3-4: multi_robot.launch.py
  Day 5:   Testing and documentation
```

**Fast Track** (Stages 1-2 only): ~10 days  
**Complete** (Stages 1-4): ~20 days

---

## Risk Mitigation

### Risk 1: DIMOS Namespace Support Delays

**Impact**: HIGH - Blocks all stages  
**Mitigation**: 
- Monitor DIMOS Issue #9 progress
- Offer to help implement if needed
- Consider forking DIMOS if blocked long-term

### Risk 2: Nav2/SLAM Parameter Incompatibility

**Impact**: MEDIUM - May need parameter workarounds  
**Mitigation**:
- Test parameter substitution early
- Fallback to separate config files if needed
- Document known limitations

### Risk 3: TF Frame Name Conflicts

**Impact**: LOW - Well-understood problem in ROS2  
**Mitigation**:
- Follow ROS2 frame naming conventions
- Validate TF tree with `ros2 run tf2_tools view_frames`
- Use rqt_tf_tree for debugging

### Risk 4: Backward Compatibility Break

**Impact**: HIGH - Could break existing deployments  
**Mitigation**:
- Maintain hardware mode default (no namespace)
- Extensive regression testing
- Deprecation warnings if API changes

---

## Alternative Approaches Considered

### Alternative 1: Separate Launch Files per Mode

**Approach**: Keep separate launch files for hardware/simulation
```
shadowhound_hardware.launch.py
shadowhound_simulation.launch.py
```

**Pros**: Clear separation, no mode switching logic  
**Cons**: Code duplication, maintenance burden

**Decision**: REJECTED - Violates DRY principle

### Alternative 2: Environment Variable Only

**Approach**: Use `ROBOT_NAMESPACE` environment variable
```bash
export ROBOT_NAMESPACE=robot0
ros2 launch shadowhound_bringup shadowhound.launch.py
```

**Pros**: Simple, no launch file changes  
**Cons**: Less discoverable, harder to override

**Decision**: REJECTED - Launch parameters more explicit

### Alternative 3: Build-Time Configuration

**Approach**: Separate workspace builds for sim vs hardware

**Pros**: Maximum isolation  
**Cons**: Extremely inflexible, not scalable

**Decision**: REJECTED - Too rigid for development

---

## Documentation Updates Required

### User-Facing Docs
- [ ] `docs/software/robot_modes.md` - Add namespace examples
- [ ] `docs/simulation/README.md` - Document simulation namespace
- [ ] `README.md` - Update quick start commands
- [ ] `docs/troubleshooting/namespace_issues.md` - Common problems

### Developer Docs
- [ ] `docs/architecture/namespace_architecture.md` - Design rationale
- [ ] `docs/software/packages/shadowhound_bringup/README.md` - Launch params
- [ ] `.github/copilot-instructions.md` - Namespace conventions

### API Docs
- [ ] Mission agent parameter documentation
- [ ] Launch file parameter reference
- [ ] Configuration file templates

---

## Future Enhancements

### Fleet Coordination
Once multi-robot works:
- Centralized mission dispatcher
- Inter-robot communication
- Shared map fusion
- Formation control

### Dynamic Namespace Assignment
- Auto-detect available robots
- Dynamic namespace allocation
- Robot discovery protocol

### Namespace-Aware Visualization
- Multi-robot RViz configs
- Per-robot namespacing in Foxglove
- Fleet dashboard

---

## References

- DIMOS Issue #9: https://github.com/danmartinez78/dimos-unitree/issues/9
- ROS2 REP 105: Coordinate Frames for Mobile Platforms
- ROS2 Best Practices: Multi-Robot Namespacing
- Isaac Sim Multi-Robot Tutorial

---

**Document Owner**: ShadowHound Development Team  
**Last Updated**: 2025-10-21  
**Next Review**: After DIMOS Issue #9 completion

---

## Appendix A: Quick Reference Commands

### Current (Temporary Workarounds)
```bash
# Simulation with topic remapping
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    robot_mode:=simulation
# (Uses 20+ topic remappings internally)
```

### After Migration (Clean)
```bash
# Hardware (default)
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=hardware

# Simulation (single robot)
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=simulation

# Simulation (custom namespace)
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=simulation \
    robot_namespace:=my_robot

# Multi-robot (future)
ros2 launch shadowhound_bringup multi_robot.launch.py \
    num_robots:=3
```

### Debugging
```bash
# Check active namespaces
ros2 node list | grep robot

# Verify TF frames
ros2 run tf2_tools view_frames

# Monitor namespaced topics
ros2 topic list | grep robot0

# Echo namespaced topic
ros2 topic echo /robot0/cmd_vel
```

---

## Appendix B: Namespace Pattern Examples

### Topic Naming
```python
# No namespace (hardware)
/cmd_vel
/odom
/camera/image_raw

# With namespace (simulation)
/robot0/cmd_vel
/robot0/odom
/robot0/camera/image_raw

# Building dynamically
namespace = "robot0"
cmd_vel_topic = f"/{namespace}/cmd_vel" if namespace else "/cmd_vel"
```

### Frame Naming
```python
# No namespace (hardware)
map → odom → base_link

# With namespace (simulation)
robot0/map → robot0/odom → robot0/base_link

# Building dynamically
namespace = "robot0"
map_frame = f"{namespace}/map" if namespace else "map"
base_frame = f"{namespace}/base_link" if namespace else "base_link"
```

### Parameter Namespacing
```yaml
# Nav2 params (no namespace)
global_frame: map
robot_base_frame: base_link

# Nav2 params (with namespace)
global_frame: robot0/map
robot_base_frame: robot0/base_link
```
