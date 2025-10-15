---
tags: [research, llm, fine-tuning, lora]
status: draft
related: [software/llm/local_llm_memory_roadmap.md, software/agent/dimos_agent_architecture.md]
summary: >
  How LoRA/adapter fine-tunes fit into ShadowHound's Persistent Intelligence MVP: where they add value, when to apply, training data, evaluation, and deployment.
---

# LoRA/Adapters for Persistent Intelligence

## Purpose
Clarify the role of LoRA/adapter fine-tunes in the Persistent Intelligence MVP and beyond. Define where adapters add the most value, the minimal data needed, how to evaluate impact, and practical deployment paths for local vs cloud LLMs.

## Background: What are LoRA/Adapters?

LoRA (Low-Rank Adaptation) is a parameter-efficient fine-tuning (PEFT) method. Instead of updating all model weights, we insert small low-rank matrices (adapters) into specific layers (e.g., attention projections) and train only those. At inference, the base model + adapter weights are combined to produce adapted behavior with minimal additional memory/compute.

- Core idea: ΔW ≈ A · B where A∈R^{d×r}, B∈R^{r×k}, rank r≪min(d,k)
- We train A and B while keeping original W frozen
- Typical target modules: q_proj, k_proj, v_proj, o_proj, sometimes ffn/down/up

Key terms:
- PEFT: Family of methods like LoRA, Prefix-Tuning, P-Tuning, Adapters
- Rank (r): Adapter capacity. Higher r = more capacity, more VRAM
- Alpha: Scaling factor for the adapter contribution
- Target Modules: Which layers get adapters (attention vs MLP)
- Merged vs Dynamic: Merge adapters into base weights offline vs load adapters dynamically at runtime

Why this matters here: We can steer specific agent behaviors (how memories are written/queried) without retraining the whole model, keeping deployment lightweight on local hardware.

## When to Use LoRA vs Alternatives

Use LoRA when you need the model to:
- Consistently emit strict schemas (JSON) for memory writes
- Reformulate queries and synthesize retrieved context reliably
- Reduce prompt dependence for specialized tasks you repeat often

Prefer Prompting/RAG alone when:
- Behavior is already acceptable with few-shot prompting
- You need maximum flexibility across many tasks without model variants

Prefer Full Finetuning when:
- You control ample compute and need broad behavior changes across many tasks (out of scope for our hardware/time budget)

Prefer Small Tooling Changes when:
- Issues are primarily in retrieval quality (embedding model choice, index hygiene, thresholds) rather than LLM behavior

Rule of thumb for ShadowHound:
- Start with RAG + strong prompting templates
- If memory JSON validity < 98% or retrieval success@k plateaus → add LoRA

## Pros and Cons (quick)

Pros:
- Lightweight to train and serve (few additional MB)
- Task-specific improvements without altering base model
- Reversible and swappable per request (if server supports)

Cons:
- More artifacts to manage (which adapter for which task)
- Runtime support varies (dynamic adapters not always available)
- Risk of overfitting to narrow data if not curated well

## Where LoRA Helps Most
- Memory Writing Adapter: produce compact, schema-consistent memory records from observations (↓ tokens, ↑ retrievability)
- Memory Recall Adapter: reformulate queries and synthesize retrieved memories into grounded answers (↑ hit rate, ↑ factuality)
- Skills/Schema Grounding Adapter: reduce tool-call and JSON schema drift (↓ execution errors)

## When to Apply
- After baseline memory scaffolding (backends, persistence, spatial tags, RAG thresholds) is stable
- Start with Memory Writing, then Recall; defer Skills/Schema if tool-call errors become a bottleneck

## Decision Guide (ShadowHound)

1) Backend/Serving
- Cloud (OpenAI/Anthropic): No custom adapters → use prompts/few-shot
- Local (vLLM/other): Adapters OK → check dynamic LoRA support; else prepare merged variants

2) Pain Point
- Messy memory JSON or long/wordy entries → Memory Writing adapter
- Weak recall (missed context, poor synthesis) → Recall adapter
- Tool-call schema deviations → Skills/Schema adapter (optional)

3) Resources
- GPU VRAM ≥ 12–16 GB recommended for 7B with adapters
- If constrained, choose smaller base (Mistral 7B over 13B+) and keep r small (8–16)

4) Deployment
- Dynamic adapter loading available? Use per-request adapter routing
- Else: serve merged-weight variants per adapter as distinct model IDs

## Data & Curation
- Use internal logs and synthetic scenes
- Memory Writing pairs: (observation+pose+mission_ctx) → normalized JSON memory
- Recall pairs: (question + top-k memory set) → grounded answer with citations
- Quality gates: JSON validity, retrieval success@k, grounded accuracy, token length per memory

### Minimal Data Format
- JSONL rows for supervised finetuning
- Memory Writing example:
  {"input": "Saw a red ball on table at (x=1.2,y=3.5)", "output": {"event":"object_seen","text":"Red ball on table.","pose":{"x":1.2,"y":3.5,"yaw":1.57},"tags":["object:red_ball","room:living_room"],"mission_id":"m-2025-10-15-1","timestamp":1697370000.1}}
- Recall example (with retrieved docs snippet):
  {"input": {"question":"Where did we see the red ball?","docs":["Red ball on table. pose=(1.2,3.5)"]}, "output": "You saw the red ball on the table near x=1.2, y=3.5."}

