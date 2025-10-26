# Isaac Sim Namespace Configuration Analysis

**Date**: October 22, 2025  
**Issue**: Simulation currently hardcodes `robot0` namespace, need configurable namespace support  
**Repository**: https://github.com/danmartinez78/go2_omniverse (fork, branch: `added_copter`)  
**Upstream**: https://github.com/abizovnuralem/go2_omniverse

---

## Problem Statement

Currently, Isaac Sim (via go2_omniverse) publishes all ROS2 topics under a hardcoded `/robot0/` namespace:
- `/robot0/odom`
- `/robot0/cmd_vel`
- `/robot0/imu`
- `/robot0/front_cam/rgb`
- etc.

**Goal**: Enable custom namespace (e.g., `tachi`, `ghost`, `motoko`) to match hardware robot names and maintain consistency across hardware/sim/multi-robot scenarios.

---

## Current Architecture

### Launch Flow

```
Tower: ~/workspace/go2_omniverse/
├── run_sim.sh                          # Wrapper script
├── main.py                             # Isaac Sim entry point
├── Isaac_sim/                          # Simulation USD files
├── go2_omniverse_ws/                   # ROS2 workspace (submodule)
│   └── src/
│       └── go2_description/            # URDF, ROS2 nodes
└── IsaacSim-ros_workspaces/            # ROS2 bridge workspace (submodule)
    └── src/
        └── isaac_ros_nitros_bridge/    # ROS2 topic publishers
```

### Current Launch Command

```bash
cd ~/workspace/go2_omniverse
./run_sim.sh

# Internally calls:
conda activate env_isaaclab
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
python main.py --robot go2 --device cuda --enable_cameras
```

### Namespace Handling

**Multi-Robot Mode** (`--robot_amount > 1`):
- Robot 1: `/robot0/*` topics
- Robot 2: `/robot1/*` topics
- Robot 3: `/robot2/*` topics
- etc.

**Single Robot Mode** (`--robot_amount 1` - default):
- Hardcoded: `/robot0/*` topics
- **No way to customize!** ❌

---

## Investigation Required

### Files to Examine (in go2_omniverse repo)

Since this is NOT part of our shadowhound repository, we need to:

1. **Clone and inspect go2_omniverse**:
   ```bash
   git clone --branch added_copter https://github.com/danmartinez78/go2_omniverse /tmp/go2_omniverse
   cd /tmp/go2_omniverse
   ```

2. **Search for namespace/robot0 configuration**:
   ```bash
   # Find where "robot0" is defined
   grep -r "robot0" . --include="*.py" --include="*.yaml" --include="*.xml"
   
   # Find robot namespace configuration
   grep -r "robot_amount\|namespace\|robot.*name" main.py go2_omniverse_ws/ IsaacSim-ros_workspaces/
   ```

3. **Key files to check**:
   - `main.py` - Entry point, argument parsing
   - `go2_omniverse_ws/src/go2_description/launch/*.py` - ROS2 launch files
   - `IsaacSim-ros_workspaces/` - ROS2 bridge configuration
   - Any USD/configuration files defining robot instances

---

## Potential Solutions

### Option 1: Add `--robot_namespace` Parameter to main.py ⭐ RECOMMENDED

**Approach**: Modify `main.py` to accept custom namespace

**Changes Needed**:
1. Add argument parser parameter:
   ```python
   # In main.py
   parser.add_argument(
       "--robot_namespace",
       type=str,
       default="robot0",
       help="ROS2 namespace for robot topics (e.g., tachi, ghost, motoko)"
   )
   ```

2. Pass namespace to ROS2 bridge initialization
3. Update USD scene graph to use custom namespace
4. Modify TF frame names to use namespace prefix

**Pros**:
- ✅ Clean, user-facing parameter
- ✅ Maintains backward compatibility (default="robot0")
- ✅ Works with single-robot and multi-robot modes
- ✅ Aligns with ShadowHound namespace architecture

**Cons**:
- ❌ Requires modifying go2_omniverse code (external repo)
- ❌ Need to maintain fork or submit PR upstream

