---
tags: [dimos, submodule, integration, issue]
status: draft
related: []
summary: >
  Add namespace parameter support to DIMOS UnitreeGo2 for simulation compatibility.
---

# DIMOS Enhancement: Namespace Support for Simulation Mode

**Issue Type**: Enhancement / Bug Fix  
**Priority**: High (Blocks simulation mode)  
**Affected Component**: `src/dimos-unitree/dimos/robot/unitree/unitree_go2.py`  
**Related Components**:
  - `dimos/robot/ros_transform.py` (ROSTransformAbility)
  - `dimos/perception/spatial_perception.py` (SpatialMemory)
  - `dimos/robot/local_planner/` (VFHPurePursuitPlanner, AstarPlanner)

---

## Problem Statement

The DIMOS library cannot be used in **namespaced ROS2 environments** (e.g., Isaac Sim with `/robot0/*` namespace). This blocks multi-robot and simulation scenarios where topics/frames use namespace prefixes.

### Current Failures

**1. Planner Initialization Timeout**

When `UnitreeGo2` initializes, it creates local and global planners that immediately call `topic_latest()` with hardcoded topic names:

```python
# Line 167 in unitree_go2.py
get_costmap=self.ros_control.topic_latest("/local_costmap/costmap", Costmap),

# Line 180 in unitree_go2.py  
get_costmap=self.ros_control.topic_latest("map", Costmap),
```

**Problem**: In simulation with Isaac Sim (namespaced `/robot0/`), these topics don't exist:
- Expected: `/robot0/local_costmap/costmap`
- Actual code looks for: `/local_costmap/costmap` (FAILS)

**Result**: `topic_latest()` waits 30 seconds before timing out, blocking robot initialization.

**2. Transform Provider Hardcoded Frame Name**

The `ROSTransformAbility` mixin has hardcoded `target_frame="map"` in all transform methods:

```python
# Lines 56-62 in ros_transform.py
def transform_euler_pos(self, source_frame: str, target_frame: str = "map", timeout: float = 1.0):
    return to_euler_pos(self.transform(source_frame, target_frame, timeout))

def transform_euler(self, source_frame: str, target_frame: str = "map", timeout: float = 1.0):
    res = self.transform(source_frame, target_frame, timeout)
    return to_euler(res)
```

**Problem**: In simulation, the map frame is `robot0/map`, not `map`:
- Simulation expects: `robot0/base_link` → `robot0/map`
- Code tries: `base_link` → `map` (FAILS)

**Result**: Transform lookups fail during SpatialMemory initialization.

### Use Cases Requiring This Fix

1. **Simulation with Isaac Sim**: Multi-robot simulations use namespace per robot
2. **Multi-Robot Hardware**: Fleet of robots with `/robot1/*`, `/robot2/*` namespaces
3. **ROS2 Best Practices**: Namespacing is recommended for multi-robot systems (REP 125)
4. **Docker Deployments**: Containerized robots often use namespaces for isolation

---

## Root Causes

### RC1: No Namespace Parameter in UnitreeGo2

**File**: `src/dimos-unitree/dimos/robot/unitree/unitree_go2.py`

The `UnitreeGo2.__init__()` has no way to specify namespace for topic subscriptions or frame names.

**Impact**: All topic paths and frame names are hardcoded without namespace prefix support.

### RC2: Hardcoded Topic Names in Planners

**File**: `src/dimos-unitree/dimos/robot/unitree/unitree_go2.py:167,180`

Planner initialization directly calls `topic_latest()` with hardcoded absolute paths:
```python
self.ros_control.topic_latest("/local_costmap/costmap", Costmap)
self.ros_control.topic_latest("map", Costmap)
```

**Impact**: Cannot use planners in namespaced environments without blocking timeouts.

### RC3: Hardcoded Frame Names in Transform Methods

**File**: `src/dimos-unitree/dimos/robot/ros_transform.py:49-62`

All transform methods default to `target_frame="map"` with no way to override at initialization:
```python
def transform_euler_pos(self, source_frame: str, target_frame: str = "map", timeout: float = 1.0):
```

**Impact**: Frame name mismatches in simulation environments where frames use different prefixes.

### RC4: No Mode Detection in Robot Class

**File**: `src/dimos-unitree/dimos/robot/robot.py` and `unitree_go2.py`

Robot initialization doesn't detect or adapt to simulation vs. hardware mode.

**Impact**: Cannot apply simulation-specific configurations (namespaced topics/frames).

---

## Proposed Solution

### Phase 1: Add Namespace Parameter (REQUIRED)

Add optional `namespace` parameter to `UnitreeGo2.__init__()`:

```python
def __init__(
    self,
    ros_control: Optional[UnitreeROSControl] = None,
    ip: str = None,
    # ... existing parameters ...
    namespace: str = "",  # NEW: namespace prefix for topics/frames
    # ... rest of parameters ...
):
```

**In Planner Initialization** (Line ~167):
```python
# OLD:
get_costmap=self.ros_control.topic_latest("/local_costmap/costmap", Costmap)

# NEW:
costmap_topic = f"{self.namespace}/local_costmap/costmap".lstrip("/")
get_costmap=self.ros_control.topic_latest(costmap_topic, Costmap)
```

**In Transform Methods** (ros_transform.py):

Add optional frame prefix parameter:
```python
def transform_euler(
    self, 
    source_frame: str, 
    target_frame: str = "map", 
    timeout: float = 1.0,
    frame_namespace: str = ""  # NEW
):
    """Transform with optional frame namespace support."""
    # Apply namespace to frames if provided
    if frame_namespace:
        source_frame = f"{frame_namespace}/{source_frame}".lstrip("/")
        target_frame = f"{frame_namespace}/{target_frame}".lstrip("/")
    # ... existing implementation ...
```

### Phase 2: Lazy Planner Initialization (RECOMMENDED)

Make planner initialization lazy to avoid blocking timeouts:

```python
def _ensure_planners_initialized(self):
    """Initialize planners on first use if not already initialized."""
    if hasattr(self, '_planners_initialized'):
        return
    
    # Initialize local and global planners here
    # (Current __init__ code moved to here)
    
    self._planners_initialized = True

@property
def local_planner(self):
    self._ensure_planners_initialized()
    return self._local_planner
```

**Benefit**: Planners initialized only when needed, avoiding timeouts during robot init.

### Phase 3: Mode Detection Helper (OPTIONAL)

Add utility to detect simulation mode:

```python
@staticmethod
def detect_mode() -> str:
    """Detect if running in simulation or hardware mode.
    
    Returns:
        "simulation" or "hardware"
    """
    return os.getenv("ROBOT_MODE", "hardware").lower()

@classmethod
def for_simulation(cls, ros_control=None, namespace="robot0", **kwargs):
    """Factory method for simulation mode with sensible defaults."""
    return cls(
        ros_control=ros_control,
        namespace=namespace,
        **kwargs
    )
```

---

## Implementation Checklist

### Core Changes Required

- [ ] **unitree_go2.py**
  - [ ] Add `namespace: str = ""` parameter to `__init__`
  - [ ] Update planner initialization to use namespaced topics
  - [ ] Document namespace parameter with examples

- [ ] **ros_transform.py**
  - [ ] Add `frame_namespace: str = ""` parameter to transform methods
  - [ ] Apply namespace prefix in transform lookups
  - [ ] Maintain backward compatibility (empty namespace = no prefix)

- [ ] **robot.py (Base Class)**
  - [ ] Add `namespace` storage and getter
  - [ ] Pass namespace through to subcomponents
  - [ ] Update SpatialMemory initialization with namespace-aware frames

### Testing Required

- [ ] Unit tests for namespace parameter handling
- [ ] Integration test: UnitreeGo2 in simulation with `/robot0/` namespace
- [ ] Integration test: UnitreeGo2 in hardware without namespace (regression)
- [ ] Multi-robot test: Two robots with `/robot1/` and `/robot2/` namespaces
- [ ] Transform tests: Verify frame name prefixing works correctly

### Documentation

- [ ] Update UnitreeGo2 docstring with namespace parameter
- [ ] Add simulation setup guide using namespace parameter
- [ ] Document frame naming conventions for simulation
- [ ] Add example: `robot = UnitreeGo2(ros_control, namespace="robot0")`

---

## Backward Compatibility

✅ **MAINTAINED**: All changes use optional parameters with empty string defaults:
- `namespace: str = ""` → No prefix applied (existing behavior)
- `frame_namespace: str = ""` → No prefix applied (existing behavior)

Existing code will continue to work without modification.

---

## Benefits

1. ✅ Enables simulation with namespaced environments (Isaac Sim, etc.)
2. ✅ Supports multi-robot deployments with namespace isolation
3. ✅ Follows ROS2 best practices for namespace handling
4. ✅ No breaking changes to existing hardware deployments
5. ✅ Clean API with optional parameters
6. ✅ Lazy initialization avoids blocking timeouts
7. ✅ Enables flexible deployment scenarios

---

## Related Issues

- **ShadowHound**: Blocked on this for laptop + Isaac Sim integration
- **Future Multi-Robot**: Will need namespace support for fleet deployments

---

## Success Criteria

- [ ] UnitreeGo2 initializes in < 2 seconds in simulation mode (no blocking timeouts)
- [ ] Transform lookups work with both `map` and `robot0/map` frames
- [ ] Planner initialization completes without timeouts in namespaced environment
- [ ] All existing hardware tests pass without modification
- [ ] Simulation tests pass with namespace parameter
- [ ] Multi-robot test demonstrates isolation between `robot1/` and `robot2/`

---

## Priority and Timeline

**Current Status**: Blocking ShadowHound simulation testing  
**Priority**: HIGH - Required for Q4 2025 simulation validation  
**Estimated Effort**: 4-6 hours  
**Timeline**: Should be completed before ShadowHound integration testing

---

## Implementation Notes

### Key Insight

The namespace issue affects multiple layers:
1. **Topic names** - subscriptions and publishers
2. **Frame names** - TF2 lookups
3. **Initialization** - hardcoded assumptions about availability

A comprehensive fix requires addressing all three layers consistently.

### Namespace Format

Use standard ROS2 conventions:
- Empty string: no namespace (hardware mode)
- "robot0": becomes `robot0/` prefix in relative paths
- "/robot0": absolute, preferred in documentation

Normalize in code: `f"{namespace}/topic_name".lstrip("/")`

### Testing Approach

1. Start with unit tests for namespace handling
2. Integration test in simulation environment
3. Regression test with hardware (empty namespace)
4. Multi-robot test to verify isolation

---

## Migration Path

1. **Phase 1 (Required)**: Namespace parameter support
2. **Phase 2 (Recommended)**: Lazy planner initialization
3. **Phase 3 (Optional)**: Mode detection helpers

Can implement incrementally without blocking each other.

---

**Prepared by**: ShadowHound Development  
**Date**: October 21, 2025  
**Related PR**: Feature branch `laptop-sim-integration`
