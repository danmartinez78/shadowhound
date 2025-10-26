---
tags: [architecture, tf, frames, simulation, multi-robot]
status: active
related: [docs/simulation/isaac_sim_integration.md]
summary: >
  TF frame structure and publisher responsibilities for ShadowHound simulation stack.
  Documents the current Isaac Sim TF publishing pattern and Nav2 expectations.
---

# TF Frame Reference - ShadowHound Simulation

## Current State Analysis (October 26, 2025)

### Problem Summary
**Isaac Sim is publishing TF transforms on the GLOBAL `/tf` topic with MIXED frame naming:**
- Parent frame: `odom` (no namespace prefix)
- Child frame: `robot0/base_link` (with namespace prefix)

This creates a mismatch where Nav2 cannot find the correct transforms.

---

## Published Frames (Current)

### TF Topic: `/tf` (Global, non-namespaced)

**Transform: `odom` → `robot0/base_link`**
- **Publisher**: Isaac Sim `go2_driver_node` (running on Tower)
- **Rate**: ~38 Hz
- **Frame ID**: `odom` (NO namespace prefix)
- **Child Frame ID**: `robot0/base_link` (WITH namespace prefix)
- **Issue**: ⚠️ **Inconsistent naming - parent has no prefix, child has prefix**

**Transform: `robot0/base_link` → `robot0/lidar_link`**
- **Publisher**: Isaac Sim `go2_driver_node` (unknown authority in tf2_monitor)
- **Rate**: ~38 Hz
- **Frame ID**: `robot0/base_link`
- **Child Frame ID**: `robot0/lidar_link`
- **Status**: ✅ Consistent naming (both have prefix)

**Transform: `robot0/base_link` → `robot0/UnitreeL1_link`**
- **Publisher**: Isaac Sim `go2_driver_node` (unknown authority in tf2_monitor)
- **Rate**: ~38 Hz
- **Frame ID**: `robot0/base_link`
- **Child Frame ID**: `robot0/UnitreeL1_link`
- **Status**: ✅ Consistent naming (both have prefix)

### Odom Topic: `/robot0/odom`

**Message Header:**
```yaml
header:
  frame_id: odom                    # ⚠️ No namespace prefix
child_frame_id: robot0/base_link   # ✅ Has namespace prefix
```

**Issue**: The odometry message publishes with `frame_id: odom`, matching the TF transform parent frame.

---

## Expected Frame Structure for Multi-Robot

### Option 1: Fully Namespaced (RECOMMENDED)

**All frames should have the robot namespace prefix:**

```
robot0/odom                         ← Fixed world frame
    └─ robot0/base_link            ← Robot base
        ├─ robot0/lidar_link       ← LiDAR sensor
        └─ robot0/UnitreeL1_link   ← Other sensor
```

**Published on**: `/tf` (global topic, frames are namespaced)

**Benefits:**
- ✅ True multi-robot support (robot0, robot1, etc.)
- ✅ No frame name collisions
- ✅ Clear ownership of frames
- ✅ Standard ROS2 multi-robot pattern

**Nav2 Configuration:**
```yaml
local_costmap:
  local_costmap:
    ros__parameters:
      global_frame: robot0/odom
      robot_base_frame: robot0/base_link
```

### Option 2: Non-Namespaced Frames (Single Robot Only)

**All frames without namespace prefix:**

```
odom                               ← Fixed world frame
    └─ base_link                   ← Robot base
        ├─ lidar_link              ← LiDAR sensor
        └─ UnitreeL1_link          ← Other sensor
```

**Published on**: `/tf` (global topic, frames are NOT namespaced)

**Benefits:**
- ✅ Simpler configuration
- ✅ Matches many single-robot examples

**Drawbacks:**
- ❌ Cannot run multiple robots (frame name collisions)
- ❌ Not scalable

**Nav2 Configuration:**
```yaml
local_costmap:
  local_costmap:
    ros__parameters:
      global_frame: odom
      robot_base_frame: base_link
```

### Option 3: Namespaced Topics, Non-Namespaced Frames (AVOID)

**Frames without prefix, published on namespaced topic:**

```
Published on /robot0/tf:
  odom → base_link → lidar_link
```

**Status**: ❌ **Anti-pattern - creates confusion and breaks tools**

---

## Current Implementation Issues

### Issue 1: Inconsistent Frame Naming

