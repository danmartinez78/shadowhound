---
tags: [research, examples, ops-vs-avatar, memory, personality]
status: draft
related: [research/persistent_intelligence_day_one_system_context.md, research/personality_and_mission_execution.md, research/lora_adapters_persistent_intelligence.md]
summary: >
  Concrete examples clarifying what persists on-robot, what transfers to avatar, and how personality evolves safely.
---

# Ops vs Avatar: Concrete Examples

## Purpose
Make the Ops (physical robot) vs Avatar (sim) boundaries tangible with two scenarios: kitchen discovery → fridge task, and "be more serious" style change.

## Scenario A: Kitchen Discovery → Later Fridge Task

### A1) Oven Mission (No Prior Map) — Ops
- Robot explores, detects kitchen region, finds stove.
- Memory writes (short_term):
  - text: "Detected kitchen region near (x=2.1,y=3.5). Found stove."
  - metadata: {mission_id, timestamp, pose, tags:[room:kitchen, object:stove], confidence}
- Policy promotes key facts to long_term at mission end (kitchen location).
- Persistence: Chroma PersistentClient stores embeddings; VisualMemory stores key frames.

### A2) Fridge Task (Same Deployment) — Ops
- Query: "Check if the fridge is open."
- RAG returns the kitchen fact from long_term.
- Planner navigates directly (or with reduced exploration) to kitchen; performs fridge check.
- No learning alters behavior; only memory retrieval informs planning.

### A3) Offload to Avatar — Transfer
- Export mission bundle + memory deltas (or snapshot) to Data Lake.
- Avatar loads long_term and short_term for consolidation.
- Background workflows:
  - Deduplicate/retag (e.g., strengthen kitchen boundary)
  - Summarize and promote useful spatial facts
  - Generate synthetic variants for future recall tests

### A4) Learning and Checkpointing — Avatar
- Avatar can train/evaluate recall adapters or update trait vector z/policy πθ(s) within bounds.
- Canary replays on real bundles → A/B in avatar.
- If budgets OK, checkpoint PC-n and set as last-good for Ops. No manual parameter tweaks.

## Scenario B: "Be More Serious" During Ops

### B1) User Instruction — Ops
- User: "Be more serious."
- Immediate effect: apply style overlay for current run
  - tone=serious, verbosity=low
  - Affects conversation/explanations; does not affect tool schemas/safety
- Log preference as persona_feedback with timestamp/user_id.

### B2) Persistence — Ops
- Overlay persists for the deployment (until shutdown or changed by user).
- Stored in the mission bundle; does not rewrite base personality.

### B3) Influence on Evolution — Avatar
- Avatar uses persona_feedback as supervised signal for style.
- Optionally trains/weights a style adapter for "serious" tone.
- Tests via canary + A/B; if good, creates PC-(n+1) with serious-as-default style.
- Promotion sets serious style as default in future Ops until changed.

## Boundaries Recap
- Ops (Robot):
  - Writes memories, reads via RAG, applies style overlays
  - No learning of personality/policy/adapters; safety invariants fixed
- Avatar (Sim):
  - All learning/evolution (trait z, πθ, adapters) using real + sim data
  - Regression budgets, checkpoint/rollback, promotion to Ops

## Artifacts
- On-robot persistence: Chroma DB (long_term + per-mission short_term), VisualMemory, mission bundles
- Offload payload: mission.json, memories_short_term.jsonl, long_term snapshot/deltas, images/, trace.log, persona_feedback.jsonl
- Checkpoints: personality_store/{persona}/{pc_id}/ (config/traits/adapters + evidence)

## Open Questions for Design Review
- Best policy for when to promote short_term → long_term?
- How to encode room boundaries consistently across sessions?
- How big should style overlays be (what knobs allowed)?
- Sync cadence of long_term between Ops and Avatar?
