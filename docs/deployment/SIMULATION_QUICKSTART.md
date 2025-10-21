---
tags: [simulation, quickstart, deployment]
status: active
related: 
  - ../simulation/data_flow_architecture.md
  - ../simulation/SIM_AUTONOMY_TESTING.md
summary: >
  Quick start guide for running ShadowHound with Isaac Sim using unified start.sh entry point.
---

# Simulation Quick Start Guide

**Single-command deployment for laptop + Isaac Sim distributed setup.**

---

## Prerequisites

### 1. Tower (Isaac Sim)

Isaac Sim must be running and publishing topics:

```bash
# On Tower (192.168.10.167)
# Start Isaac Sim with Go2 robot
# (Refer to Isaac Sim setup documentation)
```

### 2. Laptop (ShadowHound)

Ensure environment is configured:

```bash
# Check/edit .env file
cd /workspaces/shadowhound
cat .env

# Required settings:
ROBOT_MODE=simulation
ROS_DOMAIN_ID=0
ROS_LOCALHOST_ONLY=0
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# LLM backend (choose one):
AGENT_BACKEND=openai
OPENAI_API_KEY=sk-your-key-here

# OR
AGENT_BACKEND=ollama
OLLAMA_BASE_URL=http://192.168.10.116:8000/v1
OLLAMA_MODEL=qwen2.5-coder:32b
```

### 3. Network Validation

Verify Isaac Sim topics are visible from laptop:

```bash
# Should see /robot0/* topics
ros2 topic list | grep robot0

# Expected output:
/robot0/cmd_vel
/robot0/odom
/robot0/imu
/robot0/front_cam/rgb
/robot0/point_cloud2_L1
/robot0/joint_states
/robot0/go2_states
```

---

## Launch Commands

### **Single-Command Launch** (Recommended)

The unified `start.sh` script handles everything:

```bash
cd /workspaces/shadowhound
./start.sh
```

**What it does automatically:**
1. ✅ Detects `ROBOT_MODE=simulation` from `.env`
2. ✅ Launches autonomy stack (Nav2, SLAM, Foxglove, RViz2)
3. ✅ Waits for Nav2 action servers (`/spin`)
4. ✅ Verifies Isaac Sim topics
5. ✅ Launches mission agent
6. ✅ Opens web UI at http://localhost:8080

**Expected output:**

```
🚀 SIMULATION AUTONOMY STACK
============================================================
Prerequisites:
  1. Isaac Sim running on Tower (publishing /robot0/* topics)
  2. Network ROS2 configured

Launching:
  ✅ Robot state publisher (TF transforms)
  ✅ Pointcloud to laserscan converter
  ✅ Nav2 (if enabled)
  ✅ SLAM Toolbox (if enabled)
  ✅ Foxglove Bridge (if enabled)
  ✅ RViz2 (if enabled)
============================================================

✓ Isaac Sim topics detected!
  • /robot0/cmd_vel
  • /robot0/odom
  • /robot0/imu
  • /robot0/front_cam/rgb
  • /robot0/point_cloud2_L1

✓ Autonomy stack launched (PID: 12345)
✓ Nav2 nodes detected!
✓ Nav2 /spin action server available!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 Web Dashboard will be available at: http://localhost:8080
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### **Environment Variable Override**

Override `.env` settings with environment variables:

```bash
# Use different LLM backend
AGENT_BACKEND=ollama ./start.sh

# Use custom Ollama URL
OLLAMA_BASE_URL=http://192.168.10.116:8000/v1 ./start.sh

# Disable web interface
WEB_INTERFACE=false ./start.sh
```

---

### **Command-Line Flags**

Alternative to environment variables:

```bash
# Agent-only mode (autonomy stack already running)
./start.sh --agent-only

# Skip repository update check
./start.sh --skip-update

# Auto-pull latest changes
./start.sh --auto-update

# Help
./start.sh --help
```

---

## Verification Steps

### 1. Check Autonomy Stack

```bash
# In another terminal
source /workspaces/shadowhound/.shadowhound_env

# Verify Nav2 nodes
ros2 node list | grep -E "behavior|controller|planner"

# Expected:
/behavior_server
/bt_navigator
/controller_server
/planner_server
/waypoint_follower

# Verify action servers
ros2 action list | grep -E "spin|navigate|backup"

# Expected:
/backup
/navigate_to_pose
/spin
```

### 2. Check Mission Agent

```bash
# Look for these log messages:
[INFO] [mission_agent]: Robot initialized ✓
[INFO] [mission_agent]: Mission agent ready
[INFO] [mission_agent]: Web interface: http://localhost:8080
```

### 3. Test Web Interface

Open browser to http://localhost:8080

Try these commands:
- `"describe what you see"` - Vision test
- `"spin 90 degrees"` - Nav2 /spin action test
- `"move forward 1 meter"` - Navigation test

---

## Troubleshooting

### Issue: "No /robot0/* topics detected"

**Cause:** Isaac Sim not running or network issue

**Solution:**
```bash
# On Tower, check Isaac Sim is running
# Verify ROS_DOMAIN_ID matches on both machines

# On laptop, check network
ros2 topic list  # Should see Tower's topics
ping 192.168.10.167  # Should reach Tower
```

---

### Issue: "Timeout waiting for Nav2 nodes"

**Cause:** Nav2 taking longer than 30s to initialize

**Solution:**
```bash
# Check autonomy stack logs
tail -f /tmp/shadowhound_sim_autonomy.log

# Common issues:
# - Missing Nav2 parameters
# - TF frame mismatches
# - Costmap configuration errors
```

---

### Issue: "/spin action not available"

**Cause:** Nav2 behavior server not fully initialized

**Solution:**
```bash
# Wait a few more seconds and check again
ros2 action list | grep spin

# If still missing after 1 minute:
# Restart autonomy stack
pkill -f sim_autonomy.launch
./start.sh
```

---

### Issue: "Mission agent hangs at initialization"

**Cause:** Missing Nav2 action server or topics

**Solution:**
```bash
# Verify all prerequisites:
ros2 topic list | grep robot0  # Isaac Sim topics
ros2 action list | grep spin   # Nav2 action server
ros2 node list | grep behavior # Nav2 nodes

# If any missing, restart from step 1
```

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│ Tower (192.168.10.167)                                      │
│                                                              │
│  Isaac Sim                                                   │
│  └─ Publishes /robot0/* topics                             │
│     ├─ /robot0/cmd_vel        (subscribes)                 │
│     ├─ /robot0/odom           (publishes)                  │
│     ├─ /robot0/imu            (publishes)                  │
│     ├─ /robot0/front_cam/rgb  (publishes)                  │
│     └─ /robot0/point_cloud2_L1 (publishes)                 │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ ROS2 Topics
                          │ (CycloneDDS)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Laptop (Development Machine)                                │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Autonomy Stack (sim_autonomy.launch.py)             │  │
│  │ - Nav2 (navigation + /spin action)                   │  │
│  │ - SLAM Toolbox (mapping)                             │  │
│  │ - Foxglove Bridge (port 8765)                        │  │
│  │ - RViz2 (3D visualization)                           │  │
│  │ - robot_state_publisher (TF transforms)              │  │
│  │ - pointcloud_to_laserscan (sensor conversion)        │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Mission Agent (shadowhound_mission_agent)           │  │
│  │ - DIMOS framework                                    │  │
│  │ - LLM planning (OpenAI or Ollama)                    │  │
│  │ - Web interface (port 8080)                          │  │
│  │ - Topic remapping (/robot0/*)                        │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Comparison: Manual vs Unified

### **Before (Manual Two-Terminal Setup)**

```bash
# Terminal 1
ros2 launch shadowhound_bringup sim_autonomy.launch.py

# Wait for Nav2...

# Terminal 2
./start.sh --agent-only
```

**Pros:** More control, separate logs  
**Cons:** Two commands, manual timing, easy to forget steps

---

### **After (Unified start.sh)**

```bash
# Single command
./start.sh
```

**Pros:** One command, automatic sequencing, proper error handling  
**Cons:** Combined logs (use /tmp/*.log for separation)

---

## Log Files

All processes log to `/tmp/`:

```bash
# Autonomy stack logs
tail -f /tmp/shadowhound_sim_autonomy.log

# Mission agent logs (if launched separately)
tail -f /tmp/shadowhound_mission_agent.log

# Combined logs (start.sh output)
# Just read terminal output
```

---

## Shutdown

Press `Ctrl+C` in the start.sh terminal:

```
🔄 Shutting Down
✓ Stopping simulation autonomy stack (PID: 12345)...
✓ Cleaning up ROS nodes...
✓ Shutdown complete
```

**Cleanup is automatic!** All launched processes are tracked and killed gracefully.

---

## Next Steps

After successful launch:

1. **Test vision**: Open http://localhost:8080, try `"describe what you see"`
2. **Test navigation**: Try `"spin 90 degrees"` or `"move forward 1 meter"`
3. **Monitor in Foxglove**: Open Foxglove Studio, connect to `ws://localhost:8765`
4. **Watch in RViz2**: See 3D visualization of robot, map, costmaps

---

## Related Documentation

- [Data Flow Architecture](../simulation/data_flow_architecture.md) - Why Isaac Sim replaces go2_driver_node
- [Testing Guide](../simulation/SIM_AUTONOMY_TESTING.md) - Detailed testing procedures
- [Network Setup](../networking/ros2_networking.md) - ROS2 distributed setup
- [Troubleshooting](../troubleshooting/simulation_issues.md) - Common problems

---

## Summary

**Single-command deployment:**
```bash
./start.sh
```

**What you get:**
- ✅ Nav2 navigation stack
- ✅ SLAM mapping
- ✅ Foxglove visualization
- ✅ RViz2 3D view
- ✅ Mission agent with web UI
- ✅ Automatic cleanup on exit

**Requirements:**
- Isaac Sim running on Tower
- `ROBOT_MODE=simulation` in `.env`
- Network ROS2 configured

**Access:**
- Web UI: http://localhost:8080
- Foxglove: ws://localhost:8765
- RViz2: Launched automatically

🎉 **You're ready to test autonomous missions!**
