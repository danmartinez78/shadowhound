---
tags: [project_overview/planning, roadmap, milestones]
status: active
related: []
summary: >
  High-level phases and milestones for the ShadowHound robot dog initiative.
aliases: [roadmap]
---

# Project Roadmap

## Purpose
Define strategic milestones with specific, measurable deliverables that guide ShadowHound development from infrastructure to field-ready autonomy.

**Last Updated**: 2025-10-13 (Revised with specific deliverables)  
**Current Phase**: Phase 0 (Infrastructure) - 90% Complete

## Prerequisites
- Familiarity with the ShadowHound architecture and mission goals
- Access to [Status Analysis](status_analysis_2025_10.md) for current state assessment
- Understanding of [Development Workflows](../development/development_hub.md)

---

## Phase Overview

### 📊 Progress Summary

| Phase | Status | Completion | Target Date |
|-------|--------|------------|-------------|
| Phase 0: Infrastructure | 🔄 In Progress | 90% | Oct 2025 ✅ |
| Phase 1: Skills Foundation | 🔜 Next | 0% | Nov 2025 |
| Phase 2: Mission Agent | 🔮 Planned | 0% | Dec 2025 - Jan 2026 |
| Phase 3: Hardware Validation | 🔮 Planned | 0% | Feb - Mar 2026 |
| Phase 4: Advanced Autonomy | 🔮 Future | 0% | Apr - May 2026 |

---

## Phase 0: Infrastructure ✅ 90% Complete

**Goal**: Development environment and documentation infrastructure ready for rapid implementation

**Duration**: September - October 2025

### Deliverables

#### ✅ Completed
- [x] Devcontainer with ROS2 Humble + DIMOS
- [x] Package structure (3 packages: bringup, mission_agent, skills)
- [x] Build system working (`colcon build`)
- [x] Documentation infrastructure (MkDocs, GitHub Pages, Obsidian vault)
- [x] Development workflows documented
- [x] Cloud agent collaboration workflow
- [x] Issue templates and PR templates
- [x] Submodule protection (auto-formatting prevention)

#### 🔄 Remaining (10%)
- [ ] Testing infrastructure (pytest configuration, CI for tests)
- [ ] Code quality checks in CI (black, flake8, mypy)
- [ ] Mock robot interface for testing

### Success Criteria
✅ Team can develop efficiently with clear docs and workflows  
⏸️ Can run automated tests on every PR (blocked on testing infrastructure)

**Next Action**: Complete testing infrastructure → Phase 1

---

## Phase 1: Skills Foundation 🔜 Target: November 2025

**Goal**: 10-15 working skills with comprehensive testing, validated in simulation

**Duration**: 2-3 weeks (with cloud agent assistance)

### Deliverables

#### Core Infrastructure
- [ ] **RobotInterface** implemented
  - Connects to DIMOS API
  - Wraps basic motion commands
  - Safety clamps (velocity limits, bounds checking)
  - Error handling and timeouts

- [ ] **SkillRegistry** implemented
  - Skill base class with validation
  - Registration decorator (`@register_skill`)
  - Discovery mechanism
  - Execution engine with telemetry

- [ ] **Testing Infrastructure**
  - pytest configuration
  - Mock robot interface
  - Test utilities and fixtures
  - CI integration (GitHub Actions)

#### Navigation Skills (5)
- [ ] `nav.stop` - Immediately stop all motion
- [ ] `nav.rotate` - Rotate by angle (degrees)
- [ ] `nav.translate` - Move forward/backward by distance
- [ ] `nav.goto` - Navigate to (x, y, yaw) pose
- [ ] `nav.follow_path` - Follow waypoint list

#### Perception Skills (3)
- [ ] `perception.snapshot` - Capture camera image
- [ ] `perception.scan_lidar` - Get lidar scan data
- [ ] `perception.detect_obstacles` - Basic obstacle detection

#### Reporting Skills (3)
- [ ] `report.log` - Log message with timestamp
- [ ] `report.speak` - Text-to-speech (if available)
- [ ] `report.status` - Report system status

#### System Skills (2-4)
- [ ] `system.health_check` - Verify all systems operational
- [ ] `system.emergency_stop` - Safe emergency shutdown
- [ ] `system.battery_status` - Report battery level
- [ ] `system.reset` - Reset to safe state (optional)

### Success Criteria
- ✅ All skills pass unit tests (>80% coverage)
- ✅ Can execute "rotate 90 degrees, move forward 1 meter, stop" via skills API
- ✅ Skills validated in simulation (Gazebo or mock)
- ✅ Documentation complete for all skills

**Estimated Effort**: 40-60 hours (2-3 weeks with cloud agent for testing/docs)

---

## Phase 2: Mission Agent 🔮 Target: December 2025 - January 2026

**Goal**: Natural language mission execution with real-time monitoring

**Duration**: 1-2 months

### Deliverables

