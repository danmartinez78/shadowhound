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

### 🎯 Core Planning Documents
- **[MVP Roadmap](mvp_embodied_ai_platform.md)** - **SOURCE OF TRUTH** - Embodied AI platform roadmap and milestones
- **[MVP Protection Policy](MVP_PROTECTION_POLICY.md)** - How to protect MVP scope from unintended changes
- **[Current Status (Oct 13)](status_analysis_2025_10.md)** - Comprehensive state assessment

### 💡 Ideas & Future Work
- **[Ideas Backlog](ideas_backlog.md)** - Future enhancements and feature ideas
- **[Ideas Integration Summary](ideas_integration_summary.md)** - Planning history and ideas analysis

### � Related Quick References (Moved)
- **[Launch Checklist](../deployment/launch_checklist.md)** - Deployment and startup procedures
- **[Command Reference](../development/command_reference.md)** - Common commands and shortcuts
- **[Agent Types Comparison](../software/agent/agent_types_comparison.md)** - OpenAI vs Planning agent guide

### 📜 Historical Documents
- **[Cleanup Tracking (Oct 14)](../history/project_overview_cleanup_oct14_2025.md)** - Documentation reorganization audit trail
- **[Skills-First Roadmap (Archived)](../legacy/roadmap_skills_first_oct13.md)** - Historical implementation approach
- **[Pre-MVP TODO](../history/todo_pre_mvp_oct2025.md)** - Task list before MVP planning
- **[Status Updates](../history/)** - Point-in-time status snapshots

## Current Phase
**Milestone 1: Vision Foundation (MVP)**
- Testing infrastructure setup
- Skills definition and audit
- Vision stack selection (DIMOS vs VLM vs hybrid)
- Object detection integrated with mission agent

See [MVP Roadmap](mvp_embodied_ai_platform.md) for complete milestones and success criteria.

## Key Documents by Topic

### Core Planning (In This Directory)
| Document | Purpose | Audience |
|----------|---------|----------|
| [MVP Roadmap](mvp_embodied_ai_platform.md) | **SOURCE OF TRUTH** - Embodied AI platform milestones | All stakeholders |
| [MVP Protection Policy](MVP_PROTECTION_POLICY.md) | Scope protection guidelines | Contributors, AI agents |
| [Current Status (Oct 13)](status_analysis_2025_10.md) | Comprehensive state assessment | Contributors, stakeholders |
| [Ideas Backlog](ideas_backlog.md) | Future enhancements and features | Planning, contributors |

### Operational Guides (Moved to Appropriate Directories)
| Document | Purpose | Audience |
|----------|---------|----------|
| [Launch Checklist](../deployment/launch_checklist.md) | Deployment and startup procedures | Operators, new contributors |
| [Command Reference](../development/command_reference.md) | Common commands and shortcuts | Maintainers, operators |
| [Agent Types Comparison](../software/agent/agent_types_comparison.md) | OpenAI vs Planning agent performance | Mission developers |

### Historical Documentation (Archived)
| Document | Purpose | Audience |
|----------|---------|----------|
| [Cleanup Tracking (Oct 14)](../history/project_overview_cleanup_oct14_2025.md) | Documentation reorganization audit | Maintainers, continuity |
| [Skills-First Roadmap](../legacy/roadmap_skills_first_oct13.md) | Historical implementation approach | Architects, historical reference |
| [Pre-MVP TODO](../history/todo_pre_mvp_oct2025.md) | Task list before MVP planning | Historical reference |

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
- [x] MVP roadmap is the authoritative planning document
- [x] MVP Protection Policy guards scope from unintended changes
- [x] Operational guides moved to appropriate directories
- [x] Historical documents archived with proper context
- [x] Directory reduced from 14 to 6 files for clarity

## See Also
- [Documentation Root](../project_overview/project_overview_hub.md) - Complete documentation index
- [Hardware Platform](../hardware/hardware_hub.md) - Unitree Go2 and sensor suite
- [Networking](../networking/networking_hub.md) - ROS2, DDS, and WebRTC configuration
- [Simulation](../simulation/simulation_hub.md) - Gazebo and hardware-in-the-loop testing

---

**Navigation**: [← Documentation Root](../project_overview/project_overview_hub.md) | [Development Hub →](../development/development_hub.md)
