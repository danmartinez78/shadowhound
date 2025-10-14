---
tags: [software/llm, index]
status: active
related: []
aliases: [LLM Documentation Index]
summary: >
  Local LLM integration documentation - vLLM, Ollama setup, benchmarking, and backend validation.
---

# LLM Integration Documentation

## Purpose
Central hub for local LLM backend documentation covering vLLM deployment, Ollama alternatives, performance benchmarking, and integration guides.

## Prerequisites
- NVIDIA Jetson AGX Thor or compatible GPU system
- Understanding of LLM concepts and model serving
- Familiarity with Docker/containers

## Quick Start Guides

### Production (Recommended)
- **[vLLM Quick Start](../../software/llm/vllm_quickstart.md)** — Deploy Hermes-2-Pro on Thor using NVIDIA's official container

### Alternative Backends
- **[Ollama Setup](../../software/llm/ollama_setup.md)** — Alternative local LLM backend (24x faster than cloud)
- **[Ollama Backend Integration](../../software/llm/ollama_backend_integration.md)** — Integration details
- **[llama.cpp Migration](../../software/llm/llama_cpp_migration.md)** — Migration from llama.cpp

## Backend Selection & Validation

### Validation & Testing
- **[LLM Backend Validation](../../software/llm/llm_backend_validation.md)** — Startup validation system
- **[Backend Validation Summary](../../software/llm/backend_validation_summary.md)** — Validation results
- **[Backend Quick Reference](../../software/llm/backend_quick_reference.md)** — Quick command reference
- **[Ollama Testing Guide](../../software/llm/testing_guide_ollama.md)** — Test procedures

### Model Selection
- **[Ollama Models](../../software/llm/ollama_models.md)** — Available models overview
- **[Ollama Model Selection](../../software/llm/ollama_model_selection.md)** — Choosing the right model
- **[Ollama Model Comparison](../../software/llm/ollama_model_comparison.md)** — Performance comparison

## Performance & Benchmarking

### Benchmarking Guides
- **[Ollama Benchmarking](../../software/llm/ollama_benchmarking.md)** — Benchmark methodology
- **[Benchmark Results](../../software/llm/ollama_benchmark_results.md)** — Performance data
- **[Benchmark Memory Management](../../software/llm/ollama_benchmark_memory_management.md)** — Memory optimization
- **[Quality Scoring Summary](../../software/llm/quality_scoring_summary.md)** — Quality metrics
- **[Ollama Quality Scoring](../../software/llm/ollama_quality_scoring.md)** — Detailed scoring

### Thor-Specific Notes
- **[Thor Resources](../../software/llm/thor_resources.md)** — Thor GPU/memory specs
- **[Thor Performance Notes](../../software/llm/thor_performance_notes.md)** — Performance observations
- **[Security Analysis (jtop)](../../software/llm/security_analysis_jtop.md)** — Security considerations

## Deployment & Operations

### Deployment
- **[Ollama Deployment Checklist](../../software/llm/ollama_deployment_checklist.md)** — Pre-deployment verification
- **[Feature Complete (Ollama)](../../software/llm/feature_complete_ollama.md)** — Feature status
- **[Local AI Implementation Status](../../software/llm/local_ai_implementation_status.md)** — Overall status

### Integration
- **[Local LLM Integration Summary](../../software/llm/local_llm_integration_summary.md)** — Integration overview
- **[Local LLM Memory Roadmap](../../software/llm/local_llm_memory_roadmap.md)** — Memory/RAG roadmap
- **[Ollama Status & TODOs](../../software/llm/ollama_status_and_todos.md)** — Current status and tasks

### Authentication & Configuration
- **[vLLM HuggingFace Auth](../../software/llm/vllm_huggingface_auth.md)** — Authentication setup (if needed)

## Architecture Overview

### Backend Options

| Backend | Speed | Use Case | Status |
|---------|-------|----------|--------|
| **vLLM (Thor)** | 1-2s | Production, autonomous | ✅ Recommended |
| **Ollama (Gaming PC)** | 0.5-1s | Development, fastest | ✅ Validated |
| **Ollama (Thor)** | 1-2s | Alternative to vLLM | ✅ Validated |
| **Cloud (GPT-4)** | 3-7s | Fallback, highest quality | ✅ Default |

### Key Components
- **Mission Planner** — Converts natural language to skill sequences
- **Backend Validation** — Startup health checks for LLM connectivity
- **Embeddings** — ChromaDB for local vector storage
- **Skills API** — Typed interface for robot commands

## Common Tasks

### Deploy vLLM on Thor
```bash
# See vllm_quickstart.md for full guide
docker run --runtime nvidia --gpus all \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -p 8000:8000 \
  nvcr.io/nvidia/pytorch:24.07-py3 \
  /bin/bash -c "pip install vllm && vllm serve NousResearch/Hermes-2-Pro-Llama-3-8B"
```

### Test Backend Connection
```bash
# Validate backend at startup
ros2 launch shadowhound_bringup mission_agent.launch.py

# Check logs for validation results
# Should see: "✅ LLM backend validated successfully"
```

### Switch Backends
```bash
# Edit .env file
# AGENT_BACKEND=cloud  # or 'local' for vLLM/Ollama

# Restart mission agent
ros2 launch shadowhound_bringup mission_agent.launch.py
```

## Validation
- [ ] vLLM deployment tested on Thor
- [ ] Ollama benchmarks validated
- [ ] Backend validation working correctly
- [ ] Model selection guide accurate
- [ ] Performance metrics up-to-date

## See Also
- [Environment Variables](../configuration/environment_variables.md) — LLM backend configuration
- [Agent Architecture](../agent/dimos_agent_architecture.md) — How agent uses LLMs
- [Hardware Topologies](../../hardware/network_power_topologies.md) — Thor power/network setup
- [Software Index](../../software/software_hub.md) — Complete software documentation

## References
- [Documentation Root](../../index.md)
- vLLM Documentation: https://docs.vllm.ai/
- Ollama Documentation: https://ollama.ai/
- Hermes-2-Pro Model: https://huggingface.co/NousResearch/Hermes-2-Pro-Llama-3-8B
- NVIDIA PyTorch Containers: https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch
