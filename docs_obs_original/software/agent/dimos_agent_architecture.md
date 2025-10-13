# DIMOS Agent Architecture - Complete Reference

**Date:** October 12, 2025  
**Context:** Comprehensive investigation of DIMOS agent types, capabilities, and ShadowHound integration strategy  
**Related:** `dimos_development_policy.md`, `dimos_branch_consolidation.md`, `local_llm_memory_roadmap.md`

---

## TL;DR - Critical Findings

**Agent Capabilities Matrix:**

| Agent Type | Local LLM | Cloud LLM | Skills/Tools | Default Memory | Status |
|------------|-----------|-----------|--------------|----------------|--------|
| **OpenAIAgent** | ✅ (vLLM) | ✅ | ✅ Function Calling | OpenAISemanticMemory | ⭐ Recommended |
| **ClaudeAgent** | ❌ | ✅ | ✅ Function Calling | OpenAISemanticMemory | Production Ready |
| **PlanningAgent** | ✅ (vLLM) | ✅ | ✅ Function Calling | OpenAISemanticMemory | Production Ready |
| **HuggingFaceLocalAgent** | ✅ | ❌ | ❌ No Tools | LocalSemanticMemory | Limited Use |
| **HuggingFaceRemoteAgent** | ❌ | ✅ (HF API) | ❌ No Tools | LocalSemanticMemory | Legacy |
| **CTransformersGGUFAgent** | ✅ (GGUF) | ❌ | ❌ No Tools | LocalSemanticMemory | Experimental |

**Key Insights:**
- ✅ **Skills/function calling REQUIRES** OpenAIAgent, ClaudeAgent, or PlanningAgent
- ✅ **HuggingFaceLocalAgent has NO tools support** - Cannot use skills-based robot control
- ✅ **OpenAIAgent works with vLLM** - OpenAI-compatible API support
- ✅ **Local embeddings work with ANY agent** - Just pass `LocalSemanticMemory()` explicitly
- ⚠️ **DIMOS README is misleading** - Claims "OpenAI API key required for all LLMAgents" (NOT true)
- ⚠️ **Missing import bug in LocalSemanticMemory** - `SentenceTransformer` not imported (line 147)

**ShadowHound Decision:**
- **Using:** `OpenAIAgent` + vLLM + `LocalSemanticMemory` + `MyUnitreeSkills`
- **Why:** Only combination supporting local LLM + local memory + robot control skills
- **Blocker:** 1-line import fix needed in DIMOS `chroma_impl.py` 

---

## Table of Contents

