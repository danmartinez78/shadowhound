---
tags: [software, autodoc]
status: draft
related: []
summary: >
  Auto-generated reference for shadowhound_mission_agent_api.
---

# shadowhound_mission_agent API Reference

Auto-generated Python API documentation.

## Module: `shadowhound_mission_agent.mission_agent`

ShadowHound Mission Agent - ROS2 wrapper for mission execution.

This node provides a ROS2 interface to the MissionExecutor, handling:
- ROS node lifecycle and parameter management
- Topic subscriptions (mission commands) and publications (status)
- Web interface integration
- ROS logging bridge

The actual mission execution logic is in MissionExecutor (pure Python).


### Class: `MissionAgentNode`

**Inherits:** `Node`

ROS2 node providing interface to MissionExecutor.

This is a thin wrapper that handles ROS-specific concerns while
delegating all business logic to MissionExecutor.


#### Methods

##### `__init__(self)`

*No documentation available.*

##### `mission_callback(self, msg: String)`

Handle incoming mission commands from ROS topic.


##### `camera_callback(self, msg: Image)`

Handle camera feed for web UI.

Converts raw ROS Image message to JPEG format for efficient web streaming.


##### `update_diagnostics(self)`

Update diagnostics information for web UI.


##### `destroy_node(self)`

Clean up resources.


### Functions

#### `main(args)`

Main entry point for the mission agent node.


---

## Module: `shadowhound_mission_agent.mission_executor`

Mission Executor - Pure Python mission execution logic.

This module contains the core business logic for mission execution, separated from
ROS concerns. This separation enables:
- Testing without ROS infrastructure
- Reuse in scripts, notebooks, and web applications
- Clear separation of concerns (ROS vs business logic)

The MissionExecutor handles:
- Robot initialization (DIMOS UnitreeGo2)
- Agent initialization (DIMOS agents)
- Skill library setup
- Mission execution logic

It does NOT handle:
- ROS node initialization
- ROS topic publishers/subscribers
- ROS parameter handling
- ROS logging (uses standard Python logging)


### Class: `MissionExecutorConfig`

Configuration for MissionExecutor.


### Class: `MissionExecutor`

Pure Python mission executor using DIMOS framework.

This class contains the core mission execution logic without ROS dependencies.
It can be used in ROS nodes, scripts, notebooks, or web applications.

Example usage:
# In a ROS node
config = MissionExecutorConfig(agent_backend="cloud")
executor = MissionExecutor(config, logger=node.get_logger())
executor.initialize()
result = executor.execute_mission("patrol the perimeter")

# In a script
executor = MissionExecutor(MissionExecutorConfig())
executor.initialize()
result = executor.execute_mission("go to waypoint A")

# In a notebook
import logging
logger = logging.getLogger(__name__)
executor = MissionExecutor(MissionExecutorConfig(), logger=logger)
executor.initialize()


#### Methods

##### `__init__(self, config: MissionExecutorConfig, logger: Optional[logging.Logger])`

Initialize mission executor.

**Parameters:**
- `config`: Configuration for the executor
- `logger`: Optional logger (uses standard logging if not provided)


##### `initialize(self) -> None`

Initialize robot, skills, and agent.

This must be called before execute_mission(). Separated from __init__
to allow for explicit initialization timing (e.g., after ROS node is ready).

**Raises:**
- `RuntimeError`: If initialization fails


##### `execute_mission(self, command: str) -> tuple[str, dict]`

Execute a mission command.

**Parameters:**
- `command`: Natural language mission command

**Returns:**
- Tuple of (response string, timing dict)
Timing dict contains: agent_duration, total_duration, overhead_duration

**Raises:**
- `RuntimeError`: If executor not initialized or execution fails


##### `get_robot_status(self) -> Dict[str, Any]`

Get current robot status.

**Returns:**
- Dictionary with robot status information

**Raises:**
- `RuntimeError`: If robot not initialized


##### `get_available_skills(self) -> list`

Get list of available skills.

**Returns:**
- List of skill information

**Raises:**
- `RuntimeError`: If skills not initialized


##### `cleanup(self) -> None`

Clean up resources.


---

## Module: `shadowhound_mission_agent.rag_memory_example`

