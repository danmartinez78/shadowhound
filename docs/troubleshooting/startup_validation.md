---
tags: [troubleshooting/validation, llm, diagnostics]
status: active
related: []
summary: >
  Two-layer LLM backend validation system - pre-flight checks in start.sh and runtime validation in mission agent.
---

# Startup Validation Flow

## Overview

ShadowHound now has **two layers of LLM backend validation** to ensure reliable operation and fast failure detection.

## Two-Layer Validation

### Layer 1: Start Script Pre-Flight Check (`start.sh`)
**When**: Early in startup sequence, before any heavy initialization  
**Purpose**: Fail fast and save time

**Runs BEFORE**:
- Workspace build
- Dependency checks
- Robot driver launch
- Nav2 initialization

**What it checks**:

#### Ollama Backend
1. ✅ Service reachability (5s timeout)
2. ✅ Model availability (is model pulled?)
3. ✅ Test prompt (30s timeout)

#### OpenAI Backend
1. ✅ API key present
2. ✅ API key format check (starts with `sk-`)

**Example output**:
```bash
── LLM Backend Check ──────────────────────────────────────────
ℹ Configured backend: ollama
ℹ Ollama URL: http://192.168.50.10:11434
ℹ Ollama Model: qwen2.5-coder:32b

ℹ 1. Checking Ollama service reachability...
✓ Ollama service responding
ℹ 2. Checking if model 'qwen2.5-coder:32b' is available...
✓ Model 'qwen2.5-coder:32b' is available
ℹ 3. Testing model response (this may take a few seconds)...
✓ Model responded successfully (3s)
ℹ Response: OK

✓ Ollama backend validation passed!
```

**Time saved on failure**: 30-60 seconds (no robot driver launch, no Nav2 init)

### Layer 2: Mission Agent Validation (`mission_agent.py`)
**When**: During mission agent initialization  
**Purpose**: Authoritative validation before accepting missions

**Runs AFTER**:
- MissionExecutor initialization
- DIMOS robot/skills setup

**What it checks**:

#### Ollama Backend
1. ✅ Service responding
2. ✅ Model available
3. ✅ Test prompt succeeds

#### OpenAI Backend
1. ✅ API key present
2. ✅ Test prompt to OpenAI API

**Example output**:
```bash
============================================================
🔍 VALIDATING LLM BACKEND CONNECTION
============================================================
Testing ollama backend...
  URL: http://192.168.50.10:11434
  Model: qwen2.5-coder:32b
  Checking Ollama service...
  ✅ Ollama service responding
  ✅ Model 'qwen2.5-coder:32b' available
  Sending test prompt...
  ✅ Test prompt succeeded (response: 'OK')
============================================================
✅ Ollama backend validation PASSED
============================================================
```

**Fail behavior**: Node exits with RuntimeError and clear error message

## Why Two Layers?

### Start Script Validation (Layer 1)
**Pros**:
- ✅ Catches issues **before** heavy system initialization
- ✅ Saves 30-60s by failing fast
- ✅ Better UX - user doesn't wait through driver launch
- ✅ Can continue on failure (user choice)

**Cons**:
- ⚠️ Not authoritative (mission agent can still fail)
- ⚠️ Adds 2-5s to startup (but saves 30-60s on failure)

### Mission Agent Validation (Layer 2)
**Pros**:
- ✅ Authoritative check - runs in mission agent context
- ✅ Validates actual LLM client initialization
- ✅ Cannot be bypassed
- ✅ Runs every time, even if start.sh skipped

**Cons**:
- ⚠️ Happens after system initialization (later in sequence)

## Startup Sequence

```
./start.sh
  ↓
1. System checks (ROS2, Python, colcon)
  ↓
2. Git updates check
  ↓
3. Configuration setup (.env loading)
  ↓
4. 🔍 LLM Backend Validation ← EARLY CHECK (Layer 1)
  ↓                              Fails fast, saves time
5. Workspace build
  ↓
6. Dependency checks
  ↓
7. Network checks
  ↓
8. Robot driver launch (30s)
  ↓
9. Nav2 initialization (15s)
  ↓
10. Mission agent launch
  ↓
11. MissionExecutor initialization
  ↓
12. 🔍 Backend Validation ← AUTHORITATIVE (Layer 2)
  ↓                         Final check before accepting missions
13. Ready to accept missions!
```

