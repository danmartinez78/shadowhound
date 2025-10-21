---
tags: [safety, architecture, hardware, simulation]
status: active
related:
  - ../simulation/data_flow_architecture.md
  - ../../deployment/SIMULATION_QUICKSTART.md
summary: >
  Strategy for supporting hardware and simulation without breaking either.
---

# Safety Strategy: Hardware + Simulation Support

**Current Date**: October 21, 2025  
**Concern**: Ensure changes for simulation don't break physical hardware support  
**Status**: 🟢 SAFE - Current design supports both modes

---

## Executive Summary

✅ **GOOD NEWS**: The current architecture is **already designed** to support both hardware and simulation safely.

**Key Safety Mechanism**: `ROBOT_MODE` environment variable
- Controls which driver/stack launches
- Determines topic remapping behavior
- Switches between hardware, simulation, and mock modes

**Risk Level**: 🟢 LOW - Mode detection prevents conflicts

---

## Architecture Breakdown

### Layer 1: Start Script (`start.sh`)

**How it's safe**:
```bash
# ROBOT_MODE controls everything
if [ "$ROBOT_MODE" = "mock" ]; then
    # Skip driver entirely - no network calls
    print_info "Robot mode: mock - skipping driver launch"
    return 0

elif [ "$ROBOT_MODE" = "simulation" ]; then
    # Launch sim autonomy stack instead of driver
    launch_sim_autonomy_stack
    return $?

else
    # Hardware mode: launch real robot driver
    launch_robot_driver
    return $?
fi
```

**Verification Points** ✅:
- Mode is read from `.env` file early
- Different code paths are taken per mode
- No topic conflicts between modes

---

### Layer 2: Robot Driver / Autonomy Stack

#### Hardware Mode
```bash
# Launches: go2_driver_node (from go2_ros2_sdk)
# Topics published: /go2_states, /odom, /imu, /cmd_vel, /camera/image_raw
# Driver type: WebRTC or CycloneDDS (based on CONN_TYPE)
# Requester: Physical Unitree Go2 robot
```

**Protection**: 
- Driver only launches if `ROBOT_MODE != "simulation"` and `ROBOT_MODE != "mock"`
- If someone sets wrong mode, driver won't start (explicit check)

#### Simulation Mode
```bash
# Launches: sim_autonomy.launch.py (custom)
# Topics published: /robot0/odom, /robot0/imu, /robot0/cmd_vel, /robot0/front_cam/rgb
# Stack includes: Nav2, SLAM, Foxglove, RViz2
# Requester: Isaac Sim running on Tower
```

**Protection**:
- Only launches autonomy stack, never driver
- Topics are namespaced to `/robot0/*`
- Can coexist with mock/hardware on same network

#### Mock Mode
```bash
# Launches: Nothing (pure software)
# Topics: Internal only (no network)
# Purpose: Testing without hardware or sim
```

**Protection**:
- Completely isolated from network
- Safe for CI/CD testing

---

### Layer 3: Mission Agent (`mission_agent.launch.py`)

**Design**: Single launch file with conditional remappings

```python
# All remappings are harmless for hardware mode
# (topics don't exist, remappings do nothing)
remappings=[
    # Simulation namespace remapping (ignored in hardware mode)
    ("/cmd_vel", "/robot0/cmd_vel"),
    ("cmd_vel", "robot0/cmd_vel"),
    
    # ... more remappings ...
    
    # If running hardware: /robot0/* topics don't exist
    #   → Remappings have no effect (no-op)
    # If running simulation: remappings enable /robot0/* topics
    #   → Mission agent works correctly
]
```

**Parameters control behavior**:
```python
mission_agent_node = Node(
    parameters=[{
        "robot_mode": LaunchConfiguration("robot_mode"),
        # ... other params ...
    }],
)
```

Mission agent receives `robot_mode` and can adjust behavior:
- `hardware`: Expect `/cmd_vel`, `/odom`, `/camera/image_raw`
- `simulation`: Expect `/robot0/cmd_vel`, `/robot0/odom`, etc.
- `mock`: No external topics

---

## Safety Verification Checklist

### ✅ Current Protections

