---
tags: [networking, testing]
status: draft
related: []
summary: >
  Run the WebRTC direct test workflow to validate connectivity between the workstation and the Unitree Go2.
---

# WebRTC Direct Test

## Purpose
Validate the WebRTC transport path before a full ShadowHound deployment by exercising the SDK driver and mission command scripts end to end.

## Prerequisites
- [[software/ros2_setup|ROS 2 Workstation Setup]] completed inside the development container.
- Robot reachable over Wi-Fi with its IP address available (or plan to rerun setup to update it).
- Access to the `scripts/` utilities included with the repository checkout.
 - Environment configured using your standard `.env` (see [[software/environment_configuration|Environment Configuration Guide]]). No bespoke per-test `.env` files are required.

## Steps
1. Launch the Unitree SDK driver in WebRTC mode to establish the media and control channels.
2. Send validation commands from a separate terminal to confirm bidirectional communication.
3. Capture any anomalies in the **Troubleshooting** section and update this page after remediation.

### Environment Notes
- Ensure `GO2_IP` is set appropriately in your standard environment.
- Set `CONN_TYPE=webrtc` when using WebRTC transport.
- `RMW_IMPLEMENTATION=rmw_cyclonedds_cpp` is recommended.

### Launch Sequence
1. **Terminal 1 – Start the driver**
   ```bash
   ./scripts/test_webrtc_direct.sh
   ```
2. **Terminal 2 – Exercise commands**
   ```bash
   ./scripts/test_commands.sh sit
   ./scripts/test_commands.sh stand
   ./scripts/test_commands.sh wave
   ```

### Troubleshooting
- **Robot not reachable** — Confirm IP and network reachability.
- **Incorrect configuration** — Review your standard environment variables.

## Validation
- [ ] `./scripts/test_webrtc_direct.sh` reports a healthy WebRTC connection without errors.
- [ ] Mission command scripts trigger the expected sit/stand/wave behaviors (or mock confirmations in simulation).

## References
- [[software/scripts|Script Catalog]]
- [[networking/README|Networking Overview]]
- [[troubleshooting/README|Troubleshooting Hub]]
