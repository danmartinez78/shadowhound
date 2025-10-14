---
tags: [project, overview]
status: draft
related: []
summary: >
  Entry point for the ShadowHound knowledge base maintained in Obsidian.
---

# ShadowHound Knowledge Base

## Purpose
Central entry point for the ShadowHound documentation vault. This autonomous mobile robot system combines ROS2 navigation with LLM/VLM-driven task planning on the Unitree Go2 platform.

**See [Architecture Documentation](architecture/architecture_hub.md) for system diagrams and design overview.**

## Prerequisites
- Clone the repository and open the `/docs` directory as an Obsidian vault.
- Install the Obsidian Markdown Links core plugin (enabled by default).

## Steps
1. Review the directory hubs below to explore specific topic areas.
2. Use the reusable template at [`_templates/page`](./_templates/page.md) when authoring new content.
3. Store shared media inside [`_assets/`](./_assets/) and reference them with relative paths.

## Documentation Directories

### 📋 Planning & Status
**[Project Overview](project_overview/project_overview_hub.md)**
- Strategic planning, roadmaps, and status tracking
- Quick start guides and operational references
- 8 active documents: roadmap, todo, setup status, architecture review

### 🏗️ System Design
**[Architecture](architecture/architecture_hub.md)**
- System architecture and design decisions
- Component interactions and data flows
- Layered design: Application → Agent → Skills → Robot

### 🔧 Development
**[Development](development/development_hub.md)**
- Contributor guides and development policies
- Git workflows and submodule management
- 11 documents including cleanup tracking and checklists

### � Deployment
**[Deployment](deployment/deployment_hub.md)**
- Environment strategies and configuration
- Launch orchestration and machine setup
- Multi-machine synchronization procedures

### �💻 Software
**[Software](software/software_hub.md)**
- ROS2 packages and implementations
- LLM integration (vLLM, Ollama) - 26+ docs
- Web interface and WebRTC communication
- Configuration and environment setup

### 🤖 Hardware
**[Hardware](hardware/hardware_hub.md)**
- Unitree Go2 platform and sensor suite
- Network and power topologies
- Hardware specifications and integration guides

### 🌐 Networking
**[Networking](networking/networking_hub.md)**
- ROS2 DDS and WebRTC configuration
- Direct connectivity testing
- Multi-machine deployment topologies

### 🐛 Troubleshooting
**[Troubleshooting](troubleshooting/troubleshooting_hub.md)**
- Diagnostic workflows and health checks
- Known issues and resolutions
- Startup validation and robot testing

### 🔬 Research & Testing
**[Simulation](simulation/simulation_hub.md)** - Gazebo and hardware-in-the-loop
**[Research](research/research_hub.md)** - Experiments and development logs
**[Performance](performance/performance_hub.md)** - Benchmarking and optimization

### 📦 Supporting
**[Integrations](integrations/integrations_hub.md)** - DIMOS, vision, AI integrations
**[Known Issues](issues/issues_hub.md)** - Bug tracking and workarounds
**[History & Archive](history/history_hub.md)** - Archived legacy documentation


## Validation
- [ ] Vault opens in Obsidian without warnings.
- [ ] All category links resolve inside Obsidian.
- [ ] Link conversion step renders correctly on GitHub Pages and Wiki.

## References
- [Authoring Guidelines](../AGENTS.md)
- [Repository README](../README.md)

