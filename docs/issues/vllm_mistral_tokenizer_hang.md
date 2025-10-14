---
tags: [issue, vllm, mistral, inference]
status: active
related: []
summary: >
  vLLM server hangs with Mistral model due to tokenizer mismatch and FLASHINFER backend issues
---

# vLLM Mistral Tokenizer Hang

## Issue

When running vLLM with Mistral-7B-Instruct-v0.3, API requests hang indefinitely with these symptoms:

```bash
# curl hangs at 0% after ~2 minutes
curl -X POST http://192.168.10.116:8000/v1/chat/completions ...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   329    0     0  100   329      0      3  0:01:49  0:01:48  0:00:01     0

# vLLM logs show warnings:
(APIServer pid=1) INFO: Non-Mistral tokenizer detected when using a Mistral model...
(APIServer pid=1) INFO: Engine 000: Avg prompt throughput: 5.2 tokens/s, 
  Avg generation throughput: 0.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, 
  GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
```

**Key Indicators:**
1. **Tokenizer warning**: "Non-Mistral tokenizer detected"
2. **Very low throughput**: 5.2 tokens/s prompt, 0.1 tokens/s generation
3. **Zero GPU cache usage**: 0.0% (should be >0% when processing)
4. **Request stuck**: Running but not progressing

## Root Causes

### 1. Tokenizer Mismatch
vLLM fails to automatically detect Mistral's correct tokenizer, falling back to a generic one that doesn't work properly with tool calling.

**Solution:** Explicitly specify tokenizer with `--tokenizer` flag:
```bash
vllm serve "mistralai/Mistral-7B-Instruct-v0.3" \
  --tokenizer "mistralai/Mistral-7B-Instruct-v0.3" \
  --tool-call-parser mistral
```

### 2. FLASHINFER Backend Incompatibility
The `VLLM_ATTENTION_BACKEND=FLASHINFER` environment variable causes issues on Jetson AGX Orin with certain models.

**Solution:** Remove the FLASHINFER backend specification, let vLLM auto-detect:
```bash
# Don't set this:
# -e VLLM_ATTENTION_BACKEND=FLASHINFER

# Let vLLM choose the best backend automatically
```

## Fixes Applied

### Updated `scripts/setup_vllm_thor.sh`

**Change 1: Add explicit tokenizer**
```diff
  vllm serve "${MODEL}" \
    --port 8000 \
    --host 0.0.0.0 \
    --trust-remote-code \
+   --tokenizer "${MODEL}" \
    --max-model-len ${MAX_MODEL_LEN} \
```

**Change 2: Remove FLASHINFER backend**
```diff
  docker run --rm -it --network host \
    --name "${CONTAINER_NAME}" \
    --shm-size=16g \
    --runtime=nvidia \
    --gpus all \
-   -e VLLM_ATTENTION_BACKEND=FLASHINFER \
    -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
```

## Testing

### 1. Restart vLLM with fixes
```bash
# On Thor
cd ~/shadowhound
git pull origin feature/local-llm-support

# Stop old container
docker stop vllm-server 2>/dev/null || true

# Restart with fixes
./scripts/setup_vllm_thor.sh
```

### 2. Verify tokenizer detection
Look for these in startup logs:
```
# Should NOT see:
INFO: Non-Mistral tokenizer detected when using a Mistral model...

# Should see proper model loading:
INFO: Loading model weights...
INFO: Model loaded successfully
```

### 3. Test basic completion (no tool calling)
```bash
curl -X POST http://192.168.10.116:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "mistralai/Mistral-7B-Instruct-v0.3",
    "messages": [{"role": "user", "content": "Say hello"}],
    "max_tokens": 20
  }'
```

**Expected:**
- Response within ~5 seconds
- Actual text completion
- No "Non-Mistral tokenizer" warning

