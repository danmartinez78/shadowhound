---
tags: [development, experiments, documentation]
status: active
related: [devlog.md, recent_work.md]
summary: >
  Guide for documenting experimental work and research-driven development
---

# Experiment Documentation Guide

## Purpose

This directory contains **detailed documentation of experimental work** that doesn't fit into the lightweight devlog timeline. Use experiment docs for:

- **Large feature branches** with extensive exploration
- **Research-driven development** (testing multiple approaches)
- **Performance investigations** (profiling, optimization experiments)
- **Integration experiments** (testing libraries, frameworks, models)
- **Failed attempts with learnings** (what didn't work and why)

## When to Create an Experiment Doc

### ✅ Create Experiment Doc When:
- Testing multiple approaches to solve a problem (e.g., 4 LLM models)
- Feature branch spans multiple days with significant iteration
- Extensive debugging or investigation required
- Need to document "what we tried" not just "what worked"
- Experimental results inform future decisions
- Work involves research, profiling, or comparative analysis

### ❌ Use Simple Devlog Entry When:
- Straightforward feature implementation (clear path)
- Bug fix with obvious solution
- Documentation updates
- Refactoring with no exploration
- Mechanical tasks (file moves, config updates)

## File Naming Convention

**Pattern**: `{feature_area}_{topic}_{start_date}.md`

**Examples**:
- `local_llm_exploration_oct10_2025.md` - LLM backend research
- `dimos_integration_oct05_2025.md` - DIMOS feature branch work
- `webrtc_skill_debugging_oct12_2025.md` - Investigating WebRTC issues
- `semantic_navigation_mapping_nov01_2025.md` - Future mapping work
- `voice_interface_tts_selection_nov15_2025.md` - TTS research

**Why This Works**:
- Feature area prefix enables filtering by topic
- Date shows when work started (chronological ordering)
- Descriptive middle section explains the experiment
- Unique filename = no merge conflicts

## Experiment Doc Template

```markdown
---
tags: [experiment, {feature_area}, {technology}]
status: in-progress | complete | abandoned
started: YYYY-MM-DD
completed: YYYY-MM-DD (if applicable)
related: [{related_docs}]
summary: >
  One-line description of the experiment
---

# {Experiment Title}

## Context
Why this experiment was needed. What problem are we solving?

## Hypothesis
What we believe will work and why.

## Experiments

### Experiment 1: {Approach Name} (YYYY-MM-DD)
**Commit**: `abc123`

**What We Tried**:
- Specific approach details
- Configuration used
- Test conditions

**Results**:
- What happened
- Performance metrics
- Issues encountered

**Decision**: Continue | Pivot | Abandon

---

### Experiment 2: {Another Approach} (YYYY-MM-DD)
**Commit**: `def456`

[Same structure...]

---

## Final Results

### What Worked
- Successful approach details
- Performance characteristics
- Trade-offs accepted

### What Didn't Work
- Failed approaches
- Why they failed
- Lessons learned

### Key Decisions
- Final technical choices
- Rationale for decisions
- Constraints identified

## Implementation Status

- [ ] Research complete
- [ ] Approach validated
- [ ] Implementation merged
- [ ] Documentation updated

## References
- Links to related docs
- External resources
- Related PRs/issues
```

## Linking Between Devlog and Experiments

### In Devlog (Lightweight Entry)
```markdown
### Evening: Local LLM Integration Complete
**Type**: Feature
**Status**: ✅ Complete
**Experiment Doc**: [experiments/local_llm_exploration_oct10_2025.md](experiments/local_llm_exploration_oct10_2025.md)

Tested 4 LLM models, selected Mistral 7B for 24x speed improvement.

**Key Results**:
- vLLM on Thor: 37 tok/s baseline
- Tool calling validated
- Local embeddings working

**Commits**: `3ac1e01`, `45618b2`
```

### In Experiment Doc (Detailed Narrative)
Full experimental process with all the "what we tried" details.

## Benefits

### For Development Workflow
- **No merge conflicts**: Each experiment = unique file
- **Parallel work friendly**: Multiple feature branches = multiple experiment docs
- **Preserves learning**: Full narrative of exploration
- **Lightweight timeline**: Devlog stays focused on "what happened when"

### For AI Agents
- **Clear context**: Agents can read experiment docs to understand past work
- **Decision history**: Why we chose X over Y is documented
- **Pattern recognition**: Similar problems → review similar experiments
- **Reduces repetition**: Don't re-explore failed approaches

### For Future Developers
- **Research reproducibility**: Can follow the experimental process
- **Understand trade-offs**: Why decisions were made
- **Avoid pitfalls**: Learn from failed attempts
- **Quick reference**: Date-based naming makes finding relevant work easy

## Example Workflow

### Starting New Experimental Work

1. **Create experiment doc**:
   ```bash
   cd docs/development/experiments/
   cp template_experiment.md semantic_navigation_nov01_2025.md
   ```

2. **Fill in Context and Hypothesis sections**

3. **Work and document experiments** as you go:
   - Add experiment entries with dates and commits
   - Document what you tried and results
   - Note decisions and pivots

4. **When work completes**:
   - Fill in Final Results section
   - Update status to `complete`
   - Add completion date

5. **Add lightweight devlog entry**:
   - Date and time range
   - Link to experiment doc
   - Key results summary
   - Commit hashes

### During Feature Branch Work

**Daily commits** to feature branch:
```bash
git commit -m "feat(llm): test mistral-7b performance"
```

**Update experiment doc** with results:
```markdown
### Experiment 2: Mistral 7B (2025-10-10)
**Commit**: `3ac1e01`

**What We Tried**: Mistral 7B Instruct v0.3...
```

**When branch merges**:
```bash
# 1. Merge feature branch
git merge feature/local-llm

# 2. Update experiment doc status to "complete"

# 3. Add devlog entry with link to experiment doc
```

## Experiment Doc Examples

See these real examples from ShadowHound development:

- [local_llm_exploration_oct10_2025.md](local_llm_exploration_oct10_2025.md) - LLM model selection
- [dimos_integration_oct05_2025.md](dimos_integration_oct05_2025.md) - Feature branch work

## Agent Instructions

**For AI Agents**: When completing experimental work:

1. ✅ **DO**: Create experiment doc for research/exploration work
2. ✅ **DO**: Document all approaches tried (successes and failures)
3. ✅ **DO**: Link experiment doc from devlog entry
4. ✅ **DO**: Update experiment doc status when complete
5. ❌ **DON'T**: Put detailed experimental narrative in devlog
6. ❌ **DON'T**: Skip documenting failed approaches

## Migration from Old Pattern

**Historical devlog entries** (before Oct 14, 2025):
- Leave as-is in devlog.md (complete historical record)
- New work uses experiment docs + lightweight devlog

**No need to migrate** old entries unless:
- You're actively building on that work
- The experimental details would help future work
- You want to extract as a reference example

## Questions?

- See [devlog.md](../devlog.md) for the lightweight timeline
- See [recent_work.md](../recent_work.md) for last 5 days summary
- See examples in this directory for real-world usage

---

**Last Updated**: 2025-10-14
**Pattern Established**: Oct 14, 2025 (Session: PR review & devlog strategy redesign)
