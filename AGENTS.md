# AGENTS.md — Copilot & VS Code Agent Guide
_Last updated: 2025-09-26_

This file guides AI coding agents to generate **production‑ready** patches that fit our architecture.

## Context to load
- Read `project_context.md` (architecture, contracts).
- We use a **Skill API** seam; skills are typed functions with timeouts and safety guards.
- Classic ROS 2 for control; LLM agent for planning; E2E policies may back select skills.

## Packages (current)
```
shadowhound_utils/           # Skill API/registry, RobotIface, QoS, image tools
shadowhound_mission_agent/   # Agent/orchestrator (plans → skills, dialog)
dimos-unitree/               # fork; bring-up patterns
go2_ros2_sdk/                # active driver (first-class)
```

## Immediate tasks for Copilot
1) **Create Skill Registry**
```
File: shadowhound_utils/skills.py
- Define SkillSpec (name, inputs, outputs, timeout_s, safety[], offline_ok)
- Provide register_skill(spec, impl) and call_skill(name, **kwargs) with timeouts
- Implement skills:
  * navigation.rotate(yaw: float)
  * report.say(text: str)
  * perception.snapshot() -> {"uri": str}
- Add unit tests for arg validation and timeout behavior
```

2) **Implement navigation.goto**
```
Use RobotIface to publish Twist or pose goals until tolerance met.
Expose params: max_speed, yaw_tolerance, position_tolerance, timeout_s.
Respect safety clamps; publish progress to /shadowhound/metrics.
```

3) **Mission Agent plan dispatcher**
```
File: shadowhound_mission_agent/plan_dispatcher.py
- Input: HighLevelPlan JSON (or build from instruction via llm_client.py)
- Iterate steps, call skills with per-step timeout, handle fallback
- Publish /shadowhound/metrics (latency, retries, failures)
- Tests: happy path, timeout path, fallback path
```

4) **LLM/VLM backend plumbing**
```
File: shadowhound_utils/llm_client.py
- CLOUD: provider=openai|anthropic (keys via env), model param
- LOCAL: endpoint=http://127.0.0.1:8000 (Thor), optional UDS
- API: plan_from_instruction(text, scene=None) -> HighLevelPlan
- Add retry/backoff and payload size logging
```

5) **Policy micro-skill stub**
```
Create shadowhound_policy_lab/align_policy.py (stub) and register:
- policy.align_to_object(target: str) -> status
- Return NOT_IMPLEMENTED for now; wire telemetry
```

## Acceptance checklist (PRs)
- [ ] Builds on laptop & Thor (`colcon build` and compose profiles).
- [ ] Documentation is created or updated whenever relevant, not only when behavior changes.
- [ ] Skills call RobotIface (no direct driver coupling), with explicit QoS/timeouts.
- [ ] No large ROS payloads (thumbnails/URIs only).
- [ ] Mission Agent logs step latency; exports /shadowhound/metrics.
- [ ] Tests cover registry error paths and at least one full plan.

## Env & Config
- `ROS_DOMAIN_ID=7`
- `RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`
- `DIMOS_LLM_PROVIDER=openai|anthropic`
- `DIMOS_LLM_ENDPOINT=http://127.0.0.1:8000`
- `SH_JPEG_QUALITY=70`

## Troubleshooting
- **No topics:** domain mismatch or blocked multicast → discovery server or NIC pinning.
- **WebRTC lag:** use compressed images; verify permissions.
- **Local LLM timeouts:** prefer UDS on Thor; reduce payload sizes/tokens.
- **Spin jitter:** steady publish rate; clamp speeds in skills.
