---
tags: [troubleshooting, nav2, costmap, debugging]
status: active
related: [namespace_architecture_oct21_2025.md]
summary: >
  Guide for debugging costmap timeout issues and investigating redundant nodes
  during system startup in simulation mode.
---

# Costmap Timeout & Redundant Node Debugging

**Date**: October 23, 2025
**Context**: After namespace architecture implementation
**Issues**: 
1. Mission agent crashes before user can verify topic mappings (30s costmap timeout)
2. Potential redundant nodes at system startup

---

## Issue 1: Costmap Timeout Too Short for Debugging

### Problem
Mission agent exits after 30 seconds when `/robot0/local_costmap/costmap` isn't available, giving no time to debug topic mappings or Nav2 configuration.

### Root Cause
DIMOS `topic_latest()` function has hardcoded 30-second timeout:

```python
# src/dimos-unitree/dimos/robot/ros_observable_topic.py:161
def topic_latest(self, topic_name: str, msg_type: TopicType, timeout: float | None = 30.0, qos=QOS.SENSOR):
    """Blocks until first message received, then returns reader()"""
    try:
        first_val = core.pipe(ops.first(), *([ops.timeout(timeout)] if timeout is not None else [])).run()
    except Exception:
        conn.dispose()
        msg = f"{topic_name} message not received after {timeout} seconds. Is robot connected?"
        logger.error(msg)
        raise Exception(msg)  # CRASHES HERE
```

Used by planners in `unitree_go2.py`:

```python
# Line 172: Local planner
local_costmap_topic = f"{self.namespace}/local_costmap/costmap".lstrip("/")
self.local_planner = VFHPurePursuitPlanner(
    get_costmap=self.ros_control.topic_latest(local_costmap_topic, Costmap),
    # ...timeout=30.0 by default
)

# Line 186: Global planner  
map_topic = f"{self.namespace}/map".lstrip("/")
self.global_planner = AstarPlanner(
    get_costmap=self.ros_control.topic_latest(map_topic, Costmap),
    # ...timeout=30.0 by default
)
```

### Solution Options

#### Option A: Temporary Delay (Quick Fix)
Add a sleep before launching mission agent to let Nav2 stabilize:

```bash
# In start.sh, before launching mission agent
if [ "$ROBOT_MODE" = "simulation" ]; then
    print_info "Waiting for Nav2 costmaps to initialize (60s)..."
    sleep 60
fi
```

**Pros**: No code changes, quick to test
**Cons**: Wastes time if Nav2 is fast, doesn't help if Nav2 fails

#### Option B: Wait for Topics (Better)
Check for costmap topics before launching mission agent:

```bash
# In start.sh
wait_for_costmap_topics() {
    local robot_ns="${1:-robot0}"
    local timeout=120  # 2 minutes
    local elapsed=0
    
    print_info "Waiting for Nav2 costmaps to publish..."
    while [ $elapsed -lt $timeout ]; do
        if ros2 topic list 2>/dev/null | grep -q "${robot_ns}/local_costmap/costmap"; then
            print_success "Costmap topics detected"
            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
        print_info "  Waiting... (${elapsed}s/${timeout}s)"
    done
    
    print_error "Costmap topics not found after ${timeout}s"
    print_info "Topics found:"
    ros2 topic list | grep -E "${robot_ns}|costmap"
    return 1
}

# Call before mission agent
if [ "$ROBOT_MODE" = "simulation" ]; then
    wait_for_costmap_topics "$robot_ns" || return 1
fi
```

**Pros**: Responsive, provides debugging output, prevents mission agent crash
**Cons**: Adds complexity to start.sh

#### Option C: DIMOS Submodule Patch (Proper Fix)
Create a patch to make DIMOS timeout configurable:

