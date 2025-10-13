---
tags: [software, operations]
status: draft
related: []
summary: >
  Reference for the `start.sh` launcher and companion helpers that orchestrate ShadowHound deployments.
---

# Start Script Reference

## Purpose
Explain how the `start.sh` orchestration script and its helpers prepare, validate, and launch the ShadowHound stack for development and production.

## Prerequisites
- Environment configured per [[environment_configuration|Environment Configuration Guide]].
- Familiarity with the broader script ecosystem in [[scripts|Script Catalog]].
- Ability to run commands within the development container or a compatible ROS 2 workstation.

## Steps
1. Pick the appropriate launch mode (`--dev`, `--prod`, or interactive) for the current mission.
2. Review the summary printed by `start.sh` to confirm configuration, network connectivity, and ROS topics.
3. Use the quick-start helpers for recurring workflows or targeted flags for troubleshooting as documented below.

### Launch Options
```bash
./start.sh --dev        # Development defaults (mock robot, cost-optimized)
./start.sh --prod       # Production defaults (real robot, hardened settings)
./start.sh              # Interactive mode with guided prompts
./start.sh --mock       # Force mock robot even in production template
./start.sh --no-web     # Disable dashboard
./start.sh --web-port 9000
```

### Responsibilities
1. **System Checks** — Verifies ROS 2, Python, colcon, and workspace layout.
2. **Configuration** — Creates `.env` from templates, validates secrets, and summarizes active settings.
3. **Build & Install** — Runs colcon builds when needed and installs missing Python packages.
4. **Network Validation** — Pings the robot IP and surfaces connectivity warnings.
5. **Launch & Monitoring** — Starts ROS nodes, serves the web dashboard, and handles graceful shutdown.

### Companion Helpers
- `scripts/quick-start-dev.sh` — One-command development launch with verbose logging.
- `scripts/quick-start-prod.sh` — Production-safe defaults for field deployments.
- `scripts/check-deps.sh` — Use before launching to confirm prerequisites.
- `scripts/test-web-only.sh` — Validate the dashboard without ROS overhead.

### Troubleshooting Checklist
- Re-run with `--mock` if hardware connectivity blocks the workflow.
- Change ports using `--web-port` when the default 8080 is occupied.
- If environment variables seem missing or inconsistent, review your standard `.env` against the [[environment_configuration|Environment Configuration Guide]].

## Validation
- [x] `start.sh` completes without errors for both development and production presets.
- [x] Quick-start helpers (`quick-start-dev.sh`, `quick-start-prod.sh`) reflect the latest supported flags.
- [x] Troubleshooting tips validated against recent incidents and updated as needed.
- [x] Verified all referenced scripts exist in the repository.

## References
- [[scripts|Script Catalog]]
- [[environment_configuration|Environment Configuration Guide]]
- [[networking/webrtc_direct_test|WebRTC Direct Test]]
