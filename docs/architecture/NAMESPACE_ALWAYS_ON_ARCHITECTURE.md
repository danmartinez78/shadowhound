---
tags: [architecture, namespacing, tachi, design-decision]
status: active
related: 
  - namespace_migration_plan.md
  - NAMESPACE_MIGRATION_SUMMARY.md
  - ../development/SESSION_HANDOFF_OCT21_2025.md
summary: >
  Always-on namespace architecture - hardware and sim both use namespaces
---

# Always-On Namespace Architecture

**Decision Date**: October 21, 2025  
**Status**: APPROVED - Ready for Implementation  
**Default Namespace**: `tachi` (short for Tachikoma)

---

## Executive Summary

**Key Decision**: **Always use namespaces**, even on physical hardware.

Instead of switching between namespaced (sim) and non-namespaced (hardware) topics, we use namespaces everywhere:

```
Hardware:    /tachi/cmd_vel, /tachi/odom, /tachi/scan
Simulation:  /tachi/cmd_vel, /tachi/odom, /tachi/scan
Multi-Robot: /tachi/*, /ghost/*, /motoko/*
```

**Why This is Better**:
- ✅ **True hardware/sim parity** - Exact same topics in both modes
- ✅ **Simpler architecture** - No mode-switching logic
- ✅ **Multi-robot ready** - Architecture supports fleet from day one
- ✅ **Cleaner testing** - Bag files work seamlessly
- ✅ **Fun names** - Use themed names instead of robot0/robot1

---

## The Three Architectures Compared

### ❌ Old Architecture (Pre-Migration)
```
Hardware:    /cmd_vel, /odom, /scan         (no namespace)
Simulation:  /robot0/cmd_vel, /robot0/odom  (namespaced)
Problem:     Topic remapping hacks needed!
```

### ⚠️ Original Plan (Mode Switching)
```
Hardware:    /cmd_vel, /odom, /scan         (namespace="")
Simulation:  /robot0/cmd_vel, /robot0/odom  (namespace="robot0")
Problem:     Mode-switching logic, different topics per mode
```

### ✅ **New Plan (Always Namespace)**
```
Hardware:    /tachi/cmd_vel, /tachi/odom    (namespace="tachi")
Simulation:  /tachi/cmd_vel, /tachi/odom    (namespace="tachi")
Benefit:     Same topics everywhere, no mode switching!
```

---

## Default Namespace: `tachi`

**Why "tachi"?**
- Short for "Tachikoma" (Ghost in the Shell reference)
- Short and memorable (5 chars)
- Matches project personality (AI-driven robot)
- More fun than "robot0"

**Alternative Namespaces**:
```bash
# Default
robot_namespace="tachi"

# Multi-robot (themed names)
robot_namespace="tachi"   # First robot
robot_namespace="ghost"   # Second robot
robot_namespace="motoko"  # Third robot

# Or use numbers if preferred
robot_namespace="robot0"
robot_namespace="robot1"
```

---

## Architecture Flow

### Launch Parameter
```python
# shadowhound.launch.py
DeclareLaunchArgument(
    'robot_namespace',
    default_value='tachi',  # Always namespaced!
    description='Robot namespace (e.g., tachi, ghost, motoko, robot0)'
)
```

### Mission Agent
```python
# mission_executor.py
self.declare_parameter('robot_namespace', 'tachi')
robot_namespace = self.get_parameter('robot_namespace').value

# Pass to DIMOS - handles all topic namespacing
self.robot = UnitreeGo2(namespace=robot_namespace)
```

### Hardware SDK Integration
```python
# Option A: go2_ros2_sdk with topic remapping (fast implementation)
Node(
    package='go2_driver',
    executable='go2_driver',
    remappings=[
        ('cmd_vel', 'tachi/cmd_vel'),
        ('odom', 'tachi/odom'),
        # ... remap all topics to tachi/* namespace
    ]
)

# Option B: go2_ros2_sdk with namespace parameter (cleaner, requires PR)
Node(
    package='go2_driver',
    executable='go2_driver',
    parameters=[{'robot_namespace': LaunchConfiguration('robot_namespace')}]
)
```

---

## Benefits Breakdown

### 1. True Hardware/Sim Parity ✨