```bash
# patches/dimos_configurable_costmap_timeout.patch
diff --git a/dimos/robot/unitree/unitree_go2.py b/dimos/robot/unitree/unitree_go2.py
@@ -169,7 +169,7 @@
         local_costmap_topic = f"{self.namespace}/local_costmap/costmap".lstrip("/")
         self.local_planner = VFHPurePursuitPlanner(
-            get_costmap=self.ros_control.topic_latest(local_costmap_topic, Costmap),
+            get_costmap=self.ros_control.topic_latest(local_costmap_topic, Costmap, timeout=120.0),
             transform=self.ros_control,
@@ -184,7 +184,7 @@
         map_topic = f"{self.namespace}/map".lstrip("/")
         self.global_planner = AstarPlanner(
-            get_costmap=self.ros_control.topic_latest(map_topic, Costmap),
+            get_costmap=self.ros_control.topic_latest(map_topic, Costmap, timeout=120.0),
             get_robot_pos=lambda: self.ros_control.transform_euler_pos("base_link", frame_namespace=self.namespace),
```

Apply with:
```bash
cd src/dimos-unitree
git apply ../../patches/dimos_configurable_costmap_timeout.patch
```

**Pros**: Proper fix, increases timeout to 2 minutes
**Cons**: Requires maintaining DIMOS patch

### Recommended Approach
**Option B** (wait for topics) for immediate debugging, then **Option C** (DIMOS patch) for production.

---

## Issue 2: Redundant Nodes at Startup

### Problem
User reports seeing redundant nodes when system starts in simulation mode.

### Potential Causes

#### Cause 1: Multiple Launch File Inclusions
Check if sim_autonomy.launch.py includes Nav2/SLAM multiple times:

```bash
# Check for duplicate includes
grep -n "IncludeLaunchDescription" src/shadowhound_bringup/launch/sim_autonomy.launch.py
```

**Expected**: One Nav2 include, one SLAM include
**If more**: Remove duplicates

#### Cause 2: Old Nodes Still Running
Previous launch not fully cleaned up:

```bash
# Check for zombie nodes
ros2 node list
ps aux | grep -E "(nav2|slam|pointcloud)" | grep -v grep
```

**Solution**: Kill old nodes before relaunch:
```bash
# In start.sh cleanup
pkill -f "nav2_" 2>/dev/null || true
pkill -f "slam_toolbox" 2>/dev/null || true
pkill -f "pointcloud_to_laserscan" 2>/dev/null || true
```

#### Cause 3: Namespace Confusion
Nodes launching in multiple namespaces (e.g., both `/` and `/robot0/`):

```bash
# Check node namespaces
ros2 node list | sort

# Expected (simulation mode):
/robot0/behavior_server
/robot0/bt_navigator
/robot0/controller_server
/robot0/local_costmap/local_costmap
/robot0/global_costmap/global_costmap
/robot0/planner_server
/robot0/pointcloud_to_laserscan
/robot0/slam_toolbox

# NOT expected (indicates misconfiguration):
/behavior_server  # Missing namespace!
/robot0/behavior_server  # Duplicate!
```

#### Cause 4: Isaac Sim Also Publishing
Isaac Sim might be publishing some ROS nodes:

```bash
# Check which machine nodes are running on
ros2 node info /robot0/slam_toolbox | grep "Node name"

# Check if topics come from Tower (Isaac Sim)
ros2 topic info /robot0/odom | grep "Publisher count"
```

### Investigation Steps

1. **Before starting system**, verify clean state:
   ```bash
   ros2 node list  # Should be minimal (just daemon)
   ros2 topic list  # Should show only Isaac Sim topics from Tower
   ```

2. **Start system** with verbose logging:
   ```bash
   ROBOT_MODE=simulation ./start.sh
   ```

3. **Immediately after Nav2 launches**, check nodes:
   ```bash
   ros2 node list | tee /tmp/nodes_after_nav2.txt
   ```

4. **After mission agent launches**, check again:
   ```bash
   ros2 node list | tee /tmp/nodes_after_agent.txt
   ```

