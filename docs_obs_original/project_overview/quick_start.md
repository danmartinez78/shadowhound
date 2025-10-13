---
tags: [project_overview/operations, onboarding, launch]
status: active
related: []
summary: >
  Rapid launch checklist for bringing up ShadowHound via the automated `start.sh` workflow.
aliases: [launch, getting-started]
---

# Quick Start Launch Checklist

## Purpose
Provide a condensed set of commands and expectations for operators who need to bring ShadowHound online quickly using the orchestrated start scripts.

## Prerequisites
- Repository cloned and opened inside the development container environment.
- Environment configured according to [[software/environment_configuration|Environment Configuration Guide]].
- Familiarity with the helper scripts documented in [[software/scripts|Script Catalog]].

## Steps
1. Run the dependency check to confirm the workstation is ready.
2. Launch the orchestrator in the mode that matches your mission (development or production).
3. Follow the on-screen prompts and confirm the validation checklist before commanding the robot.

### One-Command Launch
```bash
./start.sh --dev    # Development mode (mock robot by default)
./start.sh --prod   # Production mode (real robot)
./start.sh          # Interactive prompts for new operators
```

### What the Orchestrator Does
1. Runs environment and dependency diagnostics.
2. Creates or updates `.env` based on selected mode.
3. Builds the workspace if required.
4. Validates network connectivity to the robot.
5. Launches ROS nodes and the web dashboard.

### Common Usage Patterns
- **Daily development:** `./scripts/quick-start-dev.sh`
- **Production field run:** `./scripts/quick-start-prod.sh`
- **Web UI smoke test:** `./scripts/test-web-only.sh`
- **Pre-flight verification:** `./scripts/check-deps.sh`

## Validation
- [x] Launch completed without errors using the chosen mode.
- [x] Web dashboard accessible (or intentionally disabled) and responsive.
- [x] Mission commands accepted (mock confirmations or hardware motion observed).
- [x] Scripts verified to exist and match documented usage patterns.

## See Also
- [[project_overview/project_overview_hub|Project Overview Hub]] - Planning and operations
- [[project_overview/quick_reference|Quick Reference]] - Command cheat sheet
- [[troubleshooting/startup_validation|Startup Validation]] - Health checks
- [[troubleshooting/quick_start_robot_test|Robot Testing]] - Hardware validation
- [[software/configuration/environment_variables|Environment Variables]] - Configuration reference

## References
- [[project_overview/project_overview_hub|Documentation Root]]
- [[software/software_hub|Software Hub]]
- [[development/development_hub|Development Hub]]
```