**Same Topics Everywhere**:
```bash
# Hardware
ros2 topic list
/tachi/cmd_vel
/tachi/odom
/tachi/scan

# Simulation
ros2 topic list
/tachi/cmd_vel
/tachi/odom
/tachi/scan

# Mission agent doesn't know the difference!
```

**Testing Parity**:
```bash
# Record bag from hardware
ros2 bag record -a  # All /tachi/* topics

# Replay bag for testing
ros2 bag play my_test.bag

# Mission agent runs identically against:
# - Live hardware
# - Replayed bag
# - Simulation
```

### 2. Simplified Code Path

**Before (Mode Switching)**:
```python
if mode == "hardware":
    robot_namespace = ""
    topics = ["/cmd_vel", "/odom"]
elif mode == "sim":
    robot_namespace = "robot0"
    topics = ["/robot0/cmd_vel", "/robot0/odom"]
```

**After (Always Namespace)**:
```python
robot_namespace = "tachi"  # Always!
# DIMOS handles all namespacing internally
```

### 3. Multi-Robot Ready 🤖🤖🤖

```bash
# Single robot
./start.sh --namespace tachi

# Multi-robot simulation
./start.sh --sim --namespace tachi &
./start.sh --sim --namespace ghost &
./start.sh --sim --namespace motoko &

# FUTURE: Multi-robot hardware (if you get more Go2s)
./start.sh --namespace tachi &  # First Go2
./start.sh --namespace ghost &  # Second Go2
```

### 4. Network Isolation

```bash
# Multiple developers on same network
Developer 1: --namespace alice_tachi
Developer 2: --namespace bob_tachi
Developer 3: --namespace charlie_tachi

# No topic conflicts!
```

### 5. Fun Factor 😎

```bash
# Instead of boring robot0/robot1
/tachi/cmd_vel
/ghost/cmd_vel
/motoko/cmd_vel

# Much more fun than
/robot0/cmd_vel
/robot1/cmd_vel
/robot2/cmd_vel
```

---

## Migration Stages (Simplified!)

### Stage 0: ✅ COMPLETE - DIMOS Namespace Support
- DIMOS merged namespace support (commit 531de18)
- `UnitreeGo2(namespace="tachi")` ready to use
- No changes needed!

### Stage 1: Launch File Defaults (1-2 hours)
**Goal**: Set `robot_namespace='tachi'` everywhere

**Files to Modify**:
1. `launch/shadowhound_full.launch.py`
   - Add parameter: `robot_namespace` default='tachi'
   - Pass to sim_autonomy.launch.py

2. `src/shadowhound_bringup/launch/sim_autonomy.launch.py`
   - Receive `robot_namespace` from parent
   - Pass to mission_agent.launch.py

3. `src/shadowhound_mission_agent/launch/mission_agent.launch.py`
   - Receive `robot_namespace` from parent
   - Pass to mission_executor node
   - **DELETE** all topic remappings (20+ lines removed!)

### Stage 2: Mission Agent Integration (2-3 hours)
**Goal**: Use namespace parameter in mission executor

**File to Modify**:
- `src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py`
  ```python
  self.declare_parameter('robot_namespace', 'tachi')
  robot_namespace = self.get_parameter('robot_namespace').value
  self.robot = UnitreeGo2(namespace=robot_namespace)
  ```

### Stage 3: Hardware SDK Namespace (2-4 hours)
**Goal**: Make go2_ros2_sdk publish to `/tachi/*` topics

**Option A - Topic Remapping** (Fast):
- Add remappings in hardware bringup launch file
- ~10 lines of code
- Works immediately

**Option B - SDK Namespace Parameter** (Better Long-Term):
- Submit PR to go2_ros2_sdk for namespace support
- Cleaner architecture
- Benefits community

**Recommendation**: Start with Option A, transition to Option B.

### Stage 4: Config File Updates (2-4 hours)
**Goal**: Make Nav2 configs namespace-aware

**Files to Modify**:
- `config/nav2_params_simulation.yaml` - Dynamic frame names
- `config/nav2_params.yaml` - Dynamic frame names

**Complexity**: Medium (config templating needed)

---

## Testing Strategy

### Test 1: Hardware Mode (Regression)
```bash
./start.sh
# Expected topics: /tachi/cmd_vel, /tachi/odom
# Mission should work exactly as before
```

