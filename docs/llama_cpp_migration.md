# Migration from Ollama to llama.cpp

**Status:** In Progress  
**Related:** Issue #12 - Evaluate alternatives to Ollama  
**Date:** October 12, 2025

## Background

Initial testing of local LLM support used Ollama with qwen2.5-coder:7b on Thor (Jetson AGX Orin). However, Ollama proved unstable and incompatible with the ShadowHound agent architecture.

## Ollama Issues Encountered

### 1. Stability Problems
- Frequent 500 errors requiring container restarts
- Random crashes during inference
- Thor system requiring full reboots
- phi4:14b causing segfaults on ARM64

### 2. 'GGGGG' Bug (Critical)
**Symptom:** All agent responses returned "GGGGGGGGGGG..." (repeated 'G' characters)

**Investigation:**
- ✅ Direct curl test to Ollama: Works fine
- ✅ Curl with single tool: Works fine
- ❌ Agent with 47 skills: Returns 'GGGGG'
- ❌ Agent with 5 skills: Still returns 'GGGGG'

**Attempted Fixes:**
- Reduced `max_output_tokens` from 4096 → 512
- Reduced skill count from 47 → 5 (Move, Reverse, SpinLeft, SpinRight, Wait)
- Verified DIMOS integration code
- Tested both OpenAIAgent and PlanningAgent modes

**Root Cause:** Unknown, but likely related to:
- System prompt formatting incompatibility
- Tool schema handling in Ollama
- Context window bugs in Ollama's OpenAI compatibility layer
- Sampling/temperature issues with qwen2.5-coder

### 3. Decision to Abandon Ollama

After 2+ hours of debugging, Ollama was deemed **not production-ready** for Jetson deployment. The 'GGGGG' bug persisted even with minimal configuration, indicating fundamental incompatibility.

## Why llama.cpp?

### Advantages over Ollama

1. **Stability:** More mature codebase, better tested on ARM64
2. **Memory Efficiency:** GGUF quantization (Q4_K_M uses ~4.4GB vs 4.7GB unquantized)
3. **OpenAI Compatibility:** Native OpenAI-compatible API server
4. **Function Calling:** Better tested with tool/function schemas
5. **Performance:** Lower overhead, faster inference
6. **Community:** Larger user base on Jetson/embedded systems

### Model Selection

**Chosen:** `qwen2.5-coder-7b-instruct-q4_k_m.gguf`

**Why Q4_K_M Quantization:**
- Good balance of quality vs memory
- Fits comfortably in 16GB GPU memory
- Minimal quality loss vs full precision
- Faster inference than Q8 or full precision

**Alternatives Considered:**
- Q8_0: Higher quality but slower and more memory
- Q4_0: Smaller but lower quality
- Q5_K_M: Good middle ground if Q4 quality insufficient

## Setup Instructions

### On Thor (Jetson AGX Orin)

```bash
# Clone repo and run setup script
cd ~
git clone https://github.com/danmartinez78/shadowhound.git
cd shadowhound
git checkout feature/local-llm-support

# Run automated setup
./scripts/setup_llamacpp_thor.sh
```

The script will:
1. Stop Ollama (free GPU memory)
2. Install build dependencies
3. Clone and build llama.cpp with CUDA
4. Download Qwen2.5-Coder GGUF model (~4.4GB)
5. Create systemd service
6. Start server on port 8080

**Manual steps if script fails:**

```bash
# Build llama.cpp
cd ~/llama.cpp
make clean
make LLAMA_CUDA=1 -j$(nproc)

# Download model
mkdir -p models
cd models
huggingface-cli download Qwen/Qwen2.5-Coder-7B-Instruct-GGUF \
    qwen2.5-coder-7b-instruct-q4_k_m.gguf --local-dir . --local-dir-use-symlinks False

# Start server manually
cd ~/llama.cpp
./llama-server \
    --model ./models/qwen2.5-coder-7b-instruct-q4_k_m.gguf \
    --ctx-size 8192 \
    --n-gpu-layers 35 \
    --port 8080 \
    --host 0.0.0.0 \
    --threads $(nproc) \
    --parallel 1
```

