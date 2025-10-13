---
tags: [development, architecture, testing]
status: active
related: [robot_interface, mission_executor, testing_strategy]
summary: >
  Analysis of agent-robot coupling and strategies for decoupling to enable testing without hardware.
---

# Agent-Robot Decoupling Analysis

**Date**: 2025-10-13  
**Status**: Design Phase  
**Goal**: Enable agent development and testing without physical robot hardware

---

## Current Architecture

### Dependency Chain

```
MissionAgentNode (ROS2)
    ↓
MissionExecutor (Pure Python)
    ↓
DIMOS OpenAIAgent / PlanningAgent
    ↓
DIMOS MyUnitreeSkills (Skill Library)
    ↓
DIMOS UnitreeGo2 (Robot Interface)
    ↓
UnitreeROSControl (ROS2 Bridge)
    ↓
Hardware (Physical Robot or ROS Topics)
```

### Key Files

**ShadowHound Layer**:
- `shadowhound_mission_agent/mission_agent.py` - ROS2 wrapper
- `shadowhound_mission_agent/mission_executor.py` - Business logic

**DIMOS Layer**:
- `dimos/agents/agent.py` - OpenAIAgent, PlanningAgent
- `dimos/robot/robot.py` - Abstract Robot base class
- `dimos/robot/unitree/unitree_go2.py` - UnitreeGo2 implementation
- `dimos/robot/unitree/unitree_skills.py` - MyUnitreeSkills skill library
- `dimos/robot/unitree/unitree_ros_control.py` - ROS2 bridge

---

## Coupling Points Analysis

### 1. MissionExecutor → DIMOS Robot (TIGHT)

```python
# mission_executor.py line ~185
from dimos.robot.unitree.unitree_go2 import UnitreeGo2
from dimos.robot.unitree.unitree_ros_control import UnitreeROSControl

def _init_robot(self):
    ros_control = UnitreeROSControl(webrtc_api_topic=self.config.webrtc_api_topic)
    self.robot = UnitreeGo2(ros_control=ros_control, ip=self.config.robot_ip)
```

**Problem**: Hardcoded to `UnitreeGo2` class
**Impact**: Can't swap in mock/sim without changing code

---

### 2. MissionExecutor → DIMOS Skills (MEDIUM)

```python
# mission_executor.py line ~220
from dimos.robot.unitree.unitree_skills import MyUnitreeSkills

def _init_skills(self):
    self.skills = MyUnitreeSkills(robot=self.robot)
```

**Problem**: Hardcoded to `MyUnitreeSkills`
**Impact**: Skills tied to specific robot implementation

---

### 3. DIMOS Agent → Skills → Robot (LOOSE)

```python
# mission_executor.py line ~300
self.agent = OpenAIAgent(
    skills=self.skills,  # Agent receives skills
    openai_client=client,
)
```

**Good**: Agent only knows about skills interface, not robot directly
**Implication**: If we mock skills, agent is decoupled

---

## DIMOS Robot Base Class

From `dimos/robot/robot.py`:

```python
class Robot(ABC):
    """Base class for all DIMOS robots."""
    
    def __init__(self,
                 hardware_interface: HardwareInterface = None,
                 ros_control: ROSControl = None,
                 skill_library: SkillLibrary = None,
                 ...):
        self.hardware_interface = hardware_interface
        self.ros_control = ros_control
        self.skill_library = skill_library
        # ... spatial memory, video streams, etc.
```

**Key Insight**: DIMOS already has abstraction layer!
- `hardware_interface` - For hardware commands
- `ros_control` - For ROS2 communication
- `skill_library` - For skills

**Strategy**: We can create `MockRobot(Robot)` that inherits from this base.

---

## Decoupling Strategies

### Strategy A: Mock at Robot Layer ⭐ (Recommended)

**Approach**: Create `MockUnitreeGo2(Robot)` that simulates robot behavior

