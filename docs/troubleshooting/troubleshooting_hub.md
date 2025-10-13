---
tags: [troubleshooting, index]
status: active
related: [troubleshooting/startup_validation, troubleshooting/quick_start_robot_test, software/llm/llm_backend_validation]
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
- **[[troubleshooting/startup_validation|Startup Validation Flow]]** — Two-layer LLM backend validation (pre-flight checks + runtime)
  - Start script pre-flight checks (fail fast)
  - Mission agent runtime validation
  - Ollama and OpenAI backend validation

### Robot Testing
- **[[troubleshooting/quick_start_robot_test|Quick Start: Robot Testing]]** — Complete testing procedure with local LLM
  - GPU setup and monitoring (jtop)
  - Ollama configuration (phi4:14b)
  - End-to-end robot command testing
  - Performance validation

## Common Issues & Solutions

### LLM Backend Issues
**Symptom**: Mission agent fails to start or hangs  
**Solution**: See [[troubleshooting/startup_validation|Startup Validation]] for pre-flight checks

**Symptom**: Slow or no responses from LLM  
**Solution**: Check backend configuration in [[software/llm/llm_backend_validation|Backend Validation]]

### Robot Connectivity Issues
**Symptom**: Robot not responding to commands  
**Solution**: 
1. Verify DDS connectivity: [[networking/dds_direct_test|DDS Direct Test]]
2. Check WebRTC connection: [[networking/webrtc_direct_test|WebRTC Direct Test]]
3. Validate network topology: [[hardware/network_power_topologies|Network Topologies]]

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
- **Hardware**: Power, sensors, networking → See [[hardware/hardware_hub|Hardware Docs]]
- **Software**: ROS 2, agent, skills → See [[software/software_hub|Software Docs]]
- **Networking**: DDS, WebRTC, WiFi → See [[networking/networking_hub|Networking Docs]]

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
- [[../software/llm/llm_backend_validation|LLM Backend Validation]] — Runtime backend health checks
- [[../networking/dds_direct_test|DDS Direct Test]] — ROS 2 connectivity validation
- [[../networking/webrtc_direct_test|WebRTC Direct Test]] — Robot WiFi validation
- [[../hardware/network_power_topologies|Network Topologies]] — Wiring and connectivity reference
- [[../software/start_script_reference|Start Script]] — Startup sequence and validation

## References
- [[../index|Documentation Root]]
- [[hardware/hardware_hub|Hardware Index]]
- [[software/software_hub|Software Index]]
- [[networking/networking_hub|Networking Index]]
- ROS 2 Troubleshooting: https://docs.ros.org/en/humble/Tutorials/Beginner-CLI-Tools.html
