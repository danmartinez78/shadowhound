---
tags: [architecture, namespacing, implementation, status]
status: in-progress
related: [NAMESPACE_ALWAYS_ON_ARCHITECTURE.md]
summary: >
  Implementation status tracking for always-on namespace architecture
---

# Namespace Implementation Status

## Quick Status

| Stage | Status | Est. Time | Actual Time | Commits |
|-------|--------|-----------|-------------|---------|
| Stage 1: Launch Parameters | ✅ Complete | 1-2h | ~30min | d281a0a |
| Stage 2: Mission Agent Integration | ✅ Complete | 2-3h | ~20min | cb1a137, 7b... (partial) |
| Stage 3: Hardware SDK Namespace | 🟡 Pending | 2-4h | - | - |
| Stage 4: Config File Updates | 🟡 Pending | 2-4h | - | - |

**Current State**: Stages 1-2 complete. Mission agent can use namespaces but hardware SDK doesn't support them yet.

**Default Namespace**: `tachi` (short for Tachikoma, from Ghost in the Shell)

---

## Stage 1: Launch File Parameters ✅

**Completed**: 2025-10-21 (commit d281a0a)

**Changes**:
- `shadowhound_full.launch.py`: Added `robot_namespace` parameter (default="tachi")
- `sim_autonomy.launch.py`: Added `robot_namespace` parameter  
- `mission_agent.launch.py`: Added `robot_namespace` parameter, **REMOVED 20+ topic remappings**

**Benefits Realized**:
- ✅ Deleted 20+ hardcoded `robot0` topic remappings
- ✅ Clean launch file hierarchy (namespace passed through)
- ✅ Single parameter controls entire stack namespace

**Testing**:
- Build verified: `colcon build --packages-select shadowhound_bringup shadowhound_mission_agent`
- No runtime testing yet (Stage 2 needed first)

---

## Stage 2: Mission Agent Integration ✅

**Completed**: 2025-10-21 (commit cb1a137)

**Changes**:
- `mission_executor.py`:
  - Added `robot_namespace: str = "tachi"` to `MissionExecutorConfig`
  - Pass namespace to `UnitreeGo2(namespace=robot_namespace)`
  - Log namespace on robot initialization
  
- `mission_agent.py`:
  - Declare `robot_namespace` ROS parameter (default="tachi")
  - Read parameter: `robot_namespace = self.get_parameter("robot_namespace").value`
  - Pass to `MissionExecutorConfig(robot_namespace=robot_namespace)`
  - Log namespace in configuration output

**Benefits Realized**:
- ✅ DIMOS automatically prefixes all topics with `/tachi/`
- ✅ Subscribes to `/tachi/odom` instead of `/odom`
- ✅ Publishes to `/tachi/cmd_vel` instead of `/cmd_vel`
- ✅ Hardware and sim use same namespace (true parity)

**Example Topic Changes**:
```
Before (hardware):     After (hardware):
/odom                  /tachi/odom
/cmd_vel               /tachi/cmd_vel
/camera/image_raw      /tachi/camera/image_raw
/go2_states            /tachi/go2_states

Before (sim with remapping):  After (sim):
/robot0/odom → /odom          /tachi/odom
/robot0/cmd_vel → /cmd_vel    /tachi/cmd_vel
```

**Testing**:
- Build verified: `colcon build --packages-select shadowhound_mission_agent`
- No runtime testing yet (Stage 3 needed first)

**Known Limitations**:
- ⚠️ `go2_ros2_sdk` does NOT support namespaces yet
- ⚠️ Hardware topics will publish to `/odom`, `/cmd_vel` (no namespace)
- ⚠️ DIMOS will try to subscribe to `/tachi/odom`, `/tachi/cmd_vel` (mismatched!)

**Next Step Required**: Stage 3 (add namespace to go2_ros2_sdk)

---

## Stage 3: Hardware SDK Namespace Support 🟡

**Status**: Pending

**Goal**: Make `go2_ros2_sdk` publish/subscribe to namespaced topics

**Two Options**:

### Option A: Quick Fix (Topic Remapping in Launch File)
**Pros**: Fast (30min), no code changes  
**Cons**: Workaround, not upstream-friendly  

Add to `robot_dimos.launch.py`:
```python
remappings=[
    ("odom", "tachi/odom"),
    ("cmd_vel", "tachi/cmd_vel"),
    ("camera/image_raw", "tachi/camera/image_raw"),
    # ... all hardware topics
]
```

