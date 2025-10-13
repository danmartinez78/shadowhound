---
tags: [development/policy, dimos, git, workflow]
status: active
related: [development/submodule_policy, development/dimos_branch_consolidation, integrations/quickstart_dimos]
summary: >
  Principled workflow for DIMOS development to prevent branch divergence.
---

# DIMOS Development Policy

**Effective Date:** October 12, 2025  
**Status:** ACTIVE - All developers must follow  
**Rationale:** Prevent branch divergence, maintain clean git history, enable upstream contributions

---

## Core Principle

> **NEVER edit DIMOS files in the ShadowHound submodule directory (`src/dimos-unitree/`)**

All DIMOS development must happen in a separate clone of the dimos-unitree repository.

---

## Repository Structure

```
~/projects/
├── shadowhound/                    # Main robot system
│   └── src/dimos-unitree/         # Git submodule (READ-ONLY!)
│
└── dimos-unitree/                  # Separate clone for DIMOS work
    ├── .git/                       # Full git repo
    ├── dimos/                      # Make changes here
    └── tests/                      # Test here
```

---

## Setup: Clone DIMOS Separately

**One-time setup:**

```bash
cd ~/projects  # Or wherever you keep projects

# Clone your DIMOS fork
git clone https://github.com/danmartinez78/dimos-unitree.git
cd dimos-unitree

# Add upstream (dimensionalOS) as remote
git remote add upstream https://github.com/dimensionalOS/dimos-unitree.git
git fetch upstream

# Create dev branch tracking origin
git checkout -b dev origin/dev
```

**Now you have:**
- `~/projects/dimos-unitree/` - For DIMOS development
- `~/projects/shadowhound/src/dimos-unitree/` - Submodule (read-only)

---

## Standard Workflow

### 1. Found a Bug in DIMOS

```bash
# In ShadowHound, you notice a DIMOS issue
cd ~/projects/shadowhound
./start.sh
# See error in DIMOS code...

# ❌ DON'T edit src/dimos-unitree/ 
# ✅ DO switch to separate DIMOS clone
```

### 2. Create Issue & Branch

```bash
cd ~/projects/dimos-unitree

# Make sure you're up to date
git checkout dev
git pull origin dev

# Create feature branch from dev
git checkout -b fix/issue-description

# Example:
git checkout -b fix/agent-memory-exception-bug
```

### 3. Make Changes & Test

```bash
# Edit files in ~/projects/dimos-unitree/
vim dimos/exceptions/agent_memory_exceptions.py

# Test locally
python3 -m pytest tests/
# Or integrate with ShadowHound (see below)
```

### 4. Commit & Push

```bash
# In ~/projects/dimos-unitree/
git add .
git commit -m "Fix: Exception __str__ method accesses non-existent self.message

- Bug: AgentMemoryConnectionError.__str__ tries to access self.message
- Fix: Use self.args[0] instead (standard Exception pattern)
- Impact: Prevents AttributeError when exception is raised
- Related: shadowhound-ai/shadowhound#XX"

git push origin fix/agent-memory-exception-bug
```

### 5. Create Pull Request

```bash
# On GitHub: https://github.com/danmartinez78/dimos-unitree
# Create PR: fix/agent-memory-exception-bug → dev

# PR Template:
```

**Title:** `Fix: Exception __str__ method accesses non-existent self.message`

**Description:**
```markdown
## Problem
AgentMemoryConnectionError.__str__ accesses `self.message` which doesn't exist.

## Solution
Use `self.args[0]` instead (standard Python Exception pattern).

## Testing
- [x] Unit tests pass
- [x] Integrated with ShadowHound
- [x] No AttributeError when exception raised

## Related Issues
- shadowhound-ai/shadowhound#XX

## Checklist
- [x] Code follows project style
- [x] Tests added/updated
- [x] Documentation updated
- [x] Backwards compatible
```

### 6. Review & Merge

```bash
# After PR approval, merge to dev
# GitHub: Squash and merge (keeps history clean)

# Then in local dimos-unitree:
git checkout dev
git pull origin dev
```

### 7. Update ShadowHound Submodule

```bash
# In ShadowHound repo
cd ~/projects/shadowhound/src/dimos-unitree

# Update to latest dev
git fetch origin
git checkout dev
git pull origin dev

# Go back to ShadowHound root
cd ~/projects/shadowhound

# Commit submodule update
git add src/dimos-unitree
git commit -m "Update DIMOS submodule: Exception bug fix (PR #XX)"
git push origin feature/local-llm-support
```

