---
tags: [architecture, ros2, design-patterns]
status: active
related: [mission_executor, mission_agent, separation_of_concerns, naming_refactor_plan]
summary: >
  Comprehensive guide to the two-layer architecture: MissionAgentNode (ROS2 wrapper) and MissionExecutor (cognitive layer).
---

# Mission Agent vs Mission Executor: Complete Reference

**Created**: 2025-10-13  
**Last Updated**: 2025-10-13  
**Purpose**: Definitive reference for the mission execution architecture

**Future Note**: These components will be renamed in Phase 1:
- `MissionAgentNode` → `MissionNode`
- `MissionExecutor` → `RobotAgent`

See [naming_refactor_plan.md](../development/naming_refactor_plan.md) for details.

---

## Quick Reference Table

| Component | Type | Role | Dependencies | Can Test Without ROS? |
|-----------|------|------|--------------|----------------------|
| **MissionAgentNode** | ROS2 Node | Infrastructure wrapper | ROS2, MissionExecutor | ❌ No |
| **MissionExecutor** | Python Class | Robot's brain/intelligence | DIMOS, OpenAI/Ollama | ✅ Yes |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      ROS2 ECOSYSTEM                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         MissionAgentNode (mission_agent.py)              │   │
│  │  "Peripheral Nervous System" - Infrastructure Wrapper    │   │
│  │                                                           │   │
│  │  Responsibilities:                                        │   │
│  │  ✅ ROS2 lifecycle (init, spin, shutdown)                │   │
│  │  ✅ Topic subscriptions (/camera, /status)               │   │
│  │  ✅ Topic publishing (/diagnostics)                      │   │
│  │  ✅ Web interface hosting (Flask)                        │   │
│  │  ✅ Threading coordination                               │   │
│  │  ✅ Configuration from ROS params                        │   │
│  │                                                           │   │
│  │  What it's NOT:                                          │   │
│  │  ❌ Mission planning or intelligence                     │   │
│  │  ❌ Calling skills or controlling robot                  │   │
│  │  ❌ Making cognitive decisions                           │   │
│  └────────────────────┬────────────────────────────────────┘   │
│                       │ delegates to                            │
└───────────────────────┼─────────────────────────────────────────┘
                        ▼
        ┌───────────────────────────────────────────────┐
        │  MissionExecutor (mission_executor.py)         │
        │  "Brain/Cognitive Layer" - Pure Python Logic   │
        │                                                 │
        │  Responsibilities:                              │
        │  ✅ Mission planning (LLM orchestration)       │
        │  ✅ Skill execution (calling Robot via Skills) │
        │  ✅ Context management (conversation, RAG)     │
        │  ✅ Cognitive reasoning (DIMOS agents)         │
        │  ✅ Progress tracking and reporting            │
        │                                                 │
        │  What it's NOT:                                │
        │  ❌ ROS-aware (no imports from rclpy)          │
        │  ❌ Managing topics or web interface           │
        │  ❌ Lifecycle management                       │
        │                                                 │
        │  Dependencies:                                  │
        │  → DIMOS (OpenAIAgent, PlanningAgent)          │
        │  → DIMOS (UnitreeGo2, Skills)                  │
        │  → OpenAI client or Ollama                     │
        │  → Chroma (embeddings/RAG)                     │
        └───────────────────────────────────────────────┘
