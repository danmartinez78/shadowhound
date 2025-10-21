---
tags: [development, continuation, simulation]
status: active
related:
  - experiments/laptop_sim_integration_oct21_2025.md
  - simulation/data_flow_architecture.md
summary: >
  Quick reference for continuing laptop + Isaac Sim integration work.
---

# Next Session Quick Start Guide

## Current State
- **Branch**: `feature/laptop-sim-integration`
- **Blocker**: Mission agent times out waiting for `/local_costmap/costmap` (30s)
- **Root Cause**: Nav2 TF frame configuration mismatch
- **All Infrastructure**: In place and working

## Quick Context (Read First)
1. **Full experiment status**: `docs/development/experiments/laptop_sim_integration_oct21_2025.md`
2. **Architecture overview**: `docs/simulation/data_flow_architecture.md`
3. **Testing guide**: `docs/simulation/SIM_AUTONOMY_TESTING.md`

## Immediate Task: Fix Nav2 Configuration

### Step 1: Update Nav2 Parameters
```bash
# File: config/nav2_params.yaml
# FIND lines with frame references like "base_link"
# REPLACE with "robot0/base_link"
grep -n "base_link" config/nav2_params.yaml
```

**Frame IDs to update**:
- `base_frame_id` → should be `robot0/base_link`
- `global_frame_id` → should be `robot0/odom` or `map`
- All costmap frame references

**Topics to verify**:
- Laser scan source: `/robot0/scan` (not `/scan`)
- Odom source: `/robot0/odom` (not `/odom`)

### Step 2: Rebuild and Test
```bash
# Clean build
rm -rf build install log
./start.sh  # Rebuilds automatically

# In separate terminal:
source-ws

# Verify sensor pipeline
ros2 topic list | grep robot0
ros2 topic echo /robot0/scan --once
ros2 topic list | grep costmap

# Watch mission agent initialization
ros2 launch shadowhound_mission_agent mission_agent.launch.py
```

### Step 3: Validate Success
Mission agent should initialize with:
```
[mission_agent] [INFO] Waiting for /local_costmap/costmap...
[mission_agent] [INFO] Found /local_costmap/costmap
[mission_agent] [INFO] Mission executor initialized successfully
```

### Step 4: Manual Test
```bash
# Test basic skills
curl http://localhost:8080/api/execute -X POST \
  -H "Content-Type: application/json" \
  -d '{"skill": "report.say", "args": {"text": "hello from sim"}}'

# Test rotation
curl http://localhost:8080/api/execute -X POST \
  -H "Content-Type: application/json" \
  -d '{"skill": "nav.rotate", "args": {"yaw": 1.57}}'
```

## Key Files to Know

### Configuration
- `config/nav2_params.yaml` - **FIX THIS** (frame IDs)
- `config/nav2_params_sim.yaml` - May exist for sim-specific settings

### Launch Files
- `src/shadowhound_bringup/launch/sim_autonomy.launch.py` - Autonomy stack
- `src/shadowhound_bringup/launch/mission_agent.launch.py` - Mission agent (has remappings)
- `start.sh` - Entry point

### Documentation
- `docs/simulation/data_flow_architecture.md` - Full architecture
- `docs/development/experiments/laptop_sim_integration_oct21_2025.md` - This session's status

## Zombie Process Cleanup (If Needed)
```bash
# Kill all ROS processes
pgrep -f "ros-args" | awk '{print "kill -9 " $1}' | sh

# Verify clean state (should show 0 results)
ps -x | grep -i ros
```

## Expected Success Criteria
- ✅ Mission agent initializes without timeout
- ✅ Costmaps publish to `/robot0/local_costmap/costmap`
- ✅ Web interface responsive at http://localhost:8080
- ✅ `describe what you see` command works
- ✅ `spin 90 degrees` command works

## If Things Go Wrong
1. Check experiment doc for detailed troubleshooting: `docs/development/experiments/laptop_sim_integration_oct21_2025.md`
2. Run diagnostic commands in "RUNNING THE CURRENT STATE" section
3. Check TF frames: `ros2 run tf2_tools view_frames`
4. Check topics: `ros2 topic list` and `ros2 topic echo <topic_name>`

## Commit When Done
```bash
git add -A
git commit -m "feat(sim): fix nav2 namespace configuration

- Updated nav2_params.yaml frame IDs to use robot0/base_link
- Fixed costmap publishing for distributed architecture
- Mission agent initializes successfully
- All sensor pipeline working"

git push origin feature/laptop-sim-integration
```

## Then Update Development Log
After merging to main:
```bash
# Add entry to docs/development/devlog.md
# Link to this experiment document
# Include: date, type, status, key results, commits
```

---

**Good luck! You've got this. All the hard infrastructure work is done—this is just tuning configuration. 🚀**
