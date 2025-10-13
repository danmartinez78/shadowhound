---
tags: [development/tracking, tasks, project]
status: active
related: [roadmap.md, status_analysis_2025_10.md, cloud_agent_workflow.md]
summary: >
  Active TODO list for ShadowHound development - organized by phase with clear priorities,
  acceptance criteria, and links to relevant documentation.
---

# ShadowHound TODO List

**Last Updated**: 2025-10-13 (Major revision based on status analysis)  
**Current Phase**: Phase 0 (Infrastructure) → Phase 1 (Skills Foundation)

**Key Changes**:
- Realistic assessment: We're completing Phase 0, not Phase 1
- Focus on actual implementation (skills, testing)
- Leverage cloud agents for suitable tasks
- Clear acceptance criteria for all tasks

See [Status Analysis (Oct 2025)](../project_overview/status_analysis_2025_10.md) for detailed assessment.

---

## 🔴 Phase 0: Complete Infrastructure (10% Remaining)

**Goal**: Finish testing infrastructure before moving to Phase 1

### Testing Infrastructure ⭐
- [ ] Set up pytest configuration
  - Create `pytest.ini` in workspace root
  - Configure test discovery patterns
  - Set up coverage reporting
  - **Acceptance**: `pytest` runs successfully from workspace root
  - **Related**: All package `test/` directories

- [ ] Create mock robot interface
  - Mock DIMOS API calls
  - Configurable behavior for testing
  - State tracking for assertions
  - **Acceptance**: Can test skills without real robot
  - **Related**: `shadowhound_skills/shadowhound_skills/mock_robot.py`

- [ ] Add CI for testing
  - GitHub Actions workflow for tests
  - Run on every PR
  - Block merge if tests fail
  - **Acceptance**: CI runs tests automatically
  - **Related**: `.github/workflows/tests.yml`

### Code Quality in CI
- [ ] Add black/isort/flake8 checks
  - Format checking (not auto-format)
  - Import sorting validation
  - Linting with project rules
  - **Acceptance**: CI fails on style violations
  - **Related**: `.github/workflows/quality.yml`

**Estimated Time**: 1-2 days  
**Cloud Agent Candidate**: ✅ Yes - Well-defined setup tasks

---

## 🔴 Phase 1: Skills Foundation (Priority Tasks)

**Goal**: Implement core skills infrastructure + 3-5 working skills

