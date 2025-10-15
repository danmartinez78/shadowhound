---
tags: [research, personality, agent, architecture]
status: draft
related: [project_overview/mvp_embodied_ai_platform.md, research/persistent_intelligence_day_one_system_context.md, research/lora_adapters_persistent_intelligence.md]
summary: >
  Exploring how to model agent personality, whether and how it evolves, and how to couple/decouple it from mission execution—balancing reliable robotics with embodied intelligence research.
---

# Personality and Mission Execution

## Purpose
Frame personality as a first-class, testable subsystem in an embodied intelligence platform, and define how it relates to mission execution without compromising safety.

## Definitions (Working)
- Personality: A stable set of behavioral parameters shaping communication style, curiosity, risk tolerance, and help-seeking.
- Persona: A particular configuration of those parameters (e.g., TARS, Tachikoma), potentially with dialogue tone and ethics presets.
- Evolution: Long-horizon updates to personality parameters or policies from experience or feedback.
- Mode: Operational context: "Ops" (reliability-first) vs "Research" (exploration-first).

## Design Goals
- Safety-first: personality never bypasses safety or timeouts.
- Decoupled but influenceable: mission execution is independent, but consults personality for style, thresholds, and default choices.
- Observable and reversible: changes are logged, attributed, and rollback-able.
- Pluggable evolution: enable research on evolution without entangling core reliability path.

## Architectural Options

### A) Hard Decoupling (Ops Mode Default)
- Mission Execution (skills, planning) is deterministic within safety bounds.
- Personality affects:
  - Communication style (verbosity, tone)
  - Query reformulation style (but not tool schemas)
  - Help-seeking thresholds (ask human earlier/later)
- Evolution: disabled or gated (manual approval only)
- Pros: reliability, testability; Cons: less emergent behavior

### B) Soft Coupling (Research Mode)
- Personality can influence:
  - Exploration vs exploitation balance (curiosity)
  - Retry budgets and how to gather more evidence
  - When to store or promote memories (importance weighting)
- Evolution: allowed under constraints (rate limits, guardrails)
- Pros: supports embodied growth; Cons: more variance in outcomes

### C) Personality-in-the-Loop Planning (Advanced/Future)
- Personality acts as a policy prior for the planner (preferred strategies)
- Requires: strong safety envelope + evaluation harness
- Pros: rich behaviors; Cons: higher risk/complexity

## Where Personality Lives
- PersonalityConfig: structured parameters loaded at startup (YAML or .env)
- PersonalityEngine: resolves parameters into guidance for:
  - Prompt templates (tone, style)
  - Query strategies (e.g., cautious vs bold prompting)
  - Agent knobs (e.g., rag_threshold adjustments within safe ranges)
- PersonalityStore (optional): records proposed changes from feedback/evolution experiments

## Evolution Mechanisms (Research)
- Human feedback: thumbs-up/down, slider for tone, “ask me more/less”
- Experience-based: periodic summaries propose deltas (curiosity +0.1)
- LoRA adapters: persona-specific adapters for communication style (local only)
- Auto-summarization: compress conversational history into traits
- Governance: proposal → review → apply; revert log

## Safety & Governance
- Guardrails: hard caps on retries, timeouts, motion limits, RAG thresholds
- Modes:
  - Ops: evolution off, soft-coupling limited, strict schema validation
  - Research: evolution on (rate-limited), personality can adjust soft knobs
- Audit: log all personality reads/writes; include mission_id and rationale

## Avatar Mode: Softened Guards with Checkpointed Evolution

Goal: allow exploration and non-linear evolution in sim while preventing large regressions.

Principles:
- Hard safety invariants remain (even in sim): collision constraints, tool-calling schema validity, timeouts.
- “Softening” allows broader ranges for curiosity, help-seeking, retry budgets, and exploration planning.
- Every change is checkpointed; rollbacks are automatic if regression exceeds budget.

Checkpointing:
- Create a Personality Checkpoint (PC) on each approved evolution step:
  - Snapshot: PersonalityConfig, adapter set (if any), seed/version, change rationale
  - Evidence: offline eval metrics vs baseline, dataset/time window
  - Lineage: parent PC id; supports branches (non-linear evolution)
  - Storage: Data Lake → personality_store/{persona}/{pc_id}/

Regression Budget:
- Define allowed deltas before auto-rollback (example):
  - Success rate: ≥ -3% vs baseline
  - Time-to-complete: ≤ +10%
  - Intervention rate: ≤ +5%
  - Safety violations: 0 tolerated
  - Memory quality: JSON validity ≥ 98%, retrieval success@k ≥ baseline -2%

Rollback / Roll-forward:
- If any metric exceeds budget, revert to last-good PC automatically
- Record revert event and rationale; propose alternative adjustments
- Allow roll-forward to new branch from last-good PC