**Testing**:
```bash
# Custom namespace
python main.py --robot go2 --device cuda --robot_namespace tachi
# Topics: /tachi/odom, /tachi/cmd_vel, etc.

# Hardware-style (no namespace)
python main.py --robot go2 --device cuda --robot_namespace ""
# Topics: /odom, /cmd_vel, etc.

# Multi-robot with custom names
python main.py --robot_amount 3 --device cuda \
    --robot_namespace tachi,ghost,motoko
# Topics: /tachi/*, /ghost/*, /motoko/*
```

---

### Option 2: Environment Variable Configuration

**Approach**: Read namespace from environment variable

**Changes Needed**:
1. Modify main.py or ROS2 bridge to read `ROBOT_NAMESPACE` env var
2. Default to "robot0" if not set

**Usage**:
```bash
export ROBOT_NAMESPACE=tachi
./run_sim.sh
```

**Pros**:
- ✅ Simple implementation
- ✅ No command-line argument changes

**Cons**:
- ❌ Less discoverable (users might not know about it)
- ❌ Still requires code changes to go2_omniverse

---

### Option 3: Post-Launch Topic Remapping (CURRENT WORKAROUND)

**Approach**: Use ROS2 topic remapping on laptop side

**Current Implementation**:
```python
# In mission_agent.launch.py (shadowhound side)
remappings=[
    ("/cmd_vel", "/robot0/cmd_vel"),
    ("/odom", "/robot0/odom"),
    # ... etc
]
```

**Pros**:
- ✅ No changes to go2_omniverse needed
- ✅ Works today

**Cons**:
- ❌ Not clean (adds complexity to mission agent)
- ❌ Duplicates namespace logic (sim AND mission agent both manage namespaces)
- ❌ Doesn't solve multi-robot scenarios
- ❌ Inconsistent with hardware mode (hardware uses DIMOS namespace, sim uses remapping)

**Status**: ⚠️ This is what we're currently using, but should be replaced

---

### Option 4: Fork go2_omniverse and Maintain Custom Branch

**Approach**: Create shadowhound fork of go2_omniverse with namespace support

**Implementation**:
1. Fork: https://github.com/danmartinez78/go2_omniverse
2. Create branch: `feature/configurable-namespace`
3. Implement Option 1 (--robot_namespace parameter)
4. Use our fork in Tower setup scripts

**Pros**:
- ✅ Full control over implementation
- ✅ Can integrate tightly with ShadowHound architecture
- ✅ Can submit PR upstream later

**Cons**:
- ❌ Maintenance burden (keep up with upstream changes)
- ❌ More complexity in setup

**Recommendation**: ⭐ **START WITH THIS** - gives us flexibility while we test

---

## Recommended Implementation Plan

### Phase 1: Investigation (15 minutes)

1. **Clone go2_omniverse** to inspect:
   ```bash
   cd /tmp
   git clone --branch added_copter https://github.com/danmartinez78/go2_omniverse
   cd go2_omniverse
   git submodule update --init --recursive
   ```

2. **Search for namespace configuration**:
   ```bash
   # Find where robot0 is hardcoded
   grep -rn "robot0" . --include="*.py" | grep -v "__pycache__"
   
   # Find ROS2 node initialization
   grep -rn "ros_core\|rclpy\|Node" go2_omniverse_ws/src/ IsaacSim-ros_workspaces/src/
   
   # Find USD scene configuration
   find . -name "*.usd" -o -name "*.usda"
   ```

3. **Document findings**:
   - Where is `robot0` namespace defined?
   - Is it in Python code, USD scene, or launch files?
   - How does multi-robot mode assign namespaces?

---

### Phase 2: Prototype Implementation (1-2 hours)

1. **Create fork**:
   ```bash
   # On GitHub: Fork abizovnuralem/go2_omniverse to danmartinez78/go2_omniverse
   
   # Clone our fork
   git clone https://github.com/danmartinez78/go2_omniverse ~/go2_omniverse_dev
   cd ~/go2_omniverse_dev
   git checkout -b feature/configurable-namespace
   ```

