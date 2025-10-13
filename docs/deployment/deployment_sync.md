# Deployment Sync Guide

## Environment Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Desktop (VS Code Remote SSH)                                             │
│ - You are here: /workspaces/shadowhound/ (devcontainer)                 │
│ - Git operations work here                                               │
│ - Changes made here need to be synced to laptop host                     │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ SSH Connection
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ Laptop Host (192.168.10.167)                                             │
│ - Runtime location: /home/daniel/shadowhound/                           │
│ - This is where ROS2 runs                                                │
│ - This is where Python executes from                                     │
│ - Error tracebacks show this path                                        │
│ - ./start.sh runs here                                                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Network
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ Thor (Jetson AGX Orin: 192.168.10.116)                                  │
│ - vLLM container on port 8000                                            │
│ - Model: Qwen/Qwen2.5-Coder-7B-Instruct                                 │
│ - Optional: Go2 SDK if needed                                            │
└─────────────────────────────────────────────────────────────────────────┘
```

## Critical Understanding

### The Two-Path Problem

**Editing Path (Desktop devcontainer):**
- `/workspaces/shadowhound/`
- Git works here
- VS Code edits here
- Changes committed here

**Execution Path (Laptop host):**
- `/home/daniel/shadowhound/`
- ROS2 runs here
- Python executes here
- Error tracebacks show this path

### Why Errors Persist After Fixing

When you:
1. ✅ Edit file in devcontainer: `/workspaces/shadowhound/src/dimos-unitree/...`
2. ✅ Commit changes
3. ✅ Rebuild in devcontainer
4. ❌ **Still get old error**

**Root cause:** The laptop host at `/home/daniel/shadowhound/` hasn't pulled your changes!

## Sync Workflow

### Option A: Pull Changes on Laptop Host (Recommended)

On the **laptop** (not in devcontainer):
```bash
ssh laptop  # or however you access it
cd /home/daniel/shadowhound
git status  # Check for uncommitted changes
git pull origin feature/local-llm-support
git submodule update --init --recursive
./start.sh  # Will rebuild with new code
```

### Option B: Direct File Sync (Quick Fix)

If git is messy on the host:
```bash
# From desktop, sync specific file to laptop
rsync -av /workspaces/shadowhound/src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py \
  laptop:/home/daniel/shadowhound/src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py

# Then on laptop, clear cache and rebuild
ssh laptop "cd /home/daniel/shadowhound && \
  find src/dimos-unitree -name '*.pyc' -delete && \
  find src/dimos-unitree -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true && \
  ./start.sh"
```

### Option C: Work Directly on Laptop Host

Edit files directly on the laptop:
```bash
ssh laptop
cd /home/daniel/shadowhound
nano src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py
# Make changes
./start.sh  # Test immediately
```

Then sync back to devcontainer for git:
```bash
# From desktop
rsync -av laptop:/home/daniel/shadowhound/src/dimos-unitree/ \
  /workspaces/shadowhound/src/dimos-unitree/
git add .
git commit -m "..."
```

## Current Issue: DIMOS Exception Bug

### The Bug
File: `src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py` line 44

**Old (buggy) code on laptop host:**
```python
def __str__(self):
    return f"{self.message}\nCaused by: {repr(self.cause)}" if self.cause else self.message
```

**Fixed code in devcontainer:**
```python
def __str__(self):
    # Python Exception stores message in args[0], not as self.message attribute
    message = self.args[0] if self.args else "Unknown error"
    return f"{message}\nCaused by: {repr(self.cause)}" if self.cause else message
```

### To Fix on Laptop Host

**Option 1: Pull from Git**
```bash
ssh laptop
cd /home/daniel/shadowhound
git pull origin feature/local-llm-support
cd src/dimos-unitree
git fetch origin
git checkout fix/webrtc-instant-commands-and-progress  # or whatever branch has the fix
git pull
cd ../..
./start.sh
```

**Option 2: Manual Edit**
```bash
ssh laptop
nano /home/daniel/shadowhound/src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py
# Change line 44 from self.message to self.args[0]
# Save and exit
./start.sh
```

**Option 3: Copy Fixed File**
```bash
# From desktop devcontainer
scp /workspaces/shadowhound/src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py \
  laptop:/home/daniel/shadowhound/src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py
```

## Prevention

### Before Testing Changes

Always ensure laptop host is synced:
```bash
# Quick sync check
ssh laptop "cd /home/daniel/shadowhound && git status && git log -1 --oneline"

# If behind, pull
ssh laptop "cd /home/daniel/shadowhound && git pull && git submodule update --remote"
```

### Best Practice Workflow

1. **Edit in devcontainer** (where you are now)
2. **Commit and push** to GitHub
3. **Pull on laptop host** before testing
4. **Run ./start.sh** on laptop host
5. **Check error tracebacks** - they'll show `/home/daniel/shadowhound/...`

## Verification

To verify paths match:
```bash
# Check git commit on devcontainer
cd /workspaces/shadowhound
git log -1 --oneline

# Check git commit on laptop host  
ssh laptop "cd /home/daniel/shadowhound && git log -1 --oneline"

# Should be identical!
```

To verify file contents match:
```bash
# Desktop devcontainer
md5sum /workspaces/shadowhound/src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py

# Laptop host
ssh laptop "md5sum /home/daniel/shadowhound/src/dimos-unitree/dimos/exceptions/agent_memory_exceptions.py"

# Checksums should match!
```

## Quick Reference

| Location | Path | Purpose |
|----------|------|---------|
| Desktop (you) | `/workspaces/shadowhound/` | Edit, commit, git ops |
| Laptop host | `/home/daniel/shadowhound/` | Run, test, deploy |
| Thor Jetson | N/A | vLLM server |

**Remember:** Error tracebacks will always show `/home/daniel/shadowhound/...` because that's where Python runs!