```

---

## The Pattern: Humble Object

This architecture follows the [Humble Object pattern](https://martinfowler.com/bliki/HumbleObject.html):

**Definition**: Separate logic that's hard to test (infrastructure) from logic that's easy to test (business logic).

### In Our Case:

**Hard to Test (MissionAgentNode)**:
- Requires ROS2 environment running
- Needs topics/services/parameters configured
- Threading and async coordination
- Web server lifecycle

**Easy to Test (MissionExecutor)**:
- Pure Python, no ROS dependencies
- Can instantiate directly in Jupyter
- Can mock Robot interface easily
- Testable with simple unit tests

### Benefits:

1. **Unit Testing**: Test cognitive layer without spinning up ROS
2. **Reusability**: Could use MissionExecutor in CLI tool, web service, or different robot framework
3. **Clarity**: ROS infrastructure concerns separate from mission planning logic
4. **Development**: Develop/debug brain logic without hardware or ROS environment

---

## Detailed Responsibilities

### MissionAgentNode (mission_agent.py)

**✅ DOES** (Infrastructure):
- Initialize ROS2 node with lifecycle callbacks
- Declare and read ROS parameters (`backend_config`, `camera_topic`, etc.)
- Subscribe to camera feed (`/camera/compressed`)
- Subscribe to robot status topic (`/shadowhound/robot_status`)
- Publish diagnostics (`/shadowhound/diagnostics`)
- Host web interface (Flask, threading)
- Coordinate threading (ROS spin thread, web UI thread)
- Bridge web UI requests to MissionExecutor
- Bridge camera images to MissionExecutor
- Handle graceful shutdown (Ctrl+C, etc.)

**❌ DOES NOT** (Delegated to MissionExecutor):
- Plan missions with LLM
- Call skills or control robot
- Make cognitive decisions
- Manage conversation context
- Track mission progress
- Handle RAG/embeddings
- Instantiate DIMOS agents

**Configuration** (ROS Parameters):
- `backend_config`: Path to YAML config (selects cloud vs local LLM)
- `camera_topic`: Where to subscribe for images
- `robot_status_topic`: Where to get robot telemetry
- `diagnostics_topic`: Where to publish agent health
- `web_interface_port`: Flask server port
- `enable_web_ui`: Whether to start web interface

**Example Launch**:
```bash
ros2 run shadowhound_mission_agent mission_agent \
  --ros-args \
  -p backend_config:=/path/to/cloud_openai.yaml \
  -p camera_topic:=/camera/compressed \
  -p web_interface_port:=5001
```

**Testing Strategy**:
- **Unit Tests**: Test parameter parsing, callback registration, threading coordination
- **Integration Tests**: Launch with mock topics, verify topic connections, test web UI endpoints

---

### MissionExecutor (mission_executor.py)

**✅ DOES** (Business Logic/Intelligence):
- Initialize DIMOS agents (OpenAIAgent, PlanningAgent)
- Configure Robot interface (UnitreeGo2 or future MockRobot)
- Load skills registry and validate available skills
- Orchestrate LLM calls for mission planning
- Execute skills in sequence (Robot.do_skill(...))
- Manage conversation context (DIMOS ContextManager)
- Track mission progress (DIMOS telemetry)
- Handle RAG queries (Chroma embeddings)
- Report execution results and errors
- Provide chat/query interfaces

**❌ DOES NOT** (Delegated to MissionAgentNode):
- Manage ROS topics or services
- Handle ROS parameters or configuration files
- Host web interface or HTTP endpoints
- Manage threading (runs in caller's thread)
- Subscribe to camera or status topics
- Publish diagnostics or telemetry

**Configuration** (MissionExecutorConfig dataclass):
- `backend_config`: Path to backend YAML (cloud vs local)
- `robot`: Robot instance (UnitreeGo2, future MockRobot)
- `skills`: Skills registry instance
- `enable_rag`: Whether to use embeddings/RAG
- `conversation_history_size`: Max messages to keep
- `default_timeout`: Skill execution timeout

**Example Instantiation**:
```python
from shadowhound_mission_agent.mission_executor import MissionExecutor, MissionExecutorConfig
from dimos import UnitreeGo2, Skills

# Instantiate robot and skills
robot = UnitreeGo2(ip="192.168.1.103")
skills = Skills(robot)

# Create executor
config = MissionExecutorConfig(
    backend_config="/path/to/cloud_openai.yaml",
    robot=robot,
    skills=skills,
    enable_rag=True
)
executor = MissionExecutor(config)

# Execute mission
result = executor.execute_mission("patrol the perimeter")
print(result)

# Query/chat
response = executor.chat("what did you see?")
print(response)
```

**Testing Strategy**:
- **Unit Tests**: Mock Robot and Skills, test mission planning logic, test skill execution flow
- **Integration Tests**: Use MockRobot (Phase 1), test real skill execution, test RAG queries
- **Notebook Tests**: Interactive testing in Jupyter without ROS

---

## Data Flow Examples

### 1. Web UI Mission Request

```
User Browser
    ↓ (HTTP POST /api/mission)
MissionAgentNode.web_mission_callback()
    ↓ (Python method call)
