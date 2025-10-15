---
tags: [research, index]
status: active
related: []
aliases: [Research Index]
summary: >
  Research index tracking experiments, benchmarks, and external findings relevant to ShadowHound.
---

# Research Index

## Purpose
Collect research notes, benchmarking results, and references that inform ShadowHound system design.

## Prerequisites
- Access to experiment logs and datasets.
- Understanding of current research priorities.

## Steps
1. Create sub-pages for each experiment or literature review using the template.
2. Include reproducibility metadata such as dataset version, commit hash, and evaluation metrics.
3. Link promising findings back to roadmap items or implementation tickets.

## Validation
- [ ] Each research note includes reproducibility metadata
- [ ] External papers are cited with accessible links
- [ ] Conversion pipeline preserves equations and figures

## Architecture & Design Research

### Persistent Intelligence (Multi-Brain Learning)

- [Persistent Intelligence Architecture](persistent_intelligence_architecture_shadowHound.md) — Multi-brain architecture (Thor + Spark + Tower) with continuous learning cycles
- [Early Design Priorities](shadowHound_early_design_priorities.md) — Foundational patterns for Isaac Sim and future multi-brain deployment
- [DIMOS Integration Analysis](persistent_intelligence_dimos_integration.md) — Practical implementation mapping of persistent intelligence to DIMOS-Unitree framework

### MVP Navigation & Perception (Oct 2025 Discovery)

- [Local Planning Architecture](local_planning_architecture.md) — VFH + Pure Pursuit local planner architecture (navigation WITHOUT global maps)
- [Hybrid Perception Architecture](hybrid_perception_architecture.md) — YOLO + VLM integration patterns for embodied AI missions
- [MVP Implementation Roadmap](mvp_implementation_roadmap.md) — Revised 1-week MVP timeline leveraging local planning discovery

**Key Insight**: DIMOS local planner enables reactive navigation without SLAM, dramatically accelerating MVP (1 week vs 2-3 weeks). Reactive decisions create richer learning data for future persistent intelligence.

## See Also
- [Development Log](../development/devlog.md) — Research and development notes
- [LLM Documentation](../software/llm/llm_hub.md) — Local LLM research and benchmarks
- [MVP Roadmap](../project_overview/mvp_embodied_ai_platform.md) — Current MVP scope and milestones

## References
- [Documentation Root](../index.md)
- Research assets and datasets (link when available)
- [Software Index](../software/software_hub.md)
- [Simulation Index](../simulation/simulation_hub.md)
