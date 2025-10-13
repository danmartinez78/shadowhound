---
tags: [architecture, ros2, design-patterns]
status: active
related: [mission_executor, mission_agent, separation_of_concerns]
summary: >
  Clarifies the distinction between MissionAgentNode (ROS2 wrapper) and MissionExecutor (pure Python business logic).
---

# Mission Agent vs Mission Executor

**Created**: 2025-10-13  
**Purpose**: Clarify the two-layer architecture for mission execution

---

## The Confusion

We have two similar-sounding components:
- `MissionAgentNode` (in `mission_agent.py`)
- `MissionExecutor` (in `mission_executor.py`)

**Why both?** Separation of concerns using the **Humble Object pattern**.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    ROS2 Layer                               │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         MissionAgentNode (ROS2 Node)                 │  │
│  │  - ROS lifecycle management                          │  │
│  │  - Parameter declarations                            │  │
│  │  - Topic subscriptions (/mission_command)            │  │
│  │  - Topic publishers (/mission_status)                │  │
│  │  - ROS logging bridge                                │  │
│  │  - Web interface coordination                        │  │
│  │  - Camera feed handling (Image → JPEG)               │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                 │
│                           │ delegates to                    │
│                           ▼                                 │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                  Pure Python Layer                          │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         MissionExecutor (Business Logic)             │  │
│  │  - Robot initialization (DIMOS UnitreeGo2)           │  │
│  │  - Agent initialization (DIMOS OpenAI/Planning)      │  │
│  │  - Skill library setup (MyUnitreeSkills)             │  │
│  │  - Mission execution (.execute_mission())            │  │
│  │  - Configuration management                          │  │
│  │  - Backend selection (OpenAI vs Ollama)              │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                 │
│                           │ uses                            │
│                           ▼                                 │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    DIMOS Layer                              │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ OpenAIAgent │  │ UnitreeGo2   │  │ MyUnitreeSkills  │  │
│  │ (LLM)       │→ │ (Robot)      │← │ (Function Tools) │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
│                           │                                 │
│                           ▼                                 │
└─────────────────────────────────────────────────────────────┘
                            │
                    Physical Hardware
                    (Unitree Go2)
```

---

## MissionAgentNode: The ROS2 Wrapper

**File**: `shadowhound_mission_agent/mission_agent.py`  
**Type**: `rclpy.node.Node` (ROS2 Node)  
**Responsibility**: Handle ROS-specific infrastructure

### What It Does

```python
class MissionAgentNode(Node):
    def __init__(self):
        super().__init__("shadowhound_mission_agent")
        
        # 1. ROS Parameter Management
        self.declare_parameter("agent_backend", "openai")
        self.declare_parameter("robot_ip", "192.168.1.103")
        # ... more ROS parameters
        
        # 2. Create MissionExecutor (delegates business logic)
        config = MissionExecutorConfig(
            agent_backend=self.get_parameter("agent_backend").value,
            robot_ip=self.get_parameter("robot_ip").value,
            # ...
        )
        self.mission_executor = MissionExecutor(config, logger=self.get_logger())
        self.mission_executor.initialize()
        
        # 3. ROS Topic Subscriptions
        self.mission_sub = self.create_subscription(
            String, "mission_command", self.mission_callback, 10
        )
        self.camera_sub = self.create_subscription(
            Image, "/camera/image_raw", self.camera_callback, qos
        )
        
        # 4. ROS Topic Publishers
        self.status_pub = self.create_publisher(String, "mission_status", 10)
        
        # 5. Optional: Web Interface (Flask server)
        self.web = WebInterface(
            command_callback=self._execute_mission_from_web,
            port=8080
        )
    
    def mission_callback(self, msg: String):
        """Handle ROS topic message."""
        command = msg.data
        
        # Delegate to MissionExecutor
        response, timing = self.mission_executor.execute_mission(command)
        
        # Publish ROS result
        status = String()
        status.data = f"COMPLETED: {response}"
        self.status_pub.publish(status)
    
    def camera_callback(self, msg: Image):
        """Convert ROS Image → JPEG for web UI."""
        np_arr = np.frombuffer(msg.data, ...)
        _, jpeg_buffer = cv2.imencode(".jpg", np_arr)
        self.web.update_camera_frame(jpeg_buffer.tobytes())
