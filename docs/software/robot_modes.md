---
tags: [software, configuration, simulation]
status: draft
related: [tower_go2_isaac_sim_quickstart.md, mission_agent.md]
summary: >
  Explains the three robot modes (hardware, simulation, mock) and when to use each.
---

# Robot Modes

ShadowHound supports three distinct robot modes to enable development, testing, and deployment across different environments.

## Overview

| Mode | Use Case | Topics | CONN_TYPE | DIMOS Skills | Remapping |
|------|----------|--------|-----------|--------------|-----------|
| `hardware` | Physical Unitree Go2 | Real robot | `webrtc` | ✅ Full | None |
| `simulation` | Isaac Sim testing | Sim topics | `cyclonedds` | ⚠️ Limited | `robot0/*` |
| `mock` | Local development | None | `cyclonedds` | ❌ None | None |

## Mode Details

### Hardware Mode

**When to use:**
- Deploying to physical Unitree Go2 robot
- Testing with real hardware
- Production missions

**Configuration:**
```bash
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    robot_mode:=hardware \
    agent_backend:=openai
```

**Characteristics:**
- Uses WebRTC connection for DIMOS high-level API
- Full access to robot skills (sit, stand, wave, etc.)
- Requires robot on WiFi network
- No topic remapping (standard topic names)
- Topics: `/cmd_vel`, `/odom`, `/imu`, `/camera/image_raw`, etc.

**Environment:**
```bash
export CONN_TYPE=webrtc
export ROBOT_IP=192.168.1.103
```

### Simulation Mode

**When to use:**
- Testing with Isaac Sim on Tower
- Distributed architecture (sim on Tower, agent on laptop)
- Algorithm development with realistic sensor data
- Multi-robot scenarios

**Configuration:**
```bash
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    robot_mode:=simulation \
    agent_backend:=openai
```

**Characteristics:**
- Uses CycloneDDS for ROS2 communication
- Topics from Isaac Sim with `/robot0/` namespace
- Automatic topic remapping handled by launch file
- Limited DIMOS skills (navigation works, high-level API doesn't)
- Good for nav stack, perception, and mission planning testing

**Environment:**
```bash
export CONN_TYPE=cyclonedds
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
```

**Topic Mapping:**
```
Mission Agent → Simulation
/cmd_vel      → /robot0/cmd_vel
/odom         → /robot0/odom
/imu          → /robot0/imu
/camera/image_raw → /robot0/front_cam/rgb
```

**See Also:**
- [Tower Go2 Isaac Sim Quickstart](../deployment/tower_go2_isaac_sim_quickstart.md) - Setting up simulation
- [Laptop-Sim Distributed Workflow](../deployment/laptop_sim_distributed_workflow.md) - Running agent on laptop, sim on Tower

### Mock Mode

**When to use:**
- Pure software development (no hardware/sim needed)
- Testing LLM agent logic
- CI/CD pipelines
- Quick prototyping without external dependencies

**Configuration:**
```bash
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    robot_mode:=mock \
    agent_backend:=openai
```

**Characteristics:**
- No external topic dependencies
- Mission agent starts immediately
- Useful for testing:
  - LLM backends (OpenAI, Ollama)
  - Mission parsing and planning
  - Web interface
  - Semantic memory (RAG)
- DIMOS integration disabled (no robot control)

**Environment:**
```bash
export CONN_TYPE=cyclonedds  # Doesn't matter, no robot connection
```

## Implementation Notes

### Launch File Parameter

The launch file accepts `robot_mode` parameter:

```python
robot_mode_arg = DeclareLaunchArgument(
    "robot_mode",
    default_value="mock",
    description=(
        "Robot mode: 'hardware' (real Unitree Go2), "
        "'simulation' (Isaac Sim with namespace), "
        "'mock' (pure software mock)"
    ),
)
```

### Migration from `mock_robot`

**Old way (deprecated):**
```bash
ros2 launch shadowhound_mission_agent mission_agent.launch.py mock_robot:=true
```

**New way:**
```bash
# Same behavior as mock_robot:=true
ros2 launch shadowhound_mission_agent mission_agent.launch.py robot_mode:=mock

# Real robot (was mock_robot:=false)
ros2 launch shadowhound_mission_agent mission_agent.launch.py robot_mode:=hardware

# New capability: simulation
ros2 launch shadowhound_mission_agent mission_agent.launch.py robot_mode:=simulation
```

### Conditional Remapping

Currently, remappings are always applied but harmless for non-simulation modes (topics don't exist).

Future improvement: Use `LaunchCondition` to only apply remappings when `robot_mode==simulation`.

## Quick Reference

### Start Script Integration

The `start.sh` script can be updated to support robot modes:

```bash
./start.sh --hardware        # Hardware mode
./start.sh --simulation      # Simulation mode (new)
./start.sh --mock           # Mock mode (default)
```

### Environment Variables

| Variable | Hardware | Simulation | Mock |
|----------|----------|------------|------|
| `CONN_TYPE` | webrtc | cyclonedds | cyclonedds |
| `ROBOT_IP` | Required | N/A | N/A |
| `ROS_DOMAIN_ID` | Default | 0 | Any |
| `ROS_LOCALHOST_ONLY` | 0 | 0 | 1 |

### Common Issues

**Problem:** Mission agent hangs in simulation mode
- **Cause:** Trying to use WebRTC connection with sim
- **Fix:** Ensure `CONN_TYPE=cyclonedds` for simulation mode

**Problem:** Topics not found in simulation mode
- **Cause:** Isaac Sim not running or wrong namespace
- **Fix:** Verify `ros2 topic list | grep robot0` shows topics

**Problem:** DIMOS skills not working in simulation mode
- **Cause:** WebRTC API not available with CycloneDDS
- **Fix:** This is expected - use navigation topics instead

## Future Work

### Conditional Remapping (M2)

Make remapping conditional on robot mode:

```python
from launch.conditions import IfCondition
from launch.substitutions import EqualsSubstitution

# Only apply remappings if robot_mode == 'simulation'
condition = IfCondition(
    EqualsSubstitution(LaunchConfiguration("robot_mode"), "simulation")
)
```

### Dynamic Namespace (M2)

Support configurable simulation namespace:

```python
robot_namespace_arg = DeclareLaunchArgument(
    "robot_namespace",
    default_value="robot0",
    description="Namespace for simulation mode (e.g., robot0, robot1)"
)
```

### Auto-detect Mode (M3)

Automatically detect robot mode based on available topics:

```python
# If /robot0/* topics exist → simulation
# If /go2_states exists → hardware
# Else → mock
```

## Related Documentation

- [Mission Agent Launch File](../../src/shadowhound_mission_agent/launch/mission_agent.launch.py)
- [Tower Simulation Setup](../deployment/tower_go2_isaac_sim_quickstart.md)
- [Laptop-Sim Integration](../deployment/laptop_sim_distributed_workflow.md)
- [DIMOS Integration](../integrations/dimos_framework.md)
