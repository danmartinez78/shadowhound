---
tags: [software, setup]
status: draft
related: []
summary: >
  Prepare a ShadowHound ROS 2 development workstation with essential tooling.
---

# ROS 2 Workstation Setup

## Purpose
Document the baseline workstation setup for developing and testing ShadowHound ROS 2 packages.

## Prerequisites
- Ubuntu 22.04 LTS with sudo privileges.
- Stable internet connection for dependency installation.
- Access to GitHub credentials for cloning private repositories.

## Steps
1. **Install ROS 2 Humble**
   ```bash
   sudo apt update && sudo apt install -y curl gnupg2 lsb-release
   sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | \
       gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
       http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros2.list
   sudo apt update && sudo apt install -y ros-humble-desktop python3-rosdep
   sudo rosdep init || true
   rosdep update
   ```
2. **Configure Workspace Utilities**
   ```bash
   echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
   mkdir -p ~/shadowhound_ws/src
   cd ~/shadowhound_ws
   git clone https://github.com/shadowhound-robotics/shadowhound.git src/shadowhound
   ```
3. **Install Project Dependencies**
   ```bash
   cd ~/shadowhound_ws/src/shadowhound
   rosdep install --from-paths src --ignore-src -r -y
   pip install -r requirements.txt || true
   ```
4. **Build and Validate**
   ```bash
   cd ~/shadowhound_ws
   colcon build --symlink-install
   source install/setup.bash
   ros2 pkg list | grep shadowhound
   ```

## Validation
- [ ] `colcon build` completes without errors.
- [ ] `ros2 pkg list` shows ShadowHound packages.
- [ ] Obsidian vault opens and docs render as expected.

## References
- ROS 2 Humble Installation Guide
- [[software/software_hub|Software Index]]
- [[../index|Vault Index]]
