---
tags: [software, index]
status: active
related: []
aliases: [Software Index]
summary: >
  Software documentation index for ROS 2 packages, LLM integration, web interface, and tooling.
---

# Software Index

## Purpose
Organize the ShadowHound software stack documentation, including ROS 2 packages, simulation tooling, and automation scripts.

## Prerequisites
- Working ROS 2 Humble development environment.
- Familiarity with the repository layout (`src/`, `launch/`, `docs/`).

## Steps
1. Review the quick links below for setup guides and automation tools.
2. Generate auto-documentation stubs by running `python tools/ros2_autodoc.py` after package changes.
3. Use [Autodoc landing](../software/autodoc/_index.md) to locate generated package references.

### Quick Links
- [ROS 2 Workstation Setup](../software/ros2_setup.md)
- [DIMOS Integration Quick Start](../software/dimos_quick_start.md)
- [Script Catalog](../software/scripts.md)
- [Environment Configuration Guide](../software/environment_configuration.md)
- [Start Script Reference](../software/start_script_reference.md)
- [Isaac Sim Remote Streaming](../software/isaac_sim_remote.md)

### By Topic
#### LLM & AI Integration
- [vLLM Quick Start](../software/llm/vllm_quickstart.md) — Local LLM deployment on Thor
- [Ollama Setup](../software/llm/ollama_setup.md) — Alternative local LLM backend
- [Backend Validation](../software/llm/llm_backend_validation.md) — Startup validation system

#### Web Interface & WebRTC
- [WebRTC Configuration](../software/web/webrtc_configuration.md) — Robot WiFi communication setup
- [Web UI Mockup](../software/web/web_ui_mockup.md) — Design reference

#### Agent System
- [DIMOS Agent Architecture](../software/agent/dimos_agent_architecture.md) — Agent system design

#### Configuration
- [Environment Variables](../software/configuration/environment_variables.md) — Complete variable reference
- [Embeddings Auto-Detection](../software/configuration/embeddings_auto_detection.md) — ChromaDB setup
- [vLLM Environment Example](../software/configuration/vllm_env_example.md) — Configuration template

#### Auto-Generated API Documentation
- [Autodoc Index](../software/autodoc/_index.md) — ROS 2 package API documentation

## Validation
- [ ] Autodoc stubs regenerate without errors
- [ ] All setup guides reference validated commands
- [ ] MkDocs navigation renders the same hierarchy as the vault
- [ ] All subdirectories have README index pages

## See Also
- [Development Documentation](../development/development_hub.md) — Git workflows and policies
- [Hardware Documentation](../hardware/hardware_hub.md) — Robot and sensor setup
- [Networking Documentation](../networking/networking_hub.md) — DDS and WebRTC connectivity
- [Troubleshooting Index](../troubleshooting/troubleshooting_hub.md) — Diagnostic procedures

## References
- [Documentation Root](../index.md)
- `tools/ros2_autodoc.py` — Auto-generate package documentation
- `tools/link_convert.py` — Convert wikilinks for GitHub Pages
