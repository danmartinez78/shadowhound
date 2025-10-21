---
tags: [actionable, checklist, dimos, shadowhound]
status: active
related: [AGENT_PR_REVIEW_DIMOS_10.md, SESSION_HANDOFF_OCT21_2025.md]
summary: >
  Actionable checklist for merging DIMOS PR #10 and completing ShadowHound Isaac Sim integration
---

# Action Checklist - Complete DIMOS Integration & ShadowHound Isaac Sim

**Current Status**: DIMOS PR #10 ready for merge, ShadowHound waiting for merge  
**Target**: Complete Isaac Sim integration by merging to dev/main

---

## Phase 1: Review & Approve DIMOS PR #10 ✅ (READY NOW)

**Status**: PR #10 is DRAFT and ready for review  
**Link**: https://github.com/danmartinez78/dimos-unitree/pull/10

### Review Checklist
- [ ] Read PR description (comprehensive overview included)
- [ ] Review code changes:
  - [ ] `dimos/robot/ros_transform.py` - frame_namespace added to 8 methods
  - [ ] `dimos/robot/robot.py` - namespace parameter and storage
  - [ ] `dimos/robot/unitree/unitree_go2.py` - namespace parameter, planner initialization
- [ ] Check test coverage:
  - [ ] `tests/test_namespace_support.py` - 10 tests, all passing ✅
- [ ] Verify documentation:
  - [ ] `docs/NAMESPACE_SUPPORT.md` - API reference and usage guide
- [ ] Backward compatibility assessment:
  - [ ] All namespace parameters optional ✅
  - [ ] No breaking changes ✅
  - [ ] Existing code continues to work ✅

### Approval Action
- [ ] **APPROVE** PR #10 with comment:
  ```
  Reviewed and approved. Implementation is complete, well-tested, and maintains 
  100% backward compatibility. Ready for merge.
  ```
- [ ] **MERGE** PR #10 into `main` branch
- [ ] Verify merge successful (check GitHub Actions if configured)

**Time Estimate**: 15-30 minutes

---

## Phase 2: Update ShadowHound Codebase ✅ (READY AFTER PHASE 1)

**Location**: `/workspaces/shadowhound/`  
**Branch**: `feature/laptop-sim-integration` (already created)

### Step 2.1: Update DIMOS Submodule

```bash
cd /workspaces/shadowhound/src/dimos-unitree
git pull origin main
cd ../..
git add src/dimos-unitree
git commit -m "chore: update dimos-unitree to latest (namespace support PR #10)"
```

**Checklist**:
- [ ] Verify DIMOS submodule updated to latest commit with namespace support
- [ ] Commit message clear and descriptive
- [ ] No merge conflicts in submodule

### Step 2.2: Update mission_executor.py

**File**: `src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py`

**Current Code** (around line 290):
```python
robot = UnitreeGo2(
    ros_control=ros_control,
    ip=self.config.robot_ip,
    # ... other params ...
)
```

**Updated Code** (add namespace support):
```python
robot_mode = os.getenv("ROBOT_MODE", "hardware").lower()
robot = UnitreeGo2(
    ros_control=ros_control,
    ip=self.config.robot_ip,
    namespace="robot0" if robot_mode == "simulation" else "",  # NEW
    # ... other params ...
)
```

**Implementation Checklist**:
- [ ] Read current mission_executor.py to find UnitreeGo2 initialization
- [ ] Add `namespace` parameter based on ROBOT_MODE
- [ ] Verify build succeeds: `colcon build --packages-select shadowhound_mission_agent`
- [ ] Commit message: `feat(mission_agent): add namespace parameter for simulation support`

**Time Estimate**: 10-15 minutes

---

## Phase 3: Test Simulation Mode 🧪 (VERIFY)

**Prerequisite**: Isaac Sim running on Tower at 192.168.x.x  
**Environment**: Laptop with ROS2 Humble, network access to Tower

### Step 3.1: Verify Network Connectivity

```bash
# Verify Tower can see laptop
ssh -i ~/.ssh/tower_key nvidia@192.168.x.x "echo 'Tower accessible'"

# Verify ROS2 domain bridging
export ROS_DOMAIN_ID=0
ros2 daemon stop
ros2 daemon start
ros2 node list  # Should see Tower nodes
```

**Checklist**:
- [ ] Tower accessible via SSH
- [ ] ROS_DOMAIN_ID=0 set on laptop
- [ ] `ros2 node list` shows nodes from Tower

### Step 3.2: Start in Simulation Mode

```bash
# Terminal 1: Start simulation environment
export ROBOT_MODE=simulation
./start.sh --dev
```

**Expected Behavior**:
- ✅ Mission agent initializes without 30-second timeouts
- ✅ No "Waiting for /local_costmap/costmap" errors
- ✅ TF frames load correctly (`robot0/map`, `robot0/base_link`, etc.)
- ✅ RViz2 shows LiDAR and costmaps

**Checklist**:
- [ ] Mission agent starts successfully (< 5 seconds initialization)
- [ ] No timeout errors in logs
- [ ] RViz2 visualization shows robot and environment
- [ ] `/robot0/local_costmap/costmap` topic visible
- [ ] TF tree shows namespaced frames

### Step 3.3: Test Basic Autonomy

```bash
# If mission API available
curl http://localhost:8000/api/missions \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"task": "report", "text": "System online"}'

# Or test manually with RViz2 navigation goal
```

**Checklist**:
- [ ] Mission execution works
- [ ] Robot responds to navigation goals
- [ ] No TF lookup errors
- [ ] No topic subscription errors