---

## Testing DIMOS Changes in ShadowHound

### Option 1: Temporary Submodule Branch (Testing Only)

```bash
# In ShadowHound submodule, temporarily switch to your branch
cd ~/projects/shadowhound/src/dimos-unitree
git fetch origin
git checkout fix/agent-memory-exception-bug

# Test in ShadowHound
cd ~/projects/shadowhound
./start.sh
# Test thoroughly...

# ❌ DON'T commit submodule with feature branch
# ✅ DO switch back to dev after testing
cd src/dimos-unitree
git checkout dev
cd ..
git checkout src/dimos-unitree  # Discard submodule change
```

### Option 2: Install DIMOS from Local Clone (Development)

```bash
# Uninstall submodule DIMOS
pip uninstall dimos -y

# Install from separate clone (editable)
pip install -e ~/projects/dimos-unitree

# Now changes in ~/projects/dimos-unitree/ are immediately active
# Test in ShadowHound
cd ~/projects/shadowhound
./start.sh
# Make changes in ~/projects/dimos-unitree/
# Test changes immediately (no rebuild needed)

# When done:
pip uninstall dimos -y
pip install -e ~/projects/shadowhound/src/dimos-unitree
```

### Option 3: Python Path Override (Quick Testing)

```bash
# In ShadowHound launch script or .env
export PYTHONPATH=~/projects/dimos-unitree:$PYTHONPATH

# Now ~/projects/dimos-unitree takes precedence
./start.sh
```

---

## Emergency Fix Workflow

**When you MUST fix something immediately in production:**

### 1. Document the Emergency

```bash
# Create issue IMMEDIATELY
# Title: "[EMERGENCY] Description of issue"
```

### 2. Make Minimal Fix

```bash
# In separate dimos-unitree clone (NOT submodule!)
cd ~/projects/dimos-unitree
git checkout -b hotfix/emergency-description

# Make minimal fix
vim dimos/path/to/file.py
git commit -m "HOTFIX: Brief description (issue #XX)"
```

### 3. Deploy & PR Simultaneously

```bash
# Push hotfix branch
git push origin hotfix/emergency-description

# Update ShadowHound submodule to hotfix
cd ~/projects/shadowhound/src/dimos-unitree
git fetch origin
git checkout hotfix/emergency-description
cd ../..
git add src/dimos-unitree
git commit -m "HOTFIX: Update DIMOS for emergency fix (issue #XX)"

# Create PR to dev immediately
# GitHub: Create PR hotfix/emergency-description → dev
```

### 4. Post-Emergency Cleanup

```bash
# After PR merged to dev:
cd ~/projects/shadowhound/src/dimos-unitree
git checkout dev
git pull origin dev
cd ../..
git add src/dimos-unitree
git commit -m "Update DIMOS to dev (includes hotfix from #XX)"
```

---

## Branch Strategy

### In dimos-unitree Repository

```
main (stable releases)
  ↑
dev (active development)
  ↑
feature/*, fix/* (your branches)
```

**Rules:**
- Always branch from `dev`
- Always PR to `dev`
- Never commit directly to `dev` or `main`
- Squash and merge to keep history clean

### In ShadowHound Submodule

```
Submodule pointer: Always points to dev (or specific release tag)
```

**Rules:**
- Submodule should always point to `dev` branch HEAD
- Never point to feature branches (except temporarily for testing)
- Update submodule pointer after every DIMOS PR merge

---

## Preventing Divergence

### Weekly Sync Check

```bash
# Every Monday, check for divergence
cd ~/projects/shadowhound/src/dimos-unitree
git fetch origin

# Compare submodule commit to dev HEAD
SUBMODULE_COMMIT=$(git rev-parse HEAD)
DEV_HEAD=$(git rev-parse origin/dev)

if [ "$SUBMODULE_COMMIT" != "$DEV_HEAD" ]; then
    echo "⚠ Submodule is behind dev!"
    git log --oneline $SUBMODULE_COMMIT..$DEV_HEAD
    # Update submodule
fi
```

### Pre-Commit Hook (ShadowHound)

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Check if DIMOS submodule has uncommitted changes

cd src/dimos-unitree
if ! git diff-index --quiet HEAD --; then
    echo "❌ ERROR: DIMOS submodule has uncommitted changes!"
    echo "This violates the DIMOS development policy."
    echo "See docs/dimos_development_policy.md"
    echo ""
    echo "Changes:"
    git status --short
    echo ""
    echo "Fix:"
    echo "  cd ~/projects/dimos-unitree"
    echo "  # Make changes there, create PR, then update submodule"
    exit 1