```python
# shadowhound_robot/mock_robot.py
from dimos.robot.robot import Robot
from dimos.robot.unitree.unitree_skills import MyUnitreeSkills

class MockUnitreeGo2(Robot):
    """Simulated UnitreeGo2 for testing without hardware."""
    
    def __init__(self, **kwargs):
        # No hardware_interface, no ros_control
        super().__init__(
            hardware_interface=None,
            ros_control=None,
            **kwargs
        )
        
        # Simulated state
        self.position = [0.0, 0.0, 0.0]  # x, y, yaw
        self.battery = 100.0
        self.mode = "idle"
        
    def move_vel(self, x: float, y: float, duration: float):
        """Simulate velocity command."""
        self.position[0] += x * duration
        self.position[1] += y * duration
        return {"success": True}
    
    def get_ros_video_stream(self):
        """Return synthetic video frames."""
        import rx
        return rx.interval(0.1).pipe(
            ops.map(lambda _: self._generate_test_frame())
        )
    
    def _generate_test_frame(self):
        """Generate synthetic camera frame."""
        import numpy as np
        import cv2
        frame = np.zeros((480, 640, 3), dtype=np.uint8)
        cv2.putText(frame, f"Mock @ {self.position[:2]}", 
                    (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        return frame
```

**Changes to MissionExecutor**:

```python
# mission_executor.py
from shadowhound_robot.mock_robot import MockUnitreeGo2

def _init_robot(self):
    if self.config.robot_type == "mock":
        self.robot = MockUnitreeGo2()
    elif self.config.robot_type == "real":
        ros_control = UnitreeROSControl(...)
        self.robot = UnitreeGo2(ros_control=ros_control, ip=self.config.robot_ip)
    elif self.config.robot_type == "gazebo":
        self.robot = GazeboUnitreeGo2(...)
```

**Pros**:
- ✅ Agent code unchanged (still uses real skills)
- ✅ Skills code unchanged (uses mock robot)
- ✅ Fast iteration
- ✅ Can simulate failures, edge cases
- ✅ Works with DIMOS architecture

**Cons**:
- ⚠️ Must implement enough of Robot interface for skills to work
- ⚠️ Physics not realistic (but okay for agent logic testing)

---

### Strategy B: Mock at Skills Layer

**Approach**: Create `MockUnitreeSkills` that returns canned responses

```python
# shadowhound_skills/mock_skills.py
from dimos.skills.skills import AbstractRobotSkill, SkillLibrary

class MockMoveSkill(AbstractRobotSkill):
    x: float
    y: float
    duration: float
    
    def __call__(self):
        # No robot interaction - just return success
        time.sleep(0.1)  # Simulate delay
        return f"Mock: Moved to ({self.x}, {self.y})"

class MockUnitreeSkills:
    def __init__(self, robot=None):
        # Ignore robot parameter
        pass
    
    def get(self):
        # Return mock skills
        return [MockMoveSkill, MockReverseSkill, ...]
```

**Pros**:
- ✅ Extremely fast (no simulation)
- ✅ Test agent planning in isolation
- ✅ Easy to simulate skill failures

**Cons**:
- ⚠️ Doesn't test real skill implementations
- ⚠️ Doesn't validate robot interface
- ⚠️ Less realistic

---

### Strategy C: Gazebo/Isaac Sim Integration

**Approach**: Create `GazeboUnitreeGo2(Robot)` that connects to simulator

```python
# shadowhound_robot/sim_robot.py
class GazeboUnitreeGo2(Robot):
    """Robot backed by Gazebo simulation."""
    
    def __init__(self, **kwargs):
        # Initialize with ROS control pointing to Gazebo topics
        ros_control = UnitreeROSControl(
            webrtc_api_topic="/gazebo/webrtc_req"  # Gazebo namespace
        )
        super().__init__(
            ros_control=ros_control,
            **kwargs
        )
```

**Pros**:
- ✅ Realistic physics
- ✅ Visual validation
- ✅ Sensor simulation
- ✅ DIMOS supports Genesis/Isaac already

**Cons**:
- ⚠️ Slower (real-time simulation)
- ⚠️ Requires simulator setup
- ⚠️ Heavier resource usage

---

## Recommended Hybrid Approach 🎯

Use **all three** strategies for different testing needs:

### Testing Pyramid

