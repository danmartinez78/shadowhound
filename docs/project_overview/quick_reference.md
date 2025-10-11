---
tags: [project, reference]
status: draft
related: []
summary: >
  Command cheat sheet and operational shortcuts for ShadowHound maintainers.
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
./scripts/update_repos.sh
./scripts/update_repos.sh --auto

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
colcon build --packages-select shadowhound_mission_agent --symlink-install
colcon build --packages-select go2_interfaces unitree_go go2_robot_sdk --symlink-install
source /opt/ros/humble/setup.bash
source install/setup.bash
export PYTHONPATH="$HOME/shadowhound/src/dimos-unitree:$PYTHONPATH"
```

### Git Operations
```bash
git status
git log --oneline --graph -5
git submodule update --init --remote
```

### Environment Variables
```bash
export GO2_IP=192.168.10.167
export ROS_DOMAIN_ID=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export OPENAI_API_KEY=sk-...
```

### Troubleshooting Snippets
- **No robot topics:**
  ```bash
  ros2 topic list | grep go2
  ros2 launch go2_robot_sdk robot.launch.py
  ```
- **Submodule drift:**
  ```bash
  cd src/dimos-unitree
  git submodule update --remote --merge
  ```
- **Build failures:**
  ```bash
  rm -rf build install log
  colcon build --symlink-install
  rosdep install --from-paths src --ignore-src -r -y
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
git reset --hard origin/feature/dimos-integration
git submodule update --init --remote
rm -rf build install log
./start.sh --dev --auto-update
```

## Validation
- [ ] Command snippets verified against the current repository structure.
- [ ] Environment variable recommendations align with the active deployment templates.
- [ ] Troubleshooting steps reflect the latest known issues and resolutions.

## References
- [[software/scripts|Script Catalog]]
- [[software/start_script_reference|Start Script Reference]]
- [[software/environment_configuration|Environment Configuration Guide]]
