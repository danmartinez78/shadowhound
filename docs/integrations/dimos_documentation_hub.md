---
tags: [integrations, dimos, reference]
status: active
related: [dimos_capabilities, dimos_integration]
summary: >
  Quick reference hub for DIMOS framework documentation - points to upstream and local resources.
---

# DIMOS Documentation Hub

**Last Updated**: 2025-10-13  
**DIMOS Version**: Submodule commit in ShadowHound

## Purpose

Central index for all DIMOS framework documentation. Points to upstream sources and local guides.

## Prerequisites

- DIMOS submodule initialized: `git submodule update --init --recursive`
- Understanding of [Project Architecture](../architecture/architecture_hub.md)

---

## 📚 Upstream Documentation

### Official DIMOS Sources

**Main Repository**: https://github.com/dimensionalOS/dimos-unitree  
**Fork (Ours)**: https://github.com/danmartinez78/dimos-unitree

#### Essential Reads

1. **[DIMOS README](../../src/dimos-unitree/README.md)** - Start here!
   - Quick start guide
   - Docker setup
   - Python installation
   - Project structure
   - Basic examples

2. **[Robot README](../../src/dimos-unitree/dimos/robot/unitree/README.md)** - Unitree Go2 specifics
   - Hardware setup
   - ROS2 SDK integration
   - WebRTC configuration

3. **[Web Interface README](../../src/dimos-unitree/dimos/web/README.md)** - Web UI
   - Interface setup
   - Development mode
   - API endpoints

4. **[Simulation README](../../src/dimos-unitree/dimos/simulation/README.md)** - Genesis/Isaac Sim
   - Simulation environments
   - Testing without hardware

### GitHub Issue Tracker

**Documentation Enhancement Issue**: [Create issue from draft](dimos_documentation_issue_draft.md)

We've drafted a comprehensive documentation enhancement request for upstream. See [issue draft](dimos_documentation_issue_draft.md) for details.

---

## 📖 ShadowHound Local Guides

These are our working notes and guides while upstream documentation is being improved.

### Getting Started

- **[DIMOS Quick Start](../software/dimos_quick_start.md)** - ShadowHound-specific setup
- **[DIMOS Integration](dimos_integration.md)** - How we integrate DIMOS
- **[DIMOS Development Policy](../development/dimos_development_policy.md)** - How to modify DIMOS safely

### Capabilities & Features

- **[DIMOS Capabilities](dimos_capabilities.md)** - ⭐ **40+ Skills Catalog**
  - Locomotion skills (BalanceStand, Sit, etc.)
  - Dynamic maneuvers (FrontFlip, Handstand, etc.)
  - Expressive behaviors (Hello, Dance, etc.)
  - Navigation skills (TrajectoryFollow, etc.)
  - System skills (GetState, Trigger, etc.)

- **[DIMOS Vision Capabilities](dimos_vision_capabilities.md)** - VLM integration
  - Qwen VLM support
  - Scene understanding
  - Object detection

- **[DIMOS Agent Architecture](../software/agent/dimos_agent_architecture.md)** - Agent system design
  - OpenAIAgent, PlanningAgent, ClaudeAgent
  - Agent chaining patterns
  - Observable streams

### Development Guides

- **[DIMOS Branch Consolidation](../development/dimos_branch_consolidation.md)** - Branch management
- **[DIMOS Submodule Modifications](../troubleshooting/dimos_submodule_modifications.md)** - Troubleshooting submodule issues

---

## 🎯 Key Concepts

### Skills System

**What are Skills?**
- Task-specific robot capabilities
- Type-safe with Pydantic models
- Callable via LLM agents
- Two types: WebRTC API skills (40+) and class-based skills (Move, Reverse, etc.)

**Base Classes**:
- `AbstractSkill` - Base skill interface
- `AbstractRobotSkill` - Robot-specific skills
- `SkillLibrary` - Registry and management