### On Laptop (Mission Control)

Update `.env` file:

```bash
# Change from Ollama to llama.cpp
AGENT_BACKEND=openai  # llama.cpp uses OpenAI-compatible API
OPENAI_BASE_URL=http://192.168.10.116:8080/v1
OPENAI_MODEL=qwen2.5-coder-7b-instruct-q4_k_m.gguf
USE_PLANNING_AGENT=false

# Keep skills reduced for initial testing
# (Will restore full set after validation)
```

Rebuild and test:

```bash
cd ~/shadowhound
git pull origin feature/local-llm-support
git submodule update --init --recursive
colcon build --packages-select shadowhound_mission_agent
source install/setup.bash
./start.sh
```

## Testing Plan

### Phase 1: Basic Validation (30 mins)
- [x] Server starts without errors
- [ ] API health check responds
- [ ] Simple chat completion works
- [ ] No 'GGGGG' bug

**Test Commands:**
```bash
# Health check
curl http://192.168.10.116:8080/health

# Simple completion
curl -X POST http://192.168.10.116:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q4_k_m.gguf",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 100
  }'
```

### Phase 2: Function Calling (1 hour)
- [ ] Agent loads 5 nav2 skills without errors
- [ ] Commands generate proper function calls
- [ ] Responses are coherent (not 'GGGGG')
- [ ] Latency acceptable (<15s per command)

**Test Commands via UI:**
- "hi"
- "what is your name?"
- "move forward"
- "turn left 90 degrees"
- "explain what skills you have"

### Phase 3: Stress Test (30 mins)
- [ ] 100 requests without crash
- [ ] Memory usage stable
- [ ] No degradation over time
- [ ] Thor system remains responsive

### Phase 4: Robot Control (30 mins)
- [ ] One successful robot command execution
- [ ] Nav2 skills work as expected
- [ ] Telemetry and status updates work

## Performance Tuning

### GPU Layers (`--n-gpu-layers`)

**Default:** 35 layers

Adjust based on GPU memory usage:
- Monitor with: `nvidia-smi -l 1`
- If OOM errors: Reduce to 30 or 25
- If GPU underutilized: Increase to 40

### Context Size (`--ctx-size`)

**Default:** 8192 tokens

- Larger = more conversation history, but slower
- Smaller = faster but less context
- 8192 is good balance for robot missions

### Parallel Requests (`--parallel`)

**Default:** 1

- Keep at 1 for single-user testing
- Can increase to 2-4 for multi-user if memory allows

## Rollback Plan

If llama.cpp also fails:

1. Document failures in Issue #12
2. Try vLLM as next alternative
3. If all local options fail, fallback to cloud (OpenAI API)

## Success Criteria

llama.cpp is considered successful if:

- ✅ No crashes in 100 requests
- ✅ No 'GGGGG' bug or similar failures
- ✅ Latency < 15s per command
- ✅ Function calling works correctly
- ✅ One successful robot command execution
- ✅ Memory usage stable over time

## Known Limitations

1. **Single Request at a Time:** `--parallel 1` means sequential processing
2. **Slower than Cloud:** ~10-15s vs 1-2s for OpenAI API
3. **Context Limits:** 8192 tokens vs 128k for cloud models
4. **No Streaming:** Initial implementation won't stream responses

## Future Optimizations

If llama.cpp proves viable:

1. **Model Optimization:**
   - Test Q5_K_M for better quality
   - Try smaller 3B models for faster inference
   - Evaluate AWQ/GPTQ quantization

2. **Server Optimization:**
   - Enable continuous batching
   - Increase parallel requests
   - Tune KV cache settings

3. **Infrastructure:**
   - Add load balancing for multiple Thors
   - Implement request queuing
   - Add monitoring/alerting

## References

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [GGUF Model Hub](https://huggingface.co/models?library=gguf)
- [Qwen2.5-Coder Models](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF)
- [Issue #12: Evaluate alternatives to Ollama](https://github.com/danmartinez78/shadowhound/issues/12)