**Current State:**
```
/tf topic:
  odom → robot0/base_link → robot0/lidar_link
  ^^^^    ^^^^^^^^^^^^^^^^^^^
  No prefix  Has prefix
```

**Problem**: 
- TF tree has mixed naming convention
- Nav2 expects consistent naming
- When Nav2 runs in namespace `robot0`, it looks for `robot0/base_link` relative to its namespace
- This becomes `robot0/robot0/base_link` which doesn't exist

**Error Seen:**
```
[robot0.local_costmap.local_costmap]: Timed out waiting for transform from base_link to odom
tf error: Invalid frame ID "odom" passed to canTransform argument target_frame - frame does not exist
```

**Root Cause**: Nav2 is looking for `robot0/odom`, but TF has `odom`

### Issue 2: Frame Authority Unknown

**tf2_monitor output:**
```
Node: <no authority available> 38.2954 Hz
```

**Problem**: Cannot determine which node is publishing transforms
**Impact**: Hard to debug, hard to fix at source

---

## Resolution Options

### Option A: Fix Isaac Sim Driver (BEST - Upstream Fix)

**Change Isaac Sim `go2_driver_node` to publish fully namespaced frames:**

```python
# In Isaac Sim go2_driver_node
odom_msg.header.frame_id = f"{namespace}/odom"       # Was: "odom"
odom_msg.child_frame_id = f"{namespace}/base_link"   # Already correct

# For TF transforms
transform.header.frame_id = f"{namespace}/odom"      # Was: "odom"
transform.child_frame_id = f"{namespace}/base_link"  # Already correct
```

**Benefits:**
- ✅ Fixes root cause
- ✅ Enables multi-robot simulation
- ✅ Follows ROS2 best practices
- ✅ No workarounds needed

**Status**: Requires access to Isaac Sim extension source code

### Option B: Add TF Remapping Node (WORKAROUND)

**Create a TF republisher that fixes frame names:**

```python
class TFFrameRemapper(Node):
    """Republishes /tf transforms with corrected frame names"""
    
    def __init__(self):
        super().__init__('tf_frame_remapper')
        self.sub = self.create_subscription(
            TFMessage, '/tf', self.tf_callback, 10)
        self.pub = self.create_publisher(TFMessage, '/tf', 10)
    
    def tf_callback(self, msg):
        for transform in msg.transforms:
            # Fix: odom → robot0/odom
            if transform.header.frame_id == "odom":
                transform.header.frame_id = "robot0/odom"
        
        # Republish corrected transforms
        self.pub.publish(msg)
```

**Benefits:**
- ✅ No Isaac Sim source code changes needed
- ✅ Can implement immediately
- ✅ Fixes the immediate issue

**Drawbacks:**
- ⚠️ Workaround, not a real fix
- ⚠️ Extra node in the pipeline
- ⚠️ Slight latency increase

### Option C: Update Nav2 Config Only (PARTIAL FIX - CURRENT)

**Use mixed naming in Nav2 config:**

```yaml
# config/nav2_params_simulation.yaml
local_costmap:
  local_costmap:
    ros__parameters:
      global_frame: robot0/odom      # Nav2 will look for this frame
      robot_base_frame: robot0/base_link
```

**Status**: ⚠️ **This is what we just tried - it won't work!**

**Why it fails:**
- Nav2 looks for `robot0/odom` in TF
- TF only has `odom` (no prefix)
- Transform lookup fails

---

## Recommended Solution

### Step 1: Add TF Frame Prefix Remapper (Immediate)

Create `shadowhound_bringup/scripts/tf_frame_remapper.py`:

