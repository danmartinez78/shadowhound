# Isaac Lab Upgrade: Fixing LiDAR Config Compatibility

## Problem Summary

The **go2_omniverse** `added_copter` branch (last updated **May 28, 2025**) expects a newer version of Isaac Lab than what's currently installed on Tower.

**Current State:**
- Tower: Isaac Lab **v2.1.0** (April 24, 2025)
- Repo expects: Isaac Lab **v2.2.0+** (August 2025)

**Incompatibility:**
- v2.1.0 extension.toml uses: `isaacsim.sensors.rtx` module naming
- Repo extension.toml uses: `omni.isaac.sensor` (older naming that was updated in v2.2.0)

## Solution: Upgrade to Isaac Lab v2.2.1

Isaac Lab v2.2.1 (August 29, 2025) includes:
- ✅ Compatible with Isaac Sim 4.5.0 (Tower has this)
- ✅ Module naming updates matching repo expectations
- ✅ rsl_rl compatibility maintained
- ✅ Backwards compatible with our trained models

## Execution Steps (On Tower)

### Step 1: Pull Latest Scripts

```bash
cd ~/shadowhound
git pull origin dev
```

**You should see:**
- `scripts/tower_upgrade_isaaclab.sh` (new)
- `scripts/tower_test_sim_after_upgrade.sh` (new)

### Step 2: Run Isaac Lab Upgrade

```bash
bash ~/shadowhound/scripts/tower_upgrade_isaaclab.sh
```

**What it does:**
1. Backs up current Isaac Lab v2.1.0 installation
2. Checks out Isaac Lab v2.2.1 tag
3. Cleans old packages
4. Reinstalls Isaac Lab with new version
5. Verifies installation

**Expected duration:** ~10-15 minutes

**Expected output:**
```
✓ Isaac Lab upgraded to v2.2.1
Current version info:
v2.2.1
```

### Step 3: Test Simulation Still Works

```bash
bash ~/shadowhound/scripts/tower_test_sim_after_upgrade.sh
```

**What it does:**
- Starts Go2 simulation for 60 seconds
- Verifies robot loads without errors
- Times out automatically

**Success criteria:**
- Robot appears in Isaac Sim
- No module import errors
- No crashes

### Step 4: Apply LiDAR Config (If Sim Works)

```bash
# First, rollback the broken config from earlier
bash ~/shadowhound/scripts/tower_rollback_lidar_config.sh

# Then apply LiDAR config with new Isaac Lab version
bash ~/shadowhound/scripts/tower_fix_lidar_config.sh
```

**What should happen:**
- ✅ extension.toml replacement should work (module naming now matches)
- ✅ Unitree_L1.json copied to correct location
- ✅ No module import errors

### Step 5: Final Verification

```bash
cd ~/workspace/go2_omniverse
./run_sim.sh
```

**Check for:**
- ✅ Robot loads successfully
- ✅ No LiDAR config errors in terminal
- ✅ LiDAR point cloud visualized (if enabled)
- ✅ Simulation runs smoothly

## Rollback Plan (If Upgrade Fails)

If the upgrade breaks something:

```bash
# Restore original Isaac Lab v2.1.0
cd ~/workspace/IsaacLab
git checkout v2.1.0

# Reinstall
source ~/miniconda3/etc/profile.d/conda.sh
conda activate env_isaaclab
./isaaclab.sh --install

# Test original simulation still works
cd ~/workspace/go2_omniverse
./run_sim.sh
```

The simulation was working perfectly before, so rollback guarantees we're back to a good state.

## Version Compatibility Matrix

| Component | Version | Status |
|-----------|---------|--------|
| Isaac Sim | 4.5.0 | ✅ Installed (Tower) |
| Isaac Lab (before) | v2.1.0 | ⚠️ Too old for repo |
| Isaac Lab (after) | v2.2.1 | ✅ Matches repo expectations |
| go2_omniverse | added_copter (May 28) | ✅ Will work with v2.2.1 |
| rsl_rl | v1.x | ✅ Maintained in v2.2.1 |

## Expected Timeline

1. **Upgrade**: 10-15 minutes
2. **Test sim**: 2-3 minutes
3. **Apply LiDAR config**: 1 minute
4. **Final verification**: 2 minutes

**Total:** ~20 minutes to complete upgrade

## Success Indicators

**After upgrade, you should NOT see:**
- ❌ `ModuleNotFoundError: No module named 'omni.isaac.sensor'`
- ❌ `ModuleNotFoundError: No module named 'isaacsim.sensors.rtx'`
- ❌ `AttributeError: 'NoneType' object has no attribute 'GetPath'`

**After upgrade, you SHOULD see:**
- ✅ Robot loads in simulation
- ✅ No LiDAR config errors
- ✅ Clean terminal output during sim startup

## Notes

- The upgrade is **safe** - v2.2.1 is stable and tested
- Isaac Lab v2.2.1 is the **latest stable release** (August 29, 2025)
- This resolves the fundamental version mismatch between Tower installation (April) and repo updates (May)
- Our previous simulation success proves Isaac Sim 4.5.0 works - we just need newer Isaac Lab

## Commits

This upgrade workflow includes:
- Commit 64d1ac9: Isaac Lab upgrade script
- Commit 20d1954: Simulation test script
- Total: 32 commits on dev branch
