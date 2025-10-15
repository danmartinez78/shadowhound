---
tags: [mvp, persistent-intelligence, local-planning, roadmap, learning]
status: draft
related:
  - ../project_overview/mvp_embodied_ai_platform.md
  - local_planning_architecture.md
  - hybrid_perception_architecture.md
  - persistent_intelligence_dimos_integration.md
summary: >
  Persistent Intelligence MVP proposal that builds on original ShadowHound MVP. Proposes local planning
  first approach for faster development, then adds learning capabilities on top of working system.
---

# Persistent Intelligence MVP

**Created**: 2025-10-14  
**Status**: Proposal  
**Foundation**: Builds on [ShadowHound MVP: Embodied AI Platform](../project_overview/mvp_embodied_ai_platform.md)

---

## Executive Summary

This document proposes enhancements to the **original ShadowHound MVP** that enable **persistent intelligence** — a robot that learns from experience and improves over time. Rather than replacing the original MVP, this proposal identifies **early wins** that accelerate development while establishing the foundation for continuous learning.

**Key Insight**: Recent discovery of DIMOS's local planning capabilities enables a **local-first navigation strategy** that delivers autonomous navigation in ~1 week (vs 2-3 weeks with global planning), while still supporting global planning when needed.

**Strategy**:
1. **Phase 1**: Implement original MVP with local planning first (faster path)
2. **Phase 2**: Add trajectory logging and learning infrastructure
3. **Phase 3**: Integrate persistent intelligence (multi-brain, day/night learning)

---

## Proposed Changes to Original MVP

### Reference: Original MVP Goals

From [mvp_embodied_ai_platform.md](../project_overview/mvp_embodied_ai_platform.md), the original MVP aims to:

1. ✅ Accept voice/console/web commands
2. ✅ Execute vision-based missions
3. ✅ Navigate safely in dynamic environments
4. ✅ Respond with voice output and personality
5. ✅ Process onboard Thor AGX (no cloud)
6. ✅ Learn and remember spatial information

**Core Approach**: SLAM + Nav2 for navigation, VLM for perception

---

### Proposed Enhancement: Local Planning First

**Discovery**: DIMOS includes a complete **VFH (Vector Field Histogram) + Pure Pursuit local planner** that enables autonomous navigation **without requiring global maps or SLAM localization**.

#### Why This Matters

**Original MVP Approach**:
```
Week 1-2: Map environment with SLAM
Week 2-3: Test Nav2 global planning
Week 3-4: Add camera perception
Week 4: End-to-end mission

Risk: High (SLAM + Nav2 untested, complex stack)
Timeline: 3-4 weeks
```

**Enhanced MVP Approach** (Local Planning First):
```
Week 1: Test local planner + Add YOLO perception
Week 1: Working end-to-end mission "Find the ball"

Then (optional): Add SLAM + Nav2 for multi-room
Timeline: 1 week for basic, 2-3 weeks for full
```

#### Benefits of Local-First Approach

| Aspect | Local Planning First | SLAM + Nav2 First |
|--------|---------------------|-------------------|
| **Development Speed** | ✅ 1 week to working mission | ⚠️ 2-3 weeks |
| **Risk** | ✅ Low (simpler stack) | ⚠️ High (untested, complex) |
| **Testing** | ✅ Easy (no mapping phase) | ⚠️ Requires mapping first |
| **Robustness** | ✅ Reactive (always works) | ⚠️ Can lose localization |
| **Use Cases** | ✅ Object search missions | ✅ Multi-room navigation |
| **Learning Data** | ✅ Rich reactive decisions | ⚠️ Sparse waypoints |

#### Hybrid Navigation Strategy (Recommended)

**Proposal**: Support BOTH local and global planning, use whichever is appropriate:

```python
class NavigationStrategy:
    """Choose navigation approach based on mission requirements."""
    
    def plan_navigation(self, mission):
        # Check if global map available and needed
        if mission.requires_multi_room() and self.has_valid_map():
            return self.global_planner.plan(mission.goal)
        
        # Check if goal is visible (camera perception)
        if mission.goal_visible():
            return self.local_planner.plan(mission.goal)
        
        # Fallback: Explore until goal visible
        return self.exploration_planner.plan()
```

**When to use local planning**:
- ✅ Object search ("Find the red ball")
- ✅ Person following
- ✅ Visual navigation ("Go to the chair")
- ✅ Exploration

**When to use global planning**:
- ✅ Multi-room navigation ("Go to the kitchen")
- ✅ Return to specific locations ("Go back to where you saw the ball")
- ✅ Optimal path planning
- ✅ Return to dock/charging station

**Key Point**: Local planning enables fast MVP delivery WITHOUT blocking future global planning integration.

---

### Navigation Success Criteria (Revised)

**Original MVP Success Criterion #3**:
> "Navigate safely in dynamic environments (with/without prior map)"

**Enhanced Success Criteria** (more specific):

**Tier 1: Local Planning** (Week 1 - MVP Minimum):
- ✅ Navigate to visible objects detected by camera
- ✅ Avoid obstacles using LiDAR (VFH collision avoidance)
- ✅ Handle dynamic obstacles (people walking by)
- ✅ Execute recovery behaviors when stuck
- ✅ Success rate > 90% for object search missions

**Tier 2: Global Planning** (Week 2-3 - Enhanced):
- ✅ Build map while exploring (SLAM)
- ✅ Localize in known environments
- ✅ Navigate to semantic locations ("kitchen")
- ✅ Remember and return to specific locations
- ✅ Plan optimal paths avoiding obstacles

**Tier 3: Hybrid** (Week 3-4 - Complete):
- ✅ Switch between local and global planning automatically
- ✅ Use global planning for efficiency when map available
- ✅ Fallback to local planning if localization fails
- ✅ Explore unknown areas while maintaining global awareness

**Deliverable Sequence**:
1. Week 1: Tier 1 working → **Ship MVP v1**
2. Week 2-3: Add Tier 2 → **Ship MVP v2** 
3. Week 3-4: Add Tier 3 → **Ship MVP v3**

This enables early validation and iterative delivery.

---

### Perception Success Criteria (Clarified)

**Original MVP Success Criterion #2**:
> "Execute vision-based missions (find objects, check appliance states)"

**Enhanced Success Criteria** (implementation details):

**Tier 1: YOLO Object Detection** (Week 1 - MVP Minimum):
- ✅ Detect common objects (COCO dataset classes)
- ✅ Estimate 3D position from depth
- ✅ Transform detections to navigation frame (odom)
- ✅ Real-time tracking at 10 FPS
- ✅ Navigate to detected objects

**Tier 2: VLM Semantic Verification** (Week 2 - Enhanced):
- ✅ Verify object properties ("Is this ball RED?")
- ✅ Answer visual questions ("Is the oven on?")
- ✅ Scene understanding ("What room is this?")
- ✅ Hybrid YOLO+VLM pipeline (YOLO fast → VLM verify)
- ✅ Sample VLM at 0.2-1 Hz (balance latency vs accuracy)

**Tier 3: Spatial Memory** (Week 3-4 - Complete):
- ✅ Remember object locations over time
- ✅ Semantic queries ("What did I see in the kitchen?")
- ✅ Update beliefs as environment changes
- ✅ CLIP embeddings for semantic similarity

**Note**: DIMOS already has implementations for all tiers (untested). See:
- Tier 1: `object_detection_stream.py` + `yolo_2d_det.py`
- Tier 2: `qwen/video_query.py` + `get_bbox_from_qwen_frame()`
- Tier 3: `spatial_perception.py` + `SpatialMemory` class

---

## Early Wins Identified

### Win #1: MockRobot for Development Velocity

**Problem**: Hardware testing is slow, risky, and blocks parallel development.

**Solution**: Implement MockRobot (pure Python, no dependencies).

