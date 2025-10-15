---
tags: [research, alignment, review]
status: draft
related: [research/persistent_intelligence_mvp.md, research/persistent_intelligence_day_one_system_context.md, research/personality_and_mission_execution.md, research/ops_vs_avatar_concrete_examples.md, research/lora_adapters_persistent_intelligence.md]
summary: >
  Alignment/misalignment review consolidating prior plans with today’s exploration across memory, avatar workflows, and personality evolution.
---

# Alignment Review: Persistent Intelligence (Oct 15)

## Objective
Identify where today’s refinements align with prior research/plans and where they diverge, so we can converge on a comprehensive, coherent design.

## Sources Compared
- Prior: Persistent Intelligence MVP, earlier research notes (Oct 14), DIMOS agent architecture docs
- New Today: Day-One System Context, Personality & Mission Execution, Ops vs Avatar Examples, LoRA research (architecture focus)

## Headline
- Strong alignment on memory persistence, RAG-first pattern, and offload-to-avatar learning.
- New clarity (minor divergence) on: strict “no on-robot learning” rule, personality overlays vs evolution, and checkpointed avatar evolution.

---

## Alignment (Consistent with Prior Plans)

1) Memory as the backbone
- Text memories with pose/tags, persistent across sessions (Chroma)
- Promotion policy: short_term → long_term
- RAG integration with thresholds and token caps

2) Avatar as the learning venue
- Use real mission bundles + sim for improvement
- Canary replays and A/B before promotion
- Checkpoint and rollback concept was present, now made explicit

3) Local-first capability
- Selectable memory backend (local/cloud/skip)
- No requirement for cloud to function; cloud only optional

4) LoRA priority areas
- Memory-writing schema tightening and recall synthesis as top ROI
- Use adapters only in local serving; prompts for cloud models

---

## New Clarifications (Refinements, Not Contradictions)

1) Modes & Learning Boundaries
- Ops (robot): no personality/policy/adapter learning; only memory writes and RAG
- Avatar (sim): all learning/evolution with regression budgets
- Promotion from avatar via checkpoint (optional single approval)

2) Personality Overlays vs Evolution
- Overlays: immediate, style-only changes during Ops (e.g., “be more serious”), persist for deployment; logged as feedback
- Evolution: avatar converts feedback and outcomes into learned defaults (trait z, adapters, or policy), then checkpoints

3) Checkpointed Non-Linear Evolution
- Personality checkpoints (PCs) with lineage/branches, evidence, and auto-rollback
- Defined regression budgets (success rate, time, interventions, memory quality, zero safety violations)

4) Two-tier persistence and transfer
- On-robot: long_term persists; short_term mission bundles exported
- Avatar: consolidates, deduplicates, labels, and proposes promotions back to Ops

---

## Potential Misalignments or Decisions Needed

1) How big can style overlays be in Ops?
- Prior: unspecified; Today: style-only and bounded knobs
- Decision: enumerate allowed overlay knobs and ranges (tone, verbosity, ask-clarifications phrasing)

2) Sync cadence of long_term between Ops and Avatar
- Prior: implied; Today: explicit offload at shutdown
- Decision: define periodic sync vs at-mission-end vs on-demand

3) Room boundary representation
- Prior: spatial tags; Today: consolidation in avatar
- Decision: choose a canonical representation (rooms as polygons vs centroids + radius) and labeling flow

4) Promotion policy for PCs
- Prior: manual judgment; Today: budgets + optional approval
- Decision: formalize budgets per metric and the promote/rollback protocol

5) Adapter routing in Ops
- Prior: adapters discussed; Today: adapters used in avatar and only promoted after checks
- Decision: whether to allow adapter-based style in Ops (if serving stack supports it) or keep to prompting overlays only

---

## Next Steps (Proposed)
- Add “Modes & Learning Boundaries” sidebar to:
  - Day-One System Context
  - Personality & Mission Execution
  - Ops vs Avatar Examples
- Draft a Persona Overlay Spec: allowed knobs + ranges; lifetime rules
- Define Mission Bundle Schema v0.1 (fields for memories, feedback, traces)
- Decide long_term sync cadence and merge strategy
- Establish regression budget baselines from last week’s missions (or create synthetic benchmarks)

## Closing
We are largely aligned; today’s work tightened boundaries and made promotion/rollback operational. The remaining decisions are about exact knobs, schemas, and sync cadence—mechanical choices we can lock down tonight.