## Failure Scenarios

### Scenario 1: Ollama Service Down

**Layer 1** (start.sh):
```
✗ Cannot reach Ollama service at http://192.168.50.10:11434

Possible issues:
  • Ollama service not running
  • Wrong URL (check OLLAMA_BASE_URL in .env)
  • Network/firewall blocking connection
  • Thor not powered on (if using remote Ollama)

To fix:
  • Check Ollama status: docker ps | grep ollama
  • Test manually: curl http://192.168.50.10:11434/api/tags
  • Update .env with correct OLLAMA_BASE_URL

Continue anyway? (Mission agent will fail) [y/N]:
```

**User saved**: 30-60s (no robot driver/Nav2 launch)

### Scenario 2: Model Not Pulled

**Layer 1** (start.sh):
```
✓ Ollama service responding
✗ Model 'qwen2.5-coder:32b' not found in Ollama

Available models:
  • llama3.1:70b
  • phi4:14b
  • qwen2.5:14b

To fix:
  • Pull the model: ollama pull qwen2.5-coder:32b
  • Or update OLLAMA_MODEL in .env to use an available model

Continue anyway? (Mission agent will fail) [y/N]:
```

**User saved**: 30-60s

### Scenario 3: OpenAI Key Missing

**Layer 1** (start.sh):
```
✗ OPENAI_API_KEY not set in environment

To fix:
  • Add OPENAI_API_KEY to .env file
  • Get API key from: https://platform.openai.com/api-keys
```

**User saved**: 30-60s + clearer error message

### Scenario 4: Backend Reachable but Misconfigured

**Layer 1** passes (service is up, model exists)  
**Layer 2** fails (e.g., model incompatible with DIMOS)

Mission agent catches the actual runtime issue:
```
[ERROR] [mission_agent]: LLM backend validation failed
[ERROR] Model initialization failed: <specific error>
```

This is OK - Layer 2 provides final authoritative validation.

## Configuration

### Environment Variables

Set in `.env` file:

```bash
# Backend selection
AGENT_BACKEND=ollama  # or 'openai'

# Ollama configuration
OLLAMA_BASE_URL=http://192.168.50.10:11434
OLLAMA_MODEL=qwen2.5-coder:32b

# OpenAI configuration
OPENAI_API_KEY=sk-proj-...
OPENAI_MODEL=gpt-4o
```

### Skipping Validation

**Not recommended**, but if you need to bypass for testing:

#### Skip start.sh validation
Comment out the check in `start.sh`:
```bash
# check_llm_backend  # Skipped for testing
```

#### Skip mission agent validation
Comment out in `mission_agent.py`:
```python
# if not self._validate_llm_backend():
#     raise RuntimeError(...)
```

⚠️ **Warning**: Skipping validation can lead to cryptic runtime errors.

## Performance Impact

### Layer 1 (start.sh)
- **Success case**: +2-5s startup time
- **Failure case**: Saves 30-60s by failing fast

**Net benefit**: Saves 25-55s on misconfiguration

### Layer 2 (mission_agent)
- **Always runs**: +2-5s agent initialization
- **Provides**: Authoritative validation, cannot be bypassed

**Total overhead**: 4-10s (acceptable for reliability gain)

## Testing Validation

### Test start.sh validation
```bash
# Test with unreachable backend
OLLAMA_BASE_URL=http://192.168.99.99:11434 ./start.sh

# Test with missing model
OLLAMA_MODEL=nonexistent-model ./start.sh

# Test OpenAI without key
unset OPENAI_API_KEY
AGENT_BACKEND=openai ./start.sh
```

### Test mission agent validation
```bash
# Launch mission agent directly (skips start.sh)
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    agent_backend:=ollama \
    ollama_base_url:=http://192.168.99.99:11434

# Should fail with clear error message
```

## Related Documentation

- **Backend Validation**: `docs/LLM_BACKEND_VALIDATION.md`
- **Implementation Summary**: `docs/BACKEND_VALIDATION_SUMMARY.md`
- **Deployment Checklist**: `docs/OLLAMA_DEPLOYMENT_CHECKLIST.md`

## Commits

- Layer 1 (start.sh): `0b22643` - Early validation in start script
- Layer 2 (mission_agent): `ef0138e` - Automatic validation on startup

---

**Last Updated**: 2025-10-10  
**Status**: ✅ Implemented and tested
