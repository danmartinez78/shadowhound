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


## Wiring dimos-unitree bring-up
This workspace **includes** the `dimos-unitree` driver in the bring-up launch.

- We assume a launch file at: `share/dimos_unitree/launch/bringup.launch.py` with an argument like `comm_mode := webrtc|ethernet`.
- If your fork uses a different filename or arg names, edit:
  `launch/shadowhound_bringup.launch.py` → `include_dimos_driver()`.

### WebRTC Development (Laptop-first)
1. Ensure the GO2 and your laptop are on the same Wi‑Fi and that WebRTC permissions are granted per the `dimos-unitree` README.
2. Launch:
   ```bash
   ros2 launch shadowhound_bringup shadowhound_bringup.launch.py profile:=laptop_webrtc backend:=cloud
   ```
3. In another terminal:
   ```bash
   ros2 topic list
   rviz2
   ```

### Thor (Ethernet) Runtime
1. Set static IPs (e.g., GO2 `192.168.50.2`, Thor `192.168.50.4`) and plug Ethernet.
2. Launch:
   ```bash
   ros2 launch shadowhound_bringup shadowhound_bringup.launch.py profile:=thor_ethernet backend:=local llm_endpoint:=http://127.0.0.1:8000
   ```

> Tip: If Wi‑Fi multicast is flaky for RViz, consider a DDS discovery server or pin DDS to the right NIC.
