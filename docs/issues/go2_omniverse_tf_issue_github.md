## Issue Title
TF Frame Namespace Inconsistency - Breaks Multi-Robot and Nav2 Integration

## Summary
The `go2_driver_node` publishes TF transforms with inconsistent frame naming (parent: `odom`, child: `robot0/base_link`), breaking multi-robot support and Nav2 integration. All frames should use consistent namespace prefixes.

## Current Behavior
```
/tf topic:
  odom → robot0/base_link → robot0/lidar_link
  ^^^^    ^^^^^^^^^^^^^^^^^^^
  No prefix    Has prefix
```

## Expected Behavior
```
/tf topic:
  robot0/odom → robot0/base_link → robot0/lidar_link
  ^^^^^^^^^^^    ^^^^^^^^^^^^^^^^^^^
  Consistent namespace prefix on ALL frames
```

## Impact
1. **Nav2 Integration Broken**: Nav2 looks for `robot0/odom` in TF, finds only `odom` → transform lookup fails
2. **Multi-Robot Impossible**: Multiple robots would all publish transforms with parent frame `odom` → TF tree corruption
3. **Inconsistent with Messages**: `/robot0/odom` topic has `frame_id: odom` but `child_frame_id: robot0/base_link`

## Error Observed
```
[robot0.local_costmap.local_costmap]: Timed out waiting for transform from base_link to odom
tf error: Invalid frame ID "odom" passed to canTransform - frame does not exist
```

## Root Cause
Isaac Sim extension hardcodes `"odom"` as frame_id instead of using robot namespace.

## Proposed Fix
Update odometry and TF publishers to include namespace prefix:

```python
# Current (BROKEN):
odom_msg.header.frame_id = "odom"
tf_transform.header.frame_id = "odom"

# Fixed:
odom_msg.header.frame_id = f"{robot_namespace}/odom"
tf_transform.header.frame_id = f"{robot_namespace}/odom"
```

## Verification Tests
1. `ros2 run tf2_ros tf2_monitor` should show `robot0/odom` frame
2. `ros2 run tf2_ros tf2_echo robot0/base_link robot0/odom` should succeed
3. `ros2 topic echo /robot0/odom --once` should show `frame_id: robot0/odom`
4. Nav2 costmap should not timeout waiting for transforms

## Priority
High - Blocks Nav2 integration and multi-robot testing

## Additional Context
- Branch: `added_copter`
- ROS2 multi-robot best practice: frames are namespaced, TF topic is global
- Currently using TF remapper node as workaround (adds latency)
- Detailed analysis: https://github.com/danmartinez78/shadowhound/blob/feature/laptop-sim-integration/docs/issues/go2_omniverse_tf_frame_namespace_issue.md
