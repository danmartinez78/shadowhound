# ShadowHound + DIMOS Quick Start

**5-Minute Guide to Getting Started**

## 📋 Prerequisites

- ✅ Devcontainer running (ROS2 Humble)
- ✅ ROBOT_IP environment variable set
- ✅ OPENAI_API_KEY configured (for agents)

## 🚀 Quick Setup

### 1. Clone ShadowHound with Submodules (First Time)

```bash
# Clone with all submodules (DIMOS + Go2 SDK)
git clone --recurse-submodules https://github.com/danmartinez78/shadowhound.git
cd shadowhound

# OR if already cloned, initialize submodules
git submodule update --init --recursive

# Install DIMOS Python package
pip3 install -e src/dimos-unitree

# Install ROS dependencies
rosdep install --from-paths src --ignore-src -y

# Build workspace
colcon build --symlink-install
source install/setup.bash
```

**Note:** As of October 2025, ShadowHound uses **git submodules** (not vcs/vcstool). DIMOS and the Go2 SDK are included as nested submodules.

### 2. Test DIMOS Integration

```python
# In Python REPL or script
from dimos.robot.unitree import UnitreeGo2, UnitreeROSControl

# Mock robot (no hardware needed)
robot = UnitreeGo2(
    ros_control=UnitreeROSControl(mock_connection=True),
    disable_video_stream=True
)

print("✅ DIMOS integration working!")
```

### 3. Run DIMOS Examples

```bash
# Navigate to DIMOS tests
cd src/dimos-unitree/tests

# Test basic robot control (mock mode)
python3 test_robot.py

# Test agent with FastAPI interface
# (requires OPENAI_API_KEY)
python3 test_unitree_agent_queries_fastapi.py
```

## 🤖 Using DIMOS with Real Robot

```bash
# Set environment
export ROBOT_IP=192.168.1.103
export CONN_TYPE=webrtc
export OPENAI_API_KEY=sk-...

# Run DIMOS robot test
cd src/dimos-unitree/tests
python3 run_go2_ros.py
```

## 📝 Creating a Custom ShadowHound Skill

```python
# File: src/shadowhound_skills/shadowhound_skills/patrol.py

from dimos.skills.skills import AbstractRobotSkill
from pydantic import Field

class PatrolArea(AbstractRobotSkill):
    """Patrol predefined waypoints."""
    
    name: str = "PatrolArea"
    description: str = "Patrol an area visiting waypoints in sequence"
    
    waypoints: list[tuple[float, float]] = Field(
        description="List of (x, y) waypoints"
    )
    
    def __call__(self, **kwargs) -> dict:
        """Execute patrol."""
        waypoints = kwargs.get('waypoints', self.waypoints)
        
        for i, (x, y) in enumerate(waypoints):
            # Use DIMOS navigation
            result = self._robot.skill_library.execute(
                "NavigateToGoal",
                x=x, y=y, theta=0.0
            )
            
            if not result.get('success'):
                return {
                    'success': False,
                    'error': f'Failed at waypoint {i}'
                }
        
        return {
            'success': True,
            'data': {'waypoints_visited': len(waypoints)}
        }
```

## 🧪 Testing Custom Skill

```python
# File: test_patrol.py

from dimos.robot.unitree import UnitreeGo2, UnitreeROSControl
from shadowhound_skills import PatrolArea

# Initialize robot
robot = UnitreeGo2(
    ros_control=UnitreeROSControl(mock_connection=True),
    disable_video_stream=True
)

# Add custom skill
robot_skills = robot.get_skills()
robot_skills.add(PatrolArea)
robot_skills.create_instance("PatrolArea", robot=robot)

# Execute
result = robot_skills.execute(
    "PatrolArea",
    waypoints=[(1.0, 1.0), (2.0, 1.0), (2.0, 2.0), (1.0, 2.0)]
)

print(result)
```

## 🤖 Using with Agent

```python
from dimos.agents import OpenAIAgent

# Robot already has skills library
agent = OpenAIAgent(
    dev_name="ShadowHoundAgent",
    tools=robot_skills.get_tools(),  # Auto-generates tool definitions
    model="gpt-4-turbo"
)

# Agent can now call skills
response = agent.query("Patrol the perimeter")
print(response)
```

## 📚 Common DIMOS Patterns

### Robot Control
```python
# Direct control
robot.move(distance=1.0, speed=0.5)
robot.rotate(angle=1.57)  # 90 degrees
robot.webrtc_req(api_id=1006)  # RecoveryStand

# Get state
position, rotation = robot.get_pose()
```

### Available DIMOS Skills
```python
from dimos.skills.navigation import NavigateToGoal, NavigateWithText, GetPose
from dimos.skills.visual_navigation_skills import FollowHuman
from dimos.skills import KillSkill, Speak

# Add to robot
robot_skills = robot.get_skills()
robot_skills.add(NavigateToGoal)
robot_skills.add(Speak)

# Execute
robot_skills.execute("NavigateToGoal", x=2.0, y=1.0, theta=0.0)
robot_skills.execute("Speak", text="Mission complete")
```

### Video Streams (RxPY)
```python
# Get camera stream
video_stream = robot.get_ros_video_stream(fps=10)

# Subscribe to frames
def on_frame(frame):
    print(f"Got frame: {frame.shape}")

video_stream.subscribe(on_frame)
```

## 🔧 Troubleshooting

### DIMOS Not Found
```bash
# Make sure it's installed
pip3 list | grep dimos

# If not, install it
pip3 install -e src/dimos-unitree
```

### Can't Connect to Robot
```bash
# Check environment variables
echo $ROBOT_IP
echo $CONN_TYPE

# Verify robot is on network
ping $ROBOT_IP

# Check ROS2 topics
ros2 topic list
```

### Import Errors
```bash
# Source workspace
source install/setup.bash

# Check Python path
python3 -c "import sys; print('\n'.join(sys.path))"
```

## 📖 Learn More

- **Full Architecture**: `docs/project.md`
- **Integration Plan**: `docs/DIMOS_INTEGRATION.md`
- **DIMOS Examples**: `src/dimos-unitree/tests/`
- **DIMOS Docs**: https://github.com/dimensionalOS/dimos-unitree

## 🎯 Next Steps

1. ✅ Complete DIMOS integration (Phase 0)
2. ⏭️ Implement first custom skill (PatrolArea)
3. ⏭️ Test on mock robot
4. ⏭️ Test on real hardware
5. ⏭️ Build mission agent

---

**Questions?** Check `docs/project.md` for detailed architecture and patterns.