**Benefits**:
- ✅ Unit tests run in milliseconds
- ✅ CI/CD on every commit (GitHub Actions)
- ✅ Multiple developers can work in parallel
- ✅ Test edge cases without hardware risk

**Effort**: 1-2 days

**Priority**: **CRITICAL** - Enables all other work

**Implementation**: See `local_planning_quickstart.md` Phase 0

---

### Win #2: Local Planning Eliminates SLAM Dependency

**Problem**: SLAM + Nav2 untested, high risk, 2-3 week timeline.

**Solution**: VFH local planner (already in DIMOS, just needs testing).

**Benefits**:
- ✅ Working autonomous navigation in 1 week
- ✅ No localization failures (reactive not planned)
- ✅ Simpler to test and debug
- ✅ Sufficient for object search missions
- ✅ Can add global planning later if needed

**Effort**: 2-3 days testing + parameter tuning

**Priority**: **HIGH** - Unblocks perception integration

**Implementation**: See `local_planning_architecture.md`

---

### Win #3: Sequential YOLO+VLM Pipeline

**Problem**: Pure YOLO can't handle nuanced queries ("red ball"). Pure VLM too slow for real-time.

**Solution**: Hybrid pipeline (YOLO finds candidates → VLM verifies).

**Benefits**:
- ✅ Real-time tracking (YOLO at 10 FPS)
- ✅ Semantic reasoning (VLM for verification)
- ✅ Efficient (VLM only on candidates)
- ✅ Handles complex queries ("person in blue shirt")

**Effort**: 1-2 days integration

**Priority**: **MEDIUM** - Enables nuanced missions

**Implementation**: See `hybrid_perception_architecture.md` Pattern 2

---

### Win #4: Trajectory Logging for Learning

**Problem**: No data capture, can't learn from experience.

**Solution**: Log reactive navigation decisions (local planning choices).

**Benefits**:
- ✅ Foundation for persistent intelligence
- ✅ Rich data (VFH decisions, perception, outcomes)
- ✅ Enables offline analysis and adaptation
- ✅ Prepares for multi-brain architecture

**Effort**: 1-2 days (simple JSON logging first)

**Priority**: **MEDIUM** - Enables Phase 2

**Implementation**: See persistent_intelligence_dimos_integration.md Section 3.2

---

## Persistent Intelligence MVP Roadmap

### Phase 1: Foundation (Week 1) - Original MVP Tier 1

**Goal**: Working embodied AI mission with local planning

**Deliverables**:
1. MockRobot implementation (CI/CD enabled)
2. VFH local planner validated on hardware
3. YOLO object detection integrated
4. End-to-end mission: "Find the ball"

**Success Criteria**:
- ✅ Robot finds and navigates to visible objects
- ✅ Success rate > 90% (10 trials)
- ✅ No collisions
- ✅ Mission completion < 30 seconds

**Aligns with Original MVP**: Success criteria #2 (vision missions) and #3 (navigation) Tier 1

**Detailed Timeline**: See `local_planning_quickstart.md`

---

### Phase 2: Learning Infrastructure (Week 2) - Beyond Original MVP

**Goal**: Capture decision data for future learning

**Deliverables**:
1. Trajectory logging system
   - JSON format (simple, readable)
   - Logs: perception, decisions, actions, outcomes
   - Frame consistency (all in odom)
2. Session management
   - Unique session IDs
   - Monotonic timestamps
   - Domain tags (real vs sim)
3. Data viewer/analyzer
   - CLI tool to inspect trajectories
   - Success rate analysis
   - Parameter correlation

**Success Criteria**:
- ✅ Every mission logged completely
- ✅ Logs are parseable and queryable
- ✅ Can replay decisions offline
- ✅ Storage < 10MB per hour

**New Capability**: Foundation for persistent intelligence (not in original MVP)

**Implementation Details**:

