---
tags: [research, architecture, persistent-intelligence, multi-brain, learning-loop]
status: draft
related: [shadowHound_early_design_priorities.md, mvp_embodied_ai_platform.md]
summary: >
  Persistent Intelligence Architecture integrating Thor (mobile brainstem), Spark (cortex), 
  and Tower (avatar) for continuous learning with day/night cycles and power-loss-safe data durability.
---

# Persistent Intelligence Architecture — ShadowHound Project
_Last updated: 2025-10-14_

This document defines the **Persistent Intelligence Architecture** for the ShadowHound robot ecosystem.
It integrates physical and simulated embodiments, **distributed co-brains (Thor + Spark)**, and a nightly self-improvement workflow.
The goal: **a continuously learning, characterful robot** — a practical Tachikoma — with robust data durability even under abrupt power loss.

---

## 0. Terminology (Reframed Roles)
- **Body** = **Unitree Go2 Pro** (actuators, sensors, proprioception)
- **Brains** = **AGX Thor (mobile brainstem)** + **DGX Spark (cortex)**
- **Avatar** = **Tower (RTX 4070) / Isaac Sim** (virtual embodiments + UI)
- **Memory** = Vector/RAG stores + adapter checkpoints + replay buffers

Thor and Spark are **co-brains**. Thor executes latency-critical loops on the robot; Spark expands reasoning/memory and performs nightly adaptation.

---

## 1. System Overview

| Role | Hardware | Purpose | Key Traits |
|------|----------|---------|-----------|
| **Body** | Go2 Pro | Real-world embodiment | Low-level control, sensors |
| **Mobile Brainstem** | **AGX Thor** (on Go2) | Real-time autonomy + local reasoning | 128 GB unified memory; deterministic, field-rated |
| **Cortex** | **DGX Spark (GB10)** | Large-context reasoning; trainer/curator; nightly fine-tunes | ~PFLOP-class FP8, 128 GB unified mem, CUDA-X stack |
| **Avatar** | Tower (RTX 4070) | Sim embodiment & user UI (single/multi-agent) | Isaac Sim/Lab scenes |

Together they form a **closed learning loop**: Thor acts → Spark learns → Avatar tests → **adapters** return to Thor.

---

## 2. Networking Reality & Budgets

**Operational link (robot moving):** Thor ⇄ Spark over **Wi‑Fi** (6/6E preferred)
- Throughput (real-world): 200–300 Mbps typical
- RTT: 2–5 ms median; 10–20 ms jitter possible
- **Design budget**: 30–40 ms round-trip including serialization

**Maintenance link (robot docked/charging):** Thor ⇄ Spark over **Ethernet (recommended)**
- Use for **bulk sync** (GB‑scale logs, checkpoints, dataset exports) and software updates.
- If Ethernet tether-on-dock is infeasible, schedule **Wi‑Fi nightly sync windows** and throttle transfers.

**Offload payload guidance (Wi‑Fi):**
- Send **embeddings + sparse state** (≤ 10–16 KB/request), not raw frames.
- Keep deliberation RPCs ≤ 1–5 Hz with **hard timeouts** (e.g., 50 ms).

---

## 3. Core Loop: Day / Night Cycle

### Day — Real Operation (Thor‑Primary, Wi‑Fi available)
1. **Reflex Layer** (50–200 Hz): state estimation, locomotion, collision checks (Thor).
2. **Reasoning Layer** (1–5 Hz): local VLM/VLA on Thor; offload heavy steps to Spark only if within latency budget.
3. **Logging:** Thor writes **durable local replay** segments (see §7) and streams summaries to Spark opportunistically.

### Night / Dock — Reflection & Growth (Spark‑Primary, Ethernet preferred)
1. **Curation:** Spark clusters trajectories; selects failures/novelties.
2. **Adaptation:** LoRA/adapter fine‑tunes or RL on Isaac Lab/GR00T.
3. **Evaluation:** headless sim regression; safety & latency tests.
4. **Distillation:** export adapters (TensorRT‑LLM/NeMo); sign artifacts.
5. **Deployment:** push approved adapters to Thor; keep rollback slots.

---

## 4. Architecture Topology

