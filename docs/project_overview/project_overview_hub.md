---
tags: [project_overview, index]
status: active
related: [development/README, software/README, architecture/README]
summary: >
  Central hub for ShadowHound project planning, status tracking, roadmaps, and quick reference guides.
---

# Project Overview

## Purpose
Serve as the primary entry point for understanding ShadowHound's current status, planned milestones, and operational quick-start procedures. This hub connects strategic planning documents with tactical implementation guides.

## Prerequisites
- Familiarity with the ShadowHound mission: autonomous mobile robot combining ROS2 navigation with LLM/VLM-driven task planning
- Access to the repository workspace and development environment
- Understanding of the [[architecture/architecture_hub|System Architecture]] and [[hardware/hardware_hub|Hardware Platform]]

## Quick Navigation

### 🚀 Getting Started
- **[[project_overview/quick_start|Quick Start]]** - One-command launch checklist for rapid bring-up
- **[[project_overview/quick_reference|Quick Reference]]** - Command cheat sheet and operational shortcuts
- **[[project_overview/agent_quick_reference|Agent Quick Reference]]** - Agent types and performance characteristics

### 📋 Planning & Status
- **[[project_overview/roadmap|Project Roadmap]]** - High-level phases and strategic milestones
- **[[project_overview/todo|Project TODO]]** - Prioritized backlog and task tracking
- **[[project_overview/setup_status|Setup Status]]** - DIMOS integration milestone (October 4, 2025)
- **[[project_overview/status_2025-10-12|Status 2025-10-12]]** - Recent documentation reorg and handoff

### 🏗️ Architecture & Context
- **[[project_overview/architecture_review_summary|Architecture Review Summary]]** - October 3 design decisions and layered architecture

## Current Phase
**Phase 0: Bootstrap & Local LLM Integration**
- Core ROS2 packages scaffolded with DIMOS framework
- vLLM backend integration with local embeddings
- End-to-end testing with Thor (Jetson) deployment

See [[project_overview/roadmap|Project Roadmap]] for detailed milestone tracking.

## Key Documents by Topic

### Onboarding & Operations
| Document | Purpose | Audience |
|----------|---------|----------|
| [[project_overview/quick_start|Quick Start]] | Rapid launch checklist using `start.sh` | Operators, new contributors |
| [[project_overview/quick_reference|Quick Reference]] | Command cheat sheet and environment presets | Maintainers, operators |
| [[project_overview/agent_quick_reference|Agent Quick Reference]] | Agent types (OpenAI vs Planning) performance guide | Mission developers |

### Strategic Planning
| Document | Purpose | Audience |
|----------|---------|----------|
| [[project_overview/roadmap|Project Roadmap]] | High-level phases and target outcomes | Leadership, contributors |
| [[project_overview/todo|Project TODO]] | Prioritized backlog with acceptance criteria | Contributors, maintainers |
| [[project_overview/architecture_review_summary|Architecture Review]] | October 3 layered design decisions | Architects, technical leads |

### Status & Progress
| Document | Purpose | Audience |
|----------|---------|----------|
| [[project_overview/setup_status|Setup Status]] | DIMOS integration milestone (Oct 4) | Contributors, onboarding |
| [[project_overview/status_2025-10-12|Status 2025-10-12]] | Documentation reorg and handoff | Maintainers, continuity |

## Related Documentation

### Development
- **[[development/development_hub|Development Hub]]** - Contributor guides, policies, and workflows
- **[[development/submodule_policy|Submodule Policy]]** - Git submodule management guidelines
- **[[development/dimos_development_policy|DIMOS Development]]** - Framework development practices

### Implementation
- **[[software/software_hub|Software Hub]]** - ROS2 packages, LLM integration, web interface
- **[[software/llm/llm_hub|LLM Integration]]** - vLLM/Ollama setup and model selection
- **[[architecture/architecture_hub|Architecture]]** - System design and component interactions

### Operations
- **[[troubleshooting/troubleshooting_hub|Troubleshooting]]** - Diagnostic workflows and issue resolution
- **[[troubleshooting/startup_validation|Startup Validation]]** - Backend and node health checks
- **[[troubleshooting/quick_start_robot_test|Robot Testing]]** - Hardware-in-the-loop validation

## Validation
- [ ] Quick start guide launches ShadowHound successfully
- [ ] Quick reference commands execute without errors
- [ ] Roadmap milestones align with current repository state
- [ ] TODO backlog reflects current priorities
- [ ] Status documents provide clear handoff information

## See Also
- [[project_overview/project_overview_hub|Documentation Root]] - Complete documentation index
- [[hardware/hardware_hub|Hardware Platform]] - Unitree Go2 and sensor suite
- [[networking/networking_hub|Networking]] - ROS2, DDS, and WebRTC configuration
- [[simulation/simulation_hub|Simulation]] - Gazebo and hardware-in-the-loop testing

---

**Navigation**: [[project_overview/project_overview_hub|← Documentation Root]] | [[development/development_hub|Development Hub →]]