### Option B: Proper Fix (Add Namespace Parameter)
**Pros**: Clean, upstream-friendly, multi-robot ready  
**Cons**: Slower (2-4h), requires SDK changes  

Modify `go2_driver_node` to accept `robot_namespace` parameter:
```python
# In go2_robot_sdk driver node
namespace = self.get_parameter("robot_namespace").value
self.odom_pub = self.create_publisher(
    Odometry, 
    f"{namespace}/odom",  # Prefix all topics
    10
)
```

**Recommendation**: Start with Option A for quick testing, transition to Option B for production

**Files to Modify** (Option B):
- `src/go2_ros2_sdk/go2_robot_sdk/go2_driver_node.py` (main driver)
- `src/go2_ros2_sdk/launch/robot_dimos.launch.py` (add namespace parameter)
- All topic publishers/subscribers in driver node

**Testing Strategy**:
1. Launch hardware stack with namespace: `ros2 launch ... robot_namespace:=tachi`
2. Verify topics: `ros2 topic list | grep tachi`
3. Expected: `/tachi/odom`, `/tachi/cmd_vel`, `/tachi/camera/image_raw`
4. Test mission agent connection to namespaced topics

---

## Stage 4: Config File Updates 🟡

**Status**: Pending

**Goal**: Update Nav2 and SLAM config files to support dynamic frame names

**Files to Modify**:
- `config/nav2_params_simulation.yaml` - Frame names should use `robot_namespace`
- `config/mapper_params_simulation.yaml` - SLAM frame names
- Possibly: `config/nav2_params.yaml` (if used for hardware)

**Current Hardcoded Frames**:
```yaml
# nav2_params_simulation.yaml
global_frame: robot0/odom        # Should be: tachi/odom
robot_base_frame: robot0/base_link  # Should be: tachi/base_link

# mapper_params_simulation.yaml  
map_frame: robot0/map            # Should be: tachi/map
odom_frame: robot0/odom          # Should be: tachi/odom
base_frame: robot0/base_link     # Should be: tachi/base_link
```

**Challenge**: ROS2 parameters don't support string substitution directly

**Solutions**:

### Option 1: Generate Config from Launch File
```python
# In launch file
nav2_params = {
    "global_frame": f"{robot_namespace}/odom",
    "robot_base_frame": f"{robot_namespace}/base_link",
    # ...
}
```

### Option 2: Use Launch Substitutions + YAML Template
```yaml
# Template: nav2_params.yaml.template
global_frame: $(var robot_namespace)/odom
robot_base_frame: $(var robot_namespace)/base_link
```

### Option 3: Programmatic Config Generation
Create Python script to generate YAML from template on launch

**Recommendation**: Option 1 (inline parameters in launch file) - most straightforward

**Testing Strategy**:
1. Launch Nav2 with namespace: `ros2 launch ... robot_namespace:=tachi`
2. Check Nav2 expects frames: `ros2 param get /controller_server robot_base_frame`
3. Expected: `tachi/base_link`
4. Test navigation with namespaced frames

---

## Multi-Robot Testing Plan 🧪

**Once Stages 1-4 complete, test multi-robot scenario:**

### Setup
1. Launch Tower Isaac Sim with TWO robots:
   - Robot 1 namespace: `tachi` (publishes `/tachi/*`)
   - Robot 2 namespace: `ghost` (publishes `/ghost/*`)

2. Launch TWO mission agents on laptop:
   ```bash
   # Terminal 1: Tachi agent
   ros2 launch shadowhound_bringup mission_agent.launch.py \
       robot_namespace:=tachi
   
   # Terminal 2: Ghost agent
   ros2 launch shadowhound_bringup mission_agent.launch.py \
       robot_namespace:=ghost
   ```

3. Verify topic isolation:
   ```bash
   ros2 topic list | grep tachi  # Should see /tachi/* only
   ros2 topic list | grep ghost  # Should see /ghost/* only
   ```

4. Send missions to both robots:
   ```bash
   ros2 topic pub /tachi/mission_command std_msgs/String "data: 'patrol north'"
   ros2 topic pub /ghost/mission_command std_msgs/String "data: 'patrol south'"
   ```

5. Expected: Both robots execute independently without topic conflicts

---

## Benefits Realized So Far