```text
[Go2 Body] ⇄ [AGX Thor (mobile brainstem)]  ~~Wi‑Fi~~  ⇄  [DGX Spark (cortex)]  —  [Tower/Isaac Sim]
    |                  |                                             |                 |
    |  sensors/actuators,                               trainer/curator,       multi/single-agent
    |  safety envelopes                                 memory services        simulation + UI
```

**Decision hierarchy**
- Thor is always **authoritative** for safety‑critical control.
- Spark proposes **subgoals/BT ticks**; Thor fuses and executes or ignores on timeout.

---

## 5. Persistent Personality Model

**Memory layers**
- **Episodic:** daily interaction/trajectory logs (short‑term; tagged by domain `real|sim|synthetic`)
- **Semantic:** structured world knowledge in vector DB (RAG)
- **Skill:** LoRA/adapter weights

**Stability policy**
- Persona/ethics live in prompts + RAG; **do not** fine‑tune identity.
- Fine‑tuning targets **skills**; promotion requires regression pass.

---

## 6. Replay Buffer & Message Schemas

**Trajectory (conceptual; serialize via protobuf/flatbuffer):**
```protobuf
message Trajectory {
  string domain = "real" | "sim" | "synthetic";
  bytes  obs_embedding;   // compact vision/audio embedding
  bytes  state_vector;    // pose, goal, objects (struct)
  bytes  action;          // subgoal/BT tick or action token
  float  outcome_score;   // task rewardish metric
  string task_id;
  int64  t_monotonic_ns;  // monotonic timestamp
  string robot_id;
  uint64 seq_id;          // strictly increasing per device
}
```
**Deliberation RPC (Thor ⇄ Spark, gRPC):**
```protobuf
message DelibRequest { bytes obs_embedding; bytes state_vector; uint64 seq_id; int64 deadline_ms; }
message DelibReply   { bytes subgoal; bytes constraints; uint64 seq_id; bool valid; }
```

---

## 7. Data Durability on Thor (Power‑Loss Safe)

Because Wi‑Fi can drop and the robot may **brown‑out abruptly**, Thor must **bookmark** and persist critical data locally.

### 7.1 Write‑Ahead Logging (WAL) Pattern
- **Double‑buffered segment files** in `/data/replay/segments/`:
  - `seg_<epoch>_<counter>.wal` (append‑only, binary protobuf/flatbuffer)
  - Every N records (e.g., 32) write a small **index block** (offsets + last `seq_id`).
- Use **atomic rotates**: write to `*.wal.tmp` → `fsync()` → rename to `*.wal`.
- Maintain a **manifest** `MANIFEST.json` with:
  - last committed segment, SHA‑256, record counts, and watermarks (`seq_id`, `t_monotonic_ns`).
  - Update manifest via **atomic rename** after `fsync()`.
- On boot, **replay** by scanning manifest then verifying segment hashes; recover partial tails safely.

### 7.2 Filesystem & Mount Options
- Use **ext4** with journaling enabled; mount with `barrier=1`, `data=ordered` (default on Ubuntu).
- Set `commit=5` (or tighter) to bound journal flush intervals.
- Avoid write‑caching on removable media; prefer eMMC/NVMe on Thor.

### 7.3 Storage Format Recommendations
- **SQLite (WAL mode)** for metadata/catalog tables.
- **Parquet** for batched tensors/embeddings when compacting segments (offline), not for live WAL.
- Keep **small fixed‑size records** for live logging; batch to Parquet during docked maintenance.

### 7.4 Checkpointing & Bookmarks
- Emit lightweight **checkpoints** every M seconds (e.g., 10 s) containing:
  - last `seq_id`, current adapter IDs, map revision, battery state, Wi‑Fi quality.
- Store to `/data/checkpoints/current.ckpt` via atomic rename; keep a **rolling N=5** history.

### 7.5 Prioritized Flush
- Priority **A** (must‑keep): safety incidents, task failures, operator annotations → `fsync()` immediately.
- Priority **B**: normal trajectories → buffered; flush on segment close or every 5 s.
- Priority **C**: verbose debug → only flushed on idle or dock.

### 7.6 Time & Identity
- Use **monotonic clocks** for ordering (`CLOCK_MONOTONIC_RAW`); store wall‑clock only for UI.
- Sync NTP via **chrony**; keep a working **RTC** to survive power loss.
- Stamp every file with **robot_id** and **adapter_id** for provenance.

