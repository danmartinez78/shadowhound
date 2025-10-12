# vLLM Tool Calling Configuration Issue

**Date:** October 12, 2025  
**Status:** RESOLVED ✅  
**Priority:** HIGH (blocks agent function calling)

---

## Problem

Agent fails with 400 Bad Request when trying to use tool calling:

```
INFO:httpx:HTTP Request: POST http://192.168.10.116:8000/v1/chat/completions "HTTP/1.1 400 Bad Request"
ERROR - Unexpected error in API call: Error code: 400 - {'error': {'message': '"auto" tool choice requires --enable-auto-tool-choice and --tool-call-parser to be set', 'type': 'BadRequestError', 'param': None, 'code': 400}}
```

### Context

- LocalSemanticMemory embeddings fix ✅ WORKING
- vLLM server running on Thor:8000 ✅ RESPONDING
- Agent using OpenAIAgent with function calling ✅ CONFIGURED
- **vLLM server missing tool calling flags** ❌ BLOCKING

---

## Root Cause

The vLLM server must be started with specific flags to enable tool/function calling:

```bash
vllm serve MODEL \
  --enable-auto-tool-choice \    # ← MISSING!
  --tool-call-parser hermes       # ← MISSING!
```

Without these flags, vLLM rejects requests with `tool_choice="auto"` (which OpenAI SDK sends by default when tools are provided).

### Why This Matters

DIMOS agents (OpenAIAgent, PlanningAgent) use **function calling** for robot control:
- Agent receives mission: "spin left 90 degrees"
- LLM generates function call: `SpinLeft(angle=90)`
- Agent executes skill via `MyUnitreeSkills.spin_left(90)`

Without tool calling support, **the agent cannot control the robot**.

---

## Solution

### Fix Applied

Updated `scripts/setup_vllm_thor.sh` to include tool calling flags:

```bash
# OLD (broken):
VLLM_ATTENTION_BACKEND=FLASHINFER vllm serve "$MODEL" \
  --port 8000 \
  --host 0.0.0.0 \
  --trust-remote-code \
  --max-model-len 8192 \
  --gpu-memory-utilization 0.8 \
  --tensor-parallel-size 1

# NEW (fixed):
VLLM_ATTENTION_BACKEND=FLASHINFER vllm serve "$MODEL" \
  --port 8000 \
  --host 0.0.0.0 \
  --trust-remote-code \
  --max-model-len 8192 \
  --gpu-memory-utilization 0.8 \
  --tensor-parallel-size 1 \
  --enable-auto-tool-choice \      # Enable auto tool choice
  --tool-call-parser hermes         # Use Hermes parser
```

### Deployment Steps

**On Thor:**

```bash
# 1. Stop current vLLM server (Ctrl+C)

# 2. Pull latest script
cd ~/shadowhound
git pull origin feature/local-llm-support

# 3. Restart with new flags
./scripts/setup_vllm_thor.sh
```

**On Laptop:**

```bash
# No changes needed - agent already configured correctly
# Just wait for Thor to restart, then test
./start.sh --prod
```

---

## Verification

### Test 1: Direct API Call

```bash
# From laptop - test tool calling directly
curl -X POST http://192.168.10.116:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "Qwen/Qwen2.5-Coder-7B-Instruct",
    "messages": [{"role": "user", "content": "Move forward 1 meter"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "move",
        "description": "Move the robot forward",
        "parameters": {
          "type": "object",
          "properties": {
            "distance": {"type": "number"}
          }
        }
      }
    }],
    "tool_choice": "auto"
  }'
```

**Expected:** No 400 error, response includes tool call

### Test 2: Agent Mission

```bash
# From laptop - full integration test
./start.sh --prod

# In web UI (http://localhost:8501):
# Send: "spin left 90 degrees"
```

**Expected:** 
- ✅ No 400 error in logs
- ✅ LLM generates `SpinLeft` function call
- ✅ Agent executes skill
- ✅ Robot spins left

---

## Technical Details

### Tool Call Parser Options

vLLM supports several parsers:

| Parser | Models | Quality | Speed |
|--------|--------|---------|-------|
| `hermes` | General | Good | Fast |
| `mistral` | Mistral models | Best | Fast |
| `internlm` | InternLM models | Good | Fast |

**We use `hermes`** because:
- Works with Qwen2.5-Coder-7B-Instruct ✅
- Fast and reliable ✅
- Standard format ✅

### Alternative: Mistral Parser

If you switch to Mistral models:
```bash
--tool-call-parser mistral
```

### Verification of Server Config

Check vLLM server logs to confirm flags are active:
```bash
ssh thor
docker logs vllm-server 2>&1 | grep -E "enable-auto-tool-choice|tool-call-parser"
```

Should see:
```
enable_auto_tool_choice=True
tool_call_parser=hermes
```

---

## Related Issues

- **LocalSemanticMemory import bug** - ✅ Fixed (moved import to module level)
- **Mock mode topic dependency** - ⏸️ Documented, not yet fixed
- **Start script issues** - ⏸️ Documented, prioritized

---

## Timeline

- **2025-10-12 13:21** - Error discovered during robot testing
- **2025-10-12 13:30** - Root cause identified (missing vLLM flags)
- **2025-10-12 13:35** - Fix applied to `setup_vllm_thor.sh`

---

## References

- [vLLM OpenAI Compatible Server](https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html)
- [vLLM Tool Calling Support](https://docs.vllm.ai/en/latest/features/tool_calling.html)
- [Hermes Tool Call Format](https://docs.vllm.ai/en/latest/features/tool_calling.html#hermes)
- DIMOS: `agents/agent_openai.py` - Function calling implementation

---

## Next Steps

1. ✅ Fix applied to script
2. ⏳ User restarts vLLM on Thor
3. ⏳ Test agent function calling
4. ⏳ Update vLLM quickstart docs with new flags
5. ⏳ Consider adding flag validation to start script (Issue #8)
