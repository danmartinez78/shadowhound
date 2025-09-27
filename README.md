# ShadowHound
_Last updated: 2025-09-26_

ShadowHound is a Unitree GO2 project that pairs **LLM/VLM/VLA planning** with a **classic ROS 2 skill stack**. We start laptop‑first over **WebRTC**, then run fully **onboard Jetson AGX Thor**. The workspace is managed as a **meta‑repo** with `vcstool`, flattening `go2_ros2_sdk` as a first‑class dependency.

- Project context: see **project_context.md**
- Agent guide for Copilot/VS Code: see **AGENTS.md**

## Quickstart (native)
```bash
vcs import src < shadowhound.repos
rosdep install --from-paths src -iry
colcon build --symlink-install
source install/setup.bash
ros2 launch shadowhound_bringup shadowhound_bringup.launch.py profile:=laptop_webrtc backend:=cloud
```

## Containers
```bash
cp .env.example .env

# Laptop (WebRTC + cloud)
docker compose --profile laptop up --build

# Thor (Ethernet + local)
docker compose --profile thor up --build
```
> Ensure NVIDIA Container Runtime on Thor and that your JetPack version matches `docker/Dockerfile.thor`.

## Repos
- `dimos-unitree` (your fork; minimal patches)
- `go2_ros2_sdk` (pinned, active)
- `shadowhound_utils` (Skill registry, RobotIface, QoS, thumbnails)
- `shadowhound_mission_agent` (planner/orchestrator)
- (later) media, voice, and policy packages

## Status
- Meta‑repo scaffolded (launch, configs, CI).
- Dockerfiles + compose ready.
- `RobotIface` shim in place; skills connect here.
- Mission agent skeleton responds to `/shadowhound/instruction` (“spin”), to verify end‑to‑end wiring.

## Optional: Enabling Torch / Detic Models
For a fast initial devcontainer build the vendored `Detic` model stack is ignored via a `COLCON_IGNORE` file:

`src/dimos-unitree/dimos/models/Detic/COLCON_IGNORE`

Remove that file if you need advanced perception / TorchScript export utilities. Then inside the container install Torch (Python) and the C++ libtorch distribution if you need C++/TorchScript binaries:

```bash
pip install torch --index-url https://download.pytorch.org/whl/cpu
curl -L https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-latest.zip -o /tmp/libtorch.zip \
	&& unzip /tmp/libtorch.zip -d /opt \
	&& echo 'export Torch_DIR=/opt/libtorch/share/cmake/Torch' >> ~/.bashrc
```

Reopen the shell (or `source ~/.bashrc`) and rebuild:
```bash
colcon build --symlink-install
```
If you only require Python inference in pure Python nodes, the `pip install torch` step alone is sufficient; keep the `COLCON_IGNORE` file to avoid lengthy C++ model build steps.
