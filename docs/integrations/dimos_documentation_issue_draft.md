---
tags: [dimos, documentation, issue-draft]
status: draft
related: []
summary: >
  Draft GitHub issue for dimos-unitree documentation improvements.
---

# DIMOS Documentation Issue Draft

**Repository**: https://github.com/danmartinez78/dimos-unitree  
**Issue Type**: Documentation Enhancement  
**Priority**: High (foundational for downstream projects)

---

## Issue Title

**Comprehensive Skills Library and API Documentation**

---

## Issue Description

### Problem Statement

The DIMOS framework is incredibly powerful but lacks comprehensive, accessible documentation for:
- **Skills Library API** - What skills exist, their parameters, and usage examples
- **Agent System** - How to use OpenAIAgent, PlanningAgent, ClaudeAgent, etc.
- **Memory System** - LocalSemanticMemory, ChromaDB integration, usage patterns
- **Robot Interface** - UnitreeGo2, UnitreeROSControl API reference
- **Reactive Streams** - RxPY observable patterns and data flow

This makes it difficult for downstream projects (like ShadowHound) to:
1. Discover what capabilities exist
2. Understand how to use them correctly
3. Debug issues when things don't work
4. Contribute improvements back upstream

### Current State

**What Exists**:
- ✅ README with quick start and examples
- ✅ Code comments and docstrings (some modules)
- ✅ Example usage in `tests/run.py`
- ✅ Docker setup documentation

**What's Missing**:
- ❌ Comprehensive skills library reference
- ❌ API documentation generated from docstrings
- ❌ Agent usage patterns and examples
- ❌ Memory system configuration guide
- ❌ Troubleshooting guide
- ❌ Architecture diagrams

### Proposed Solution

Create comprehensive documentation covering:

#### 1. Skills Library Reference

**Location**: `docs/skills_reference.md`

Document all 40+ Unitree Go2 skills:

```markdown
## Skills Library Reference

### Locomotion Skills

#### BalanceStand
**ID**: 1002  
**Description**: Maintains balanced standing position  
**Parameters**: None  
**Returns**: Success status  
**Usage**:
```python
robot.webrtc_req(api_id=1002)
```

#### Sit
**ID**: 1009  
**Description**: Sit down from standing position  
**Parameters**: None  
**Returns**: Success status  
**Usage**:
```python
robot.webrtc_req(api_id=1009)
```

[... continue for all 40+ skills ...]

### Navigation Skills (Class-based)

#### Move
**Class**: `MyUnitreeSkills.Move`  
**Description**: Move the robot using direct velocity commands  
**Parameters**:
- `x` (float, required): Forward velocity (m/s)
- `y` (float, default=0.0): Left/right velocity (m/s)
- `yaw` (float, default=0.0): Rotational velocity (rad/s)
- `duration` (float, default=0.0): How long to move (seconds). If 0, continuous

**Returns**: Command result  
**Usage**:
```python
skill_library.create_instance("Move", x=0.3, duration=2.0, robot=robot)()
```

[... continue for all class-based skills ...]
```

#### 2. Agent System Documentation

**Location**: `docs/agents_guide.md`

```markdown
## Agent System Guide

### Available Agents

#### OpenAIAgent
Standard agent using OpenAI's models (GPT-4, GPT-3.5, etc.)

**Parameters**:
- `dev_name` (str): Agent identifier
- `input_video_stream` (Observable, optional): Camera feed
- `input_query_stream` (Observable, optional): Text input stream
- `skills` (SkillLibrary): Available skills
- `system_query` (str, optional): System prompt
- `model_name` (str, default="gpt-4o"): Model to use
- `openai_client` (OpenAI, optional): Custom OpenAI client

**Usage**:
```python
agent = OpenAIAgent(
    dev_name="TestAgent",
    skills=robot.get_skills(),
    model_name="gpt-4o"
)
```

#### PlanningAgent
Multi-step planning agent that breaks down complex tasks

**Parameters**: [same as OpenAIAgent plus...]
- `max_steps` (int, default=5): Maximum planning steps

**Usage**:
```python
planner = PlanningAgent(
    dev_name="Planner",
    input_query_stream=web_interface.query_stream,
    skills=robot.get_skills(),
    model_name="gpt-4o"
)
```

#### ClaudeAgent
Agent using Anthropic's Claude models

[... similar format ...]

### Agent Chaining

Agents can be chained by connecting output → input:

```python
# Planner generates multi-step plan
planner = PlanningAgent(...)

# Executor executes each step
executor = OpenAIAgent(
    input_query_stream=planner.get_response_observable(),  # Chain here!
    ...
)
```
```

#### 3. Memory System Documentation

**Location**: `docs/memory_guide.md`

```markdown
## Memory System Guide

### LocalSemanticMemory

Provides semantic memory for spatial reasoning and location grounding.

**Parameters**:
- `embedder` (HuggingFaceEmbeddings | OpenAIEmbeddings): Embedding model
- `persist_directory` (str, optional): Path to persist ChromaDB

**Usage**:
```python
from langchain_openai import OpenAIEmbeddings
from dimos.agents.memory.chroma_impl import LocalSemanticMemory

