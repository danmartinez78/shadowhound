---
tags: [project, legacy]
status: draft
related: []
summary: >
  Legacy documentation preserved from earlier phases for review and migration.
---

# How ShadowHound Works with ChatGPT API

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
## Overview

ShadowHound uses the **DIMOS framework's OpenAIAgent** to communicate with ChatGPT. Your web interface and ROS topics send natural language commands that get processed through multiple layers before reaching OpenAI's API.

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER INPUT                                                   │
│    - Web Dashboard: http://localhost:8080                       │
│    - ROS Topic: ros2 topic pub /mission_command                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. SHADOWHOUND MISSION AGENT (Your Code)                       │
│    - mission_agent.py: MissionAgentNode                         │
│    - Receives command: "stand up and wave hello"                │
│    - Calls: self.agent.process_text(command)                    │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. DIMOS OPENAI AGENT (DIMOS Framework)                        │
│    - agent.py: OpenAIAgent class                                │
│    - Builds prompt with:                                        │
│      • System prompt (robot capabilities)                       │
│      • Available skills (40+ robot actions)                     │
│      • Conversation history                                     │
│      • Memory context (RAG)                                     │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. OPENAI API CALL                                              │
│    - client.chat.completions.create()                           │
│    - Model: gpt-4o (default) or gpt-4                           │
│    - Tools: Skill library (function calling)                    │
│    - Max tokens: 16,384 output                                  │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. CHATGPT RESPONSE                                             │
│    - Returns: Function call(s) to execute                       │
│    - Example: {"name": "stand", "args": {}}                     │
│              {"name": "wave", "args": {"leg": "front_right"}}   │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. SKILL EXECUTION (DIMOS)                                      │
│    - DIMOS executes the skills on the robot                     │
│    - Sends commands to Unitree Go2 hardware                     │
│    - Monitors execution and reports results                     │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. RESULT BACK TO USER                                          │
│    - ROS topic: /mission_status                                 │
│    - Web dashboard: WebSocket update                            │
│    - Status: "COMPLETED: stand up and wave hello"               │
└─────────────────────────────────────────────────────────────────┘
```

## Code Path

### 1. Your Mission Agent Node
**File**: `src/shadowhound_mission_agent/shadowhound_mission_agent/mission_agent.py`

```python
def mission_callback(self, msg: String):
    command = msg.data  # "stand up and wave hello"
    
    # Call DIMOS agent
    result = self.agent.process_text(command)  # ← Goes to DIMOS
```

### 2. DIMOS OpenAIAgent Initialization
**File**: `src/dimos-unitree/dimos/agents/agent.py` (lines 660-750)

```python
class OpenAIAgent(LLMAgent):
    def __init__(self,
                 model_name: str = "gpt-4o",  # ChatGPT model
                 skills: Optional[SkillLibrary] = None,  # Robot skills
                 ...):
        
        # Initialize OpenAI client (uses OPENAI_API_KEY env var)
        self.client = openai_client or OpenAI()
        
        # Set up skill library for function calling
        self.skill_library = SkillLibrary(skills)
```

### 3. Processing Text Commands
**File**: `src/dimos-unitree/dimos/agents/agent.py`

When you call `agent.process_text(command)`:

1. **Builds message list** with:
   - System prompt describing robot capabilities
   - Available skills as OpenAI "tools" (function calling format)
   - Conversation history
   - RAG context from semantic memory

2. **Calls `_send_query(messages)`**:

```python
def _send_query(self, messages: list) -> Any:
    """Sends the query to OpenAI's API."""
    
    # Make API call to ChatGPT
    response = self.client.chat.completions.create(
        model=self.model_name,        # "gpt-4o"
        messages=messages,             # Conversation with context
        max_tokens=16384,              # Output limit
        tools=self.skill_library.get_tools()  # Robot skills
    )
    
    return response.choices[0].message
```

### 4. ChatGPT Response Processing

ChatGPT responds with **function calls** (tool calls):

```json
{
  "role": "assistant",
  "content": null,
  "tool_calls": [
    {
      "id": "call_abc123",
      "type": "function",
      "function": {
        "name": "stand",
        "arguments": "{}"
      }
    },
    {
      "id": "call_def456",
      "type": "function",
      "function": {
        "name": "wave",
        "arguments": "{\"leg\": \"front_right\"}"
      }
    }
  ]
}
```

DIMOS then:
1. **Parses the tool calls**
2. **Executes each skill** from the library
3. **Sends results back** to ChatGPT (for multi-turn reasoning)
4. **Returns final result** to your mission agent

## Configuration

### Required Environment Variable

```bash
export OPENAI_API_KEY="sk-proj-..."
```

Without this, you'll get a warning:
```
OPENAI_API_KEY not set, agent may not function
```

### Model Selection

Default model is **gpt-4o** (fast, multimodal). You can change it:

```python
# In DIMOS agent initialization
agent = OpenAIAgent(
    robot=self.robot,
    model_name="gpt-4",           # Use GPT-4 instead
    # or model_name="gpt-4-turbo",
    # or model_name="gpt-3.5-turbo",
    ...
)
```

### Token Limits

```python
max_input_tokens_per_request: int = 128000   # Input context
max_output_tokens_per_request: int = 16384   # ChatGPT response
```

These are set in DIMOS and match gpt-4o's capabilities.

## Skills as OpenAI Tools

DIMOS converts robot skills into OpenAI's function calling format. Example:

### Skill Definition (Python)
```python
class StandSkill(AbstractSkill):
    name = "stand"
    description = "Make the robot stand up from sitting position"
    
    def execute(self, **kwargs):
        self.robot.stand()
        return "Robot standing"
