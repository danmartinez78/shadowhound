---
tags: [networking, index]
status: draft
related: []
summary: >
  Networking documentation index for connectivity, telemetry, and remote operations.
---

# Networking Index

## Purpose
Catalog networking guides for remote teleoperation, telemetry streaming, and secure infrastructure.

## Network Topology

![Network Topology](../_assets/network-topology.png)
*Figure 1: ShadowHound network topology showing development laptop, Thor (Jetson Orin Nano), and GO2 robot connected via WiFi with optional direct Ethernet connection.*

The network consists of:
- **Development Laptop** (192.168.1.100) - DevContainer, Web UI, development tools
- **Thor - Jetson Orin Nano** (192.168.1.102) - Edge compute, mission execution
- **Unitree GO2 Robot** (192.168.1.103) - Quadruped robot with internal network (192.168.12.1)

### Key Protocols & Ports
- **ROS2 DDS**: UDP 7400-7500 (CycloneDDS discovery and data)
- **FastAPI**: HTTP 8000 (Web UI and REST API)
- **WebRTC**: UDP 50000-50100 (Camera streaming)
- **SSH**: TCP 22 (Remote access and management)

## Prerequisites
- Access to network configuration credentials.
- Familiarity with VPN, VLAN, and ROS 2 discovery concepts.

## Steps
1. Document each networking environment (lab, field, cloud relay) with diagrams and configs.
2. Use `_assets/` for topology diagrams and link them via relative paths.
3. Verify all IP ranges and credentials are stored in secure vaults, not inline Markdown.

### Featured Guides
- [[networking/webrtc_direct_test|WebRTC Direct Test]]
- [[networking/dds_direct_test|ROS 2 DDS Direct Test]]

## Validation
- [ ] Each environment has a validated connection checklist.
- [ ] Sensitive secrets are stored outside of the repo.
- [ ] Converted Markdown renders without Obsidian-only syntax.

## References
- [[index|Vault Index]]
- [[software/README|Software Index]]
- Network monitoring dashboards (link when available)
