# Embeddings Auto-Detection

The ShadowHound mission agent intelligently selects the appropriate embeddings backend based on your configuration.

## How It Works

The agent uses this decision tree:

```
1. Check USE_LOCAL_EMBEDDINGS environment variable
   ├─ If "true" → Use LocalSemanticMemory (sentence-transformers)
   ├─ If "false" → Use OpenAISemanticMemory (OpenAI API)
   └─ If not set → Auto-detect based on OPENAI_BASE_URL
      ├─ Contains "api.openai.com" → Use OpenAI embeddings
      └─ Other URL (local LLM) → Use local embeddings
```

## Configuration Examples

### vLLM on Thor (Auto-detected)

```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
# No USE_LOCAL_EMBEDDINGS needed - auto-detects local LLM
```

**Result:** 
```
Embeddings: Auto-detected local LLM backend (openai), using local embeddings
✓ Agent memory: LocalSemanticMemory (sentence-transformers/all-MiniLM-L6-v2)
```

### OpenAI Cloud (Auto-detected)

```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o-mini
OPENAI_API_KEY=sk-proj-your-real-key
# No USE_LOCAL_EMBEDDINGS needed - auto-detects OpenAI cloud
```

**Result:**
```
Embeddings: Auto-detected OpenAI cloud, using OpenAI embeddings API
✓ Agent memory: OpenAISemanticMemory (text-embedding-3-large)
```

### Explicit Override (vLLM with OpenAI embeddings)

If you want to use vLLM for chat but OpenAI cloud for embeddings:

```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1  # vLLM for chat
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
USE_LOCAL_EMBEDDINGS=false  # Force OpenAI embeddings
OPENAI_API_KEY=sk-proj-your-real-key  # For embeddings API
```

**Result:**
```
Embeddings: Using explicit setting USE_LOCAL_EMBEDDINGS=False
✓ Agent memory: OpenAISemanticMemory (text-embedding-3-large)
```

**Note:** This configuration makes separate API calls - vLLM for chat, OpenAI for embeddings.

### Explicit Override (OpenAI with local embeddings)

If you want to use OpenAI cloud for chat but local embeddings (save costs):

```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=https://api.openai.com/v1  # OpenAI for chat
OPENAI_MODEL=gpt-4o-mini
USE_LOCAL_EMBEDDINGS=true  # Force local embeddings (free!)
OPENAI_API_KEY=sk-proj-your-real-key
```

**Result:**
```
Embeddings: Using explicit setting USE_LOCAL_EMBEDDINGS=True
✓ Agent memory: LocalSemanticMemory (sentence-transformers/all-MiniLM-L6-v2)
```

## Supported Backends

| Backend | Base URL Pattern | Default Embeddings | Override Possible |
|---------|-----------------|-------------------|-------------------|
| **OpenAI Cloud** | `api.openai.com` | OpenAI embeddings | ✅ Can use local |
| **vLLM** | `192.168.x.x:8000` | Local embeddings | ✅ Can use OpenAI* |
| **llama.cpp** | `192.168.x.x:8080` | Local embeddings | ✅ Can use OpenAI* |
| **Ollama** | `localhost:11434` | Local embeddings | ✅ Can use OpenAI* |

*Requires valid `OPENAI_API_KEY` for embeddings API calls

## When to Use Local Embeddings

✅ **Recommended for:**
- Local LLM backends (vLLM, llama.cpp, Ollama)
- Cost-sensitive deployments
- Offline/air-gapped environments
- Privacy-sensitive applications

**Trade-offs:**
- Free (no API costs)
- Works offline
- Slightly lower quality than OpenAI's embeddings
- First run downloads ~80MB model

## When to Use OpenAI Embeddings

✅ **Recommended for:**
- OpenAI cloud backend (automatic)
- Highest embedding quality needed
- Already paying for OpenAI API

**Trade-offs:**
- Small cost (~$0.13 per 1M tokens)
- Requires internet connection
- Higher quality embeddings

## Troubleshooting

### "ValueError: No embedding data received"

This error occurs when the agent tries to call embeddings API on a backend that doesn't support it.

**Solution:** The auto-detection should prevent this. If it happens:
1. Check your `OPENAI_BASE_URL` - is it pointing to a local LLM?
2. Force local embeddings: `USE_LOCAL_EMBEDDINGS=true`
3. Rebuild: `colcon build --packages-select shadowhound_mission_agent`

### Embeddings are slow

If using local embeddings and first run is slow:
- It's downloading the `sentence-transformers/all-MiniLM-L6-v2` model (~80MB)
- Subsequent runs will be fast (model is cached)

If using OpenAI embeddings and slow:
- Check your internet connection
- Consider switching to local embeddings (set `USE_LOCAL_EMBEDDINGS=true`)

## Implementation Details

The auto-detection logic is in `mission_executor.py`:

```python
# 1. Check explicit setting
use_local_env = os.getenv("USE_LOCAL_EMBEDDINGS", "").lower()
if use_local_env in ("true", "false"):
    use_local_embeddings = use_local_env == "true"
else:
    # 2. Auto-detect based on base URL
    is_openai_cloud = (
        agent_backend == "openai" and 
        "api.openai.com" in openai_base_url
    )
    use_local_embeddings = not is_openai_cloud

# 3. Create appropriate memory backend
if use_local_embeddings:
    agent_memory = LocalSemanticMemory(...)
else:
    agent_memory = None  # Use default OpenAISemanticMemory
```

This ensures the right embeddings backend is always used, with smart defaults and explicit override capability.
