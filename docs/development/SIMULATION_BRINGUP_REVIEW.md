# Simulation Bringup Configuration Review

**Date**: November 9, 2025  
**Branch**: feature/laptop-sim-integration  
**Status**: ⚠️ **CRITICAL ISSUES FOUND**

## Executive Summary

The simulation bringup pipeline has **conflicting configurations** between the intended namespaced TF architecture and the actual implementation. The launch file was **NOT actually refactored** as documented.

### Critical Findings

1. ✅ **start.sh**: Properly configured for simulation mode
2. ❌ **sim_autonomy.launch.py**: **STILL USING OLD ARCHITECTURE** (RewrittenYaml + global TF)
3. ✅ **nav2_params_namespaced.yaml**: Created but **NOT BEING USED**
4. ❌ **nav2_params_simulation.yaml**: Old file with prefixed frames (robot0/base_link)
5. ❌ **mapper_params_simulation.yaml**: Uses unprefixed frames but launch remaps to global TF

---

## Detailed Analysis

### 1. Start Script (`start.sh`)

**Status**: ✅ **CORRECT**

The start script properly handles simulation mode:

```bash
# Lines 578-615: Simulation mode detection
if [ "$ROBOT_MODE" = "simulation" ]; then
    launch_sim_autonomy_stack
    return $?
fi
```

Key configurations:
- Uses `ROBOT_NAMESPACE=${ROBOT_NAMESPACE:-robot0}` 
- Launches `sim_autonomy.launch.py` with namespace parameter
- Checks for Isaac Sim topics under `/${robot_ns}/` namespace
- Waits for costmaps before launching mission agent

**No changes needed**.

---

### 2. Launch File (`src/shadowhound_bringup/launch/sim_autonomy.launch.py`)

**Status**: ❌ **CRITICAL - NOT REFACTORED**

**Problem**: Launch file documentation says it was refactored to use namespaced TF, but the actual code **still contains ALL the old RewrittenYaml complexity**.

#### What the code ACTUALLY does (lines 168-244):

```python
def create_navigation_stack(config: SimAutonomyConfig) -> List:
    """
    Pattern: Global TF with namespaced frames  ← OLD PATTERN!
    - TF topics: GLOBAL /tf and /tf_static (forced via GroupAction + SetRemap)
    - Frame IDs: robot0/odom, robot0/base_link (injected via RewrittenYaml)
    """
    
    # 200+ lines of frame_remaps dictionary
    frame_remaps = {
        "amcl.ros__parameters.global_frame_id": [ns, TextSubstitution(text="/map")],
        "amcl.ros__parameters.odom_frame_id": [ns, TextSubstitution(text="/odom")],
        # ... 20+ more rewrites ...
    }
    
    # RewrittenYaml (the thing we wanted to REMOVE!)
    params = RewrittenYaml(
        source_file=config.config_paths["nav2"],
        param_rewrites=frame_remaps,
        convert_types=True,
    )
    
    # GroupAction with global TF remaps (also wanted to REMOVE!)
    nav2_group = GroupAction(
        actions=[
            PushRosNamespace(ns),
            SetRemap("tf", "/tf"),  ← Forces global TF
            SetRemap("tf_static", "/tf_static"),
            nav2_launch,
        ],
    )
```

#### What it's SUPPOSED to do (namespaced architecture):

```python
def create_navigation_stack(config: SimAutonomyConfig) -> List:
    """
    Pattern: Fully namespaced TF
    - TF topics: /robot0/tf and /robot0/tf_static (namespaced)
    - Frame IDs: map, odom, base_link (unprefixed, isolated by namespace)
    """
    
    # NO RewrittenYaml - use nav2_params_namespaced.yaml directly
    # NO frame_remaps dictionary
    # NO global TF remaps
    
    nav2_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource([...]),
        launch_arguments={
            "namespace": ns,
            "use_namespace": "true",  ← KEY: tells Nav2 to use namespaced TF
            "params_file": nav2_namespaced_config,
            "use_sim_time": use_sim_time,
            "autostart": "True",
        }.items(),
    )
    
    # NO GroupAction wrapper needed
    return [nav2_launch, slam_node, slam_lifecycle]
```

