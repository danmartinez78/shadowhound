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

**See [[architecture/architecture_hub|Architecture Documentation]] for system diagrams and design overview.**

## Prerequisites
- Clone the repository and open the `/docs` directory as an Obsidian vault.
- Install the Obsidian Markdown Links core plugin (enabled by default).

## Steps
1. Review the directory hubs below to explore specific topic areas.
2. Use the reusable template at [`_templates/page`](./_templates/page.md) when authoring new content.
3. Store shared media inside [`_assets/`](./_assets/) and reference them with relative paths.

## Documentation Directories

### 📋 Planning & Status
**[[project_overview/project_overview_hub|Project Overview]]**
- Strategic planning, roadmaps, and status tracking
- Quick start guides and operational references
- 8 active documents: roadmap, todo, setup status, architecture review

### 🏗️ System Design
**[[architecture/architecture_hub|Architecture]]**
- System architecture and design decisions
- Component interactions and data flows
- Layered design: Application → Agent → Skills → Robot

### 🔧 Development
**[[development/development_hub|Development]]**
- Contributor guides and development policies
- Git workflows and submodule management
- 11 documents including cleanup tracking and checklists

### 💻 Software
**[[software/software_hub|Software]]**
- ROS2 packages and implementations
- LLM integration (vLLM, Ollama) - 26+ docs
- Web interface and WebRTC communication
- Configuration and environment setup

### 🤖 Hardware
**[[hardware/hardware_hub|Hardware]]**
- Unitree Go2 platform and sensor suite
- Network and power topologies
- Hardware specifications and integration guides

### 🌐 Networking
**[[networking/networking_hub|Networking]]**
- ROS2 DDS and WebRTC configuration
- Direct connectivity testing
- Multi-machine deployment topologies

### 🐛 Troubleshooting
**[[troubleshooting/troubleshooting_hub|Troubleshooting]]**
- Diagnostic workflows and health checks
- Known issues and resolutions
- Startup validation and robot testing

### 🔬 Research & Testing
**[[simulation/simulation_hub|Simulation]]** - Gazebo and hardware-in-the-loop
**[[research/research_hub|Research]]** - Experiments and development logs

### 📦 Supporting
**[[integrations/integrations_hub|Integrations]]** - DIMOS, vision, AI integrations
**[[issues/issues_hub|Known Issues]]** - Bug tracking and workarounds
**[[history/history_hub|History & Archive]]** - Archived legacy documentation


## Validation
- [ ] Vault opens in Obsidian without warnings.
- [ ] All category links resolve inside Obsidian.
- [ ] Link conversion step renders correctly on GitHub Pages and Wiki.

## References
- [Authoring Guidelines](../AGENTS.md)
- [Repository README](../README.md)