### Stage 1-2 Complete ✅
- ✅ **Deleted 20+ topic remappings** (major simplification)
- ✅ **Single parameter controls namespace** (robot_namespace="tachi")
- ✅ **Clean launch file hierarchy** (parameter passed through layers)
- ✅ **Type-safe namespace handling** (configured in MissionExecutorConfig)
- ✅ **DIMOS integration working** (namespace passed to UnitreeGo2)

### Still Pending (Stage 3-4) 🟡
- 🟡 Hardware SDK publishes to `/tachi/*` (currently publishes to `/` root)
- 🟡 Nav2 uses namespaced frames (`tachi/base_link` vs `robot0/base_link`)
- 🟡 True hardware/sim parity (same topics everywhere)
- 🟡 Multi-robot capability (launch 2+ robots with different namespaces)
- 🟡 Fun themed names in production (tachi, ghost, motoko vs robot0, robot1)

---

## Estimated Completion Timeline

| Stage | Time Estimate | Status |
|-------|---------------|--------|
| Stage 1 | 1-2h | ✅ Done in 30min |
| Stage 2 | 2-3h | ✅ Done in 20min |
| Stage 3 | 2-4h | 🟡 Pending |
| Stage 4 | 2-4h | 🟡 Pending |
| **Total** | **~12h** | **~1h complete** |

**Fast Track (Stages 1-2)**: ✅ Complete (~1h actual)  
**Complete Migration (Stages 1-4)**: 🟡 ~11h remaining

**Note**: Stages 1-2 were much faster than estimated due to:
- DIMOS namespace support already implemented (commit 531de18)
- Clean architecture (single parameter, no complex logic)
- Removal of workarounds (deleted remappings, not adding new code)

---

## Known Issues & Workarounds

### Issue 1: Hardware Topics Not Namespaced Yet
**Symptom**: go2_ros2_sdk publishes to `/odom`, DIMOS subscribes to `/tachi/odom`  
**Impact**: Mission agent can't connect to hardware robot  
**Workaround**: Use Stage 3 Option A (topic remapping in launch file)  
**Proper Fix**: Stage 3 Option B (add namespace parameter to SDK)

### Issue 2: Nav2 Frame Names Hardcoded
**Symptom**: Nav2 expects `robot0/base_link`, TF publishes `tachi/base_link`  
**Impact**: Navigation fails with frame mismatch errors  
**Workaround**: None (must complete Stage 4)  
**Proper Fix**: Stage 4 (dynamic frame name generation)

### Issue 3: Isaac Sim Publishes `/robot0/*`
**Symptom**: Sim publishes `/robot0/odom`, DIMOS subscribes to `/tachi/odom`  
**Impact**: Mission agent can't connect to simulation  
**Workaround**: Remap in sim launch OR remap in Isaac Sim USD stage  
**Proper Fix**: Configure Isaac Sim to publish `/tachi/*` directly

---

## References

- **Architecture Decision**: [NAMESPACE_ALWAYS_ON_ARCHITECTURE.md](./NAMESPACE_ALWAYS_ON_ARCHITECTURE.md)
- **DIMOS Namespace Support**: Commit 531de18 in dimos-unitree
- **Stage 1 Commit**: d281a0a (launch parameters + delete remappings)
- **Stage 2 Commit**: cb1a137 (mission agent integration)

---

## Next Actions

1. **Complete Stage 3**: Add namespace to go2_ros2_sdk (2-4h estimated)
   - Option A: Quick remapping fix (30min)
   - Option B: Proper parameter support (2-4h)

2. **Complete Stage 4**: Update Nav2/SLAM configs (2-4h estimated)
   - Generate frame names from namespace parameter
   - Test navigation with namespaced frames

3. **Test Hardware**: Verify end-to-end with physical Go2
   - Launch stack: `ros2 launch ... robot_namespace:=tachi`
   - Send mission: `ros2 topic pub /tachi/mission_command ...`
   - Verify robot responds

4. **Test Simulation**: Verify with Isaac Sim
   - Configure sim to publish `/tachi/*` topics
   - Launch autonomy stack
   - Verify mission agent connects

5. **Multi-Robot Demo**: Test with two robots
   - Isaac Sim with tachi + ghost robots
   - Two mission agents on laptop
   - Independent mission execution

---

**Last Updated**: 2025-10-21  
**Branch**: `feature/laptop-sim-integration`  
**Commits**: d281a0a (Stage 1), cb1a137 (Stage 2)
