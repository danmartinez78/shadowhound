---
tags: [project, planning]
status: draft
related: []
summary: >
  Prioritized backlog tracking outstanding ShadowHound work items, milestones, and recently completed tasks.
---

# Project TODO Backlog

## Purpose
Track high, medium, and low priority tasks for the ShadowHound program while capturing recently completed work for historical context.

## Prerequisites
- Awareness of the current mission goals outlined in [Project Roadmap](project_overview/roadmap.md).
- Agreement with stakeholders on priority definitions (🔴 high, 🟡 medium, 🟢 low).
- Access to supporting documentation referenced in each task bullet.

## Steps
1. Review the high-priority items before scheduling new work to ensure blockers are addressed first.
2. Update task status directly in this backlog after completing or re-prioritizing an item.
3. Capture acceptance criteria and related documentation links within each entry.
4. Move completed items into the **Recently Completed** section with the completion date.

### 🔴 High Priority
- Agent System
  - [ ] Add vision integration to mission executor (link: [Vision Integration Design](VISION_INTEGRATION_DESIGN.md)).
  - [ ] Implement remaining unit tests for pause/resume, recovery, telemetry.
  - [ ] Add mission history and replay capability with export tooling.
- Robot Integration
  - [ ] Validate all 47 skills on hardware and log any discrepancies.
  - [ ] Improve error handling in the robot interface (timeouts, degradation strategies).
- Testing & Quality
  - [ ] Add end-to-end mission integration tests (mock and hardware).
  - [ ] Stand up CI for builds, tests, linting, and formatting.

### 🟡 Medium Priority
- Documentation
  - [ ] Produce a video walkthrough covering architecture, mission authoring, and debugging.
  - [ ] Document all 47 skills with parameters, return values, and performance notes.
  - [ ] Refresh README with the latest architecture and troubleshooting guidance.
- Features
  - [ ] Add mission templates and composition utilities.
  - [ ] Implement mission scripting language with conditional execution.
  - [ ] Build telemetry dashboard for real-time and historical metrics.
- DevOps
  - [ ] Optimize Docker build times through multi-stage caching.
  - [ ] Create one-command deployment scripts with health checks.

### 🟢 Low Priority / Nice to Have
- Enhancements
  - [ ] Add voice command support for mission input and robot feedback.
  - [ ] Explore mobile mission control application.
  - [ ] Integrate a simulation environment with Gazebo and synthetic camera feeds.
- Code Quality
  - [ ] Increase automated test coverage above 90%.
  - [ ] Enforce mypy type checking in CI.
  - [ ] Schedule performance profiling to identify hot paths and memory pressure.

### ✅ Recently Completed
- **2025-10-08** — Camera feed QoS fix, laptop UI optimization, collapsible topic list, updated command examples, validated multi-step execution, enhanced logging.
- **2025-10-06** — Agent refactor, MissionExecutor separation, additional unit tests, DIMOS parameter fixes, validation on robot, branch merge.

## Validation
- [ ] Priorities reviewed with stakeholders during the latest planning cycle.
- [ ] Completed items moved to the history section with accurate dates.
- [ ] Links to supporting docs verified and updated when files move.

## References
- [Project Roadmap](project_overview/roadmap.md)
- [Script Catalog](software/scripts.md)
- [Environment Configuration Guide](software/environment_configuration.md)
