---
tags: [project, legacy]
status: draft
related: []
summary: >
  Legacy documentation preserved from earlier phases for review and migration.
---

# Command Mode Conflict Issue

## Purpose
Preserve historical context while signaling that this page requires verification against the current workflow.

## Prerequisites
- Review the legacy notes below to understand original assumptions and instructions.
- Cross-check commands and links with the latest tooling before execution.

## Steps
1. Read through the legacy notes captured under **Legacy Notes** and flag outdated guidance.
2. Update or replace the content with validated procedures as time permits.
3. Record verification outcomes in the validation checklist and mark follow-up tasks in the backlog.

### Legacy Notes
**Date:** October 6, 2025  
**Status:** 🔴 Critical Issue - Needs Investigation  
**Severity:** High - Breaks navigation after skills execution

---

## Problem Statement

After executing WebRTC API skills (sit, stand, etc.) via CLI, **all Nav2 and teleop control stops working**.

### Reproduction Steps

1. Launch `robot.launch.py` from go2_ros2_sdk
2. ✅ **Verify Nav2 works** - Robot responds to Nav2 actions
3. ✅ **Verify teleop works** - `/cmd_vel` commands move the robot
4. Execute WebRTC skill via CLI (e.g., sit, stand)
5. ✅ **Skill executes successfully**
6. ❌ **Nav2 stops working** - No response to Nav2 actions
7. ❌ **Teleop stops working** - `/cmd_vel` commands ignored

### Tested Configurations

- **Repository:** Original go2_ros2_sdk (not dimos-unitree fork)
- **Launch file:** `robot.launch.py`
- **Firmware versions:** Multiple tested (issue persists across versions)
- **Commands tested:** Sit, Stand, and other WebRTC skills

---

## Observations

### What Works BEFORE Skills
- ✅ Nav2 actions execute
- ✅ Teleop (`/cmd_vel`) controls robot
- ✅ All navigation stack functional

### What Works AFTER Skills
- ✅ WebRTC skills execute successfully
- ❌ Nav2 actions ignored
- ❌ Teleop commands ignored
- ❌ Navigation completely broken

### What ALWAYS Works
- ✅ WebRTC skills via CLI (before and after)
- ✅ Robot state messages continue publishing

---

## Hypothesis: Robot Mode/Control Authority Conflict

### Theory 1: Sport Mode Lock
WebRTC API commands might be putting the robot into "Sport Mode" and not releasing control back to SDK:

```
Initial State:
  Robot Mode: SDK Control (Nav2/teleop works)
  
After WebRTC Command:
  Robot Mode: Sport Mode (WebRTC commands work)
  Control Authority: Not returned to SDK
  Result: Nav2/teleop ignored
```

### Theory 2: Command Queue Exclusive Lock
WebRTC commands might acquire exclusive control that isn't released:

```python
# Hypothetical internal state
if webrtc_command_executed:
    control_mode = SPORT_MODE
    # Never switches back to SDK_MODE
```

### Theory 3: Mode Field in go2_states
The `/go2_states` topic has a `mode` field that might indicate control mode:
- `mode = 0`: Unknown/transitioning?
- `mode = 1`: SDK control?
- `mode = 2`: Sport mode?

After WebRTC command, mode might not return to SDK control mode.

### Theory 4: Low-Level API Conflict
The go2_ros2_sdk might be using different API channels:
- **Nav2/teleop:** Uses low-level motion API
- **WebRTC skills:** Uses high-level sport mode API
- **Conflict:** High-level API doesn't release back to low-level

---

## Related Code Locations

### go2_ros2_sdk Structure
```
go2_ros2_sdk/
├── go2_driver_node         # Main driver
├── robot.launch.py          # Launch file used
├── webrtc_bridge           # WebRTC command handler
└── motion_control          # Nav2/teleop handler
```

### Key Topics
- `/webrtc_req` - WebRTC API commands (skills)
- `/cmd_vel` - Teleop velocity commands
- `/go2_states` - Robot state (includes mode field)
- Nav2 action servers - Navigation goals

### State Machine
```
Robot has multiple control modes:
1. SDK Mode - ROS2 controls via cmd_vel, Nav2
2. Sport Mode - WebRTC API controls (skills)
3. Manual Mode - Physical remote control

Question: How does robot know when to switch back to SDK mode?
```

