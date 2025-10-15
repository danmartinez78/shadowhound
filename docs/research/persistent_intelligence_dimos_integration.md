---
tags: [research, architecture, dimos, integration, persistent-intelligence]
status: draft
related: [persistent_intelligence_architecture_shadowHound.md, shadowHound_early_design_priorities.md, ../architecture/mission_agent_vs_executor.md]
summary: >
  Integration analysis of Persistent Intelligence Architecture with DIMOS-Unitree framework - 
  practical implementation mapping for continuous learning on the Go2 platform.
---

# Persistent Intelligence Architecture × DIMOS-Unitree Integration

_Last updated: 2025-10-14_

## Purpose

This document bridges the **Persistent Intelligence Architecture** (multi-brain, day/night learning) with the **DIMOS-Unitree framework** currently being developed for ShadowHound. It provides a concrete implementation roadmap showing how the abstract architecture maps to actual DIMOS components, skills, and the mission agent.

**Key Question**: How do we layer persistent intelligence capabilities onto the existing DIMOS/Go2/Mission Agent stack without breaking what works?

---

## 1. Current System Architecture (As-Built)

### 1.1 Four-Layer Stack (Current Implementation)

```
┌─────────────────────────────────────────────────────────────┐
│ APPLICATION LAYER                                            │
│ • shadowhound_bringup (launch files)                        │
│ • Mission orchestration via web UI                          │
│ • Configuration: .env files (not YAML)                      │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ AGENT LAYER (Mission Intelligence)                           │
│ • shadowhound_mission_agent (~2,100 LOC)                    │
│ • LLM reasoning: OpenAI cloud OR vLLM Thor                  │
│ • Tool calling: Skills registry integration                  │
│ • FastAPI web UI (479 LOC)                                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ SKILLS LAYER (DIMOS Execution Engine)                       │
│ • MyUnitreeSkills (~30 behaviors in DIMOS)                  │
│ • ⚠️ WebRTC API blocks majority of skills                   │
│ • Working: Non-WebRTC skills only                           │
│ • Perception: YOLO, tracking (untested)                     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ ROBOT LAYER (Hardware Interface)                             │
│ • go2_ros2_sdk (ROS2 bridge)                                │
│ • Sensors: Camera, 2D LiDAR, IMU, joint states, odom       │
│ • Nav2 + SLAM Toolbox (tested on hardware)                 │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Hardware Configuration (Current)

| Component | Hardware | Purpose |
|-----------|----------|---------|
| **Development** | Laptop | ROS2, DIMOS, mission agent, UI |
| **Compute** | Thor AGX (128GB) | LLM/VLM inference (vLLM) |
| **Robot** | Unitree Go2 Pro | Actuators, sensors, locomotion |
| **Simulation** | Tower (RTX 4070) | Available but unused |

**Network**: Laptop ↔ Thor ↔ Go2 over Wi-Fi (laptop primary for dev)

### 1.3 Key Observations

**What Works** ✅:
- Mission agent LLM reasoning and tool calling
- Skill registry and execution framework
- Nav2 + SLAM validated on hardware
- Web UI for monitoring and control
- Dual LLM backend support (cloud + local)

**What's Missing** ❌:
- Trajectory/decision logging
- Data persistence across sessions
- Learning/adaptation loop
- Simulation integration
- Skill evolution tracking

**Constraints** ⚠️:
- WebRTC API blocks most DIMOS skills
- Thor GPU performance degraded (37→5 tok/s)
- No MockRobot for development testing
- Limited skill set available (non-WebRTC only)

---

## 2. Persistent Intelligence Architecture (Target State)

### 2.1 Multi-Brain Topology (Future Hardware)

```
[Go2 Body] ⇄ [Thor: Mobile Brainstem]  ~~Wi-Fi~~  ⇄  [Spark: Cortex]  ⇄  [Tower: Avatar/Sim]
                     |                                        |                    |
            Real-time control                    Reasoning/Training         Isaac Sim testing
            (50-200 Hz)                          (nightly fine-tunes)       (domain: sim)
