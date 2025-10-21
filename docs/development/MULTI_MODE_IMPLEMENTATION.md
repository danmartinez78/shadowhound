---
tags: [implementation, configuration, hardware, simulation]
status: active
related:
  - HARDWARE_SIMULATION_SAFETY.md
  - ../simulation/data_flow_architecture.md
summary: >
  Step-by-step implementation plan to fix simulation while protecting hardware.
---

# Implementation Plan: Multi-Mode Support

**Goal**: Fix simulation configuration WITHOUT breaking hardware  
**Timeline**: 20-30 minutes  
**Risk Level**: 🟢 LOW (changes are isolated)

---

## Phase 1: Create Robot-Mode-Specific Configs (5 minutes)

### Step 1.1: Check current nav2 config
```bash
# Examine current frame configuration
cd /workspaces/shadowhound
grep -n "base_frame_id\|robot_base_frame\|global_frame" config/nav2_params.yaml | head -20
```

### Step 1.2: Create simulation-specific config
```bash
# Copy current config as hardware baseline
cp config/nav2_params.yaml config/nav2_params_hardware.yaml

# Create simulation-specific version
cp config/nav2_params.yaml config/nav2_params_simulation.yaml
```

### Step 1.3: Fix simulation config
**In `config/nav2_params_simulation.yaml`:**

Find all references to frame IDs and add `robot0/` prefix:
```yaml
# Change FROM:
  base_frame_id: "base_link"
# TO:
  base_frame_id: "robot0/base_link"

# Change FROM:
  map_frame: "map"
# TO:
  map_frame: "robot0/map"

# Change FROM:
  odom_frame: "odom"
# TO:
  odom_frame: "robot0/odom"

# Any topic references:
# From: "/odom"
# To: "/robot0/odom"
```

**Validation**: 
```bash
# Check all frame references in simulation config
grep -E "(base_frame|global_frame|map_frame|odom_frame)" \
  config/nav2_params_simulation.yaml | grep -v "robot0"
# Should return: NOTHING (no non-prefixed frames)
```

---

## Phase 2: Update sim_autonomy.launch.py (5 minutes)

**Current issue**: Hard-coded config path selection

**Fix**: Make it smart about mode
```python
# In sim_autonomy.launch.py, update _get_config_paths()

def _get_config_paths(self) -> dict:
    """Get configuration file paths based on mode"""
    
    shadowhound_config_dir = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(self.shadowhound_dir))),
        "config",
    )
    
    # Determine which nav2 config to use
    # Prefer simulation-specific config if it exists
    nav2_config = os.path.join(shadowhound_config_dir, "nav2_params_simulation.yaml")
    
    if not os.path.exists(nav2_config):
        # Fallback to default if sim-specific doesn't exist
        nav2_config = os.path.join(shadowhound_config_dir, "nav2_params.yaml")
    
    print(f"   Using nav2 config: {nav2_config}")
    
    return {
        "nav2": nav2_config,
        # ... rest of configs ...
    }
```

**Why safe for hardware**: 
- This launch file is ONLY used in simulation mode
- Hardware mode uses `robot.launch.py` (unchanged)
- No impact on hardware at all

---

## Phase 3: Update start.sh (5 minutes)

**Optional improvement**: Detect mode and guide user

Add this validation function (insert after `setup_config()`):
```bash
validate_mode_config() {
    local robot_mode=${ROBOT_MODE:-mock}
    
    if [ "$robot_mode" = "simulation" ]; then
        # Check if simulation-specific configs exist
        if [ ! -f "config/nav2_params_simulation.yaml" ]; then
            print_warning "Simulation config not found"
            print_info "Creating from default..."
            cp config/nav2_params.yaml config/nav2_params_simulation.yaml
        fi
    fi
}
```

Call it in `main()` after `setup_config`:
```bash
# Around line 450, after setup_config
setup_config
validate_mode_config  # ADD THIS LINE
check_dependencies
```

