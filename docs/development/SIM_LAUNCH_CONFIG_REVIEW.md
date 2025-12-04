# Isaac Sim Launch Configuration Review

**Date**: November 10, 2025  
**Context**: Review go2_omniverse launch configuration for ShadowHound integration  
**PR**: go2_omniverse #6 (namespaced TF support)

---

## Executive Summary

The go2_omniverse Isaac Sim bridge requires specific launch arguments to align with ShadowHound's namespaced architecture. **Critical finding**: The sim uses prefixed frame IDs (`robot0/odom`) even with namespaced topics, requiring either sim changes OR param file adjustments.

---

## Current Sim Launch Pattern

### Default Launch (run_sim.sh)
```bash
#!/bin/bash
source /opt/ros/${ROS_DISTRO}/setup.bash
cd IsaacSim-ros_workspaces/${ROS_DISTRO}_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build
source install/setup.bash
cd ../..
cd go2_omniverse_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build
source install/setup.bash
cd ..

eval "$(conda shell.bash hook)"
conda activate env_isaaclab
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6

# Run the Python script
python main.py --robot_amount 1 --robot go2 --device cuda --enable_cameras
```

### Key CLI Arguments (omniverse_sim.py)

| Argument | Type | Default | Description | ShadowHound Needs |
|----------|------|---------|-------------|-------------------|
| `--robot_amount` | int | 1 | Number of robot instances | `1` |
| `--robot` | str | "go2" | Robot type (go2/g1) | `"go2"` |
| `--robot_namespace` | str | "" | Custom namespace(s), comma-separated | `"robot0"` or similar |
| `--tf_namespace` | str | "" | TF topic namespace(s) (PR #6) | `"robot0"` (requires PR #6 merge) |
| `--task` | str | "Isaac-Velocity-Rough-Unitree-Go2-v0" | Isaac Lab task | Default OK |
| `--device` | str | N/A | Compute device | `"cuda"` |
| `--enable_cameras` | flag | False | Enable camera stream | Optional |
| `--custom_env` | str | "" | Custom environment (office/warehouse) | "" |
| `--num_envs` | int | 1 | Number of parallel envs | `1` |

---

## PR #6 Analysis: Namespaced TF Support

### What It Does
- Adds `--tf_namespace` CLI argument
- Creates per-robot TF publishers: `/robot0/tf` instead of global `/tf`
- Validation: ensures namespace count matches robot count
- Batches transforms into single `TFMessage` per robot
- **Backward compatible**: empty arg uses global `/tf`

### Current Issues (from PR review)

#### ✅ Issue 1: FIXED by User
**Validation missing for `tf_namespaces` length**
- User manually committed Copilot's suggestion
- Added length check to prevent `IndexError`

#### ⚠️ Issue 2: Documentation Mismatch
**Help text mentions `/tf_static`, but not implemented**

Current help text:
```python
"If empty, publishes to global /tf and /tf_static (default). "
"If set, publishes to /<tf_namespace>/tf and /<tf_namespace>/tf_static."
```

Actual implementation (ros2.py:282):
```python
self.tf_publishers.append(
    self.create_publisher(TFMessage, f"/{ns}/tf", 10)
)
# No /tf_static publisher created!
```

**Recommendation**: Update help text to remove `/tf_static` reference (see PR comment template).

#### 🚨 Issue 3: CRITICAL - Frame IDs Prefixed
**Frames use prefixed IDs even with namespaced topics**

Current behavior (ros2.py:289-291):
```python
odom_trans.header.frame_id = f"{ns}/odom"      # "robot0/odom"
odom_trans.child_frame_id = f"{ns}/base_link"  # "robot0/base_link"
# Published to /robot0/tf
```

Expected for Nav2 namespacing:
```python
odom_trans.header.frame_id = "odom"            # Unprefixed
odom_trans.child_frame_id = "base_link"        # Unprefixed
# Published to /robot0/tf (namespace provides isolation)
```

**Why this matters**:
1. Nav2's `use_namespace=true` expects unprefixed frames
2. Standard ROS2 multi-robot pattern (see Nav2 multi-robot tutorial)
3. Our `nav2_params_namespaced.yaml` uses unprefixed frames:
   ```yaml
   base_frame_id: base_link       # NOT robot0/base_link
   odom_frame_id: odom            # NOT robot0/odom
   ```

**Impact**: Architectural mismatch between sim output and ShadowHound Nav2 stack.

---

## Required Sim Launch Configuration

### Option A: Launch After PR #6 Merges (RECOMMENDED)

**Wait for**: PR #6 with unprefixed frame ID fix

```bash
#!/bin/bash
# Tower sim launch (after PR #6 with frame ID fix)

# Setup ROS2 workspace
source /opt/ros/humble/setup.bash
cd ~/go2_omniverse/IsaacSim-ros_workspaces/humble_ws
colcon build
source install/setup.bash
cd ../..

# Setup go2 interface packages
cd go2_omniverse_ws
colcon build
source install/setup.bash
cd ..

# Activate Isaac Lab environment
eval "$(conda shell.bash hook)"
conda activate env_isaaclab
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6

# Launch sim with namespaced TF
python main.py \
    --robot_amount 1 \
    --robot go2 \
    --robot_namespace robot0 \
    --tf_namespace robot0 \
    --device cuda \
    --enable_cameras
```

**Validates**:
```bash
# Check TF topic structure
ros2 topic list | grep tf
# Expected: /robot0/tf

# Check frame IDs (AFTER fix)
ros2 topic echo /robot0/tf --once
# Expected frames: "odom" → "base_link" (unprefixed)
```

### Option B: Launch Before PR #6 Fix (TEMPORARY)

**Use if**: Testing before frame ID fix merges

```bash
# Same launch script, but adjust Nav2 params to match sim output
```

**AND** modify `nav2_params_namespaced.yaml`:
```yaml
amcl:
  ros__parameters:
    base_frame_id: robot0/base_link    # Prefixed to match sim
    odom_frame_id: robot0/odom
    global_frame_id: robot0/map

local_costmap:
  ros__parameters:
    global_frame: robot0/odom
    robot_base_frame: robot0/base_link
```

**⚠️ WARNING**: This defeats the purpose of our refactor (removed RewrittenYaml complexity).

---

## ROS2 Topics Published by Sim

### After PR #6 with `--tf_namespace robot0`

**Transform Topics**:
- `/robot0/tf` - Namespaced TF transforms (odom→base_link, lidar links)
- `/tf_static` - Global static transforms (URDF links) ⚠️ Still global

**Sensor Topics** (with `--robot_namespace robot0`):
- `/robot0/joint_states` - Joint positions
- `/robot0/odom` - Odometry
- `/robot0/imu` - IMU data
- `/robot0/point_cloud2_L1` - Unitree L1 lidar
- `/robot0/point_cloud2_extra` - Extra lidar
- `/robot0/front_cam/rgb` - Camera image (with `--enable_cameras`)

**Command Topics** (with `--robot_namespace robot0`):
- `/robot0/cmd_vel` - Velocity commands (sim subscribes)

---

## Integration with ShadowHound

### Launch Sequence

1. **Tower (Isaac Sim)**:
   ```bash
   cd ~/go2_omniverse
   ./run_sim_shadowhound.sh  # Custom script using config above
   ```

2. **Laptop (ShadowHound Stack)**:
   ```bash
   cd ~/shadowhound
   ./start.sh --mode sim  # Uses sim_autonomy.launch.py
   ```

### Network Configuration

**Current Setup**:
- Tower: `192.168.10.116` (Jetson Thor)
- Laptop: `192.168.10.167` (Dev machine)
- ROS_DOMAIN_ID: 42

**Requirements**:
- Isaac Sim must run on Tower (GPU needed)
- ROS2 topics cross network via DDS
- CycloneDDS config: `config/cyclonedds_network.xml`

### Config File Selection

Our refactored `sim_autonomy.launch.py` prefers:
```python
# Lines 74-88 in sim_autonomy.launch.py
nav2_params_file = PathJoinSubstitution([
    FindPackageShare('shadowhound_bringup'),
    'config',
    'nav2_params_namespaced.yaml'  # FIRST CHOICE
])

# Fallback if namespaced doesn't exist
nav2_params_file_fallback = PathJoinSubstitution([
    FindPackageShare('shadowhound_bringup'),
    'config',
    'nav2_params_simulation.yaml'  # FALLBACK
])
```

**Critical**: `nav2_params_namespaced.yaml` uses **unprefixed frames** (base_link, odom, map).

---

## Validation Checklist

### Pre-Launch Validation
- [ ] PR #6 merged with frame ID fix
- [ ] Conda environment `env_isaaclab` activated
- [ ] ROS2 workspaces built (`IsaacSim-ros_workspaces/humble_ws`, `go2_omniverse_ws`)
- [ ] Network connectivity: laptop can ping Tower (192.168.10.116)
- [ ] ROS_DOMAIN_ID=42 on both machines

### Post-Launch Validation (Sim Side)
```bash
# On Tower or laptop (if DDS working)
ros2 topic list | grep robot0
# Expected: /robot0/tf, /robot0/odom, /robot0/imu, etc.

ros2 topic echo /robot0/tf --once
# Expected frame IDs: "odom" → "base_link" (NOT robot0/odom)

ros2 topic hz /robot0/tf
# Expected: ~100 Hz (depends on sim rate)
```

### Post-Launch Validation (Nav2 Side)
```bash
# On laptop after launching ShadowHound stack
ros2 topic list | grep robot0
# Expected: /robot0/cmd_vel, /robot0/local_costmap/costmap, etc.

ros2 node list
# Expected: /robot0/amcl, /robot0/controller_server, etc.

ros2 param get /robot0/amcl base_frame_id
# Expected: "base_link" (not "robot0/base_link")

# Check TF tree
ros2 run tf2_tools view_frames
# Expected: robot0/map → robot0/odom → base_link (NO robot0 prefix on base_link)
```

### Runtime Validation
- [ ] AMCL initializes without TF warnings
- [ ] Local costmap shows obstacles (scan observation source active)
- [ ] Global costmap loads map
- [ ] Nav2 can plan paths
- [ ] Robot responds to `/robot0/cmd_vel` from Nav2

---

## Common Issues & Solutions

### Issue: "Frame [robot0/base_link] does not exist"
**Symptom**: AMCL or costmap errors about missing frames  
**Cause**: Nav2 params use unprefixed frames, sim publishes prefixed  
**Solution**: 
- Option A: Wait for PR #6 frame ID fix
- Option B: Temporarily use prefixed frames in `nav2_params_namespaced.yaml`

### Issue: No TF data on /robot0/tf
**Symptom**: `ros2 topic echo /robot0/tf` shows nothing  
**Cause**: Sim not launched with `--tf_namespace`  
**Solution**: Add `--tf_namespace robot0` to launch command

### Issue: Topics on global namespace instead of /robot0
**Symptom**: `/odom` instead of `/robot0/odom`  
**Cause**: Missing `--robot_namespace` argument  
**Solution**: Add `--robot_namespace robot0` to launch command

### Issue: DDS discovery failure across network
**Symptom**: `ros2 topic list` doesn't show sim topics from laptop  
**Cause**: Network/firewall/DDS config  
**Solution**: 
1. Check firewall: `sudo ufw status`
2. Verify ROS_DOMAIN_ID: `echo $ROS_DOMAIN_ID` (should be 42)
3. Test multicast: `ping -c 3 239.255.0.1`
4. Check CycloneDDS config: `export CYCLONEDDS_URI=file:///path/to/config/cyclonedds_network.xml`

---

## Next Steps

### Immediate (Before Sim Testing)
1. ✅ Post PR comment on go2_omniverse #6 (template ready at `/tmp/pr_comment.md`)
2. ⏳ Wait for Copilot AI to fix:
   - `/tf_static` documentation (simple text fix)
   - **CRITICAL**: Frame ID unprefixing when `tf_namespace` is set
3. ✅ Create custom launch script: `~/go2_omniverse/run_sim_shadowhound.sh`

### ✅ PR #6 Status: READY TO TEST

**Copilot has fixed all issues**:
- ✅ Namespaced TF publishers (`/robot0/tf`)
- ✅ Unprefixed frame IDs when using `--tf_namespace` (`odom → base_link`)
- ✅ Backward compatible (prefixed frames on global `/tf` without flag)
- ✅ Documentation updated (README + CLI help)

**Implementation verified**:
- `_get_frame_id()` helper returns unprefixed frames when `tf_namespaces[robot_num]` is set
- Help text correctly documents behavior (no `/tf_static` mention)
- README has clear usage examples

### Testing Plan
1. Checkout PR branch on Tower: `git checkout copilot/add-per-robot-namespaced-tf-support`
2. Launch sim: `python main.py --robot_amount 1 --robot go2 --robot_namespace robot0 --tf_namespace robot0 --device cuda`
3. Verify TF topic: `ros2 topic list | grep /robot0/tf`
4. **Critical test**: `ros2 topic echo /robot0/tf --once` → frames should be `odom` and `base_link` (unprefixed)
5. Launch ShadowHound stack on laptop: `./start.sh --mode sim`
6. Verify Nav2 nodes start without TF errors
7. Check costmap activation

---

## Custom Launch Script Template

```bash
#!/bin/bash
# run_sim_shadowhound.sh
# Launch Isaac Sim for ShadowHound integration

set -e  # Exit on error

# Configuration
ROBOT_TYPE="go2"
ROBOT_AMOUNT=1
ROBOT_NAMESPACE="robot0"
TF_NAMESPACE="robot0"
DEVICE="cuda"

echo "=== ShadowHound Isaac Sim Launch ==="
echo "Robot: ${ROBOT_TYPE}"
echo "Namespace: ${ROBOT_NAMESPACE}"
echo "TF Namespace: ${TF_NAMESPACE}"
echo ""

# Setup ROS2 workspace
echo "Building ROS2 workspace..."
source /opt/ros/humble/setup.bash
cd IsaacSim-ros_workspaces/humble_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build
source install/setup.bash
cd ../..

# Setup go2 interface packages
echo "Building go2 interface packages..."
cd go2_omniverse_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build
source install/setup.bash
cd ..

# Activate Isaac Lab environment
echo "Activating Isaac Lab environment..."
eval "$(conda shell.bash hook)"
conda activate env_isaaclab
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6

echo ""
echo "Launching Isaac Sim..."
echo "Press Ctrl+C to stop"
echo ""

# Launch sim
python main.py \
    --robot_amount ${ROBOT_AMOUNT} \
    --robot ${ROBOT_TYPE} \
    --robot_namespace ${ROBOT_NAMESPACE} \
    --tf_namespace ${TF_NAMESPACE} \
    --device ${DEVICE} \
    --enable_cameras
```

**Installation**:
```bash
# On Tower
cd ~/go2_omniverse
cat > run_sim_shadowhound.sh << 'EOF'
[paste script above]
EOF
chmod +x run_sim_shadowhound.sh
```

---

## References

- **go2_omniverse PR #6**: https://github.com/danmartinez78/go2_omniverse/pull/6
- **Nav2 Multi-Robot Tutorial**: https://navigation.ros.org/tutorials/docs/navigation2_with_multiple_robots.html
- **ShadowHound Launch Refactor**: `docs/development/SIMULATION_BRINGUP_REVIEW.md`
- **Nav2 Params**: `src/shadowhound_bringup/config/nav2_params_namespaced.yaml`
- **Sim Launch File**: `src/shadowhound_bringup/launch/sim_autonomy.launch.py`