```

### 2.2 Day/Night Learning Cycle

**Day (Operations)**:
- Thor runs mission agent + DIMOS skills
- Logs decision trajectories locally (WAL)
- Offloads heavy reasoning to Spark (optional)

**Night (Learning)**:
- Spark curates interesting trajectories
- Fine-tunes skill adapters (LoRA)
- Tests in Isaac Sim (Tower)
- Deploys approved adapters back to Thor

---

## 3. Integration Mapping: Architecture → DIMOS

### 3.1 Where Components Live

| Architecture Concept | Current DIMOS/ShadowHound Component | Notes |
|---------------------|-------------------------------------|-------|
| **Mobile Brainstem** | Thor (future) OR Laptop (current) | Mission agent + skill executor |
| **Cortex** | Not present (future: Spark) | Would handle heavy reasoning/training |
| **Avatar** | Not present (future: Tower/Isaac Sim) | RTX 4070 available but unused |
| **Body** | Go2 Pro + go2_ros2_sdk | Already working |
| **Deliberation RPC** | Mission agent → DIMOS skill calls | Already exists (tool calling) |
| **Trajectory Log** | Not implemented | Need to add |
| **Skill Adapters** | Not implemented | Future: LoRA weights for skills |
| **Replay Buffer** | Not implemented | Need to add (WAL pattern) |
| **Domain Tags** | Not implemented | Easy to add |

### 3.2 Message Flow Analysis

#### **Current: Mission Agent → DIMOS Skills**

```python
# Mission Agent (shadowhound_mission_agent)
user_input = "Find the red ball"
plan = llm.generate_plan(user_input)  # Tool calls generated

# Execution
for step in plan:
    skill_name = step["name"]  # e.g., "nav.goto"
    args = step["args"]         # e.g., {"x": 5.0, "y": 2.0}
    result = skill_registry.execute(skill_name, **args)
```

#### **Target: With Trajectory Logging**

```python
# Enhanced execution with logging
for step in plan:
    # Capture context BEFORE execution
    context = {
        "camera_embedding": self.get_camera_embedding(),
        "robot_pose": self.get_pose(),
        "detected_objects": self.perception.get_objects(),
        "mission_state": self.state_machine.current_state
    }
    
    # Execute skill
    result = skill_registry.execute(skill_name, **args)
    
    # Log trajectory record
    trajectory_logger.log_step(
        domain="real",
        skill=skill_name,
        args=args,
        context=context,
        result=result,
        outcome_score=self.assess_outcome(result)
    )
```

### 3.3 DIMOS Skills → Trajectory Actions Mapping

**DIMOS MyUnitreeSkills** (subset that works):

| DIMOS Skill | Trajectory Action Type | Logging Priority |
|-------------|------------------------|------------------|
| Navigation skills | `{"type": "nav", "skill": "goto/rotate/stop"}` | High |
| Perception skills | `{"type": "perception", "skill": "snapshot/detect"}` | High |
| Voice skills | `{"type": "voice", "skill": "speak/listen"}` | Medium |
| Utility skills | `{"type": "util", "skill": "wait/report"}` | Low |

**WebRTC-blocked skills**: Log attempts and failures for future analysis

---

## 4. Implementation Phases

### Phase 0: Foundation (No Hardware Changes) - **Current Sprint**

**Goal**: Add architectural patterns to current codebase without blocking MVP

**Tasks**:
1. ✅ **Domain tagging**: Add `domain: "real"` to all logs
2. ✅ **Session IDs**: Generate `robot_id` and `session_id` at startup
3. ✅ **Monotonic timestamps**: Use `CLOCK_MONOTONIC` for ordering
4. ✅ **Skill call logging**: Log every skill execution with context (simple JSON append)
5. ✅ **Network profiling**: Document laptop↔Thor performance

**Deliverables**:
- `budgets.yaml` - Network and timing constraints
- `logs/trajectories/session_YYYYMMDD_HHMMSS.jsonl` - Simple skill logs
- Updated mission agent with logging hooks

**Effort**: ~1-2 days
**Risk**: Very low (additive only)

---

### Phase 1: Data Durability (Thor or Laptop) - **MVP + 1 week**

**Goal**: Power-loss safe trajectory logging

**Tasks**:
1. Implement WAL (Write-Ahead Logging) pattern
2. Segment files: `replay/segments/seg_YYYYMMDD_NNN.wal`
3. Manifest with checksums: `replay/MANIFEST.json`
4. Recovery tool: `scripts/recover_trajectories.py`

**Implementation Details**:
```python
# trajectory_logger.py
class TrajectoryLogger:
    def __init__(self, data_dir="/data/replay"):
        self.segment_writer = SegmentWriter(data_dir)
        self.manifest = Manifest(data_dir)
        
    def log_step(self, domain, skill, args, context, result, outcome_score):
        record = {
            "domain": domain,
            "robot_id": self.robot_id,
            "session_id": self.session_id,
            "seq_id": self.next_seq_id(),
            "timestamp_ns": time.clock_gettime_ns(time.CLOCK_MONOTONIC),
            "skill": skill,
            "args": args,
            "context": context,
            "result": result,
            "outcome_score": outcome_score
        }
        
        self.segment_writer.append(record)  # Double-buffered, fsync every N
        
        if self.segment_writer.should_rotate():
            self.segment_writer.rotate()
            self.manifest.update()  # Atomic write
