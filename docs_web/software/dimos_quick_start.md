---
tags: [software, dimos]
status: draft
related: []
summary: >
  Fast-start workflow for integrating the DIMOS framework with ShadowHound, including workspace setup, skill authoring, and testing.
---

# DIMOS Integration Quick Start

## Purpose
Provide a concise walkthrough for importing DIMOS into the ShadowHound workspace, exercising the integration, and extending it with custom skills.

## Prerequisites
- Development container running with ROS 2 Humble installed.
- Access to the DIMOS repositories listed in `shadowhound.repos`.
- OpenAI API key configured when testing agent integrations.

## Steps
1. Import DIMOS and the Unitree SDK dependencies via `vcs` using the provided `.repos` file.
2. Install Python and ROS dependencies, then build the workspace with colcon.
3. Validate the integration using DIMOS tests in both mock and hardware modes.
4. Author and register custom skills, then exercise them through DIMOS agents as needed.

### Import Repositories
```bash
cat > shadowhound.repos <<'YAML'
repositories:
  dimos-unitree:
    type: git
    url: https://github.com/dimensionalOS/dimos-unitree.git
    version: main
  go2_ros2_sdk:
    type: git
    url: https://github.com/dimensionalOS/go2_ros2_sdk.git
    version: prod
YAML

vcs import src < shadowhound.repos
pip3 install -e src/dimos-unitree
rosdep install --from-paths src --ignore-src -y
colcon build --symlink-install
source install/setup.bash
```

### Validate Integration
```python
from dimos.robot.unitree import UnitreeGo2, UnitreeROSControl

robot = UnitreeGo2(
    ros_control=UnitreeROSControl(mock_connection=True),
    disable_video_stream=True,
)
print("✅ DIMOS integration working!")
```

### Exercise DIMOS Tests
```bash
cd src/dimos-unitree/tests
python3 test_robot.py                        # Mock mode validation
python3 test_unitree_agent_queries_fastapi.py  # Agent integration (requires OPENAI_API_KEY)
```

### Real Robot Session
```bash
export ROBOT_IP=192.168.1.103
export CONN_TYPE=webrtc
export OPENAI_API_KEY=sk-...
python3 run_go2_ros.py
```

### Author a Custom Skill
```python
from dimos.skills.skills import AbstractRobotSkill

class PatrolArea(AbstractRobotSkill):
    name = "PatrolArea"
    description = "Patrol predefined waypoints"

    def __call__(self, **kwargs):
        waypoints = kwargs.get("waypoints", [])
        for index, (x, y) in enumerate(waypoints):
            result = self._robot.skill_library.execute("NavigateToGoal", x=x, y=y, theta=0.0)
            if not result.get("success"):
                return {"success": False, "error": f"Failed at waypoint {index}"}
        return {"success": True, "data": {"waypoints_visited": len(waypoints)}}
```

## Validation
- [ ] DIMOS repositories cloned and installed using `shadowhound.repos`.
- [ ] Workspace builds successfully after importing DIMOS dependencies.
- [ ] DIMOS tests (mock and hardware) run without errors.
- [ ] Custom skill registration verified via DIMOS agent or direct execution.

## References
- [Script Catalog](scripts.md)
- [Environment Configuration Guide](environment_configuration.md)
- [Hardware Stack Overview](hardware/README.md)