Example: Adding RAG memory to ShadowHound mission agent.

This example shows how to create a custom knowledge base for your robot
using DIMOS's semantic memory (RAG) capabilities.

Usage:
1. Copy relevant parts into mission_agent.py
2. Customize knowledge_base list with your data
3. Agent will automatically use RAG for all queries


### Class: `MissionMemoryManager`

Helper class to manage mission history and robot knowledge.


#### Methods

##### `__init__(self, use_local_embeddings)`

Initialize memory manager.

**Parameters:**
- `use_local_embeddings`: If True, use free local embeddings.
If False, use OpenAI embeddings (costs $).


##### `load_robot_knowledge(self)`

Load static robot knowledge into RAG database.


##### `add_mission_log(self, mission_data)`

Add a completed mission to the knowledge base.

**Parameters:**
- `mission_data`: Dict with mission details
{
    "command": str,
    "result": str,
    "battery_start": int,
    "battery_end": int,
    "duration_sec": float,
    "anomalies": list,
    "notes": str
}


##### `search(self, query, n_results, threshold)`

Search the knowledge base.

**Parameters:**
- `query`: Search query string
- `n_results`: Number of results to return
- `threshold`: Minimum similarity score (0-1)

**Returns:**
- List of (document, score) tuples


### Functions

#### `test_rag_memory()`

Test RAG memory with sample queries.


---

## Module: `shadowhound_mission_agent.web_interface`

Web interface for ShadowHound mission control.

Provides a FastAPI-based web server that can be embedded in any ROS2 node.
Designed to be reusable and independent of specific node implementation.


### Class: `MissionCommand`

**Inherits:** `BaseModel`

Mission command request model.


### Class: `MissionResponse`

**Inherits:** `BaseModel`

Mission command response model.


### Class: `WebInterface`

Reusable web interface for robot mission control.

This class provides a FastAPI server that can be embedded in any ROS2 node.
It handles HTTP requests and WebSocket connections for real-time updates.

**Example:**
>>> # In your ROS node
>>> def handle_command(cmd: str) -> dict:
...     # Your command processing logic
...     return {"success": True, "message": "Command executed"}
>>>
>>> web = WebInterface(
...     command_callback=handle_command,
...     port=8080
... )
>>> web.start()


#### Methods

##### `__init__(self, command_callback: Callable[[str], Dict[str, Any]], port: int, host: str, logger: Optional[logging.Logger])`

Initialize web interface.

**Parameters:**
- `command_callback`: Function to call when mission command received.
Should accept (command: str) and return dict with
'success' and 'message' keys.
- `port`: Port to run web server on (default: 8080)
- `host`: Host to bind to (default: 0.0.0.0 for all interfaces)
- `logger`: Optional logger instance


##### `broadcast_sync(self, message: str)`

Synchronous wrapper for broadcast (for use from non-async code).


##### `get_mock_image(self, camera: str) -> Optional[bytes]`

Get mock image data for specified camera.

This method can be called by vision skills to retrieve uploaded mock images
for testing without robot hardware.

**Parameters:**
- `camera`: Camera name ('front', 'left', 'right')

**Returns:**
- Image data as bytes, or None if no mock image available


##### `has_mock_image(self, camera: str) -> bool`

Check if mock image exists for specified camera.


##### `update_camera_frame(self, image_data: bytes)`

Update the latest camera frame.

**Parameters:**
- `image_data`: JPEG or PNG image bytes


##### `update_diagnostics(self, diagnostics: Dict[str, Any])`

Update diagnostics information.

**Parameters:**
- `diagnostics`: Dict containing robot_mode, topics_available, action_servers, etc.


##### `add_terminal_line(self, line: str)`

Add a line to the terminal buffer.

**Parameters:**
- `line`: Text line to add


##### `update_performance_metrics(self, timing_info: Dict[str, Any])`

Update performance metrics with new timing information.

**Parameters:**
- `timing_info`: Dict containing agent_duration, total_duration, overhead_duration


##### `start(self)`

Start web server in background thread.


##### `stop(self)`

Stop web server.


---

## References

- [[shadowhound_mission_agent|Package Overview]]
- [[_index|Return to Autodoc Index]]
