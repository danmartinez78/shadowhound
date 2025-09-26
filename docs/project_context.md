# ShadowHound Project Context
_Last updated: 2025-09-26_

This document captures the **current source of truth** for the ShadowHound robot dog project. It reflects our latest decisions:

- Base on **dimos-unitree** patterns but depend **directly** on the active **go2_ros2_sdk** (flattened in the meta‑repo).
- Primary compute is **Jetson AGX Thor onboard**; laptop-first via **WebRTC** for early development.
- High‑level reasoning via **LLM/VLM/VLA** agents, executed through a **typed Skill API**, with classic ROS 2 nodes doing real‑time control.
- We also explore **end‑to‑end micro‑policies** for reactive skills behind the same Skill API.
- We deploy primarily via **containers** (compose profiles for laptop and Thor).

---

## 1) Goals & Scope
- **Environments:** home, lab, office (indoors first).
- **First priority:** natural human interaction (voice/text) and reliable navigation/inspection.
- **Shareable progress:** consistent capture of screenshots/clips/captions.
- **Learning:** safe online improvement for non‑safety‑critical micro‑skills with promotion gates.
- **Foundation models:** cloud and local; adapters/prompts tuned to our domain.

---

## 2) Architecture (three layers, swappable via Skill API)
```
┌────────────────────────────────────────────────────────────────┐
│  Layer C — Policy (optional E2E models)                        │
│    • Micro‑skills: align, approach, visual servo               │
│    • Emits short action bursts or sub‑goals (guard‑railed)     │
├────────────────────────────────────────────────────────────────┤
│  Layer B — Task/Plan Agent (LLM/VLM/VLA)                       │
│    • Interprets intent, plans steps, dialog, memory            │
│    • Calls Skills/Tools (typed API), not raw topics            │
├────────────────────────────────────────────────────────────────┤
│  Layer A — Skills (classic ROS 2)                              │
│    • Deterministic nodes: nav, capture, TTS, safety, media     │
│    • Owns /cmd_vel, /odom, /imu, camera, watchdogs             │
└────────────────────────────────────────────────────────────────┘
```
**Skill API seam:** Agents and policies call *skills* like `navigation.goto`, `perception.snapshot`, `report.say`. The **implementation** can be classic ROS code or a learned policy without changing the caller.

---

## 3) Repositories & Workspace
We use a **meta‑repo** (e.g., `shadowhound/`) that owns the ROS 2 workspace via `vcstool`.
- `dimos-unitree` — your fork; minimal patches; used for bring‑up patterns
- `go2_ros2_sdk` — **first‑class** dependency (pinned)
- `shadowhound_utils` — **Skill API/registry**, `RobotIface`, QoS, image utils
- `shadowhound_mission_agent` — **agent/orchestrator** (plans → skills, dialog)
- (later) `shadowhound_media_agent`, `shadowhound_voice_agent`, `shadowhound_policy_lab`

`shadowhound.repos` pins all sources. We **removed** any nested submodule to `go2_ros2_sdk` inside `dimos-unitree` to avoid drift.

---

## 4) Networking & Bring‑up Modes
- **Laptop‑first (WebRTC):** agent on laptop; GO2 via WebRTC; cloud models.
- **On‑Thor (Ethernet):** agent + local models; laptop only RViz/SSH.
- **ROS:** `ROS_DOMAIN_ID=7`; RMW = CycloneDDS (consistent across machines); use discovery server or NIC pinning if multicast is flaky.

---

## 5) Contracts & Data Discipline
- **ROS topics** for control/state only: `/cmd_vel`, `/odom`, `/imu/data`, `/joint_states`, camera topics (compressed as needed).
- **Model calls** (LLM/VLM/VLA) via HTTP/gRPC/UDS; send **thumbnails/scene graphs** (≤ 200–500 KB), not raw frames.
- **Plan JSON** with typed steps, per‑step timeouts, retries, and fallbacks.

---

## 6) Decision Rules
- **Safety / real‑time:** Skills (classic) default.
- **Intent & planning:** Agent (LLM).
- **Reactive micro‑skills:** E2E policy *if available*, else classic.
- **Ambiguity:** query VLM/VLA or ask human.

**Safety envelope:** speed clamps; soft bounds; battery thresholds; watchdog on comms; “two‑key” for risky actions.

---

## 7) Evaluation & Telemetry
- **Latency & jitter:** per‑step and mission totals; `/cmd_vel` stability.
- **Success rate & human‑assists** per mission.
- **Safety:** watchdog trips, overspeed, no‑go violations.
- **Cost/Energy:** tokens (cloud), GPU power/temp.
- **Logging:** store instruction, plan, skill traces, thumbnails, outcomes; publish `/shadowhound/metrics`.

---

## 8) Containerization (current state)
- `docker/Dockerfile.dev` (x86_64 dev) and `docker/Dockerfile.thor` (Jetson).
- `docker-compose.yml` with profiles: **laptop** and **thor**; `network_mode: host`.
- `.env.example` for ROS + model backends.
- Build brings in sources via `shadowhound.repos`, installs deps, and launches **shadowhound_bringup**.

---

## 9) Initial Skills (MVP)
- `navigation.goto(x,y,yaw)` and `navigation.rotate(yaw)`
- `perception.snapshot() -> uri` (JPEG quality=70)
- `report.say(text)`
- (optional) `media.clip(seconds) -> uri`
- (stub) `policy.align_to_object(target)`

Each skill must declare **inputs/outputs**, **timeouts**, **safety contract**, and **offline_ok**.

---

## 10) Phases & Exit Criteria
- **Phase 0 (Bring‑up):** topics visible; demo agent executes `report.say` + `rotate` dry‑run.
- **Phase 1 (Agent+Skills, cloud):** “Go to bench, look for orange case, say if open.”
- **Phase 2 (Local models on Thor):** repeat Phase 1 fully offline.
- **Phase 3 (E2E micro‑skills):** add `align_to_object` policy; show latency/success gains.

---

## 11) Runbook
```bash
vcs import src < shadowhound.repos
rosdep install --from-paths src -iry
colcon build --symlink-install
source install/setup.bash

# Laptop-first (WebRTC + cloud)
ros2 launch shadowhound_bringup shadowhound_bringup.launch.py profile:=laptop_webrtc backend:=cloud

# On-Thor (Ethernet + local)
ros2 launch shadowhound_bringup shadowhound_bringup.launch.py profile:=thor_ethernet backend:=local llm_endpoint:=http://127.0.0.1:8000
```