### 4. Test tool calling
```bash
curl -X POST http://192.168.10.116:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "mistralai/Mistral-7B-Instruct-v0.3",
    "messages": [{"role": "user", "content": "Move forward 1 meter"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "Move",
        "description": "Move the robot",
        "parameters": {
          "type": "object",
          "properties": {
            "x": {"type": "number", "description": "Distance in meters"}
          },
          "required": ["x"]
        }
      }
    }],
    "tool_choice": "auto"
  }' | jq '.choices[0].message'
```

**Expected:**
```json
{
  "role": "assistant",
  "content": null,
  "tool_calls": [
    {
      "id": "...",
      "type": "function",
      "function": {
        "name": "Move",
        "arguments": "{\"x\": 1.0}"
      }
    }
  ]
}
```

**NOT:**
```json
{
  "content": "```json\n{\"name\": \"Move\", \"arguments\": {\"x\": 1.0}}\n```",
  "tool_calls": []  // ❌ Empty!
}
```

## Performance Expectations

With fixes applied, you should see:

```
# Good performance indicators:
INFO: Engine 000: 
  Avg prompt throughput: 50-100 tokens/s  (was 5.2!)
  Avg generation throughput: 20-40 tokens/s  (was 0.1!)
  GPU KV cache usage: 5-15%  (was 0.0%!)
```

**Typical response times:**
- Basic chat: 0.5-2 seconds
- Tool calling: 1-3 seconds
- Complex multi-tool: 3-5 seconds

## Alternative Backends (If Still Issues)

If problems persist, try different attention backends explicitly:

### Option 1: xFormers (Most Compatible)
```bash
vllm serve "${MODEL}" \
  --tokenizer "${MODEL}" \
  --attention-backend xformers \
  ...
```

### Option 2: PyTorch Native
```bash
vllm serve "${MODEL}" \
  --tokenizer "${MODEL}" \
  --attention-backend torch_sdpa \
  ...
```

## Other Potential Issues

### Model Download Incomplete
If first run was interrupted, model might be corrupted:
```bash
# Clear cache and re-download
rm -rf ~/.cache/huggingface/hub/models--mistralai--Mistral-7B-Instruct-v0.3
./scripts/setup_vllm_thor.sh
```

### Memory Fragmentation
If Thor has been running models for a while:
```bash
# Restart to clear GPU memory completely
sudo reboot
```

### Docker Shared Memory Too Small
Increase `--shm-size` if you see out-of-memory errors:
```bash
# In setup_vllm_thor.sh, change:
--shm-size=16g  # Increase to 32g if needed
```

## Monitoring

Watch vLLM logs for health indicators:
```bash
docker logs -f vllm-server 2>&1 | grep -E "(INFO|WARNING|ERROR)"
```

**Healthy signs:**
- No tokenizer warnings
- GPU cache usage >0%
- Throughput >20 tokens/s
- Requests complete <5 seconds

**Unhealthy signs:**
- "Non-Mistral tokenizer detected"
- GPU cache = 0.0%
- Throughput <10 tokens/s
- Requests timeout

## References

- vLLM Tool Calling Docs: https://docs.vllm.ai/en/stable/features/tool_calling.html
- Mistral Model Card: https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.3
- vLLM Attention Backends: https://docs.vllm.ai/en/stable/design/attention.html
- Issue: [vllm_tool_calling_not_executing](vllm_tool_calling_not_executing.md)

## Status

**Current State:** Fixes applied, awaiting testing

**Next Steps:**
1. ✅ Added `--tokenizer` flag to setup script
2. ✅ Removed FLASHINFER backend
3. ⏳ User needs to restart vLLM on Thor
4. ⏳ Test basic completion (should be fast now!)
5. ⏳ Test tool calling (should return tool_calls array!)
6. ⏳ Test robot control (should actually move!)

**Expected Outcome:** With explicit tokenizer and default attention backend, Mistral should work perfectly. Tool calling should return properly formatted function calls within 1-3 seconds.
