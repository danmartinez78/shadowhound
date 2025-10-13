---
tags: [project, legacy]
status: draft
related: []
summary: >
  Legacy documentation preserved from earlier phases for review and migration.
---

# DIMOS Integration Plan

## Purpose
Preserve historical context while signaling that this page requires verification against the current workflow.

## Prerequisites
- Review the legacy notes below to understand original assumptions and instructions.
- Cross-check commands and links with the latest tooling before execution.

## Steps
1. Read through the legacy notes captured under **Legacy Notes** and flag outdated guidance.
2. Update or replace the content with validated procedures as time permits.
3. Record verification outcomes in the validation checklist and mark follow-up tasks in the backlog.

### Legacy Notes
**Date**: 2025-10-04  
**Status**: Architecture redesign complete, ready for implementation

---

## 📋 Overview

Shadow Hound has been redesigned to leverage the **DIMOS (Dimensional Framework)** instead of building robot infrastructure from scratch. This dramatically simplifies the implementation and accelerates development.

### What Changed

**Before (v0.1.0)**: Build everything
- Custom robot interface layer
- Custom skills registry and execution engine
- Custom agent orchestration
- Custom perception pipelines
- Custom navigation integration

**After (v0.2.0)**: Build on DIMOS
- ✅ Use `UnitreeGo2` robot class (DIMOS)
- ✅ Use `UnitreeROSControl` for hardware (DIMOS)
- ✅ Use `SkillLibrary` and `AbstractRobotSkill` (DIMOS)
- ✅ Use `OpenAIAgent`, `PlanningAgent` (DIMOS)
- ✅ Use perception streams (DIMOS)
- ✅ Use local/global planners (DIMOS)
- **NEW**: Focus on mission-specific skills and behaviors

---

## 🎯 Benefits

### Development Speed
- **80% reduction** in infrastructure code
- Start with working robot control day 1
- Focus on mission logic, not plumbing

### Reliability
- Battle-tested framework from Dimensional Inc.
- Active maintenance and community
- Proven on real Unitree Go2 hardware

### Features
- WebRTC video streaming
- Object detection (Detic)
- Person tracking
- Spatial memory (ChromaDB)
- VLM integration
- Path planning (VFH + A*)
- Web interface for development

---

## 📦 New Package Structure

### Removed Packages
- ❌ `shadowhound_interfaces` - Use DIMOS types
- ❌ `shadowhound_robot` - Use `UnitreeGo2`
- ❌ Most of `shadowhound_skills` - Use DIMOS skills

### Kept/Modified Packages
- ✅ `shadowhound_bringup` - Launch files for missions
- ✅ `shadowhound_skills` - **Custom mission-specific skills only**
- ✅ `shadowhound_mission_agent` - High-level mission orchestration

---

## 🚀 Implementation Plan

### Phase 0: DIMOS Integration (Week 1)

**Goal**: Get DIMOS working in workspace

**Tasks**:
1. Create `shadowhound.repos` with DIMOS dependencies:
   ```yaml
   repositories:
     dimos-unitree:
       type: git
       url: https://github.com/dimensionalOS/dimos-unitree.git
       version: main
     go2_ros2_sdk:
       type: git
       url: https://github.com/dimensionalOS/go2_ros2_sdk.git
       version: prod
   ```

2. Install DIMOS in workspace:
   ```bash
   vcs import src < shadowhound.repos
   pip3 install -e src/dimos-unitree
   rosdep install --from-paths src --ignore-src -y
   colcon build
   ```

3. Verify integration:
   ```python
   from dimos.robot.unitree import UnitreeGo2, UnitreeROSControl
   robot = UnitreeGo2(
       ros_control=UnitreeROSControl(mock_connection=True),
       disable_video_stream=True
   )
   ```

**Exit Criteria**: Can import and initialize DIMOS classes

---

### Phase 1: Custom Skills (Week 2-3)

**Goal**: Implement ShadowHound mission skills

**Create**:
1. `shadowhound_skills/patrol.py` - PatrolArea skill
2. `shadowhound_skills/search.py` - SearchForObject skill  
3. `shadowhound_skills/investigation.py` - InvestigateAnomaly skill
4. `shadowhound_skills/reporting.py` - ReportFindings skill