2. **Implement namespace parameter**:
   - Modify `main.py` to accept `--robot_namespace`
   - Update ROS2 node initialization
   - Update TF frame names
   - Test locally

3. **Test on Tower**:
   ```bash
   cd ~/workspace/go2_omniverse
   git remote add shadowhound https://github.com/danmartinez78/go2_omniverse
   git fetch shadowhound
   git checkout shadowhound/feature/configurable-namespace
   
   # Test custom namespace
   python main.py --robot go2 --device cuda --robot_namespace tachi
   
   # Verify topics
   ros2 topic list | grep tachi
   # Expected: /tachi/odom, /tachi/cmd_vel, etc.
   ```

---

### Phase 3: Integration with ShadowHound (30 minutes)

1. **Update Tower setup script** to use our fork:
   ```bash
   # In scripts/sim_and_data_lake_setup.sh
   # Change clone URL to use our fork
   git clone --branch feature/configurable-namespace \
       https://github.com/danmartinez78/go2_omniverse "$ws/go2_omniverse"
   ```

2. **Update run_sim.sh** to accept namespace parameter:
   ```bash
   # Add to run_sim.sh
   ROBOT_NAMESPACE=${ROBOT_NAMESPACE:-tachi}  # Default to tachi
   
   python main.py --robot go2 --device cuda \
       --enable_cameras \
       --robot_namespace "$ROBOT_NAMESPACE"
   ```

3. **Update shadowhound launch** to use custom namespace:
   ```bash
   # On laptop
   ros2 launch shadowhound_bringup shadowhound.launch.py robot_namespace:=tachi
   
   # Topics now match: /tachi/* (both sim and mission agent)
   ```

4. **Remove topic remapping workarounds**:
   - Mission agent already passes namespace to DIMOS ✅
   - DIMOS handles topic namespacing ✅
   - Sim publishes with correct namespace ✅
   - **No remapping needed!** 🎉

---

## Expected Outcomes

### After Implementation

**Simulation with custom namespace**:
```bash
# On Tower
cd ~/workspace/go2_omniverse
ROBOT_NAMESPACE=tachi ./run_sim.sh

# Topics published:
# /tachi/odom
# /tachi/cmd_vel
# /tachi/imu
# /tachi/front_cam/rgb
# etc.
```

**Hardware mode** (unchanged):
```bash
# Robot publishes with namespace from SDK
ros2 launch go2_robot_sdk robot.launch.py robot_namespace:=tachi

# Topics:
# /tachi/odom
# /tachi/cmd_vel
# etc.
```

**Mission agent** (no changes needed):
```bash
# Works with both sim and hardware
ros2 launch shadowhound_bringup shadowhound.launch.py robot_namespace:=tachi

# DIMOS connects to /tachi/* topics automatically
```

**Multi-robot simulation**:
```bash
# On Tower
python main.py --robot_amount 3 --device cuda \
    --robot_namespace tachi,ghost,motoko

# Topics:
# /tachi/*, /ghost/*, /motoko/*
```

---

## Scope Assessment

### Minimal Scope (1-2 hours) ⭐ RECOMMENDED

**What**: Add `--robot_namespace` parameter to main.py

**Files to Modify** (estimated):
1. `main.py` - Add argument parser parameter (~5 lines)
2. ROS2 node initialization - Pass namespace to node (~10 lines)
3. TF frame configuration - Update frame IDs (~20 lines)
4. run_sim.sh - Add namespace environment variable support (~5 lines)

**Total**: ~40 lines of changes across 4 files

**Risk**: Low - parameter-based, backward compatible

**Testing**: 30 minutes on Tower

---

### Medium Scope (2-4 hours)

**Additional**: Support multi-robot custom namespaces

**Files to Modify**:
- Everything in minimal scope
- Multi-robot spawning logic (~30 lines)
- USD scene graph updates (~20 lines)

**Total**: ~90 lines across 6 files

**Risk**: Medium - affects multi-robot mode

---