```

**Deliverables**:
- `shadowhound_trajectory_logger` package
- WAL implementation with recovery
- Integration with mission agent

**Effort**: ~2-3 days
**Risk**: Medium (need to test power-loss scenarios)

---

### Phase 2: Message Contracts (Prepare for Offload) - **MVP + 2 weeks**

**Goal**: Define stable interfaces for future Thor↔Spark communication

**Tasks**:
1. Define Deliberation RPC schema (JSON or protobuf)
2. Define Trajectory Log schema (standardize format)
3. Implement schema validation
4. Document network budgets

**Schemas**:

```python
# schemas/deliberation_rpc.py
from pydantic import BaseModel

class RobotState(BaseModel):
    pose: dict  # {x, y, yaw}
    goal: str
    detected_objects: list[str]
    mission_state: str

class DeliberationRequest(BaseModel):
    embedding: bytes  # Camera embedding (4-8KB)
    state: RobotState
    deadline_ms: int

class DeliberationResponse(BaseModel):
    subgoal: dict  # {skill, args}
    constraints: dict
    valid: bool
    reasoning: str  # LLM explanation
```

```python
# schemas/trajectory_record.py
from pydantic import BaseModel

class TrajectoryRecord(BaseModel):
    domain: str  # real | sim | synthetic
    robot_id: str
    session_id: str
    seq_id: int
    timestamp_ns: int
    
    task_id: str
    context: dict  # State before action
    action: dict   # {skill, args}
    result: dict   # Skill execution result
    outcome_score: float  # 0.0-1.0
```

**Deliverables**:
- `shadowhound_interfaces/schemas/` - Pydantic models
- Schema validation in mission agent
- Documentation in `docs/architecture/message_contracts.md`

**Effort**: ~1-2 days
**Risk**: Low (can start simple, evolve)

---

### Phase 3: Simulation Avatar (Tower/Isaac Sim) - **Parallel Track**

**Goal**: Test policies in simulation before hardware deployment

**Tasks**:
1. Set up Isaac Sim on Tower (RTX 4070)
2. Import Go2 URDF/USD model
3. Create basic scene (empty room, obstacles)
4. Implement policy server (accepts RPC calls)
5. Tag all sim data with `domain: "sim"`

**Architecture**:
```
[Isaac Sim Scene] → Camera/LiDAR → [Embedding Extractor] → [Policy Server] → Skills
                                                                    ↓
                                                           Trajectory Logger
                                                           (domain: sim)
```

**Integration with DIMOS**:
- Policy server uses **same skill registry** as real robot
- Skills execute against Isaac Sim physics
- Trajectories logged identically (except `domain: "sim"`)

**Deliverables**:
- Isaac Sim workspace on Tower
- Policy server container
- Basic Go2 scene with nav challenges
- Sim trajectory logs for validation

**Effort**: ~1-2 weeks (learning curve)
**Risk**: Medium (new tooling, but doesn't block MVP)

---

### Phase 4: Cortex Integration (When Spark Arrives) - **Post-MVP**

**Goal**: Offload heavy reasoning to Spark, enable nightly training

**Tasks**:
1. Deploy mission agent reasoning to Spark
2. Implement Thor↔Spark RPC (gRPC)
3. Network latency testing (Wi-Fi constraints)
4. Fallback strategy (local reasoning if offload fails)

**Day Operations**:
```
[Thor] Mission agent (lightweight) → RPC → [Spark] LLM reasoning → response
  ↓ (if latency OK)                                ↑
  ↓ (if timeout)                                   ↑
[Thor] Local fallback reasoning ──────────────────┘
```

**Night Operations** (Spark-only):
```
[Spark] Read trajectory logs from Thor (Ethernet sync)
  ↓
[Spark] Curate interesting trajectories (failures, novelties)
  ↓
[Spark] Fine-tune skill adapters (LoRA)
  ↓
[Tower] Test adapters in Isaac Sim (regression suite)
  ↓
[Spark] Sign and package approved adapters
  ↓