```python
#!/usr/bin/env python3
"""
TF Frame Remapper - Fixes Isaac Sim's inconsistent frame naming

Problem: Isaac Sim publishes:
  - odom → robot0/base_link (mixed naming)

Solution: Remap to:
  - robot0/odom → robot0/base_link (consistent naming)
"""

import rclpy
from rclpy.node import Node
from tf2_msgs.msg import TFMessage
from geometry_msgs.msg import TransformStamped

class TFFrameRemapper(Node):
    def __init__(self):
        super().__init__('tf_frame_remapper')
        
        # Get namespace parameter
        self.declare_parameter('robot_namespace', 'robot0')
        self.namespace = self.get_parameter('robot_namespace').value
        
        # Subscribe to global /tf
        self.tf_sub = self.create_subscription(
            TFMessage, '/tf', self.tf_callback, 10)
        
        # Republish corrected transforms
        self.tf_pub = self.create_publisher(TFMessage, '/tf', 10)
        
        self.get_logger().info(
            f'TF Frame Remapper started for namespace: {self.namespace}')
        self.get_logger().info(
            f'Will remap: odom → {self.namespace}/odom')
    
    def tf_callback(self, msg: TFMessage):
        """Remap frame IDs to include namespace prefix"""
        remapped_transforms = []
        
        for transform in msg.transforms:
            # Create a copy
            new_transform = TransformStamped()
            new_transform.header = transform.header
            new_transform.child_frame_id = transform.child_frame_id
            new_transform.transform = transform.transform
            
            # Fix parent frame if it's "odom" without prefix
            if transform.header.frame_id == "odom":
                new_transform.header.frame_id = f"{self.namespace}/odom"
                self.get_logger().debug(
                    f'Remapped: odom → {self.namespace}/odom', 
                    throttle_duration_sec=5.0)
            else:
                new_transform.header.frame_id = transform.header.frame_id
            
            remapped_transforms.append(new_transform)
        
        # Publish remapped transforms
        remapped_msg = TFMessage(transforms=remapped_transforms)
        self.tf_pub.publish(remapped_msg)

def main(args=None):
    rclpy.init(args=args)
    node = TFFrameRemapper()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
```

### Step 2: Add to Launch File

Add to `sim_autonomy.launch.py`:

```python
# TF Frame Remapper - fixes Isaac Sim's inconsistent frame naming
Node(
    package='shadowhound_bringup',
    executable='tf_frame_remapper.py',
    name='tf_frame_remapper',
    namespace=robot_namespace,
    parameters=[{
        'robot_namespace': robot_namespace,
    }],
    output='screen',
),
```

### Step 3: Keep Nav2 Config with Namespaced Frames

```yaml
# config/nav2_params_simulation.yaml
local_costmap:
  local_costmap:
    ros__parameters:
      global_frame: robot0/odom        # Now this frame will exist!
      robot_base_frame: robot0/base_link
```

---

## Frame Naming Best Practices

### DO ✅

1. **Use consistent naming across all frames**
   - Either all frames have namespace prefix OR none do
   - Never mix `odom` with `robot0/base_link`

2. **Publish all transforms on global `/tf` topic**
   - Frames themselves are namespaced
   - Topic is global (no `/robot0/tf`)

3. **Set TF publisher node name for debugging**
   - Use `tf_prefix` or set node name clearly
   - Helps with `tf2_monitor` output

4. **Document frame tree in URDF/SDF**
   - Makes expected structure clear
   - robot_state_publisher can validate

### DON'T ❌

1. **Don't publish frames on namespaced TF topics**
   - `/robot0/tf` is an anti-pattern for namespaced frames
   - Use global `/tf` with namespaced frame IDs

2. **Don't mix naming conventions**
   - Current issue: `odom` → `robot0/base_link`
   - Pick one pattern and stick to it

3. **Don't hardcode frame names in drivers**
   - Use parameters for namespace
   - Enable multi-robot use

4. **Don't skip TF publisher node names**
   - Makes debugging much harder
   - `<no authority available>` is not helpful

---

## Validation Commands

### Check Current Frame Tree
```bash
ros2 run tf2_ros tf2_monitor
```

### Check Specific Transform
```bash
ros2 run tf2_ros tf2_echo robot0/base_link robot0/odom
```

### List All TF Topics
```bash
ros2 topic list | grep tf
```

### Check TF Message Content
```bash
ros2 topic echo /tf --once
```

### Verify Nav2 Can Find Frames
```bash
# Should not timeout if frames exist
ros2 topic echo /robot0/local_costmap/costmap --once
```

---

## Related Issues

- **Issue**: Nav2 costmap timeout waiting for transforms
- **Symptom**: `Invalid frame ID "odom" passed to canTransform`
- **Root Cause**: Frame naming inconsistency from Isaac Sim
- **Solution**: TF frame remapper node (Option B above)

---

## Future Work

1. **Upstream Fix**: Submit patch to Isaac Sim extension for consistent frame naming
2. **Multi-Robot Testing**: Test with robot0, robot1 simultaneously
3. **Dynamic Remapping**: Auto-detect and fix frame naming issues
4. **URDF Validation**: Compare actual TF tree against expected URDF structure

---

**Last Updated**: October 26, 2025  
**Status**: Issue identified, workaround solution designed, implementation pending
