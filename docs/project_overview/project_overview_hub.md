---
tags: [project_overview, index]
status: active
related: []
summary: >
  Central hub for ShadowHound project planning, status tracking, roadmaps, and quick reference guides.
---

# Project Overview

## Purpose
Serve as the primary entry point for understanding ShadowHound's current status, planned milestones, and operational quick-start procedures. This hub connects strategic planning documents with tactical implementation guides.

## Prerequisites
- Familiarity with the ShadowHound mission: autonomous mobile robot combining ROS2 navigation with LLM/VLM-driven task planning
- Access to the repository workspace and development environment
- Understanding of the [System Architecture](../architecture/architecture_hub.md) and [Hardware Platform](../hardware/hardware_hub.md)

## Quick Navigation

### 🚀 Getting Started
- **[Quick Start](../project_overview/quick_start.md)** - One-command launch checklist for rapid bring-up
- **[Quick Reference](../project_overview/quick_reference.md)** - Command cheat sheet and operational shortcuts
- **[Agent Quick Reference](../project_overview/agent_quick_reference.md)** - Agent types and performance characteristics

### 📋 Planning & Status
- **[Project Roadmap](../project_overview/roadmap.md)** - High-level phases and strategic milestones
- **[Project TODO](../project_overview/todo.md)** - Prioritized backlog and task tracking
- **[Setup Status](../project_overview/setup_status.md)** - DIMOS integration milestone (October 4, 2025)
- **[Status 2025-10-12](../project_overview/status_2025-10-12.md)** - Recent documentation reorg and handoff

### 🏗️ Architecture & Context
- **[Architecture Review Summary](../project_overview/architecture_review_summary.md)** - October 3 design decisions and layered architecture

## Current Phase
**Phase 0: Bootstrap & Local LLM Integration**
- Core ROS2 packages scaffolded with DIMOS framework
- vLLM backend integration with local embeddings
- End-to-end testing with Thor (Jetson) deployment

See [Project Roadmap](../project_overview/roadmap.md) for detailed milestone tracking.

## Key Documents by Topic

### Onboarding & Operations
| Document | Purpose | Audience |
|----------|---------|----------|
| [Quick Start](../project_overview/quick_start.md) | Rapid launch checklist using `start.sh` | Operators, new contributors |
| [Quick Reference](../project_overview/quick_reference.md) | Command cheat sheet and environment presets | Maintainers, operators |
| [Agent Quick Reference](../project_overview/agent_quick_reference.md) | Agent types (OpenAI vs Planning) performance guide | Mission developers |

### Strategic Planning
| Document | Purpose | Audience |
|----------|---------|----------|
| [Project Roadmap](../project_overview/roadmap.md) | High-level phases and target outcomes | Leadership, contributors |
| [Project TODO](../project_overview/todo.md) | Prioritized backlog with acceptance criteria | Contributors, maintainers |
| [Architecture Review](../project_overview/architecture_review_summary.md) | October 3 layered design decisions | Architects, technical leads |

### Status & Progress
| Document | Purpose | Audience |
|----------|---------|----------|
| [Setup Status](../project_overview/setup_status.md) | DIMOS integration milestone (Oct 4) | Contributors, onboarding |
| [Status 2025-10-12](../project_overview/status_2025-10-12.md) | Documentation reorg and handoff | Maintainers, continuity |

## Related Documentation

### Development
- **[Development Hub](../development/development_hub.md)** - Contributor guides, policies, and workflows
- **[Submodule Policy](../development/submodule_policy.md)** - Git submodule management guidelines
- **[DIMOS Development](../development/dimos_development_policy.md)** - Framework development practices

### Implementation
- **[Software Hub](../software/software_hub.md)** - ROS2 packages, LLM integration, web interface
- **[LLM Integration](../software/llm/llm_hub.md)** - vLLM/Ollama setup and model selection
- **[Architecture](../architecture/architecture_hub.md)** - System design and component interactions

### Operations
- **[Troubleshooting](../troubleshooting/troubleshooting_hub.md)** - Diagnostic workflows and issue resolution
- **[Startup Validation](../troubleshooting/startup_validation.md)** - Backend and node health checks
- **[Robot Testing](../troubleshooting/quick_start_robot_test.md)** - Hardware-in-the-loop validation

## Validation
- [ ] Quick start guide launches ShadowHound successfully
- [ ] Quick reference commands execute without errors
- [ ] Roadmap milestones align with current repository state
- [ ] TODO backlog reflects current priorities
- [ ] Status documents provide clear handoff information

## See Also
- [Documentation Root](../project_overview/project_overview_hub.md) - Complete documentation index
- [Hardware Platform](../hardware/hardware_hub.md) - Unitree Go2 and sensor suite
- [Networking](../networking/networking_hub.md) - ROS2, DDS, and WebRTC configuration
- [Simulation](../simulation/simulation_hub.md) - Gazebo and hardware-in-the-loop testing

---

**Navigation**: [← Documentation Root](../project_overview/project_overview_hub.md) | [Development Hub →](../development/development_hub.md)