1. [Agent Type Comparison](#agent-type-comparison)
2. [Skills/Function Calling Architecture](#skillsfunction-calling-architecture)
3. [Memory System Architecture](#memory-system-architecture)
4. [Local LLM Support](#local-llm-support)
5. [Local Embeddings Support](#local-embeddings-support)
6. [ShadowHound Implementation](#shadowhound-implementation)
7. [Configuration Examples](#configuration-examples)
8. [Known Issues and Bugs](#known-issues-and-bugs)
9. [Recommendations](#recommendations)

---

## Agent Type Comparison

### 1. OpenAIAgent (⭐ Recommended for ShadowHound)

**File:** `dimos/agents/agent.py` (line 660)  
**Inherits:** `LLMAgent`

**Capabilities:**
- ✅ OpenAI-compatible API (works with OpenAI, Azure, vLLM, LocalAI, etc.)
- ✅ Function calling / tools support
- ✅ Vision capabilities (multimodal)
- ✅ Structured outputs (response_model)
- ✅ RAG with agent memory
- ✅ Token counting and limits

**Parameters:**
```python
def __init__(self,
    dev_name: str,
    agent_type: str = "Vision",
    query: str = "What do you see?",
    input_query_stream: Optional[Observable] = None,
    input_data_stream: Optional[Observable] = None,
    input_video_stream: Optional[Observable] = None,
    output_dir: str = "assets/agent",
    agent_memory: Optional[AbstractAgentSemanticMemory] = None,  # ⚠️ Defaults to OpenAISemanticMemory
    system_query: Optional[str] = None,
    max_input_tokens_per_request: int = 128000,
    max_output_tokens_per_request: int = 16384,
    model_name: str = "gpt-4o",
    prompt_builder: Optional[PromptBuilder] = None,
    tokenizer: Optional[AbstractTokenizer] = None,
    rag_query_n: int = 4,
    rag_similarity_threshold: float = 0.45,
    skills: Optional[Union[AbstractSkill, list[AbstractSkill], SkillLibrary]] = None,  # ⭐ Skills support
    response_model: Optional[BaseModel] = None,
    frame_processor: Optional[FrameProcessor] = None,
    image_detail: str = "low",
    pool_scheduler: Optional[ThreadPoolScheduler] = None,
    process_all_inputs: Optional[bool] = None,
):
```

**Skills Implementation:**
```python
# Lines 748-758 in agent.py
self.skills = skills
if isinstance(self.skills, SkillLibrary):
    self.skill_library = self.skills
elif isinstance(self.skills, list):
    self.skill_library = SkillLibrary()
    for skill in self.skills:
        self.skill_library.add(skill)
elif isinstance(self.skills, AbstractSkill):
    self.skill_library = SkillLibrary()
    self.skill_library.add(self.skills)
```

**Use Cases:**
- Primary agent for cloud OpenAI/Azure deployments
- ⭐ **ShadowHound:** Local vLLM + local embeddings + robot skills
- Any scenario requiring function calling / tools
- Vision tasks requiring image understanding

**Example:**
```python
from dimos.agents.agent import OpenAIAgent
from dimos.agents.memory.chroma_impl import LocalSemanticMemory
from dimos.robot.unitree.unitree_skills import MyUnitreeSkills

agent = OpenAIAgent(
    dev_name="ShadowHound",
    model_name="Qwen/Qwen2.5-Coder-7B-Instruct",
    agent_memory=LocalSemanticMemory(),  # ⚠️ Must pass explicitly for local
    skills=MyUnitreeSkills(robot=robot),  # ⭐ Robot control skills
)
```

---

### 2. ClaudeAgent

**File:** `dimos/agents/claude_agent.py` (line 77)  
**Inherits:** `LLMAgent`

**Capabilities:**
- ✅ Anthropic Claude API
- ✅ Function calling / tools support (Claude-specific format)
- ✅ Extended thinking mode (thinking_budget_tokens)
- ✅ Vision capabilities
- ✅ Structured outputs
- ✅ RAG with agent memory

**Parameters:**
```python
def __init__(self,
    dev_name: str,
    agent_type: str = "Vision",
    # ... (similar to OpenAIAgent)
    model_name: str = "claude-3-7-sonnet-20250219",
    skills: Optional[AbstractSkill] = None,  # ⭐ Skills support
    thinking_budget_tokens: Optional[int] = 2000,  # Claude-specific
):
```

**Skills Implementation:**
Similar to OpenAIAgent but converts tools to Claude-specific format:
```python
def _convert_tools_to_claude_format(self, tools: List[Dict]) -> List[Dict]:
    # Converts OpenAI tool format to Claude format
```

**Use Cases:**
- Cloud deployments requiring Claude's extended thinking
- Tasks requiring very long context (200K+ tokens)
- Alternative to OpenAI with similar capabilities

---

### 3. PlanningAgent (Specialized OpenAIAgent)

**File:** `dimos/agents/planning_agent.py` (line 38)  
**Inherits:** `OpenAIAgent`

**Capabilities:**
- ✅ All OpenAIAgent capabilities
- ✅ Task decomposition and planning
- ✅ Multi-turn dialogue for plan refinement
- ✅ Structured plan output (list of steps)
- ✅ Plan confirmation workflow

**Parameters:**
```python
def __init__(self,
    dev_name: str = "PlanningAgent",
    model_name: str = "gpt-4",
    input_query_stream: Optional[Observable] = None,
    use_terminal: bool = False,
    skills: Optional[AbstractSkill] = None,  # ⭐ Skills support
):
```

**Specialized Behavior:**
- Returns structured JSON: `{"type": "dialogue"|"plan", "content": ..., "needs_confirmation": bool}`
- Maintains conversation history for iterative refinement
- Breaks complex tasks into executable skill calls

**Use Cases:**
- Complex missions requiring multi-step planning
- Tasks where user confirmation is needed before execution
- High-level mission orchestration

**Example:**
```python
from dimos.agents.planning_agent import PlanningAgent

agent = PlanningAgent(
    dev_name="MissionPlanner",
    model_name="gpt-4o",
    skills=MyUnitreeSkills(robot=robot),
)
# Returns plans like: ["Move forward 2m", "Rotate 90 degrees", "Move forward 1m"]
```

---

### 4. HuggingFaceLocalAgent

**File:** `dimos/agents/agent_huggingface_local.py` (line 47)  
**Inherits:** `LLMAgent`

**Capabilities:**
- ✅ 100% local LLM execution (no API)
- ✅ Loads models via transformers (AutoModelForCausalLM)
- ✅ GPU/CPU auto-detection
- ✅ Local embeddings by default
- ❌ **NO skills/function calling support**
- ❌ No vision capabilities

**Parameters:**
```python
def __init__(self,
    dev_name: str,
    agent_type: str = "HF-LLM",
    query: str = "What do you see?",
    model_name: str = "Qwen/Qwen2.5-3B",
    system_query: Optional[str] = None,
    agent_memory: Optional[AbstractAgentSemanticMemory] = None,  # ⚠️ Defaults to LocalSemanticMemory
    max_output_tokens_per_request: int = 512,
    do_sample: bool = True,
    temperature: float = 0.1,
    top_p: float = 0.95,
    top_k: int = 50,
):
```

**Implementation Details:**
```python
# Lines 79: Defaults to local memory
agent_memory = agent_memory or LocalSemanticMemory()

# Lines 135-220: Simple text generation, NO tools
def _send_query(self, query: str, images: list = None) -> str:
    # Just generates text - no function calling!
    prompt = self._build_prompt(query)
    inputs = self.tokenizer(prompt, return_tensors="pt").to(self.device)
    outputs = self.model.generate(...)
    return self.tokenizer.decode(outputs[0], skip_special_tokens=True)
```

**⚠️ Critical Limitation:**
```bash
$ grep -n "skills\|tools\|function" dimos/agents/agent_huggingface_local.py
# Returns: (empty) - NO skills support!
```

**Use Cases:**
- Simple text generation tasks
- Deployments requiring 100% local operation (no API dependencies)
- Scenarios where skills/function calling NOT needed
- ❌ **NOT suitable for ShadowHound** - Cannot control robot via skills

**Example:**
```python
from dimos.agents.agent_huggingface_local import HuggingFaceLocalAgent

agent = HuggingFaceLocalAgent(
    dev_name="TextAgent",
    model_name="Qwen/Qwen2.5-3B",
    # agent_memory defaults to LocalSemanticMemory automatically
)
response = agent.send_query("Describe the scene")  # Text only, no actions
```

---

### 5. HuggingFaceRemoteAgent

**File:** `dimos/agents/agent_huggingface_remote.py` (line 44)  
**Inherits:** `LLMAgent`

**Capabilities:**
- ✅ HuggingFace Inference API
- ✅ Access to HF hosted models
- ✅ Local embeddings by default
- ❌ **NO skills/function calling support**
- ❌ No vision capabilities

**Status:** Similar to HuggingFaceLocalAgent but uses HF API instead of local loading. Legacy option.

---

### 6. CTransformersGGUFAgent

**File:** `dimos/agents/agent_ctransformers_gguf.py` (line 86)  
**Inherits:** `LLMAgent`

**Capabilities:**
- ✅ Runs GGUF quantized models
- ✅ CPU-optimized inference
- ✅ Low memory footprint
- ✅ Local embeddings by default
- ❌ **NO skills/function calling support**

**Status:** Experimental. For resource-constrained deployments. No skills support.

---

## Skills/Function Calling Architecture

### What Are Skills?

Skills in DIMOS are **executable functions that agents can call** to interact with the world:

```python
from dimos.skills.skills import AbstractSkill, SkillLibrary
from pydantic import Field

class Move(AbstractSkill):
    """Move the robot using direct velocity commands."""
    
    x: float = Field(..., description="Forward velocity (m/s)")
    y: float = Field(default=0.0, description="Left/right velocity (m/s)")
    yaw: float = Field(default=0.0, description="Rotational velocity (rad/s)")
    
    def __call__(self):
        super().__call__()
        return self._robot.move_vel(x=self.x, y=self.y, yaw=self.yaw)
```

### How Skills Work

1. **Registration:** Skills are added to a `SkillLibrary`
2. **Tool Schema Generation:** Skills are converted to OpenAI tool format
3. **LLM Decision:** Agent decides which skill to call based on context
4. **Execution:** Skill is invoked with parsed parameters
5. **Result:** Skill returns result to agent for next decision

### Agent Support Matrix

| Agent Type | Skills Support | Implementation |
|------------|----------------|----------------|
| OpenAIAgent | ✅ Yes | Native OpenAI function calling |
| ClaudeAgent | ✅ Yes | Claude tool use API |
| PlanningAgent | ✅ Yes | Inherits from OpenAIAgent |
| HuggingFaceLocalAgent | ❌ No | Simple text generation only |
| HuggingFaceRemoteAgent | ❌ No | Simple text generation only |
| CTransformersGGUFAgent | ❌ No | Simple text generation only |

### ShadowHound Skills

**MyUnitreeSkills** provides robot control:

```python
from dimos.robot.unitree.unitree_skills import MyUnitreeSkills

class MyUnitreeSkills(SkillLibrary):
    # Dynamically generated skills from UNITREE_ROS_CONTROLS
    # + Custom skills:
    
    class Move(AbstractRobotSkill):
        """Move the robot using direct velocity commands."""
        # Calls: self._robot.move_vel()
    
    class Reverse(AbstractRobotSkill):
        """Reverse the robot using direct velocity commands."""
        # Calls: self._robot.move_vel() with negative x
    
    class SpinLeft(AbstractRobotSkill):
        """Spin the robot left using degree commands."""
        # Calls: self._robot.spin(degrees=positive)
    
    class SpinRight(AbstractRobotSkill):
        """Spin the robot right using degree commands."""
        # Calls: self._robot.spin(degrees=negative)
    
    class Wait(AbstractSkill):
        """Wait for a specified amount of time."""
        # Calls: time.sleep()
```

**Critical Point:** Without skills support, ShadowHound **cannot control the robot**. The agent would only generate text describing what it should do, but couldn't execute commands.

---

## Memory System Architecture

---

## Memory System Architecture

### Memory Types in DIMOS

**Location:** `dimos/agents/memory/chroma_impl.py`

DIMOS provides two ChromaDB-based memory implementations:

#### 1. OpenAISemanticMemory (Cloud)

```python
class OpenAISemanticMemory(ChromaAgentSemanticMemory):
    """Uses OpenAI embeddings API (requires OPENAI_API_KEY)"""
    
    def __init__(
        self,
        collection_name: str = "agent_memory",
        model_name: str = "text-embedding-3-large",
        persist_dir: str = "~/.chroma",
    ):
        # Uses OpenAIEmbeddings from langchain-openai
        embedding_function = OpenAIEmbeddings(model=model_name)
```

**Dependencies:** `langchain-openai`, `chromadb`  
**API Endpoint:** `https://api.openai.com/v1/embeddings`  
**Cost:** ~$0.13 per 1M tokens

#### 2. LocalSemanticMemory (Local) ⭐

```python
class LocalSemanticMemory(ChromaAgentSemanticMemory):
    """Uses local sentence-transformers for embeddings (no API required)"""
    
    def __init__(
        self,
        collection_name: str = "agent_memory",
        model_name: str = "sentence-transformers/all-MiniLM-L6-v2",
        persist_dir: str = "~/.chroma",
    ):
        # ⚠️ BUG: Line 147 - SentenceTransformer not imported!
        self.model = SentenceTransformer(self.model_name, device=device)
```

**Dependencies:** `sentence-transformers`, `chromadb`, `langchain-chroma`  
**Model:** 384-dimensional embeddings, ~80MB download  
**Cost:** Free (runs locally)

**⚠️ Known Bug (Line 147):**
```python
# Missing import at top of file:
from sentence_transformers import SentenceTransformer

# Error when initializing:
NameError: name 'SentenceTransformer' is not defined
```

### Default Memory by Agent Type

| Agent Type | Default Memory |
|------------|----------------|
| OpenAIAgent | `OpenAISemanticMemory()` |
| ClaudeAgent | `OpenAISemanticMemory()` |
| PlanningAgent | `OpenAISemanticMemory()` (inherits from OpenAI) |
| HuggingFaceLocalAgent | `LocalSemanticMemory()` ✅ |
| HuggingFaceRemoteAgent | `LocalSemanticMemory()` ✅ |
| CTransformersGGUFAgent | `LocalSemanticMemory()` ✅ |

**Key Insight:** You can override any agent's default memory by passing `agent_memory` parameter explicitly!

```python
# OpenAIAgent with LOCAL embeddings (our use case!)
agent = OpenAIAgent(
    dev_name="ShadowHound",
    agent_memory=LocalSemanticMemory(),  # ⭐ Override default
    skills=MyUnitreeSkills(robot=robot),
)
```

---

## Local LLM Support

### Option 1: HuggingFaceLocalAgent (Fully Local)
### Option 1: HuggingFaceLocalAgent (Fully Local)

**Best for:** Simple text generation without skills/function calling

```python
from dimos.agents.agent_huggingface_local import HuggingFaceLocalAgent

agent = HuggingFaceLocalAgent(
    dev_name="LocalAgent",
    model_name="Qwen/Qwen2.5-3B",
    # agent_memory defaults to LocalSemanticMemory() automatically
)
```

**Pros:**
- ✅ 100% local (no API dependencies)
- ✅ Defaults to LocalSemanticMemory automatically
- ✅ GPU/CPU auto-detection

**Cons:**
- ❌ NO skills/function calling support
- ❌ Cannot control robot via MyUnitreeSkills
- ❌ Text generation only

### Option 2: OpenAIAgent + vLLM (⭐ ShadowHound's Choice)

**Best for:** Local LLM with skills/function calling support

**Architecture:**
```
┌─────────────────────────────────────┐
│ OpenAIAgent                         │
│   ├─ skills: MyUnitreeSkills       │ ← Robot control
│   ├─ agent_memory: LocalSemanticM. │ ← Local embeddings
│   └─ model: vLLM API endpoint      │ ← Local LLM
└──────────────┬──────────────────────┘
               │
               ▼
    Thor: vLLM (OpenAI-compatible API)
    - Model: Qwen/Qwen2.5-Coder-7B-Instruct
    - Port: 8000
    - Endpoint: http://192.168.10.116:8000/v1
```

**Configuration:**
```bash
# .env
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
# USE_LOCAL_EMBEDDINGS auto-detected as true (non-OpenAI URL)
```

**Code:**
```python
from dimos.agents.agent import OpenAIAgent
from dimos.agents.memory.chroma_impl import LocalSemanticMemory
from dimos.robot.unitree.unitree_skills import MyUnitreeSkills

agent = OpenAIAgent(
    dev_name="ShadowHound",
    model_name="Qwen/Qwen2.5-Coder-7B-Instruct",
    agent_memory=LocalSemanticMemory(),  # ⚠️ Must pass explicitly!
    skills=MyUnitreeSkills(robot=robot),  # ⭐ Robot control
)
```

**Pros:**
- ✅ Local LLM via vLLM (no cloud API costs)
- ✅ Local embeddings via sentence-transformers
- ✅ Skills/function calling support
- ✅ Robot control via MyUnitreeSkills
- ✅ OpenAI-compatible (easy to switch to cloud if needed)

**Cons:**
- ⚠️ Requires vLLM server setup (separate process)
- ⚠️ Must explicitly pass LocalSemanticMemory (doesn't default)
- ⚠️ Requires fixing DIMOS import bug (1 line)

### vLLM Setup on Thor (Jetson AGX Orin)

**Container:**
```bash
docker run -d \
  --name vllm \
  --gpus all \
  --shm-size 8g \
  -p 8000:8000 \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  nvcr.io/nvidia/vllm:25.09-py3 \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --dtype float16 \
  --max-model-len 4096 \
  --gpu-memory-utilization 0.9
```

**Verify:**
```bash
curl http://192.168.10.116:8000/v1/models
# Response: {"data": [{"id": "Qwen/Qwen2.5-Coder-7B-Instruct", ...}]}
```

**⚠️ Important:** vLLM does NOT provide `/v1/embeddings` endpoint - this is why we need LocalSemanticMemory!

---

## Local Embeddings Support

## Local Embeddings Support

### LocalSemanticMemory Implementation

**File:** `dimos/agents/memory/chroma_impl.py`

```python
class LocalSemanticMemory(ChromaAgentSemanticMemory):
    """Uses local sentence-transformers for embeddings (no API required)"""
    
    def __init__(
        self,
        collection_name: str = "agent_memory",
        model_name: str = "sentence-transformers/all-MiniLM-L6-v2",
        persist_dir: str = "~/.chroma",
    ):
        # Embedding function using local sentence-transformers
        embedding_function = self._create_embedding_function()
        
        # Initialize ChromaDB
        self.collection_name = collection_name
        self.model_name = model_name
        # ...
```

### Dependencies

**Required packages:**
```bash
pip install chromadb>=0.4.22 langchain-chroma sentence-transformers
```

**Model download (first run only):**
- `sentence-transformers/all-MiniLM-L6-v2` (~80MB)
- Cached in `~/.cache/huggingface/`

### Verifying Local Embeddings

**Test script:** `scripts/test_local_embeddings.py`

```bash
cd /workspaces/shadowhound
python3 scripts/test_local_embeddings.py
```

**Expected output:**
```
✅ All dependencies installed
✅ Model loaded: sentence-transformers/all-MiniLM-L6-v2
✅ Test embeddings generated: 384 dimensions
✅ ChromaDB collection created
✅ Documents stored successfully
✅ Semantic search working
✅ All tests passed!
```

### ⚠️ Known Bug: Missing Import

**Location:** `dimos/agents/memory/chroma_impl.py` line 147

**Error:**
```python
NameError: name 'SentenceTransformer' is not defined
```

**Root Cause:**
```python
# Line 147:
self.model = SentenceTransformer(self.model_name, device=device)

# But imports section (lines 1-40) is MISSING:
from sentence_transformers import SentenceTransformer
```

**Fix (1 line):**
```python
# Add to imports at top of file:
from sentence_transformers import SentenceTransformer
```

**Status:** Identified, fix pending (waiting for DIMOS branch consolidation)

---

## ShadowHound Implementation

> **Agent API keys**
> 
> Full functionality will require API keys for the following:
> 
> Requirements: 
> - **OpenAI API key (required for all LLMAgents due to OpenAIEmbeddings)**
> - Claude API key (required for ClaudeAgent)
> - Alibaba API key (required for Navigation skills)

**This is WRONG!** 

- `HuggingFaceLocalAgent` defaults to `LocalSemanticMemory()` (no OpenAI key needed)
- Any agent can use `LocalSemanticMemory` if you pass it explicitly
- OpenAI key is only required if using `OpenAISemanticMemory`

**Why the confusion?**
- Most DIMOS examples use `OpenAIAgent` without passing `agent_memory`
- `OpenAIAgent` defaults to `OpenAISemanticMemory()` if no `agent_memory` provided
- But this is just a default, not a requirement!

---

## Test Examples from DIMOS Repository

### With HuggingFaceLocalAgent + Local Embeddings
```python
# tests/test_agent_huggingface_local.py
from dimos.agents.agent_huggingface_local import HuggingFaceLocalAgent

agent = HuggingFaceLocalAgent(
    dev_name="HuggingFaceLLMAgent",
    model_name="Qwen/Qwen2.5-3B",
    # agent_memory defaults to LocalSemanticMemory()
)
```

### With OpenAIAgent + OpenAI Embeddings
```python
# tests/test_unitree_agent.py
from dimos.agents.agent import OpenAIAgent

agent = OpenAIAgent(
    dev_name="UnitreePerceptionAgent",
    # agent_memory defaults to OpenAISemanticMemory()
)
```

### ChromaDB Direct Usage (No Agent)
```python
# tests/test_standalone_chromadb.py
from langchain_openai import OpenAIEmbeddings
from langchain_chroma import Chroma

embeddings = OpenAIEmbeddings(
    model="text-embedding-3-large",
    api_key=OPENAI_API_KEY,
)
db_connection = Chroma(
    collection_name="my_collection",
    embedding_function=embeddings,
)
```

**⚠️ Missing:** No example of `OpenAIAgent` + `LocalSemanticMemory` + vLLM!

---

## Summary and Key Takeaways

### What We Learned

1. **Skills/Function Calling is Critical**
   - Only OpenAIAgent, ClaudeAgent, and PlanningAgent support skills
   - HuggingFaceLocalAgent, HuggingFaceRemoteAgent, CTransformersGGUFAgent do NOT
   - Without skills, cannot control robot via MyUnitreeSkills

2. **Local LLM + Local Embeddings is Possible**
   - vLLM provides OpenAI-compatible API for local LLMs
   - sentence-transformers provides local embeddings
   - OpenAIAgent works with both (not just OpenAI cloud)

3. **Agent Memory is Separate from LLM**
   - Can mix: local LLM + cloud embeddings
   - Can mix: cloud LLM + local embeddings
   - Default memory depends on agent type

4. **DIMOS Has Bugs**
   - LocalSemanticMemory missing import (line 147)
   - AgentMemoryConnectionError.__str__() bug (fixed)
   - Documentation is misleading/incomplete

5. **OpenAIAgent is Most Flexible**
   - Works with OpenAI, Azure, vLLM, LocalAI
   - Supports skills/function calling
   - Can use any memory backend

### ShadowHound Architecture (Final)

```
┌─────────────────────────────────────────────────────┐
│ ShadowHound Mission Agent                           │
│                                                     │
│ OpenAIAgent                                         │
│   ├─ LLM: vLLM (Thor Jetson)                       │ ← Qwen2.5-Coder-7B
│   │   └─ http://192.168.10.116:8000/v1             │
│   │                                                 │
│   ├─ Memory: LocalSemanticMemory                   │ ← ChromaDB + sentence-transformers
│   │   ├─ Model: all-MiniLM-L6-v2                   │
│   │   └─ Storage: ~/.chroma/                       │
│   │                                                 │
│   └─ Skills: MyUnitreeSkills                       │ ← Robot control
│       ├─ Move(x, y, yaw, duration)                 │
│       ├─ Reverse(x, y, yaw, duration)              │
│       ├─ SpinLeft(degrees)                         │
│       ├─ SpinRight(degrees)                        │
│       └─ Wait(seconds)                             │
│                                                     │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
         Unitree Go2 Robot
         (WebRTC via go2_ros2_sdk)
```

**Status:**
- ✅ Architecture validated
- ✅ Dependencies installed
- ⚠️ Blocked by DIMOS import bug
- 📋 Next: Consolidate DIMOS branches + apply fix

---

## References and Links

### DIMOS Source Files
- Base Agent Interface: `dimos/agents/agent.py`
- OpenAIAgent: `dimos/agents/agent.py` (line 660)
- ClaudeAgent: `dimos/agents/claude_agent.py`
- PlanningAgent: `dimos/agents/planning_agent.py`
- HuggingFaceLocalAgent: `dimos/agents/agent_huggingface_local.py`
- Memory Implementations: `dimos/agents/memory/chroma_impl.py`
- Skills Base: `dimos/skills/skills.py`
- Unitree Skills: `dimos/robot/unitree/unitree_skills.py`

### DIMOS Test Files
- HuggingFace Local Tests: `tests/test_agent_huggingface_local*.py`
- Unitree Agent Tests: `tests/test_unitree_agent.py`
- ChromaDB Tests: `tests/test_standalone_chromadb.py`

### ShadowHound Files
- Mission Executor: `src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py`
- Test Script: `scripts/test_local_embeddings.py`
- Documentation:
  - This file: `docs/dimos_local_llm_findings.md`
  - Branch consolidation: `docs/dimos_branch_consolidation.md`
  - Development policy: `docs/dimos_development_policy.md`
  - Local memory roadmap: `docs/local_llm_memory_roadmap.md`

### External Resources
- vLLM Documentation: https://docs.vllm.ai/
- sentence-transformers: https://www.sbert.net/
- ChromaDB: https://docs.trychroma.com/
- OpenAI API (compatibility reference): https://platform.openai.com/docs/api-reference

---

**Document Version:** 2.0  
**Last Updated:** October 12, 2025  
**Next Review:** After DIMOS branch consolidation and fix application

---

## Bug Found and Fixed

### AgentMemoryConnectionError.__str__() AttributeError

**Location:** `dimos/exceptions/agent_memory_exceptions.py` line 44

**Bug:**
```python
def __str__(self):
    return f"{self.message}\nCaused by: {repr(self.cause)}" if self.cause else self.message
    # ERROR: self.message doesn't exist!
```

**Why it failed:**
- Python's `Exception` class stores the message in `args[0]`, not as a `message` attribute
- When exception is converted to string (e.g., during logging), it crashes

**Fix:**
```python
def __str__(self):
    # Python Exception stores message in args[0], not as self.message attribute
    message = self.args[0] if self.args else "Unknown error"
    return f"{message}\nCaused by: {repr(self.cause)}" if self.cause else message
```

**Fixed in DIMOS commit:** cfcaa24

---

## ShadowHound Implementation

### Architecture Decision

**Goal:** Fully local AI stack with robot control

**Requirements:**
1. ✅ Local LLM (no cloud API costs/latency)
2. ✅ Local embeddings (no cloud API costs)
3. ✅ Skills/function calling (robot control)
4. ✅ Vector memory (RAG for context)

**Agent Evaluation:**

| Requirement | HuggingFaceLocalAgent | OpenAIAgent + vLLM |
|-------------|----------------------|---------------------|
| Local LLM | ✅ Yes | ✅ Yes (via vLLM) |
| Local Embeddings | ✅ Yes (default) | ✅ Yes (explicit) |
| Skills Support | ❌ **NO** | ✅ **YES** |
| Robot Control | ❌ Cannot use MyUnitreeSkills | ✅ Full support |

**Decision:** OpenAIAgent + vLLM + LocalSemanticMemory ⭐

**Why:** Only combination meeting all requirements. HuggingFaceLocalAgent cannot control robot due to missing skills support.

### Implementation in mission_executor.py

**File:** `src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py`

#### 1. Auto-Detection Logic (Lines 260-285)

```python
# Determine embeddings strategy based on backend and configuration
use_local_env = os.getenv("USE_LOCAL_EMBEDDINGS", "").lower()

if use_local_env in ("true", "false"):
    # User explicitly set preference
    use_local_embeddings = use_local_env == "true"
else:
    # Auto-detect based on OPENAI_BASE_URL
    base_url = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
    use_local_embeddings = "api.openai.com" not in base_url
    
self.logger.info(f"📊 Using local embeddings: {use_local_embeddings}")
```

**Logic:**
1. Explicit `USE_LOCAL_EMBEDDINGS=true/false` takes precedence
2. Otherwise, detect based on `OPENAI_BASE_URL`:
   - Contains `api.openai.com` → Use OpenAI embeddings
   - Any other URL (vLLM, LocalAI, etc.) → Use local embeddings

#### 2. LocalSemanticMemory Initialization (Lines 288-323)

```python
if use_local_embeddings:
    try:
        from dimos.agents.memory.chroma_impl import LocalSemanticMemory
        
        agent_memory = LocalSemanticMemory(
            collection_name="shadowhound_memory",
            model_name="sentence-transformers/all-MiniLM-L6-v2",
        )
        self.logger.info("✅ LocalSemanticMemory initialized")
        
    except ImportError as e:
        # Missing dependencies
        self.logger.warning("⚠ LocalSemanticMemory dependencies not installed")
        self.logger.warning(f"  Install: pip install chromadb langchain-chroma sentence-transformers")
        agent_memory = "skip"  # Prevent None (which triggers OpenAISemanticMemory)
        
    except Exception as e:
        # DIMOS bugs or initialization failures
        error_msg = str(e)
        self.logger.warning(f"⚠ Failed to initialize LocalSemanticMemory: {error_msg}")
        
        if "SentenceTransformer" in error_msg or "name 'SentenceTransformer' is not defined" in error_msg:
            self.logger.error("🐛 DIMOS Bug: Missing import in chroma_impl.py line 147")
            self.logger.error("   Fix: Add 'from sentence_transformers import SentenceTransformer'")
        
        agent_memory = "skip"
else:
    agent_memory = None  # OpenAIAgent will auto-create OpenAISemanticMemory
```

**Graceful Fallback:**
- Catches `ImportError` (missing packages)
- Catches `Exception` (DIMOS bugs)
- Sets `agent_memory="skip"` to prevent `None` (which triggers OpenAISemanticMemory)
- Provides actionable error messages

#### 3. OpenAIAgent Initialization (Lines 334-360)

```python
# Prepare agent kwargs
agent_kwargs = {
    "dev_name": "shadowhound",
    "model_name": model_name,
    "skills": self.skills,  # ⭐ MyUnitreeSkills
    "input_video_stream": self.robot.video_rx_stream,
    "system_query": dedent("""
        You are ShadowHound, an autonomous Unitree Go2 quadruped robot...
    """),
}

# Only pass agent_memory if we successfully created one
if agent_memory != "skip":
    agent_kwargs["agent_memory"] = agent_memory
    self.logger.info("✅ Using configured agent_memory")
else:
    self.logger.warning("⚠ Running without memory (no RAG)")

# Initialize agent
self.agent = OpenAIAgent(**agent_kwargs)
```

**Key Points:**
- Always passes `skills=MyUnitreeSkills` for robot control
- Only passes `agent_memory` if initialization succeeded
- If `agent_memory` not passed and backend is OpenAI cloud, defaults to OpenAISemanticMemory
- If `agent_memory` not passed and backend is vLLM, will try OpenAISemanticMemory and fail (no embeddings endpoint)

#### 4. Skills Initialization (Lines 175-215)

```python
from dimos.robot.unitree.unitree_skills import MyUnitreeSkills

self.skills = MyUnitreeSkills(robot=self.robot)

self.logger.info(f"✅ Initialized {len(list(self.skills))} robot skills:")
for skill in self.skills:
    self.logger.info(f"   - {skill.__name__}")
```

**Output:**
```
✅ Initialized 5 robot skills:
   - Move
   - Reverse
   - SpinLeft
   - SpinRight
   - Wait
```

### Configuration Files

#### .env (Development - vLLM on Thor)

```bash
# Agent Backend
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
# OPENAI_API_KEY not needed for vLLM

# Embeddings (auto-detected as local due to non-OpenAI URL)
# USE_LOCAL_EMBEDDINGS=true  # Optional explicit override

# Robot
MOCK_ROBOT=false
CONN_TYPE=webrtc
GO2_IP=192.168.1.103
```

#### .env (Production - Cloud Fallback)

```bash
# Agent Backend
AGENT_BACKEND=openai
# OPENAI_BASE_URL defaults to https://api.openai.com/v1
OPENAI_MODEL=gpt-4o
OPENAI_API_KEY=sk-...

# Embeddings (auto-detected as cloud)
# Uses OpenAISemanticMemory automatically

# Robot
MOCK_ROBOT=false
CONN_TYPE=webrtc
GO2_IP=192.168.1.103
```

### Testing the Stack

**1. Test embeddings dependencies:**
```bash
python3 scripts/test_local_embeddings.py
# Should pass after DIMOS bug fixed
```

**2. Test mission agent:**
```bash
./start.sh
# Check logs for:
# ✅ LocalSemanticMemory initialized
# ✅ Initialized 5 robot skills
# ✅ DIMOS OpenAI-compatible agent initialized
```

**3. Test robot control:**
```bash
# In mission agent terminal, give command:
"Move forward 2 meters"

# Should see:
# - LLM generates skill call: Move(x=0.5, duration=4.0)
# - Skill executes: robot moves forward
# - Result stored in memory for future context
```

---

## Configuration Examples

## Configuration Examples

### 1. Local LLM + Local Embeddings (⭐ ShadowHound Production)

**Use Case:** Fully autonomous robot with no cloud dependencies

```bash
# .env
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
# USE_LOCAL_EMBEDDINGS auto-detected as true
```

**Stack:**
- LLM: vLLM on Thor (Jetson AGX Orin)
- Embeddings: sentence-transformers/all-MiniLM-L6-v2
- Vector DB: ChromaDB (~/.chroma/)
- Agent: OpenAIAgent with MyUnitreeSkills

**Benefits:**
- ✅ Zero cloud costs
- ✅ Low latency (LAN only)
- ✅ Works offline
- ✅ Full robot control
- ✅ Semantic memory/RAG

### 2. Cloud LLM + Cloud Embeddings

**Use Case:** Maximum quality, don't care about costs

```bash
# .env
AGENT_BACKEND=openai
# OPENAI_BASE_URL defaults to https://api.openai.com/v1
OPENAI_MODEL=gpt-4o
OPENAI_API_KEY=sk-...
# USE_LOCAL_EMBEDDINGS auto-detected as false
```

**Stack:**
- LLM: OpenAI GPT-4o
- Embeddings: OpenAI text-embedding-3-large
- Vector DB: ChromaDB (~/.chroma/)
- Agent: OpenAIAgent with MyUnitreeSkills

**Benefits:**
- ✅ Highest quality LLM
- ✅ Best embeddings
- ✅ No local GPU needed

**Costs:**
- LLM: ~$5/1M input tokens, ~$15/1M output tokens
- Embeddings: ~$0.13/1M tokens

### 3. Hybrid: Local LLM + Cloud Embeddings

**Use Case:** Save on LLM costs but use best embeddings

```bash
# .env
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
USE_LOCAL_EMBEDDINGS=false  # ⚠️ Explicit override
OPENAI_API_KEY=sk-...  # For embeddings only
```

**Stack:**
- LLM: vLLM (free)
- Embeddings: OpenAI (paid)
- Vector DB: ChromaDB (~/.chroma/)
- Agent: OpenAIAgent with MyUnitreeSkills

### 4. Hybrid: Cloud LLM + Local Embeddings

**Use Case:** Best LLM, no embeddings costs

```bash
# .env
AGENT_BACKEND=openai
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o
OPENAI_API_KEY=sk-...
USE_LOCAL_EMBEDDINGS=true  # ⚠️ Explicit override
```

**Stack:**
- LLM: OpenAI GPT-4o (paid)
- Embeddings: sentence-transformers (free)
- Vector DB: ChromaDB (~/.chroma/)
- Agent: OpenAIAgent with MyUnitreeSkills

### 5. Simple Text Agent (No Skills)

**Use Case:** Local text generation without robot control

```python
from dimos.agents.agent_huggingface_local import HuggingFaceLocalAgent

agent = HuggingFaceLocalAgent(
    dev_name="TextAgent",
    model_name="Qwen/Qwen2.5-3B",
    # agent_memory defaults to LocalSemanticMemory()
)
```

**Limitations:**
- ❌ NO skills/function calling
- ❌ Cannot control robot
- ✅ Good for chatbots, summarization, etc.

---

## Known Issues and Bugs

### 1. Missing Import in LocalSemanticMemory ⚠️ CRITICAL

**File:** `src/dimos-unitree/dimos/agents/memory/chroma_impl.py`  
**Line:** 147  
**Status:** Identified, fix pending

**Error:**
```python
NameError: name 'SentenceTransformer' is not defined
```

**Root Cause:**
```python
# Line 147:
self.model = SentenceTransformer(self.model_name, device=device)

# But import is missing at top of file (lines 1-40)
```

**Fix:**
```python
# Add to imports section:
from sentence_transformers import SentenceTransformer
```

**Impact:**
- ❌ LocalSemanticMemory initialization fails
- ❌ Falls back to no memory (no RAG)
- ❌ Blocks local embeddings for OpenAIAgent + vLLM

**Workaround:**
- Use cloud embeddings temporarily
- OR fix DIMOS locally (violates submodule policy but documented in emergency workflow)

**Resolution Plan:**
1. Consolidate DIMOS branches (dev + fix/webrtc)
2. Apply fix to consolidated dev branch
3. Test with ShadowHound
4. Submit PR to upstream DIMOS
5. Update submodule SHA in ShadowHound

### 2. README Misleading Claim

**File:** `dimos-unitree/README.md`

**Claim:**
> **Agent API keys**
> 
> Full functionality will require API keys for the following:
> 
> Requirements: 
> - **OpenAI API key (required for all LLMAgents due to OpenAIEmbeddings)**

**Reality:**
- ❌ NOT required for HuggingFaceLocalAgent (uses LocalSemanticMemory by default)
- ❌ NOT required for any agent if you pass `agent_memory=LocalSemanticMemory()` explicitly
- ✅ Only required if using `OpenAISemanticMemory` (which is just a default, not a requirement)

**Impact:** Misleading documentation discourages local deployments

**Resolution:** Update DIMOS README to clarify local options

### 3. OpenAIAgent Memory Default

**File:** `dimos/agents/agent.py` line 95

**Issue:**
```python
self.agent_memory = agent_memory or OpenAISemanticMemory()
```

This means if you pass `agent_memory=None`, it creates OpenAISemanticMemory which:
- Requires OpenAI API key
- Makes API calls to /v1/embeddings
- Fails with vLLM (no embeddings endpoint)

**Workaround:** Never pass `None`, always pass explicit memory or omit parameter

**Our Solution:** Use `agent_memory="skip"` as sentinel value to prevent None

### 4. AgentMemoryConnectionError.__str__() Bug (FIXED)

**File:** `dimos/exceptions/agent_memory_exceptions.py` line 44  
**Status:** ✅ Fixed in DIMOS commit cfcaa24

**Bug:**
```python
def __str__(self):
    return f"{self.message}\nCaused by: {repr(self.cause)}" if self.cause else self.message
    # ERROR: self.message doesn't exist! Python stores in args[0]
```

**Fix:**
```python
def __str__(self):
    message = self.args[0] if self.args else "Unknown error"
    return f"{message}\nCaused by: {repr(self.cause)}" if self.cause else message
```

### 5. No vLLM + LocalSemanticMemory Examples

**Issue:** DIMOS documentation has no examples of:
- OpenAIAgent with vLLM backend
- OpenAIAgent with LocalSemanticMemory
- Hybrid configurations

**Impact:** Users don't know these combinations are possible

**Resolution:** Add examples to DIMOS docs (and this document!)

---

## Recommendations

### For DIMOS Project

If contributing back to DIMOS:

1. **Fix LocalSemanticMemory import** (1 line, critical)
   ```python
   from sentence_transformers import SentenceTransformer
   ```

2. **Update README** to clarify:
   - OpenAI key is optional
   - Local embeddings available via LocalSemanticMemory
   - HuggingFaceLocalAgent works completely locally

3. **Add examples** of:
   - OpenAIAgent + vLLM backend
   - OpenAIAgent + LocalSemanticMemory
   - Hybrid configurations

4. **Document agent capabilities clearly:**
   - Which agents support skills/tools
   - Which agents support vision
   - Which agents support local operation

5. **Add dependency checking** in LocalSemanticMemory:
   ```python
   try:
       from sentence_transformers import SentenceTransformer
   except ImportError:
       raise ImportError("sentence-transformers not installed. Run: pip install sentence-transformers")
   ```

### For ShadowHound Project

**Immediate:**
1. ✅ Consolidate DIMOS branches (dev + fix/webrtc)
2. ✅ Apply LocalSemanticMemory import fix
3. ✅ Test full stack with local LLM + local embeddings
4. ✅ Verify robot control via skills works end-to-end

**Short-term:**
1. Monitor vLLM performance and quality
2. Benchmark local embeddings vs OpenAI embeddings
3. Consider contributing fixes back to DIMOS
4. Document any additional issues found

**Long-term:**
1. Evaluate switching to PlanningAgent for complex missions
2. Consider ClaudeAgent for scenarios requiring extended thinking
3. Explore vision capabilities (multimodal missions)
4. Benchmark different embedding models

---

## Test Examples in DIMOS

- DIMOS Agent Interface: `dimos/agents/agent.py`
- HuggingFace Local Agent: `dimos/agents/agent_huggingface_local.py`
- Memory Implementations: `dimos/agents/memory/chroma_impl.py`
- Test Examples: `tests/test_agent_huggingface_local*.py`
- ShadowHound Implementation: `src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py`
