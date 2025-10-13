---
tags: [project_overview/architecture, design, review]
status: active
r## References
- [[project_overview/project_overview_hub|Documentation Root]]
- [[architecture/architecture_hub|System Architecture]]
- [[software/agent/dimos_agent_architecture|Agent Architecture]]ed: [architecture/README, project_overview/roadmap, software/README]
summary: >
  Key outcomes from the October 3, 2025 architecture review that redefined ShadowHound's layered design and delivery plan.
aliases: [arch-review, design-decisions]
---s: [project, architecture]
status: draft
related: []
summary: >
  Key outcomes from the October 3, 2025 architecture review that redefined ShadowHound’s layered design and delivery plan.
---

# Architecture Review Summary

## Purpose
Capture the decisions and follow-up actions from the October 3, 2025 architecture review so contributors can align implementation work with the agreed design.

## Prerequisites
- Familiarity with the baseline architecture documented in [[project_overview/roadmap|Project Roadmap]].
- Access to the detailed reference in [[architecture/architecture_hub|Architecture Documentation]].
- Awareness of current package status across the repository.

## Steps
1. Review the updated layer model and package responsibilities summarized below.
2. Cross-check active workstreams against the phase plan to ensure sequencing remains realistic.
3. Update individual package backlogs or implementation notes with the review outcomes.
4. Record verification in the **Validation** checklist when packages or processes meet the revised expectations.

### Layered Architecture

![System Architecture](../_assets/system-architecture.png)
*Figure 1: Complete system architecture showing the layered design from Web UI through Mission Agent, DIMOS Skills, ROS2 Bridge, to GO2 hardware.*

- **Application** — Launch files, configuration, and deployment tooling.
- **Agent** — LLM/VLM mission planning and orchestration.
- **Skills** — Validated execution layer with telemetry and safety guards.
- **Robot** — ROS 2 bridge and hardware abstraction.
- **Hardware** — External go2_ros2_sdk and physical platform.

### Package Structure
```
shadowhound_interfaces/   # Custom messages, services, and actions
shadowhound_robot/        # Hardware integration facade
shadowhound_skills/       # Skills registry and implementations
shadowhound_agent/        # Mission planner and LLM integration
shadowhound_bringup/      # Launch files, configs, orchestration
```

### Phase Plan Highlights
- **Phase 0** — Bootstrap the packages and achieve clean builds.
- **Phase 1** — Implement the skills registry and foundational skills with unit tests.
- **Phase 2** — Integrate hardware via go2_ros2_sdk and validate on the robot.
- **Phase 3** — Deliver natural-language mission execution through DIMOS.
- Later phases extend into advanced navigation, perception, and onboard deployment.

### Safety & Interface Guidelines
- Skills own all robot control; agents never publish directly to ROS topics.
- Every skill implements timeouts, validation, and structured results.
- ROS networking defaults (domains, RMW) must be configured explicitly via environment settings.

## Validation
- [ ] Repository package layout matches the five-package structure above.
- [ ] Skills registry enforces validation and telemetry per the review.
- [ ] Phase checklists updated to reflect current progress after this review.

## See Also
- [[project_overview/project_overview_hub|Project Overview Hub]] - Planning and status tracking
- [[architecture/architecture_hub|Architecture Hub]] - Detailed system design
- [[project_overview/roadmap|Project Roadmap]] - Implementation phases
- [[software/software_hub|Software Hub]] - Package development
- [[development/development_hub|Development Hub]] - Contributor workflows

## References
- [[project_overview/project_overview_hub|Documentation Root]]
- [[architecture/architecture_hub|Architecture Documentation]]
- [[software/agent/dimos_agent_architecture|Agent Architecture]]