### Test 2: Simulation Mode
```bash
./start.sh --sim
# Isaac Sim: /robot0/cmd_vel → remapped to → /tachi/cmd_vel
# Mission agent connects via namespace="tachi"
```

### Test 3: Custom Namespace
```bash
./start.sh --namespace ghost
# Topics: /ghost/cmd_vel, /ghost/odom
```

### Test 4: Multi-Robot Sim (Future)
```bash
# Terminal 1
./start.sh --sim --namespace tachi

# Terminal 2
./start.sh --sim --namespace ghost

# Verify: No topic conflicts
ros2 topic list | grep -E "(tachi|ghost)"
```

---

## Tradeoffs

### Advantages ✅
- True hardware/sim parity
- Simpler code (no mode switching)
- Multi-robot ready
- Better testing (bags just work)
- More fun (themed names)

### Disadvantages ⚠️
1. **ROS2 Bag Compatibility**:
   - Old bags without namespace won't work directly
   - **Workaround**: Use `--remap` when playing bags
   
2. **Third-Party Tools**:
   - Some tools expect `/cmd_vel` not `/tachi/cmd_vel`
   - **Workaround**: Use `--remap` flag
   - Example: `ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args --remap /cmd_vel:=/tachi/cmd_vel`

3. **Slightly More Typing**:
   - `ros2 topic echo /tachi/cmd_vel` vs `/cmd_vel`
   - **Impact**: Minimal (tab completion helps)

### Verdict
**Advantages vastly outweigh disadvantages.** The architectural simplicity and multi-robot readiness are worth the minor typing inconvenience.

---

## Timeline

**Fast Track** (Stages 1-2): ~5 hours  
**With Hardware SDK** (Stages 1-3): ~8 hours  
**Complete** (Stages 1-4): ~12 hours

**Critical Path**: None! DIMOS already supports namespaces.

---

## Usage Examples

### Launch Commands
```bash
# Default (tachi namespace)
./start.sh

# Simulation
./start.sh --sim

# Custom namespace
./start.sh --namespace ghost

# Multi-robot
./start.sh --sim --namespace tachi &
./start.sh --sim --namespace ghost &
```

### Topic Inspection
```bash
# List all tachi topics
ros2 topic list | grep tachi

# Echo velocity commands
ros2 topic echo /tachi/cmd_vel

# Publish test command
ros2 topic pub /tachi/cmd_vel geometry_msgs/msg/Twist "..."
```

### Bag Files
```bash
# Record mission
ros2 bag record -a -o mission_$(date +%Y%m%d_%H%M%S)

# Replay
ros2 bag play mission_20251021_143000.db3

# Mission agent connects to replayed topics seamlessly!
```

---

## Decision Rationale

### Why Always Namespace?

**Problem**: Original plan had two code paths (hardware vs sim)
```python
if hardware:
    namespace = ""
else:
    namespace = "robot0"
```

**Solution**: One code path everywhere
```python
namespace = "tachi"  # Always!
```

**Result**:
- Eliminates entire dimension of complexity
- One configuration to test
- One deployment path
- One set of topics

### Why "tachi" instead of "robot0"?

**Technical**: Both work equally well  
**UX**: "tachi" is more memorable and fun  
**Flexibility**: Can use themed names (tachi, ghost, motoko) OR numbers (robot0, robot1)

**User's Choice**: Pick what fits your vibe!

---

## Next Steps

1. ✅ Architecture documented
2. ✅ Default namespace chosen (`tachi`)
3. 🚀 **Begin Stage 1 implementation**
   - Add `robot_namespace='tachi'` to launch files
   - Remove topic remapping workarounds
   - Test with hardware and simulation

---

## References

- **Full Migration Plan**: `docs/architecture/namespace_migration_plan.md`
- **Quick Summary**: `docs/architecture/NAMESPACE_MIGRATION_SUMMARY.md`
- **DIMOS Implementation**: Commit `531de18` in dimos-unitree submodule
- **Session Handoff**: `docs/development/SESSION_HANDOFF_OCT21_2025.md`

---

**Created**: 2025-10-21  
**Status**: APPROVED - Ready for Implementation  
**Implementation Branch**: `feature/laptop-sim-integration`