```python
# Trajectory log format
{
    "session_id": "2025-10-14-12-34-56-abc123",
    "domain": "real",
    "mission": {
        "instruction": "Find the red ball",
        "start_time": 1234567890.123,
        "end_time": 1234567920.456,
        "result": "success"
    },
    "trajectory": [
        {
            "step": 0,
            "timestamp": 1234567890.234,
            "perception": {
                "detections": [
                    {"label": "ball", "position": [2.0, 0.5], "confidence": 0.8}
                ],
                "frame": "odom"
            },
            "decision": {
                "type": "set_goal",
                "goal_xy": [2.0, 0.5],
                "reason": "yolo_detection"
            },
            "vfh_state": {
                "safety_threshold": 0.8,
                "selected_direction": 0.35,
                "obstacle_density": 0.2
            },
            "action": {
                "linear_vel": 0.3,
                "angular_vel": 0.15
            },
            "outcome": {
                "distance_to_goal": 1.2,
                "collision": false
            }
        }
        // ... more steps
    ]
}
```

---

### Phase 3: Enhanced Perception (Week 2-3) - Original MVP Tier 2

**Goal**: Add VLM semantic reasoning

**Deliverables**:
1. VLM detector integration (Qwen or local LLaVA)
2. Sequential YOLO+VLM pipeline
3. Enhanced missions: "Find the RED ball" (not just any ball)

**Success Criteria**:
- ✅ Can distinguish objects by properties (color, state)
- ✅ VLM latency < 5 seconds
- ✅ Correct object found in 90% of trials

**Aligns with Original MVP**: Success criteria #2 (vision missions) Tier 2

**Implementation**: See `hybrid_perception_architecture.md` Pattern 2 (Sequential)

---

### Phase 4: Global Planning (Week 3-4) - Original MVP Tier 2-3

**Goal**: Add SLAM + Nav2 for multi-room navigation

**Deliverables**:
1. SLAM Toolbox mapping
2. Nav2 global planner integration
3. Hybrid navigation (local + global)
4. Semantic location memory ("kitchen")

**Success Criteria**:
- ✅ Can build map while exploring
- ✅ Can localize in known map
- ✅ Can navigate to semantic locations
- ✅ Switches automatically between local/global

**Aligns with Original MVP**: Success criteria #3 (navigation) Tier 2-3 and #6 (spatial memory)

---

### Phase 5: Persistent Intelligence (Week 4-6) - New Capabilities

**Goal**: Enable learning from experience

**Deliverables**:
1. **WAL (Write-Ahead Logging)**
   - Power-loss safe trajectory logging
   - Segment + manifest pattern
   - Can survive robot crashes/power loss

2. **Offline Analysis Tools**
   - Trajectory visualization
   - Success factor analysis
   - Parameter sensitivity studies
   - Failure mode identification

3. **Adaptive Parameters**
   - Learn optimal VFH parameters from data
   - Adjust safety margins based on outcomes
   - Tune perception thresholds

4. **Isaac Sim Integration** (Tower GPU)
   - Replay trajectories in simulation
   - Test parameter changes safely
   - Validate improvements before deployment

**Success Criteria**:
- ✅ Data survives robot crashes
- ✅ Can identify causes of failures
- ✅ Can test improvements in sim
- ✅ Parameter changes improve success rate

**New Capabilities**: Beyond original MVP scope

**Implementation Details**:

**WAL Pattern**:
```
/data/trajectories/
  ├── 20251014/
  │   ├── segment_001.jsonl    # Active segment
  │   ├── segment_002.jsonl
  │   └── manifest.json         # Index of segments
  └── 20251015/
      └── ...
```

**Analysis Tools**:
```bash
# Analyze success factors
./analyze_trajectories.py --date 2025-10-14 --metric success_rate

# Find failure patterns
./analyze_trajectories.py --failures --group-by perception_confidence

# Visualize trajectory
./visualize_trajectory.py --session 2025-10-14-12-34-56-abc123
```