5. **Compare**:
   ```bash
   diff /tmp/nodes_after_nav2.txt /tmp/nodes_after_agent.txt
   ```

6. **Check for duplicate namespaces**:
   ```bash
   ros2 node list | grep -v robot0  # Should be empty or minimal
   ros2 node list | grep robot0     # Should show all Nav2 nodes
   ```

### Expected Node List (Simulation Mode)

After complete startup, you should see:

```
/robot0/amcl (if using AMCL)
/robot0/behavior_server
/robot0/bt_navigator
/robot0/controller_server
/robot0/global_costmap/global_costmap
/robot0/local_costmap/local_costmap
/robot0/planner_server
/robot0/pointcloud_to_laserscan
/robot0/slam_toolbox
/robot0/waypoint_follower
/transform_listener_impl_* (TF helpers)
```

**Note**: Some nodes may have child processes (e.g., costmap spawns lifecycle nodes).

### Debugging Commands

```bash
# Count nodes per namespace
ros2 node list | cut -d'/' -f2 | sort | uniq -c

# Find nodes without namespace
ros2 node list | grep -v "^/robot0/" | grep -v "^/transform_"

# Check if any nodes are on wrong machine
for node in $(ros2 node list); do
    echo "=== $node ==="
    ros2 node info "$node" | grep -E "(Node name|Namespace)"
done

# Find duplicate node names
ros2 node list | sort | uniq -d
```

---

## Quick Debugging Workflow

When mission agent times out:

1. **Don't let it crash** - use Option B above to wait for costmaps

2. **While waiting, verify namespacing**:
   ```bash
   # Check nodes
   ros2 node list | grep robot0
   
   # Check topics  
   ros2 topic list | grep robot0
   
   # Verify costmap publishing
   ros2 topic hz /robot0/local_costmap/costmap
   ros2 topic echo /robot0/local_costmap/costmap --once
   ```

3. **Check Nav2 logs**:
   ```bash
   ros2 node list | grep costmap
   ros2 topic info /robot0/local_costmap/costmap
   ```

4. **Verify TF tree**:
   ```bash
   ros2 run tf2_tools view_frames
   # Check for robot0/base_link, robot0/odom frames
   ```

5. **If costmap not publishing**, check:
   - SLAM Toolbox running: `ros2 node list | grep slam`
   - Scan topic available: `ros2 topic hz /robot0/scan`
   - TF frames valid: `ros2 run tf2_ros tf2_echo robot0/odom robot0/base_link`

---

## Next Steps

### For User (Immediate)
1. **Before next test run**, implement Option B (wait_for_costmap_topics function in start.sh)
2. **Run system** and capture node list at each stage
3. **Report findings**: Which nodes appear? Any duplicates? Any unnnamespaced?

### For Agent (Follow-up)
1. Create DIMOS patch (Option C) if timeout continues to be issue
2. Based on user's redundant node findings, update launch files
3. Document expected vs actual node topology

---

## Related Files

**Launch Files**:
- `src/shadowhound_bringup/launch/sim_autonomy.launch.py` - Orchestrates Nav2 + SLAM
- `src/shadowhound_mission_agent/launch/mission_agent.launch.py` - Mission agent startup

**DIMOS Source**:
- `src/dimos-unitree/dimos/robot/unitree/unitree_go2.py` - Planner initialization
- `src/dimos-unitree/dimos/robot/ros_observable_topic.py` - topic_latest timeout

**Start Script**:
- `start.sh` - System orchestration (lines 1200-1250: sim mode launch)

**Documentation**:
- `docs/development/experiments/namespace_architecture_oct21_2025.md` - Namespace implementation
- `docs/simulation/SIM_AUTONOMY_TESTING.md` - Manual simulation testing

---

## Status
- **Costmap Timeout**: 🟡 Pending user feedback on which solution to implement
- **Redundant Nodes**: 🟡 Pending user investigation with node list captures
