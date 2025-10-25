---
tags: [development, simulation, handoff, troubleshooting]
status: in-progress
related: [docs/development/devlog.md]
summary: >
  Handoff document for laptop-Tower Isaac Sim integration debugging session.
  Three critical issues fixed: boolean evaluation, RMW mismatch, duplicate RViz nodes.
---

# Laptop Sim Integration Handoff - October 25, 2025

## Current Status: Ready for Testing

**Branch**: `feature/laptop-sim-integration`

**Last Commits**:
- `2a5fa8a` - Fix RViz node name conflict (Tower vs laptop)
- `cc98d6b` - Fix RMW implementation mismatch
- `e08de8e` - Revert CycloneDDS network tuning (wrong fix)

**What's Working**:
- Launch file boolean capitalization fixed (Python `True` vs bash `true`)
- Namespace architecture validated (`/robot0/*` prefix on all Nav2 nodes)
- RMW implementation aligned (both use FastDDS default)
- RViz node names unique (Tower: `/rviz2`, Laptop: `/rviz2_laptop`)

**What Needs Testing**:
- [ ] Pull latest changes on laptop
- [ ] Verify topics stay active when Nav2 launches
- [ ] Confirm costmap publishes correctly
- [ ] Test mission agent launch

---

## Three Critical Fixes Applied

### Fix 1: Python Boolean Evaluation (RESOLVED ✅)

**Problem**: Launch file error `name 'true' is not defined`

**Root Cause**: ROS2 `IfCondition` uses Python's `eval()` which requires `'True'` (capital), not bash-style `'true'`

**Solution Applied** (3 layers):
1. **sim_autonomy.launch.py** - Default values changed to `"True"`
   - Lines 124-133: Boolean argument defaults
   - Lines 217, 222: Nav2 arguments to `'True'`
2. **start.sh** - CLI arguments changed to `True`
   - Lines 1131-1136: Launch command arguments

**Commits**: `6c5ef50`, `18a6a84`, `eaba56f`

---

### Fix 2: RMW Implementation Mismatch (RESOLVED ✅)

**Problem**: Topics visible in `ros2 topic list` but no data received

**Symptoms**:
```bash
ros2 topic list              # Shows /robot0/point_cloud2_L1 ✓
ros2 topic hz /robot0/...    # "WARNING: topic does not appear to be published yet" ✗
```

**Root Cause**: **Different RMW implementations = separate DDS domains**
- Isaac Sim's `go2_driver_node`: Uses **FastDDS** (ROS2 default)
- Laptop nodes: Were forced to **CycloneDDS** by `.env.simulation` and `start.sh`
- Nodes with different RMW implementations **cannot communicate**

**User Discovery**: "I unset the RMW_IMPLEMENTATION env variable...and now hz on the lidar topic works" 🎯

**Solution Applied**:

1. **.env.simulation** (lines 44-51):
```bash
# RMW Implementation - Use default (FastDDS) to match Isaac Sim nodes
# NOTE: Both laptop and Tower must use the SAME RMW implementation
# Isaac Sim nodes use FastDDS by default, so we use that too
# RMW_IMPLEMENTATION=rmw_cyclonedds_cpp  # ← Commented out
```

2. **start.sh** (lines 982-997):
```bash
# RMW Implementation - only set if already configured
if [ -n "${RMW_IMPLEMENTATION:-}" ]; then
    export RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION}
fi
# No longer forces CycloneDDS
```

**Result**: Both Tower and laptop now use **FastDDS** default → communication works

**Commits**: `cc98d6b` (fix), `e08de8e` (revert false lead)

**False Lead Abandoned**: Initially thought network fragmentation was causing drops, created CycloneDDS tuning config. Reverted when real issue (RMW mismatch) was discovered.

---

### Fix 3: Duplicate RViz Node Names (RESOLVED ✅)

**Problem**: Topics die when Nav2 launches, "Publisher already registered" warnings

**Symptoms**:
```bash
ros2 node list
/rviz2    # ← Appears 3 times!
/rviz2
/rviz2
WARNING: Be aware that are nodes in the graph that share an exact name
```

**Root Cause**: 
- Tower: Running RViz as `/rviz2`
- Laptop: Also launching RViz as `/rviz2`
- Duplicate names cause ROS logging conflicts → breaks topic subscriptions

**User Revelation**: "I was running rviz2 on the sim tower" 💡

**Solution Applied**:

**sim_autonomy.launch.py** (line 262):
```python
Node(
    package="rviz2",
    executable="rviz2",
    name="rviz2_laptop",  # ← Changed from "rviz2"
    output="screen",
    arguments=["-d", config.config_paths["rviz"]],
    condition=IfCondition(with_rviz2),
)
```

**Result**: Tower uses `/rviz2`, laptop uses `/rviz2_laptop` → no conflicts

**Commit**: `2a5fa8a`

---

## Testing Instructions

### On Laptop (~/shadowhound)

**Step 1: Pull Latest Changes**
```bash
cd ~/shadowhound
git pull  # Should get commit 2a5fa8a
```

**Step 2: Rebuild**
```bash
colcon build --packages-select shadowhound_bringup
source install/setup.bash
```

**Step 3: Test with Minimal Script**
```bash
./test_autonomy.sh
```

This new script:
- Skips all health checks
- No mission agent
- Just launches Nav2, SLAM, Foxglove, RViz
- Useful for isolating core stack issues

**Step 4: Verify Node Names**
```bash
# In another terminal
ros2 node list | grep rviz

# Expected output:
# /rviz2           ← From Tower
# /rviz2_laptop    ← From laptop
```

**Step 5: Verify Topics Stay Active**
```bash
ros2 topic hz /robot0/point_cloud2_L1
ros2 topic hz /robot0/local_costmap/costmap
ros2 topic hz /robot0/cmd_vel
```

**Expected**: All topics should show consistent Hz rates, not "not published yet"

**Step 6: Check for Warnings**
```bash
# In launch output, should NOT see:
# "Publisher already registered for provided node name"
```

---

## Architecture Reference

### Network Setup
```
Tower (192.168.10.167):
  - Isaac Sim + go2_omniverse
  - go2_driver_node (FastDDS)
  - RViz as /rviz2

Laptop (192.168.10.167):
  - Nav2 + SLAM Toolbox (FastDDS)
  - Mission agent (planned)
  - RViz as /rviz2_laptop
  
Connection: Wired ethernet
ROS_DOMAIN_ID: 0
ROS_LOCALHOST_ONLY: 0
RMW: FastDDS (default)
```

### Namespace Structure
```
/robot0/                    ← Robot namespace
  /cmd_vel                  ← Nav2 output
  /odom                     ← From go2_driver_node
  /point_cloud2_L1          ← LiDAR from Isaac Sim
  /local_costmap/costmap    ← Nav2 costmap
  /global_costmap/costmap
  /scan                     ← From pointcloud_to_laserscan
  /map                      ← From SLAM Toolbox
```

---

## Known Issues & Workarounds

### Issue: Multiple RViz Instances Waste Bandwidth
**Impact**: Both Tower and laptop visualizing same data over network

**Workaround**: Consider running RViz on only ONE machine:
- Option A: Only Tower (best for real-time Isaac Sim viz)
- Option B: Only laptop (best for Nav2 debugging)

**Implementation**: Set `rviz2:=False` in `test_autonomy.sh` or `start.sh`

---

## Original Issue: Costmap Not Publishing

**Status**: Likely resolved by RMW fix, needs verification

**Original Report**: "no costmap is being published"

**Hypothesis**: RMW mismatch was preventing costmap reception from Nav2

**Test After Fixes**:
```bash
ros2 topic hz /robot0/local_costmap/costmap
```

**Expected**: Should show 5-10 Hz rate

**If Still Broken**: Check Nav2 logs for costmap plugin errors

---

## Next Steps After Validation

1. **If Topics Work**: 
   - Enable mission agent in `start.sh`
   - Test DIMOS integration
   - Send navigation goals via mission agent

2. **If Costmap Still Broken**:
   - Check Nav2 parameter files (`config/nav2_params_simulation.yaml`)
   - Verify sensor data reaching Nav2 (obstacles in costmap)
   - Enable Nav2 debug logging

3. **If RViz Conflicts Persist**:
   - Double-check both machines aren't launching multiple RViz instances
   - Verify unique node names in `ros2 node list`

---

## Files Modified This Session

**Launch Files**:
- `src/shadowhound_bringup/launch/sim_autonomy.launch.py`
  - Boolean defaults to `"True"`
  - Nav2 arguments to `'True'`
  - RViz node name to `"rviz2_laptop"`

**Environment**:
- `.env.simulation`
  - RMW_IMPLEMENTATION commented out
- `start.sh`
  - Conditional RMW export
  - Boolean CLI arguments to `True`

**New Scripts**:
- `test_autonomy.sh` - Minimal test launcher (no checks, no agent)

**Reverted**:
- `config/cyclonedds_network.xml` (deleted)
- `scripts/tune_cyclonedds_network.sh` (deleted)

---

## Key Learnings

### ROS2 Multi-Machine Debugging Checklist
1. ✅ **Same RMW implementation** across all nodes
2. ✅ **Unique node names** across machines
3. ✅ **Same ROS_DOMAIN_ID** on both machines
4. ✅ **ROS_LOCALHOST_ONLY=0** for network communication
5. ⚠️ Boolean capitalization in launch files (`'True'` not `'true'`)

### RMW Implementation Critical Rules
- **Default RMW**: FastDDS (if `RMW_IMPLEMENTATION` unset)
- **Alternative**: CycloneDDS (if explicitly set)
- **CANNOT MIX**: Nodes with different RMW cannot communicate
- **Isaac Sim**: Uses FastDDS by default
- **Debugging Symptom**: Topics visible in list but no data

### Node Name Conflicts
- **Duplicate names**: Cause rosout publisher conflicts
- **Symptoms**: "Publisher already registered" warnings
- **Impact**: Breaks topic subscriptions and logging
- **Solution**: Use unique names across machines

---

## Contact & Questions

**Branch**: `feature/laptop-sim-integration`

**Related Docs**:
- `docs/development/devlog.md` - Daily development log
- `docs/development/recent_work.md` - Last 5 days summary
- `docs/troubleshooting/ros2_debugging.md` - ROS2 debugging patterns

**Testing Environment**:
- Tower: Isaac Sim 4.x on Ubuntu 22.04
- Laptop: ROS2 Humble on Ubuntu 22.04
- Network: Wired gigabit ethernet

**Commands for Quick Diagnostics**:
```bash
# Check RMW implementation
echo $RMW_IMPLEMENTATION  # Should be empty (uses FastDDS default)

# Check node names
ros2 node list | sort | uniq -c  # Look for duplicates

# Check topic publishers
ros2 topic info /robot0/point_cloud2_L1

# Check ROS environment
printenv | grep ROS_
```

---

**Status**: Ready for laptop testing. All known issues fixed. Next: Verify costmap and mission agent.

**Last Updated**: October 25, 2025 - Post debugging session
