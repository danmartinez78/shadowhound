# vLLM Quick Start for Thor

**Recommended:** Use NVIDIA's official vLLM container - fastest and most stable option.

## Quick Setup (5 minutes)

On Thor:
```bash
cd ~/shadowhound  # or wherever you cloned it
git pull origin feature/local-llm-support
./scripts/setup_vllm_thor.sh
```

That's it! The script will:
1. Pull NVIDIA's vLLM container (~10GB)
2. Start server with Qwen2.5-Coder-7B-Instruct
3. Expose OpenAI-compatible API on port 8000

**First run takes longer** while downloading the model (~5GB).

## On Your Laptop

Update `.env`:
```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
USE_PLANNING_AGENT=false
```

Rebuild and test:
```bash
cd ~/shadowhound
git pull origin feature/local-llm-support
colcon build --packages-select shadowhound_mission_agent
source install/setup.bash
./start.sh
```

## Test It

**From laptop:**
```bash
# Simple test
curl -X POST http://192.168.10.116:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "Qwen/Qwen2.5-Coder-7B-Instruct",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 50
  }'
```

**Via web UI:**
- Go to http://localhost:8501
- Send: "hi"
- Should get actual response (not 'GGGGG'!)

## Why vLLM?

✅ **Official NVIDIA support** for Thor  
✅ **3.5x faster** than alternatives  
✅ **Pre-built container** - no compilation needed  
✅ **OpenAI-compatible API** - seamless integration  
✅ **Better memory management** than Ollama  

## Stopping the Server

Press `Ctrl+C` in the terminal running the script.

## Troubleshooting

### Out of memory
Edit script, reduce `GPU_MEMORY=0.8` to `0.6` or `0.5`

### Model download fails
Check internet connection and HuggingFace access

### Container won't start
```bash
# Check logs
docker logs vllm-server

# Verify GPU
nvidia-smi

# Free memory
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

## Different Models

Edit the script to try other models:
```bash
# In setup_vllm_thor.sh, change MODEL= line:

# Faster, smaller (FP4 quantized):
MODEL="nvidia/Llama-3.1-8B-Instruct-FP4"

# Larger, better quality:
MODEL="meta-llama/Llama-3.1-8B-Instruct"

# Coding-focused (current default):
MODEL="Qwen/Qwen2.5-Coder-7B-Instruct"
```

## Performance

Expected latency: **5-10 seconds** per command (much faster than Ollama's 12-15s)

## Related

- [Issue #12: LLM Alternatives](https://github.com/danmartinez78/shadowhound/issues/12)
- [NVIDIA vLLM Announcement](https://forums.developer.nvidia.com/t/announcing-new-vllm-container-3-5x-increase-in-gen-ai-performance-in-just-5-weeks-of-jetson-agx-thor-launch/346634)
- [docs/llama_cpp_migration.md](../docs/llama_cpp_migration.md) - Background on Ollama issues
