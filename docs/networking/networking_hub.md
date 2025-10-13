---
tags: [networking, index]
status: draft
related: [hardware/network_power_topologies, software/web/webrtc_configuration]
aliases: [Networking Index]
summary: >
  Networking documentation index for connectivity, telemetry, and remote operations.
---

# Networking Index

## Purpose
Catalog networking guides for remote teleoperation, telemetry streaming, and secure infrastructure.

> Source of truth: This section aligns with [[hardware/network_power_topologies|Network & Power Topologies]] for wiring and IP planning. Treat that page as canonical for router mode, addressing, and variants.

## Which path should I use?
- Use WebRTC when:
  - You're on Wi‑Fi and want low‑latency camera streaming with NAT traversal.
  - You're testing full media + control paths via the Unitree SDK bridge.
  - Follow: [[networking/webrtc_direct_test|WebRTC Direct Test]]

- Use DDS (CycloneDDS) when:
  - You're on Ethernet or a LAN that allows multicast (UDP 7400‑7500).
  - You only need ROS 2 topics/services (no WebRTC media path).
  - Follow: [[networking/dds_direct_test|ROS 2 DDS Direct Test]]

## Quick checklist
- [ ] Confirm IP connectivity to the robot/bridge for your chosen path
- [ ] Export or verify ROS networking env (ROS_DOMAIN_ID, RMW)
- [ ] Run the corresponding test script from `scripts/`
- [ ] Capture outcomes and update the guide with any findings

## Network Topology

![Router Topology](../_assets/router-topology.svg)
*Figure 1: Router-based topology with AP/Bridge mode, DHCP off (or limited), and example addressing.*

Roles on the LAN:
- **Development Laptop** – DevContainer, Web UI, development tools
- **Thor (Jetson)** – Edge compute, mission execution (prefer wired Ethernet to router)
- **Unitree GO2** – Robot; connects via Ethernet (factory subnet) and/or Wi‑Fi to the router

### Key Protocols & Ports
- **ROS2 DDS**: UDP 7400-7500 (CycloneDDS discovery and data)
- **FastAPI**: HTTP 8000 (Web UI and REST API)
- **WebRTC**: UDP 50000-50100 (Camera streaming)
- **SSH**: TCP 22 (Remote access and management)

## WiFi Router topology (recommended)

A dedicated WiFi router between the robot and Thor provides a predictable, low‑latency LAN for both WebRTC and DDS. This mirrors the GL.iNet GL‑SFT1200 setup described in [[hardware/network_power_topologies|Network & Power Topologies]].

### Topology
- Laptop ⇄ Router (WiFi)
- Thor (Jetson) ⇄ Router (Ethernet preferred, WiFi acceptable)
- Unitree Go2 ⇄ Router (WiFi)

Benefits:
- Isolated LAN with stable DHCP leases and no enterprise firewalls in the way
- Deterministic latency when Thor uses Ethernet to the router
- Easier troubleshooting vs. campus/enterprise WiFi

### IP addressing plan (canonical example)
- Router/AP (bridge mode): 192.168.10.1/24
- Thor (Jetson) eth0: 192.168.10.3/24
- GO2 (factory Ethernet): 192.168.123.161/24 (unchanged factory subnet)
- Thor secondary IP (same NIC): 192.168.123.10/24 to reach GO2 factory subnet

Optional simplification:
- Re‑address GO2 to 192.168.10.2/24 so everything lives on 192.168.10.0/24 (see the optional note in [[hardware/network_power_topologies|Network & Power Topologies]]).

### Router configuration checklist
- Mode: Access Point / Bridge (WAN+LAN bridged)
- Address: 192.168.10.1/24
- DHCP: Off (static addressing), or very limited scope during bring‑up
- Client isolation: Disabled
- Bands: Prefer 5 GHz for robot + laptop; 2.4 GHz optional
- Multicast: Enable IGMP snooping or multicast forwarding (helps DDS discovery)
- Time sync: NTP enabled

### Protocol considerations
- WebRTC:
  - Works on Wi‑Fi; ensure router doesn’t block high UDP ephemeral ports (50000–50100)
  - Set `CONN_TYPE=webrtc` and ensure `GO2_IP` matches the robot’s Wi‑Fi or LAN address
- DDS (CycloneDDS):
  - Multicast must be permitted on the LAN (UDP 7400–7500)
  - Best when Thor is wired; Wi‑Fi clients can still participate

### Validation
1. Confirm DHCP leases show the three devices with expected IPs
2. From laptop, ping Thor and the robot IP
3. WebRTC path: run [[networking/webrtc_direct_test|WebRTC Direct Test]]
4. DDS path: run [[networking/dds_direct_test|ROS 2 DDS Direct Test]]

### Common pitfalls
- Client isolation enabled on APs blocks peer‑to‑peer traffic — disable it
- Enterprise WiFi often filters multicast — use your own router/AP for DDS
- Mixed 2.4/5 GHz with power‑saving can introduce latency spikes — pin to 5 GHz if possible

### Related
- [[software/web/webrtc_configuration|WebRTC Configuration]] — Robot WiFi onboarding flow
- [[hardware/network_power_topologies|Network & Power Topologies]] — Comprehensive router + power distribution configurations for all hardware variants

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
- [[software/software_hub|Software Index]]
- Network monitoring dashboards (link when available)
