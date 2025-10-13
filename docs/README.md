---
tags: [project, index]
status: draft
related: []
aliases: [Docs Index, Documentation Index]
summary: >
  Landing page for the ShadowHound documentation vault with quick links and navigation.
---

# ShadowHound Documentation

Welcome to the ShadowHound documentation! This guide helps you navigate the complete documentation structure.

---

## 🚀 Quick Start

New to ShadowHound? Start here:

- **[Quick Start Guide](project_overview/quick_start.md)** - Get up and running in 15 minutes
- **[Quick Reference](project_overview/quick_reference.md)** - Command cheat sheet and common tasks
- **[Setup Status](project_overview/setup_status.md)** - Current configuration and readiness

---

## 📖 Core Documentation

### Project Overview
- [Project Context](project.md) - High-level vision and goals
- [Architecture Overview](architecture/README.md) - System design and components
- [TODO List](project_overview/todo.md) - Current tasks and priorities
- [Roadmap](project_overview/roadmap.md) - Future plans and milestones

### Hardware
- [Hardware Setup](hardware/README.md) - Robot and sensor configuration
- [Network & Power Topologies](hardware/network_power_topologies.md) - Comprehensive wiring and power configurations for all hardware variants

### Software
- [Software Overview](software/README.md) - Software stack guide
- [ROS2 Setup](software/ros2_setup.md) - ROS2 installation and configuration
- [DIMOS Quick Start](software/dimos_quick_start.md) - DIMOS framework guide
- [Start Script Reference](software/start_script_reference.md) - Launch system guide

---

## 🔧 Configuration

### Environment & Backends
- [Environment Variables](software/configuration/environment_variables.md) - All environment settings
- [Embeddings Auto-Detection](software/configuration/embeddings_auto_detection.md) - Local vs cloud embeddings

### LLM Backends
- [Backend Quick Reference](software/llm/backend_quick_reference.md) - Choose your LLM backend
- [Local LLM Integration](software/llm/local_llm_integration_summary.md) - vLLM, Ollama, llama.cpp
- [Ollama Setup](software/llm/OLLAMA_SETUP.md) - Ollama configuration
- [vLLM Quickstart](software/llm/vllm_quickstart.md) - vLLM setup on Thor

---

## 🛠️ Development

### Getting Started
- [Development Guide](development/README.md) - Contribution guidelines
- [DIMOS Development Policy](development/dimos_development_policy.md) - Submodule workflow
- [Copilot CLI Setup](development/copilot_cli_setup.md) - AI assistant setup

### Agent System
- [Agent Architecture](software/agent/dimos_agent_architecture.md) - Agent design
- [Agent Tasks](software/agent/agent_tasks.md) - Agent capabilities
- [Agent Refactor Analysis](software/agent/agent_refactor_analysis.md) - Recent changes

### Integrations
- [DIMOS Integration](integrations/dimos_integration.md) - DIMOS framework integration
- [Vision Integration](integrations/vision_integration_design.md) - VLM and camera setup
- [RAG Integration](integrations/rag_integration.md) - Semantic memory
- [ChatGPT Integration](integrations/chatgpt_integration.md) - OpenAI API usage

### Web Interface
- [Web Interface Integration](software/web/web_interface_integration.md) - Dashboard setup
- [WebRTC Configuration](software/web/webrtc_configuration.md) - Real-time video
- [UI Redesign Summary](software/web/ui_redesign_summary.md) - Current UI state

---

## 🐛 Troubleshooting

### Common Issues
- [Troubleshooting Guide](troubleshooting/README.md) - Debug procedures
- [Mission Agent Troubleshooting](troubleshooting/troubleshooting_mission_agent.md) - Agent issues
- [Debugging Robot Commands](troubleshooting/debugging_robot_commands.md) - Robot control issues
- [Topic Diagnostics](troubleshooting/topic_diagnostics.md) - ROS2 topic debugging

### Known Issues
- [Command Mode Conflict](troubleshooting/command_mode_conflict.md) - Terminal input issues
- [Issue Tracker](issues/README.md) - Documented bugs and workarounds

