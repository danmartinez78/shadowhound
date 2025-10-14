---
tags: [troubleshooting, index]
status: active
related: []
aliases: [Troubleshooting Index]
summary: >
  Troubleshooting index for common ShadowHound failure modes, diagnostic procedures, and recovery steps.
---

# Troubleshooting Index

## Purpose
Centralize troubleshooting guides to reduce mean time to recovery across hardware, software, and networking failures. This index covers startup validation, robot testing procedures, and diagnostic workflows.

## Prerequisites
- Access to telemetry logs or observability dashboards
- Knowledge of the impacted subsystem
- Familiarity with ROS 2 diagnostics tools

## Active Troubleshooting Guides

### Startup & Validation
- **[Startup Validation Flow](../troubleshooting/startup_validation.md)** — Two-layer LLM backend validation (pre-flight checks + runtime)
  - Start script pre-flight checks (fail fast)
  - Mission agent runtime validation
  - Ollama and OpenAI backend validation

### Robot Testing
- **[Quick Start: Robot Testing](../troubleshooting/quick_start_robot_test.md)** — Complete testing procedure with local LLM
  - GPU setup and monitoring (jtop)
  - Ollama configuration (phi4:14b)
  - End-to-end robot command testing
  - Performance validation

## Common Issues & Solutions

### LLM Backend Issues
**Symptom**: Mission agent fails to start or hangs  
**Solution**: See [Startup Validation](../troubleshooting/startup_validation.md) for pre-flight checks

**Symptom**: Slow or no responses from LLM  
**Solution**: Check backend configuration in [Backend Validation](../software/llm/llm_backend_validation.md)

### Robot Connectivity Issues
**Symptom**: Robot not responding to commands  
**Solution**: 
1. Verify DDS connectivity: [DDS Direct Test](../networking/dds_direct_test.md)
2. Check WebRTC connection: [WebRTC Direct Test](../networking/webrtc_direct_test.md)
3. Validate network topology: [Network Topologies](../hardware/network_power_topologies.md)

### ROS 2 Topic Issues
**Symptom**: Topics not visible or no data  
**Diagnostic Commands**:
```bash
# List all topics
ros2 topic list

# Check topic info
ros2 topic info /topic_name

# Echo topic data
ros2 topic echo /topic_name

# Check DDS discovery
ros2 daemon status
ros2 daemon stop  # If needed to reset
ros2 daemon start
```

## Diagnostic Workflow

### 1. Identify Subsystem
- **Hardware**: Power, sensors, networking → See [Hardware Docs](../hardware/hardware_hub.md)
- **Software**: ROS 2, agent, skills → See [Software Docs](../software/software_hub.md)
- **Networking**: DDS, WebRTC, WiFi → See [Networking Docs](../networking/networking_hub.md)

### 2. Gather Information
```bash
# Check system logs
journalctl -xe

# ROS 2 node status
ros2 node list
ros2 node info /node_name

# Network connectivity
ping 192.168.10.103  # GO2 robot
ping 192.168.10.1    # Router

# GPU status (on Thor)
jtop
```

### 3. Apply Solution
- Follow relevant troubleshooting guide
- Document resolution steps
- Update this index if new pattern found

### 4. Verify Resolution
- Test the fixed functionality
- Monitor for recurrence
- Update telemetry/alerting if needed

## Steps
1. Identify affected subsystem using diagnostic workflow above
2. Gather diagnostic information (logs, topic status, network connectivity)
3. Follow relevant troubleshooting guide from Active Guides section
4. Verify resolution and document lessons learned

## Validation
- [ ] Each troubleshooting guide tested on current build
- [ ] Diagnostic commands validated and produce expected output
- [ ] Resolution procedures documented with verification steps
- [ ] Cross-links to related docs verified

## See Also
- [LLM Backend Validation](../software/llm/llm_backend_validation.md) — Runtime backend health checks
- [DDS Direct Test](../networking/dds_direct_test.md) — ROS 2 connectivity validation
- [WebRTC Direct Test](../networking/webrtc_direct_test.md) — Robot WiFi validation
- [Network Topologies](../hardware/network_power_topologies.md) — Wiring and connectivity reference
- [Start Script](../software/start_script_reference.md) — Startup sequence and validation

## References
- [Documentation Root](../index.md)
- [Hardware Index](../hardware/hardware_hub.md)
- [Software Index](../software/software_hub.md)
- [Networking Index](../networking/networking_hub.md)
- ROS 2 Troubleshooting: https://docs.ros.org/en/humble/Tutorials/Beginner-CLI-Tools.html
