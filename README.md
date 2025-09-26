# ShadowHound (Meta-Repo)
_Last updated: 2025-09-26_

This is the **top-level workspace** for ShadowHound. It treats your fork of **dimos-unitree** and the active **go2_ros2_sdk** as **first-class dependencies** via **vcstool**.
We keep a thin compatibility layer so agents are backend-agnostic, and we support two profiles:
- **Laptop-first (WebRTC)**
- **Thor (Ethernet)**

## Quickstart
```bash
git clone https://github.com/<you>/shadowhound
cd shadowhound
vcs import src < shadowhound.repos
rosdep install --from-paths src -iry
colcon build --symlink-install
source install/setup.bash
```

## Profiles
```bash
# Laptop-first (WebRTC)
ros2 launch shadowhound_bringup bringup.launch.py profile:=laptop_webrtc backend:=cloud

# Thor (Ethernet)
ros2 launch shadowhound_bringup bringup.launch.py profile:=thor_ethernet backend:=local llm_endpoint:=http://127.0.0.1:8000
```
