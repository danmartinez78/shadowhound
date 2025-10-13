---
tags: [project_overview/reference, commands, operations]
status: active
related: []
summary: >
  Command cheat sheet and operational shortcuts for ShadowHound maintainers.
aliases: [commands, cheat-sheet]
---

# Quick Reference

## Purpose
Aggregate frequently used commands, environment tweaks, and emergency actions so operators can respond quickly without searching multiple documents.

## Prerequisites
- Repository workspace initialized with the DIMOS and ShadowHound packages.
- Awareness of the launch tooling outlined in [[software/scripts|Script Catalog]].
- Environment variables configured according to [[software/environment_configuration|Environment Configuration Guide]].

## Steps
1. Use the command tables below to execute common maintenance, launch, and diagnostic workflows.
2. Apply the environment variable presets that match your deployment scenario.
3. Follow the troubleshooting aids when encountering build, git, or networking issues.
4. Update the cheat sheet when new scripts or workflows become standard operating procedure.

### Common Commands
```bash
# Repository updates
scripts/update_repos.sh
scripts/update_repos.sh --auto

# Topic checks
python3 scripts/check_topics.py
./test_topic_visibility.sh

# Launch profiles
./start.sh --dev
./start.sh --prod
./start.sh --dev --mock
./start.sh --dev --agent-only
```

### Build & Source
```bash
# Quick build commands (from devcontainer aliases)
cb              # colcon build --symlink-install
cbr             # colcon build --symlink-install && source install/setup.bash
source-ws       # source install/setup.bash

# Specific packages
colcon build --packages-select shadowhound_mission_agent --symlink-install
colcon build --packages-select shadowhound_skills shadowhound_bringup --symlink-install

# Manual setup
source /opt/ros/humble/setup.bash
source install/setup.bash
export PYTHONPATH="/workspaces/shadowhound/src/dimos-unitree:$PYTHONPATH"
```

### Git Operations
```bash
git status
git log --oneline --graph -5
git submodule update --init --remote
```

### Environment Variables
```bash
# Robot connection
export ROBOT_IP=192.168.1.103
export CONN_TYPE=webrtc
export MOCK_ROBOT=false

# ROS configuration
export ROS_DOMAIN_ID=42
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# LLM configuration
export OPENAI_API_KEY=sk-...
export OPENAI_MODEL=gpt-4o
```

### Troubleshooting Snippets
- **No robot topics:**
  ```bash
  ros2 topic list | grep camera
  # Check DIMOS connection
  cd src/dimos-unitree && python3 tests/test_robot.py
  ```
- **Submodule drift:**
  ```bash
  cd src/dimos-unitree
  git submodule update --init --remote --recursive
  ```
- **Build failures:**
  ```bash
  rm -rf build install log
  rosdep-install  # or: rosdep install --from-paths src --ignore-src -r -y
  cb              # or: colcon build --symlink-install
  ```
- **Update conflicts:**
  ```bash
  git stash push -m "local changes"
  git pull
  git stash pop
  ```

### Emergency Reset
```bash
git fetch origin
git reset --hard origin/main
git submodule update --init --remote --recursive
rm -rf build install log
./start.sh --dev --auto-update
```

## Validation
- [x] Command snippets verified against the current repository structure.
- [x] Environment variable recommendations align with the active deployment templates.
- [x] Troubleshooting steps reflect the latest known issues and resolutions.
- [x] Updated to use devcontainer aliases (cb, cbr, source-ws, rosdep-install).
- [x] Updated to reflect DIMOS integration and current package structure.

## See Also
- [[project_overview/project_overview_hub|Project Overview Hub]] - Planning and operations
- [[project_overview/agent_quick_reference|Agent Quick Reference]] - Agent-specific commands
- [[project_overview/quick_start|Quick Start]] - Rapid launch checklist
- [[software/configuration/environment_variables|Environment Variables]] - Complete reference
- [[troubleshooting/troubleshooting_hub|Troubleshooting]] - Diagnostic workflows

## References
- [[project_overview/project_overview_hub|Documentation Root]]
- [[software/software_hub|Software Hub]]
- [[development/development_hub|Development Hub]]