### Large Scope (4-8 hours)

**Additional**: Full USD scene refactor + comprehensive testing

**Includes**:
- Custom USD scenes with namespace support
- Comprehensive multi-robot testing
- Documentation updates
- Upstream PR preparation

**Risk**: High - complex changes to USD scene graph

---

## Recommendation

**Start with Minimal Scope** (1-2 hours):

1. ✅ Fork go2_omniverse
2. ✅ Add `--robot_namespace` parameter to main.py
3. ✅ Test on Tower with `robot_namespace:=tachi`
4. ✅ Update shadowhound Tower setup to use our fork
5. ✅ Verify end-to-end: sim → laptop → mission agent

**Benefits**:
- Quick win (completes namespace migration fully)
- Low risk (parameter-based, backward compatible)
- Clean architecture (no topic remapping hacks)
- Consistent with hardware mode
- Foundation for multi-robot support later

**Defer to Later**:
- Multi-robot custom namespaces (when we need it)
- USD scene customization (out of scope for MVP)
- Upstream PR (after we validate it works for us)

---

## Next Steps

1. **Investigate**: Clone go2_omniverse and find where `robot0` is defined
2. **Prototype**: Implement `--robot_namespace` parameter in our fork
3. **Test**: Verify on Tower with custom namespace
4. **Integrate**: Update shadowhound setup scripts
5. **Document**: Update Tower quickstart guide
6. **Validate**: End-to-end testing with mission agent

**Estimated Time**: 2-3 hours total

**Priority**: Medium-High (completes namespace migration architecture)

**Blocker**: None (can proceed immediately)

---

## Questions to Answer During Investigation

1. **Where is `robot0` defined?**
   - Python code? (main.py, ROS2 nodes)
   - USD scene file? (Isaac Sim scene graph)
   - Launch file? (ROS2 launch configuration)

2. **How does multi-robot mode assign namespaces?**
   - Loop with index? (`robot0`, `robot1`, `robot2`)
   - Configuration file?
   - USD scene graph?

3. **What components need namespace updates?**
   - ROS2 topic publishers
   - TF frame IDs
   - USD scene graph entity names
   - Launch file parameters

4. **Are there any hardcoded assumptions?**
   - Hardcoded "robot0" strings in launch files
   - TF frame name assumptions
   - Topic name expectations

---

## Success Criteria

✅ **Minimal Success**:
- Simulation publishes topics with custom namespace (e.g., `/tachi/*`)
- Mission agent connects using same namespace
- Hardware mode still works with same namespace
- Backward compatible (default to `robot0` if not specified)

✅ **Full Success**:
- Multi-robot mode supports custom namespace list
- No topic remapping needed in mission agent
- Consistent namespace handling across hardware/sim
- Documentation updated

✅ **Stretch Goals**:
- Upstream PR accepted to go2_omniverse
- Support for empty namespace (hardware-style no prefix)
- Multi-robot coordination examples

---

## Related Documentation

- **Namespace Migration Plan**: `docs/architecture/namespace_migration_plan.md`
- **Stage 3 SDK Complete**: `docs/development/STAGE3_SDK_COMPLETE.md`
- **Stage 2 Already Complete**: `docs/development/STAGE2_ALREADY_COMPLETE.md`
- **Tower Quickstart**: `docs/deployment/tower_go2_isaac_sim_quickstart.md`
- **go2_omniverse repo (our fork)**: https://github.com/danmartinez78/go2_omniverse
- **go2_omniverse upstream**: https://github.com/abizovnuralem/go2_omniverse

---

## Conclusion

Adding custom namespace support to Isaac Sim is:
- ✅ **Feasible** (estimated 1-2 hours minimal scope)
- ✅ **Low risk** (parameter-based, backward compatible)
- ✅ **High value** (completes namespace migration architecture)
- ✅ **Unblocked** (can start immediately)

**Recommendation**: Proceed with investigation and minimal scope implementation.

This completes the namespace migration by ensuring simulation matches hardware/mission-agent architecture (all use configurable `robot_namespace` parameter).
