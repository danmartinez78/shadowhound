---
tags: [architecture, index]
status: active
related: []
aliases: [Architecture Index]
summary: >
  Architecture documentation index covering system design, component relationships, and deployment topology.
---

# Architecture Documentation

System architecture, design decisions, and component relationships.

## Overview

ShadowHound is an autonomous mobile robot system combining ROS2 navigation with LLM/VLM-driven planning. The system architecture is built on four main layers:

### System Architecture

![System Architecture](../_assets/system-architecture.png)
*Figure 1: System Architecture - The layered design from Web UI through Mission Agent, DIMOS Skills Engine, ROS2 Bridge, to the Unitree GO2 hardware.*

### Key Data Flows

![Data Flow Architecture](../_assets/data-flow.png)
*Figure 2: Data Flow - Mission commands flow top-down, telemetry flows bottom-up, camera feeds use WebRTC, and skills execute with feedback loops.*

### Network Topology

![Network Topology](../_assets/network-topology.png)
*Figure 3: Network Topology - Development laptop, Thor (Jetson Orin), and GO2 robot connected via WiFi network with optional direct Ethernet.*

### Documentation Workflow

![Documentation Ecosystem](../_assets/docs-ecosystem.png)
*Figure 4: Documentation Ecosystem - Obsidian vault authoring through automation tools and CI/CD to multiple publication targets.*

## Documents

### System Architecture
- [Architecture Clarification](../architecture/architecture_clarification.md) - Core architectural decisions
- [Architecture Update Summary](../architecture/arch_update_summary.md) - Recent architectural changes
- [Architecture Review Summary](../architecture/architecture_review_summary.md) - October 3 design decisions
- [Deployment Topology](../architecture/deployment_topology.md) - System deployment and network topology

### Component Architecture
- [Camera Architecture](../architecture/camera_architecture.md) - Vision system design and data flow

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
- [Software Overview](../software/software_hub.md) - Software stack

## Design Principles

1. **Skills-First**: All robot control through Skills API
2. **Safety-First**: Timeout, validation, error handling in every skill
3. **Container-First**: Development in devcontainer
4. **Type-First**: Type hints, validated inputs, structured results

## See Also
- [Software Documentation](../software/software_hub.md) — Software stack and packages
- [Hardware Documentation](../hardware/hardware_hub.md) — Hardware components and wiring
- [DIMOS Integration](../integrations/dimos_integration.md) — Framework architecture
- [Documentation Index](../architecture/architecture_hub.md) — Complete documentation map

For questions about architecture decisions, see the main [README](../index.md) or create an issue.

