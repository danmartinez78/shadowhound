---
tags: [research, design, priorities, isaac-sim, early-phase]
status: draft
related: [persistent_intelligence_architecture_shadowHound.md, mvp_embodied_ai_platform.md]
summary: >
  Early design priorities for building system architecture patterns that will scale seamlessly 
  from Isaac Sim development to multi-brain deployment with Thor and Spark.
---

# Early Design Priorities — ShadowHound Project

_Last updated: 2025-10-14_

This document outlines **early program design decisions** that will ensure smooth integration with the long-term **Persistent Intelligence Architecture**. It focuses on the **Isaac Sim setup on the RTX 4070**, emphasizing design patterns, data contracts, and technical discipline that will scale seamlessly once the AGX Thor and DGX Spark come online.

---

## 1. Design Intent

The early phase is about building the *shape* of the system. Core goals:

- Establish message formats and timing budgets that will remain valid when hardware expands.  
- Prevent data entropy — always know what, where, and why data was produced.  
- Treat latency, determinism, and provenance as first-class citizens.  
- Avoid overfitting to simulation convenience; design for the Wi‑Fi + embedded reality ahead.

---

## 2. Non‑Negotiables to Bake In Now

### 2.1 Interfaces Over Implementations
Freeze **two skinny contracts** immediately:
- **Deliberation RPC:** `{embedding, state} → {subgoal, constraints}` (use gRPC or simple HTTP stub).  
- **Trajectory Log:** `{domain, seq_id, t_monotonic_ns, obs_embedding, state_vector, action, outcome_score}`.

These two interfaces are the backbone of the architecture. Everything else can evolve freely.

### 2.2 Event‑Driven Perception
Encode frames → **embeddings (4–8 KB)** → forward those.  
Do not stream raw video to reasoning layers; save raw frames only for labeling or archival.

### 2.3 Domain Labels Everywhere
Every log, file, and run tagged with:
```
domain: real | sim | synthetic
seed: <int>
```
This ensures you can mix datasets safely later and isolate sim‑specific artifacts.

### 2.4 Latency Budgets as Config
Create `budgets.yaml` early and enforce it:
```yaml
control_hz: 100
deliberation_hz: 2
offload_deadline_ms: 75
embedding_bytes_max: 16384
reply_bytes_max: 2048
```
Sim nodes should warn if they exceed any budget.

### 2.5 Reproducibility by Construction
- One **Dockerfile** for the policy server.  
- Switch between ROS 2 and Isaac topics via ENV vars.  
- Pin Isaac Sim + CUDA + Python dependencies in a lockfile.  
- Seed all randomized sim runs.

### 2.6 Data Durability Mindset
Even in simulation, write logs to **segment + manifest** format.  
You’re rehearsing for Thor’s power‑loss‑safe WAL world.

### 2.7 Adapters, Not Monoliths
- Treat all skill deltas as **LoRA/adapter swaps**.  
- Maintain an `adapters/registry.json` from day one.  
- Avoid retraining entire models.

---

## 3. Early Architecture Choices That Will Age Well

- **Binary message shapes:** use FlatBuffer or Proto for embeddings and states.  
- **Monotonic clocks:** for all internal timing; convert to wall‑clock only for UI.  
- **Global IDs:** `robot_id`, `session_id`, `adapter_id`, `sim_env_id`, `seed`.  
- **Observability:** track simple counters: RPC latency p50/p95, embeddings/sec, tokens/sec.

---

## 4. Early Anti‑Patterns to Avoid

- Streaming 1080p frames into reasoning loops.  
- Encoding ethics/personality into weights instead of prompts/RAG.  
- Assuming perfect physics or sensors in simulation.  
- Building scenes that cannot run headless.  
- Mixed‑generation multi‑GPU training “just because.”

---

## 5. Practical Things to Build Now (on the RTX 4070)

### 5.1 Policy Server Skeleton
- Accept `{embedding, state}` → return `{subgoal, constraints}`.  
- Stub reasoning logic at first; log all requests/responses to a replay segment.

### 5.2 Embedding Node in Isaac Sim
- Camera → encoder → embedding (triggered on salience or at fixed intervals).  
- Store to disk as `*.seg` files and POST to policy server.

### 5.3 Replay/Segment Writer
- Append fixed‑size records; roll segments every N seconds or records.  
- Write a simple JSON **manifest** with checksums and offsets.  
- Same code will run on Thor later.

### 5.4 Budgets & Health Watchdog
- Report drift if p95 latency exceeds configured budgets.  
- Emit a single `health.json` per run with RPC stats and counts.

### 5.5 Adapter Registry + Loader
```json
{
  "navigation": "adapters/nav_v1.lora",
  "pickup": "adapters/pickup_beta.lora"
}
```
Allow easy swap‑in/out via ENV var or command‑line flag.

### 5.6 Promotion Gate (Sim Only for Now)
- Script that tests a new adapter across seeded scenes, scores results, and writes `promotion_report.md`.  
- Automation > memory — never trust human recall.

---

## 6. Useful File Templates

### `budgets.yaml`
```yaml
control_hz: 100
deliberation_hz: 2
offload_deadline_ms: 75
embedding_bytes_max: 16384
reply_bytes_max: 2048
```

### `health.json`
```json
{
  "session_id": "sim-2025-10-14-01",
  "domain": "sim",
  "rpc_ms_p50": 22.1,
  "rpc_ms_p95": 58.7,
  "embeddings_sent": 1423,
  "replies_ok": 1409,
  "replies_timeout": 14
}
```

### Segment Header (binary layout concept)
```
MAGIC: SHSEG
version: 1
domain: sim
robot_id: sim-4070
seed: 12345
record_size: 512
```

---

## 7. Minimal Milestone Ladder

| Milestone | Description | Outcome |
|------------|--------------|----------|
| **M0** | Basic plumbing: policy server, embedding node, segment writer | Core data loop working |
| **M1** | Headless eval & nightly runs | Reproducible results |
| **M2** | Real adapters (LoRA) integrated | Skills modularized |
| **M3** | Wi‑Fi latency rehearsal in sim (inject jitter) | Real‑world timing validated |
| **M4** | Avatar UI stub | User interaction & monitoring |

---

## 8. Why This Matters Later

Early discipline creates lasting stability:

- Message contracts ensure Thor, Spark, and Avatar will all “speak the same language.”  
- Budgets prevent future latency disasters.  
- Domain tags make data fusion trustworthy.  
- Segment + manifest logs guarantee recoverability.  
- Adapters + promotion gates make continuous learning explainable.  

By embedding these patterns now, you’re effectively **teaching your system how to grow** — gracefully, predictably, and with traceable memory.

---

_“Early architecture is destiny.”_  
**— ShadowHound Lab Principles**