---

## 📊 API Reference

### Auto-Generated Documentation
- [API Index](software/autodoc/_index.md) - All package documentation
- [Mission Agent API](software/autodoc/shadowhound_mission_agent_api.md) - Mission executor
- [Skills API](software/autodoc/shadowhound_skills_api.md) - Robot skills

### ROS2 Packages
- [shadowhound_mission_agent](software/autodoc/shadowhound_mission_agent.md)
- [shadowhound_skills](software/autodoc/shadowhound_skills.md)
- [shadowhound_bringup](software/autodoc/shadowhound_bringup.md)

---

## 🗺️ Navigation by Topic

### Architecture & Design
- [Architecture](architecture/)
  - System architecture
  - Camera architecture
  - Deployment topology
  - Architecture clarifications

### Deployment
- [Deployment](deployment/)
  - Laptop setup
  - Orchestrated launch
  - Environment strategies
  - Deployment sync

### Development Process
- [Development](development/)
  - Development tracking
  - Branch consolidation
  - Auto-update system
  - Cache clearing guide
  - QOL improvements

### Historical Records
- [History](history/)
  - Merge summaries
  - EOD summaries
  - Migration notes

### Research & Experiments
- [Research](research/)
  - Development log
  - Experimental features

### Simulation
- [Simulation](simulation/)
  - Gazebo setup
  - Mock environments

### Networking
- [Networking](networking/)
  - WebRTC direct test
  - Network configuration

---

## 📝 Documentation Standards

### Writing Guidelines
- Use [Obsidian-style wikilinks](AGENTS.md) for cross-references
- Include YAML front-matter in all docs:
  ```yaml
  ---
  tags: [category, topic]
  status: active|archived|outdated
  related: []
  summary: >
    Brief description
  ---
  ```
- Follow the [page template](_templates/page.md)

### Organization
- Keep root directory minimal (< 10 files)
- Group related docs in subdirectories
- Create README.md index for each subdirectory
- Use descriptive, consistent naming (snake_case.md)

### Maintenance
- Archive old docs in `archive/`
- Update links when moving files
- Run link validation: `python tools/validate_wikilinks.py --docs docs`
- Sync to GitHub Wiki: `python tools/wiki_sync.py --push`

---

## 🔗 External Resources

- **GitHub Repository**: [danmartinez78/shadowhound](https://github.com/danmartinez78/shadowhound)
- **GitHub Wiki**: [ShadowHound Wiki](https://github.com/danmartinez78/shadowhound/wiki)
- **MkDocs Site**: [Documentation Site](https://danmartinez78.github.io/shadowhound/) (if deployed)
- **ROS2 Documentation**: [docs.ros.org](https://docs.ros.org/en/humble/)
- **DIMOS Framework**: [DIMOS Repository](https://github.com/dimensionalOS/dimos-unitree)

---

## 📞 Getting Help

1. **Search Documentation**: Use Ctrl+F or GitHub search
2. **Check Troubleshooting**: [troubleshooting/README.md](troubleshooting/README.md)
3. **Review Known Issues**: [issues/](issues/)
4. **Ask the Team**: Create a GitHub Issue
5. **Development Chat**: Check project communication channels

---

## 🎯 Quick Links

| Topic | Link |
|-------|------|
| Get Started | [Quick Start](project_overview/quick_start.md) |
| Environment Setup | [Environment Variables](software/configuration/environment_variables.md) |
| Run Robot | [Start Script](software/start_script_reference.md) |
| Choose LLM Backend | [Backend Guide](software/llm/backend_quick_reference.md) |
| Debug Issues | [Troubleshooting](troubleshooting/README.md) |
| Contribute | [Development Guide](development/README.md) |
| API Reference | [Autodoc Index](software/autodoc/_index.md) |

---

**Last Updated**: October 12, 2025  
**Documentation Version**: 2.0 (Post-Reorganization)

For questions or improvements, please create an issue or submit a pull request.
