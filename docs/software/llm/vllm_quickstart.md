# vLLM Quick Start for Thor

**Recommended:** Use NVIDIA's official vLLM container - fastest and most stable option.

## Prerequisites

**None!** Hermes-2-Pro is open and doesn't require authentication.

~~The Qwen model requires HuggingFace authentication~~ (No longer using Qwen)
<del>

```bash
# On Thor - run once
huggingface-cli login
```

When prompted:
- Get token from: https://huggingface.co/settings/tokens (read access)
- Say **Yes** to "Add token as git credential" (persists forever)
- Accept license: https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct

See [docs/vllm_huggingface_auth.md](./vllm_huggingface_auth.md) for troubleshooting.

</del>

## Quick Setup (5 minutes)

On Thor:
```bash
cd ~/shadowhound  # or wherever you cloned it
git pull origin feature/local-llm-support
./scripts/setup_vllm_thor.sh
```

That's it! The script will:
1. Pull NVIDIA's vLLM container (~10GB)
2. Start server with **Mistral-7B-Instruct-v0.3** (Apache 2.0, no license restrictions!)
3. **Enable native tool calling support**
4. Expose OpenAI-compatible API on port 8000

**Note:** Mistral is fully open source (Apache 2.0) - no gating or authentication!

**First run takes longer** while downloading the model (~5GB).

## On Your Laptop

Update `.env`:
```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=mistralai/Mistral-7B-Instruct-v0.3
USE_PLANNING_AGENT=false

# API key (required by DIMOS, use dummy for vLLM)
OPENAI_API_KEY=sk-dummy-key-for-vllm
```

**Note on Embeddings:** The agent will automatically detect that you're using a local LLM (non-OpenAI URL) and use local embeddings (sentence-transformers). No need to set `USE_LOCAL_EMBEDDINGS=true` unless you want to be explicit.

See [docs/vllm_env_example.txt](./vllm_env_example.txt) for complete configuration.

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
    "model": "mistralai/Mistral-7B-Instruct-v0.3",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 50
  }'
```

**Via web UI:**
- Go to http://localhost:8501
- Send: "hi"
- Should get actual response (not 'GGGGG'!)

## Why Mistral 7B?

✅ **Apache 2.0 License** - fully open, no restrictions or gating!  
✅ **Native tool calling** - built into the model  
✅ **Officially validated by vLLM** - tested and stable  
✅ **No authentication required** - just download and run  
✅ **Smaller than Llama** - faster inference, less memory  
✅ **Official NVIDIA support** for Thor  
✅ **OpenAI-compatible API** - seamless integration  

**From vLLM docs:** Mistral is one of the primary tested models for tool calling and uses the `mistral` parser.  

## Stopping the Server

Press `Ctrl+C` in the terminal running the script.

## Troubleshooting

### "ValueError: No embedding data received"
**Cause:** This shouldn't happen anymore! The agent auto-detects local LLM backends.  
**If it does happen:** Force local embeddings in `.env`:
```bash
USE_LOCAL_EMBEDDINGS=true
```
Then rebuild: `colcon build --packages-select shadowhound_mission_agent`

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

Other vLLM-validated tool calling models (if you want to try):

```bash
# In setup_vllm_thor.sh, change MODEL= and parser:

# Current default (Apache 2.0, no license!):
MODEL="mistralai/Mistral-7B-Instruct-v0.3"
--tool-call-parser mistral

# Llama 3.1 (requires Meta license acceptance):
MODEL="meta-llama/Llama-3.1-8B-Instruct"
--tool-call-parser hermes

# IBM Granite (Apache 2.0):
MODEL="ibm-granite/granite-3.0-8b-instruct"
--tool-call-parser hermes
```

**⚠️ Models that DON'T work:**
- `Qwen/Qwen2.5-Coder-7B-Instruct` - Returns JSON as text, not tool calls
- `NousResearch/Hermes-2-Pro-Llama-3-8B` - CUDA index errors

**✅ Recommended:** Stick with Mistral - it's open source and just works!

## Performance

Expected latency: **5-10 seconds** per command (much faster than Ollama's 12-15s)

## Related

- [Issue #12: LLM Alternatives](https://github.com/danmartinez78/shadowhound/issues/12)
- [NVIDIA vLLM Announcement](https://forums.developer.nvidia.com/t/announcing-new-vllm-container-3-5x-increase-in-gen-ai-performance-in-just-5-weeks-of-jetson-agx-thor-launch/346634)
- [scripts/README.md](../../scripts/README.md) - Comparison of all setup options
- [docs/vllm_huggingface_auth.md](vllm_huggingface_auth.md) - Authentication troubleshooting
