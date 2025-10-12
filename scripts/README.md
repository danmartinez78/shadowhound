# Thor Setup Scripts

Scripts for setting up local LLM inference on Thor (Jetson AGX Orin).

## llama.cpp Setup

**Recommended:** Use llama.cpp for stable local inference

### Option 1: Full Setup with Systemd (Recommended)

```bash
# On Thor
./setup_llamacpp_thor.sh
```

Creates systemd service that auto-starts on boot. Includes health checks and service management.

**Service commands:**
```bash
sudo systemctl status llamacpp   # Check status
sudo systemctl start llamacpp    # Start server
sudo systemctl stop llamacpp     # Stop server
sudo systemctl restart llamacpp  # Restart server
sudo journalctl -u llamacpp -f   # View logs
```

### Option 2: Quick Manual Setup

```bash
# On Thor (runs in foreground)
./setup_thor_llamacpp_quick.sh
```

Runs server in current terminal. Press Ctrl+C to stop. Good for testing.

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
