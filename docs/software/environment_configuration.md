---
tags: [software, configuration]
status: draft
related: []
summary: >
  Reference for managing ShadowHound environment variables and `.env` templates across development and production deployments.
---

# Environment Configuration Guide

## Purpose
Document the environment variables and templates that govern ShadowHound behavior so that every deployment is reproducible and auditable.

## Prerequisites
- Repository cloned with access to the `.env.*` templates in the project root.
- Understanding of the launch automation from [[scripts|Script Catalog]].
- Sensitive credentials (OpenAI keys, robot IP addresses) stored securely before editing `.env` files.

## Steps
1. Copy the template that matches your scenario (`.env.development` or `.env.production`) to `.env`.
2. Populate mandatory secrets such as `OPENAI_API_KEY` and the robot IP before running any launch script.
3. Tune optional variables for ROS networking, mission behavior, and observability based on the tables below.
4. Re-run launch or diagnostic scripts and document deviations in the **Validation** checklist.

### Template Overview
| File | Purpose | Usage |
|------|---------|-------|
| `.env.example` | Exhaustive reference for every supported variable. | Use as documentation or to diff template changes. |
| `.env.development` | Opinionated defaults for local development and mock robot testing. | Copy for day-to-day development workflows. |
| `.env.production` | Hardened defaults for hardware deployments. | Copy when preparing a real robot session. |

### Development Profile
```bash
cp .env.development .env
nano .env  # Add OPENAI_API_KEY and adjust preferences
```
Recommended adjustments:
- Keep `MOCK_ROBOT=true` and `OPENAI_MODEL=gpt-4o-mini` for low-cost iteration.
- Ensure `ENABLE_WEB_INTERFACE=true` and `WEB_PORT=8080` for dashboard access.
- Set `ROS_DOMAIN_ID=42` to avoid collisions on shared networks.

### Production Profile
```bash
cp .env.production .env
nano .env  # Populate GO2_IP and sensitive keys
chmod 600 .env
```
Key fields to review:
- `MOCK_ROBOT=false` and `GO2_IP=<robot-ip>` for live hardware.
- `OPENAI_MODEL=gpt-4o` or another approved high-quality model.
- `ENABLE_WEB_INTERFACE=false` if exposing the dashboard is not allowed.

### Variable Categories
- **OpenAI & LLM** — `OPENAI_API_KEY`, `OPENAI_MODEL`, `OPENAI_EMBEDDING_MODEL`, `USE_PLANNING_AGENT`.
- **Robot Connectivity** — `GO2_IP`, `GO2_INTERFACE`, `CONN_TYPE`, `MOCK_ROBOT`.
- **ROS Networking** — `ROS_DOMAIN_ID`, `RMW_IMPLEMENTATION`, `RCUTILS_LOGGING_LEVEL`.
- **Web Interface** — `ENABLE_WEB_INTERFACE`, `WEB_PORT`, `WEB_HOST`.
- **RAG / Memory** — `USE_LOCAL_EMBEDDINGS`, `RAG_QUERY_N`, `RAG_SIMILARITY_THRESHOLD`.
- **Logging & Telemetry** — `LOG_LEVEL`, `DIMOS_DEBUG`, `THREAD_POOL_SIZE`.

### Configuration Recipes
```bash
# Cost-optimized development
OPENAI_MODEL=gpt-3.5-turbo
USE_LOCAL_EMBEDDINGS=true
MOCK_ROBOT=true

# Performance-optimized production
OPENAI_MODEL=gpt-4o
USE_LOCAL_EMBEDDINGS=false
THREAD_POOL_SIZE=8
ENABLE_WEB_INTERFACE=false
```

## Validation
- [ ] `.env` derived from the correct template for the current mission.
- [ ] Mandatory secrets populated and stored securely (no accidental commits).
- [ ] Launch scripts read the updated environment without warnings.

## References
- [[scripts|Script Catalog]]
- [[networking/webrtc_direct_test|WebRTC Direct Test]]
- [[troubleshooting/README|Troubleshooting Hub]]
