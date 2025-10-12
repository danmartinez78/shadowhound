---
tags: [roadmap, local-llm, memory, rag]
status: active
related: []
summary: >
  Roadmap to fully local AI agent with memory (vLLM + local embeddings).
---

# Roadmap: Fully Local AI Agent with Memory

**Goal:** Robot with local LLM (vLLM) + local memory (RAG) - 100% offline capable

**Current Status:** ✅ vLLM working, ⏳ Local memory ready but not installed

---

## Phase 1: vLLM Backend ✅ COMPLETE

**What we did:**
- Set up vLLM on Thor (Jetson AGX Orin)
- Model: Qwen/Qwen2.5-Coder-7B-Instruct
- OpenAI-compatible API on port 8000
- 3.5x faster than Ollama
- HuggingFace auth configured

**Status:** ✅ Working - vLLM serving on `http://192.168.10.116:8000/v1`

---

## Phase 2: Local Embeddings Setup ⏳ IN PROGRESS

**What we need:**

### On Laptop Host

```bash
cd /home/daniel/shadowhound

# Install embeddings dependencies
pip install chromadb langchain-chroma sentence-transformers

# Verify installation
python3 scripts/test_local_embeddings.py
```

**Expected output:**
```
✅ chromadb                   - Vector database for RAG
✅ langchain_chroma           - LangChain ChromaDB integration
✅ sentence_transformers      - Local embedding models
✅ LocalSemanticMemory initialized successfully!
🎉 Ready for fully local AI agent with memory!
```

### What This Gives You

**Local Embeddings Stack:**
- **sentence-transformers/all-MiniLM-L6-v2** - 22M parameter embedding model
- **ChromaDB** - Vector database (stores locally in `~/.chroma/`)
- **LangChain** - RAG orchestration

**Capabilities:**
- ✅ Store mission history in vector DB
- ✅ Semantic search over past missions
- ✅ Context-aware responses
- ✅ Learn from experience
- ✅ 100% local (no cloud calls)

---

## Phase 3: End-to-End Testing ⏭️ NEXT

**Once embeddings installed:**

```bash
cd /home/daniel/shadowhound
./start.sh
```

**Expected logs:**
```
✓ Agent memory: LocalSemanticMemory (sentence-transformers/all-MiniLM-L6-v2)
DIMOS OpenAIAgent initialized with 5 skills
```

**Test memory:**
```python
# Give mission
"Move forward 2 meters"

# Later...
"What did I ask you to do earlier?"
# Agent should remember and respond from memory
```

---

## Architecture: Fully Local Stack

```
┌─────────────────────────────────────────────────────────┐
│  Mission Agent (Laptop)                                  │
│  ┌────────────────┐      ┌─────────────────────────┐   │
│  │ Mission Input  │ ───> │ OpenAIAgent (DIMOS)     │   │
│  └────────────────┘      │ - Query vLLM for plan   │   │
│                           │ - Search memory for ctx │   │
│                           │ - Execute skills        │   │
│                           └─────────────────────────┘   │
│                                  │        │              │
│                                  ▼        ▼              │
│                           ┌──────────┐ ┌──────────────┐ │
│                           │   vLLM   │ │LocalSemantic │ │
│                           │ (remote) │ │Memory (local)│ │
│                           └──────────┘ └──────────────┘ │
└─────────────────────────────────────────────────────────┘
              │                              │
              │                              │
              ▼                              ▼
      ┌─────────────┐              ┌──────────────────┐
      │    Thor     │              │   ChromaDB       │
      │  (Jetson)   │              │ ~/.chroma/       │
      │             │              │                  │
      │  vLLM:8000  │              │  Embeddings:     │
      │  Qwen2.5-   │              │  all-MiniLM-L6-  │
      │  Coder-7B   │              │  v2              │
      └─────────────┘              └──────────────────┘
          REMOTE                        LOCAL
          (LLM)                        (MEMORY)
```

**Key Points:**
- LLM generation: Remote (Thor GPU required)
- Embeddings: Local (CPU-friendly, fast)
- Vector DB: Local (persistent storage)
- **No internet required once models downloaded**

---

## Fallback Behavior (Current State)

**If embeddings dependencies NOT installed:**

```python
# mission_executor.py logic:
try:
    agent_memory = LocalSemanticMemory(...)  # Try local first
    ✅ Full local stack with memory
except ImportError:
    agent_memory = "skip"  # Dependencies missing
    ⚠️ Agent works but no memory (temporary state)
```

