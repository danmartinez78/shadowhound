---
tags: [research, architecture, persistent-intelligence]
status: draft
related: [research/persistent_intelligence_mvp.md, research/lora_adapters_persistent_intelligence.md, software/agent/dimos_agent_architecture.md]
summary: >
  System context and Day-One scenario for Persistent Intelligence: physical robot mission → data offload → avatar-in-sim workflows.
---

# Persistent Intelligence: Day-One System Context

## Purpose
Provide a high-level context diagram and a concrete Day-One scenario showing how memory, data flows, and LoRA adapters fit across physical robot and avatar-in-sim workflows.

## System Context Diagram

Actors and systems:
- User (web UI)
- Mission Agent (DIMOS) on Laptop
- Skills (DIMOS MyUnitreeSkills)
- Robot Interface (ROS2, Go2 SDK)
- Memory Layer (Local/Cloud backends)
- Data Lake (offload and analytics)
- Avatar-in-Sim (Spark workflows)

Textual diagram (abstract):

```
User ── Web UI ──► Mission Agent (DIMOS)
                     │
                     ├─► Skills (DIMOS) ──► Robot Interface (ROS2) ──► Unitree Go2
                     │
                     ├─► Memory Manager ──► Vector Store (Chroma) + Blobs (images)
                     │                         ▲
                     │                         └─ Embeddings (local|cloud)
                     │
                     ├─► Telemetry Logger ──► Data Lake (artifacts, logs, traces)
                     │
                     └─► Model Backend (Cloud|Local vLLM) ──► (optional) LoRA adapters

Shutdown/Offload Path:
Robot ─► Laptop Offload ─► Data Lake ─► Avatar-in-Sim (Spark)
```

## Day-One Scenario: "Check if the oven is on"

Assumptions:
- No prior map; agent uses local planning + perception.
- Web UI available for mission start and feedback.
- Memory backend = local (Sentence-Transformers + Chroma PersistentClient).
- LoRA = not required on day one, but planned for writing/recall later.

### 1) Initialization
- User powers on robot; laptop launches Mission Agent.
- Agent selects backend (local), creates/pins `mission_id`.
- MemoryManager seeds collections: `short_term_{mission_id}`, `long_term`.

### 2) Mission Execution (Physical)
- User enters: "Check if the oven is on".
- Agent plan (conceptual):
  1. Explore kitchen region if unknown (local planner, frontier exploration)
  2. Perception checks for oven/stove, read indicators (lights/knobs/temperature)
  3. If ambiguous, refine pose/viewpoint, capture image, ask clarification if needed
  4. Report back with evidence (image + textual observation)

- Memory Writes (during mission):
  - Observations as compact facts with tags + pose:
    - `"Saw a stove with control knobs at (x=…, y=…)"`
    - `"Indicator light near oven: ON"`
    - `"Captured image: img_001.jpg (cabinet, stove, counter)"`
  - Metadata per record: `{timestamp, mission_id, pose{x,y,yaw}, tags:[room:kitchen, object:stove], confidence}`
  - Images stored in VisualMemory; text embeds kept in Chroma

- RAG Queries (during mission):
  - "Have we seen an oven here before?" → returns prior kitchen context if any
  - Threshold keeps low-similarity memories out of prompt

- User Feedback (in Web UI):
  - Approve/Correct: "This is the oven" / "That was the dishwasher"
  - Feedback is appended as corrective memories (tag: `feedback/correction`) and used to update tags on affected records

- Safety & Telemetry:
  - Timeouts per skill, abort on planner stalls
  - Telemetry streamed to Data Lake (pose trace, decisions, thumbnails)

### 3) Mission Outcome
- Agent conclusion:
  - "The oven appears ON (indicator lit)." with confidence and evidence link
- Memory Promotion Policy:
  - Promote key facts from `short_term_{mission_id}` → `long_term` (e.g., kitchen layout, appliance locations)
  - Keep ambiguous/low-value in short-term for retention purge

### 4) Shutdown & Offload
- Before power down:
  - Persist Chroma (auto) and VisualMemory (thumbnails)
  - Export mission bundle to Data Lake:
    - `mission.json` (summary, decisions, timings)
    - `memories_short_term.jsonl` (text+metadata)
    - `images/` (key frames, thumbnails)
    - `trace.log` (actions, states)
- Robot powers off.

## Avatar-in-Sim (Spark Workflows)

### 5) Avatar Resume
- Avatar loads last mission bundle and long-term memory snapshot.
- Same Web UI front-end, with avatar indicator (optional reduced control set).
- If user idle: run background workflows:
  - Memory consolidation: summarize short-term, deduplicate, merge corrections
  - Data labeling tasks: confirm room labels, tag objects, cluster scenes
  - Synthetic experience: plan-and-rehearse similar tasks in sim; generate new memory-writing examples

### 6) LoRA Entry Points (Later Phases)
- Memory Writing Adapter:
  - Trained on curated observation → normalized JSON
  - Used in avatar background workflows to improve future on-robot writing
- Recall Adapter:
  - Trained on (question + docs) → grounded answers
  - A/B tested in avatar environment before enabling on robot

### 7) Data Governance & Retention
- Collections: `short_term_{mission}`, `long_term`, `labels`, `feedback`
- Purge: short-term after 30 days; long-term capped by importance/size
- Privacy: redact faces/audio in public datasets; store raw only locally

## Data We Store (Day One)
- Text observations (embedded) with metadata: `{mission_id, timestamp, pose, tags, confidence}`
- Key frames / thumbnails linked by `image_id`
- Mission summary + action trace (for replay)
- User feedback records (corrections, confirmations)

## Open Questions
- Kitchen localization without a prior map: how much frontier exploration vs user guidance?
- Room labeling source of truth: human-in-the-loop vs heuristic scene classification
- Offload trigger: on-demand vs automatic at mission end
- Avatar autonomy budget: what background workflows are allowed when idle?
