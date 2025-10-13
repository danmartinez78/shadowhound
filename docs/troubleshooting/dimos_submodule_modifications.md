---
tags: [troubleshooting, git, submodules, devcontainer]
status: active
related: [development/submodule_policy]
summary: >
  Troubleshooting guide for persistent dimos-unitree submodule modifications - why they happen and how to prevent them.
---

# DIMOS-Unitree Submodule Modification Issues

## Problem Summary

You're experiencing **consistent issues with uncommitted changes** in the `src/dimos-unitree` submodule. The modifications are typically:
- Minor formatting changes (line breaks, whitespace)
- Auto-formatting by Black, autopep8, or VS Code
- Accidental edits when viewing files

## Root Causes

### 1. Auto-Formatting Tools
**Primary Culprit**: When you open Python files in the submodule, VS Code's formatters automatically reformat code:

```python
# Original (from upstream)
logger.debug(f"tool_choice set to: {tool_choice_param}, skill_library has {len(self.skill_library.get_tools())} tools")

# Auto-formatted (by Black/autopep8)
logger.debug(
    f"tool_choice set to: {tool_choice_param}, skill_library has {len(self.skill_library.get_tools())} tools"
)
```

The change is purely cosmetic but creates a git diff.

### 2. Devcontainer vs Host Path Split
As documented in `.github/copilot-instructions.md`:
- **Edit path**: `/workspaces/shadowhound/` (devcontainer)
- **Runtime path**: `/home/daniel/shadowhound/` (laptop host)

The submodule can have different states in each location:
- Devcontainer: Clean (after fix)
- Host: Still has uncommitted changes (stale)

### 3. Violation of Submodule Policy
According to `docs/development/submodule_policy.md`, you should **NEVER** edit files in `src/dimos-unitree/`. But:
- Formatters run automatically when files open
- Easy to accidentally edit when viewing
- No protection against modifications

## Quick Fix: Reset Changes

```bash
# In devcontainer
cd /workspaces/shadowhound/src/dimos-unitree
git checkout -- .
git clean -fd

# Verify it's clean
cd /workspaces/shadowhound
git status  # Should show "nothing to commit, working tree clean"
```

## Permanent Solutions Implemented

### 1. VS Code Settings Protection
**File**: `.vscode/settings.json`

Added:
```json
{
  // Prevent file watching in submodules (reduces load and accidental triggers)
  "files.watcherExclude": {
    "**/src/dimos-unitree/**": true
  },
  
  // Exclude submodule from Black formatting
  "python.formatting.blackArgs": [
    "--line-length=99",
    "--exclude=src/dimos-unitree/"
  ],
  
  // Exclude from pylint
  "python.linting.pylintArgs": [
    "--ignore=src/dimos-unitree"
  ],
  
  // Reduce search noise from external dependencies
  "search.exclude": {
    "**/src/dimos-unitree/dimos/robot/unitree/external/**": true
  }
}
```

### 2. Git Attributes
**File**: `.gitattributes`

Added:
```gitattributes
# Mark submodule as vendored (no diffs, not counted in language stats)
src/dimos-unitree/** linguist-vendored
src/dimos-unitree/** -diff
```

