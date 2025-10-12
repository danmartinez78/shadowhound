# Thor Setup Scripts

Scripts for setting up local LLM inference on Thor (Jetson AGX Orin).

## Prerequisites

### HuggingFace Authentication (One-time Setup)

Both vLLM and llama.cpp require HuggingFace authentication for Qwen models:

```bash
# On Thor - run once
huggingface-cli login
```

When prompted:
- Get token from: https://huggingface.co/settings/tokens (read access)
- Say **Yes** to "Add token as git credential" (persists forever)
- Accept license at model page (Qwen2.5-Coder)

Token is saved to `~/.cache/huggingface/token` and automatically used by both setup scripts.

See: `docs/vllm_huggingface_auth.md` for troubleshooting

## vLLM Setup (RECOMMENDED)

**Fastest and most stable** - Uses NVIDIA's official vLLM container

```bash
# On Thor (after huggingface-cli login)
./setup_vllm_thor.sh
```

**Why vLLM:**
- Official NVIDIA support for Thor
- 3.5x performance improvement (NVIDIA tested)
- Pre-built container (no compilation)
- Best memory management

**Laptop .env:**
```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
USE_PLANNING_AGENT=false

# CRITICAL: vLLM doesn't support embeddings API
USE_LOCAL_EMBEDDINGS=true
OPENAI_API_KEY=sk-dummy-key-for-vllm
```

**Important:** Must set `USE_LOCAL_EMBEDDINGS=true` - vLLM doesn't support `/v1/embeddings` endpoint.

See: `docs/vllm_quickstart.md` and `docs/vllm_env_example.txt`

## llama.cpp Setup (BACKUP)

**Use if vLLM has issues** - Uses official llama.cpp container

```bash
# On Thor (after huggingface-cli login)
./setup_llamacpp_docker_thor.sh
```

**Why llama.cpp:**
- More stable than Ollama
- Lower memory usage (GGUF quantization)
- OpenAI-compatible API
- Containerized (no host build required)

**Laptop .env:**
```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8080/v1
OPENAI_MODEL=qwen2.5-coder-7b-instruct-q4_k_m.gguf
USE_PLANNING_AGENT=false

# Also requires local embeddings
USE_LOCAL_EMBEDDINGS=true
OPENAI_API_KEY=sk-dummy-key
```

## ~~Ollama Setup~~ (DEPRECATED)

**DO NOT USE** - Ollama is unstable on Thor with critical bugs:
- Frequent crashes and 500 errors
- 'GGGGG' bug (all responses are repeated 'G' characters)
- Requires Thor reboots
- phi4:14b causes segfaults

Scripts removed from repo - use containerized alternatives only.

## Quick Comparison

| Feature | vLLM | llama.cpp | Ollama |
|---------|------|-----------|--------|
| **Status** | ✅ Recommended | ✅ Backup | ❌ Deprecated |
| **Stability** | Excellent | Good | Poor |
| **Performance** | Fastest (3.5x) | Fast | Slow |
| **Memory** | Efficient | Very Efficient | Problematic |
| **Setup Time** | 15-20 min | 15-20 min | 10 min |
| **NVIDIA Support** | Official | Community | Community |
| **Port** | 8000 | 8080 | 11434 |

## Configuration

### vLLM (Recommended)

- **Port:** 8000
- **Model:** Qwen/Qwen2.5-Coder-7B-Instruct (~5GB)
- **Context:** 8192 tokens
- **GPU Memory:** 80% utilization

### llama.cpp (Backup)

- **Port:** 8080
- **Model:** qwen2.5-coder-7b-instruct-q4_k_m.gguf (~4.4GB)
- **Context:** 8192 tokens
- **GPU Layers:** 35 (adjust if OOM errors)

## Testing

### Quick Health Check

**vLLM:**
```bash
curl http://192.168.10.116:8000/health
```

**llama.cpp:**
```bash
curl http://192.168.10.116:8080/health
```

### Test Completion

**vLLM:**
```bash
curl -X POST http://192.168.10.116:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "Qwen/Qwen2.5-Coder-7B-Instruct",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 50
  }'
```

**llama.cpp:**
```bash
curl -X POST http://192.168.10.116:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q4_k_m.gguf",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 50
  }'
```

### Test Agent

```bash
# On laptop
cd ~/shadowhound
./start.sh
# Then use web UI: http://localhost:8501
```

## Troubleshooting

### Container won't start

```bash
# Check if container is running
docker ps -a | grep vllm
docker ps -a | grep llama

# Check logs
docker logs <container_name>

# Common issues:
# - Ollama still running: docker stop ollama
# - Port in use: lsof -i :8000 (or :8080)
# - GPU memory full: nvidia-smi
```

### Out of memory errors

**vLLM:**
Edit script and reduce `--gpu-memory-utilization`:
```bash
--gpu-memory-utilization 0.7  # From 0.8
```

**llama.cpp:**
Edit script and reduce GPU layers:
```bash
--n-gpu-layers 25  # From 35
```

### Slow inference

Check GPU usage:
```bash
nvidia-smi -l 1
```

If GPU not fully utilized:
- vLLM: Check attention backend (FLASHINFER recommended)
- llama.cpp: Increase GPU layers if memory available

## Performance Tuning

### vLLM

**GPU Memory Utilization:**
- **0.8:** Default, balanced
- **0.7:** If OOM errors
- **0.9:** If have spare memory

**Attention Backend:**
- **FLASHINFER:** Fastest (default)
- **FLASH_ATTN:** Good fallback
- **XFORMERS:** If others unavailable

### llama.cpp

**GPU Layers:**
- **35:** Default, ~14GB GPU memory
- **30:** If OOM, ~12GB GPU memory  
- **40:** If have spare memory, ~16GB

**Context Size:**
- **8192:** Default, good for missions
- **4096:** Faster, less context
- **16384:** Slower, more context

**Model Variants:**
- **Q4_K_M:** Default, 4.4GB (good balance)
- **Q5_K_M:** 5.4GB (better quality)
- **Q8_0:** 7.7GB (best quality, slower)

## Migration from Ollama

If you were using Ollama:

1. Stop Ollama: `docker stop ollama`
2. Run vLLM setup script (recommended): `./setup_vllm_thor.sh`
3. Update laptop .env (see Configuration above)
4. Rebuild agent: `colcon build --packages-select shadowhound_mission_agent`
5. Test: `./start.sh`

## References

- [vLLM Docs](https://docs.vllm.ai/)
- [vLLM Quickstart](../docs/vllm_quickstart.md)
- [llama.cpp Docs](https://github.com/ggerganov/llama.cpp)
- [Qwen2.5 Models](https://huggingface.co/Qwen)
- [Issue #12: LLM Alternatives](https://github.com/danmartinez78/shadowhound/issues/12)
