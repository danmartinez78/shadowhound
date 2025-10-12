---
tags: [project, setup]
status: draft
related: []
summary: >
  Snapshot of the DIMOS integration status as of October 4, 2025, including repository layout and next steps.
---

# Project Setup Status (October 4, 2025)

## Purpose
Document the initial DIMOS integration milestone, including repository structure, verification steps, and follow-up actions for continuing the ShadowHound bring-up.

## Prerequisites
- Repository cloned inside the development container with Git submodule support enabled.
- Access to the DIMOS and go2_ros2_sdk forks referenced in `shadowhound.repos`.
- Ability to run shell commands in the workspace root.

## Steps
1. Confirm `shadowhound.repos` points to the expected forks and branches.
2. Import DIMOS dependencies using `vcs import` and initialize nested submodules.
3. Execute the verification commands below to ensure repositories and submodules are on the correct revisions.
4. Advance to the next setup tasks after recording progress in the **Validation** section.

### Repository Structure
```
/workspaces/shadowhound/
├── src/
│   ├── dimos-unitree/
│   │   └── dimos/robot/unitree/external/
│   │       ├── go2_ros2_sdk/      # Fork on robodan_dev
│   │       └── go2_webrtc_connect/
│   ├── shadowhound_bringup/
│   ├── shadowhound_skills/
│   └── shadowhound_mission_agent/
├── scripts/setup_dimos.sh
├── shadowhound.repos
└── docs/
```

### Verification Commands
```bash
cd src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk
git remote -v      # Expect fork URL
git branch         # Expect robodan_dev

cd /workspaces/shadowhound/src/dimos-unitree
git submodule status
```
Expected output snippet:
```
+6c0551b... dimos/robot/unitree/external/go2_ros2_sdk (robodan_dev)
 5235733a... dimos/robot/unitree/external/go2_webrtc_connect (heads/master)
```

### Next Steps
1. Install DIMOS Python package:
   ```bash
   pip3 install -e src/dimos-unitree
   ```
2. Install ROS dependencies and requirements for `go2_ros2_sdk`.
3. Build the workspace with `colcon build --symlink-install` and source the setup file.
4. Create bringup and skills packages if they are still pending.

## Validation
- [ ] `shadowhound.repos` cloned with expected fork URLs and branches.
- [ ] Submodule status matches the target revisions.
- [ ] Follow-up tasks captured in the roadmap or package-specific backlogs.

## References
- [DIMOS Integration Quick Start](software/dimos_quick_start.md)
- [Script Catalog](software/scripts.md)
- [Project Roadmap](project_overview/roadmap.md)
