---
tags: [networking/testing, dds, ros2, guide]
status: draft
related: [networking/webrtc_direct_test, hardware/network_power_topologies, troubleshooting/startup_validation]
summary: >
  Validate CycloneDDS (Ethernet) transport and basic ROS 2 communication without WebRTC.
---

# ROS 2 DDS Direct Test

## Purpose
Validate the ROS 2 DDS transport path over Ethernet before running full ShadowHound bringup. This exercises the go2_ros2_sdk driver and confirms topics flow over CycloneDDS without relying on WebRTC.

## Prerequisites
- Robot reachable over Ethernet or LAN where DDS multicast is allowed.
- ROS 2 Humble environment available in the devcontainer.
- Network allows UDP 7400-7500 for CycloneDDS discovery/data.

## Steps
1. Ensure CONN_TYPE is set to `cyclonedds` (or unset) and RMW uses CycloneDDS.
2. Launch the Unitree SDK driver normally.
3. Verify basic topics and run a couple of quick checks.

### Environment
```bash
# Optional: make DDS explicit (default is CycloneDDS)
export CONN_TYPE=cyclonedds
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
# Optional: pin ROS_DOMAIN_ID for isolation
export ROS_DOMAIN_ID=0
```

### Launch Driver
```bash
cd /workspaces/shadowhound
source /opt/ros/humble/setup.bash
# If you've built the workspace locally, source it too
[ -f install/setup.bash ] && source install/setup.bash

# Use the upstream/dimos launch file via helper script
./scripts/test_dds_direct.sh
```

### Quick Checks
- List topics and confirm GO2 data is present:
```bash
ros2 topic list | grep -E "go2_|camera|imu|odom"
```
- Echo state once:
```bash
ros2 topic echo /go2_states --once
```

## Troubleshooting
- If topics don't appear:
  - Verify Ethernet connectivity to robot bridge.
  - Check firewall rules for UDP 7400-7500.
  - Ensure only one ROS_DOMAIN_ID is in use across machines.

## Validation
- [ ] Driver launches without errors
- [ ] `/go2_states` publishes
- [ ] Camera/IMU topics appear (if enabled)
- [ ] No WebRTC-only topics required

## See Also
- [[networking/webrtc_direct_test|WebRTC Direct Test]] - WiFi alternative with camera streaming
- [[hardware/network_power_topologies|Network Topologies]] - Router and LAN setup for DDS
- [[troubleshooting/startup_validation|Startup Validation]] - Common launch issues

## References
- [[networking/README|Networking Overview]]
- [[software/scripts|Script Catalog]]
