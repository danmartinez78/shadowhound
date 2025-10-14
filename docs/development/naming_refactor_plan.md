---
tags: [architecture, refactoring, planning]
status: planned
related: [mission_agent_vs_executor, agent_robot_decoupling]
summary: >
  Plan for Phase 1 refactoring to rename MissionExecutor → RobotAgent and MissionAgentNode → MissionNode.
---

# Naming Refactor: Mission Components → Clear Layering

**Status**: Planned for Phase 1  
**Issue**: To be created  
**Estimated Effort**: 1 hour

---

## Problem Statement

Current naming is confusing and doesn't reflect the actual responsibilities:

```
MissionAgentNode     ← Sounds like AI, but it's just ROS2 infrastructure
MissionExecutor      ← Sounds generic, but it's the robot's brain/personality
```

Both have "mission" in the name and "agent" is ambiguous (ROS agent? AI agent?).

---

## Proposed Changes

### Rename 1: MissionExecutor → RobotAgent

**Current**: `MissionExecutor`  
**Proposed**: `RobotAgent`  
**File**: `mission_executor.py` → `robot_agent.py`

**Rationale**:
- It IS the robot's agent (intelligence/personality)
- Contains LLM reasoning and decision making
- Configures personality (system prompts, model choice)
- Manages memory and context
- Name aligns with DIMOS terminology (OpenAIAgent, PlanningAgent)
- Opens door for multiple personalities (TachikomaAgent, etc.)

### Rename 2: MissionAgentNode → MissionNode

**Current**: `MissionAgentNode`  
**Proposed**: `MissionNode`  
**File**: `mission_agent.py` → `mission_node.py`

**Rationale**:
- It's just a ROS2 node (infrastructure)
- Not an "agent" in the AI sense
- "Node" clearly indicates ROS2 layer
- Shorter and clearer

---

## Scope of Changes

### Python Files
```
src/shadowhound_mission_agent/shadowhound_mission_agent/
├── mission_executor.py    → robot_agent.py
│   └── MissionExecutor    → RobotAgent
│   └── MissionExecutorConfig → RobotAgentConfig
│
└── mission_agent.py       → mission_node.py
    └── MissionAgentNode   → MissionNode
```

### Imports to Update
```python
# Before
from .mission_executor import MissionExecutor, MissionExecutorConfig

# After
from .robot_agent import RobotAgent, RobotAgentConfig
```

### Test Files
```
test/test_mission_executor.py  → test_robot_agent.py
  ├── Test class names
  └── Import statements
```

### Documentation Files (6+ files)
```
docs/development/agent_robot_decoupling_analysis.md
docs/architecture/mission_agent_vs_executor.md  (rename to mission_node_vs_robot_agent.md)
docs/software/packages/shadowhound_mission_agent/agent_design.md
docs/software/packages/shadowhound_mission_agent/agent_architecture.md
docs/software/packages/shadowhound_mission_agent/web_interface.md
```

### Launch Files (if any reference class names)
- Check launch/ directory for any Python launch files

---

## Migration Strategy

### Phase 1: Preparation (Complete ✅)
- [x] Document current architecture clearly
- [x] Add comprehensive docstrings to both files
- [x] Create this refactoring plan

### Phase 2: Rename Execution (Phase 1 kickoff)
1. Rename Python files
2. Update class names
3. Update imports in same package
4. Update test files
5. Update documentation
6. Test build and basic functionality
7. Run test suite
8. Update README if needed

### Phase 3: Validation
- [ ] All tests pass
- [ ] Documentation references updated
- [ ] No broken imports
- [ ] Launch files work
- [ ] Web interface still functions

---

## Before/After Comparison

### Current Architecture
```
┌─────────────────────────────────────┐
│  MissionAgentNode (ROS2)            │  ← Confusing: "Agent" but not AI
│  - ROS infrastructure                │
│  - Topics, parameters, QoS           │
└─────────────────────────────────────┘
            ↓ delegates to
┌─────────────────────────────────────┐
│  MissionExecutor (Pure Python)      │  ← Confusing: More than "execute"
│  - Robot initialization              │
│  - Agent/LLM intelligence            │
│  - Mission reasoning                 │
└─────────────────────────────────────┘
```