```

### Key Characteristics

- ✅ **ROS-Aware**: Inherits from `rclpy.node.Node`
- ✅ **Infrastructure**: Handles topics, parameters, QoS, timers
- ✅ **Thin Wrapper**: ~500 lines, mostly ROS boilerplate
- ✅ **Delegates**: All business logic to `MissionExecutor`
- ✅ **Single Responsibility**: ROS interface only

### What It Does NOT Do

- ❌ Initialize DIMOS robot
- ❌ Initialize DIMOS agent
- ❌ Execute missions (delegates to `MissionExecutor`)
- ❌ Contain LLM logic
- ❌ Know about DIMOS internals

---

## MissionExecutor: The Business Logic

**File**: `shadowhound_mission_agent/mission_executor.py`  
**Type**: Pure Python class (no ROS inheritance)  
**Responsibility**: Mission execution logic

### What It Does

```python
class MissionExecutor:
    """Pure Python mission executor - no ROS dependencies."""
    
    def __init__(self, config: MissionExecutorConfig, logger=None):
        self.config = config
        self.logger = logger or logging.getLogger(__name__)
        
        # DIMOS components (initialized later)
        self.robot = None
        self.skills = None
        self.agent = None
    
    def initialize(self):
        """Initialize DIMOS components."""
        self._init_robot()      # UnitreeGo2 with ROS control
        self._init_skills()     # MyUnitreeSkills
        self._init_agent()      # OpenAIAgent or PlanningAgent
    
    def _init_robot(self):
        """Initialize DIMOS robot interface."""
        ros_control = UnitreeROSControl(...)
        self.robot = UnitreeGo2(ros_control=ros_control, ip=self.config.robot_ip)
    
    def _init_skills(self):
        """Initialize DIMOS skill library."""
        self.skills = MyUnitreeSkills(robot=self.robot)
    
    def _init_agent(self):
        """Initialize DIMOS agent (OpenAI or Ollama)."""
        if self.config.agent_backend == "ollama":
            client = OpenAI(base_url=f"{self.config.ollama_base_url}/v1")
            model = self.config.ollama_model
        else:
            client = OpenAI()
            model = self.config.openai_model
        
        self.agent = OpenAIAgent(
            model_name=model,
            skills=self.skills,
            openai_client=client,
        )
    
    def execute_mission(self, command: str) -> tuple[str, dict]:
        """Execute mission command through DIMOS agent."""
        start_time = time.time()
        
        # Call DIMOS agent
        response = self.agent.run_observable_query(command).run()
        
        # Calculate timing
        total_duration = time.time() - start_time
        timing_info = {"total_duration": total_duration, ...}
        
        return response, timing_info
```

### Key Characteristics

- ✅ **Pure Python**: No ROS inheritance, uses standard `logging`
- ✅ **DIMOS Integration**: Initializes robot, skills, agent
- ✅ **Configuration-Driven**: Backend selection (OpenAI/Ollama)
- ✅ **Business Logic**: Mission execution, timing, error handling
- ✅ **Reusable**: Can be used in scripts, notebooks, tests

### What It Does NOT Do

- ❌ Handle ROS topics/services
- ❌ Manage ROS parameters
- ❌ Handle camera feed (ROS Image messages)
- ❌ Manage web interface
- ❌ ROS lifecycle management

---

## Why This Separation? (Humble Object Pattern)

### Benefits

1. **Testability** 🧪
   ```python
   # Test MissionExecutor WITHOUT ROS!
   config = MissionExecutorConfig(agent_backend="mock")
   executor = MissionExecutor(config)
   executor.initialize()
   response = executor.execute_mission("stand up")
   assert "success" in response
   ```

2. **Reusability** ♻️
   ```python
   # Use in Jupyter notebook
   executor = MissionExecutor(MissionExecutorConfig())
   executor.initialize()
   executor.execute_mission("patrol perimeter")
   
   # Use in standalone script
   executor = MissionExecutor(MissionExecutorConfig())
   while True:
       cmd = input("Command: ")
       print(executor.execute_mission(cmd))
   ```

3. **Separation of Concerns** 🎯
   - ROS changes don't affect business logic
   - Business logic changes don't require ROS knowledge
   - Clear boundary between infrastructure and domain

4. **Development Speed** ⚡
   - Test business logic without launching ROS
   - Debug without ROS complexity
   - Iterate faster (no `ros2 launch` cycle)

---

## Data Flow Example

### User Sends Command via Web UI

```
1. Browser → HTTP POST → WebInterface.command_callback()
   ↓
2. WebInterface → MissionAgentNode._execute_mission_from_web()
   ↓
3. MissionAgentNode → MissionExecutor.execute_mission("stand up")
   ↓
4. MissionExecutor → OpenAIAgent.run_observable_query("stand up")
   ↓
5. OpenAIAgent → LLM (GPT-4 or Ollama)
   ↓ (LLM decides to call "StandUp" skill)
