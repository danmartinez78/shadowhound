# TF Frame Namespace Inconsistency - Breaks Multi-Robot and Nav2 Integration

## Problem Summary

The `go2_driver_node` publishes TF transforms with **inconsistent frame naming**, breaking multi-robot support and Nav2 integration:

**Current behavior:**
```
/tf topic:
  odom → robot0/base_link → robot0/lidar_link
  ^^^^    ^^^^^^^^^^^^^^^^^^^
  No namespace prefix    Has namespace prefix
```

**Expected behavior:**
```
/tf topic:
  robot0/odom → robot0/base_link → robot0/lidar_link
  ^^^^^^^^^^^    ^^^^^^^^^^^^^^^^^^^
  Consistent namespace prefix on ALL frames
```

## Impact

### 1. Breaks Nav2 Integration ❌

Nav2 expects consistent frame naming. When running in namespace `robot0`:

```yaml
# Nav2 config
local_costmap:
  global_frame: robot0/odom
  robot_base_frame: robot0/base_link
```

Nav2 looks for `robot0/odom` in TF, but only `odom` exists → **Transform lookup fails**

**Error seen:**
```
[robot0.local_costmap.local_costmap]: Timed out waiting for transform from base_link to odom
tf error: Invalid frame ID "odom" passed to canTransform argument target_frame - frame does not exist
```

### 2. Breaks Multi-Robot Support ❌

With multiple robots, each would publish:
- Robot 0: `odom` → `robot0/base_link`
- Robot 1: `odom` → `robot1/base_link`

**Problem**: Multiple transforms with the same parent frame `odom` → **TF tree corruption**

ROS2 TF2 maintains a single global transform tree. Without namespaced frames, you cannot have multiple robots.

### 3. Inconsistent with Odometry Message ❌

The `/robot0/odom` topic message has:
```yaml
header:
  frame_id: odom              # No prefix
child_frame_id: robot0/base_link  # Has prefix
```

This mismatch is confusing and breaks assumptions in many ROS2 tools.

## Root Cause

The Isaac Sim extension publishes TF transforms and odometry messages with hardcoded `"odom"` frame_id, instead of using the robot namespace.

**Likely location in code:**
```python
# Current (BROKEN):
odom_msg.header.frame_id = "odom"
tf_transform.header.frame_id = "odom"

# Should be:
odom_msg.header.frame_id = f"{robot_namespace}/odom"
tf_transform.header.frame_id = f"{robot_namespace}/odom"
```

## Proposed Solution

### Fix: Add Namespace Prefix to Odom Frame

**Changes needed:**

1. **Odometry message** - Update frame_id:
   ```python
   odom_msg.header.frame_id = f"{robot_namespace}/odom"  # or "robot0/odom"
   odom_msg.child_frame_id = f"{robot_namespace}/base_link"  # Already correct
   ```

2. **TF transform** - Update parent frame_id:
   ```python
   tf_transform.header.frame_id = f"{robot_namespace}/odom"
   tf_transform.child_frame_id = f"{robot_namespace}/base_link"  # Already correct
   ```

3. **Keep publishing to global `/tf` topic** (not `/robot0/tf`)
   - Frames are namespaced, topic is global
   - Standard ROS2 multi-robot pattern

### Expected Result

After fix:
```
/tf topic:
  robot0/odom → robot0/base_link → robot0/lidar_link
```

All transforms have consistent `robot0/` namespace prefix.

## Files to Modify

Based on the repository structure, likely files:

1. **ROS2 Bridge/Driver Node**:
   - `IsaacSim-ros_workspaces/src/*/` - ROS2 bridge nodes
   - Look for: odometry publisher, TF publisher

2. **Isaac Sim Extension**:
   - `Isaac_sim/` - USD files and Python extensions
   - Search for: `"odom"`, `frame_id`, TF broadcasting

3. **Launch Configuration**:
   - `go2_omniverse_ws/src/go2_description/launch/` - ROS2 launch files
   - May need to pass namespace parameter to nodes

## Verification

After implementing the fix:

### Test 1: Check TF Frames
```bash
ros2 run tf2_ros tf2_monitor

# Expected output:
# Frame: robot0/odom
# Frame: robot0/base_link
# Frame: robot0/lidar_link
```

### Test 2: Check Transform Lookup
```bash
ros2 run tf2_ros tf2_echo robot0/base_link robot0/odom

# Should output transform data, not "frame does not exist"
```

### Test 3: Check Odometry Message
```bash
ros2 topic echo /robot0/odom --once

# Expected:
# header:
#   frame_id: robot0/odom        ← Fixed!
# child_frame_id: robot0/base_link
```

### Test 4: Nav2 Integration
```bash
# Launch Nav2 with robot0 namespace
# Should NOT see TF timeout errors
```

## Additional Context

### ROS2 Multi-Robot TF Best Practices

From ROS2 documentation:

1. **Frames are namespaced**: `robot0/base_link`, `robot1/base_link`
2. **TF topic is global**: All robots publish to `/tf` (not `/robot0/tf`)
3. **Consistent naming**: All frames in a robot's tree have the same prefix

### Current Workaround

We've added a TF remapper node as a temporary workaround, but this:
- Adds unnecessary latency
- Doesn't solve the root cause
- Needs to be removed once this is fixed

## Related Documentation

- **ShadowHound TF Frame Reference**: [docs/architecture/tf_frame_reference.md](https://github.com/danmartinez78/shadowhound/blob/feature/laptop-sim-integration/docs/architecture/tf_frame_reference.md)
- **ROS2 TF2 Tutorial**: http://docs.ros.org/en/humble/Tutorials/Intermediate/Tf2/Introduction-To-Tf2.html
- **Nav2 Multi-Robot**: https://docs.nav2.org/tutorials/docs/navigation2_with_slam.html

## Priority

**High** - Blocks proper Nav2 integration and multi-robot testing

---

**Repository**: https://github.com/danmartinez78/go2_omniverse  
**Branch**: `added_copter`  
**Reported by**: ShadowHound Integration Team  
**Date**: October 26, 2025
