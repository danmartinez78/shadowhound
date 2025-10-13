---
tags: [software/web, index]
status: active
related: [software/README, networking/webrtc_direct_test, hardware/network_power_topologies]
aliases: [Web Interface Documentation]
summary: >
  Web interface and WebRTC communication documentation for ShadowHound robot control.
---

# Web Interface Documentation

## Purpose
Documentation for the ShadowHound web interface and WebRTC-based robot communication system.

## Prerequisites
- Understanding of WebRTC protocols
- Familiarity with GO2 robot communication modes
- Network configuration knowledge (see [[networking/networking_hub|Networking Docs]])

## Key Documents

### WebRTC Configuration
- **[[software/web/webrtc_configuration|WebRTC Configuration Guide]]** — Complete setup guide for robot WiFi communication, high-level API access, and dual-protocol architecture (WebRTC + CycloneDDS)

### Web UI Design
- **[[software/web/web_ui_mockup|Web UI Mockup]]** — Design reference and interface mockup for robot control interface

## WebRTC Overview

The Unitree Go2 robot supports **two communication protocols**:

1. **CycloneDDS (Ethernet)** — Direct motor control, sensors, basic navigation
2. **WebRTC (WiFi)** — Full API access including high-level behaviors (sit, stand, dance, wave)

### When to Use Each Protocol

| Protocol | Connection | Use Case | Speed |
|----------|-----------|----------|-------|
| **CycloneDDS** | Ethernet/USB | Low-level control, sensors | Fastest, ~1ms |
| **WebRTC** | WiFi | High-level skills, remote ops | Good, ~10-50ms |

### WebRTC Advantages
- ✅ Access to high-level behaviors (sit, stand, wave, etc.)
- ✅ WiFi-based (no cables required)
- ✅ Works alongside DDS (dual-mode operation)
- ✅ Video streaming support
- ❌ Higher latency than direct DDS

## Common Tasks

### Configure WebRTC Connection
See [[software/web/webrtc_configuration|WebRTC Configuration Guide]] for complete setup instructions including:
- Robot WiFi onboarding
- WebRTC connection setup
- Dual-protocol architecture
- Troubleshooting connectivity

### Access Web Interface
```bash
# Start web interface (if integrated)
# See start script reference for details
./start.sh
```

### Test WebRTC Connectivity
See [[../../networking/webrtc_direct_test|WebRTC Direct Test]] for validation procedures.

## Architecture Notes

### Dual-Protocol Design
ShadowHound uses both protocols simultaneously:
- **DDS** for navigation, odometry, lidar
- **WebRTC** for skills, status, high-level commands

This hybrid approach provides:
- Low-latency sensor data
- Rich high-level API access
- Flexible deployment options

### Network Requirements
- GO2 robot on WiFi: `192.168.10.103`
- Thor/Laptop on same network: `192.168.10.x`
- See [[../../hardware/network_power_topologies|Network Topologies]] for complete wiring

## Validation
- [ ] WebRTC configuration guide tested and validated
- [ ] Web UI mockup reflects current design
- [ ] Connectivity procedures documented
- [ ] Dual-protocol architecture explained

## See Also
- [[../../networking/webrtc_direct_test|WebRTC Direct Test]] — Connectivity validation
- [[networking/networking_hub|Networking Documentation]] — Network setup and DDS configuration
- [[../../hardware/network_power_topologies|Hardware Topologies]] — Router and WiFi setup
- [[software/software_hub|Software Index]] — Complete software documentation

## References
- [[../../index|Documentation Root]]
- Unitree GO2 SDK Documentation
- WebRTC Protocol Specification
- go2-webrtc-connect: https://github.com/abizovnuralem/go2_webrtc_connect