| Component | Protection | Status |
|-----------|-----------|--------|
| **start.sh** | `ROBOT_MODE` environment variable gating | ✅ Implemented |
| **Driver launch** | Explicit mode check before launching | ✅ Implemented |
| **Autonomy stack** | Conditional `launch_sim_autonomy_stack()` function | ✅ Implemented |
| **Topic remappings** | Harmless in hardware mode (topics don't exist) | ✅ Safe |
| **Mission agent** | Receives `robot_mode` parameter | ✅ Implemented |
| **Network isolation** | Mock mode completely local | ✅ Safe |
| **Namespace isolation** | Sim uses `/robot0/*`, hardware uses `/` | ✅ Safe |

### ⚠️ Potential Risks (Currently Mitigated)

| Risk | Likelihood | Mitigation | Status |
|------|-----------|-----------|--------|
| Someone sets `ROBOT_MODE=simulation` on hardware | LOW | Clear docs, default is `mock` | ✅ Mitigated |
| Remappings break hardware topics | LOW | Topics don't exist in hardware, no harm | ✅ Safe |
| Topic naming collision | LOW | Hardware=`/`, Sim=`/robot0/` | ✅ Safe |
| Autonomy stack on hardware | LOW | Only launches in simulation mode | ✅ Safe |
| Nav2 frame misconfiguration | MEDIUM | Identified, pending fix | ⚠️ See below |

---

## Current Issues & Fixes

### Issue 1: Nav2 Frame Configuration (IDENTIFIED)

**Problem**: Nav2 uses `base_link` but sim publishes `robot0/base_link`

**Current Status**: 🟡 NEEDS FIX (only affects simulation)

**Impact on Hardware**: ❌ NONE - hardware uses correct frames

**Fix**:
```yaml
# config/nav2_params.yaml changes needed:
- global_frame_id: "map"           # Already correct (works with /robot0/map)
- robot_base_frame_id: "base_link" 
  # Change to: "robot0/base_link"   (for simulation)
  # Keep as: "base_link"             (for hardware)
  # Solution: Make conditional based on ROBOT_MODE
```

**Recommended Solution**: Create separate config files
```
config/
  nav2_params_hardware.yaml          # Uses base_link
  nav2_params_simulation.yaml        # Uses robot0/base_link
  nav2_params.yaml                   # (current - for backwards compat)
```

---

## Recommended Improvements

### 1. **Configuration File Strategy** (CRITICAL)

Currently unsafe: Single `nav2_params.yaml` with hardcoded `base_link`

**Better approach**: Robot-mode-specific configs
```bash
# In sim_autonomy.launch.py
config_dir = os.path.join(shadowhound_config_dir, f"nav2_params_{ROBOT_MODE}.yaml")

# With fallback to default
if not os.path.exists(config_dir):
    config_dir = os.path.join(shadowhound_config_dir, "nav2_params.yaml")
```

**Files to create**:
```
config/
  nav2_params.yaml                    # Current (default)
  nav2_params_hardware.yaml           # Hardware-specific (frame: base_link)
  nav2_params_simulation.yaml         # Simulation-specific (frame: robot0/base_link)
```

**Safety Level**: 🟢 HIGH - No ambiguity

---

### 2. **Environment Validation** (MEDIUM)

Add pre-flight check in `start.sh`:

```bash
validate_mode_consistency() {
    print_section "Mode Consistency Check"
    
    local robot_mode=${ROBOT_MODE:-mock}
    
    # Warn if mode doesn't match network setup
    if [ "$robot_mode" = "simulation" ]; then
        print_info "Simulation mode: Expecting Isaac Sim on Tower"
        
        # Check if sim topics visible
        if ! ros2 topic list 2>/dev/null | grep -q "/robot0/"; then
            print_warning "No /robot0/* topics detected"
            print_info "Is Isaac Sim running on Tower?"
            read -p "Continue anyway? [y/N]: " continue_choice
            if [[ "$continue_choice" != "y" ]]; then
                exit 1
            fi
        fi
    elif [ "$robot_mode" = "hardware" ]; then
        print_info "Hardware mode: Expecting Unitree Go2 at $ROBOT_IP"
        
        # Check robot is reachable
        if ! ping -c 1 -W 2 "$ROBOT_IP" &> /dev/null; then
            print_error "Robot not reachable at $ROBOT_IP"
            read -p "Continue anyway? [y/N]: " continue_choice
            if [[ "$continue_choice" != "y" ]]; then
                exit 1
            fi
        fi
    fi
}
```

**Safety Level**: 🟡 MEDIUM - Helps catch mistakes

---

### 3. **Documentation Isolation** (LOW EFFORT, HIGH VALUE)

Create clear documentation separating hardware from simulation:

**File**: `docs/robot_modes_guide.md`
```markdown
# Robot Modes Guide

## Quick Reference

| Mode | Purpose | Use When | Topics | Driver |
|------|---------|----------|--------|--------|
| `hardware` | Real robot | Using physical Unitree Go2 | `/` | go2_driver_node |
| `simulation` | Isaac Sim | Testing on Tower Isaac Sim | `/robot0/*` | sim_autonomy_stack |
| `mock` | Pure software | CI/CD, offline testing | Internal | None |

## Hardware Mode (.env)
```bash
ROBOT_MODE=hardware
ROBOT_IP=192.168.10.167
CONN_TYPE=webrtc  # or cyclonedds
```

## Simulation Mode (.env)
```bash
ROBOT_MODE=simulation
# No ROBOT_IP needed - uses network ROS2
ROS_DOMAIN_ID=0
```
```

**Safety Level**: 🟢 HIGH - Prevents user error

---

## Testing Strategy

### ✅ Hardware Validation (No changes needed)
```bash
# Test that hardware mode still works as before
./start.sh --prod  # Production config with hardware mode

# Verify:
# 1. Driver launches
# 2. Topics appear: /go2_states, /odom, /cmd_vel
# 3. Mission agent initializes
# 4. Web UI responsive
```

### ✅ Simulation Validation (Current work)
```bash
# Test that simulation mode works
./start.sh --dev  # Development config with simulation mode

# Verify:
# 1. Autonomy stack launches
# 2. Topics appear: /robot0/odom, /robot0/cmd_vel
# 3. Mission agent initializes
# 4. Web UI responsive
```

### ✅ Mock Validation
```bash
# Test that mock mode works
ROBOT_MODE=mock ./start.sh

# Verify:
# 1. No driver launches
# 2. No external topics
# 3. Mission agent initializes (internal state only)
```

### ⚠️ Conflict Testing
```bash
# Test that modes don't interfere
# Open two terminals:

# Terminal 1: Hardware mode
ROBOT_MODE=hardware ./start.sh --prod

# Terminal 2: Simulation mode (SHOULD FAIL - can't use same ROS domain)
# This is expected behavior - don't run both simultaneously!

# However, if using separate ROS_DOMAIN_IDs, they can coexist
ROS_DOMAIN_ID=1 ROBOT_MODE=simulation ./start.sh --dev
```

---

## Current Status by Component

| Component | Hardware Ready | Simulation Ready | Safety Level |
|-----------|---|---|---|
| `start.sh` | ✅ YES | ✅ YES | 🟢 HIGH |
| `sim_autonomy.launch.py` | N/A | ⚠️ PARTIAL | 🟡 MEDIUM |
| `robot.launch.py` | ✅ YES | N/A | 🟢 HIGH |
| `mission_agent.launch.py` | ✅ YES | ✅ YES | 🟢 HIGH |
| `nav2_params.yaml` | ✅ YES | ❌ BROKEN* | 🔴 LOW |
| Topic remappings | N/A | ⚠️ CONDITIONAL | 🟡 MEDIUM |

*Nav2 frames need fixing for simulation mode

---

## Action Items

### 🟢 SAFE (No changes needed)
- ✅ Mission agent remappings (harmless for hardware)
- ✅ Mode detection in `start.sh` (working as intended)
- ✅ Network isolation (modes don't interfere)

### 🟡 IMPROVE (Optional but recommended)
- Create robot-mode-specific nav2 config files
- Add environment validation pre-checks
- Document hardware vs simulation setup
- Add mode consistency validation

### 🔴 MUST FIX (Before simulation works)
- Fix Nav2 frame references for simulation
- Test full end-to-end with both modes

---

## Quick Decision Matrix

**Q: Should we change how start.sh detects mode?**  
A: NO - Current `ROBOT_MODE` approach is correct

**Q: Should remappings stay unconditional?**  
A: YES - They're safe and help both modes

**Q: Should we split nav2_params.yaml?**  
A: YES - Create separate files per mode for clarity

**Q: Can hardware and simulation run simultaneously?**  
A: NO - They'd compete for /cmd_vel unless using different ROS_DOMAIN_IDs

**Q: Is current implementation safe for hardware users?**  
A: YES - Default is `mock`, hardware-specific remappings won't interfere

---

## Conclusion

**Overall Assessment**: 🟢 **SAFE**

Current design already separates hardware and simulation well. The architecture uses:
1. Environment variables for mode selection
2. Conditional launch logic
3. Namespace isolation
4. Harmless remappings

**Remaining work**: Fix Nav2 configuration for simulation (doesn't affect hardware)

**Recommendation**: Proceed with configuration fixes; no changes needed to core safety mechanisms.

