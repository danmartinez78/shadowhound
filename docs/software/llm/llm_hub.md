---
tags: [software/llm, index]
status: active
related: [software/README, software/configuration/environment_variables, hardware/network_power_topologies]
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
- **[[software/llm/vllm_quickstart|vLLM Quick Start]]** — Deploy Hermes-2-Pro on Thor using NVIDIA's official container

### Alternative Backends
- **[[software/llm/ollama_setup|Ollama Setup]]** — Alternative local LLM backend (24x faster than cloud)
- **[[software/llm/ollama_backend_integration|Ollama Backend Integration]]** — Integration details
- **[[software/llm/llama_cpp_migration|llama.cpp Migration]]** — Migration from llama.cpp

## Backend Selection & Validation

### Validation & Testing
- **[[software/llm/llm_backend_validation|LLM Backend Validation]]** — Startup validation system
- **[[software/llm/backend_validation_summary|Backend Validation Summary]]** — Validation results
- **[[software/llm/backend_quick_reference|Backend Quick Reference]]** — Quick command reference
- **[[software/llm/testing_guide_ollama|Ollama Testing Guide]]** — Test procedures

### Model Selection
- **[[software/llm/ollama_models|Ollama Models]]** — Available models overview
- **[[software/llm/ollama_model_selection|Ollama Model Selection]]** — Choosing the right model
- **[[software/llm/ollama_model_comparison|Ollama Model Comparison]]** — Performance comparison

## Performance & Benchmarking

### Benchmarking Guides
- **[[software/llm/ollama_benchmarking|Ollama Benchmarking]]** — Benchmark methodology
- **[[software/llm/ollama_benchmark_results|Benchmark Results]]** — Performance data
- **[[software/llm/ollama_benchmark_memory_management|Benchmark Memory Management]]** — Memory optimization
- **[[software/llm/quality_scoring_summary|Quality Scoring Summary]]** — Quality metrics
- **[[software/llm/ollama_quality_scoring|Ollama Quality Scoring]]** — Detailed scoring

### Thor-Specific Notes
- **[[software/llm/thor_resources|Thor Resources]]** — Thor GPU/memory specs
- **[[software/llm/thor_performance_notes|Thor Performance Notes]]** — Performance observations
- **[[software/llm/security_analysis_jtop|Security Analysis (jtop)]]** — Security considerations

## Deployment & Operations

### Deployment
- **[[software/llm/ollama_deployment_checklist|Ollama Deployment Checklist]]** — Pre-deployment verification
- **[[software/llm/feature_complete_ollama|Feature Complete (Ollama)]]** — Feature status
- **[[software/llm/local_ai_implementation_status|Local AI Implementation Status]]** — Overall status

### Integration
- **[[software/llm/local_llm_integration_summary|Local LLM Integration Summary]]** — Integration overview
- **[[software/llm/local_llm_memory_roadmap|Local LLM Memory Roadmap]]** — Memory/RAG roadmap
- **[[software/llm/ollama_status_and_todos|Ollama Status & TODOs]]** — Current status and tasks

### Authentication & Configuration
- **[[software/llm/vllm_huggingface_auth|vLLM HuggingFace Auth]]** — Authentication setup (if needed)

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
- [[../configuration/environment_variables|Environment Variables]] — LLM backend configuration
- [[../agent/dimos_agent_architecture|Agent Architecture]] — How agent uses LLMs
- [[../../hardware/network_power_topologies|Hardware Topologies]] — Thor power/network setup
- [[index|Software Index]] — Complete software documentation

## References
- [[../../index|Documentation Root]]
- vLLM Documentation: https://docs.vllm.ai/
- Ollama Documentation: https://ollama.ai/
- Hermes-2-Pro Model: https://huggingface.co/NousResearch/Hermes-2-Pro-Llama-3-8B
- NVIDIA PyTorch Containers: https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch
