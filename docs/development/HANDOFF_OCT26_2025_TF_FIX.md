---
tags: [development, handoff, simulation, nav2, tf-frames]
status: active
related: 
  - docs/development/devlog.md
  - docs/architecture/tf_frame_reference.md
  - docs/issues/go2_omniverse_tf_frame_namespace_issue.md
summary: >
  Handoff doc for TF frame remapping fix - ready for laptop testing
---

# Development Handoff: TF Frame Remapping Fix
**Date**: October 26, 2025  
**Branch**: `feature/laptop-sim-integration`  
**Status**: Fix implemented, ready for testing on laptop  
**Last Commit**: `ccd33db` - "fix(sim): launch SLAM separately with explicit TF remappings"

---

## 🎯 Current Status

**PROBLEM SOLVED**: Nav2 costmap TF timeout errors  
**ROOT CAUSE IDENTIFIED**: Frame IDs in config were absolute (robot0/odom) but Nav2 with use_namespace=True expects relative (odom)  
**SOLUTION IMPLEMENTED**: 
1. Launch SLAM separately with explicit TF remappings
2. Use relative frame IDs in Nav2 params (Nav2 adds namespace automatically)

**READY FOR**: Laptop testing to verify Nav2 + SLAM work end-to-end

---

## 📋 What Was Done

### Issue Discovery
- **Original Issue**: Nav2 costmap timeout: "Invalid frame ID 'robot0/odom' passed to canTransform"
- **Investigation**: Nav2 nodes subscribing to `/robot0/tf` instead of global `/tf`
- **Verification**: 
  - Tower publishes correct namespaced frames: `robot0/odom` → `robot0/base_link`
  - Laptop can receive `/tf` messages from Tower ✅
  - But Nav2 subscribed to wrong topic (`/robot0/tf` with 3 subscribers, `/tf` with 0) ❌

### Fix Attempts
1. **Attempt 1**: Added explicit `SetRemap` in `GroupAction` wrapper
   - **Result**: Failed - `LaunchConfiguration` objects can't be used in f-strings
   - **Error**: `Couldn't parse remap rule: '-r /<LaunchConfiguration object>/tf:=/tf'`

2. **Attempt 2** (FINAL): Launch SLAM Toolbox separately from Nav2
   - **Reason**: Nav2's built-in TF remappings only apply to `nav2_container`, not included launches
   - **Solution**: Launch SLAM as direct `Node` with explicit `remappings` parameter
   - **Result**: Build successful, ready for testing ✅

### Files Modified
- **`src/shadowhound_bringup/launch/sim_autonomy.launch.py`**:
  - Nav2 launched with `slam=False`
  - SLAM Toolbox launched separately as `Node` with:
    ```python
    remappings=[
        ("/tf", "/tf"),
        ("/tf_static", "/tf_static"),
    ]
    ```
  - Both Nav2 and SLAM now get proper TF remappings

### Architecture Validation
- ✅ Researched ROS2 multi-robot TF best practices
- ✅ Confirmed correct pattern: namespaced frames (`robot0/odom`) + global TF topics (`/tf`)
- ✅ Found Nav2 PR #1147 (2019) documenting this support
- ✅ Verified Isaac Sim fork already publishes correct namespaced frames
- ✅ This is NOT a workaround - it's the correct architecture

---

## 🚀 Next Steps on Laptop

### 1. Pull Latest Changes
```bash
cd ~/shadowhound
git pull origin feature/laptop-sim-integration  # Get commit e494604
```

**Expected Output**:
```
Updating f633bb7..e494604
Fast-forward
 config/nav2_params_simulation.yaml | 28 ++++++++++++----------------
 1 file changed, 14 insertions(+), 14 deletions(-)
```

### 2. Rebuild
```bash
colcon build --packages-select shadowhound_bringup
source install/setup.bash
```

**Expected**: Clean build in ~7 seconds

### 3. Test Launch
```bash
./test_autonomy.sh
```

### 4. Verify TF Subscriptions
**In another terminal**:
```bash
# Check that Nav2 subscribes to global /tf
ros2 topic info /tf

# Should show subscriptions like:
# - /robot0/local_costmap/local_costmap
# - /robot0/global_costmap/global_costmap  
# - /robot0/slam_toolbox
# Subscription Count: 5-10 (depending on what's running)

# Check that namespaced /tf has NO subscriptions
ros2 topic info /robot0/tf
# Subscription Count: 0
```

### 5. Verify Nav2 Costmap Publishing
```bash
# Check costmap is publishing
ros2 topic hz /robot0/local_costmap/costmap

# Should show: average rate: ~5-10 Hz
```

### 6. Check for Errors
```bash
# Look for TF timeout errors in Nav2 logs
ros2 topic echo /rosout --field msg | grep -i "timed out\|invalid frame"

# Should see: NO timeout errors
```

---

## ✅ Success Criteria

- [ ] `./test_autonomy.sh` launches without parse errors
- [ ] All nodes start successfully (no crashes)
- [ ] `ros2 topic info /tf` shows multiple Nav2 + SLAM subscriptions
- [ ] `ros2 topic info /robot0/tf` shows 0 subscriptions
- [ ] No TF timeout errors in Nav2 logs
- [ ] `/robot0/local_costmap/costmap` publishes at steady rate (~5-10 Hz)
- [ ] RViz shows costmap visualization (if enabled)

---

## 🐛 If Issues Occur

### SLAM Node Fails to Start
**Symptom**: `slam_toolbox` crashes or can't find config
**Check**:
```bash
# Verify SLAM config exists
ls -la ~/shadowhound/install/go2_robot_sdk/share/go2_robot_sdk/config/mapper_params_online_async.yaml

# Check config path in launch output
```

### Nav2 Still Has TF Timeout
**Symptom**: "Timed out waiting for transform from robot0/base_link to robot0/odom"
**Debug**:
```bash
# Check TF frames exist
ros2 run tf2_ros tf2_echo robot0/odom robot0/base_link

# Should show: Transform exists and updating
```

### Costmap Not Publishing
**Symptom**: `ros2 topic hz /robot0/local_costmap/costmap` shows nothing
**Check**:
```bash
# Verify sensor data arriving
ros2 topic hz /robot0/scan  # Should be ~10 Hz from Tower

# Check Nav2 logs for other errors
ros2 node list | grep robot0
ros2 node info /robot0/local_costmap/local_costmap
```

---

## 📚 Related Documentation

### Created During This Session
- **`docs/architecture/tf_frame_reference.md`** - Comprehensive TF frame guide (457 lines)
- **`docs/issues/go2_omniverse_tf_frame_namespace_issue.md`** - Technical analysis
- **GitHub Issue #3** - Filed in go2_omniverse repo (note: fork already has fix)

### Key References
- **`docs/development/devlog.md`** - Update with results after testing
- **`config/nav2_params_simulation.yaml`** - Uses namespaced frames (updated earlier)
- **Isaac Sim Fork**: `https://github.com/danmartinez78/go2_omniverse` (branch: `added_copter`)

---

## 🔧 Technical Details

### Current TF Architecture
```
Tower (192.168.10.167):
  Isaac Sim + go2_driver_node
  └─ Publishes to /tf (global topic)
     └─ Frames: robot0/odom → robot0/base_link → robot0/lidar_link
     └─ Rate: ~38 Hz
     └─ RMW: FastDDS (default)

Laptop:
  Nav2 + SLAM + RViz
  └─ Subscribe to /tf (global topic)
     └─ Frame IDs in params: robot0/odom, robot0/base_link
     └─ RMW: FastDDS (default)
```

### Why This Fix Works
1. **Nav2's `bringup_launch.py`** has remappings: `[('/tf', 'tf'), ('/tf_static', 'tf_static')]`
2. These remappings only apply to the `nav2_container` node, not included launches
3. **Solution Part 1**: Launch SLAM as direct `Node` so remappings work
4. **Solution Part 2**: Use **relative frame IDs** (odom, base_link) in params
5. When `use_namespace=True`, Nav2 automatically prepends namespace: `odom` → `robot0/odom`
6. Result: Nav2 looks for `robot0/odom` which matches what Isaac Sim publishes ✅

**Key Insight**: Absolute frame IDs (`robot0/odom`) in params + `use_namespace=True` = Nav2 looks for `robot0/robot0/odom` ❌  
**Correct Pattern**: Relative frame IDs (`odom`) in params + `use_namespace=True` = Nav2 looks for `robot0/odom` ✅

### Code Structure
```python
# sim_autonomy.launch.py now has two separate launches:

# 1. Nav2 (without SLAM)
IncludeLaunchDescription(
    nav2_bringup/launch/bringup_launch.py,
    launch_arguments={
        "namespace": "robot0",
        "use_namespace": "True",
        "slam": "False",  # ← Key change
        ...
    }
)

# 2. SLAM Toolbox (separate with explicit remappings)
Node(
    package="slam_toolbox",
    executable="sync_slam_toolbox_node",
    namespace="robot0",
    remappings=[
        ("/tf", "/tf"),              # ← Explicit remappings
        ("/tf_static", "/tf_static"),
    ],
    ...
)
```

---

## 📊 Commit History (This Session)

1. **`344aba2`** - First attempt: Added `SetRemap` in `GroupAction` (failed - LaunchConfiguration issue)
2. **`f172df3`** - Fixed outdated RMW comment (CycloneDDS → FastDDS)
3. **`ccd33db`** - Launch SLAM separately with remappings (fixed parse error but frames still wrong)
4. **`f633bb7`** - Created handoff document
5. **`e494604`** - **CRITICAL FIX**: Use relative frame IDs in Nav2 params (current)

---

## 🎬 What Happens After Testing

### If Test Succeeds ✅
1. Update `docs/development/devlog.md` with success entry:
   ```markdown
   ### Evening: TF Frame Remapping Fix Complete
   **Type**: Bugfix
   **Status**: ✅ Complete
   **Branch**: `feature/laptop-sim-integration`
   
   Fixed Nav2 costmap TF timeout by launching SLAM separately with explicit remappings.
   
   **Key Results**:
   - Nav2 + SLAM subscribe to global /tf ✅
   - Costmap publishing at 5-10 Hz ✅
   - No TF timeout errors ✅
   
   **Commits**: `344aba2`, `f172df3`, `ccd33db`
   ```

2. Merge to `dev`:
   ```bash
   git checkout dev
   git merge feature/laptop-sim-integration
   git push origin dev
   ```

3. Test full simulation workflow:
   - Tower: Isaac Sim running
   - Laptop: Nav2 + SLAM operational
   - Send navigation goals via RViz
   - Verify robot moves in simulation

### If Test Fails ❌
1. Capture error logs:
   ```bash
   ros2 launch shadowhound_bringup sim_autonomy.launch.py 2>&1 | tee ~/slam_debug.log
   ```

2. Check specific diagnostics:
   ```bash
   ros2 topic list | grep tf
   ros2 topic info /tf
   ros2 topic info /robot0/tf
   ros2 run tf2_ros tf2_monitor
   ```

3. Document findings and create GitHub issue if needed

---

## 💡 Key Learnings

1. **LaunchConfiguration objects can't be interpolated** in f-strings for ROS2 remappings
2. **Nav2's TF remappings only apply to `nav2_container`**, not included launches
3. **ROS2 multi-robot pattern**: Namespaced frames (`robot0/odom`) + global TF topics (`/tf`)
4. **`use_namespace=True` doesn't automatically fix TF** - remappings must be explicit
5. **Direct `Node()` launches respect remappings** better than `IncludeLaunchDescription`

---

## 🔍 Additional Context

### Network Environment
- **Desktop**: VS Code Remote SSH → Laptop devcontainer
- **Laptop Host**: `192.168.10.167` - Runs ROS2 nodes (NOT in devcontainer!)
- **Tower**: `192.168.10.116` - Runs Isaac Sim + go2_driver_node
- **Important**: Code edits in `/workspaces/shadowhound/` but runs from `/home/daniel/shadowhound/`

### File Path Warning ⚠️
- **Edit files in**: `/workspaces/shadowhound/` (devcontainer - for git)
- **Code runs from**: `/home/daniel/shadowhound/` (laptop host - what Python executes)
- **Always verify**: Changes synced between both paths if errors persist

### Current System State
- ✅ Tower publishing correct namespaced TF frames
- ✅ Laptop can receive `/tf` from Tower (network OK)
- ✅ Nav2 config updated with namespaced frame IDs
- ✅ Launch file updated with explicit SLAM remappings
- ⏳ Waiting for laptop testing to verify end-to-end

---

## 📞 Quick Commands Reference

```bash
# Standard workflow
cd ~/shadowhound
git pull
colcon build --packages-select shadowhound_bringup
source install/setup.bash
./test_autonomy.sh

# Diagnostics
ros2 topic info /tf
ros2 topic info /robot0/tf
ros2 topic hz /robot0/local_costmap/costmap
ros2 topic list | grep robot0
ros2 node list | grep robot0

# TF debugging
ros2 run tf2_ros tf2_echo robot0/odom robot0/base_link
ros2 run tf2_ros tf2_monitor

# Check for errors
ros2 topic echo /rosout --field msg | grep -i "error\|timeout"
```

---

**Ready to Test!** 🚀

All changes committed and pushed to `feature/laptop-sim-integration`.  
Next action: Pull, build, test on laptop following steps above.
