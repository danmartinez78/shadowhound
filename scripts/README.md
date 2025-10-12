# Thor Setup Scripts

Scripts for setting up local LLM inference on Thor (Jetson AGX Orin).

## vLLM Setup (RECOMMENDED)

**Fastest and most stable** - Uses NVIDIA's official vLLM container

```bash
# On Thor
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
```

See: `docs/vllm_quickstart.md`

## llama.cpp Setup (BACKUP)

**Use if vLLM has issues** - Uses official llama.cpp container

```bash
# On Thor
./setup_llamacpp_docker_thor.sh
```

**Why llama.cpp:**
- More stable than Ollama
- Lower memory usage (GGUF quantization)
- OpenAI-compatible API
- No host installation needed

**Laptop .env:**
```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8080/v1
OPENAI_MODEL=qwen2.5-coder-7b-instruct-q4_k_m.gguf
USE_PLANNING_AGENT=false
```

## ~~Ollama Setup~~ (DEPRECATED)

**DO NOT USE** - Ollama is unstable on Thor with critical bugs:
- Frequent crashes and 500 errors
- 'GGGGG' bug (all responses are repeated 'G' characters)
- Requires Thor reboots
- phi4:14b causes segfaults

See `docs/llama_cpp_migration.md` for details.

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

### Thor Server Settings

- **Model:** qwen2.5-coder-7b-instruct-q4_k_m.gguf (~4.4GB)
- **Port:** 8080
- **Context:** 8192 tokens
- **GPU Layers:** 35 (adjust if OOM errors)

### Laptop .env Settings

```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8080/v1
OPENAI_MODEL=qwen2.5-coder-7b-instruct-q4_k_m.gguf
USE_PLANNING_AGENT=false
```

## Testing

### Quick Health Check

```bash
# From laptop
curl http://192.168.10.116:8080/health
```

### Test Completion

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

### Server won't start

```bash
# Check logs
sudo journalctl -u llamacpp -n 50

# Common issues:
# - Ollama still running: docker stop ollama
# - Port in use: lsof -i :8080
# - GPU memory full: nvidia-smi
```

### Out of memory errors

Reduce GPU layers in `/etc/systemd/system/llamacpp.service`:

```bash
sudo nano /etc/systemd/system/llamacpp.service
# Change: --n-gpu-layers 35
# To:     --n-gpu-layers 25
sudo systemctl daemon-reload
sudo systemctl restart llamacpp
```

### Slow inference

Check GPU usage:

```bash
nvidia-smi -l 1
```

If GPU not fully utilized, increase layers or check CUDA build.

## Performance Tuning

### GPU Layers

- **35:** Default, ~14GB GPU memory
- **30:** If OOM, ~12GB GPU memory  
- **40:** If have spare memory, ~16GB

### Context Size

- **8192:** Default, good for missions
- **4096:** Faster, less context
- **16384:** Slower, more context

### Model Variants

- **Q4_K_M:** Default, 4.4GB (good balance)
- **Q5_K_M:** 5.4GB (better quality)
- **Q8_0:** 7.7GB (best quality, slower)

To change model, download new GGUF and update service file.

## Migration from Ollama

If you were using Ollama:

1. Stop Ollama: `docker stop ollama`
2. Run setup script (above)
3. Update laptop .env (see Configuration)
4. Rebuild agent: `colcon build --packages-select shadowhound_mission_agent`
5. Test: `./start.sh`

See `docs/llama_cpp_migration.md` for detailed migration guide.

## References

- [llama.cpp Docs](https://github.com/ggerganov/llama.cpp)
- [Qwen2.5 Models](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF)
- [Issue #12: LLM Alternatives](https://github.com/danmartinez78/shadowhound/issues/12)