[Thor] Deploy adapters (next day startup)
```

**Deliverables**:
- gRPC service definitions
- Spark deployment containers
- Nightly training pipeline
- Adapter deployment system

**Effort**: ~2-3 weeks
**Risk**: High (multi-machine coordination, new hardware)

---

## 5. DIMOS-Specific Considerations

### 5.1 WebRTC API Blocker

**Problem**: Most DIMOS MyUnitreeSkills use WebRTC API directly (non-functional)

**Impact on Persistent Intelligence**:
- Limits skill repertoire for learning
- Trajectories will show many failed skill attempts
- Need to build custom Nav2-based skills

**Mitigation Strategies**:
1. **Short-term**: Focus learning on working skills (Nav2, perception)
2. **Medium-term**: Implement custom skills using ROS2 topics (not WebRTC)
3. **Long-term**: Fix WebRTC API or contribute upstream to DIMOS

**Logging Strategy**:
- Log **all** skill attempts (including WebRTC failures)
- Tag with `skill_available: false` for blocked skills
- Use failure logs to inform skill implementation priorities

### 5.2 Thor GPU Performance

**Problem**: Thor GPU degraded (37→5 tok/s for LLM inference)

**Impact on Day/Night Cycle**:
- Can't run heavy LLM/VLM models on Thor during day operations
- Need to offload to Spark or cloud for complex reasoning
- Limits onboard autonomy

**Architecture Adjustment**:
- **Day**: Thor runs **lightweight** VLM/LLM (or offloads to Spark/cloud)
- **Night**: Spark handles all training/fine-tuning
- **Fallback**: Cloud LLM if Thor/Spark both unavailable

**Testing Needed**:
- Profile Thor with realistic mission loads
- Measure latency for Thor→Spark offload
- Identify minimum viable model size for Thor

### 5.3 MockRobot for Development

**Problem**: No MockRobot implemented (hardware required for testing)

**Impact on Learning Loop**:
- Can't test trajectory logging without hardware
- Sim avatar becomes critical for safe testing
- Development velocity limited

**Solution Path**:
1. **Phase 3**: Isaac Sim becomes the "MockRobot"
2. Skills execute in simulation with identical interfaces
3. Trajectories logged with `domain: "sim"` for validation

### 5.4 Skills Inventory Integration

**Current State**: DIMOS has ~30 MyUnitreeSkills (mostly blocked)

**Trajectory Logging Strategy**:
- Maintain `skills_manifest.json`:
```json
{
  "nav.goto": {
    "status": "working",
    "implementation": "nav2",
    "logging_priority": "high"
  },
  "nav.rotate": {
    "status": "working",
    "implementation": "nav2",
    "logging_priority": "high"
  },
  "webrtc.stand": {
    "status": "blocked",
    "implementation": "webrtc_api",
    "logging_priority": "medium",
    "failure_reason": "webrtc_api_unavailable"
  }
}
```

**Learning Focus**:
- Train adapters on **working skills first**
- Use failure logs to prioritize skill development
- Track skill availability over time (metrics)

---

## 6. Data Flow: Current → Target

### 6.1 Current Data Flow

```
User Input → Mission Agent → LLM Planning → Skill Calls → DIMOS → Go2
                                                              ↓
                                                    (no logging)
```

### 6.2 Phase 0 Data Flow

```
User Input → Mission Agent → LLM Planning → Skill Calls → DIMOS → Go2
                                    ↓                        ↓
                              (tool calls)        (execution results)
                                    ↓                        ↓
                              Trajectory Logger (simple JSON)
                                    ↓
                              logs/trajectories/session_XXX.jsonl
```

### 6.3 Phase 1 Data Flow (WAL)

```
User Input → Mission Agent → LLM Planning → Skill Calls → DIMOS → Go2
                                    ↓                        ↓
                              Trajectory Logger (WAL)
                                    ↓
                    replay/segments/seg_XXX.wal (double-buffered, fsync)
                                    ↓
                              replay/MANIFEST.json (atomic update)
```

### 6.4 Phase 4 Data Flow (Full Learning Loop)

```
                    ┌─────── Day Operations ───────┐
                    │                              │
User → [Thor] Mission Agent → Skills → Go2 → Sensors
              ↓                ↓
        Trajectory Logger   Results
              ↓
      /data/replay (WAL)
              ↓
    (docked at night: Ethernet sync)
              ↓
        [Spark] Curator → Training → Testing → Adapters
                              ↓           ↓
                          LoRA    [Tower] Isaac Sim
                              ↓
                    (approved adapters)
                              ↓
        [Thor] Load adapters (next day)
              └──────────────────────────┘
