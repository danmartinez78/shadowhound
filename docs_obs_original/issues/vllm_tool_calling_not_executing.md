# vLLM Tool Calling Returns JSON String Instead of Executing

**Date:** October 12, 2025  
**Status:** INVESTIGATING 🔍  
**Priority:** CRITICAL (blocks robot control)

---

## Problem

The agent receives correct function call JSON from the LLM, but it's returned as a **markdown string** instead of being executed as a tool call.

### Observed Behavior

```
> take a small step back please
✅ SUCCESS: ```json {"name": "Reverse", "arguments": {"x": -0.1, "y": 0.0, "yaw": 0.0, "duration": 2.0}} ```
```

**Robot does NOT move** - the JSON is just displayed as text.

### Expected Behavior

```
> take a small step back please
[Calling function: Reverse(x=-0.1, y=0.0, yaw=0.0, duration=2.0)]
[Function result: Success - moved back 0.1m]
✅ SUCCESS: I've moved back a small step as requested.
```

**Robot moves** - function is executed, result is used in response.

---

## Root Cause Analysis

The LLM is generating function call **JSON as text** instead of making an **OpenAI-format tool call**. This suggests one of:

### 1. vLLM Tool Parser Not Working

Even though we added `--tool-call-parser hermes`, the parser may not be correctly formatting tool calls for Qwen2.5-Coder-7B-Instruct.

**Check:** Look at vLLM server logs for tool call parsing messages

### 2. Model Doesn't Support Tool Calling Format

Qwen2.5-Coder-7B-Instruct may not have been trained with Hermes tool calling format.

**Check:** Test with a known tool-calling model like `mistralai/Mistral-7B-Instruct-v0.3`

### 3. System Prompt Issue

The system prompt may be instructing the model to return JSON instead of making tool calls.

**Check:** Review mission_executor.py system prompt

### 4. DIMOS Not Receiving Tool Calls

vLLM may be formatting tool calls correctly, but they're not being passed through in the OpenAI-compatible response format.

**Check:** Log the raw response from vLLM before DIMOS processes it

---

## Diagnostic Steps

### Step 1: Check vLLM Server Logs

```bash
ssh thor
docker logs vllm-server 2>&1 | grep -i "tool\|function"
```

Look for:
- `enable_auto_tool_choice=True` ✅
- `tool_call_parser=hermes` ✅  
- Tool parsing errors ❌
- Function call processing ❓

### Step 2: Test Direct vLLM API

```bash
# From laptop - test tool calling directly
curl -X POST http://192.168.10.116:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "Qwen/Qwen2.5-Coder-7B-Instruct",
    "messages": [
      {"role": "system", "content": "You are a helpful robot assistant."},
      {"role": "user", "content": "Move forward 1 meter"}
    ],
    "tools": [{
      "type": "function",
      "function": {
        "name": "Move",
        "description": "Move the robot forward",
        "parameters": {
          "type": "object",
          "properties": {
            "x": {"type": "number", "description": "Distance in meters"},
            "y": {"type": "number"},
            "yaw": {"type": "number"},
            "duration": {"type": "number"}
          },
          "required": ["x", "y", "yaw", "duration"]
        }
      }
    }],
    "tool_choice": "auto"
  }' | jq .
```

**Expected response format (if working):**
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "tool_calls": [{
        "id": "call_xxx",
        "type": "function",
        "function": {
          "name": "Move",
          "arguments": "{\"x\": 1.0, \"y\": 0.0, \"yaw\": 0.0, \"duration\": 3.0}"
        }
      }]
    }
  }]
}
```

**Actual response format (if broken):**
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "```json {\"name\": \"Move\", \"arguments\": {...}} ```"
    }
  }]
}
```

### Step 3: Add Response Logging in Mission Executor

```python
# In mission_executor.py, line 432
response = self.agent.run_observable_query(command).run()

# ADD THIS BEFORE:
self.logger.info(f"DEBUG: Raw agent response type: {type(response)}")
self.logger.info(f"DEBUG: Raw agent response: {response}")
```

This will show what DIMOS is actually receiving.

### Step 4: Check DIMOS Tool Call Processing

```python
# In mission_executor.py, after agent initialization
self.logger.info(f"Agent skill library tools: {self.agent.skill_library.get_tools()}")
```

This verifies skills are registered correctly.

---

## Possible Solutions

### Solution 1: Use Different Tool Parser

Try `internlm` or `mistral` parser instead of `hermes`:

```bash
# In setup_vllm_thor.sh
--tool-call-parser internlm  # or mistral
```

### Solution 2: Use Tool-Calling Specific Model

Switch to a model known to work with tool calling:

```bash
# Mistral 7B (has native tool calling support)
MODEL="mistralai/Mistral-7B-Instruct-v0.3"
--tool-call-parser mistral

# Or Hermes 2 Pro (designed for tool calling)
MODEL="NousResearch/Hermes-2-Pro-Llama-3-8B"
--tool-call-parser hermes
```

### Solution 3: Add Tool Calling Instructions to System Prompt

```python
# In mission_executor.py, add to system_query:
system_query = """
You are a robot control agent with access to movement skills.

CRITICAL: When the user asks you to perform an action, you MUST use the provided tools/functions.
DO NOT describe the action or return JSON. CALL THE FUNCTION DIRECTLY.

Available skills:
- Move(x, y, yaw, duration): Move forward
- Reverse(x, y, yaw, duration): Move backward
- SpinLeft(angle): Rotate left
- SpinRight(angle): Rotate right
- Wait(duration): Pause
"""
```

### Solution 4: Enable vLLM Guided Decoding

Add `--guided-decoding-backend` flag to force proper tool call format:

```bash
vllm serve ... \
  --enable-auto-tool-choice \
  --tool-call-parser hermes \
  --guided-decoding-backend outlines  # Force structured output
```

---

## Model Compatibility Matrix

| Model | Tool Parser | Status | Notes |
|-------|-------------|--------|-------|
| Qwen2.5-Coder-7B-Instruct | hermes | ❓ Testing | May need different parser |
| Qwen2.5-Coder-7B-Instruct | internlm | ⏳ Try next | Better for Qwen models |
| Mistral-7B-Instruct-v0.3 | mistral | ✅ Known good | Native tool support |
| Hermes-2-Pro-Llama-3-8B | hermes | ✅ Known good | Designed for tools |

---

## References

- [vLLM Tool Calling Docs](https://docs.vllm.ai/en/latest/features/tool_calling.html)
- [Hermes Tool Format](https://huggingface.co/NousResearch/Hermes-2-Pro-Llama-3-8B#prompt-format-for-function-calling)
- [Qwen2.5 Function Calling](https://qwen.readthedocs.io/en/latest/framework/function_call.html)
- DIMOS: `dimos/agents/agent.py` line 310-350 - Tool execution logic

---

## Next Steps

1. ⏳ Check vLLM logs for tool parsing errors
2. ⏳ Test direct API call with tools (curl command above)
3. ⏳ Try `--tool-call-parser internlm` (may work better with Qwen)
4. ⏳ If still broken, switch to Hermes-2-Pro model (known to work)
5. ⏳ Add response logging to debug what format we're receiving
