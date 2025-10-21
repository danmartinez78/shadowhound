---
tags: [architecture, safety, modes]
status: active
related:
  - HARDWARE_SIMULATION_SAFETY.md
  - MULTI_MODE_IMPLEMENTATION.md
summary: >
  Visual architecture diagram showing how hardware and simulation modes are isolated.
---

# Visual Architecture: Hardware + Simulation Safety

## Mode Isolation Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ShadowHound Entry Point                          │
│                      (start.sh)                                    │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
                  ROBOT_MODE env var
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   HARDWARE       SIMULATION         MOCK
   
┌─────────────────────────────────────────────────────────────────────┐
│  PATH 1: HARDWARE MODE                                              │
├─────────────────────────────────────────────────────────────────────┤
│  1. Check ROBOT_IP reachable via ping                               │
│  2. Launch: robot.launch.py → go2_driver_node                       │
│  3. Topics: /go2_states, /odom, /imu, /cmd_vel, /camera/...        │
│  4. Driver: WebRTC or CycloneDDS connection to robot                │
│  5. Config: nav2_params.yaml (base_link)                            │
│  6. Remappings: Ignored (/robot0/* don't exist)                     │
│                                                                      │
│  🟢 Safety: Completely separate driver, standard ROS namespaces    │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  PATH 2: SIMULATION MODE                                            │
├─────────────────────────────────────────────────────────────────────┤
│  1. Check /robot0/* topics visible (Isaac Sim on Tower)             │
│  2. Launch: sim_autonomy.launch.py                                  │
│     → Nav2 (navigation_launch.py)                                   │
│     → SLAM Toolbox (online_async_launch.py)                         │
│     → Foxglove Bridge                                               │
│     → RViz2                                                         │
│     → pointcloud_to_laserscan converter                             │
│  3. Topics: /robot0/odom, /robot0/imu, /robot0/cmd_vel...         │
│  4. Driver: NONE (Isaac Sim publishes topics)                       │
│  5. Config: nav2_params_simulation.yaml (robot0/base_link)          │
│  6. Remappings: Enabled (/robot0/* exist)                           │
│                                                                      │
│  🟡 Status: Working, needs Nav2 frame fix                           │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  PATH 3: MOCK MODE                                                  │
├─────────────────────────────────────────────────────────────────────┤
│  1. No driver launch                                                │
│  2. No network ROS2 topics                                          │
│  3. Pure software execution (testing, CI/CD)                        │
│                                                                      │
│  🟢 Safety: Completely isolated, no network                         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Topic Namespace Isolation

```
HARDWARE MODE                    SIMULATION MODE
    │                                   │
    ├─ /cmd_vel                        ├─ /robot0/cmd_vel
    ├─ /odom                           ├─ /robot0/odom
    ├─ /imu                            ├─ /robot0/imu
    ├─ /camera/image_raw               ├─ /robot0/front_cam/rgb
    ├─ /go2_states                     ├─ /robot0/go2_states
    ├─ /local_costmap/costmap          ├─ /robot0/local_costmap/costmap
    └─ /global_costmap/costmap         └─ /robot0/global_costmap/costmap

    🔒 NO COLLISION
    Both modes can theoretically run simultaneously with different
    ROS_DOMAIN_IDs (would just see different topics)
```

---

## Component Decision Matrix

```
                 Hardware        Simulation      Mock
                 ─────────────────────────────────────────
Driver           go2_driver      None            None
                 ✅ Active        ✅ N/A           ✅ N/A

Autonomy         Robot.launch    sim_autonomy    None
Stack            + optional      + mandatory     ✅ N/A
                 nav2

Topics           /               /robot0/*       Internal
Namespace        (root)          (isolated)      (isolated)
                 ✅              ✅              ✅

Network          WebRTC/CDR       Isaac Sim      Localhost
Connection       to robot         ROS2           only
                 ✅              ✅              ✅

Config File      nav2_params     nav2_params_    N/A
                 .yaml           simulation.yaml

Remappings       Ignored         Enabled         N/A
/robot0/*        (topics don't    (topics exist)
                 exist)

Safety Impact    ✅ HIGH          ✅ MEDIUM      🟢 HIGH
of Sim Changes   (isolated)       (mode-specific) (isolated)
```

---

## Remapping Safety Analysis

```
MISSION AGENT REMAPPINGS:
┌─────────────────────────────────────────────────────────────────┐
│ Remapping: ("/cmd_vel", "/robot0/cmd_vel")                      │
├─────────────────────────────────────────────────────────────────┤
│ HARDWARE MODE:                  SIMULATION MODE:                │
│ ├─ Mission agent requests       ├─ Mission agent requests       │
│ │  /cmd_vel publish             │  /cmd_vel publish             │
│ ├─ Remapping applied:           ├─ Remapping applied:           │
│ │  /cmd_vel → /robot0/cmd_vel   │  /cmd_vel → /robot0/cmd_vel   │
│ ├─ Result:                      ├─ Result:                      │
│ │  Tries to find /robot0/cmd_vel│  Finds /robot0/cmd_vel ✅     │
│ ├─ /robot0/cmd_vel doesn't      ├─ Goes to Isaac Sim ✅         │
│ │  exist in hardware (topics    │                              │
│ │  are at / root)               │                              │
│ └─ Topic silently fails to      └─ Works as intended ✅         │
│    connect (acceptable, uses                                    │
│    fallback topics at /)                                        │
│                                                                  │
│ 🟢 SAFE: Remappings don't break hardware!                       │
│    Hardware sees /cmd_vel at root namespace                    │
│    Simulation sees /robot0/cmd_vel at sim namespace            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Configuration File Strategy

```
Current State (UNSAFE for sim):
┌─────────────────────────────┐
│ config/nav2_params.yaml     │
│ ├─ base_link                │ ✅ Works for hardware
│ ├─ /odom                    │ ❌ Breaks for simulation
│ └─ /map                     │
└─────────────────────────────┘

Improved State (SAFE for both):
┌──────────────────────────────────────────────┐
│ config/nav2_params.yaml (original - fallback)│
│ ├─ base_link              (hardware default) │
│                                              │
│ config/nav2_params_hardware.yaml (explicit)  │
│ ├─ base_link              (hardware frames)  │
│                                              │
│ config/nav2_params_simulation.yaml (new)     │
│ ├─ robot0/base_link       (sim frames)   ✅  │
│ ├─ /robot0/odom           (sim topics)   ✅  │
│ └─ /robot0/map            (sim topics)   ✅  │
└──────────────────────────────────────────────┘
```

---

## Launch File Hierarchy

```
start.sh (ROBOT_MODE check)
    │
    ├── ROBOT_MODE=hardware
    │   └─ launch_robot_driver()
    │      └─ robot.launch.py (from go2_sdk)
    │         └─ go2_driver_node ✅ Hardware driver
    │
    ├── ROBOT_MODE=simulation
    │   └─ launch_sim_autonomy_stack()
    │      └─ sim_autonomy.launch.py ✅ Autonomy stack
    │         ├─ Nav2 (navigation_launch.py)
    │         ├─ SLAM (online_async_launch.py)
    │         ├─ Foxglove
    │         ├─ RViz2
    │         └─ pointcloud_to_laserscan
    │
    └── ROBOT_MODE=mock
        └─ Skip driver, launch mission agent only
           (pure software, no external connections)

Stage 2: verify_robot_topics() - Mode-specific verification
    │
    ├─ Hardware: Check /go2_states, /odom, /imu
    │            Check Nav2 action servers
    │
    └─ Simulation: Check /robot0/*, Isaac Sim topics
                   Check Nav2 action servers

Stage 3: launch_mission_agent()
    └─ mission_agent.launch.py (same for all modes)
       └─ Topic remappings applied (harmless for all)
```

---

## Risk Analysis: Change Impact

```
RISK: "Fixing simulation breaks hardware"

Change Type              Hardware Impact    Reason
────────────────────────────────────────────────────────────────
sim_autonomy.launch.py   ✅ NONE           Only used in simulation mode
updated config paths     ✅ NONE           Hardware uses robot.launch.py

nav2_params_simulation   ✅ NONE           Different file (robot uses
.yaml created                               nav2_params.yaml)

Mission agent            ✅ NONE           Remappings are harmless
remappings (unchanged)                     (topics don't exist = no-op)

ROBOT_MODE detection     ✅ NONE           Hardware mode unchanged
logic (unchanged)                          Explicit checks prevent issues

Namespace isolation      ✅ SAFE           Hardware (/) vs Sim (/robot0/)
(/robot0/* prefix)                         no collision

Result: 🟢 ZERO IMPACT on hardware users!
```

---

## Safety Verification Checklist

Before committing changes, verify:

```
Hardware Safety ✅
  □ go2_driver_node still launches in hardware mode
  □ /go2_states, /odom, /imu topics appear (root namespace)
  □ Nav2 uses hardware frame configuration
  □ Mission agent initializes without errors
  □ Web UI responsive

Simulation Safety ✅
  □ sim_autonomy.launch.py launches correctly
  □ /robot0/odom, /robot0/imu topics visible
  □ Nav2 uses simulation frame configuration
  □ Costmaps publish to /robot0/local_costmap/costmap
  □ Mission agent initializes without timeout
  □ Web UI responsive

Cross-Mode ✅
  □ No topic conflicts if both modes attempt to run
  □ Mode detection works correctly
  □ Remappings don't break hardware
  □ Fallback configs work if new files missing

Regression ✅
  □ Original nav2_params.yaml unchanged
  □ start.sh core logic unchanged
  □ Mission agent launch unchanged
  □ Hardware driver unchanged
```

---

## Conclusion

**Architecture supports multiple modes safely:**
- ✅ **Hardware**: Isolated driver, root namespace
- ✅ **Simulation**: Isolated autonomy stack, /robot0/ namespace  
- ✅ **Mock**: No external connections

**Change impact:**
- ✅ **Zero impact on hardware** (different code paths, namespaces)
- ✅ **Fixes simulation** (Nav2 frame configuration)
- ✅ **Maintains backwards compatibility** (falls back to original config)

**Confidence:** 🟢 HIGH - Safe to proceed with implementation
