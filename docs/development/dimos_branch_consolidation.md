---
tags: [development/policy, dimos, git]
status: active
related: [development/submodule_policy, development/dimos_development_policy]
summary: >
  Plan to consolidate divergent DIMOS branches and establish principled workflow.
---

# DIMOS Branch Consolidation Plan

## Problem Statement

**Date:** October 12, 2025  
**Issue:** Divergent branches in dimos-unitree submodule

We currently have two divergent branches in the dimos-unitree fork:

1. **`dev`** (merged PRs)
   - Logger initialization improvements (#6)
   - Tokenizer factory with Ollama support (#2)
   - Merged to dev, ready for main

2. **`fix/webrtc-instant-commands-and-progress`** (ShadowHound submodule)
   - WebRTC command queue fixes
   - Go2 SDK updates (reverted then re-updated)
   - Quick fallback tokenizer (different approach)
   - Navigation skill reductions (temp for testing)
   - Planning agent defensive fixes

**Root Cause:** We worked on DIMOS directly in two contexts:
- PRs merged to dev (proper workflow)
- Quick fixes on feature branch (for ShadowHound integration)

## Commits Analysis

### On dev but NOT on fix/webrtc:
```
7d9a45e Merge pull request #6 (logger initialization)
41a40d1 Move logger initialization to module level
0e641fe Merge pull request #2 (tokenizer factory)
de2cda3 Implement tokenizer factory with Ollama support
```

### On fix/webrtc but NOT on dev:
```
e73cc86 Temp: Reduce to 5 nav2 skills (testing)
19812a4 Defensive: Ensure current_plan is always a list
0507511 Fix: PlanningAgentResponse content type
1e31858 Quick fix: Add fallback tokenizer (different approach)
4addfbc Skip models directory during build
3c0bc01 Revert go2_ros2_sdk to 6c0551b
27d2ea2 Fix: Use go2_interfaces.msg
1d2a68d Update go2_ros2_sdk to latest robodan_dev
7538e0f Fix WebRTC command queue (IMPORTANT!)
```

## Consolidation Strategy

### Option 1: Rebase fix/webrtc onto dev (Recommended)

**Benefits:**
- ✅ Preserves all work from both branches
- ✅ Linear history
- ✅ Tokenizer factory from dev + fixes from fix/webrtc
- ✅ Can submit consolidated PR to upstream DIMOS

**Steps:**
```bash
cd /workspaces/shadowhound/src/dimos-unitree

# 1. Fetch latest
git fetch origin

# 2. Create backup branch
git branch backup-fix-webrtc fix/webrtc-instant-commands-and-progress

# 3. Rebase onto dev
git checkout fix/webrtc-instant-commands-and-progress
git rebase origin/dev

# 4. Resolve conflicts (if any)
# - Tokenizer: Keep factory from dev, remove fallback from fix/webrtc
# - Logger: Already in dev
# - Keep all other fixes from fix/webrtc

# 5. Test the consolidated branch
cd /workspaces/shadowhound
rm -rf build/ install/ log/
./start.sh

# 6. Push consolidated branch
cd src/dimos-unitree
git push origin fix/webrtc-instant-commands-and-progress --force-with-lease

# 7. Update ShadowHound submodule pointer
cd /workspaces/shadowhound
git add src/dimos-unitree
git commit -m "Update DIMOS submodule to consolidated branch (rebased on dev)"
git push origin feature/local-llm-support
```

### Option 2: Merge dev into fix/webrtc

**Benefits:**
- ✅ Simpler (no rebase)
- ✅ Preserves exact history

**Drawbacks:**
- ❌ Merge commit in history
- ❌ Less clean for upstream PR

**Steps:**
```bash
cd /workspaces/shadowhound/src/dimos-unitree
git checkout fix/webrtc-instant-commands-and-progress
git merge origin/dev
# Resolve conflicts
git push origin fix/webrtc-instant-commands-and-progress
```

### Option 3: Create new unified branch

**Benefits:**
- ✅ Clean slate
- ✅ Cherry-pick only what's needed

**Steps:**
```bash
cd /workspaces/shadowhound/src/dimos-unitree
git checkout -b feature/local-llm-integration origin/dev
git cherry-pick 7538e0f  # WebRTC fixes
git cherry-pick 27d2ea2  # go2_interfaces fix
git cherry-pick 0507511  # PlanningAgentResponse fix
git cherry-pick 19812a4  # current_plan defensive fix
# Skip: e73cc86 (temp testing reduction)
# Skip: 1e31858 (fallback tokenizer - use factory from dev)
# Skip: SDK reverts (handled by new branch)
```

## Recommended Approach: Option 1 (Rebase)

This gives us:
1. Logger initialization improvements (from dev)
2. Tokenizer factory (from dev) - better than fallback
3. WebRTC command queue fixes (from fix/webrtc)
4. Planning agent defensive fixes (from fix/webrtc)
5. Go2 SDK updates (from fix/webrtc)
6. Clean history for upstream PR

## Conflict Resolution Guide

### Expected Conflicts

**1. Tokenizer Implementation**
- **dev:** Full factory pattern in `dimos/agents/openai_agent.py`
- **fix/webrtc:** Quick fallback in same file
- **Resolution:** Keep dev's factory, remove fix/webrtc's fallback

**2. Logger Initialization**
- **dev:** Module-level logger
- **fix/webrtc:** May have different logger calls
- **Resolution:** Keep dev's approach

**3. Navigation Skills**
- **fix/webrtc:** Reduced to 5 skills (temp for testing)
- **Resolution:** Keep full skill set, remove temp reduction

### Conflict Resolution Commands

```bash
# During rebase, if conflict:
git status  # See conflicted files

# For each file:
vim <file>  # Resolve conflicts
git add <file>

# Continue rebase
git rebase --continue

# If stuck:
git rebase --abort  # Start over
```

## Post-Consolidation Cleanup

After consolidation:

1. **Remove temp/testing commits:**
   ```bash
   # Interactive rebase to remove e73cc86 (skill reduction)
   git rebase -i origin/dev
   # Mark e73cc86 as 'drop' or 'squash'
   ```

2. **Update commit messages:**
   ```bash
   # Make commit messages more descriptive
   git rebase -i origin/dev
   # Mark commits for 'reword'
   ```

3. **Test thoroughly:**
   ```bash
   cd /workspaces/shadowhound
   rm -rf build/ install/ log/
   ./start.sh
   # Test vLLM integration
   # Test WebRTC commands
   # Test mission agent
   ```

4. **Submit PR to upstream DIMOS:**
   ```bash
   # After testing, create PR from fix/webrtc to DIMOS dev
   # Title: "Fix: WebRTC instant commands + local LLM support"
   # Body: List all fixes, reference shadowhound issues
   ```

## Future Policy: DIMOS Development Workflow

See `docs/dimos_development_policy.md` (to be created)

### Core Principles

1. **Never work directly on DIMOS submodule in ShadowHound repo**
2. **Always create PRs in dimos-unitree repository first**
3. **Update submodule pointer only after PR is merged**
4. **Use workarounds in ShadowHound when DIMOS bugs found**

### Workflow

```
1. Find issue in DIMOS
   ↓
2. Create issue in dimos-unitree repo
   ↓
3. Create branch in dimos-unitree repo (not submodule!)
   ↓
4. Make fix, test, commit
   ↓
5. Submit PR to dimos-unitree dev branch
   ↓
6. After merge: Update ShadowHound submodule pointer
   ↓
7. Test in ShadowHound context
```

### Emergency Workflow (Temporary Fixes)

If you MUST make a quick fix in the submodule:

1. **Document it immediately** (add to consolidation list)
2. **Mark commit as "Temp:" or "Quick fix:"**
3. **Create proper PR within 24 hours**
4. **Never let temp fixes diverge for > 1 day**

## Action Items

**Immediate (Today):**
- [ ] Choose consolidation strategy (recommend Option 1: Rebase)
- [ ] Create backup branch
- [ ] Execute consolidation
- [ ] Test consolidated branch
- [ ] Update ShadowHound submodule pointer
- [ ] Push to GitHub

**Short-term (This Week):**
- [ ] Create `dimos_development_policy.md`
- [ ] Add pre-commit hook to warn about submodule edits
- [ ] Document upstream PR process
- [ ] Clean up commit history (interactive rebase)
- [ ] Submit consolidated PR to upstream DIMOS

**Long-term (Ongoing):**
- [ ] Follow new DIMOS development policy strictly
- [ ] Weekly check for divergence between branches
- [ ] Regular syncs with upstream DIMOS main/dev

## See Also
- [[development/dimos_development_policy|DIMOS Development Policy]] — Principled workflow to prevent divergence
- [[development/submodule_policy|Git Submodule Policy]] — Never edit submodules directly
- [[development/development_hub|Development Index]] — Complete development documentation

## References
- [[development/submodule_policy|Submodule Policy]] — Never edit submodules policy
- [[development/dimos_development_policy|DIMOS Development Policy]] — Established workflow
- DIMOS Fork: https://github.com/danmartinez78/dimos-unitree
- ShadowHound: https://github.com/danmartinez78/shadowhound
- Upstream DIMOS: https://github.com/dimensionalOS/dimos-unitree
