---
tags: [architecture, namespacing, quickref]
status: active
related: [namespace_migration_plan.md]
summary: >
  Quick reference summary for namespace migration plan
---

# Namespace Migration - Quick Summary

**TL;DR**: We need to migrate the entire ShadowHound stack to support ROS2 namespacing, but we're currently **blocked on DIMOS** implementing namespace support first.

---

## The Problem

Isaac Sim publishes topics with `/robot0/` namespace (multi-robot capable), but:
- ❌ DIMOS library doesn't support namespaces
- ❌ Mission agent expects non-namespaced topics
- 🔧 Temporary workaround: 20+ topic remappings in launch files (ugly!)

---

## The Solution

**4-Stage Migration Plan**:

```
Stage 0: BLOCKED ⏳ → Wait for DIMOS Issue #9 (namespace parameter)
Stage 1: Launch Files 🚀 → Add robot_namespace parameter
Stage 2: Mission Agent 🤖 → Remove remapping workarounds, use DIMOS namespace
Stage 3: Configs 🔧 → Dynamic frame name generation
Stage 4: Multi-Robot 🤖🤖 → Future enhancement
```

---

## Three Deployment Modes

```
┌──────────────────────────────────────────────────────┐
│ Mode         │ Namespace    │ Use Case               │
├──────────────┼──────────────┼────────────────────────┤
│ Hardware     │ "" (empty)   │ Real Go2 robot         │
│ Simulation   │ "robot0"     │ Isaac Sim single robot │
│ Multi-Sim    │ "robot0-N"   │ Multiple robots (TBD)  │
└──────────────────────────────────────────────────────┘
```

**Usage After Migration**:
```bash
# Hardware (default - no namespace)
ros2 launch shadowhound_bringup shadowhound.launch.py robot_mode:=hardware

# Simulation (robot0 namespace)
ros2 launch shadowhound_bringup shadowhound.launch.py robot_mode:=simulation

# Custom namespace
ros2 launch shadowhound_bringup shadowhound.launch.py \
    robot_mode:=simulation \
    robot_namespace:=my_robot
```

---

## Current Status

### ✅ Complete
- Architecture planned (380+ lines)
- Testing strategy defined
- Timeline estimated (10-20 days)
- Design principles documented

### 🔴 Blocked On
- **DIMOS Issue #9**: https://github.com/danmartinez78/dimos-unitree/issues/9
- Need `UnitreeGo2(namespace="robot0")` parameter support

### ⏳ Next Steps (After DIMOS Complete)
1. Add `robot_namespace` parameter to all launch files
2. Remove topic remapping workarounds
3. Pass namespace to DIMOS `UnitreeGo2()` constructor
4. Test hardware mode (regression)
5. Test simulation mode (namespace validation)

---

## Design Principles

1. **Parameter-Driven**: Single `robot_namespace` parameter controls everything
2. **No Code Duplication**: Same codebase for all modes
3. **Backward Compatible**: Hardware mode unchanged (namespace="")
4. **Clean Architecture**: No topic remapping hacks

---

## Timeline

**Fast Track** (Stages 1-2): ~10 days  
**Complete** (Stages 1-4): ~20 days

**Critical Path**: DIMOS Issue #9 must complete first

---

## Key Files

- **Migration Plan**: `docs/architecture/namespace_migration_plan.md` (full details)
- **DIMOS Issue**: `docs/issues/dimos_namespace_support_issue.md`
- **DIMOS Implementation**: `docs/issues/dimos_namespace_support_implementation.md`
- **Session Handoff**: `docs/development/SESSION_HANDOFF_OCT21_2025.md`

---

## Example: Before and After

### Before (Current - Ugly Workaround)
```python
# mission_agent.launch.py
remappings=[
    ("/cmd_vel", "/robot0/cmd_vel"),
    ("cmd_vel", "robot0/cmd_vel"),
    ("/odom", "/robot0/odom"),
    ("odom", "robot0/odom"),
    # ... 20+ more remappings ...
]
```

### After (Clean - Namespace Parameter)
```python
# mission_agent.launch.py
parameters=[{
    "robot_namespace": LaunchConfiguration("robot_namespace"),
}]
# NO remapping needed!

# mission_executor.py
robot = UnitreeGo2(
    ros_control=ros_control,
    namespace=robot_namespace,  # DIMOS handles all namespacing
)
```

---

## Why Namespace Support Matters

### Simulation Requirements
- Isaac Sim publishes `/robot0/*` topics for multi-robot support
- Can't change sim topic names (vendor-provided environment)
- Need ShadowHound to adapt to namespaced topics

### Future Multi-Robot
- Fleet of robots with `/robot1/`, `/robot2/`, etc.
- Shared simulation environment
- Independent mission execution per robot

### ROS2 Best Practices
- Namespacing is recommended for multi-robot (REP 125)
- Enables topic/frame isolation
- Prevents name conflicts

---

## Read Full Plan

👉 See `docs/architecture/namespace_migration_plan.md` for complete details

---

**Created**: 2025-10-21  
**Status**: Planning Complete, Implementation Blocked on DIMOS
