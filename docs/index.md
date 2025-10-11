---
tags: [project, overview]
status: draft
related: []
summary: >
  Entry point for the ShadowHound knowledge base maintained in Obsidian.
---

# ShadowHound Knowledge Base

## Purpose
Provide a curated entry point into the Obsidian vault and downstream public documentation surfaces.

## Architecture Overview

ShadowHound is an autonomous mobile robot system combining ROS2 navigation with LLM/VLM-driven planning. The system architecture is built on four main layers:

![System Architecture](_assets/system-architecture.png)
*Figure 1: System Architecture - The layered design from Web UI through Mission Agent, DIMOS Skills Engine, ROS2 Bridge, to the Unitree GO2 hardware.*

### Key Data Flows

![Data Flow Architecture](_assets/data-flow.png)
*Figure 2: Data Flow - Mission commands flow top-down, telemetry flows bottom-up, camera feeds use WebRTC, and skills execute with feedback loops.*

### Network Topology

![Network Topology](_assets/network-topology.png)
*Figure 3: Network Topology - Development laptop, Thor (Jetson Orin), and GO2 robot connected via WiFi network with optional direct Ethernet.*

### Documentation Workflow

![Documentation Ecosystem](_assets/docs-ecosystem.png)
*Figure 4: Documentation Ecosystem - Obsidian vault authoring through automation tools and CI/CD to multiple publication targets.*

## Prerequisites
- Clone the repository and open the `/docs` directory as an Obsidian vault.
- Install the Obsidian Markdown Links core plugin (enabled by default).

## Steps
1. Review the top-level categories below and follow links for detailed guides.
2. Use the reusable template at [`_templates/page`](./_templates/page.md) when authoring new content.
3. Store shared media inside [`_assets/`](./_assets/) and reference them with relative paths.

### Category Quick Links
- [[project_overview/roadmap|Project Overview & Roadmap]]
- [[project_overview/quick_start|Quick Start Launch Checklist]]
- [[project_overview/quick_reference|Quick Reference]]
- [[project_overview/todo|Project TODO Backlog]]
- [[project_overview/setup_status|Project Setup Status (Oct 4 2025)]]
- [[project_overview/architecture_review_summary|Architecture Review Summary]]
- [[hardware/README|Hardware Stack]]
- [[software/README|Software Stack]]
- [[software/scripts|Script Catalog]]
- [[software/environment_configuration|Environment Configuration Guide]]
- [[software/start_script_reference|Start Script Reference]]
- [[software/dimos_quick_start|DIMOS Integration Quick Start]]
- [[networking/README|Networking]]
- [[networking/webrtc_direct_test|WebRTC Direct Test]]
- [[simulation/README|Simulation]]
- [[troubleshooting/README|Troubleshooting]]
- [[research/README|Research Log]]
- [[research/devlog|Development Log]]


## Validation
- [ ] Vault opens in Obsidian without warnings.
- [ ] All category links resolve inside Obsidian.
- [ ] Link conversion step renders correctly on GitHub Pages and Wiki.

## References
- [[AGENTS|Authoring Guidelines]]
- [[../README|Repository README]]