**This is safe fallback:**
- ✅ Agent still functions
- ✅ Skills still work  
- ✅ Robot still operational
- ❌ No memory (forgets between missions)

**Not a regression - just incomplete setup!**

---

## Comparison: With vs Without Memory

### Without Memory (Current Laptop State)

```
User: "Move forward 2 meters"
Agent: [Executes mission, forgets]

User: "What did I just ask?"
Agent: [No context, can't remember]
```

### With Memory (After Installing Dependencies)

```
User: "Move forward 2 meters"
Agent: [Executes mission, stores in ChromaDB]

User: "What did I just ask?"
Agent: [Searches memory] "You asked me to move forward 2 meters"

User: "Do it again"
Agent: [Understands from context] [Executes same mission]
```

---

## Dependencies Status

### Already in Requirements ✅

These are in `.dimos-base-requirements.txt`:
- ✅ `chromadb>=0.4.22`
- ✅ `langchain-chroma>=0.1.4`
- ✅ `sentence-transformers>=2.2.0`

### Installation Status by Machine

**Desktop (Devcontainer):**
- Status: Unknown (doesn't run agent)
- Action: Not needed (editing only)

**Laptop Host:**
- Status: ❓ Need to check
- Action: `pip install chromadb langchain-chroma sentence-transformers`
- Test: `python3 scripts/test_local_embeddings.py`

**Thor (Jetson):**
- Status: Not needed (only runs vLLM)
- Action: None

---

## Next Steps

### Immediate (Today)

1. **Pull latest code on laptop:**
   ```bash
   cd /home/daniel/shadowhound
   git pull origin feature/local-llm-support
   ```

2. **Test embeddings status:**
   ```bash
   python3 scripts/test_local_embeddings.py
   ```

3. **If missing, install:**
   ```bash
   pip install chromadb langchain-chroma sentence-transformers
   ```

4. **Clean rebuild:**
   ```bash
   rm -rf build/ install/ log/
   ./start.sh
   ```

5. **Verify logs show:**
   ```
   ✓ Agent memory: LocalSemanticMemory (sentence-transformers/all-MiniLM-L6-v2)
   ```

### Short-term (This Week)

- Test memory functionality with real missions
- Verify memory persists across restarts
- Tune RAG parameters (similarity threshold, etc.)
- Test mission context understanding

### Long-term (Ongoing)

- Expand memory with more context types
- Add vision embeddings (CLIP) for image memory
- Implement memory pruning (forget old missions)
- Multi-modal memory (text + images)

---

## FAQ

### Q: Why separate vLLM (remote) and embeddings (local)?

**A:** Different requirements:
- **vLLM (text generation):** GPU-heavy, benefits from Jetson's GPU
- **Embeddings:** CPU-friendly, small model (22M params), runs fine on laptop
- Keeps laptop responsive while leveraging Thor's GPU

### Q: What if ChromaDB has issues?

**A:** Agent falls back gracefully:
- Still uses vLLM for planning
- Still executes skills
- Just no memory (forgets between missions)
- No crash, no data loss

### Q: Can we use Thor for embeddings too?

**A:** Possible but unnecessary:
- Embeddings are fast on CPU (~5ms per embedding)
- Would add network latency (~10-20ms)
- Local is actually faster!
- Keeps Thor focused on LLM generation

### Q: What's stored in memory?

**A:** Mission context:
- User commands
- Agent responses
- Skill executions
- Success/failure outcomes
- Timestamps
- Semantic embeddings for search

---

## Success Criteria

**Phase 2 Complete When:**
- [ ] Dependencies installed on laptop
- [ ] `test_local_embeddings.py` passes
- [ ] Agent logs show LocalSemanticMemory initialized
- [ ] No embeddings errors in agent startup

**Phase 3 Complete When:**
- [ ] Agent remembers previous missions
- [ ] Context-aware responses work
- [ ] Memory persists across restarts
- [ ] No cloud API calls (100% local)

---

## Related Documentation

- **Embeddings Auto-Detection:** Auto-detects local vs cloud based on OPENAI_BASE_URL
- **DIMOS Memory:** Uses chromadb for vector storage
- **.env Configuration:** Already set up for vLLM + local embeddings

---

**TL;DR:** We're not moving backwards! The code is designed for fully local memory. We just need to install the dependencies. The fallback is temporary and safe. Once dependencies are installed, we'll have fully local AI with memory! 🚀