```

### OpenAI Tool Format (JSON)
```json
{
  "type": "function",
  "function": {
    "name": "stand",
    "description": "Make the robot stand up from sitting position",
    "parameters": {
      "type": "object",
      "properties": {},
      "required": []
    }
  }
}
```

ChatGPT sees these as available functions it can call!

## Example: Full Flow

### User Input
```bash
curl -X POST http://localhost:8080/api/mission \
  -d '{"command": "stand up and do a little dance"}'
```

### 1. Mission Agent Receives
```python
command = "stand up and do a little dance"
result = self.agent.process_text(command)
```

### 2. DIMOS Builds Prompt
```python
messages = [
    {
        "role": "system",
        "content": "You are controlling a Unitree Go2 quadruped robot. Available skills: stand, sit, wave, dance, ..."
    },
    {
        "role": "user",
        "content": "stand up and do a little dance"
    }
]

tools = [
    {"type": "function", "function": {"name": "stand", ...}},
    {"type": "function", "function": {"name": "dance", ...}},
    # ... 40+ skills
]
```

### 3. Sends to OpenAI
```python
response = client.chat.completions.create(
    model="gpt-4o",
    messages=messages,
    tools=tools,
    max_tokens=16384
)
```

### 4. ChatGPT Responds
```json
{
  "tool_calls": [
    {"function": {"name": "stand", "arguments": "{}"}},
    {"function": {"name": "dance", "arguments": "{\"dance_id\": 1}"}}
  ]
}
```

### 5. DIMOS Executes
```python
# Execute skill 1
skill_registry.execute("stand")

# Execute skill 2
skill_registry.execute("dance", dance_id=1)
```

### 6. Result to User
```json
{
  "success": true,
  "message": "Mission completed: Executed stand, dance"
}
```

## Advanced Features

### 1. Conversation Memory
DIMOS maintains conversation history, so ChatGPT remembers context:

```bash
# First command
"stand up"

# Second command (ChatGPT knows robot is already standing)
"now wave"
```

### 2. Semantic Memory (RAG)
DIMOS uses ChromaDB to store and retrieve context:

```python
agent_memory.add_vector(
    "id0",
    "Optical Flow tracks object movement in video"
)

# Later, relevant context is automatically retrieved and added to prompt
```

### 3. Planning Agent
For complex missions, use `PlanningAgent` instead:

```python
# In mission_agent.py
self.agent = PlanningAgent(...)  # Instead of OpenAIAgent

# This agent creates a plan first, then executes
result = self.agent.plan_and_execute("patrol the perimeter")
```

Planning flow:
1. **Generate plan**: ChatGPT creates step-by-step plan
2. **Review plan**: User or system validates
3. **Execute plan**: Each step executed sequentially
4. **Adapt**: Can replan if steps fail

## API Costs

**Important**: Every command costs OpenAI API tokens!

### Typical Command Cost
```
Input tokens:  ~1,500-3,000   (system prompt + skills + history)
Output tokens: ~100-500       (response with tool calls)
Cost per call: ~$0.01-0.05    (with gpt-4o)
```

### Cost Optimization
1. **Use gpt-3.5-turbo** for simple commands (10x cheaper)
2. **Reduce skill library** size (fewer tools = smaller context)
3. **Clear conversation history** periodically
4. **Use mock robot** for testing (free!)

## Switching to Local Models

To avoid API costs, you can use local models:

```python
# Option 1: Use local OpenAI-compatible server
client = OpenAI(
    base_url="http://localhost:8000/v1",  # Local LLM server
    api_key="not-needed"
)

# Option 2: Use different provider
from anthropic import Anthropic
# DIMOS also supports Claude via ClaudeAgent
```

## Debugging

### See ChatGPT Prompts
Enable logging in DIMOS:

```python
import logging
logging.basicConfig(level=logging.DEBUG)

# You'll see full prompts and responses in logs
```

### Test Without Robot
```bash
ros2 launch shadowhound_mission_agent bringup.launch.py \
    mock_robot:=true

# Commands go to ChatGPT but robot execution is mocked
```

### Inspect Tool Calls
Check DIMOS logs for tool call details:

```
[INFO] Tool call: stand()
[INFO] Tool call: wave(leg='front_right')
[INFO] Skill execution: stand -> Success
[INFO] Skill execution: wave -> Success
```

## Summary

**Your Integration**:
```
Web/ROS → mission_agent.py → agent.process_text()
```

**DIMOS Does**:
1. Builds prompt with system context + skills
2. Calls OpenAI API with function calling
3. Parses ChatGPT's tool call responses
4. Executes skills on robot
5. Returns results

**ChatGPT Does**:
- Understands natural language command
- Reasons about which skills to use
- Returns function calls in correct order
- Maintains conversation context

**Key Files**:
- `mission_agent.py` (yours): ROS/Web → DIMOS bridge
- `dimos/agents/agent.py`: OpenAIAgent implementation
- `dimos/agents/planning_agent.py`: PlanningAgent for complex missions
- `dimos/skills/skills.py`: Skill library management

**Environment**:
```bash
export OPENAI_API_KEY="sk-..."  # Required!
```

**Models Supported**:
- gpt-4o (default, fastest, multimodal)
- gpt-4 (most capable, slower)
- gpt-4-turbo (balanced)
- gpt-3.5-turbo (cheapest, good for simple tasks)

Your ShadowHound web interface makes all of this accessible through a beautiful UI - users just type commands, and the entire ChatGPT → Skills → Robot chain happens automatically! 🚀


## Validation
- [ ] Legacy guidance reviewed for accuracy and converted to the new workflow where applicable.
- [ ] Links updated to use vault-friendly wikilinks or confirmed for external references.
- [ ] Outstanding migration work captured as tasks in the backlog.

## References
- [[integrations/integrations_hub|Knowledge Base Index]]
