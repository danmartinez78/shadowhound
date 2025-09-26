# AGENTS.md — Copilot & VS Code Agent Playbook
_Last updated: 2025-09-26_

This guide standardizes how to write agents/skills/policies so Copilot Chat and VS Code Agents can scaffold usable code, tests, and docs with minimal back‑and‑forth.

---

## 0) Always load context
- Read `docs/project_context.md` and this file.
- We are Thor‑centric; `dimos-unitree` driver patterns + **first‑class** `go2_ros2_sdk`.
- Agents call **Skills** (typed API); E2E policies may fulfill certain skills.

---

## 1) Repo & Packages
Workspace lives in the **meta‑repo** (`shadowhound`):
```
src/
  dimos-unitree/               # fork, minimal patches
  go2_ros2_sdk/                # active SDK (first-class)
  shadowhound_utils/           # Skill registry, RobotIface, QoS, thumbs
  shadowhound_mission_agent/   # Agent/orchestrator
  shadowhound_media_agent/     # (later) snapshot/clip+caption
  shadowhound_policy_lab/      # (later) E2E experiments → exported as skills
```

---

## 2) Skill Registry Contract
Each skill registers a typed function and a safety contract:
```python
# shadowhound_utils/skills.py (create this file)
@dataclass
class SkillSpec:
    name: str
    inputs: dict
    outputs: dict
    timeout_s: int
    safety: list[str]
    offline_ok: bool

def register_skill(spec: SkillSpec, impl: Callable): ...
def call_skill(name: str, **kwargs): ...  # raises on timeout/violation
```

**Built‑ins to implement first:**
- `navigation.goto(x:float, y:float, yaw:float)`
- `navigation.rotate(yaw:float)`
- `perception.snapshot() -> {uri:str}`
- `report.say(text:str)`

---

## 3) RobotIface (driver abstraction)
Use `shadowhound_utils.robot_iface.RobotIface` (already scaffolded) to publish `/cmd_vel`, read `/odom`, `/imu`, and access camera frames for thumbnails. Extend it rather than binding skills to a specific driver.

---

## 4) Agent ←→ Skill wiring
**Mission Agent** responsibilities:
- Parse instruction (LLM) → **HighLevelPlan** (JSON).
- For each step: select skill, set timeouts, enforce safety gates.
- Emit `/shadowhound/say` updates; publish `/shadowhound/metrics` (latency, errors).

**Plan JSON (example)**
```json
{
  "plan_id":"abc123",
  "steps":[
    {"type":"goto","target":{"x":2.0,"y":-1.0,"yaw":0.0}},
    {"type":"perceive","mode":"photo+describe"},
    {"type":"report","summary":"Orange case is open"}
  ],
  "fallback":{"if_timeout_s":10,"action":"return_to_base"}
}
```

---

## 5) Prompt Library (copy/paste into Copilot Chat)

### A) Create the Skill Registry and basic skills
```
Create shadowhound_utils/skills.py with a SkillSpec dataclass, register_skill, and call_skill.
Implement skills:
- navigation.goto -> publish Twist/pose using RobotIface
- navigation.rotate -> controlled yaw rotation
- perception.snapshot -> capture Image, compress to JPEG (quality=70), return file URI
- report.say -> publish to /shadowhound/say (later TTS)
Include unit tests for timeouts and argument validation.
```

### B) Build the Mission Agent orchestration
```
In shadowhound_mission_agent, add plan_dispatcher.py that:
- Accepts HighLevelPlan JSON on /shadowhound/plan OR builds it from instruction via a stub LLM client
- Iterates steps and calls skills with per-step timeouts
- Publishes metrics: /shadowhound/metrics (latency, success, retries)
Add tests for: step ordering, timeout handling, and fallback branching.
```

### C) Add LLM/VLM backends (cloud + local)
```
Add shadowhound_utils/llm_client.py that supports:
- CLOUD: provider=openai|anthropic via env keys (model param)
- LOCAL: endpoint=http://127.0.0.1:8000 or UDS on Thor
API: plan_from_instruction(text, scene=None) -> HighLevelPlan
Add retry/backoff, token caps, and payload size logging.
```

### D) Policy micro-skill (stub)
```
Create shadowhound_policy_lab/align_policy.py (stub) and expose it as a skill:
- policy.align_to_object(target:str) -> status
- For now, return NOT_IMPLEMENTED; wire telemetry and a fake unit test.
```

### E) Bring-up launch composition
```
Edit launch/shadowhound_bringup.launch.py to Include the dimos-unitree driver launch with profile mapping (webrtc/ethernet).
Start Mission Agent with backend params; expose ROS_DOMAIN_ID and RMW.
```

---

## 6) Acceptance Criteria for PRs
- [ ] `colcon build` succeeds; no missing params in launch.
- [ ] Skills use RobotIface; QoS & timeouts explicit.
- [ ] No large images on ROS topics (thumbnails/URIs via tools instead).
- [ ] Mission Agent logs step latency and errors; metrics topic exists.
- [ ] Tests cover registry error paths and at least one happy‑path plan.

---

## 7) Env & Config
- `ROS_DOMAIN_ID=7`
- `RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`
- `DIMOS_LLM_PROVIDER=openai|anthropic` (if cloud)
- `DIMOS_LLM_ENDPOINT=http://127.0.0.1:8000` (Thor local)
- `SH_JPEG_QUALITY=70`

---

## 8) Troubleshooting
- **No topics in RViz:** domain mismatch or Wi‑Fi multicast blocked → use discovery server or NIC binding.
- **WebRTC lag:** switch to compressed image topic; confirm browser permissions (if applicable).
- **Local LLM timeouts:** prefer UDS on Thor; reduce payload size and token limits.
- **Spin jitter:** clamp cmd rate; ensure RobotIface publishes with steady QoS.
