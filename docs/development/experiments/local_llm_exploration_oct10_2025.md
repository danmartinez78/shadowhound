---
tags: [experiment, llm, local-inference, performance]
status: complete
started: 2025-10-10
completed: 2025-10-10
related: [../software/llm/thor_performance_notes.md, ../architecture/local_ai_roadmap.md]
summary: >
  Explored local LLM alternatives to OpenAI cloud, tested 4 models, selected Mistral 7B for 24x speed improvement
---

# Local LLM Exploration

## Context

ShadowHound initially used OpenAI cloud API for LLM inference (~12s response time). For an autonomous mobile robot, this latency is problematic:
- Network dependency (robot may operate without internet)
- Slow iteration cycles during development
- Cost considerations for continuous operation
- Privacy concerns for household deployment

**Goal**: Deploy LLM locally on Thor AGX Orin for faster, offline-capable inference.

## Hypothesis

vLLM server running on Thor AGX Orin (64GB RAM) can host 7B-13B parameter models with:
- Sub-second response times (vs. 12s cloud)
- Tool calling support (critical for DIMOS agent)
- Acceptable quality for household assistant tasks

## Experiments

### Experiment 1: Llama 3.1 8B Instruct (2025-10-10 Morning)
**Commit**: `ca48cf3`

**What We Tried**:
- Model: `meta-llama/Meta-Llama-3.1-8B-Instruct`
- vLLM server on Thor (port 8000)
- Tool calling with DIMOS agent

**Results**:
- ❌ License issues: Llama models require gated access
- ❌ Tokenizer hang: Loading got stuck on tokenizer initialization
- ⚠️ Licensing concern: Meta's license may restrict commercial use

**Decision**: **Abandon** - Licensing complexity and technical issues make this unsuitable for open-source project

---

### Experiment 2: Mistral 7B Instruct v0.3 (2025-10-10 Afternoon)
**Commit**: `3ac1e01`

**What We Tried**:
- Model: `mistralai/Mistral-7B-Instruct-v0.3`
- vLLM server on Thor (port 8000)
- Tool calling validation script
- DIMOS agent integration test

**Results**:
- ✅ **Tool calling works!** Properly formats and executes tool calls
- ✅ Apache 2.0 license (fully open for any use)
- ✅ Performance: ~37 tokens/sec baseline (24x faster than cloud)
- ✅ Response time: ~0.5s vs 12s cloud (96% reduction)
- ✅ Quality: Acceptable for household assistant tasks

**Decision**: **Selected as primary local model** - Best balance of performance, licensing, and functionality

---

### Experiment 3: Qwen 2.5 7B Instruct (2025-10-10 Evening)
**Commit**: `16be165`

**What We Tried**:
- Model: `Qwen/Qwen2.5-7B-Instruct`
- Same vLLM setup as Mistral
- Tool calling test

**Results**:
- ❌ **Tool calling broken**: Returns tool calls as JSON text instead of executing
- ⚠️ Format issue: Output contains the tool call structure but doesn't trigger execution
- ✅ Performance: Similar speed to Mistral
- ✅ License: Apache 2.0

**Decision**: **Reject** - Tool calling is critical for agent functionality, format incompatibility is a blocker

---

### Experiment 4: Local Embeddings (SentenceTransformers) (2025-10-10 Evening)
**Commit**: `b0c0e26`

**What We Tried**:
- Replace OpenAI embeddings with `sentence-transformers/all-MiniLM-L6-v2`
- Test with DIMOS memory system
- Validate embedding quality for RAG

**Results**:
- ✅ Works with non-OpenAI backends
- ✅ Fast: Local embedding generation
- ✅ Quality: Sufficient for memory retrieval
- ✅ No API costs or rate limits

**Decision**: **Adopt** - Default for non-OpenAI backends

---

### Experiment 5: DIMOS Memory Fix (2025-10-10 Late Evening)
**Commit**: `d9b6340`

**What We Tried**:
- Fix DIMOS auto-creating OpenAI memory even with local LLM
- Patch to respect backend configuration
- Test with local LLM + local embeddings

**Results**:
- ✅ **Fixed**: DIMOS now respects backend choice
- ✅ Local LLM + local embeddings working together
- ✅ No OpenAI dependency when using local backend

**Decision**: **Merged** - Critical fix for local deployment

---

## Final Results

### What Worked

**Mistral 7B Instruct v0.3** selected as primary local model:
- **Performance**: 37 tok/s baseline, ~0.5s response time
- **Tool calling**: Fully functional with DIMOS agent
- **License**: Apache 2.0 (open for any use)
- **Quality**: Acceptable for household tasks
- **24x speed improvement** over OpenAI cloud (0.5s vs 12s)

**Local embeddings** (SentenceTransformers):
- No external API dependency
- Fast local generation
- Works with DIMOS memory system

### What Didn't Work

**Llama 3.1 8B**:
- Gated model access (licensing friction)
- Tokenizer hang issues
- License restrictions unclear for commercial use

**Qwen 2.5 7B**:
- Tool calling format incompatible with agent framework
- Returns JSON text instead of executing tool calls

**Hermes-2-Pro**:
- Briefly considered but not tested (switched to Mistral after good results)

### Key Decisions

1. **Mistral 7B as default local model**
   - Rationale: Best balance of performance, licensing, tool calling support
   - Trade-off: May not match GPT-4 quality, but speed/cost/privacy wins

2. **Local embeddings for non-OpenAI backends**
   - Rationale: Removes last OpenAI dependency
   - Trade-off: Slightly lower quality than OpenAI embeddings, but acceptable

3. **Dual-backend support maintained**
   - Rationale: Cloud still useful for complex tasks, development
   - Configuration: `.env` file selects backend

4. **Tool calling is non-negotiable**
   - Rationale: Agent framework requires tool execution
   - Impact: Eliminates many otherwise viable models

### Performance Metrics

| Backend | Response Time | Tokens/Sec | Cost | Dependency |
|---------|--------------|------------|------|------------|
| OpenAI Cloud | ~12s | ~8 tok/s | $$ | Internet |
| Mistral 7B Local | ~0.5s | ~37 tok/s | Free | Thor AGX |

**Speed improvement**: 24x faster (96% latency reduction)

### Constraints Identified

1. **Thor compute budget unknown**: Need to profile full system under load
2. **Model size limit**: 7B-13B models fit in 64GB RAM with room for other processes
3. **Tool calling format**: Not all models support OpenAI-compatible tool calling
4. **Licensing critical**: Must verify Apache 2.0 or MIT for deployment

## Implementation Status

- [x] Research complete (4 models tested)
- [x] Approach validated (Mistral 7B working)
- [x] Implementation merged (commit `3ac1e01`)
- [x] Documentation updated (performance notes, roadmap)
- [x] Local embeddings integrated
- [x] DIMOS memory fix applied

## Follow-Up Work

### Immediate
- Profile Thor under full system load (compute budget)
- Test Mistral 7B on real robot missions

### Future
- Experiment with quantized models (4-bit for memory efficiency)
- Test Mistral 22B if compute budget allows
- Evaluate vision-language models for perception tasks

## References

- [Thor Performance Notes](../software/llm/thor_performance_notes.md)
- [Local AI Roadmap](../architecture/local_ai_roadmap.md)
- vLLM Documentation: https://docs.vllm.ai/
- Mistral AI: https://mistral.ai/
- Tool calling test script: `test_backend_validation.py`

---

**Total Time**: ~13 hours (full day marathon)
**Commits**: 60+ commits (most intensive development day)
**Outcome**: ✅ Local LLM deployment validated, 24x speed improvement achieved
