---
tags: [project, legacy]
status: draft
related: []
summary: >
  Legacy documentation preserved from earlier phases for review and migration.
---

# 🚀 Orchestrated Launch System - Complete!

## Purpose
Preserve historical context while signaling that this page requires verification against the current workflow.

## Prerequisites
- Review the legacy notes below to understand original assumptions and instructions.
- Cross-check commands and links with the latest tooling before execution.

## Steps
1. Read through the legacy notes captured under **Legacy Notes** and flag outdated guidance.
2. Update or replace the content with validated procedures as time permits.
3. Record verification outcomes in the validation checklist and mark follow-up tasks in the backlog.

### Legacy Notes
## What We Built

The start script is now a **full system orchestrator** that handles everything from git updates to verified robot initialization.

## Three-Stage Launch Architecture

### Stage 1: Robot Driver 🤖
```
✓ Pings robot (192.168.10.167)
✓ Launches go2_ros2_sdk in background
✓ Saves PID for cleanup
✓ Waits for /go2_states topic (30s timeout)
✓ Logs to /tmp/shadowhound_robot_driver.log
```

### Stage 2: Topic Verification 🔍
```
✓ Runs scripts/check_topics.py diagnostic
✓ Shows all robot-related topics
✓ Verifies critical topics (go2_states, camera, imu, odom, costmap)
✓ Checks Nav2 action servers (/spin)
✓ Prompts before continuing
```

### Stage 3: Mission Agent 🧠
```
✓ Sources ROS2 and workspace
✓ Sets PYTHONPATH for DIMOS
✓ Launches mission agent
✓ Agent runs built-in diagnostics (double-check)
✓ Initializes DIMOS framework
```

## Complete Feature Set

### 1. Git Auto-Update (Commit 8ab216f)
- ✅ Checks main repo + submodules for updates
- ✅ Shows commit counts and recent changes
- ✅ Safe stash/restore of uncommitted changes
- ✅ Automatic rebuild trigger
- ✅ Standalone `scripts/update_repos.sh`

### 2. Topic Diagnostics (Commit ad48e43)
- ✅ Standalone `scripts/check_topics.py`
- ✅ Built into mission_agent
- ✅ Built into start.sh Stage 2
- ✅ Clear ✅/❌ status output

### 3. Orchestrated Launch (Commit e31506e)
- ✅ Three-stage validated launch
- ✅ Robot driver in background
- ✅ Topic verification before agent
- ✅ Clean shutdown of all processes
- ✅ Flexible modes (skip-driver, agent-only)

## Usage Examples

### Standard Launch (Recommended)
```bash
./start.sh --dev
```
**Process:**
1. Checks for git updates
2. Rebuilds if needed
3. Pings robot
4. Launches robot driver
5. Verifies topics
6. Launches mission agent

### Daily Development
```bash
# Morning: Auto-update and launch
./start.sh --dev --auto-update
```

### Rapid Agent Iteration
```bash
# Terminal 1: Launch driver once
ros2 launch launch/go2_sdk/robot.launch.py

# Terminal 2: Iterate on agent
./start.sh --dev --skip-driver
# Make changes, Ctrl+C, relaunch
./start.sh --dev --skip-driver
```

### Agent-Only (Fastest)
```bash
# When driver already running and verified
./start.sh --dev --agent-only
```

### Mock Development
```bash
# No hardware needed
./start.sh --dev --mock
```

## Command-Line Options

| Flag | Description | Use Case |
|------|-------------|----------|
| `--dev` | Development config | Local testing |
| `--prod` | Production config | Real robot deployment |
| `--mock` | Mock robot mode | No hardware available |
| `--skip-update` | Skip git check | Testing local changes |
| `--auto-update` | Auto-pull updates | CI/CD, morning sync |
| `--skip-driver` | Use existing driver | Driver already running |
| `--agent-only` | Skip all checks | Fast iteration on agent |
| `--no-web` | Disable web UI | Headless operation |
| `--web-port N` | Custom port | Port conflict |

## What Problems This Solves

### Before
```bash
# Terminal 1: Launch driver manually
ros2 launch launch/go2_sdk/robot.launch.py
# Wait... is it ready? Check manually:
ros2 topic list | grep go2_states

# Terminal 2: Launch agent
ros2 launch shadowhound_mission_agent mission_agent.launch.py
# Agent hangs... topics weren't ready yet
# Kill, wait longer, try again
```

### After
```bash
# Single command
./start.sh --dev

# Automatically:
# ✓ Checks git updates
# ✓ Rebuilds if needed
# ✓ Pings robot
# ✓ Launches driver
# ✓ Waits for topics
# ✓ Verifies with diagnostics
# ✓ Launches agent when safe
# ✓ Clean shutdown on Ctrl+C
```

