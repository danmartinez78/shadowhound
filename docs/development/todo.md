# ShadowHound TODO List

**Last Updated**: 2025-10-08

---

## 🔴 High Priority

### Agent System
- [ ] Add vision integration to mission executor
  - Use VLM for visual context in planning
  - Test with camera feed from robot
  - Related: `docs/VISION_INTEGRATION_DESIGN.md`

- [ ] Implement remaining unit tests (4 skipped tests)
  - Test mission pause/resume functionality
  - Test error recovery scenarios
  - Test telemetry collection

- [ ] Add mission history and replay capability
  - Store mission execution logs
  - Allow replaying past missions
  - Export mission data for analysis

### Robot Integration
- [ ] Validate all 47 skills on hardware
  - Systematic testing of each skill
  - Document any issues or limitations
  - Create skill test suite

- [ ] Improve error handling in robot interface
  - Better timeout management
  - Graceful degradation when skills fail
  - Recovery strategies

### Testing & Quality
- [ ] Add integration tests for full mission flow
  - End-to-end mission execution
  - Test with mock robot and real robot
  - Automated regression testing

- [ ] Set up continuous integration (CI)
  - Automated builds on commits
  - Run unit tests automatically
  - Code quality checks (linting, formatting)

---

## 🟡 Medium Priority

### Documentation
- [ ] Create video walkthrough of system
  - Architecture overview
  - How to write a mission
  - Debugging tips

- [ ] Document all 47 skills
  - Parameters, return values, examples
  - Success/failure scenarios
  - Performance characteristics

- [ ] Update README with latest architecture
  - Reflect MissionExecutor changes
  - Update setup instructions
  - Add troubleshooting section

### Features
- [ ] Add mission templates
  - Common mission patterns
  - Reusable mission components
  - Template library

- [ ] Implement mission composition
  - Combine simple missions into complex ones
  - Mission scripting language
  - Conditional execution

- [ ] Add telemetry dashboard
  - Real-time mission status
  - Performance metrics
  - Historical data visualization

### DevOps
- [ ] Optimize Docker build times
  - Multi-stage builds
  - Better layer caching
  - Reduce image size

- [ ] Create deployment scripts
  - One-command deployment
  - Environment validation
  - Health checks

---

## 🟢 Low Priority / Nice to Have

### Enhancements
- [ ] Add voice command support
  - Natural language mission input
  - Voice feedback from robot
  - Integration with speech processor

- [ ] Create mobile app for mission control
  - Remote mission triggering
  - Status monitoring
  - Emergency stop

- [ ] Add simulation environment
  - Test missions without robot
  - Gazebo integration
  - Synthetic camera feeds

### Code Quality
- [ ] Increase test coverage to >90%
  - Add more unit tests
  - Integration test coverage
  - Coverage reporting

- [ ] Add type checking in CI
  - mypy validation
  - Strict type hints
  - Type documentation

- [ ] Performance profiling
  - Identify bottlenecks
  - Optimize hot paths
  - Memory usage analysis

---

---

## 🔵 Post-Merge Tasks (feature/local-llm-support)

### Skill Testing
- [ ] Test Wait skill more thoroughly
  - Context: Observed issues during multi-step command testing
  - Test cases:
    - Wait with various durations (1s, 5s, 10s, 30s)
    - Wait in middle of multi-step sequence
    - Verify robot stays idle during wait
    - Check if duration is respected accurately
  - Related: `src/dimos-unitree/dimos/robot/unitree/unitree_skills.py`
  - Reported: 2025-10-12 during local LLM testing

---

## ✅ Recently Completed

### 2025-10-12
- ✅ Local LLM integration (vLLM on Thor)
  - Proof of concept with Mistral-7B and Qwen2.5-Coder-7B
  - Local embeddings with sentence-transformers
  - Custom chat templates for vLLM
  - ~60% success rate (needs more tuning)
- ✅ Agent improvements for tool calling
  - Added tool_choice='auto' to DIMOS OpenAIAgent
  - Added temperature=0.0 for deterministic responses
  - Improved GPT-4o performance: 100% consistent, 2-7s response time
- ✅ Dual configuration system (cloud + local)
  - Easy switching between backends in .env
  - Documentation and setup scripts
  - Merge to dev branch ready

### 2025-10-08
- ✅ Fixed camera feed QoS mismatch (BEST_EFFORT vs RELIABLE)
- ✅ Optimized web UI layout for laptop screens
  - Camera feed (400x300) on left with fixed aspect ratio
  - Performance + Diagnostics stacked on right
  - Everything fits on one screen without scrolling
- ✅ Added collapsible topics list to save vertical space
- ✅ Updated command examples (removed abandoned pose skills)
- ✅ Validated multi-step execution with PlanningAgent
- ✅ Added comprehensive camera callback debug logging

### 2025-10-06
- ✅ Agent refactor: Separate ROS concerns from business logic
- ✅ Create MissionExecutor (pure Python)
- ✅ Simplify MissionAgentNode (thin wrapper)
- ✅ Add 14 unit tests for MissionExecutor
- ✅ Update AGENT_ARCHITECTURE.md documentation
- ✅ Fix executor naming conflict with ROS2 Node
- ✅ Fix model parameter name for DIMOS
- ✅ Add configurable token limits
- ✅ Validate on robot (47 skills loaded)
- ✅ Merge feature/agent-refactor into feature/dimos-integration

---

## 📋 Task Categories

### Legend
- 🔴 **High Priority**: Critical for next milestone or blocking other work
- 🟡 **Medium Priority**: Important but not urgent
- 🟢 **Low Priority**: Nice to have, can wait
- ✅ **Completed**: Done and validated

### Adding New Tasks
When adding tasks, include:
1. **Clear title**: What needs to be done
2. **Context**: Why it's needed
3. **Acceptance criteria**: How to verify completion
4. **Related files/docs**: Links to relevant code or documentation

Example:
```markdown
- [ ] Task title
  - Context: Why this is needed
  - Acceptance: How to verify it's done
  - Related: `path/to/file.py`, `docs/doc.md`
```
