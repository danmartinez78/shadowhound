---
tags: [development, namespace, implementation, planning]
status: active
related: 
  - ../architecture/namespace_migration_plan.md
  - ../architecture/NAMESPACE_MIGRATION_SUMMARY.md
summary: >
  Stage 1 implementation plan - Add robot_namespace parameter to launch files
---

# Stage 1 Implementation Plan - Launch File Infrastructure

**Status**: Ready to implement (DIMOS namespace support complete!)  
**Goal**: Add `robot_namespace` parameter to all launch files  
**Estimated Time**: 2-3 hours  
**Date**: October 21, 2025

---

## Prerequisites ✅

- [x] DIMOS namespace support merged (commit 531de18)
- [x] Migration plan documented
- [x] Feature branch ready (feature/laptop-sim-integration)

---

## Files to Modify

### 1. Top-Level Launch: `shadowhound.launch.py`

**File**: `src/shadowhound_bringup/launch/shadowhound.launch.py`

**Changes**:
```python
# ADD: robot_namespace parameter
robot_namespace_arg = DeclareLaunchArgument(
    "robot_namespace",
    default_value="",
    description="Robot namespace (empty for hardware, 'robot0' for sim)"
)

# ADD: robot_mode parameter (if not already present)
robot_mode_arg = DeclareLaunchArgument(
    "robot_mode",
    default_value="mock",
    description="Robot mode: 'hardware', 'simulation', or 'mock'"
)

# PASS: to child launch
launch_arguments={
    "robot_mode": LaunchConfiguration("robot_mode"),
    "robot_namespace": LaunchConfiguration("robot_namespace"),
    # ... other args
}.items()
```

### 2. Simulation Launch: `sim_autonomy.launch.py`

**File**: `src/shadowhound_bringup/launch/sim_autonomy.launch.py`

**Changes**:
```python
# ADD: Accept robot_namespace parameter
robot_namespace_arg = DeclareLaunchArgument(
    "robot_namespace",
    default_value="robot0",  # Default for simulation
    description="Robot namespace for simulation"
)

# UPDATE: SimAutonomyConfig to accept namespace
class SimAutonomyConfig:
    def __init__(self):
        # Get from launch configuration
        self.robot_namespace = LaunchConfiguration("robot_namespace")
        # OR get from parameter
        # self.robot_namespace = robot_namespace
```

**NOTE**: Current sim_autonomy.launch.py hardcodes "robot0" - make it configurable

### 3. Mission Agent Launch: `mission_agent.launch.py`

**File**: `src/shadowhound_mission_agent/launch/mission_agent.launch.py`

**Changes**:
```python
# ADD: robot_namespace parameter
robot_namespace_arg = DeclareLaunchArgument(
    "robot_namespace",
    default_value="",
    description="Robot namespace (empty for hardware/mock, 'robot0' for sim)"
)

# ADD: to mission_agent_node parameters
parameters=[
    {
        "robot_namespace": LaunchConfiguration("robot_namespace"),
        # ... other params
    }
]

# REMOVE: All topic remappings (20+ entries)
# DELETE this entire remappings section once namespace parameter works
```

---

## Implementation Steps

### Step 1: Add Parameters to Launch Files

1. **shadowhound.launch.py**:
   - Add `robot_namespace_arg`
   - Pass to mission_agent.launch.py

2. **sim_autonomy.launch.py**:
   - Add `robot_namespace_arg` with default="robot0"
   - Make SimAutonomyConfig.robot_namespace configurable

3. **mission_agent.launch.py**:
   - Add `robot_namespace_arg`
   - Add to node parameters
   - Keep remappings for now (Stage 2 will remove)

### Step 2: Test Parameter Passing

```bash
# Test hardware mode (no namespace)
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=hardware \
    robot_namespace:=""

# Test simulation mode (robot0 namespace)
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=simulation \
    robot_namespace:=robot0

# Test custom namespace
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=simulation \
    robot_namespace:=my_robot
```

### Step 3: Validate

```bash
# Check parameter is received by mission agent
ros2 param list /mission_agent
ros2 param get /mission_agent robot_namespace

# Verify topics are NOT yet namespaced (that's Stage 2)
ros2 topic list
# Should still see remapped topics (that's expected for Stage 1)
```

---

## Testing Checklist

### Unit Tests
- [ ] Launch files parse without errors
- [ ] Parameters have correct defaults
- [ ] Parameters pass through launch hierarchy

### Integration Tests
- [ ] Hardware mode: namespace="" works
- [ ] Simulation mode: namespace="robot0" works
- [ ] Custom namespace: namespace="my_robot" works
- [ ] Mission agent receives parameter correctly

### Regression Tests
- [ ] Existing hardware mode still works
- [ ] No breaking changes to current functionality

---

## Stage 1 Success Criteria

- ✅ All launch files accept `robot_namespace` parameter
- ✅ Parameter has correct defaults (empty for hardware, robot0 for sim)
- ✅ Parameter passes through entire launch hierarchy
- ✅ Mission agent receives parameter as ROS parameter
- ✅ No breaking changes to hardware mode
- ⚠️ Topic remapping still in place (will remove in Stage 2)

---

## Known Limitations (Stage 1)

**Not Yet Implemented**:
- Mission agent doesn't use namespace parameter yet (Stage 2)
- Topic remapping still in place (Stage 2 will remove)
- Config files still hardcoded (Stage 3)

**This is Expected**: Stage 1 is infrastructure only, not functional changes

---

## Next Steps (Stage 2)

After Stage 1 complete:
1. Update mission_executor.py to read `robot_namespace` parameter
2. Pass namespace to `UnitreeGo2(namespace=...)`
3. Remove all topic remapping from mission_agent.launch.py
4. Test hardware mode (regression)
5. Test simulation mode (should work without remapping!)

---

## Quick Commands Reference

```bash
# Build workspace
colcon build --packages-select shadowhound_bringup shadowhound_mission_agent

# Source
source install/setup.bash

# Test launch files
ros2 launch shadowhound_bringup shadowhound.launch.py --show-args

# Check parameters
ros2 param list
ros2 param get /mission_agent robot_namespace
```

---

**Estimated Time**: 2-3 hours  
**Complexity**: Low (just parameter plumbing)  
**Risk**: Very low (backward compatible changes only)

---

**Ready to implement!** 🚀