**Time Estimate**: 20-30 minutes

---

## Phase 4: Test Hardware Mode 🤖 (REGRESSION)

**Prerequisite**: Physical Unitree Go2 available (optional)  
**Purpose**: Verify backward compatibility, no breaking changes

### Step 4.1: Prepare Hardware Test Environment

```bash
# Terminal 1: Start in hardware mode (default)
export ROBOT_MODE=hardware
# OR don't set it - hardware is default

./start.sh
```

**Expected Behavior**:
- ✅ Mission agent initializes normally
- ✅ Robot connects to physical Go2
- ✅ Uses `/local_costmap/costmap` (no namespace)
- ✅ TF tree shows standard frames (`map`, `base_link`)
- ✅ No behavioral changes from previous version

**Checklist**:
- [ ] Mission agent initializes successfully
- [ ] No namespace-related errors in logs
- [ ] Robot hardware connection established
- [ ] RViz2 shows correct frames
- [ ] Mission execution works as before

**Time Estimate**: 15-20 minutes (if hardware available)

**Note**: If no hardware available, this can be verified by:
- [ ] Checking logs for any namespace-related issues
- [ ] Verifying default behavior (no namespace parameter used)
- [ ] Confirming backward compatibility by code review

---

## Phase 5: Merge to Production 🚀 (FINAL)

**Target Branches**:
- `feature/laptop-sim-integration` → `dev` → `main`

### Step 5.1: Update Devlog Entry

**File**: `docs/development/devlog.md`

**Add Entry**:
```markdown
## 2025-10-21 (Monday) - Evening

### DIMOS Namespace Support Integration Complete
**Type**: Feature
**Status**: ✅ Complete
**Branch**: `feature/laptop-sim-integration`

Merged DIMOS namespace support PR #10 and integrated into ShadowHound.

**Key Results**:
- ✅ DIMOS PR #10 merged (namespace support)
- ✅ ShadowHound mission_executor.py updated
- ✅ Simulation mode tested successfully
- ✅ Hardware mode verified (backward compatible)
- ✅ Ready for production deployment

**Commits**: [list commit hashes here]

**What's Enabled**:
- Isaac Sim integration with proper namespacing
- Multi-robot support ready (fleet-capable)
- Zero breaking changes (100% backward compatible)
```

**Checklist**:
- [ ] Devlog entry added to `docs/development/devlog.md`
- [ ] All commit hashes included
- [ ] Status marked as Complete

### Step 5.2: Merge Feature Branch to dev

```bash
# Switch to dev branch
git checkout dev

# Merge feature branch
git merge feature/laptop-sim-integration --no-ff

# Commit message suggestion:
# "Merge feature/laptop-sim-integration: DIMOS namespace support + Isaac Sim integration"
```

**Checklist**:
- [ ] Switched to `dev` branch
- [ ] Merged `feature/laptop-sim-integration`
- [ ] Clear merge commit message
- [ ] No merge conflicts

### Step 5.3: Push to Repository

```bash
# Push dev branch
git push origin dev

# Optionally merge to main if ready for release
git checkout main
git merge dev --no-ff
git push origin main
```

**Checklist**:
- [ ] `dev` branch pushed successfully
- [ ] GitHub shows all commits
- [ ] GitHub Actions pass (if configured)
- [ ] Optional: `main` branch updated for release

**Time Estimate**: 10 minutes

---

## Summary Checklist

### Critical Path (REQUIRED)
- [ ] Phase 1: Approve & merge DIMOS PR #10
- [ ] Phase 2: Update ShadowHound codebase
- [ ] Phase 3: Test simulation mode (Isaac Sim)
- [ ] Phase 5.2: Merge feature branch to dev

### Validation (RECOMMENDED)
- [ ] Phase 3: Verify no timeouts, proper namespace usage
- [ ] Phase 4: Verify hardware mode (if available)
- [ ] Phase 5: Update devlog entry

### Optional but Recommended
- [ ] Phase 5.3: Merge `dev` to `main` for release

---

## Estimated Timeline

| Phase | Task | Time | Status |
|-------|------|------|--------|
| 1 | Review & merge DIMOS PR #10 | 30 min | Ready |
| 2 | Update ShadowHound code | 15 min | Ready |
| 3 | Test simulation mode | 30 min | Blocked on Phase 1 |
| 4 | Test hardware mode | 20 min | Optional |
| 5 | Merge to production | 10 min | Blocked on Phase 3 |
| **TOTAL** | | **1.5-2 hours** | **Ready to start** |

---

## Success Criteria

After completing all phases, verify:

✅ **Isaac Sim Integration**
- Mission agent initializes without timeouts
- TF frames use robot0/ namespace correctly
- Costmap topics use /robot0/ prefix correctly

✅ **Backward Compatibility**
- Hardware mode works unchanged
- No breaking API changes
- Existing deployments unaffected

✅ **Code Quality**
- All tests passing
- Documentation updated
- Commits are clear and descriptive

✅ **Production Ready**
- Feature branch merged to dev
- Devlog entry created
- All validation complete

---

## Rollback Plan (If Needed)

If any phase fails, rollback is simple:

```bash
# Revert ShadowHound changes
git revert [last commit]

# If DIMOS PR needs rollback (unlikely but possible)
cd src/dimos-unitree
git checkout previous_commit
```

---

**Next Action**: Approve and merge DIMOS PR #10  
**Documents**: See AGENT_PR_REVIEW_DIMOS_10.md for detailed review  
**Questions?**: Check docs/development/SESSION_HANDOFF_OCT21_2025.md for context

**Status**: 🟢 READY TO PROCEED