**Parameter Adaptation**:
```python
# Learn from data
optimizer = TrajectoryOptimizer(trajectories)
improved_params = optimizer.optimize_vfh_parameters()

# Test in simulation
sim_results = test_in_isaac_sim(improved_params, test_scenarios)

# Deploy if better
if sim_results.success_rate > current_success_rate:
    deploy_parameters(improved_params)
```

---

### Phase 6: Multi-Brain Architecture (Week 6-8) - Future Vision

**Goal**: Distributed intelligence (Thor + Spark + Tower)

**Deliverables**:
1. **Message Contracts** (Pydantic schemas)
   - Deliberation RPC
   - Trajectory Log format
   - Adapter metadata

2. **Spark Integration** (when hardware arrives)
   - Receives trajectories from Thor
   - Curates interesting examples
   - Fine-tunes skill adapters (LoRA)
   - Tests in Isaac Sim (Tower)
   - Deploys back to Thor

3. **Day/Night Learning Cycle**
   - Day: Thor operates, logs trajectories
   - Night: Spark learns, Thor tests in sim
   - Morning: Deploy improved adapters

**Success Criteria**:
- ✅ Thor logs trajectories reliably
- ✅ Spark receives and processes logs
- ✅ Adapters improve success rate
- ✅ Deployment is automatic

**Hardware Requirements**:
- Thor: Mobile brainstem (current)
- Spark: DGX Station (not yet acquired)
- Tower: Simulation testing (RTX 4070, available)

**Implementation**: See `persistent_intelligence_architecture_shadowHound.md`

---

## Implementation Priority Matrix

### Critical Path (Must Have for MVP)

| Phase | Item | Effort | Blocks | Priority |
|-------|------|--------|--------|----------|
| 1 | MockRobot | 1-2 days | All testing | 🔴 P0 |
| 1 | VFH local planner | 2-3 days | Perception | 🔴 P0 |
| 1 | YOLO integration | 1-2 days | Missions | 🔴 P0 |
| 1 | End-to-end mission | 1 day | MVP complete | 🔴 P0 |

**Total: ~1 week to working MVP**

### High Value (Should Have)

| Phase | Item | Effort | Blocks | Priority |
|-------|------|--------|--------|----------|
| 2 | Trajectory logging | 1-2 days | Learning | 🟡 P1 |
| 3 | VLM integration | 1-2 days | Nuanced missions | 🟡 P1 |
| 4 | SLAM + Nav2 | 1 week | Multi-room | 🟡 P1 |

**Total: +2 weeks for enhanced MVP**

### Future Work (Nice to Have)

| Phase | Item | Effort | Blocks | Priority |
|-------|------|--------|--------|----------|
| 5 | WAL logging | 2-3 days | Reliability | 🟢 P2 |
| 5 | Isaac Sim | 1-2 weeks | Safe testing | 🟢 P2 |
| 5 | Parameter adaptation | 3-5 days | Learning | 🟢 P2 |
| 6 | Multi-brain | 2-3 weeks | Distributed | 🔵 P3 |

---

## Alignment with Original MVP

### Success Criteria Mapping

| Original MVP Criterion | How Persistent Intelligence MVP Addresses |
|------------------------|------------------------------------------|
| **#1: Voice/console/web commands** | ✅ Console/web in Phase 1, voice deferred to Phase 4 |
| **#2: Vision-based missions** | ✅ Phase 1 (YOLO) + Phase 3 (VLM) |
| **#3: Navigate safely** | ✅ Phase 1 (local) + Phase 4 (global) |
| **#4: Voice output + personality** | ⏸️ Deferred (focus on autonomy first) |
| **#5: Onboard computation** | ✅ Thor AGX for all compute |
| **#6: Learn spatial information** | ✅ Phase 2 (logging) + Phase 5 (learning) |

### What We Add Beyond Original MVP

1. **Faster Development Path**: Local planning first (1 week vs 2-3 weeks)
2. **Learning Infrastructure**: Trajectory logging from day 1
3. **Adaptive System**: Parameters improve from experience
4. **Simulation Integration**: Safe testing in Isaac Sim
5. **Multi-Brain Architecture**: Foundation for distributed intelligence