```
┌─────────────────────────────────────────────────┐
│ Unit Tests: Agent Logic                        │
│ → MockUnitreeSkills (instant)                  │
│ → Focus: LLM planning, prompt engineering      │
│ → Run: Always (CI, pre-commit)                 │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Integration Tests: Skills + Robot API          │
│ → MockUnitreeGo2 (fast simulation)             │
│ → Focus: Skill execution, validation, errors   │
│ → Run: Pre-commit, PR validation               │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Simulation Tests: Motion Validation            │
│ → GazeboUnitreeGo2 (physics)                   │
│ → Focus: Navigation accuracy, collisions       │
│ → Run: Nightly, before hardware deploy         │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Hardware Tests: Real-World Validation          │
│ → UnitreeGo2 (physical robot)                  │
│ → Focus: Real-world performance                │
│ → Run: Manual, pre-release                     │
└─────────────────────────────────────────────────┘
```

---

## Implementation Plan

### Phase 0: Configuration Infrastructure

**Goal**: Support multiple robot backends via config

**Tasks**:
1. Add `robot_type` to `MissionExecutorConfig`
2. Add factory pattern to `_init_robot()`
3. Update launch files with `robot_type` parameter

**Config Example**:
```yaml
# configs/laptop_dev_mock.yaml
robot:
  type: "mock"
  
# configs/laptop_dev_gazebo.yaml
robot:
  type: "gazebo"
  
# configs/thor_onboard.yaml
robot:
  type: "real"
  ip: "192.168.10.116"
```

---

### Phase 1: Mock Robot Implementation ⭐

**Goal**: Enable agent testing without hardware

**Tasks**:
1. Create `shadowhound_robot` package structure
2. Implement `MockUnitreeGo2(Robot)`
3. Test with real `MyUnitreeSkills`
4. Validate agent can execute missions

**Acceptance Criteria**:
- Agent can execute "stand up" command with mock robot
- No ROS topics required
- Runs in pure Python environment
- Skills receive expected robot interface

**Estimated Effort**: 4-6 hours

---

### Phase 2: Test Infrastructure

**Goal**: Automated testing with mocks

**Tasks**:
1. Create pytest fixtures for mock robot
2. Write unit tests for agent logic
3. Write integration tests for skills
4. Add to CI/CD pipeline

**Test Examples**:
```python
# test/test_agent_mock.py
def test_agent_planning():
    config = MissionExecutorConfig(robot_type="mock")
    executor = MissionExecutor(config)
    executor.initialize()
    
    response = executor.execute_mission("stand up")
    
    assert "success" in response.lower()

# test/test_skills_mock.py
def test_move_skill():
    robot = MockUnitreeGo2()
    skills = MyUnitreeSkills(robot=robot)
    
    move_skill = skills.get_skill("Move")
    result = move_skill(x=1.0, y=0.0, duration=2.0)
    
    assert robot.position[0] == pytest.approx(2.0)  # 1.0 m/s * 2s
```

---

### Phase 3: Gazebo Integration (Optional)

**Goal**: Physics-based validation

**Tasks**:
1. Set up Gazebo with UnitreeGo2 model
2. Implement `GazeboUnitreeGo2(Robot)`
3. Create simulation launch files
4. Add simulation test suite

**When**: After Phase 1 skills are implemented

---

## Configuration Design

### MissionExecutorConfig Extension

```python
@dataclass
class MissionExecutorConfig:
    # Existing fields...
    agent_backend: str = "openai"
    use_planning_agent: bool = False
    
    # NEW: Robot configuration
    robot_type: str = "real"  # 'real', 'mock', 'gazebo'
    robot_ip: str = "192.168.1.103"  # Only for robot_type='real'
    webrtc_api_topic: str = "webrtc_req"
    
    # Mock robot settings
    mock_delay_ms: int = 100  # Simulated skill execution delay
    mock_failure_rate: float = 0.0  # Probability of random failures (for testing)
    
    # Gazebo settings
    gazebo_namespace: str = "/gazebo"  # ROS namespace for Gazebo
```

### Factory Pattern