memory = LocalSemanticMemory(
    embedder=OpenAIEmbeddings(model="text-embedding-3-small"),
    persist_directory="./memory_db"
)
```

### Integration with Agents

```python
agent = OpenAIAgent(
    memory=memory,
    ...
)
```
```

#### 4. API Reference (Auto-generated)

Use Sphinx or mkdocstrings to generate from docstrings:

```bash
# Install documentation tools
pip install sphinx sphinx-rtd-theme sphinx-autodoc-typehints

# Generate docs
cd docs
sphinx-apidoc -o api ../dimos
make html
```

**Sections to document**:
- `dimos.agents.*` - Agent classes and base classes
- `dimos.skills.*` - Skill base classes and utilities
- `dimos.robot.*` - Robot interfaces and control
- `dimos.perception.*` - Computer vision and sensing
- `dimos.memory.*` - Memory implementations
- `dimos.stream.*` - Video/audio streaming

#### 5. Troubleshooting Guide

**Location**: `docs/troubleshooting.md`

Common issues and solutions:
- WebRTC connection issues
- ROS2 topic not found
- Skills not executing
- Memory import errors
- Agent timeout issues

#### 6. Architecture Documentation

**Location**: `docs/architecture.md`

Visual diagrams and explanations:
- System architecture (layers)
- Data flow (observables, pub/sub)
- Agent → Skills → Robot pipeline
- Memory integration points

### Implementation Plan

**Phase 1: Skills Reference** (High Priority)
- [ ] Document all 40+ WebRTC API skills (ID + description)
- [ ] Document class-based skills (Move, Reverse, SpinLeft, etc.)
- [ ] Add usage examples for each skill
- [ ] Document SkillLibrary API (create_instance, register_skills)

**Phase 2: Agent Documentation** (High Priority)
- [ ] Document OpenAIAgent, PlanningAgent, ClaudeAgent
- [ ] Agent chaining patterns
- [ ] Observable streams (input/output)
- [ ] System prompts and configuration

**Phase 3: API Reference** (Medium Priority)
- [ ] Set up Sphinx or mkdocstrings
- [ ] Add/improve docstrings in code
- [ ] Generate API docs
- [ ] Host on GitHub Pages or ReadTheDocs

**Phase 4: Supporting Docs** (Medium Priority)
- [ ] Memory system guide
- [ ] Troubleshooting guide
- [ ] Architecture diagrams

**Phase 5: Examples & Tutorials** (Lower Priority)
- [ ] "Hello World" tutorial
- [ ] Multi-agent chaining tutorial
- [ ] Vision-based navigation tutorial
- [ ] Memory-grounded conversation tutorial

### Benefits

For **DIMOS maintainers**:
- Easier onboarding for new contributors
- Reduced support burden (fewer "how do I...?" questions)
- Better bug reports (users understand the system)
- Encourages contributions

For **downstream projects** (like ShadowHound):
- Clear API reference to work against
- Confidence in using DIMOS capabilities
- Easier debugging when things break
- Better integration quality

### Resources Needed

- Time to write documentation (can be distributed across contributors)
- Sphinx or mkdocstrings setup
- GitHub Pages or ReadTheDocs hosting (free for open source)
- Optional: Diagram tools (draw.io, Excalidraw, Mermaid)

### Volunteers

I (ShadowHound project) am willing to:
- Help document skills library (since I need it!)
- Contribute agent usage examples
- Test documentation accuracy
- Provide feedback from downstream user perspective

---

## Additional Context

**ShadowHound Project Context**:

We're building an autonomous mobile robot system on top of DIMOS and have been cataloging what we learn. We'd love to contribute this back upstream rather than maintaining separate docs. See:

- Our DIMOS capabilities analysis: `docs/integrations/dimos_capabilities.md`
- Our agent architecture notes: `docs/software/agent/dimos_agent_architecture.md`
- Our integration guide: `docs/integrations/dimos_integration.md`

We're happy to contribute these back in a format suitable for DIMOS upstream documentation.

**References**:

Similar good examples of robotics library documentation:
- [ROS2 Navigation](https://navigation.ros.org/) - Clear API reference + tutorials
- [PyRobot](https://pyrobot.org/) - Good balance of API docs + examples
- [Langchain](https://python.langchain.com/) - Excellent agent framework docs

---

## Acceptance Criteria

- [ ] Skills library fully documented with all 40+ skills
- [ ] Agent classes documented with usage examples
- [ ] API reference generated from docstrings
- [ ] Documentation accessible (GitHub Pages or ReadTheDocs)
- [ ] Troubleshooting guide created
- [ ] Architecture diagrams added

---

## Labels

- `documentation`
- `enhancement`
- `help wanted` (if accepting contributions)
- `good first issue` (for specific docs sections)

---

## Notes for Issue Creation

**Before submitting**, customize:
1. Remove ShadowHound-specific context if not relevant
2. Adjust priority based on maintainer preferences
3. Check if similar issues exist
4. Link to any related issues or discussions
5. Add screenshots/diagrams if available

**After submitting**:
1. Reference this issue in ShadowHound docs
2. Track progress and contribute where possible
3. Update ShadowHound docs when upstream improves
