---
tags: [architecture, index]
status: active
related: [software/README, hardware/README, integrations/dimos_integration]
aliases: [Architecture Index]
summary: >
  Architecture documentation index covering system design, component relationships, and deployment topology.
---

# Architecture Documentation

System architecture, design decisions, and component relationships.

## Overview

This directory contains high-level architecture documentation for the ShadowHound system.

## Documents

### System Architecture
- [Architecture Clarification](architecture_clarification.md) - Core architectural decisions
- [Architecture Update Summary](arch_update_summary.md) - Recent architectural changes
- [Deployment Topology](deployment_topology.md) - System deployment and network topology

### Component Architecture
- [Camera Architecture](camera_architecture.md) - Vision system design and data flow

## Key Concepts

### System Layers
1. **Application Layer** - Launch files, configurations
2. **Agent Layer** - LLM/VLM orchestration, mission planning
3. **Skills Layer** - Execution engine, safety, telemetry
4. **Robot Layer** - ROS2 bridge to hardware (go2_ros2_sdk)

### Communication Flow
```
User Input → Web UI/CLI → Mission Agent → DIMOS Agent → Skills → Robot Hardware
                                                            ↓
                                                      ROS2 Topics/Services
```

## Related Documentation

- [DIMOS Integration](../integrations/dimos_integration.md) - Framework integration details
- [Agent Architecture](../software/agent/dimos_agent_architecture.md) - Agent system design
- [Software Overview](../software/README.md) - Software stack

## Design Principles

1. **Skills-First**: All robot control through Skills API
2. **Safety-First**: Timeout, validation, error handling in every skill
3. **Container-First**: Development in devcontainer
4. **Type-First**: Type hints, validated inputs, structured results

## See Also
- [[software/software_hub|Software Documentation]] — Software stack and packages
- [[hardware/hardware_hub|Hardware Documentation]] — Hardware components and wiring
- [[../integrations/dimos_integration|DIMOS Integration]] — Framework architecture
- [[index|Documentation Index]] — Complete documentation map

For questions about architecture decisions, see the main [README](../README.md) or create an issue.

