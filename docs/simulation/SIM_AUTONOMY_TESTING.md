---
tags: [simulation, testing, nav2, slam]
status: active
related: 
  - data_flow_architecture.md
  - TESTING_SIM.md
summary: >
  Testing guide for simulation autonomy stack with Nav2 and SLAM on laptop.
---

# Simulation Autonomy Stack Testing Guide

## Overview

This guide walks through testing the autonomy stack (Nav2 + SLAM + Mission Agent) with Isaac Sim running on Tower and the laptop running all navigation/planning components.

**Key Architecture**:
- **Tower**: Isaac Sim (publishes `/robot0/*` topics)
- **Laptop**: Nav2, SLAM, Foxglove, RViz2, Mission Agent

**Why this works**: Isaac Sim publishes standard ROS2 topics directly, replacing `go2_driver_node`. See [data_flow_architecture.md](data_flow_architecture.md) for details.

---

## Prerequisites

### 1. Network Configuration

Both Tower and Laptop must have:

```bash
# Add to ~/.bashrc or set before each test
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
```

### 2. Tower: Isaac Sim Running

On Tower, start Isaac Sim with the Go2 robot:

```bash
# (Tower-specific command - refer to Isaac Sim setup docs)
# Sim should publish topics under /robot0/ namespace
```

Verify topics:

```bash
# From laptop
ros2 topic list | grep robot0

# Expected output:
/robot0/cmd_vel
/robot0/odom
/robot0/imu
/robot0/front_cam/rgb
/robot0/point_cloud2_L1
/robot0/go2_states
/robot0/joint_states
```

### 3. Laptop: Workspace Built

```bash
cd /workspaces/shadowhound
source source_shadowhound.sh
colcon build --symlink-install
source install/setup.bash
```

---

## Testing Procedure

### Test 1: Launch Autonomy Stack (No Mission Agent)

**Goal**: Verify Nav2, SLAM, and visualization tools launch successfully.

```bash
# Terminal 1: Launch autonomy stack
source /workspaces/shadowhound/install/setup.bash
ros2 launch shadowhound_bringup sim_autonomy.launch.py \
    rviz2:=true \
    nav2:=true \
    slam:=true \
    foxglove:=true
```

**Expected Output**:

```
🚀 SIMULATION AUTONOMY STACK
============================================================
Prerequisites:
  1. Isaac Sim running on Tower (publishing /robot0/* topics)
  2. Network ROS2 configured:
     - ROS_DOMAIN_ID=0
     - ROS_LOCALHOST_ONLY=0
     - RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

Launching:
  ✅ Robot state publisher (TF transforms)
  ✅ Pointcloud to laserscan converter
  ✅ Nav2 (if enabled)
  ✅ SLAM Toolbox (if enabled)
  ✅ Foxglove Bridge (if enabled)
  ✅ RViz2 (if enabled)

NOT Launching:
  ❌ go2_driver_node (Isaac Sim replaces this!)
============================================================

[INFO] [slam_toolbox]: Message Filter dropping message: frame 'robot0/hesai_lidar'...
[INFO] [controller_server]: Controller server has bond to lifecycle manager
[INFO] [planner_server]: Planner server has bond to lifecycle manager
```

**Validation Checks**:

```bash
# Terminal 2: Verify Nav2 action servers
ros2 action list | grep -E "navigate|spin|backup"

# Expected:
/backup
/navigate_to_pose
/spin

# Verify Nav2 nodes
ros2 node list | grep -E "controller|planner|behavior"

# Expected:
/behavior_server
/bt_navigator
/controller_server
/planner_server
/waypoint_follower

# Verify SLAM running
ros2 node list | grep slam

# Expected:
/slam_toolbox
```

**Success Criteria**:
- ✅ All Nav2 action servers available (especially `/spin`)
- ✅ SLAM Toolbox running
- ✅ RViz2 shows robot model and laser scan
- ✅ Foxglove Bridge on port 8765

---

### Test 2: Nav2 Basic Commands

**Goal**: Test Nav2 directly without mission agent.

```bash
# Terminal 3: Send test commands

# 1. Test spin action (90 degrees)
ros2 action send_goal /spin nav2_msgs/action/Spin \
    "{target_yaw: 1.57}" \
    --feedback

# Expected: Robot spins 90 degrees in RViz/Foxglove

# 2. Test navigation to pose
ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose \
    "{pose: {header: {frame_id: 'map'}, pose: {position: {x: 1.0, y: 0.0, z: 0.0}}}}" \
    --feedback

# Expected: Robot plans path and moves to (1, 0)
```

**Success Criteria**:
- ✅ Spin action completes without errors
- ✅ Navigate action plans valid path
- ✅ Robot moves in simulation
- ✅ SLAM updates map in RViz

---

### Test 3: Launch Mission Agent

**Goal**: Test mission agent initialization with Nav2 running.

```bash
# Terminal 4: Launch mission agent
source /workspaces/shadowhound/install/setup.bash
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    robot_mode:=simulation \
    agent_backend:=openai

# OR for local LLM:
ros2 launch shadowhound_mission_agent mission_agent.launch.py \
    robot_mode:=simulation \
    agent_backend:=ollama \
    ollama_base_url:=http://192.168.10.116:8000/v1
```

**Expected Output**:

```
[INFO] [mission_agent]: Mission agent initializing...
[INFO] [mission_agent]: Using robot mode: simulation
[INFO] [mission_agent]: Agent backend: openai
[INFO] [mission_agent]: Subscribing to camera/image_raw with BEST_EFFORT QoS
[INFO] [mission_agent]: Waiting for /spin action server...
[INFO] [mission_agent]: Robot initialized ✓
[INFO] [mission_agent]: Mission agent ready
[INFO] [mission_agent]: Web interface: http://localhost:8080
```

**Success Criteria**:
- ✅ NO HANG at "Waiting for /spin action server"
- ✅ "Robot initialized ✓" message appears
- ✅ Web interface accessible at http://localhost:8080

---

### Test 4: End-to-End Mission Execution

**Goal**: Execute natural language missions through web interface.

1. **Open Web Interface**: http://localhost:8080

2. **Test Vision**:
   - Command: `"describe what you see"`
   - Expected: Agent describes environment from camera image

3. **Test Rotation**:
   - Command: `"spin 90 degrees clockwise"`
   - Expected: Robot rotates using Nav2 `/spin` action

4. **Test Navigation**:
   - Command: `"move forward 1 meter"`
   - Expected: Robot navigates to goal pose

5. **Test Complex Mission**:
   - Command: `"explore the room and tell me what objects you see"`
   - Expected: Agent plans waypoints, navigates, captures images, reports

**Success Criteria**:
- ✅ Vision commands return camera descriptions
- ✅ Rotation commands execute without hanging
- ✅ Navigation commands complete successfully
- ✅ SLAM map updates during movement
- ✅ Mission agent logs show skill execution

---

## Troubleshooting

### Issue: "Waiting for /spin action server" Hangs

**Symptoms**:
- Mission agent stuck initializing
- No "Robot initialized" message

**Cause**: Nav2 not running or action server not advertising

**Solution**:

```bash
# Check if Nav2 launched
ros2 node list | grep -E "controller|planner|behavior"

# Check if action server exists
ros2 action list | grep spin

# If missing, restart sim_autonomy.launch.py with nav2:=true
```

---

### Issue: "Message Filter dropping message: frame 'robot0/hesai_lidar'"

**Symptoms**:
- SLAM Toolbox warnings about frame transforms
- Map not updating

**Cause**: TF frames not publishing or namespace mismatch

**Solution**:

```bash
# Check TF tree
ros2 run tf2_tools view_frames

# Verify robot0 namespace frames exist:
# - robot0/base_link
# - robot0/hesai_lidar
# - robot0/odom

# If missing, check robot_state_publisher in sim_autonomy.launch.py
```

---

### Issue: RViz shows no laser scan

**Symptoms**:
- RViz loads but no laser scan visualization
- Empty map

**Cause**: Pointcloud to laserscan converter not working

**Solution**:

```bash
# Check topics
ros2 topic list | grep scan

# Should see:
/robot0/scan  # From pointcloud_to_laserscan

# Check if pointcloud exists
ros2 topic list | grep point_cloud2_L1

# Should see:
/robot0/point_cloud2_L1  # From Isaac Sim

# Check converter node
ros2 node list | grep pointcloud_to_laserscan

# If missing, check sim_autonomy.launch.py
```

---

### Issue: Nav2 plans invalid paths

**Symptoms**:
- Navigation action fails
- "No valid path found" errors

**Cause**: nav2_params.yaml configuration mismatch

**Solution**:

```bash
# Check costmap topics
ros2 topic list | grep costmap

# Verify nav2_params.yaml has correct frame_id:
# - global_frame: map
# - robot_base_frame: robot0/base_link
# - odom_topic: /robot0/odom

# Edit config/nav2_params.yaml if needed
```

---

### Issue: Foxglove shows no data

**Symptoms**:
- Foxglove Studio connects but no topics visible

**Cause**: Foxglove Bridge not advertising topics

**Solution**:

```bash
# Check Foxglove Bridge node
ros2 node list | grep foxglove

# Verify port
netstat -an | grep 8765

# Reconnect Foxglove Studio to ws://laptop-ip:8765
```

---

## Performance Monitoring

### Expected Resource Usage

**Laptop (Dell XPS 15)**:
- CPU: 30-50% during navigation
- RAM: 4-6 GB
- Network: 5-10 Mbps (topic traffic)

**Metrics to Monitor**:

```bash
# Topic bandwidth
ros2 topic bw /robot0/odom
ros2 topic bw /robot0/front_cam/rgb

# Topic rate
ros2 topic hz /robot0/scan
ros2 topic hz /robot0/odom

# Node resource usage
htop  # Filter for ROS nodes
```

---

## Launch File Options

### Minimal (Nav2 Only)

```bash
ros2 launch shadowhound_bringup sim_autonomy.launch.py \
    rviz2:=false \
    nav2:=true \
    slam:=false \
    foxglove:=false
```

Use when: Testing Nav2 action servers without visualization overhead.

---

### Full Stack (All Components)

```bash
ros2 launch shadowhound_bringup sim_autonomy.launch.py \
    rviz2:=true \
    nav2:=true \
    slam:=true \
    foxglove:=true
```

Use when: Full autonomy testing with visualization.

---

### Simulation Time Mode

```bash
ros2 launch shadowhound_bringup sim_autonomy.launch.py \
    use_sim_time:=true
```

Use when: Isaac Sim publishes `/clock` topic and you want time synchronization.

---

## Next Steps

After successful testing:

1. **Integrate with CI/CD**: Add automated tests for Nav2 action servers
2. **Performance Tuning**: Adjust nav2_params.yaml for optimal path planning
3. **Mission Complexity**: Test multi-step missions with vision + navigation
4. **Hardware Testing**: Validate on physical Go2 robot

---

## References

- [data_flow_architecture.md](data_flow_architecture.md) - Why Isaac Sim replaces go2_driver_node
- [TESTING_SIM.md](TESTING_SIM.md) - Original simulation testing guide
- [Nav2 Documentation](https://navigation.ros.org/) - Navigation stack reference
- [SLAM Toolbox](https://github.com/SteveMacenski/slam_toolbox) - Mapping system docs
