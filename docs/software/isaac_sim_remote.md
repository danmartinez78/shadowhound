---
tags: [software, simulation]
status: draft
related: []
summary: >
  Configure Isaac Sim for remote streaming into the ShadowHound development environment.
---

# Isaac Sim Remote Streaming

## Purpose
Provide a repeatable process for connecting NVIDIA Isaac Sim running on a remote GPU host to the ShadowHound ROS 2 workspace.

## Prerequisites
- Remote workstation with NVIDIA Isaac Sim installed and accessible via SSH.
- ShadowHound development workstation with ROS 2 Humble and Omniverse streaming client packages.
- Network path with sufficient bandwidth (≥ 50 Mbps) and latency under 100 ms.

## Steps
1. **Prepare the Remote Host**
   1. Update Isaac Sim packages and confirm licensing.
   2. Configure the streaming server:
      ```bash
      ./isaac-sim.sh --headless --/omni/streaming/enabled=true \
          --/app/content/emptyStage.usd
      ```
2. **Expose Streaming Ports**
   - Open TCP/UDP ports `47995-48005` on the remote firewall.
   - Verify connectivity from the local workstation using `nc -zv <remote-ip> 47995`.
3. **Launch the ROS 2 Bridge**
   ```bash
   source-ws
   ros2 launch shadowhound_bringup isaac_bridge.launch.py \
       remote_ip:=<remote-ip> \
       stream_fps:=30
   ```
4. **Validate Video Feed**
   - Start the Omniverse Streaming Client locally and point to the remote IP.
   - Confirm telemetry topics publish using `ros2 topic echo /shadowhound/sim/status`.

## Validation
- [ ] Streaming client renders Isaac Sim viewport with <100 ms latency.
- [ ] ROS 2 bridge publishes `/shadowhound/sim/status` without errors.
- [ ] Networking checklist in [Networking Index](../networking/networking_hub.md) is satisfied.

## References
- NVIDIA Isaac Sim Streaming Docs
- [Autodoc Index](./autodoc/_index.md)
- [Software Index](../software/software_hub.md)
