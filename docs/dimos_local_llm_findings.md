# DIMOS Local LLM Support - Findings and Best Practices

**Date:** October 12, 2025  
**Context:** Investigation into DIMOS local LLM + local embeddings support during ShadowHound vLLM integration

## TL;DR

- ✅ **DIMOS supports local LLMs** via `HuggingFaceLocalAgent`
- ✅ **DIMOS supports local embeddings** via `LocalSemanticMemory` (ChromaDB + sentence-transformers)
- ⚠️ **README is misleading** - Claims "OpenAI API key required for all LLMAgents" but this is NOT true
- ⚠️ **No documented examples** of using `OpenAIAgent` with vLLM + `LocalSemanticMemory`
- ⚠️ **Found and fixed bug** in `AgentMemoryConnectionError.__str__()` 

---

## Local LLM Support in DIMOS

### HuggingFaceLocalAgent

DIMOS includes `dimos/agents/agent_huggingface_local.py` which:
- Loads models locally via transformers (`AutoModelForCausalLM`)
- **Defaults to LocalSemanticMemory** (line 79): `agent_memory=agent_memory or LocalSemanticMemory()`
- Supports GPU/CPU auto-detection
- Has test examples in `tests/test_agent_huggingface_local*.py`

**Example Usage:**
```python
from dimos.agents.agent_huggingface_local import HuggingFaceLocalAgent
from dimos.agents.memory.chroma_impl import LocalSemanticMemory

agent = HuggingFaceLocalAgent(
    dev_name="MyAgent",
    model_name="Qwen/Qwen2.5-3B",
    agent_type="HF-LLM",
    system_query="You are a helpful assistant",
    agent_memory=LocalSemanticMemory(),  # Optional - this is the default
    max_output_tokens_per_request=512,
)
```

### OpenAIAgent with vLLM Backend

**ShadowHound's Novel Use Case:**

We're using `OpenAIAgent` (not `HuggingFaceLocalAgent`) with:
- vLLM serving a local model (Qwen/Qwen2.5-Coder-7B-Instruct)
- OpenAI-compatible API (via `OPENAI_BASE_URL`)
- Local embeddings via `LocalSemanticMemory`

This combination is **not documented in DIMOS** but works perfectly by:
1. Setting `OPENAI_BASE_URL` to vLLM server
2. Explicitly passing `agent_memory=LocalSemanticMemory()` to avoid OpenAI embeddings

---

## Local Embeddings Support

### LocalSemanticMemory

Implemented in `dimos/agents/memory/chroma_impl.py`:

```python
class LocalSemanticMemory(ChromaAgentSemanticMemory):
    """Uses local sentence-transformers for embeddings (no API required)"""
```

**Dependencies:**
```bash
pip install chromadb langchain-chroma langchain-openai sentence-transformers
```

**Default Model:** `sentence-transformers/all-MiniLM-L6-v2`

### OpenAISemanticMemory

Also in `chroma_impl.py`:
```python
class OpenAISemanticMemory(ChromaAgentSemanticMemory):
    """Uses OpenAI embeddings API (requires OPENAI_API_KEY)"""
```

---

## The README Misleading Claim

From `dimos-unitree/README.md`:

> **Agent API keys**
> 
> Full functionality will require API keys for the following:
> 
> Requirements: 
> - **OpenAI API key (required for all LLMAgents due to OpenAIEmbeddings)**
> - Claude API key (required for ClaudeAgent)
> - Alibaba API key (required for Navigation skills)

**This is WRONG!** 

- `HuggingFaceLocalAgent` defaults to `LocalSemanticMemory()` (no OpenAI key needed)
- Any agent can use `LocalSemanticMemory` if you pass it explicitly
- OpenAI key is only required if using `OpenAISemanticMemory`

**Why the confusion?**
- Most DIMOS examples use `OpenAIAgent` without passing `agent_memory`
- `OpenAIAgent` defaults to `OpenAISemanticMemory()` if no `agent_memory` provided
- But this is just a default, not a requirement!

---

## Test Examples in DIMOS

### With Local Agent + Local Embeddings
```python
# tests/test_agent_huggingface_local.py
agent = HuggingFaceLocalAgent(
    dev_name="HuggingFaceLLMAgent",
    model_name="Qwen/Qwen2.5-3B",
    # agent_memory defaults to LocalSemanticMemory()
)
```

### With OpenAI Agent + OpenAI Embeddings
```python
# tests/test_unitree_agent.py
agent = OpenAIAgent(
    dev_name="UnitreePerceptionAgent",
    # agent_memory defaults to OpenAISemanticMemory()
)
```

### ChromaDB Direct Usage (No Agent)
```python
# tests/test_standalone_chromadb.py
from langchain_openai import OpenAIEmbeddings
from langchain_chroma import Chroma

embeddings = OpenAIEmbeddings(
    model="text-embedding-3-large",
    api_key=OPENAI_API_KEY,
)
db_connection = Chroma(
    collection_name="my_collection",
    embedding_function=embeddings,
)
```

**Missing:** No example of `OpenAIAgent` + `LocalSemanticMemory`!

---

## Bug Found and Fixed

### AgentMemoryConnectionError.__str__() AttributeError

**Location:** `dimos/exceptions/agent_memory_exceptions.py` line 44

**Bug:**
```python
def __str__(self):
    return f"{self.message}\nCaused by: {repr(self.cause)}" if self.cause else self.message
    # ERROR: self.message doesn't exist!
```

**Why it failed:**
- Python's `Exception` class stores the message in `args[0]`, not as a `message` attribute
- When exception is converted to string (e.g., during logging), it crashes

**Fix:**
```python
def __str__(self):
    # Python Exception stores message in args[0], not as self.message attribute
    message = self.args[0] if self.args else "Unknown error"
    return f"{message}\nCaused by: {repr(self.cause)}" if self.cause else message
```

**Fixed in DIMOS commit:** cfcaa24

---

## ShadowHound Implementation Strategy

### Auto-Detection Logic

We implemented smart auto-detection in `mission_executor.py`:

```python
def _should_use_local_embeddings() -> bool:
    """Determine embeddings backend based on OPENAI_BASE_URL"""
    # 1. Explicit override
    env_value = os.getenv("USE_LOCAL_EMBEDDINGS", "").strip().lower()
    if env_value in ("true", "1", "yes"):
        return True
    if env_value in ("false", "0", "no"):
        return False
    
    # 2. Auto-detect based on backend
    base_url = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
    return "api.openai.com" not in base_url
```

**Benefits:**
- ✅ Works out-of-box for typical configs
- ✅ Supports hybrid setups (local LLM + OpenAI embeddings)
- ✅ Explicit override available for edge cases

### Graceful Fallback

We also added try-except wrapper for robustness:

```python
if use_local_embeddings:
    try:
        agent_memory = LocalSemanticMemory(
            collection_name="shadowhound_memory",
            model_name="sentence-transformers/all-MiniLM-L6-v2",
        )
    except ImportError as e:
        self.logger.warning("⚠ LocalSemanticMemory dependencies not installed")
        self.logger.warning(f"  Install with: pip install chromadb langchain-chroma...")
        agent_memory = None
    except Exception as e:
        self.logger.warning(f"⚠ Failed to initialize LocalSemanticMemory: {error_msg}")
        agent_memory = None
else:
    agent_memory = None  # OpenAIAgent will auto-create OpenAISemanticMemory
```

**Handles:**
1. Missing dependencies (chromadb, sentence-transformers)
2. DIMOS bugs or initialization failures
3. Falls back gracefully to no-RAG mode

---

## Configuration Examples

### Local LLM + Local Embeddings (vLLM)
```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
# USE_LOCAL_EMBEDDINGS auto-detected as true
```

### OpenAI Cloud + OpenAI Embeddings
```bash
AGENT_BACKEND=openai
# OPENAI_BASE_URL defaults to https://api.openai.com/v1
OPENAI_MODEL=gpt-4o
OPENAI_API_KEY=sk-...
# USE_LOCAL_EMBEDDINGS auto-detected as false
```

### Hybrid: Local LLM + OpenAI Embeddings
```bash
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
USE_LOCAL_EMBEDDINGS=false  # Explicit override
OPENAI_API_KEY=sk-...  # For embeddings only
```

---

## Lessons Learned

1. **DIMOS documentation is incomplete** - Local LLM support exists but isn't well documented
2. **Multiple paths to same goal** - Can use `HuggingFaceLocalAgent` OR `OpenAIAgent` with vLLM
3. **Always pass agent_memory explicitly** - Don't rely on defaults if you need specific behavior
4. **Embeddings are separate from LLM** - Can mix and match (local LLM + cloud embeddings, etc.)
5. **Defense-in-depth is valuable** - Keep graceful fallbacks even after fixing bugs

---

## Recommendations for DIMOS Project

If contributing back to DIMOS, consider:

1. **Update README** to clarify that OpenAI key is optional
2. **Add examples** of:
   - `OpenAIAgent` with vLLM backend
   - `OpenAIAgent` + `LocalSemanticMemory`
   - Hybrid configurations
3. **Document embedding options** more clearly
4. **Test LocalSemanticMemory** more thoroughly (we hit initialization issues)
5. **Add dependency checking** in LocalSemanticMemory with clear error messages

---

## References

- DIMOS Agent Interface: `dimos/agents/agent.py`
- HuggingFace Local Agent: `dimos/agents/agent_huggingface_local.py`
- Memory Implementations: `dimos/agents/memory/chroma_impl.py`
- Test Examples: `tests/test_agent_huggingface_local*.py`
- ShadowHound Implementation: `src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py`