## Debugging

### Check Driver Logs
```bash
tail -f /tmp/shadowhound_robot_driver.log
```

### Check Topics Manually
```bash
python3 scripts/check_topics.py
```

### Update Repos Only
```bash
./scripts/update_repos.sh --auto
```

### Full Status Check
```bash
# See git status + topics + packages
echo "=== GIT STATUS ===" && git status -s && \
echo "=== TOPICS ===" && ros2 topic list | grep -E "(go2|camera)" | head -5 && \
echo "=== PACKAGES ===" && ls install/ | grep shadowhound
```

## File Structure

```
shadowhound/
├── start.sh                          # Main orchestrator (753 lines)
├── scripts/
│   ├── check_topics.py              # Standalone topic diagnostic
│   └── update_repos.sh              # Standalone git updater
├── docs/
│   ├── orchestrated_launch.md       # This feature (comprehensive)
│   ├── auto_update.md               # Git auto-update guide
│   ├── topic_diagnostics.md         # Topic checking guide
│   └── qol_improvements.md          # Summary of all features
└── quick_reference.md                # Command cheat sheet
```

## Cleanup on Exit

When you press **Ctrl+C**:
1. Trap signal caught
2. Mission agent terminated (SIGTERM → SIGKILL)
3. Robot driver terminated using saved PID
4. Temp files cleaned (`/tmp/shadowhound_*.pid`)
5. Exit gracefully

**Both processes fully cleaned up automatically!**

## Integration Examples

### With Go2 SDK Development
```bash
# Make improvements to SDK
cd src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk
# ... edit files ...

# Test with existing driver
./start.sh --dev --skip-driver

# Or test driver changes
ros2 launch launch/go2_sdk/robot.launch.py
# In another terminal:
./start.sh --dev --skip-driver
```

### With CI/CD
```bash
# Auto-update, build, launch in one command
./start.sh --prod --auto-update --no-web
```

### With Multiple Robots
```bash
# Robot 1 (default IP)
./start.sh --prod

# Robot 2 (custom IP)
export GO2_IP=192.168.10.168
export ROS_DOMAIN_ID=1
./start.sh --prod --web-port 8081
```

## Benefits Summary

### Development Workflow
✅ Single command to launch everything
✅ No more guessing if driver is ready
✅ Automatic validation between stages
✅ Fast iteration modes for different scenarios
✅ Clean shutdown of all processes

### Debugging
✅ Clear failure points (which stage failed?)
✅ Topic diagnostics built-in
✅ Log files for driver issues
✅ Interactive prompts to decide next action

### Team Collaboration
✅ Stay in sync with auto-update
✅ Consistent launch experience
✅ Self-documenting (clear stage output)
✅ Flexible for different workflows

## Next Steps on Laptop

```bash
# 1. Pull the orchestrated launch system
cd ~/shadowhound
git pull origin feature/dimos-integration

# 2. Test the full orchestration
./start.sh --dev

# You should see:
# ── Stage 1: Launching Robot Driver ──
# ── Stage 2: Verifying Robot Topics ──
# ── Stage 3: Launching Mission Agent ──
```

## Commits

1. **d5ae2ba** - Format diagnostic code
2. **ad48e43** - Add topic visibility diagnostics
3. **8ab216f** - Add automatic git repository update checking
4. **87a1ce7** - Add QoL improvements summary
5. **91512a9** - Add quick reference card
6. **e31506e** - Add orchestrated three-stage launch system ⭐ **NEW**

All pushed to `origin/feature/dimos-integration` ✅

## Documentation

- **📖 Orchestrated Launch**: `docs/orchestrated_launch.md` (comprehensive, 400+ lines)
- **📖 Auto-Update**: `docs/auto_update.md`
- **📖 Topic Diagnostics**: `docs/topic_diagnostics.md`
- **📖 QoL Summary**: `docs/qol_improvements.md`
- **📖 Quick Reference**: `quick_reference.md`

## The Result

You now have a **production-ready orchestrator** that:
- 🔄 Keeps code in sync (auto-update)
- 🤖 Launches robot driver automatically
- 🔍 Validates topics before proceeding
- 🧠 Launches mission agent safely
- 🧹 Cleans up everything on exit
- 📊 Provides clear status at each stage
- 🎯 Supports flexible workflows
- 📝 Fully documented

**No more manual coordination between driver and agent!** 🎉


## Validation
- [ ] Legacy guidance reviewed for accuracy and converted to the new workflow where applicable.
- [ ] Links updated to use vault-friendly wikilinks or confirmed for external references.
- [ ] Outstanding migration work captured as tasks in the backlog.

## References
- [[index|Knowledge Base Index]]