---

## Potential Root Causes

### 1. Missing Mode Switch Command
After WebRTC skill completes, we need to explicitly tell robot to return to SDK mode:

```python
# Pseudo-code
execute_webrtc_skill(skill_id)
wait_for_completion()
# Missing: switch_to_sdk_mode()  ← We might need this!
```

### 2. No Mode Reset in go2_driver_node
The driver might not be monitoring for mode changes or resetting after WebRTC commands.

### 3. Firmware Behavior Change
Robot firmware might have changed behavior where WebRTC commands now "sticky" lock into sport mode.

### 4. Topic Priority Conflict
WebRTC commands might be on a higher priority channel that blocks lower priority Nav2/teleop.

---

## Connection to Queue Hanging Issue

This could be related to our queue hanging problem:

### Scenario 1: Queue Waits for Wrong Completion Signal
```
Command sent → Sport mode activated → Skill executes → Progress 0→1→0
                                                              ↑
                                    But robot STAYS in sport mode!
                                    
Queue thinks: "Command complete" (progress = 0)
Reality: Robot still in sport mode, SDK control not restored
```

### Scenario 2: Queue Should Restore SDK Mode
```python
# Current queue code (simplified)
def execute_command(cmd):
    publish_webrtc_command(cmd)
    wait_for_completion()
    return  # Done?
    
# What we might need:
def execute_command(cmd):
    publish_webrtc_command(cmd)
    wait_for_completion()
    restore_sdk_mode()  # ← Missing step?
    wait_for_mode_switch()
    return
```

---

## Investigation Tasks

### Immediate Checks
1. **Monitor `/go2_states` mode field**
   ```bash
   ros2 topic echo /go2_states | grep mode
   ```
   - Check mode BEFORE WebRTC command
   - Check mode AFTER WebRTC command
   - Check mode AFTER failed Nav2/teleop

2. **Check for mode switch commands**
   ```bash
   ros2 topic list | grep -i mode
   ros2 service list | grep -i mode
   ```
   - Is there a service to switch modes?
   - Is there a topic to request mode change?

3. **Inspect go2_driver_node behavior**
   - Does it listen for mode field changes?
   - Does it have logic to restore SDK mode?
   - What happens when it receives cmd_vel while in sport mode?

4. **Look for API documentation**
   - Unitree SDK docs on mode switching
   - WebRTC API docs on control authority
   - Sport mode entry/exit requirements

### Test Matrix

| Test | Nav2 Before | WebRTC Skill | Nav2 After | Teleop After | Notes |
|------|-------------|--------------|------------|--------------|-------|
| 1    | ✅ Works    | Sit (CLI)    | ❌ Broken  | ❌ Broken    | Confirmed |
| 2    | ✅ Works    | Stand (CLI)  | ❌ Broken  | ❌ Broken    | Confirmed |
| 3    | ✅ Works    | Hello (CLI)  | ?          | ?            | Need to test |
| 4    | ✅ Works    | Sit (Queue)  | ?          | ?            | Need to test |
| 5    | Skip skill  | None         | ✅ Works   | ✅ Works     | Control test |

### Mode Field Analysis Needed

```bash
# Capture mode transitions
ros2 topic echo /go2_states > mode_log.txt

# Then in another terminal:
# 1. Send Nav2 goal (working)
# 2. Execute WebRTC skill
# 3. Try Nav2 goal again (broken)
# 4. Analyze mode_log.txt for mode changes
```

---

## Workarounds to Test

### Workaround 1: Restart Driver
```bash
# After WebRTC skill breaks Nav2
ros2 lifecycle set /go2_driver_node shutdown
ros2 run go2_robot_sdk go2_driver_node
```
Does restarting driver restore Nav2/teleop?

### Workaround 2: Explicit Mode Command
```bash
# Try publishing to potential mode topics
ros2 topic pub /robot_mode std_msgs/UInt8 "data: 1"
```

### Workaround 3: Send "Stop" Command
```bash
# Maybe sending stop clears sport mode?
ros2 topic pub /webrtc_req go2_interfaces/WebRtcReq "{api_id: 1003}"
# Then test Nav2
```