**Pattern**:
```python
from dimos.skills.skills import AbstractRobotSkill

class PatrolArea(AbstractRobotSkill):
    name = "PatrolArea"
    description = "Patrol predefined waypoints"
    
    def __call__(self, waypoints, **kwargs):
        for x, y in waypoints:
            result = self._robot.skill_library.execute(
                "NavigateToGoal", x=x, y=y, theta=0.0
            )
            if not result.get('success'):
                return {'success': False, 'error': 'Nav failed'}
        return {'success': True}
```

**Testing**:
```bash
pytest src/shadowhound_skills/test/
```

**Exit Criteria**: Custom skills work with DIMOS agent

---

### Phase 2: Hardware Testing (Week 4)

**Goal**: Validate on real Go2 robot

**Tasks**:
1. Connect to robot via WebRTC
2. Test DIMOS control (move, rotate, webrtc commands)
3. Test DIMOS navigation skills
4. Test custom ShadowHound skills
5. Safety validation

**Commands**:
```bash
export ROBOT_IP=192.168.1.103
export CONN_TYPE=webrtc
export OPENAI_API_KEY=sk-...

# Run DIMOS test
python3 src/dimos-unitree/tests/test_robot.py

# Run ShadowHound mission
ros2 launch shadowhound_bringup patrol.launch.py
```

**Exit Criteria**: Can execute multi-step missions on hardware

---

### Phase 3: Mission Agent (Week 5-6)

**Goal**: Natural language mission planning

**Integrate**:
```python
from dimos.agents import OpenAIAgent
from shadowhound_skills import PatrolArea, SearchForObject

# Add custom skills to robot
robot_skills = robot.get_skills()
robot_skills.add(PatrolArea)
robot_skills.add(SearchForObject)

# Create agent with all skills
agent = OpenAIAgent(
    dev_name="ShadowHoundMissionAgent",
    tools=robot_skills.get_tools(),  # Auto-generates tool defs
    model="gpt-4-turbo"
)

# Execute mission
response = agent.query("Patrol the perimeter and search for anomalies")
```

**Exit Criteria**: Agent can decompose and execute complex missions

---

## 📚 Key DIMOS Components

### Robot Control
```python
from dimos.robot.unitree import UnitreeGo2, UnitreeROSControl

robot = UnitreeGo2(ip=ROBOT_IP, ros_control=UnitreeROSControl())
robot.move(distance=1.0, speed=0.5)
robot.rotate(angle=1.57)
robot.webrtc_req(api_id=1006)  # RecoveryStand
```

### Skills
```python
from dimos.skills.navigation import NavigateToGoal, NavigateWithText

robot_skills = robot.get_skills()
robot_skills.add(NavigateToGoal)
result = robot_skills.execute("NavigateToGoal", x=2.0, y=1.0, theta=0.0)
```

### Agents
```python
from dimos.agents import OpenAIAgent, PlanningAgent

agent = OpenAIAgent(
    dev_name="MyAgent",
    tools=robot_skills.get_tools(),
    model="gpt-4-turbo"
)
```

### Perception
```python
from dimos.perception import ObjectDetectionStream, PersonTrackingStream

# Object detection with Detic
detector = ObjectDetectionStream(
    camera_intrinsics=robot.camera_intrinsics,
    transform_to_map=robot.ros_control.transform_pose
)

# Reactive streams (RxPY)
video_stream = robot.get_ros_video_stream()
```

---

## 🔗 Resources

- **DIMOS GitHub**: https://github.com/dimensionalOS/dimos-unitree
- **DIMOS Examples**: https://github.com/dimensionalOS/dimos-unitree/tree/main/tests
- **go2_ros2_sdk**: https://github.com/dimensionalOS/go2_ros2_sdk
- **ShadowHound project.md**: docs/project.md

---

## ✅ Next Steps

1. **Review this document** with team
2. **Create shadowhound.repos** with DIMOS dependencies
3. **Test DIMOS integration** in devcontainer
4. **Implement first custom skill** (PatrolArea)
5. **Test on mock robot** before hardware

---

_This integration plan supersedes the original Phase 0-6 roadmap in project.md v0.1.0._


## Validation
- [ ] Legacy guidance reviewed for accuracy and converted to the new workflow where applicable.
- [ ] Links updated to use vault-friendly wikilinks or confirmed for external references.
- [ ] Outstanding migration work captured as tasks in the backlog.

## References
- [[integrations/integrations_hub|Knowledge Base Index]]