MissionExecutor.execute_mission(instruction)
    ↓ (LLM orchestration)
OpenAI/Ollama API
    ← (skill plan JSON)
MissionExecutor.execute_skill_sequence()
    ↓ (for each skill)
Robot.do_skill(skill_name, **params)
    ↓ (actual robot execution)
UnitreeGo2 hardware via SDK
    ← (skill result)
MissionExecutor (collects results)
    ← (mission result)
MissionAgentNode.web_mission_callback()
    ← (HTTP JSON response)
User Browser
```

**Key Points**:
- **MissionAgentNode**: Only handles HTTP request/response
- **MissionExecutor**: Handles entire planning → execution → reporting flow
- **Decoupling**: Could easily swap web UI for CLI or different transport

---

### 2. ROS Topic Camera Feed → Mission Context

```
Robot Camera
    ↓ (publishes)
/camera/compressed topic
    ↓ (subscription)
MissionAgentNode.camera_callback(msg)
    ↓ (decompress, convert to numpy)
cv2.imdecode(msg.data)
    ↓ (Python method call)
MissionExecutor.update_camera_image(frame)
    ↓ (stores in internal buffer)
MissionExecutor._latest_camera_frame = frame
    ↓ (available for VLM calls)
MissionExecutor.execute_mission("what do you see?")
    ↓ (includes image in LLM context)
OpenAI Vision API
    ← (description)
"I see a person in a red jacket..."
```

**Key Points**:
- **MissionAgentNode**: Handles ROS subscription and image decoding
- **MissionExecutor**: Stores latest frame, uses it in LLM context
- **Separation**: MissionExecutor never knows about ROS topics

---

### 3. Diagnostics Publishing

```
MissionExecutor.execute_mission()
    ↓ (progress updates)
MissionExecutor._mission_progress = {...}
    ↓ (periodic callback from MissionAgentNode)
MissionAgentNode.diagnostics_timer_callback()
    ↓ (read executor state)
executor.get_diagnostics()
    ← (returns dict)
{
  "status": "executing",
  "current_skill": "nav.goto",
  "progress": 0.67,
  "errors": []
}
    ↓ (convert to ROS message)
DiagnosticArray message
    ↓ (publish)
/shadowhound/diagnostics topic
    ↓ (external subscribers)
rqt_robot_monitor, logging nodes
```

**Key Points**:
- **MissionExecutor**: Maintains state, exposes via getter
- **MissionAgentNode**: Polls state, publishes to ROS
- **Unidirectional**: Executor doesn't know about diagnostics topic

---

### 4. Startup Sequence

```
1. ROS Launch System
   ↓
2. MissionAgentNode.__init__()
   - Initialize ROS2 node
   - Declare parameters
   - Read backend_config path
   ↓
3. MissionAgentNode.initialize_mission_executor()
   - Load backend config YAML
   - Instantiate UnitreeGo2
   - Instantiate Skills
   - Create MissionExecutorConfig
   ↓
4. MissionExecutor.__init__(config)
   - Initialize DIMOS agents
   - Load skills registry
   - Setup RAG/embeddings
   - Validate configuration
   ↓
5. MissionAgentNode.setup_subscriptions()
   - Subscribe to /camera/compressed
   - Subscribe to /shadowhound/robot_status
   - Create diagnostics publisher
   ↓
6. MissionAgentNode.start_web_interface()
   - Initialize Flask app
   - Register routes
   - Start web server thread
   ↓
7. MissionAgentNode.spin()
   - Enter ROS event loop
   - Ready to receive missions!
```

---

## Analogy: Web Application MVC

If you're familiar with web development, think of it like MVC:

| Component | Web MVC Analog | Responsibilities |
|-----------|----------------|------------------|
| **MissionAgentNode** | Controller + Routes | Handle HTTP requests, coordinate, delegate to model |
| **MissionExecutor** | Model + Business Logic | Core logic, data manipulation, external API calls |
| **Robot/Skills** | Database + External APIs | Persistence, external services |

**Why separate?**
- You don't put database queries in route handlers
- You don't handle HTTP requests in model classes
- Same principle: infrastructure separate from logic

---

## Testing Strategies

### MissionExecutor (Pure Python)

**Unit Tests**:
```python
def test_mission_planning():
    # No ROS needed!
    mock_robot = MockRobot()
    mock_skills = MockSkills()
    config = MissionExecutorConfig(robot=mock_robot, skills=mock_skills)
    executor = MissionExecutor(config)
    
    result = executor.execute_mission("go forward 1 meter")
    assert result["success"] == True
    assert mock_skills.called_with("nav.goto", distance=1.0)