Non-linear Evolution:
- Support branching and merging of PCs to explore diverse styles
- Keep lineage graph to compare branches; select champion via eval

Cadence & Triggers:
- Time-based: propose changes daily/weekly in avatar mode
- Event-based: after N missions or user feedback threshold
- Human-in-the-loop approval for applying PCs to on-robot Ops mode

Evaluation Protocol:
- Canary: run offline replays on recent mission bundles (shadow evaluation)
- A/B in avatar: traffic-split queries between last-good PC and candidate PC
- Gate: promote only if budgets are respected on hold-out scenarios

Observability:
- Always log: PC id, persona, mode, metrics, user feedback summary
- UI affordance: switch PC, view lineage, one-click rollback

## Data & Telemetry
- Personality snapshot at mission start (immutable for run)
- Evolution proposals (diffs) with provenance
- Outcome metrics per mode: success rate, time-to-complete, intervention rate, user satisfaction

## Is It Sci‑Fi?
Not at all. Treat personality as a configuration+policy layer with strict safety boundaries. You can systematically study how changes affect behavior without compromising the mission safety envelope. Failure is acceptable in Research Mode if controlled and logged—this is precisely how to explore embodied intelligence while keeping the platform usable.

## Beyond Configuration: Personality as Policy

Configuration is the safe starting point—not the ceiling. To explore richer, emergent behavior, treat personality as a learned policy that maps state → behavioral control signals, while the planner remains safety-bounded.

Progression ladder (increasing research depth):

1) Config-Only (baseline)
- Static persona parameters; no learning during runs.

2) Adapter-Conditioned Style
- Small LoRA adapters modulate memory writing and recall style; still rule-based planning.

3) Latent Trait Vector z
- Maintain a low-dimensional personality embedding z (e.g., 8–32 dims) that conditions prompts and retrieval choices.
- Learn z via contextual bandits or Bayesian updates from feedback and outcomes (avatar mode).

4) Personality Policy πθ(s) → z
- Train a policy in sim that outputs z (or directly outputs soft knobs: curiosity, help_thresholds, exploration_budget) given state s (mission context, uncertainty, user model).
- Use constrained RL/safe-RL to honor safety and regression budgets.

5) Multi-Agent Controller (Social ↔ Planner)
- Social/Personality model negotiates intent, explanations, and memory strategies; Planner enforces tool schemas and safety.
- Learn a coordination protocol in sim; deploy with strict contracts on-robot.

6) World-Model & Drives (Future)
- Persona builds an internal predictive model; “drives” (curiosity, sociality) optimize long-horizon objectives under safety constraints.

Key idea: Personality does not directly actuate the robot; it proposes strategies, communication, and memory behavior that are then executed by a safety-bounded planner.

## Research-Mode Interface (Conceptual Contract)

Inputs (observable state s):
- Mission context, uncertainty estimates, past outcomes, user feedback summaries, memory density/coverage, time budget.

Outputs (bounded control signals):
- exploration_budget ∈ [0, Emax]
- help_threshold ∈ [Hmin, Hmax]
- rag_threshold ∈ [Tmin, Tmax]
- memory_promotion_bias ∈ [−B, +B]
- style_token (adapter id or style profile)

Invariants:
- Tool-calling schemas and motion limits remain fixed.
- Safety/timeouts cannot be relaxed by personality.

Learning options:
- Bandits for single-knob tuning; RL for multi-knob policies; supervised updates from user feedback for style.

## Evaluation Signals & Budgets

Signals:
- Task success rate, time-to-complete, intervention rate, coverage of search/exploration, user satisfaction, memory retrieval effectiveness (success@k), JSON validity, groundedness.

Budgets (avatar mode, example):
- Allow small regressions in success/time within defined bands; zero tolerance for safety violations; cap on RAG token overhead; maintain minimum memory quality.

Experiment cadence:
- Weekly candidate policies; canary on recent mission bundles → A/B in avatar → promote/rollback via checkpoints.

## Day-One Stance
- Ops Mode default for physical robot missions (personality fixed during runs)
- Research Mode for avatar-in-sim workflows (evolution allowed with guardrails)
- Same Web UI with a clear mode indicator; different default behaviors

## Experiment Ideas
1) Help-Seeking Thresholds
   - Vary threshold for asking user clarification; measure task outcomes and user satisfaction.
2) Curiosity vs Efficiency
   - Influence exploration budget for unknown rooms; measure coverage and time.
3) Communication Style
   - Persona LoRA (local only) for style; compare comprehension and user trust ratings.
4) Memory Promotion Bias
   - Personality-adjusted importance scores; measure retrieval effectiveness later.

## Open Questions
- Should persona be per-user or per-device?
- How to handle personality conflicts across multiple users?
- What is the right cadence for evolution in Research Mode (per session/day/week)?