**Example**:
```python
from dimos.robot.unitree.unitree_skills import MyUnitreeSkills

skills = MyUnitreeSkills(robot=robot)
skills.create_instance("Move", x=0.3, duration=2.0)()
```

**Full Skills List**: See [DIMOS Capabilities](dimos_capabilities.md)

---

### Agent System

**What are Agents?**
- LLM-powered decision makers
- Can call skills as functions/tools
- Support memory and spatial reasoning
- Chainable via observables

**Available Agents**:
- `OpenAIAgent` - GPT-4, GPT-3.5, etc.
- `PlanningAgent` - Multi-step task planning
- `ClaudeAgent` - Anthropic Claude models
- `HuggingFaceRemoteAgent` - HF hosted models
- `HuggingFaceLocalAgent` - Local HF models

**Example**:
```python
from dimos.agents.agent import OpenAIAgent

agent = OpenAIAgent(
    dev_name="TestAgent",
    skills=robot.get_skills(),
    model_name="gpt-4o",
    system_query="You are a helpful robot assistant."
)
```

**Agent Chaining**:
```python
# Planner → Executor pipeline
planner = PlanningAgent(...)
executor = OpenAIAgent(
    input_query_stream=planner.get_response_observable()
)
```

---

### Memory System

**What is Memory?**
- Semantic memory for spatial reasoning
- ChromaDB-backed vector storage
- Location-grounded recall

**Example**:
```python
from dimos.agents.memory.chroma_impl import LocalSemanticMemory
from langchain_openai import OpenAIEmbeddings

memory = LocalSemanticMemory(
    embedder=OpenAIEmbeddings(model="text-embedding-3-small"),
    persist_directory="./memory_db"
)

agent = OpenAIAgent(memory=memory, ...)
```

---

### Reactive Streams (RxPY)

**What are Observables?**
- Asynchronous data streams
- Pub/Sub pattern for real-time data
- Camera feeds, commands, state updates

**Example**:
```python
# Robot provides video stream observable
video_stream = robot.get_ros_video_stream()

# Agent subscribes to it
agent = OpenAIAgent(
    input_video_stream=video_stream,
    ...
)
```

---

## 🔍 Finding Information

### "How do I...?"

**See available skills?**
→ [DIMOS Capabilities](dimos_capabilities.md) - Full catalog

**Create a custom skill?**
→ Look at `src/dimos-unitree/dimos/robot/unitree/unitree_skills.py` lines 156-202  
→ Inherit from `AbstractRobotSkill`, define parameters with Pydantic

**Use a specific agent?**
→ [DIMOS Agent Architecture](../software/agent/dimos_agent_architecture.md)  
→ `src/dimos-unitree/dimos/agents/agent.py` - Source code with docstrings

**Chain multiple agents?**
→ `planner.get_response_observable()` → `executor.input_query_stream`  
→ See DIMOS README examples

**Integrate with ROS2?**
→ `src/dimos-unitree/dimos/robot/ros_control.py` - ROS interface  
→ [DIMOS Integration](dimos_integration.md)

**Set up memory?**
→ `src/dimos-unitree/dimos/agents/memory/chroma_impl.py`  
→ [Local LLM Memory Roadmap](../software/llm/local_llm_memory_roadmap.md)

**Debug WebRTC issues?**
→ [WebRTC Configuration](../software/web/webrtc_configuration.md)  
→ [DIMOS Submodule Modifications](../troubleshooting/dimos_submodule_modifications.md)

---

## 📦 Code Locations

Quick reference to key files in DIMOS submodule:

```
src/dimos-unitree/
├── dimos/
│   ├── agents/
│   │   ├── agent.py              # OpenAIAgent, PlanningAgent, ClaudeAgent
│   │   └── memory/
│   │       └── chroma_impl.py    # LocalSemanticMemory
│   ├── skills/
│   │   └── skills.py             # AbstractSkill, SkillLibrary base classes
│   ├── robot/
│   │   ├── robot.py              # Robot base class
│   │   ├── ros_control.py        # ROS2 interface
│   │   └── unitree/
│   │       ├── unitree_go2.py    # UnitreeGo2 robot class
│   │       ├── unitree_skills.py # MyUnitreeSkills (40+ skills)
│   │       └── unitree_ros_control.py  # Unitree ROS interface
│   ├── perception/
│   │   └── detection2d/          # 2D object detection
│   ├── models/
│   │   └── Detic/                # Detic model integration
│   └── web/
│       └── dimos_interface/      # Web UI
└── tests/
    └── run.py                    # Example usage
```