fi
```

### Automation Script

```bash
# scripts/check_dimos_divergence.sh
#!/bin/bash
cd ~/projects/shadowhound/src/dimos-unitree
git fetch origin

CURRENT=$(git rev-parse HEAD)
DEV_HEAD=$(git rev-parse origin/dev)

if [ "$CURRENT" != "$DEV_HEAD" ]; then
    echo "⚠ DIMOS submodule divergence detected"
    echo "Current:  $CURRENT"
    echo "Dev HEAD: $DEV_HEAD"
    echo ""
    echo "Commits behind:"
    git log --oneline $CURRENT..$DEV_HEAD
    exit 1
fi
```

---

## Upstream Contributions

### Syncing with dimensionalOS/dimos-unitree

```bash
cd ~/projects/dimos-unitree

# Fetch upstream changes
git fetch upstream

# Merge upstream main into your dev
git checkout dev
git merge upstream/main
git push origin dev

# Update ShadowHound submodule
cd ~/projects/shadowhound/src/dimos-unitree
git pull origin dev
cd ../..
git add src/dimos-unitree
git commit -m "Update DIMOS: Sync with upstream main"
```

### Contributing to Upstream

```bash
# After your fix is tested in your fork:
cd ~/projects/dimos-unitree

# Create branch for upstream PR
git checkout -b upstream/fix-description main
git cherry-pick <commits-from-dev>
git push origin upstream/fix-description

# Create PR to dimensionalOS/dimos-unitree:main
```

---

## Common Mistakes & Solutions

### ❌ Mistake: Edited files in ShadowHound submodule

```bash
cd ~/projects/shadowhound/src/dimos-unitree
git status
# modified: dimos/path/to/file.py

# Solution: Discard changes, redo in separate clone
git stash save "Mistake: Edited in submodule"
git stash show -p > /tmp/dimos-changes.patch

cd ~/projects/dimos-unitree
git checkout -b fix/ported-from-submodule dev
git apply /tmp/dimos-changes.patch
# Review, test, commit, PR
```

### ❌ Mistake: Submodule diverged from dev

```bash
cd ~/projects/shadowhound
git submodule status
# +abc123 src/dimos-unitree (ahead of dev)

# Solution: Reset submodule to dev
cd src/dimos-unitree
git fetch origin
git reset --hard origin/dev
cd ../..
git add src/dimos-unitree  # Update pointer
```

### ❌ Mistake: Multiple feature branches in submodule

```bash
# Solution: Consolidate (see dimos_branch_consolidation.md)
cd ~/projects/dimos-unitree
git rebase origin/dev
# Or merge origin/dev
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Start new DIMOS feature | `cd ~/projects/dimos-unitree && git checkout -b feature/name dev` |
| Test in ShadowHound | `pip install -e ~/projects/dimos-unitree` |
| Update submodule to dev | `cd ~/projects/shadowhound/src/dimos-unitree && git checkout dev && git pull` |
| Check for divergence | `cd ~/projects/shadowhound && git submodule status` |
| Emergency hotfix | Branch from dev, PR immediately, deploy to submodule temporarily |

---

## Enforcement

**This policy is MANDATORY for:**
- All DIMOS changes (features, fixes, refactors)
- All team members and AI agents
- All development environments (laptop, desktop, Thor)

**Exceptions:**
- None. If you think you need an exception, create an issue first.

**Consequences of Violation:**
- Divergent branches (we just fixed this!)
- Lost work during consolidation
- Merge conflicts
- Difficulty contributing upstream
- Harder for others to use your fixes

---

## Related Documentation

## See Also
- [[development/submodule_policy|Git Submodule Policy]] — Why we use standard git submodules
- [[development/dimos_branch_consolidation|DIMOS Branch Consolidation]] — Fixing current divergence
- [[integrations/quickstart_dimos|DIMOS Quick Start]] — Getting started with DIMOS
- [[development/development_hub|Development Index]] — Complete development documentation

## References
- **Submodule Policy:** [[development/submodule_policy|Git Submodule Policy]] - Why we don't edit submodules
- **Consolidation Plan:** [[development/dimos_branch_consolidation|DIMOS Branch Consolidation]] - How we're fixing current divergence

---

## Revision History

- **2025-10-12:** Initial policy created after branch divergence incident
- **Future:** Update as we learn from experience

---

**Questions?** Create an issue in shadowhound or ask in team chat. This policy is living and we'll improve it as needed.