### What We Defer

1. **Voice Interface**: Console/web sufficient for MVP validation
2. **Personality System**: Can add after autonomy working
3. **Multi-Brain Deployment**: Requires Spark hardware (not yet acquired)

---

## Risk Assessment

### High Risk Items

**1. go2_ros2_sdk Local Costmap**
- **Risk**: VFH planner needs `/local_costmap/costmap` topic
- **Impact**: Blocks Phase 1 (local planning)
- **Mitigation**: Generate costmap from `/scan` if needed
- **Probability**: Medium (30%)

**2. Thor GPU Performance**
- **Risk**: Degraded performance (5 tok/s vs 37 tok/s)
- **Impact**: VLM latency too high
- **Mitigation**: Use cloud VLM or troubleshoot Thor
- **Probability**: High (60%)

**3. WebRTC API Blocker**
- **Risk**: Most DIMOS skills non-functional
- **Impact**: Limited skill set available
- **Mitigation**: Use working skills, implement custom Nav2 skills
- **Probability**: High (100% - known issue)

### Medium Risk Items

**4. Frame Transformation Errors**
- **Risk**: base_link → odom transforms incorrect
- **Impact**: Wrong navigation goals
- **Mitigation**: Extensive validation in Phase 1
- **Probability**: Medium (40%)

**5. Depth Estimation Accuracy**
- **Risk**: Metric3D errors > 50cm
- **Impact**: Inaccurate object positions
- **Mitigation**: Calibrate, validate, consider RGB-D camera
- **Probability**: Low (20%)

### Mitigation Strategies

**Phase 1 Validation** (reduce risk before Phase 2):
- Validate every transform with known test positions
- Test obstacle avoidance extensively
- Benchmark perception accuracy
- Document failure modes

**Incremental Delivery** (fail fast):
- Ship Phase 1 before starting Phase 2
- Get user feedback at each phase
- Pivot if assumptions wrong

**Parallel Tracks** (reduce critical path):
- Phase 2 (logging) can start during Phase 1
- Phase 5 (Isaac Sim) can start during Phase 3-4
- Documentation continuously updated

---

## Success Metrics

### Phase 1 (MVP Minimum)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Mission Success Rate** | > 90% | 10 trials, "Find the ball" |
| **Navigation Accuracy** | < 1m error | Distance to object |
| **Mission Duration** | < 30s | Start to completion |
| **Collision Rate** | 0% | No collisions in 10 trials |

### Phase 2 (Learning Infrastructure)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Logging Reliability** | 100% | No lost data |
| **Storage Efficiency** | < 10MB/hr | Disk usage |
| **Replay Accuracy** | 100% | Can reconstruct all decisions |

### Phase 5 (Persistent Intelligence)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Learning Improvement** | +10% success rate | After parameter adaptation |
| **Sim-to-Real Transfer** | > 80% | Sim predictions → real outcomes |
| **Data Durability** | Zero loss | Survives crashes |

---

## Hardware Evolution

### Current Hardware (MVP Phase 1-4)

- **Development**: Laptop (ROS2, DIMOS, mission agent)
- **Compute**: Thor AGX 128GB (LLM/VLM inference)
- **Robot**: Unitree Go2 Pro (sensors, actuators)
- **Simulation**: Tower RTX 4070 (available, unused)

### Future Hardware (Phase 6+)

- **Thor**: Mobile brainstem (real-time control)
- **Spark**: DGX Station (learning, fine-tuning) ← **Not yet acquired**
- **Tower**: Simulation avatar (Isaac Sim testing)
- **Go2**: Body (unchanged)

### Migration Path

**Phase 1-4**: Everything on laptop + Thor (current)
**Phase 5**: Add Tower for Isaac Sim (RTX 4070)
**Phase 6**: Add Spark when hardware arrives

---

## Open Questions

