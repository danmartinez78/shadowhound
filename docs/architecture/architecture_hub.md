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
- [[architecture/architecture_clarification|Architecture Clarification]] - Core architectural decisions
- [[architecture/arch_update_summary|Architecture Update Summary]] - Recent architectural changes
- [[architecture/architecture_review_summary|Architecture Review Summary]] - October 3 design decisions
- [[architecture/deployment_topology|Deployment Topology]] - System deployment and network topology

### Component Architecture
- [[architecture/camera_architecture|Camera Architecture]] - Vision system design and data flow

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

- [[integrations/dimos_integration|DIMOS Integration]] - Framework integration details
- [[software/agent/dimos_agent_architecture|Agent Architecture]] - Agent system design
- [[software/software_hub|Software Overview]] - Software stack

## Design Principles

1. **Skills-First**: All robot control through Skills API
2. **Safety-First**: Timeout, validation, error handling in every skill
3. **Container-First**: Development in devcontainer
4. **Type-First**: Type hints, validated inputs, structured results

## See Also
- [[software/software_hub|Software Documentation]] — Software stack and packages
- [[hardware/hardware_hub|Hardware Documentation]] — Hardware components and wiring
- [[../integrations/dimos_integration|DIMOS Integration]] — Framework architecture
- [[architecture/architecture_hub|Documentation Index]] — Complete documentation map

For questions about architecture decisions, see the main [README](../README.md) or create an issue.

