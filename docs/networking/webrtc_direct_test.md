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

## Steps
1. Generate or refresh the `.env.webrtc_test` configuration using the interactive helper.
2. Launch the Unitree SDK driver in WebRTC mode to establish the media and control channels.
3. Send validation commands from a separate terminal to confirm bidirectional communication.
4. Capture any anomalies in the **Troubleshooting** section and update this page after remediation.

### Configuration Helper
```bash
./scripts/setup_webrtc_test.sh
```
The script prompts for the robot IP, validates connectivity, and writes `.env.webrtc_test` with:
- `GO2_IP` — Wi-Fi address of the robot.
- `CONN_TYPE=webrtc` — Enables WebRTC transport.
- `ROS_DOMAIN_ID=0` — Isolates the ROS graph for testing.
- `RMW_IMPLEMENTATION` — Sets CycloneDDS for compatibility.

### Launch Sequence
1. **Terminal 1 – Start the driver**
   ```bash
   ./scripts/test_webrtc_direct.sh
   ```
2. **Terminal 2 – Exercise commands**
   ```bash
   source .shadowhound_env
   ./scripts/test_commands.sh sit
   ./scripts/test_commands.sh stand
   ./scripts/test_commands.sh wave
   ```

### Troubleshooting
- **Robot not reachable** — Re-run the setup helper to confirm IP and network reachability.
- **Missing `.env.webrtc_test`** — The helper recreates the file automatically.
- **Incorrect configuration** — Run the helper again; it overwrites the environment safely.

## Validation
- [ ] `.env.webrtc_test` regenerated for the current robot IP and committed to your local notes if values changed.
- [ ] `./scripts/test_webrtc_direct.sh` reports a healthy WebRTC connection without errors.
- [ ] Mission command scripts trigger the expected sit/stand/wave behaviors (or mock confirmations in simulation).

## References
- [[software/scripts|Script Catalog]]
- [[networking/README|Networking Overview]]
- [[troubleshooting/README|Troubleshooting Hub]]