### 7.7 Integrity & Recovery
- Include per‑segment **SHA‑256**; verify on sync before deletion.
- Implement a `recovery --dry-run` tool to rebuild manifest and report gaps.

---

## 8. Graceful Shutdown Options (Hardware & OS)

Even with WAL, **graceful shutdown** increases reliability.

**Hardware ideas (choose per constraints):**
- **Holdup power** (supercap/UPS module) sized for ≥ 10–20 s runtime to flush buffers and stop sensors.
- **Power‑loss GPIO** from the Go2 battery/fuel gauge or external monitor; triggers OS hooks immediately.
- **Dock contact / pogo pins** that provide Ethernet & power when parked to enable fast sync.

**OS hooks:**
- `systemd` service with `Before=shutdown.target` and `ExecStop=/usr/local/bin/flush_and_quiesce.sh`.
- Register a **power‑loss signal handler** to:
  1) stop nonessential nodes,
  2) close WAL segments (index + fsync),
  3) write a final **bookmark**,
  4) remount data `ro` if time permits.
- Use `systemd-inhibit` during critical writes to prevent unintended suspends.

---

## 9. Avatar & Multi‑Embodiment (Simulation)

**Avatar (single embodiment):**
- Containerized policy server runs against Isaac topics (not ROS2).
- Provides chat + command UI; tags logs with `domain=sim`.

**Multi‑embodiment (A/B/…):**
- Spark hosts **message bus** (MQTT/gRPC), **vector DB**, **reward aggregator**.
- Each Avatar runs independent scenes with **domain randomization**; roles fixed per episode; rotated across sessions.
- **Promotion gate** ensures sim‑learned adapters pass regression on real logs before deployment.

---

## 10. Data & Compute Flow Summary

| Task | Executor | Notes |
|------|----------|-------|
| Real‑time autonomy | Thor | 50–200 Hz loops, authoritative control |
| Mid‑freq reasoning | Thor → Spark (Wi‑Fi) | 1–5 Hz, ≤ 50–100 ms total target |
| Synthetic data gen | Tower (4070) | Isaac Sim scenes |
| Nightly fine‑tune | Spark | LoRA/adapter updates |
| Regression eval | Spark + Tower | Headless sim tests |
| Adapter deployment | Spark → Thor | Signed artifacts; rollback slots |
| Bulk sync | Thor ⇄ Spark (Ethernet on dock) | Logs, checkpoints, datasets |

---

## 11. Practical Deployment Steps

1) **Network** — Wi‑Fi for ops; Ethernet on dock for sync. Static IPs; TLS gRPC endpoints; QoS for control vs bulk.  
2) **Containers** — `policy_server`, `trainer`, `isaac_sim`, `memory_db`, `replay_compactor`.  
3) **Volumes** — `/data/replay`, `/data/checkpoints`, `/data/adapters`, `/data/memory`.  
4) **Nightly Cron (Spark)** — `curate → train → eval → promote → publish`.  
5) **Promotion Policy** — ≥ 95% regression pass; no safety violations; manual approval switch.  
6) **Recovery drills** — quarterly simulated brown‑outs to validate WAL + bookmarks.

---

## 12. Safety & Ethics Checklist

- No joint‑level control offload.  
- Hard RPC deadlines + last‑good‑plan fallback.  
- Raw sensor data remains on‑prem.  
- Dataset provenance logged for all fine‑tunes.  
- Personality via prompts/RAG; adapters only for skills.  
- Regression suite before deployment.  

---

## 13. Roadmap (Updated)

| Phase | Focus | Outcome |
|------|-------|---------|
| **2.5** | Integrate Spark as cortex over Wi‑Fi | Real‑time offload within wireless budgets |
| **3.0** | Dock‑sync pipeline (Ethernet) + WAL | Durable data + fast nightly fine‑tunes |
| **3.5** | Avatar sim twin | Persistent embodiment & user interaction |
| **4.0** | Multi‑embodiment sim | Collaborative learning & social reasoning |
| **5.0** | Continuous eval loop | Autonomous growth with human oversight |

---

## 14. Guiding Principles

- **Latency governs truth.**  
- **Simulation is a hypothesis generator, not a prophet.**  
- **Personality is curated, not trained.**  
- **Learning must be explainable and reversible.**

---

_“When the body rests, the mind continues to wander.”_  
**— ShadowHound Lab Manifesto**