#### Mission Agent Core
- [ ] **DIMOS Agent Integration**
  - OpenAI agent for single-shot commands
  - PlanningAgent for multi-step missions
  - Configuration switching (cloud vs local LLM)
  - **Dependency**: [DIMOS Documentation Issue #7](https://github.com/danmartinez78/dimos-unitree/issues/7) - Integration guides
  
- [ ] **Mission Executor Node**
  - ROS2 node wrapping mission executor
  - Skill execution via SkillRegistry
  - Status publishing
  - Error recovery

#### User Interface
- [ ] **Web Dashboard**
  - Real-time camera feed
  - Mission status display
  - Performance metrics
  - Command input interface
  - Terminal/log viewer

- [ ] **Telemetry System**
  - Mission execution tracking
  - Skill performance metrics
  - System health monitoring
  - Historical data storage

#### Integration
- [ ] **Camera Feed Integration**
  - ROS2 topic subscription
  - Image compression/streaming
  - QoS configuration
  
- [ ] **Example Missions**
  - 5+ documented example missions
  - Simple to complex progression
  - Test suite for mission validation

### Success Criteria
- ✅ Can execute "patrol the area" and robot follows multi-waypoint path
- ✅ Web UI shows live camera feed and status
- ✅ Mission success rate >90% in simulation
- ✅ Response time <5s for multi-step commands

**Estimated Effort**: 80-120 hours (1-2 months, web UI via cloud agent)

---

## Phase 3: Hardware Validation 🔮 Target: February - March 2026

**Goal**: Reliable operation on Unitree Go2 in controlled environment

**Duration**: 1-2 months

### Deliverables

#### Hardware Integration
- [ ] **Skills on Real Hardware**
  - All 13+ skills tested on Go2
  - Safety parameters calibrated
  - Performance benchmarks collected
  - Hardware-specific quirks documented

- [ ] **Safety Systems**
  - Emergency stop validated
  - Collision avoidance working
  - Battery monitoring active
  - Failsafe behaviors tested

#### Testing & Validation
- [ ] **Field Test Suite**
  - 10+ test missions designed
  - Indoor environment testing
  - Various terrain types
  - Edge case validation

- [ ] **Performance Metrics**
  - Mission success rate >90%
  - Average response time <2s
  - Battery efficiency measured
  - Network reliability tested

#### Documentation
- [ ] **Operations Manual**
  - Hardware setup guide
  - Safety procedures
  - Troubleshooting guide
  - Maintenance checklist

### Success Criteria
- ✅ 90%+ mission success rate in controlled indoor environment
- ✅ Robot can run for 30+ minutes on single charge
- ✅ Emergency stop works reliably
- ✅ No safety incidents during testing

**Estimated Effort**: 60-80 hours (1-2 months of hardware testing)

---

## Phase 4: Advanced Autonomy 🔮 Target: April - May 2026

**Goal**: Outdoor autonomy with vision-based navigation

**Duration**: 2-3 months

### Deliverables

#### Vision & Perception
- [ ] **VLM Integration**
  - Scene understanding via vision-language models
  - Object detection and tracking
  - Semantic scene parsing
  - Visual navigation assistance

- [ ] **Advanced Navigation**
  - Dynamic obstacle avoidance
  - Terrain assessment
  - Weather/lighting adaptation
  - Path planning with vision

#### Multi-Robot (Optional)
- [ ] **Coordination**
  - Multi-robot discovery
  - Task allocation
  - Collision avoidance
  - Fleet management

#### Persistence
- [ ] **World Model**
  - Persistent map storage
  - Object memory
  - Location history
  - Learning from experience

### Success Criteria
- ✅ Can navigate outdoor environment autonomously
- ✅ Adapts to changing conditions (lighting, weather)
- ✅ Avoids dynamic obstacles reliably
- ✅ Mission success rate >80% outdoors

**Estimated Effort**: 120-160 hours (2-3 months)

---

## Dependencies & Risk Mitigation

### Phase Dependencies
- Phase 1 → Phase 2: Need working skills before mission agent
- Phase 2 → Phase 3: Need working agent before hardware testing
- Phase 3 → Phase 4: Need reliable hardware operation before advanced features

### Known Risks

#### Phase 1 Risks
- **Risk**: DIMOS API complexity
- **Mitigation**: Start with simple skills, thorough mocking

#### Phase 2 Risks
- **Risk**: LLM latency/reliability
- **Mitigation**: Local LLM option, timeout handling

#### Phase 3 Risks  
- **Risk**: Hardware unavailability
- **Mitigation**: Extensive simulation testing first

#### Phase 4 Risks
- **Risk**: Outdoor complexity (weather, terrain)
- **Mitigation**: Gradual outdoor exposure, fallback behaviors

---

## Velocity Multipliers

### Cloud Agent Usage
Target: Use cloud agents for 30-50% of implementation work

**Phase 1 Candidates**:
- Testing infrastructure setup
- Mock robot interface
- Individual skill implementations (after first 2 as examples)

**Phase 2 Candidates**:
- Web UI implementation (excellent cloud agent task)
- Telemetry dashboard
- Example mission collection

**Phase 3 Candidates**:
- Test suite generation
- Documentation updates
- Performance analysis scripts

### Expected Velocity Gains
- **Without cloud agents**: 6-9 months total
- **With cloud agents**: 4-6 months total (30-40% faster)

---

---

## Validation
- [x] Roadmap aligns with actual project state (Oct 2025 analysis)
- [x] Each phase has specific, measurable deliverables
- [x] Success criteria defined for each phase
- [x] Dependencies and risks documented
- [ ] Phase 1 tasks broken into GitHub issues
- [ ] Cloud agent candidates identified for each phase

## See Also
- **[Status Analysis (Oct 2025)](status_analysis_2025_10.md)** - Comprehensive state assessment
- **[Project TODO](todo.md)** - Detailed task backlog
- **[Setup Status](setup_status.md)** - Initial integration milestone
- **[Architecture Review](architecture_review_summary.md)** - Design decisions
- **[Development Hub](../development/development_hub.md)** - Implementation workflows
- **[Cloud Agent Workflow](../development/cloud_agent_workflow.md)** - High-velocity development
- **[Software Hub](../software/software_hub.md)** - Package development

## References
- [Project Overview Hub](project_overview_hub.md)
- [System Architecture](../architecture/architecture_hub.md)
- [Repository README](../../README.md)
- [Development Log](../research/devlog.md)