#### Config file selection (lines 76-86):

```python
# Prefer simulation-specific nav2 config
nav2_sim_config = os.path.join(
    shadowhound_config_dir, "nav2_params_simulation.yaml"  ← Uses OLD file!
)
nav2_default_config = os.path.join(shadowhound_config_dir, "nav2_params.yaml")

if os.path.exists(nav2_sim_config):
    nav2_config = nav2_sim_config  ← Will always choose this
```

**Problem**: Never checks for `nav2_params_namespaced.yaml`!

---

### 3. Nav2 Params Files

#### `nav2_params_namespaced.yaml`

**Status**: ✅ **CORRECT** (but not being used)

```yaml
# Clean unprefixed frames
amcl:
  ros__parameters:
    base_frame_id: base_link      ← Correct
    odom_frame_id: odom
    global_frame_id: map

local_costmap:
  local_costmap:
    ros__parameters:
      plugins: [obstacle_layer, inflation_layer]  ← Standard layout
      obstacle_layer:
        plugin: nav2_costmap_2d::ObstacleLayer
        observation_sources: scan  ← Simple, direct
```

**This is the file we WANT to use**, but launch file never selects it.

#### `nav2_params_simulation.yaml`

**Status**: ❌ **OLD ARCHITECTURE**

```yaml
# Prefixed frames (conflicts with namespaced approach)
amcl:
  ros__parameters:
    base_frame_id: robot0/base_link   ← Prefixed!
    global_frame_id: robot0/map
    odom_frame_id: robot0/odom

local_costmap:
  local_costmap:
    ros__parameters:
      plugins:
        - voxel_layer     ← Complex nested structure
        - inflation_layer
      voxel_layer:
        plugin: nav2_costmap_2d::VoxelLayer
        observation_sources: pointcloud  ← observation_sources getting lost!
```