```python
def _init_robot(self) -> None:
    """Initialize robot based on configuration."""
    
    if self.config.robot_type == "mock":
        self.logger.info("Initializing MOCK robot (no hardware)")
        self.robot = MockUnitreeGo2(
            delay_ms=self.config.mock_delay_ms,
            failure_rate=self.config.mock_failure_rate,
        )
        
    elif self.config.robot_type == "gazebo":
        self.logger.info("Initializing GAZEBO robot (simulation)")
        ros_control = UnitreeROSControl(
            webrtc_api_topic=f"{self.config.gazebo_namespace}/webrtc_req"
        )
        self.robot = GazeboUnitreeGo2(
            ros_control=ros_control,
        )
        
    elif self.config.robot_type == "real":
        self.logger.info("Initializing REAL robot (hardware)")
        ros_control = UnitreeROSControl(
            webrtc_api_topic=self.config.webrtc_api_topic
        )
        self.robot = UnitreeGo2(
            ros_control=ros_control,
            ip=self.config.robot_ip,
        )
        
    else:
        raise ValueError(f"Unknown robot_type: {self.config.robot_type}")
    
    self.logger.info(f"Robot initialized: {type(self.robot).__name__}")
```

---

## Dependencies Analysis

### Current Dependencies

**Hard Dependencies** (must mock):
- `UnitreeGo2` class
- `UnitreeROSControl` class (ROS2)
- WebRTC connection (for high-level skills)
- Camera topics (for vision)

**Soft Dependencies** (agent works without):
- Spatial memory (ChromaDB) - optional
- Visual memory - optional
- Hardware sensors (IMU, lidar) - optional for basic skills

### Mock Robot Minimum Interface

To support `MyUnitreeSkills`, mock robot must implement:

```python
# From analyzing skills usage
class MockUnitreeGo2(Robot):
    # Core movement (used by Move, Reverse, SpinLeft, SpinRight)
    def move_vel(self, x: float, y: float, duration: float): ...
    
    # State queries (used by many skills)
    def get_state(self) -> RobotState: ...
    def get_position(self) -> tuple[float, float, float]: ...
    
    # Video (used by vision-based agents)
    def get_ros_video_stream(self) -> Observable: ...
    
    # High-level API (WebRTC skills)
    # Note: These use ros_control.webrtc_req() internally
    # Mock can either:
    # 1. Simulate the API calls
    # 2. Return success without action
```

---

## Risk Analysis

### Risks with Mock Approach

1. **Mock Drift**: Mock behavior diverges from real robot
   - *Mitigation*: Periodic validation against real robot
   - *Mitigation*: Comprehensive integration tests

2. **Incomplete Interface**: Mock doesn't implement all needed methods
   - *Mitigation*: Start with minimal interface, expand as needed
   - *Mitigation*: Clear error messages for missing methods

3. **False Confidence**: Tests pass with mock but fail on real robot
   - *Mitigation*: Simulation tests before hardware deploy
   - *Mitigation*: Hardware validation as final gate

### Benefits vs Risks

**Benefits**:
- ✅ 10-100x faster iteration
- ✅ No hardware dependency
- ✅ Deterministic testing
- ✅ Parallel development (agent team + robot team)
- ✅ CI/CD automation

**Risks**:
- ⚠️ Mock drift (manageable with discipline)
- ⚠️ Integration issues (catch with sim + hardware tests)

**Verdict**: Benefits far outweigh risks for Phase 0-1 development

---

## Next Steps

### Immediate Actions

1. **Create `shadowhound_robot` package** - Establish abstraction layer
2. **Implement `MockUnitreeGo2`** - Minimum viable mock
3. **Update `MissionExecutor`** - Add factory pattern
4. **Add config support** - `robot_type` parameter
5. **Write first test** - Agent executes command with mock

### Success Criteria

- [ ] Agent can execute missions without hardware
- [ ] Tests run in <5 seconds (vs minutes with hardware)
- [ ] Mock robot implements core movement interface
- [ ] Configuration selects robot type at runtime
- [ ] Documentation covers testing workflow

---

## References

- [DIMOS Robot Base Class](../../src/dimos-unitree/dimos/robot/robot.py)
- [MissionExecutor Implementation](../../src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py)
- [Testing Strategy Doc](testing_strategy.md) (to be created)

---

**Updated**: 2025-10-13  
**Next Review**: After Phase 1 mock implementation