```

---

## 7. Practical Implementation Checklist

### Phase 0: Quick Wins (This Week)
- [ ] Add `domain`, `robot_id`, `session_id` to mission agent
- [ ] Switch to monotonic timestamps
- [ ] Create `budgets.yaml` with network measurements
- [ ] Implement simple skill call logging (JSON append)
- [ ] Test logging on sample missions

### Phase 1: Data Durability (Next 2 Weeks)
- [ ] Implement WAL segment writer
- [ ] Implement manifest with checksums
- [ ] Add recovery tool
- [ ] Test power-loss scenarios (graceful shutdown + abrupt)
- [ ] Document logging API

### Phase 2: Message Contracts (Parallel)
- [ ] Define Pydantic schemas for RPC and trajectories
- [ ] Add schema validation to mission agent
- [ ] Document in `docs/architecture/message_contracts.md`
- [ ] Create validation tests

### Phase 3: Simulation (Parallel, Non-Blocking)
- [ ] Research Isaac Sim requirements
- [ ] Set up workspace on Tower (RTX 4070)
- [ ] Import Go2 model
- [ ] Create basic test scene
- [ ] Implement policy server skeleton
- [ ] Test skill execution in sim

### Phase 4: Cortex (Post-MVP, When Spark Arrives)
- [ ] Design Thor↔Spark network topology
- [ ] Implement gRPC deliberation service
- [ ] Test latency budgets
- [ ] Implement nightly training pipeline
- [ ] Create adapter deployment system

---

## 8. Open Questions & Design Decisions

### 8.1 Architecture Questions

**Q1**: Where should trajectory logger run?
- **Option A**: On laptop (current dev setup)
- **Option B**: On Thor (future deployment)
- **Decision**: Start on laptop, migrate to Thor when ready

**Q2**: JSON or Protobuf for trajectory format?
- **Option A**: JSON (human-readable, flexible)
- **Option B**: Protobuf (compact, typed, faster)
- **Decision**: Start with JSON, consider protobuf when performance matters

**Q3**: When to implement embedding pipeline?
- **Option A**: Phase 0 (now)
- **Option B**: Phase 3 (when sim ready)
- **Decision**: Phase 3 - wait until VLM/encoder choice is clear

**Q4**: Isaac Sim priority?
- **Option A**: High (start immediately)
- **Option B**: Medium (after Phase 1 complete)
- **Decision**: TBD - depends on MVP timeline pressure

### 8.2 DIMOS Integration Questions

**Q5**: How to handle WebRTC-blocked skills in logging?
- Log attempts with failure tags
- Use to prioritize skill development
- Track skill availability metrics over time

**Q6**: Should we log low-level ROS2 data (joint states, IMU)?
- **Recommendation**: No, focus on decision-level trajectories
- Low-level data is for VLA (future work)
- Keep trajectory logs lightweight (skill-level)

**Q7**: How to assess `outcome_score` automatically?
- Start with binary (success/failure from skill result)
- Evolve to LLM-based assessment ("did this help?")
- Eventually: reward model from human feedback

---

## 9. Success Metrics

### Phase 0 Success
- [ ] 100% of skill calls logged with context
- [ ] Domain tags on all data
- [ ] Network budgets documented
- [ ] No performance regression (logging overhead <5%)

### Phase 1 Success
- [ ] Trajectories survive power-loss (tested)
- [ ] Recovery tool can reconstruct from segments
- [ ] Manifest integrity maintained
- [ ] Logging overhead <10%

### Phase 3 Success
- [ ] Go2 model working in Isaac Sim
- [ ] Same skills run in sim and real
- [ ] Trajectory logs tagged with `domain: sim`
- [ ] Basic policy can navigate test scene

### Phase 4 Success
- [ ] Thor↔Spark RPC working within latency budget
- [ ] Nightly training pipeline runs automatically
- [ ] Adapters deployed and loaded successfully
- [ ] Measurable improvement in mission success rate

---

## 10. References

- [Persistent Intelligence Architecture](persistent_intelligence_architecture_shadowHound.md) - Abstract architecture
- [Early Design Priorities](shadowHound_early_design_priorities.md) - Implementation patterns
- [Mission Agent vs Executor](../architecture/mission_agent_vs_executor.md) - DIMOS architecture
- [MVP Roadmap](../project_overview/mvp_embodied_ai_platform.md) - Current goals and constraints
- [Skills Inventory](../software/skills_inventory.md) - Available DIMOS skills

---

_"The best time to plant a tree was 20 years ago. The second best time is now."_  
**— Integration begins with the first log entry**