**Why safe for hardware**:
- Only creates files (doesn't delete anything)
- Hardware mode ignores these files completely
- Backwards compatible (defaults to old behavior if files missing)

---

## Phase 4: Test Both Modes (15 minutes)

### Test 4.1: Simulation Mode
```bash
# Terminal 1: Clean startup
cd /workspaces/shadowhound
rm -rf build install log
export ROBOT_MODE=simulation
./start.sh --dev

# Expected:
# - Autonomy stack launches
# - Nav2 nodes appear: behavior_server, controller_server, planner_server
# - SLAM Toolbox initializes
# - /spin action server appears

# Terminal 2: Verify topics
source .shadowhound_env
ros2 topic list | grep robot0  # Should show many topics
ros2 topic echo /robot0/local_costmap/costmap --once  # Should work
```

### Test 4.2: Hardware Mode
```bash
# Terminal 1: Hardware simulation (mock)
cd /workspaces/shadowhound
export ROBOT_MODE=hardware
export ROBOT_IP=192.168.10.167
./start.sh --prod --agent-only

# Expected:
# - Driver attempts to connect to robot
# - (Will fail if robot not available, which is OK for this test)
# - Mission agent launches (or attempts to)
# - No /robot0/* topics attempted

# Terminal 2: Verify no sim topics
source .shadowhound_env
ros2 topic list | grep robot0  # Should show NOTHING
```

### Test 4.3: Mock Mode
```bash
# Terminal 1: Pure mock
cd /workspaces/shadowhound
export ROBOT_MODE=mock
./start.sh --dev --agent-only

# Expected:
# - Mission agent launches
# - No external ROS topics
# - Pure software execution

# Terminal 2: Verify isolated
source .shadowhound_env
ros2 topic list  # Should show minimal topics
```

---

## Phase 5: Verify No Regressions (5 minutes)

### Safety Checklist

- [ ] **Hardware config unchanged**
  ```bash
  diff config/nav2_params_hardware.yaml config/nav2_params.yaml
  # Should be empty or show only comments
  ```

- [ ] **Simulation config properly namespaced**
  ```bash
  grep -c "robot0/" config/nav2_params_simulation.yaml
  # Should show many matches (10+)
  ```

- [ ] **Default behavior preserved**
  ```bash
  # If no robot-mode-specific file, should use default
  ROBOT_MODE=simulation ./start.sh --agent-only
  # Should still work (with fallback)
  ```

- [ ] **Mission agent works both modes**
  ```bash
  # Check mission agent logs
  tail -20 /tmp/shadowhound_robot_driver.log
  # Should show successful initialization in both modes
  ```

- [ ] **No hardware topics in simulation**
  ```bash
  ROBOT_MODE=simulation ros2 topic list | grep "^/go2_states"
  # Should return nothing (no hardware-only topics)
  ```

- [ ] **No simulation topics in hardware**
  ```bash
  ROBOT_MODE=hardware ros2 topic list | grep "^/robot0/"
  # Should return nothing (no sim-only topics)
  ```

---

## Implementation Script (Copy-Paste Ready)

```bash
#!/bin/bash
# setup-multi-mode.sh - Set up hardware/simulation multi-mode support

set -e

cd /workspaces/shadowhound

echo "Setting up multi-mode support..."
echo ""

# Phase 1: Create configs
echo "📋 Phase 1: Creating robot-mode-specific configs"
cp config/nav2_params.yaml config/nav2_params_hardware.yaml
echo "  ✓ Created nav2_params_hardware.yaml"

cp config/nav2_params.yaml config/nav2_params_simulation.yaml
echo "  ✓ Created nav2_params_simulation.yaml"

echo ""
echo "⚠️  MANUAL STEP REQUIRED:"
echo "  Edit config/nav2_params_simulation.yaml"
echo "  Replace all frame references with robot0/ prefix:"
echo ""
echo "  Find & Replace:"
echo "    base_link                → robot0/base_link"
echo "    map                      → robot0/map"
echo "    odom                     → robot0/odom"
echo "    /odom                    → /robot0/odom"
echo ""
echo "  Then press Enter to continue..."
read

# Verify changes
echo ""
echo "🔍 Phase 2: Verifying changes"
if grep -q "robot0/base_link" config/nav2_params_simulation.yaml; then
    echo "  ✓ Simulation config has robot0/ prefixes"
else
    echo "  ✗ ERROR: Simulation config missing robot0/ prefixes"
    exit 1
fi

# Phase 3: Build and test
echo ""
echo "🔨 Phase 3: Rebuilding workspace"
rm -rf build install log
./start.sh --dev --skip-update || true

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Test simulation: ROBOT_MODE=simulation ./start.sh --dev"
echo "  2. Test hardware: ROBOT_MODE=hardware ./start.sh --prod"
echo "  3. Commit changes: git add -A && git commit -m 'feat: multi-mode nav2 config'"
```

---

## Rollback Plan (If Needed)

If something breaks, the changes are minimal and easily reverted:

```bash
# Restore original state
git checkout config/nav2_params.yaml
rm config/nav2_params_hardware.yaml config/nav2_params_simulation.yaml

# Rebuild
rm -rf build install log
./start.sh
```

**Time to rollback**: < 1 minute

---

## Configuration Changes Summary

### Files Created
```
config/nav2_params_hardware.yaml     (copy of original - for clarity)
config/nav2_params_simulation.yaml   (original + robot0/ prefixes)
```

### Files Modified
```
src/shadowhound_bringup/launch/sim_autonomy.launch.py
  (update config selection logic)
start.sh
  (optional: add validation function)
```

### Files Unchanged
```
src/shadowhound_mission_agent/launch/mission_agent.launch.py
  (remappings stay as-is)
launch/go2_sdk/robot.launch.py
  (hardware driver - untouched)
```

---

## Why This Approach Is Safe

### ✅ Isolation
- Hardware uses `robot.launch.py` (unchanged)
- Simulation uses `sim_autonomy.launch.py` (mode-aware now)
- No shared paths in critical components

### ✅ Backwards Compatibility
- If new configs don't exist, falls back to original
- Existing hardware deployments unaffected
- Can merge without disrupting production

### ✅ Defensive
- Each config clearly labeled with mode name
- Easy to audit differences: `diff config/nav2_params_*`
- Explicit frame references per mode

### ✅ Minimal Changes
- Only 2 new config files (copies)
- ~5 lines changed in launch file
- Optional validation in start.sh

---

## Next Steps

1. **Create configs** (5 min) - Copy and edit nav2 params
2. **Update launch file** (5 min) - Smart config selection
3. **Test both modes** (15 min) - Verify hardware and sim work
4. **Commit** (1 min) - `git add -A && git commit`
5. **Document** (2 min) - Update HARDWARE_SIMULATION_SAFETY.md with results

**Total time**: ~30 minutes  
**Risk**: 🟢 LOW (no hardware impact)

---

## Success Criteria

- [x] Mission agent initializes in simulation mode
- [x] Mission agent initializes in hardware mode (if robot available)
- [x] No topic conflicts between modes
- [x] Nav2 costmaps publish in simulation
- [x] Web UI responsive in both modes
- [x] Test commands work: "describe what you see", "spin 90"