### Proposed Architecture
```
┌─────────────────────────────────────┐
│  MissionNode (ROS2)                 │  ← Clear: Just a ROS node
│  - ROS infrastructure                │
│  - Topics, parameters, QoS           │
└─────────────────────────────────────┘
            ↓ delegates to
┌─────────────────────────────────────┐
│  RobotAgent (Pure Python)           │  ← Clear: The robot's brain
│  - Robot initialization              │
│  - Agent/LLM intelligence            │
│  - Personality and reasoning         │
└─────────────────────────────────────┘
```

---

## Benefits

1. **Clarity**: Names reflect actual responsibilities
2. **Alignment**: Matches DIMOS terminology (OpenAIAgent, etc.)
3. **Extensibility**: Opens door for multiple agent personalities
4. **Maintainability**: New developers immediately understand layering
5. **Documentation**: Easier to explain and document

---

## Risks & Mitigation

### Risk 1: Breaking external dependencies
**Mitigation**: This is an internal package, no external users yet

### Risk 2: Git history becomes harder to follow
**Mitigation**: Use `git log --follow` to track renames

### Risk 3: Merge conflicts if work is in flight
**Mitigation**: Coordinate refactor with Phase 1 kickoff when MockRobot work starts

---

## Alternative Considered: Keep Current Names

**Pros**:
- No disruption
- Documentation can clarify

**Cons**:
- Confusion persists for all future developers
- Names don't align with what code actually does
- Missed opportunity to establish clear patterns

**Verdict**: Refactor is worth the small effort for long-term clarity

---

## Checklist for Execution

### Pre-Refactor
- [ ] Commit all current work
- [ ] Create feature branch: `refactor/rename-mission-components`
- [ ] Backup current state

### During Refactor
- [ ] Rename `mission_executor.py` → `robot_agent.py`
- [ ] Update class `MissionExecutor` → `RobotAgent`
- [ ] Update class `MissionExecutorConfig` → `RobotAgentConfig`
- [ ] Rename `mission_agent.py` → `mission_node.py`
- [ ] Update class `MissionAgentNode` → `MissionNode`
- [ ] Update all imports in package
- [ ] Update test files
- [ ] Run `colcon build --packages-select shadowhound_mission_agent`
- [ ] Run test suite
- [ ] Update docs/development/agent_robot_decoupling_analysis.md
- [ ] Update docs/architecture/mission_agent_vs_executor.md (rename file)
- [ ] Update README.md if needed
- [ ] Update other markdown docs (grep for old names)

### Post-Refactor
- [ ] All tests pass
- [ ] Documentation updated
- [ ] PR created and reviewed
- [ ] Merge to dev

---

## Code Snippets for Quick Reference

### Current Import Pattern
```python
from shadowhound_mission_agent.mission_executor import (
    MissionExecutor,
    MissionExecutorConfig,
)
```

### Future Import Pattern
```python
from shadowhound_mission_agent.robot_agent import (
    RobotAgent,
    RobotAgentConfig,
)
```

### Current Instantiation
```python
config = MissionExecutorConfig(agent_backend="ollama")
executor = MissionExecutor(config, logger=logger)
executor.initialize()
```

### Future Instantiation
```python
config = RobotAgentConfig(agent_backend="ollama")
agent = RobotAgent(config, logger=logger)
agent.initialize()
```

---

## Timeline

**When**: Phase 1 kickoff (when implementing MockRobot)  
**Why then**: Already touching this code for robot abstraction  
**Duration**: 1 hour focused work  
**Risk**: Low (mostly search-and-replace)

---

## Related Work

This refactor pairs well with:
- MockRobot implementation (Phase 1)
- Robot factory pattern (Phase 1)
- Testing infrastructure (Phase 1)

All touch the same files, so batch the changes.

---

## Success Criteria

- [x] Documentation clearly explains current state
- [ ] GitHub issue created for refactor
- [ ] Refactor completed during Phase 1
- [ ] All tests pass after refactor
- [ ] Documentation uses new names
- [ ] No references to old names remain

---

**Related Docs**:
- [Mission Agent vs Executor (current)](../architecture/mission_agent_vs_executor.md)
- [Agent-Robot Decoupling Analysis](agent_robot_decoupling_analysis.md)
- [Phase 1 Roadmap](../project_overview/roadmap.md#phase-1-skills-foundation)

**Status**: Planned, ready to execute in Phase 1
