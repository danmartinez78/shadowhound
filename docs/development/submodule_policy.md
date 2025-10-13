---
tags: [development/policy, git, submodules]
status: active
related: [development/dimos_development_policy, development/dimos_branch_consolidation]
summary: >
  Git submodule management policy for ShadowHound - standard git workflow, never edit DIMOS in submodule directory.
---

# Git Submodule Policy

## Repository Management: Git Submodules (Not vcs!)

**IMPORTANT:** As of commit `fbe527e`, ShadowHound uses **standard git submodules**, not vcstool (`.repos` files).

**Why We Switched:**
- ✅ Standard git workflow (better tooling support)
- ✅ Automatic nested submodule handling (`--recursive`)
- ✅ Less confusion for AI agents and developers
- ✅ Better IDE integration (VS Code, GitHub)
- ❌ vcs was causing sync issues and headaches

**Current Configuration:**
```bash
# .gitmodules
[submodule "src/dimos-unitree"]
    path = src/dimos-unitree
    url = https://github.com/danmartinez78/dimos-unitree.git
    branch = fix/webrtc-instant-commands-and-progress
```

**Nested Submodules:**
- `src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk/` (Go2 SDK)
- `src/dimos-unitree/dimos/robot/unitree/external/go2_webrtc_connect/` (WebRTC)
- These are automatically handled with `git submodule update --init --recursive`

## CRITICAL RULE: Never Edit DIMOS Submodule Directly

### The Problem We Hit

We applied a bug fix to `src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py` which is inside a **git submodule**. This caused sync issues because:

1. The laptop host had uncommitted changes in the submodule
2. Git wouldn't let us pull updates without stashing/committing
3. The submodule changes were stuck and hard to reject
4. Error persisted even though fix was committed to GitHub
5. Led to "nuclear option" that broke Go2 SDK packages (later fixed by submodule conversion)

### The Rule

**❌ NEVER edit files in `src/dimos-unitree/` on any machine (desktop, laptop, or thor)**

**✅ ONLY edit DIMOS in its own repository:**
- Repository: https://github.com/dimensionalOS/dimos-unitree
- Fork it if you need to make changes
- Submit PRs to upstream
- Update submodule pointer in shadowhound after merge

### Why This Matters

`src/dimos-unitree/` is a **git submodule** - it's a separate git repository. When you edit files there:
- Changes are in a different repo
- They don't sync with shadowhound commits
- Git gets confused about which version to use
- Pulling updates becomes a nightmare

### Correct Workflow for DIMOS Fixes

#### Option 1: Workaround in ShadowHound (Preferred)
```python
# In shadowhound code, wrap DIMOS calls with try-except
try:
    from dimos.agents.memory.chroma_impl import LocalSemanticMemory
    agent_memory = LocalSemanticMemory()
except Exception as e:
    logger.warning(f"Failed to init DIMOS component: {e}")
    agent_memory = None  # Graceful fallback
```

**Benefits:**
- ✅ No submodule edits
- ✅ Defensive coding
- ✅ Easy to sync
- ✅ Handles future DIMOS bugs

#### Option 2: Submit PR to DIMOS (For Real Bugs)
```bash
# 1. Fork DIMOS on GitHub
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/dimos-unitree.git
cd dimos-unitree

# 3. Make your fix
git checkout -b fix/exception-bug
# Edit files...
git commit -m "Fix: Exception __str__ method"
git push origin fix/exception-bug

# 4. Submit PR to dimensionalOS/dimos-unitree

# 5. After merge, update shadowhound submodule
cd /path/to/shadowhound/src/dimos-unitree
git fetch origin
git checkout main  # or whatever branch
git pull
cd ../..
git add src/dimos-unitree
git commit -m "Update DIMOS submodule to include exception fix"
```

**Benefits:**
- ✅ Fixes upstream for everyone
- ✅ Clean git history
- ✅ No sync issues

#### Option 3: Temporary Local Patch (Last Resort)
```bash
# Only if you MUST test something locally right now
# But NEVER commit this!

cd ~/shadowhound/src/dimos-unitree
# Make temp edit
# Test
# Then immediately revert:
git checkout -- .
```

### How to Recover from Submodule Edits

If you already edited the submodule (like we did):

```bash
# On laptop host
cd /home/daniel/shadowhound/src/dimos-unitree

# Option A: Discard all changes (DESTRUCTIVE)
git reset --hard HEAD
git clean -fd

# Option B: Stash for later
git stash save "temp dimos changes"

# Option C: Commit to a branch (if you want to keep)
git checkout -b temp-fixes
git add .
git commit -m "Temp DIMOS fixes"
# Then switch back
git checkout fix/webrtc-instant-commands-and-progress  # or original branch

# Then sync submodules
cd ../..
git submodule sync
git submodule update --init --recursive
```

### Syncing Submodules After Conversion

**On laptop host after pulling the conversion:**
```bash
cd /home/daniel/shadowhound
git pull origin feature/local-llm-support  # Get fbe527e
git submodule sync                          # Update URLs
git submodule update --init --recursive     # Clone and init all

# Verify
git submodule status
ls src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk/
# Should see: go2_interfaces, unitree_go, go2_robot_sdk, etc.
```

### Current Status

**Exception Bug Fix:**
- ❌ Applied directly to laptop's DIMOS submodule (bad)
- ✅ Also committed to devcontainer's DIMOS submodule
- ⏳ Should be submitted as PR to DIMOS upstream
- ✅ Has graceful fallback in mission_executor.py (good!)

**Recommended Action:**
1. Discard DIMOS changes on laptop: `cd ~/shadowhound/src/dimos-unitree && git reset --hard HEAD`
2. Rely on the graceful fallback we added (works without fix)
3. Submit proper PR to DIMOS repo later (helps everyone)

### Scripts Location

All scripts should be in `scripts/` directory:
- ✅ `scripts/sync_laptop_host.sh` - Pull updates to laptop
- ✅ `scripts/check_laptop_changes.sh` - See what's modified
- ✅ `scripts/test_embeddings_deps.sh` - Check dependencies

### Documentation Location

All documentation should be in `docs/` with snake_case names:
- ✅ `docs/deployment_sync.md` - Sync workflow
- ✅ `docs/dimos_local_llm_findings.md` - Local LLM research
- ✅ `docs/submodule_policy.md` - This file

### Quick Reference

| Component | Edit Location | Sync Method |
|-----------|---------------|-------------|
| ShadowHound code | Desktop devcontainer | Git commit → laptop pull |
| DIMOS library | DIMOS repo (separate) | Fork → PR → Update submodule |
| Scripts | `scripts/` directory | Git commit → laptop pull |
| Docs | `docs/` directory | Git commit → laptop pull |

**Remember:** Submodules are separate repos. Treat them as read-only dependencies!

## See Also
- [[development/dimos_development_policy|DIMOS Development Policy]] — Principled workflow for DIMOS changes
- [[development/dimos_branch_consolidation|DIMOS Branch Consolidation]] — Fixing divergent branches
- [[development/development_hub|Development Index]] — Complete development documentation

## References
- [[../index|Documentation Root]]
- Git Submodules Documentation: https://git-scm.com/book/en/v2/Git-Tools-Submodules
- DIMOS Fork: https://github.com/danmartinez78/dimos-unitree

