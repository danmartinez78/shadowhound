---
tags: [software, index]
status: active
related: [software/ros2_setup, software/llm/vllm_quickstart, software/web/webrtc_configuration]
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
3. Use [[software/autodoc/_index|Autodoc landing]] to locate generated package references.

### Quick Links
- [[software/ros2_setup|ROS 2 Workstation Setup]]
- [[software/dimos_quick_start|DIMOS Integration Quick Start]]
- [[software/scripts|Script Catalog]]
- [[software/environment_configuration|Environment Configuration Guide]]
- [[software/start_script_reference|Start Script Reference]]
- [[software/isaac_sim_remote|Isaac Sim Remote Streaming]]

### By Topic
#### LLM & AI Integration
- [[software/llm/vllm_quickstart|vLLM Quick Start]] — Local LLM deployment on Thor
- [[software/llm/ollama_setup|Ollama Setup]] — Alternative local LLM backend
- [[software/llm/llm_backend_validation|Backend Validation]] — Startup validation system

#### Web Interface & WebRTC
- [[software/web/webrtc_configuration|WebRTC Configuration]] — Robot WiFi communication setup
- [[software/web/web_ui_mockup|Web UI Mockup]] — Design reference

#### Agent System
- [[software/agent/dimos_agent_architecture|DIMOS Agent Architecture]] — Agent system design

#### Configuration
- [[software/configuration/environment_variables|Environment Variables]] — Complete variable reference
- [[software/configuration/embeddings_auto_detection|Embeddings Auto-Detection]] — ChromaDB setup
- [[software/configuration/vllm_env_example|vLLM Environment Example]] — Configuration template

#### Auto-Generated API Documentation
- [[software/autodoc/_index|Autodoc Index]] — ROS 2 package API documentation

## Validation
- [ ] Autodoc stubs regenerate without errors
- [ ] All setup guides reference validated commands
- [ ] MkDocs navigation renders the same hierarchy as the vault
- [ ] All subdirectories have README index pages

## See Also
- [[../development/README|Development Documentation]] — Git workflows and policies
- [[../hardware/README|Hardware Documentation]] — Robot and sensor setup
- [[../networking/README|Networking Documentation]] — DDS and WebRTC connectivity
- [[../troubleshooting/README|Troubleshooting Index]] — Diagnostic procedures

## References
- [[../index|Documentation Root]]
- `tools/ros2_autodoc.py` — Auto-generate package documentation
- `tools/link_convert.py` — Convert wikilinks for GitHub Pages
