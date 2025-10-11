---
tags: [software, autodoc]
status: draft
related: []
summary: >
  Auto-generated reference for shadowhound_bringup.
---

# shadowhound_bringup Package

## Package Metadata

| Field | Details |
|-------|---------|
| Path | `src/shadowhound_bringup` |
| Maintainers | ShadowHound Team <developer@shadowhound.local> |
| Licenses | Apache-2.0 |
| Dependencies | ament_copyright, ament_flake8, ament_pep257, python3-pytest, rclpy, shadowhound_mission_agent |

### Launch Files
- `src/shadowhound_bringup/launch/shadowhound.launch.py`

### Parameter Files
- `src/shadowhound_bringup/config/default.yaml`
  - mission_agent.ros__parameters.agent_backend
  - mission_agent.ros__parameters.use_planning_agent
  - mission_agent.ros__parameters.mock_robot
  - mission_agent.ros__parameters.disable_video_stream
  - mission_agent.ros__parameters.log_level

## Purpose

Launch files and configurations for ShadowHound autonomous robot system

## Prerequisites

- ROS 2 workspace configured per [[../ros2_setup|ROS 2 Workstation Setup]].

## Steps

1. Review package metadata below.
2. Update this doc with manual context as the implementation evolves.
3. Validate launch files and parameter sets using the ROS 2 tooling described here.

## Validation

- [ ] `colcon build --packages-select shadowhound_bringup` succeeds.
- [ ] Unit tests pass for this package.
- [ ] Generated launch files load without runtime errors.

## References

- Source directory: `src/shadowhound_bringup`
- [[shadowhound_bringup_api|API Reference]] (if Python package)
- [[_index|Return to Autodoc Index]]