### Phase 1 Unknowns
- [ ] Does go2_ros2_sdk publish local costmap?
- [ ] What is costmap update rate?
- [ ] Camera calibration parameters available?
- [ ] Can Thor handle VLM inference?

### Phase 2-3 Unknowns
- [ ] Which VLM to use? (Qwen API vs local LLaVA)
- [ ] What VLM sample rate? (balance latency vs accuracy)
- [ ] How to handle conflicting detections? (YOLO vs VLM)

### Phase 4 Unknowns
- [ ] SLAM Toolbox parameters for Go2?
- [ ] Nav2 costmap layer configuration?
- [ ] Semantic map representation?

### Phase 5-6 Unknowns
- [ ] When does Spark hardware arrive?
- [ ] What adapter architecture? (LoRA, BitFit, etc.)
- [ ] How to transfer sim-to-real?

---

## Next Steps

### Immediate Actions (This Week)

1. **Decision**: Approve persistent intelligence MVP approach
2. **Action**: Create GitHub issues for Phase 1 tasks
3. **Action**: Set up MockRobot development environment
4. **Action**: Validate go2_ros2_sdk local costmap availability

### Week 1 Execution

- [ ] Day 1-2: Implement MockRobot (CI/CD)
- [ ] Day 3-4: Test VFH local planner on hardware
- [ ] Day 5: Integrate YOLO detection
- [ ] Day 6-7: End-to-end mission testing

### Week 2 Planning

- [ ] Review Phase 1 results
- [ ] Decide: Continue to Phase 2 or iterate Phase 1?
- [ ] Plan trajectory logging implementation
- [ ] Research VLM options (API vs local)

---

## Conclusion

### Why This Approach Works

1. **Builds on Original MVP**: Respects existing goals and success criteria
2. **Accelerates Development**: Local planning first gets to autonomous navigation faster
3. **Reduces Risk**: Simpler stack, fewer dependencies, iterative delivery
4. **Enables Learning**: Trajectory logging from day 1 prepares for persistent intelligence
5. **Hybrid Strategy**: Supports both local and global planning, use what's appropriate

### Key Differentiators

**vs Original MVP**:
- ✅ Faster timeline (1 week vs 3-4 weeks to first autonomous mission)
- ✅ Lower risk (proven local planning vs untested SLAM)
- ✅ Learning foundation (trajectory logging built in)
- ✅ Incremental delivery (ship Phase 1, then enhance)

**vs Pure Research**:
- ✅ Concrete deliverables (working robot at each phase)
- ✅ Measurable success criteria
- ✅ Practical constraints acknowledged (hardware, APIs)
- ✅ Migration path to future vision

### Recommendation

**Approve persistent intelligence MVP approach with local planning first strategy.**

This enables:
- Rapid validation of autonomous navigation (1 week)
- Early user feedback and iteration
- Foundation for continuous learning
- Clear path to multi-brain architecture

While maintaining:
- Original MVP goals and success criteria
- Flexibility to add global planning when needed
- Option to enhance with voice, personality, etc.

---

## References

### Related Documentation

- **Foundation**: [ShadowHound MVP: Embodied AI Platform](../project_overview/mvp_embodied_ai_platform.md)
- **Technical Deep Dive**: [Local Planning Architecture](local_planning_architecture.md)
- **Perception Patterns**: [Hybrid Perception Architecture](hybrid_perception_architecture.md)
- **Quick Start**: [Local Planning Quickstart](local_planning_quickstart.md)
- **Learning Integration**: [Persistent Intelligence DIMOS Integration](persistent_intelligence_dimos_integration.md)
- **Future Vision**: [Persistent Intelligence Architecture](persistent_intelligence_architecture_shadowHound.md)

### External References

- **VFH Algorithm**: Borenstein & Koren (1991)
- **Pure Pursuit**: Coulter (1992)
- **DIMOS Framework**: `src/dimos-unitree/`
- **Go2 SDK**: `go2_ros2_sdk` documentation