See [Roadmap Phase 1](../project_overview/roadmap.md#phase-1-skills-foundation) for complete deliverables.

### Core Infrastructure (Week 1)

#### RobotInterface Implementation ⭐⭐⭐
- [ ] Design RobotInterface class
  - Define interface methods (move, rotate, stop, etc.)
  - DIMOS API integration points
  - Safety parameter configuration
  - **Acceptance**: Interface design documented
  - **Related**: `docs/software/robot_interface_design.md` (create)
  
- [ ] Implement RobotInterface
  - Connect to DIMOS API
  - Wrap basic motion commands
  - Add safety clamps (velocity, bounds)
  - Timeout and error handling
  - **Acceptance**: Can control robot via interface
  - **Related**: `shadowhound_skills/shadowhound_skills/robot_interface.py`

- [ ] Test RobotInterface
  - Unit tests with mock DIMOS
  - Integration tests with real/sim robot
  - Safety parameter validation
  - **Acceptance**: >80% test coverage
  - **Related**: `shadowhound_skills/test/test_robot_interface.py`

#### SkillRegistry Implementation ⭐⭐⭐
- [ ] Create Skill base class
  - Abstract `validate_params()` method
  - Abstract `execute()` method
  - Common telemetry collection
  - **Acceptance**: Base class usable for all skills
  - **Related**: `shadowhound_skills/shadowhound_skills/skill_base.py`

- [ ] Implement SkillRegistry
  - `@register_skill` decorator
  - Skill discovery mechanism
  - `execute(skill_name, **params)` method
  - Validation before execution
  - **Acceptance**: Can register and execute skills
  - **Related**: `shadowhound_skills/shadowhound_skills/skill_registry.py`

- [ ] Create SkillResult dataclass
  - `success: bool`
  - `data: dict`
  - `error: Optional[str]`
  - `telemetry: dict`
  - **Acceptance**: All skills return SkillResult
  - **Related**: `shadowhound_skills/shadowhound_skills/skill_base.py`

### First 3 Skills (Week 1-2)

#### Skill 1: nav.stop
- [ ] Implement StopSkill
  - Immediately set all velocities to zero
  - No parameters needed
  - Always succeeds (unless comms failure)
  - **Acceptance**: Robot stops within 0.5s
  - **Related**: `shadowhound_skills/shadowhound_skills/skills/navigation.py`

- [ ] Test StopSkill
  - Unit test with mock
  - Integration test (verify velocities zero)
  - **Acceptance**: Tests pass
  - **Related**: `shadowhound_skills/test/test_navigation_skills.py`

#### Skill 2: nav.rotate
- [ ] Implement RotateSkill
  - Parameter: `yaw` (degrees, -180 to 180)
  - Rotate robot by specified angle
  - Timeout after 10s
  - **Acceptance**: Rotates accurately ±5 degrees
  - **Related**: `shadowhound_skills/shadowhound_skills/skills/navigation.py`

- [ ] Test RotateSkill
  - Unit tests (parameter validation, timeout)
  - Integration test (measure actual rotation)
  - **Acceptance**: Tests pass
  - **Related**: `shadowhound_skills/test/test_navigation_skills.py`

#### Skill 3: report.log
- [ ] Implement LogSkill
  - Parameter: `message` (string, 1-500 chars)
  - Log to ROS logger with timestamp
  - Always succeeds
  - **Acceptance**: Message appears in logs
  - **Related**: `shadowhound_skills/shadowhound_skills/skills/reporting.py`

- [ ] Test LogSkill
  - Unit test (parameter validation)
  - Integration test (verify log output)
  - **Acceptance**: Tests pass
  - **Related**: `shadowhound_skills/test/test_reporting_skills.py`

### Documentation (Week 2)
- [ ] Document skills API
  - How to implement a skill
  - How to register a skill
  - How to execute a skill
  - **Acceptance**: Developer can add new skill
  - **Related**: `docs/software/skills_api_guide.md` (create)

- [ ] Document implemented skills
  - Parameters, return values, examples
  - Success/failure scenarios
  - Performance characteristics
  - **Acceptance**: Each skill has complete docs
  - **Related**: `docs/software/skills_reference.md` (create)

**Estimated Time**: 2-3 weeks total for Phase 1 core  
**Cloud Agent Candidates**: 
- ✅ Testing infrastructure (skill 1-3 after examples set)
- ✅ Documentation generation
- ⚠️ RobotInterface (needs domain knowledge)

---

## 🟡 Phase 1: Additional Skills (After Core)

**Prerequisite**: Core infrastructure + first 3 skills working

### Navigation Skills (3-5 more)
- [ ] `nav.translate` - Move forward/backward
- [ ] `nav.goto` - Navigate to pose (x, y, yaw)
- [ ] `nav.follow_path` - Follow waypoint list

### Perception Skills (3)
- [ ] `perception.snapshot` - Capture camera image
- [ ] `perception.scan_lidar` - Get lidar scan
- [ ] `perception.detect_obstacles` - Basic obstacle detection

### System Skills (2-3)
- [ ] `system.health_check` - Verify systems operational
- [ ] `system.emergency_stop` - Safe emergency shutdown
- [ ] `system.battery_status` - Report battery level

**Estimated Time**: 1-2 weeks  
**Cloud Agent Candidate**: ✅ Yes - Follow established patterns

---

## 🟢 Phase 2: Mission Agent (Future)

**Prerequisite**: Phase 1 complete (10-15 working skills)

See [Roadmap Phase 2](../project_overview/roadmap.md#phase-2-mission-agent) for details.

### High Priority (When Phase 2 Starts)
- [ ] DIMOS agent integration
- [ ] Mission executor node
- [ ] Web dashboard UI ← **Excellent cloud agent task**
- [ ] Camera feed integration
- [ ] Example missions (5+)

---

## ✅ Recently Completed

### October 2025 (Week 2) - Infrastructure & Documentation
- ✅ **Documentation pipeline reversal** (Issue #20)
  - Author in standard Markdown, generate Obsidian vault locally
  - Created `tools/obsidian_convert.py` and `scripts/generate_obsidian_vault.sh`
  - Simplified CI, removed 165k lines of build artifacts
  - 8x velocity improvement demonstrated

- ✅ **Cloud agent collaboration workflow**
  - Comprehensive workflow documentation (600+ lines)
  - Quick start guide (200+ lines)
  - GitHub issue templates (cloud agent, feature, bug)
  - Integrated into development hub

- ✅ **Submodule protection**
  - .gitattributes marking (linguist-vendored, -diff)
  - VS Code formatter exclusions
  - Troubleshooting documentation

- ✅ **Project status analysis**
  - Comprehensive assessment of actual vs. claimed state
  - Lessons learned documentation
  - Roadmap revision with specific deliverables
  - TODO reorganization by phase

### October 2025 (Week 1) - Documentation Cleanup
- ✅ Fixed documentation navigation and structure
- ✅ Created hub pages for all major categories
- ✅ Optimized Obsidian graph view with colors
- ✅ Eliminated phantom nodes and broken links
- ✅ Applied YAML front-matter consistently
- ✅ Created wikilink validation tool

### September - October 2025 - Bootstrap Phase
- ✅ Devcontainer with ROS2 Humble + DIMOS
- ✅ Package structure (3 packages: bringup, mission_agent, skills)
- ✅ Build system working (`colcon build`)
- ✅ DIMOS submodule integration
- ✅ Helpful aliases (cb, source-ws, etc.)

### Pre-October 2025 (Historical Context)
**Note**: These were marked as complete in previous versions but may not actually exist in codebase. See [Status Analysis](../project_overview/status_analysis_2025_10.md) for reality check.

- ⚠️ Local LLM integration (claimed, needs verification)
- ⚠️ Agent improvements for tool calling (claimed, needs verification)
- ⚠️ Camera feed fixes (claimed, needs verification)
- ⚠️ Web UI optimizations (claimed, needs verification)
- ⚠️ Multi-step execution (claimed, needs verification)

---

## 📋 Task Management

### Priority Levels
- 🔴 **Phase 0 (Current)**: Blocking Phase 1 start
- 🔴 **Phase 1 (Next)**: Core skills implementation
- 🟡 **Phase 1 (Additional)**: Extra skills after core
- 🟢 **Phase 2 (Future)**: Mission agent work
- 🔵 **Future Phases**: Phase 3-4 work

### Adding New Tasks
When adding tasks, include:
1. **Clear title**: What needs to be done
2. **Context/Why**: Reason it's needed
3. **Acceptance criteria**: How to verify completion
4. **Related files/docs**: Links to relevant code or docs
5. **Cloud agent candidate**: ✅/⚠️/❌ suitable for cloud agent?

**Example**:
```markdown
- [ ] Implement RotateSkill
  - Context: Basic navigation skill for Phase 1
  - Acceptance: Rotates accurately ±5 degrees within 10s
  - Related: `shadowhound_skills/shadowhound_skills/skills/navigation.py`
  - Cloud Agent: ⚠️ After first skill as example
```

### Cloud Agent Strategy
- ✅ **Good candidates**: Well-defined, repeatable, testable
- ⚠️ **Maybe**: After examples established
- ❌ **Not suitable**: Requires domain knowledge, architectural decisions

**See**: [Cloud Agent Workflow](cloud_agent_workflow.md) for details

---

## 📊 Progress Tracking

### Current Sprint (Phase 0 → Phase 1)
**Target**: Complete Phase 0, start Phase 1 core  
**Duration**: 1-2 weeks  
**Status**: Phase 0 at 90%

### Completion Metrics
- Phase 0: 90% (9/10 tasks complete)
- Phase 1 Core: 0% (0/15 tasks started)
- Phase 1 Additional: 0% (0/9 tasks started)

### Next Milestone
**Phase 1 Core Complete**:
- All infrastructure tasks done
- First 3 skills working and tested
- Documentation complete
- **Target**: November 15, 2025

---

## See Also
- **[Roadmap](../project_overview/roadmap.md)** - Phase-by-phase plan with deliverables
- **[Status Analysis](../project_overview/status_analysis_2025_10.md)** - Current state assessment
- **[Cloud Agent Workflow](cloud_agent_workflow.md)** - High-velocity development
- **[Development Hub](development_hub.md)** - All development processes
- **[Quick Start](../project_overview/quick_start.md)** - Get started guide

---

**Maintenance**: Update this file weekly during active development, monthly during stable periods.

---
