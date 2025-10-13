---
tags: [software, automation]
status: draft
related: []
summary: >
  Catalog of ShadowHound helper scripts for launching, testing, and maintaining the workspace.
---

# Script Catalog

## Purpose
Centralize knowledge about the helper scripts that automate ShadowHound setup, launch, diagnostics, and daily workflows.

## Prerequisites
- Repository cloned with execute permissions retained on the `scripts/` directory.
- [ROS 2 Workstation Setup](../software/ros2_setup.md) completed so ROS 2, colcon, and Python dependencies are available.
- Familiarity with environment configuration from [Environment Configuration Guide](environment_configuration.md).

## Steps
1. Select a launch profile (`./start.sh`, quick-start wrappers, or targeted helpers) that matches your scenario.
2. Run the prerequisite health checks (dependency, network, or configuration) before commanding the robot.
3. Capture observations in [Troubleshooting Hub](../troubleshooting/troubleshooting_hub.md) and update this catalog when scripts change.

### Launch & Orchestration
- **`./start.sh [options]`** — Primary orchestrator that validates prerequisites, configures `.env`, builds the workspace, and starts the ROS and web stack. Key flags:
  - `--dev`, `--prod` — Pre-set development or production profiles.
  - `--mock` — Force mock robot mode.
  - `--no-web`, `--web-port <port>` — Control the web dashboard.
- **`scripts/quick-start-dev.sh` / `scripts/quick-start-prod.sh`** — Opinionated wrappers that call `start.sh` with curated settings for daily development or production deployment.

### Validation & Diagnostics
- **`scripts/check-deps.sh`** — Audits ROS 2, Python, pip packages, and workspace structure without launching.
- **`scripts/test-web-only.sh`** — Runs the web interface in isolation for UI debugging.
- **`scripts/test_commands.sh <skill>`** — Sends sample skills (sit/stand/wave) to validate command routing.
- **`test_topic_visibility.sh`** — Confirms ROS 2 topics are visible in the current domain.

### Development Workflow Helpers
- **`scripts/add-devlog-entry.sh`** — Interactive assistant that inserts formatted entries into [Development Log](../research/devlog.md).
- **`scripts/update_repos.sh`** — Updates the repository and submodules with optional `--auto` or `--fetch-only` flags.
- Deprecated: `scripts/setup_webrtc_test.sh` (bespoke `.env` generation). Use your standard `.env` and see [Environment Configuration Guide](../software/environment_configuration.md).

### Example Workflow
```bash
# 1. Verify dependencies and configuration
./scripts/check-deps.sh

# 2. Launch in development mode with the orchestrator
./start.sh --dev

# 3. Validate command routing (mock or real robot)
./scripts/test_commands.sh stand
```

### Troubleshooting Patterns
- Re-run `scripts/check-deps.sh` after updating containers or OS packages.
- Use `./start.sh --mock` when hardware is unavailable but you need ROS and the web UI.
- If environment variables appear missing, verify your standard `.env` aligns with the [Environment Configuration Guide](../software/environment_configuration.md).

## Validation
- [x] Launch scripts tested in both development and production modes after edits.
- [x] Diagnostics scripts produce actionable output in the current environment.
- [x] This catalog references every script committed under `scripts/`.
- [x] Verified all referenced scripts exist in the repository.

## References
- [Environment Configuration Guide](environment_configuration.md)
- [WebRTC Direct Test](../networking/webrtc_direct_test.md)
- [Troubleshooting Hub](../troubleshooting/troubleshooting_hub.md)
