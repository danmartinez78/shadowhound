# Issue: Mock Mode Should Not Depend on Robot Hardware Topics

**Date:** October 12, 2025  
**Status:** Open  
**Priority:** Medium  
**Labels:** bug, mock-mode, ros2, agent

---

## Problem

When running `./start.sh --mock --agent-only`, the mission agent stalls waiting for ROS topics that don't exist:

```
[mission_agent-1] INFO:unitree_hardware_interface_video:ROSVideoProvider initialized
[mission_agent-1] 2025-10-12 12:41:13,181 - dimos.robot.ros_control - INFO - Subscribing to camera/compressed with BEST_EFFORT QoS using message type CompressedImage
[mission_agent-1] 2025-10-12 12:41:13,182 - dimos.robot.ros_control - INFO - Subscribing to go2_states with BEST_EFFORT QoS
```

The agent hangs here indefinitely, waiting for topics that will never be published in mock mode.

---

## Root Cause Analysis

### Current Behavior

The mission agent initializes `UnitreeROSControl` which subscribes to:
1. **`camera/compressed`** - Camera feed from robot
2. **`go2_states`** - Robot state messages

Even in mock mode, these subscriptions are created and the agent waits for them before continuing initialization.

### Why This Is a Problem

1. **Mock mode should be hardware-independent** - Should work for development/testing without any robot hardware
2. **Agent-only mode should not need driver** - `--agent-only` flag implies no driver is running
3. **Camera topic doesn't exist yet** - We don't publish to `camera/compressed` anywhere in our code currently
4. **Blocks testing** - Can't test agent, LLM integration, or embeddings without robot hardware

### Code Locations

**File:** `src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py`
- Lines ~150-180: Robot initialization with `UnitreeROSControl`
- No conditional logic for mock mode

**File:** `src/dimos-unitree/dimos/robot/unitree/unitree_ros_control.py`
- Unconditionally subscribes to topics even when `mock_connection=True`

---

## Expected Behavior

### Mock Mode Behavior

When `MOCK_ROBOT=true` or `--mock` flag is used:

1. **No ROS topic subscriptions** - Don't subscribe to hardware topics
2. **Mock video provider** - Use dummy/test images instead of camera feed
3. **Mock robot state** - Generate fake odometry/state data
4. **Fast initialization** - Agent should start immediately

### Agent-Only Mode

When `--agent-only` flag is used:

1. **No driver dependency** - Don't wait for driver topics
2. **Optional robot connection** - Can run with or without robot
3. **Graceful degradation** - Work with whatever topics are available

---

## Proposed Solutions

### Option 1: Conditional ROS Subscriptions (Recommended)

Modify `UnitreeROSControl` to check mock mode:

```python
# In unitree_ros_control.py
def __init__(self, mock_connection=False, ...):
    self.mock_connection = mock_connection
    
    if not self.mock_connection:
        # Only subscribe to real topics in non-mock mode
        self._setup_ros_subscriptions()
    else:
        # Mock mode: use dummy providers
        self._setup_mock_providers()
```

**Pros:**
- Clean separation of concerns
- Easy to maintain
- Works for both mock and real modes

**Cons:**
- Requires changes to DIMOS (submodule)
- Need to track in development policy

### Option 2: Mock Topic Publishers

Create a mock driver that publishes dummy data:

```bash
# In start.sh --mock mode
ros2 topic pub /camera/compressed sensor_msgs/CompressedImage "{}" &
ros2 topic pub /go2_states ... &
```

**Pros:**
- No code changes needed
- Tests ROS communication path

**Cons:**
- Hacky workaround
- Extra processes to manage
- Still couples mock mode to ROS topics

### Option 3: Timeout-Based Initialization

Make topic subscriptions non-blocking with timeouts:

```python
# Wait for topics with timeout
if not self.mock_connection:
    self._wait_for_topics(timeout=5.0)
else:
    # Mock mode: skip waiting
    pass
```

**Pros:**
- Simple change
- Backwards compatible

**Cons:**
- Still creates subscriptions (unnecessary in mock)
- Adds latency even in mock mode

---

## Recommended Implementation Plan

### Phase 1: Quick Fix (Immediate)

1. Add timeout to topic waiting in mock mode
2. Use dummy video/state providers when topics unavailable
3. Log warnings but continue initialization

**Time:** 1-2 hours  
**Risk:** Low  
**Impact:** Unblocks testing now

### Phase 2: Proper Solution (Follow-up)

1. Refactor `UnitreeROSControl` with conditional subscriptions
2. Create proper mock providers for video/state
3. Add unit tests for mock mode
4. Document mock mode architecture

**Time:** 4-6 hours  
**Risk:** Medium (submodule changes)  
**Impact:** Clean, maintainable solution

---

## Additional Context

### Current Mock Mode Issues

1. **Camera topic:** We log "Subscribing to camera/compressed" but:
   - This topic is never published in our code
   - Go2 SDK might publish it, but we haven't verified
   - Mock mode definitely won't have it

2. **State topics:** We subscribe to `go2_states` which:
   - Comes from go2_robot_sdk driver
   - Only exists when driver is running
   - Not available in `--agent-only` mode

3. **Agent-only semantics:** The `--agent-only` flag should mean:
   - Skip launching driver
   - Work without driver topics
   - Test agent logic in isolation

### Testing Workarounds

Until fixed, test embeddings/LLM without full agent:

```bash
# Use standalone test script
python3 test_embeddings_fix.py

# Or run agent with driver (even in mock)
./start.sh --mock  # Without --agent-only
```

---

## Related Issues

- None yet (first issue for mock mode)

## Related Documentation

- `docs/dimos_development_policy.md` - Submodule modification policy
- `docs/local_ai_implementation_status.md` - Testing strategy
- `.github/copilot-instructions.md` - Development patterns

---

## Acceptance Criteria

- [ ] `./start.sh --mock --agent-only` starts successfully
- [ ] Agent initializes without waiting for hardware topics
- [ ] Mock video provider works (dummy images or test video)
- [ ] Mock robot state provider works (fake odometry)
- [ ] No blocking waits for non-existent topics
- [ ] Tests pass in CI without hardware
- [ ] Documentation updated

---

## Notes

This blocks:
- ✅ Testing local embeddings fix (workaround: use `test_embeddings_fix.py`)
- ✅ Testing LLM integration without hardware
- ✅ CI/CD without robot hardware
- ✅ Development without access to robot

This is a common pattern we should solve properly for long-term maintainability.
