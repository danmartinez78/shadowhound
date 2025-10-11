# Ollama Model Selection Guide

## Tool/Function Calling Support

Shadow Hound's planning agent requires **function calling** (also known as **tool use**) support from the LLM. This is critical because the agent needs to:

1. Parse structured robot skill calls
2. Generate JSON-formatted skill parameters
3. Chain multiple skills together in a plan

## Ollama Models with Function Calling

### ✅ Recommended Models (Tested)

| Model | Size | Tool Support | Notes |
|-------|------|--------------|-------|
| **qwen2.5-coder:32b** | 19GB | ✅ Excellent | Best choice for robotics, strong function calling |
| **llama3.3:70b** | 43GB | ✅ Good | Large but capable, requires more VRAM |
| **deepseek-r1:7b** | 4.7GB | ⚠️ Experimental | Smaller, may have limitations |

### ❌ Models Without Function Calling

| Model | Size | Tool Support | Notes |
|-------|------|--------------|-------|
| **phi4:14b** | 9GB | ❌ No | Reasoning-focused, no function calling training |
| **llama3.2:3b** | 2GB | ❌ No | Too small |
| **phi3:3.8b** | 2.3GB | ❌ No | Chat only |

## How to Check Tool Support

### Method 1: Test with curl

```bash
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_NAME",
    "messages": [{"role": "user", "content": "test"}],
    "tools": [{"type": "function", "function": {"name": "test", "description": "test"}}],
    "stream": false
  }'
```

**Expected responses:**
- ✅ **200 OK**: Model supports tools
- ❌ **400 Bad Request** with `"does not support tools"`: No tool support

### Method 2: Check Ollama Model Card

```bash
docker exec ollama ollama show MODEL_NAME
```

Look for mentions of:
- "function calling"
- "tool use"  
- "structured output"

## Configuration

### For Planning Agent (Requires Tools)

```bash
# .env
AGENT_BACKEND=ollama
OLLAMA_MODEL=qwen2.5-coder:32b
USE_PLANNING_AGENT=true  # Requires function calling
```

### For Simple Agent (No Tools Needed)

```bash
# .env
AGENT_BACKEND=ollama
OLLAMA_MODEL=phi4:14b  # Can use non-tool models
USE_PLANNING_AGENT=false  # Text-only responses
```

## Performance Benchmarking Targets

Based on tool support, focus benchmarking on:

1. **qwen2.5-coder:32b** - Primary target
2. **llama3.3:70b** - High capability baseline
3. **deepseek-r1:7b** - Resource-constrained option

### Benchmark Metrics

For each model, measure:

- **Latency**: Time to first token, total completion time
- **Accuracy**: Correct skill selection, parameter extraction
- **Resource Usage**: GPU VRAM, CPU load
- **Reliability**: Success rate, error handling

### Test Cases

1. **Simple navigation**: "Go forward 5 meters"
2. **Multi-step**: "Go to waypoint A, turn around, take a photo"
3. **Complex reasoning**: "Find the red object and approach it"
4. **Error handling**: Invalid requests, out-of-bounds coordinates

## Known Limitations

### Phi4:14b
- ❌ Cannot use with planning agent
- ✅ Can use with simple agent (USE_PLANNING_AGENT=false)
- Strong at reasoning, weak at structured output

### Qwen2.5-Coder:32b
- ✅ Excellent function calling
- ⚠️ Requires ~20GB VRAM
- May be slower than smaller models

### LLaMA3.3:70b
- ✅ Very capable
- ❌ Requires ~50GB VRAM (may need multiple GPUs or high quantization)
- Better for high-stakes missions

## Future Work

See shadowhound#12 for vLLM evaluation, which may improve:
- Batching efficiency
- Multi-model serving
- Quantization options

## References

- [OpenAI Function Calling Docs](https://platform.openai.com/docs/guides/function-calling)
- [Ollama Model Library](https://ollama.com/library)
- Issue dimos-unitree#1: Proper tokenizer mapping for local models