---

## 🚨 Known Issues

### Camera Compressed Topic
**Issue**: GO2 SDK doesn't publish `camera/compressed`  
**Status**: DIMOS has handler, SDK doesn't publish  
**Workaround**: Use raw image OR add republisher  
**Details**: [Ideas Backlog](../project_overview/ideas_backlog.md#camera-compressed-topic)

### WebRTC Skills Break Nav2
**Issue**: Mode conflict between Sport Mode and Nav2  
**Status**: Temporarily abandoned for MVP  
**Workaround**: Use Nav2 skills instead  
**Details**: [MVP Plan Pivot](../history/mvp_plan_pivot.md)

---

## 🤝 Contributing Back to DIMOS

### How to Contribute

1. **Never edit in submodule** - See [DIMOS Development Policy](../development/dimos_development_policy.md)
2. **Clone DIMOS separately**: `git clone git@github.com:danmartinez78/dimos-unitree.git`
3. **Create feature branch**: `git checkout -b fix/my-improvement`
4. **Make changes and test**
5. **Push and create PR** to danmartinez78/dimos-unitree
6. **After merge, update submodule** in ShadowHound

### What to Contribute

- **Documentation improvements** - Docstrings, guides, examples
- **Bug fixes** - Especially issues we've discovered
- **Skills enhancements** - New skills or improved existing ones
- **Test coverage** - Unit tests for agents and skills

---

## 📊 Documentation Status

### Upstream (DIMOS)
- ✅ README and quick start
- ✅ Docker setup guide
- ✅ Example code in tests/
- ⚠️ API reference (minimal, in code comments)
- ❌ Comprehensive skills documentation
- ❌ Agent usage guide
- ❌ Memory system guide
- ❌ Architecture diagrams

### ShadowHound Local
- ✅ Skills catalog (40+ skills)
- ✅ Agent architecture notes
- ✅ Integration guide
- ✅ Development policy
- ✅ WebRTC configuration
- ⚠️ API reference (partial, in capabilities doc)
- 🔄 Creating upstream documentation issue

---

## 🎓 Learning Path

**New to DIMOS? Follow this path:**

1. **Read**: [DIMOS README](../../src/dimos-unitree/README.md) (30 min)
2. **Review**: [DIMOS Capabilities](dimos_capabilities.md) - See what's possible (15 min)
3. **Study**: Example code in `tests/run.py` (20 min)
4. **Explore**: [DIMOS Agent Architecture](../software/agent/dimos_agent_architecture.md) (20 min)
5. **Practice**: Set up Docker environment and run example (1 hour)
6. **Experiment**: Modify example to use different skills (1 hour)

**Total**: ~3 hours to basic proficiency

---

## Validation

- [x] Upstream DIMOS README referenced
- [x] ShadowHound guides indexed
- [x] Code locations documented
- [x] "How do I...?" section populated
- [x] Known issues documented
- [x] Contribution guide included
- [x] Learning path provided

---

## References

- **[DIMOS Main Repo](https://github.com/dimensionalOS/dimos-unitree)** - Upstream source
- **[Our Fork](https://github.com/danmartinez78/dimos-unitree)** - Our modifications
- **[Documentation Issue Draft](dimos_documentation_issue_draft.md)** - Proposed improvements
- **[Development Hub](../development/development_hub.md)** - ShadowHound dev processes
- **[Architecture Hub](../architecture/architecture_hub.md)** - System architecture

---

**Maintenance**: Update this hub when upstream documentation improves or new local guides are created.