## Training (Local Models)
- Framework: PEFT (LoRA) with HF Transformers
- Base models: Mistral-7B, Llama 3.x, Qwen 2.x (choose by GPU budget)
- Hyperparams (starting): r=8–16, alpha=16–32, dropout=0.05, lr=1e-4, batch=64 eff., epochs=1–3
- Eval set: held-out missions with gold memories and QA

### Minimal Training Recipe (pseudo)
1) Prepare JSONL train/val
2) Tokenize input/output with chat template or instruct format
3) Freeze base weights, enable LoRA on target modules (attention proj)
4) Train 1–3 epochs with early stopping by eval loss/metrics
5) Save adapter weights (.safetensors) and card metadata

## Deployment Patterns
- vLLM with adapter support (if available): route per-request to adapter ("memory-writing", "recall")
- If not supported: serve merged-weights variants as separate endpoints (model-id-suffix)
- Cloud models: no custom adapters → use prompts/few-shot; adapters apply only to local models

### Inference Routing
- Adapter selection by task:
  - memory-writing: apply writing adapter
  - recall: apply recall adapter
  - none: base model
- If dynamic loading unsupported: call specific model endpoint (e.g., mistral7b-memory-writer)

## Integration Points
- Agent: add adapter selection by task (writing vs recall)
- MemoryManager: enforce schema when adapter absent (validator), log JSON validity
- Config: MEMORY_BACKEND (openai|local|skip), ADAPTER_MODE (none|writing|recall)

## Metrics
- JSON validity rate (%) for written memories
- Retrieval success@k and similarity
- RAG token budget usage and cap compliance
- Answer groundedness (manual rubric or weak-supervision checks)

## Risks & Mitigations
- Adapter serving limitations: use merged models if dynamic LoRA not supported
- Data leakage: isolate mission collections; anonymize where needed
- Overfitting to synthetic: blend real and synthetic, use paraphrasing

## Phased Plan
1) Baseline (no LoRA): implement MemoryManager, backends, persistence, spatial tags, tests
2) Memory Writing Adapter (local): train/eval, deploy; measure JSON validity↑, tokens↓
3) Recall Adapter (local): train/eval; measure success@k↑, groundedness↑
4) Optional: Skills/Schema Adapter; prioritize only if tool-call errors persist

## Try Next
- Define the normalized memory schema and validator
- Collect 200 synthetic memory-writing pairs
- Stand up a small local embedding (bge-small/e5-small) and run baseline metrics
- Prototype adapter training on a 1k-sample subset; compare metrics vs baseline

## System Architecture (High-Level)

### Context in ShadowHound Stack
- Application (launch/config) → Agent (DIMOS) → Skills → Robot
- Persistent Intelligence spans Agent + Memory layer; LoRA enhances Agent behavior
- Memory backends (local/cloud) are pluggable, unaffected by LoRA choice

### Serving Topologies
1) Cloud-first
  - LLM: Cloud
  - Embeddings: Cloud or Local
  - LoRA: Not applicable (use prompting)
  - Pros: simplicity, low ops; Cons: latency, cost, no adapters

2) Local-first with Dynamic Adapters
  - LLM: Local server supports per-request adapter loading
  - Embeddings: Local
  - LoRA: Apply per task (writing vs recall)
  - Pros: flexible, single base model; Cons: requires server support

3) Local-first with Merged Variants
  - LLM: Multiple served variants (base, writer, recall)
  - Embeddings: Local
  - Pros: simple serving; Cons: more endpoints to manage

### Agent Integration (Conceptual)
1) Plan → Observe → Write Memory
  - Agent routes “write” prompts through writing adapter (if enabled)
2) Query → Retrieve → Answer
  - Agent routes “recall” prompts through recall adapter (if enabled)
3) Tool Calling
  - Optional schema-grounding adapter to reduce drift; validators remain primary guardrail

### Data & Observability
- Memory records carry mission_id, timestamp, pose, tags
- Metrics: JSON validity, retrieval success@k, token usage, adapter usage rates
- Traces: request → retrieved docs → final answer (with citations)

### Lifecycle & Safety
- Modes: cloud | local | skip-memory
- Fallbacks: if adapter unavailable, use base model + strict prompting
- Retention: time-based purge + quotas; mission-scoped collections

### Risks (Architectural)
- Adapter sprawl (too many variants) → use dynamic adapters or strict naming/versioning
- Inconsistent behavior across backends → define capability matrix and fallbacks
- Data governance → ensure anonymization where needed, clear retention policy

## FAQ

Q: Do we need LoRA if we have RAG?
A: RAG retrieves facts; LoRA improves how the model writes/reads those facts. They’re complementary. Start with RAG; add LoRA when behavior needs to be consistent and compact.

Q: Will adapters help tool-calling reliability?
A: A schema-grounding adapter can reduce deviations, but start with strict prompts and validators. Use an adapter only if drift remains a top error source.

Q: Which layers to target?
A: Start with attention projections (q_proj, v_proj, o_proj). Add MLP only if gains stall.

Q: How big should rank r be?
A: Start with r=8–16 for 7B models. Increase gradually if underfitting; watch VRAM.

Q: Can we use LoRA with cloud models?
A: Generally no—use prompting for cloud models. LoRA applies to local models you serve.

## Glossary
- PEFT: Parameter-Efficient Fine-Tuning
- LoRA: Low-Rank Adaptation
- Adapter: Trainable module injected into a frozen base model
- Dynamic Adapters: Load/unload adapters at runtime without merging
- RAG: Retrieval-Augmented Generation (memory retrieval → prompt)
