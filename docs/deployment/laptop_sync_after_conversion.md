---
tags: [deployment, git, submodules]
status: active
related: [submodule_policy, deployment_sync]
summary: >
  Step-by-step guide for syncing laptop host after vcs→git submodule conversion.
---

# Laptop Host Sync After Submodule Conversion

## Context

We converted ShadowHound from **vcs (vcstool)** to **git submodules** in commit `fbe527e`. This guide helps sync the laptop host with these changes.

## Before You Start

**Desktop devcontainer status:** ✅ Already converted and pushed
**Laptop host status:** ⏳ Needs to pull changes and initialize submodules

## Step-by-Step Instructions

### 1. Pull the Conversion

```bash
cd /home/daniel/shadowhound
git pull origin feature/local-llm-support
```

**Expected output:**
```
remote: Enumerating objects...
Updating af0652a..ad01b88
Fast-forward
 .gitmodules | 5 +++++
 shadowhound.repos | (deleted)
 ...
```

**Verification:**
```bash
cat .gitmodules
# Should show:
# [submodule "src/dimos-unitree"]
#     path = src/dimos-unitree
#     url = https://github.com/danmartinez78/dimos-unitree.git
#     branch = fix/webrtc-instant-commands-and-progress
```

### 2. Handle Existing DIMOS Directory

If you had uncommitted changes in `src/dimos-unitree/`:

```bash
cd src/dimos-unitree

# Option A: Discard all local changes (DESTRUCTIVE but clean)
git reset --hard HEAD
git clean -fd
cd ../..

# Option B: Stash for later review
git stash save "dimos changes before submodule conversion"
cd ../..

# Option C: Commit to a temporary branch
git checkout -b temp-laptop-changes
git add .
git commit -m "Temp DIMOS changes from laptop"
git checkout fix/webrtc-instant-commands-and-progress
cd ../..
```

### 3. Initialize Submodules

```bash
# Sync submodule URLs from .gitmodules
git submodule sync

# Initialize and clone all submodules (including nested)
git submodule update --init --recursive
```

**Expected output:**
```
Submodule 'src/dimos-unitree' (https://github.com/danmartinez78/dimos-unitree.git) registered for path 'src/dimos-unitree'
Cloning into '/home/daniel/shadowhound/src/dimos-unitree'...
Submodule path 'src/dimos-unitree': checked out '<commit-hash>'
Submodule 'dimos/robot/unitree/external/go2_ros2_sdk' registered...
Submodule 'dimos/robot/unitree/external/go2_webrtc_connect' registered...
```

**This will initialize:**
- DIMOS main submodule
- go2_ros2_sdk (nested in DIMOS)
- go2_webrtc_connect (nested in DIMOS)
- aioice libs (nested in both SDK and WebRTC)

### 4. Verify Go2 SDK Packages

```bash
ls src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk/
```

**Expected output:**
```
go2_interfaces/
unitree_go/
go2_robot_sdk/
coco_detector/
lidar_processor/
lidar_processor_cpp/
speech_processor/
README.md
...
```

**All packages should be present.** If missing, re-run:
```bash
git submodule update --init --recursive --force
```

### 5. Check Submodule Status

```bash
git submodule status
```

**Expected output:**
```
 <commit-hash> src/dimos-unitree (heads/fix/webrtc-instant-commands-and-progress)
```

**No `-` prefix means initialized. No `+` prefix means no uncommitted changes.**

### 6. Install Dependencies

```bash
# Install embeddings packages if needed
pip install chromadb langchain-chroma sentence-transformers

# Or let start.sh check and prompt
./start.sh
```

### 7. Build and Test

```bash
./start.sh
```

**Expected logs:**
```
✓ ROS2 environment sourced
✓ Checking dependencies...
✓ Building workspace...
✓ Go2 interfaces built
✓ DIMOS packages built
✓ ShadowHound packages built
✓ Sourcing workspace...
🚀 Launching mission agent...
```

**If agent starts without crashes, you're good!**

## Troubleshooting

### Issue: "No module named 'chromadb'"

**Solution:**
```bash
pip install chromadb langchain-chroma sentence-transformers
```

Or rely on graceful fallback (agent works without RAG).

### Issue: Go2 SDK Packages Missing

**Solution:**
```bash
cd /home/daniel/shadowhound
git submodule update --init --recursive --force
```

**Nuclear option if still broken:**
```bash
rm -rf src/dimos-unitree
git submodule update --init --recursive
```

### Issue: "Submodule path contains a .git directory"

**Solution (clean slate):**
```bash
cd /home/daniel/shadowhound
rm -rf src/dimos-unitree/.git
git rm -rf src/dimos-unitree
git submodule update --init --recursive
```

### Issue: Uncommitted Changes Block Pull

**Solution:**
```bash
cd src/dimos-unitree
git stash save "temp changes"
cd ../..
git submodule update --init --recursive
```

### Issue: Build Errors After Sync

**Clean rebuild:**
```bash
rm -rf build/ install/ log/
./start.sh
```

## Verification Checklist

After completing these steps:

- [ ] `.gitmodules` file exists in repo root
- [ ] `git submodule status` shows initialized submodule (no `-` prefix)
- [ ] Go2 SDK packages present: `ls src/dimos-unitree/.../go2_ros2_sdk/`
- [ ] Embeddings deps installed: `python -c "import chromadb; import sentence_transformers"`
- [ ] Build succeeds: `./start.sh` completes without errors
- [ ] Mission agent starts: Logs show "Mission agent starting..."
- [ ] vLLM responds: Test with `curl http://192.168.10.116:8000/v1/models`

## What Changed

| Aspect | Before (vcs) | After (git submodules) |
|--------|--------------|------------------------|
| Config file | `shadowhound.repos` | `.gitmodules` |
| Command to sync | `vcs import src < shadowhound.repos` | `git submodule update --init --recursive` |
| Nested submodules | Manual handling | Automatic with `--recursive` |
| AI agent confusion | High (non-standard) | Low (standard git) |
| IDE support | Limited | Full (VS Code, GitHub) |

## Next Steps

Once laptop host is synced:

1. **Test vLLM integration:**
   ```bash
   curl http://192.168.10.116:8000/v1/models
   curl http://192.168.10.116:8000/v1/completions \
     -H "Content-Type: application/json" \
     -d '{"model":"Qwen/Qwen2.5-Coder-7B-Instruct","prompt":"def fibonacci(n):"}'
   ```

2. **Test mission agent:**
   ```bash
   ./start.sh --agent-only
   # Send test mission via ROS2 or WebUI
   ```

3. **End-to-end robot test:**
   ```bash
   ./start.sh  # Full stack
   # Give mission: "Move forward 1 meter"
   ```

## References

- **Submodule Policy:** `docs/submodule_policy.md`
- **Deployment Sync:** `docs/deployment_sync.md`
- **Git Submodules Docs:** https://git-scm.com/book/en/v2/Git-Tools-Submodules
- **Conversion Commit:** `fbe527e` (desktop devcontainer)
- **Docs Update:** `ad01b88` (current)

## Support

If you hit issues not covered here:

1. Check `git submodule status` for abnormal states
2. Review `docs/submodule_policy.md` for recovery steps
3. Try `git submodule deinit -f src/dimos-unitree && git submodule update --init --recursive`
4. Last resort: Ask for help with error logs

**Remember:** Git submodules are standard, well-documented, and have excellent tooling support. This conversion eliminates the vcs headaches!
