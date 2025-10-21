---
tags: [simulation, distributed-ros2, integration, experiments]
status: in-progress
related:
  - ../devlog.md
  - ../../simulation/data_flow_architecture.md
  - ../../deployment/SIMULATION_QUICKSTART.md
summary: >
  Laptop + Isaac Sim integration - Distributed ROS2 testing and debugging.
  Current blocker: Nav2 costmaps not publishing (TF frame mismatch issue).
---

# Laptop + Isaac Sim Integration Experiment
**Date**: October 21, 2025  
**Branch**: `feature/laptop-sim-integration`  
**Status**: 🔴 IN PROGRESS - Debugging TF/costmap issues

---

## Current Situation

### What Works ✅
- **Isaac Sim on Tower** publishing topics at good rates (`/robot0/*` namespace)
- **Network ROS2** configured and working (CycloneDDS, ROS_DOMAIN_ID=0)
- **Topic remappings** in mission_agent.launch.py mapping `/robot0/` topics
- **Autonomy stack** launches on laptop (Nav2, SLAM, Foxglove, RViz2)
- **TF frames from Tower** visible on laptop (`robot0/base_link`, `robot0/UnitreeL1_link`)
- **Laptop cleanup** working - zombie process issue resolved with `pgrep -f "ros-args"` command
- **Single-entry start.sh** integrated with sim autonomy stack launch

### What's Broken 🔴
- **Nav2 costmaps not publishing** - Mission agent times out waiting for `/local_costmap/costmap`
- **RViz2 point cloud visualization** not working (TF frame issue)
- **Spatial memory initialization failing** - `"map" frame does not exist` error

### Current Error Pattern
```
[mission_agent-1] 2025-10-20 19:59:11,760 - ERROR - /local_costmap/costmap message not received after 30.0 seconds
[mission_agent-1] [ERROR] Failed to initialize MissionExecutor: /local_costmap/costmap message not received after 30.0 seconds
```

---

## Root Cause Analysis

### The TF Tree Problem

**TF frames detected on laptop**:
```
Laptop's TF Tree:
- base_link → odom (stale, rate: 10000 Hz but most_recent_transform: 0.000)
- Many robot leg links (all stale)

Tower's TF Tree (ACTIVE):
- robot0/base_link → odom (rate: 13.3 Hz, actively updating)
- robot0/UnitreeL1_link → robot0/base_link (rate: 13.3 Hz, actively updating)
- robot0/lidar_link → robot0/base_link (rate: 13.3 Hz, actively updating)
```

**Issue**: Two separate TF trees exist:
1. **Stale tree** (without `robot0/` prefix) - NOT updating
2. **Active tree** (with `robot0/` prefix) - actively updating from Tower

### Why Nav2 Costmaps Fail

Nav2 configuration uses frames **without** `robot0/` prefix:
- `base_link` (not `robot0/base_link`)
- `odom` (matches)
- `map` (doesn't exist)

When `pointcloud_to_laserscan` tries to convert using `robot0/base_link`, it works. But Nav2 can't access the data because it's looking for frames that don't exist or are stale.

---

## Solutions Attempted

### ❌ Attempt 1: Remove robot_state_publisher from sim_autonomy.launch.py
**Rationale**: Tower already publishes TF, so laptop shouldn't duplicate

**Result**: Still no costmaps, TF frames still separated

**Insight**: Confirmed that removing the publisher doesn't hurt, but doesn't fix the core issue

### ❌ Attempt 2: Check if TF frames propagate properly
**Command**: `ros2 run tf2_ros tf2_echo robot0/base_link robot0/UnitreeL1_link`

**Result**: ✅ Works - frames DO propagate to laptop

**Insight**: Network TF propagation is fine; issue is with Nav2 configuration and frame naming

---

## Key Discoveries

### 1. Zombie Process Issue (NOW RESOLVED ✅)
**Problem**: Multiple `robot_state_publisher` instances from previous launches (30+ processes!)

**Solution**: Use `pgrep -f "ros-args"` to kill ALL ROS processes robustly
```bash
pgrep -f "ros-args" | awk '{print "kill -9 " $1}' | sh
```

**Why this works**: Catches all ROS launch children, not just main process

**Integration**: Updated `kill_all_ros_nodes()` in start.sh to use this pattern

### 2. TF Tree Architecture
Tower publishes **TWO separate TF trees** (unclear why):
- Without `robot0/` prefix (stale)
- With `robot0/` prefix (active)

This is likely because Isaac Sim is running go2_ros2_sdk which publishes both namespaced and non-namespaced frames.

### 3. Topic Remappings Work
Mission agent topic remappings in launch file successfully map:
- `/cmd_vel` → `/robot0/cmd_vel` ✅
- `/odom` → `/robot0/odom` ✅
- `/local_costmap/costmap` → `/robot0/local_costmap/costmap` ✅ (but topic doesn't exist)

---

## Next Steps (For New Chat)

### High Priority 🔴
1. **Check what Nav2 is actually subscribing to** - may need to trace topic subscriptions
2. **Check if SLAM Toolbox is publishing costmaps** - verify SLAM initialization
3. **Verify pointcloud_to_laserscan is working** - check `/robot0/scan` topic being published
4. **Check Nav2 parameter configuration** - frame IDs may need `robot0/` prefix updates

### Diagnostic Commands to Run
```bash
# Check if costmap topics exist (they shouldn't yet)
ros2 topic list | grep costmap

# Check if laser scan is being published
ros2 topic echo /robot0/scan --once

# Check SLAM status
ros2 node list | grep slam

# Check Nav2 status
ros2 node list | grep -E "behavior|planner|controller"

# Check if Nav2 action servers are ready
ros2 action list | grep -E "navigate|spin"
```

### Configuration Files to Review
- `config/nav2_params.yaml` - Frame ID settings (may need `robot0/` prefix)
- `src/shadowhound_bringup/launch/sim_autonomy.launch.py` - Parameter passing to Nav2
- `src/shadowhound_mission_agent/launch/mission_agent.launch.py` - Topic remappings

### Potential Fixes
1. **Update nav2_params.yaml** to use `robot0/base_link` instead of `base_link`
2. **Create simulation-specific nav2 config** that handles `robot0/` namespace
3. **Add parameter to sim_autonomy.launch.py** for robot namespace
4. **Verify SLAM Toolbox launch** is correct for simulation

---

## Files Modified This Session

### New Files Created
- `src/shadowhound_bringup/launch/sim_autonomy.launch.py` - Autonomy stack orchestration
- `docs/simulation/data_flow_architecture.md` - Architecture documentation  
- `docs/simulation/SIM_AUTONOMY_TESTING.md` - Manual testing guide
- `docs/deployment/SIMULATION_QUICKSTART.md` - Quick start guide

### Files Updated
- `start.sh` - Added `launch_sim_autonomy_stack()`, integrated sim mode, fixed bash return syntax, enhanced cleanup
- `src/shadowhound_mission_agent/launch/mission_agent.launch.py` - Topic remappings for `robot0/` namespace
- `src/shadowhound_bringup/launch/sim_autonomy.launch.py` - Removed duplicate robot_state_publisher

### Commits on Branch
1. `feat(sim-autonomy): create simulation autonomy launch orchestration`
2. `feat(mission-agent): add topic remapping for go2_omniverse sim namespace`
3. `feat(start): integrate sim autonomy stack into start.sh`
4. `docs(deployment): add simulation quick start guide`
5. `fix(start): correct bash return statement syntax`
6. `fix(sim-autonomy): don't launch robot_state_publisher for simulation`

---

## Running the Current State

```bash
# Kill all ROS processes (robust method)
pgrep -f "ros-args" | awk '{print "kill -9 " $1}' | sh

# Launch system (with clean slate)
cd /workspaces/shadowhound
./start.sh

# In new terminal, check status
source /workspaces/shadowhound/.shadowhound_env
ros2 topic list | grep -E "robot0|costmap"
ros2 node list
```

---

## Reference Architecture

```
┌─────────────────────────────────────────┐
│ Tower (192.168.10.167)                  │
│ - Isaac Sim                             │
│ - go2_driver_node                       │
│ - Publishing /robot0/* topics           │
│ - Publishing TF (robot0/base_link, etc) │
└─────────────────┬───────────────────────┘
                  │
                  │ ROS2 (CycloneDDS)
                  │ /robot0/* topics
                  │ /tf, /tf_static
                  ▼
┌─────────────────────────────────────────┐
│ Laptop (Dev Machine)                    │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ sim_autonomy.launch.py              │ │
│ │ - Nav2 stack (nav2:=true)           │ │
│ │ - SLAM Toolbox (slam:=true)         │ │
│ │ - pointcloud_to_laserscan           │ │
│ │ - robot_state_publisher (REMOVED)   │ │
│ │ - Foxglove, RViz2                   │ │
│ └─────────────────────────────────────┘ │
│            ↓                             │
│ ┌─────────────────────────────────────┐ │
│ │ mission_agent.launch.py             │ │
│ │ - Topic remappings /robot0/*        │ │
│ │ - Mission executor                  │ │
│ │ - Web UI (port 8080)                │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## Environment Variables

```bash
# .env settings for simulation
ROBOT_MODE=simulation
ROS_DOMAIN_ID=0
ROS_LOCALHOST_ONLY=0
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# LLM backend
AGENT_BACKEND=openai
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4-turbo

# Network
CONN_TYPE=cyclonedds  # (webrtc not available in sim mode)
```

---

## Summary for New Chat

**Status**: Mission agent launches but crashes waiting for `/local_costmap/costmap` (30s timeout)

**Root Cause**: Nav2 costmaps not publishing because:
1. TF frame mismatch (`base_link` vs `robot0/base_link`)
2. Possibly SLAM not initialized properly
3. Possibly pointcloud_to_laserscan not publishing `/robot0/scan`

**Next**: Debug why Nav2 costmaps not publishing - check SLAM initialization, laser scan topic, and Nav2 node status

**Quick Start New Chat**: 
> "We're debugging laptop + Isaac Sim integration. Mission agent hangs waiting for `/local_costmap/costmap` topic. See `/workspaces/shadowhound/docs/development/experiments/laptop_sim_integration_oct21_2025.md` for full context. Need to debug why Nav2 costmaps not publishing."