**This is the file currently being used** (and it's the wrong one).

---

### 4. Pointcloud to Laserscan Node

**Status**: ⚠️ **MIXED** (lines 126-155)

```python
def create_pointcloud_to_laserscan(config: SimAutonomyConfig) -> Node:
    return Node(
        namespace=config.robot_namespace,  ← Namespaced ✅
        remappings=[
            ("cloud_in", [..., "/point_cloud2_L1"]),
            ("scan", "scan"),
            ("tf", "/tf"),         ← Forces global TF ❌
            ("tf_static", "/tf_static"),  ← Forces global TF ❌
        ],
        parameters=[{
            "target_frame": [ns, "/base_link"],  ← Prefixed frame ❌
        }],
    )
```

**Problem**: Remaps TF to global, uses prefixed target_frame. Should be:

```python
remappings=[
    ("cloud_in", "point_cloud2_L1"),  ← Simple namespace-relative
    ("scan", "scan"),
],
parameters=[{
    "target_frame": "base_link",  ← Unprefixed
}],
```

---

### 5. SLAM Toolbox Config

**Status**: ⚠️ **MIXED**

`mapper_params_simulation.yaml`:
```yaml
slam_toolbox:
  ros__parameters:
    odom_frame: odom        ← Unprefixed ✅
    map_frame: map
    base_frame: base_link
```

Config is correct, but launch file remaps SLAM to global TF (lines 254-262):

```python
slam_node = Node(
    namespace=ns,
    remappings=[
        ("tf", "/tf"),         ← Forces global TF ❌
        ("tf_static", "/tf_static"),
    ],
)
```

---

## Root Cause Analysis

### What went wrong?

1. **Documentation vs Reality Gap**: The refactor was **documented** in experiment doc and devlog, but **never actually implemented** in code.

2. **Build succeeded without code changes**: The build passed because the old code is syntactically valid - it just implements the wrong architecture.

3. **Config file selection logic**: Launch file always prefers `nav2_params_simulation.yaml` (old file with prefixed frames) and never checks for `nav2_params_namespaced.yaml`.

4. **Global TF remaps still present**: All nodes still have `("tf", "/tf")` remaps forcing global TF instead of namespaced.

---

## Required Fixes

### Priority 1: Fix Launch File

**File**: `src/shadowhound_bringup/launch/sim_autonomy.launch.py`

1. **Remove** all RewrittenYaml imports and usage
2. **Remove** all frame_remaps dictionary (200+ lines)
3. **Remove** GroupAction with SetRemap for TF
4. **Remove** PushRosNamespace (use namespace= in IncludeLaunchDescription)
5. **Update** config file selection to prefer `nav2_params_namespaced.yaml`
6. **Add** `use_namespace: "true"` to Nav2 launch arguments
7. **Remove** global TF remaps from pointcloud node
8. **Remove** global TF remaps from SLAM node
9. **Fix** pointcloud target_frame to unprefixed "base_link"

### Priority 2: Update Start Script

**File**: `start.sh`

No changes needed - already correct.

### Priority 3: Deprecate Old Config

**Action**: 
- Rename `nav2_params_simulation.yaml` to `nav2_params_simulation.yaml.old`
- Prevent accidental usage

---

## Expected Behavior After Fix

### TF Tree Structure

```
/robot0/tf:
  - map → robot0_odom (from SLAM)
  - robot0_odom → robot0_base_link (from Isaac Sim)
  - robot0_base_link → robot0_imu_link (from Isaac Sim)
  - robot0_base_link → robot0_UnitreeL1_link (from Isaac Sim)
```

**Key**: All frames are **unprefixed** within the `/robot0` namespace.

### Topic Structure

```
/robot0/scan                    ← From pointcloud_to_laserscan
/robot0/cmd_vel                 ← To Isaac Sim
/robot0/odom                    ← From Isaac Sim
/robot0/local_costmap/costmap   ← From Nav2
/robot0/global_costmap/costmap  ← From Nav2
/robot0/tf                      ← Namespaced TF topic
/robot0/tf_static               ← Namespaced TF static
```

### Parameter Verification

After fix, verify with:

```bash
ros2 param get /robot0/local_costmap local_costmap.obstacle_layer.observation_sources
# Expected: scan

ros2 param get /robot0/local_costmap local_costmap.global_frame
# Expected: odom (NOT robot0/odom)

ros2 param get /robot0/controller_server robot_base_frame
# Expected: base_link (NOT robot0/base_link)
```

---

## Testing Checklist

After implementing fixes:

- [ ] Launch file loads without errors
- [ ] `nav2_params_namespaced.yaml` is selected (check startup logs)
- [ ] No RewrittenYaml warnings in logs
- [ ] `/robot0/tf` topic exists (not `/tf`)
- [ ] Costmap `observation_sources` parameter is `scan`
- [ ] Nav2 costmaps activate without warnings
- [ ] SLAM publishes map → odom transform
- [ ] RViz2 can visualize namespaced TF tree

---

## References

- **Experiment Doc**: `docs/development/experiments/tf_namespaced_nav2_integration_nov09_2025.md`
- **Nav2 Namespacing Guide**: https://navigation.ros.org/tutorials/docs/navigation2_with_multiple_robots.html
- **GitHub Issue**: [go2_omniverse#5](https://github.com/danmartinez78/go2_omniverse/issues/5) (Isaac Sim namespaced TF support)

---

## Conclusion

**The refactor was documented but not implemented.** The launch file still uses the old global TF + prefixed frames architecture that was causing the observation_sources loss.

**Action Required**: Actually implement the refactor by removing RewrittenYaml code and using nav2_params_namespaced.yaml with namespace-based isolation.