```

**Integration Tests** (with MockRobot in Phase 1):
```python
def test_real_skill_execution():
    # Still no ROS, but real skills with mock robot
    mock_robot = MockRobot()
    skills = Skills(mock_robot)  # Real skills, mock robot
    config = MissionExecutorConfig(robot=mock_robot, skills=skills)
    executor = MissionExecutor(config)
    
    result = executor.execute_mission("rotate 90 degrees")
    assert mock_robot.yaw == 1.57  # 90 degrees in radians
```

**Jupyter Development**:
```python
# In notebook, no ROS needed
%load_ext autoreload
%autoreload 2

from mission_executor import MissionExecutor, MissionExecutorConfig
from mock_robot import MockRobot

robot = MockRobot()
executor = MissionExecutor(robot=robot)

# Interactive development
executor.chat("what skills do you have?")
executor.execute_mission("test navigation")
robot.get_pose()  # Inspect mock state
```

---

### MissionAgentNode (ROS Integration)

**Unit Tests** (partial, hard to fully test):
```python
def test_parameter_loading():
    # Test parameter parsing without full ROS
    node = MissionAgentNode()
    params = node.load_ros_parameters()
    assert "backend_config" in params
```

**Integration Tests** (full ROS needed):
```bash
# Launch with mock topics
ros2 launch shadowhound_bringup test_mission_agent.launch.py

# Verify topics connected
ros2 topic list | grep shadowhound

# Test web UI
curl http://localhost:5001/api/mission -d '{"instruction": "test"}'
```

---

## Future Refactoring (Phase 1)

These components will be renamed to better reflect their roles:

### Current → New

- `MissionExecutor` → **`RobotAgent`**
  - **Why**: It IS the robot's brain/agent, not just executing missions
  - **Benefit**: Name clearly indicates it's the cognitive layer
  - **Files**: `mission_executor.py` → `robot_agent.py`

- `MissionAgentNode` → **`MissionNode`**
  - **Why**: It's just infrastructure, not the agent itself
  - **Benefit**: Avoids "agent" confusion (only RobotAgent is the agent)
  - **Files**: `mission_agent.py` → `mission_node.py`

**See**: [naming_refactor_plan.md](../development/naming_refactor_plan.md) for full details

**Timeline**: Phase 1 kickoff, batched with MockRobot implementation

---

## Quick Decision Tree

**"Should this code go in MissionAgentNode or MissionExecutor?"**

```
Does it involve ROS topics, services, or parameters?
├─ YES → MissionAgentNode
└─ NO  → Does it involve mission planning, skill execution, or cognitive reasoning?
          ├─ YES → MissionExecutor
          └─ NO  → Might belong in Robot or Skills layer
```

**"Can I test this without ROS running?"**
├─ YES → Probably belongs in MissionExecutor
└─ NO  → Probably belongs in MissionAgentNode

**"Does this need to be testable in Jupyter/notebooks?"**
├─ YES → Must be in MissionExecutor
└─ NO  → Could be in MissionAgentNode

---

## References

- **Code**: `src/shadowhound_mission_agent/shadowhound_mission_agent/`
  - `mission_agent.py` - ROS2 wrapper node
  - `mission_executor.py` - Pure Python cognitive layer
- **Related Docs**:
  - [agent_robot_decoupling_analysis.md](../development/agent_robot_decoupling_analysis.md) - MockRobot strategy
  - [naming_refactor_plan.md](../development/naming_refactor_plan.md) - Phase 1 rename plan
- **Design Patterns**:
  - [Humble Object](https://martinfowler.com/bliki/HumbleObject.html)
  - [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
  - [Adapter Pattern](https://refactoring.guru/design-patterns/adapter)

---

**Questions or Need Clarification?**
- Check inline docstrings in Python files (concise summaries)
- See this document for comprehensive details
- Refer to naming_refactor_plan.md for future state

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