### Workaround 4: Velocity Command Flood
```bash
# Try "waking up" SDK mode with cmd_vel
ros2 topic pub --rate 10 /cmd_vel geometry_msgs/Twist "{}"
```

---

## Impact on Our Work

### Queue Implementation Concerns
Our queue fix might be incomplete if we need to:
1. Restore SDK mode after WebRTC commands
2. Wait for mode switch confirmation
3. Verify Nav2/teleop still works after queue execution

### Web UI Testing Impact
When we test via web UI, we need to verify:
- ✅ Skill executes
- ✅ Skill completes
- ✅ **Nav2 still works after** ← NEW requirement!
- ✅ **Teleop still works after** ← NEW requirement!

### Mission Planning Impact
If this issue exists, we can't safely mix:
- WebRTC skills (sit, stand, hello)
- Nav2 navigation (goto waypoint)
- Direct teleop

Mission like "go to kitchen, then sit" would break after the sit command.

---

## Questions to Answer

1. **What is the mode field in `/go2_states`?**
   - What values are valid?
   - What does each value mean?
   - Does it change after WebRTC commands?

2. **Is there a mode switch service/topic?**
   - How does robot know to return to SDK control?
   - Is it automatic or manual?
   - Does it have a timeout?

3. **Does dimos-unitree have the same issue?**
   - We've been testing in go2_ros2_sdk
   - Does the fork handle this differently?
   - Is this why DimOS exists - to manage modes?

4. **What does go2_driver_node do internally?**
   - Does it switch modes automatically?
   - Does it queue WebRTC commands differently?
   - Is there mode management logic we're missing?

5. **Is this a firmware regression?**
   - You tested multiple firmware versions
   - Did any version NOT have this issue?
   - When did it start appearing?

---

## Next Steps

### Priority 1: Understand the Mode System
1. Monitor `/go2_states` mode field during issue reproduction
2. Search go2_ros2_sdk code for "mode" handling
3. Check Unitree SDK documentation for mode switching
4. Look for mode-related services/topics

### Priority 2: Find Mode Restore Mechanism
1. Identify how to programmatically switch back to SDK mode
2. Test if explicit mode switch fixes Nav2/teleop
3. Determine if this should be in queue or driver

### Priority 3: Update Queue Fix
If mode switching is required:
```python
def execute_command(cmd):
    publish_webrtc_command(cmd)
    wait_for_completion()
    restore_sdk_mode()  # Add this
    wait_for_mode_ready()  # And this
    return
```

### Priority 4: Document Mode State Machine
Create clear documentation of:
- All robot modes
- How to switch between them
- When switches happen automatically vs manually
- Requirements for each mode

---

## Related Files to Investigate

```
go2_ros2_sdk/
├── go2_robot_sdk/
│   ├── go2_driver_node.py         # Main driver - mode logic?
│   └── webrtc_handler.py          # WebRTC command handler
├── go2_interfaces/
│   └── msg/Go2State.msg           # Mode field definition
└── launch/
    └── robot.launch.py            # Launch config

dimos-unitree/
├── dimos/robot/unitree/
│   ├── ros_control/
│   │   ├── ros_command_queue.py   # Our queue - needs mode restore?
│   │   └── unitree_ros_control.py # Mode tracking
│   └── unitree_skills.py          # Skills - should restore mode?
```

---

## Speculation: Why This Matters

If WebRTC commands "lock" the robot into sport mode:

1. **Our queue fix is incomplete** - We wait for completion but don't restore control
2. **Web UI will break Nav2** - Every skill breaks navigation
3. **Mission planning is impossible** - Can't chain navigation + skills
4. **This might be THE issue** - Maybe queue hangs because robot is stuck in wrong mode?

**Alternative theory:** Maybe the queue hangs BECAUSE it's trying to wait for robot to return to SDK mode, which never happens?

---

**Status:** Critical issue discovered. Nav2/teleop breaks after WebRTC skills. Need to investigate mode switching mechanism and update queue implementation if mode restore is required. This could be the missing piece of our queue hanging puzzle. 🔴


## Validation
- [ ] Legacy guidance reviewed for accuracy and converted to the new workflow where applicable.
- [ ] Links updated to use vault-friendly wikilinks or confirmed for external references.
- [ ] Outstanding migration work captured as tasks in the backlog.

## References
- [Knowledge Base Index](../history/history_hub.md)