6. OpenAIAgent → MyUnitreeSkills.StandUp()
   ↓
7. StandUp skill → UnitreeGo2.webrtc_req(1001)  # Stand command
   ↓
8. UnitreeGo2 → UnitreeROSControl → ROS topic /webrtc_req
   ↓
9. go2_ros2_sdk → Physical Robot (Unitree Go2)
   ↓
10. Robot stands up, returns success
   ↓
11. Response bubbles back: Skill → Agent → Executor → Node → WebInterface
   ↓
12. WebInterface → Browser (displays "✅ Robot stood up")
```

---

## When to Modify Each Component

### Modify `MissionAgentNode` when:
- Adding ROS topics/services
- Changing ROS parameters
- Modifying camera feed handling
- Adjusting web interface integration
- Updating ROS lifecycle hooks

### Modify `MissionExecutor` when:
- Changing DIMOS initialization
- Adding new backend support (e.g., vLLM)
- Modifying mission execution logic
- Updating skill/agent configuration
- Adding new robot types

---

## File Locations

```
src/shadowhound_mission_agent/
├── shadowhound_mission_agent/
│   ├── mission_agent.py          ← MissionAgentNode (ROS2 wrapper)
│   ├── mission_executor.py       ← MissionExecutor (business logic)
│   ├── web_interface.py          ← WebInterface (Flask server)
│   └── __init__.py
├── package.xml
├── setup.py
└── README.md
```

---

## Naming Clarification

### Why "Agent" in Both Names?

**MissionAgentNode**: 
- "Agent" refers to the ROS2 **agent/node** (infrastructure term)
- It's the ShadowHound **node** that handles missions

**MissionExecutor**:
- Could have been called `MissionController` or `MissionService`
- "Executor" emphasizes its role: **execute** missions
- It **uses** a DIMOS agent (OpenAIAgent/PlanningAgent) internally

### Alternative Naming (for clarity)

If we were to rename for maximum clarity:
- `MissionAgentNode` → `MissionROS2Node` or `MissionInterface`
- `MissionExecutor` → `MissionService` or `MissionOrchestrator`

**Current names are fine** - just understand the layering!

---

## Analogy: Web Application

Similar pattern in web development:

```
┌────────────────────────────────────┐
│  Flask/Django View (HTTP layer)   │  ← MissionAgentNode
│  - Handle HTTP requests/responses │
│  - Parse query params             │
│  - Render templates               │
└────────────────────────────────────┘
              ↓ delegates to
┌────────────────────────────────────┐
│  Service Layer (business logic)   │  ← MissionExecutor
│  - Execute business rules         │
│  - Call database                  │
│  - Process data                   │
└────────────────────────────────────┘
```

**Takeaway**: The web framework (Flask) doesn't contain business logic - it delegates to a service layer. Same pattern here with ROS2!

---

## Testing Strategy

### Test MissionExecutor (Unit Tests)
```python
# No ROS required!
def test_mission_execution():
    config = MissionExecutorConfig(robot_type="mock")
    executor = MissionExecutor(config)
    executor.initialize()
    
    response, timing = executor.execute_mission("stand up")
    
    assert "success" in response.lower()
    assert timing["total_duration"] < 5.0
```

### Test MissionAgentNode (Integration Tests)
```python
# Requires ROS2
def test_ros_topic_interface():
    node = MissionAgentNode()
    
    # Publish to /mission_command
    msg = String()
    msg.data = "stand up"
    test_pub.publish(msg)
    
    # Wait for /mission_status response
    response = wait_for_message("/mission_status")
    assert "COMPLETED" in response.data
```

---

## Summary

| Component | Type | Responsibility | Dependencies |
|-----------|------|---------------|--------------|
| **MissionAgentNode** | ROS2 Node | Infrastructure wrapper | ROS2, MissionExecutor |
| **MissionExecutor** | Python Class | Business logic | DIMOS, OpenAI/Ollama |

**Key Insight**: `MissionAgentNode` is the **interface**, `MissionExecutor` is the **implementation**.

This pattern enables:
- ✅ Testing without ROS
- ✅ Reusing logic in notebooks/scripts
- ✅ Clear separation of concerns
- ✅ Easy mocking for development

---

**Related Docs**:
- [MissionExecutor Implementation](../../src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py)
- [MissionAgentNode Implementation](../../src/shadowhound_mission_agent/shadowhound_mission_agent/mission_agent.py)
- [Agent-Robot Decoupling Analysis](agent_robot_decoupling_analysis.md)

**Updated**: 2025-10-13