This tells git:
- Don't show diffs for submodule files (reduces noise)
- Mark as vendored code (doesn't count in repo stats)

### 3. Git Configuration
```bash
# Disabled automatic submodule recursion
git config --local submodule.recurse false
```

This prevents git operations from automatically diving into submodules unless explicitly requested.

## Prevention Workflow

### When You Need to View DIMOS Code
```bash
# Option 1: View without opening (safer)
cat src/dimos-unitree/dimos/agents/agent.py

# Option 2: Open in read-only mode
code --reuse-window --wait src/dimos-unitree/dimos/agents/agent.py
# Close immediately after reading

# Option 3: Go to GitHub
https://github.com/danmartinez78/dimos-unitree/blob/fix/webrtc-instant-commands-and-progress/dimos/agents/agent.py
```

### When You Need to Change DIMOS
**DO NOT** edit in the submodule! Instead:

```bash
# 1. Navigate to your DIMOS fork
cd ~/repos/dimos-unitree  # Separate clone

# 2. Create a feature branch
git checkout -b fix/my-fix

# 3. Make changes and commit
# ... edit files ...
git add .
git commit -m "fix: description"
git push origin fix/my-fix

# 4. Create PR to danmartinez78/dimos-unitree

# 5. After merge, update shadowhound submodule
cd /workspaces/shadowhound/src/dimos-unitree
git fetch origin
git pull origin fix/webrtc-instant-commands-and-progress

# 6. Commit the submodule update
cd /workspaces/shadowhound
git add src/dimos-unitree
git commit -m "chore: update DIMOS submodule - <description>"
git push
```

## Host Sync Consideration

The host machine (`/home/daniel/shadowhound/`) may still have old submodule state. After fixing in devcontainer:

```bash
# On laptop host (outside devcontainer)
cd /home/daniel/shadowhound
git pull  # Get latest commits
git submodule update --init --recursive  # Sync submodules
cd src/dimos-unitree
git status  # Should be clean now
```

## Diagnostic Commands

Check submodule status:
```bash
# Show submodule commit hash
git submodule status

# Check for modifications
git diff --submodule

# See what's changed inside submodule
cd src/dimos-unitree && git status
cd src/dimos-unitree && git diff
```

Check configuration:
```bash
# View .gitmodules
cat .gitmodules

# View submodule remote
cd src/dimos-unitree && git remote -v

# View submodule branch
cd src/dimos-unitree && git branch -vv
```

## Common Scenarios

### Scenario 1: "I just opened a file and now it's modified"
**Cause**: Auto-formatter ran on save
**Fix**:
```bash
cd src/dimos-unitree
git checkout -- .
```

### Scenario 2: "Changes persist after resetting"
**Cause**: Host and devcontainer out of sync
**Fix**: Reset in both locations
```bash
# In devcontainer
cd /workspaces/shadowhound/src/dimos-unitree
git checkout -- .

# Then on host
ssh laptop
cd /home/daniel/shadowhound/src/dimos-unitree
git checkout -- .
```

### Scenario 3: "I made important changes in the submodule"
**Cause**: Edited directly in submodule (against policy)
**Fix**: Extract and apply properly
```bash
# Save the changes
cd src/dimos-unitree
git diff > /tmp/my-changes.patch
git checkout -- .

# Apply to proper DIMOS clone
cd ~/repos/dimos-unitree
git checkout -b fix/extracted-changes
git apply /tmp/my-changes.patch
# Review, commit, and PR
```

## Monitoring

Add to your regular workflow:
```bash
# Before starting work
git submodule status  # Should show no '+' prefix

# After editing
git status  # Should not show "src/dimos-unitree (modified content)"

# Before committing
git diff --submodule  # Should not show submodule changes
```

## Prevention Checklist

- [ ] VS Code settings exclude submodule from formatting
- [ ] `.gitattributes` marks submodule as vendored
- [ ] Git config has `submodule.recurse = false`
- [ ] Never open submodule files in editor
- [ ] Use GitHub web view for quick reference
- [ ] Maintain separate DIMOS clone for development
- [ ] Check submodule status before committing
- [ ] Sync host after devcontainer changes

## References

- [[development/submodule_policy|Git Submodule Policy]]
- [[development/dimos_development_policy|DIMOS Development Policy]]
- [[../copilot-instructions|Copilot Instructions (Dev Env Setup)]]
- Git Submodules: https://git-scm.com/book/en/v2/Git-Tools-Submodules

## Change Log

- 2025-01-13: Documented issue and implemented VS Code protections
- Previous: Multiple incidents of formatting changes in agent.py
