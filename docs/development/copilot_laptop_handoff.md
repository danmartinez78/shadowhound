---
tags: [development, workflow]
status: draft
related: [project_overview/status_2025-10-12]
summary: >
  Quick handoff guide for continuing work on the laptop host with the devcontainer and ensuring host path sync.
---

# Copilot Laptop Handoff

## Purpose
Provide fast, reliable steps to pull the current branch on the laptop and continue work while avoiding devcontainer vs host path confusion.

## Prerequisites
- Laptop has the workspace cloned at `/home/daniel/shadowhound/`
- Devcontainer set up for editing at `/workspaces/shadowhound/`

## Steps
1. Pull the branch on laptop host
   ```bash
   cd /home/daniel/shadowhound
   git fetch origin
   git checkout -B docs/wiki-and-cleanup origin/docs/wiki-and-cleanup
   git submodule update --init --recursive
   ```
2. Verify path sync reminder
   - Edit in: `/workspaces/shadowhound` (devcontainer)
   - Code runs from: `/home/daniel/shadowhound` (host)
   - If you see mismatched paths in errors, confirm both are updated.
3. Rebuild or source if needed
   ```bash
   # Only if ROS 2 packages changed
   cb
   source-ws
   ```
4. Try connectivity scripts
   ```bash
   # DDS (CycloneDDS/Ethernet)
   ./scripts/test_dds_direct.sh

   # WebRTC (WiFi)
   ./scripts/setup_webrtc_test.sh   # optional helper to create .env.webrtc_test
   ./scripts/test_webrtc_direct.sh
   ```

## Notes
- WebRTC canonical guide: `docs/networking/webrtc_direct_test.md`
- DDS canonical guide: `docs/networking/dds_direct_test.md`
- If a script cannot find the launch file, ensure submodules are synced and the workspace is built.

## Validation
- [ ] Branch `docs/wiki-and-cleanup` is checked out on laptop
- [ ] Submodules synced and ROS environment sourced
- [ ] DDS and WebRTC scripts execute as expected

