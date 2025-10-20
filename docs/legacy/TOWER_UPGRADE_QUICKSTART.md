# Tower Isaac Lab Upgrade - Quick Start

## TL;DR - Single Command Option

```bash
ssh daniel@192.168.10.167
bash ~/shadowhound/scripts/tower_upgrade_complete.sh
```

This runs the entire workflow:
1. Pulls latest scripts
2. Upgrades Isaac Lab v2.1.0 → v2.2.1
3. Tests simulation
4. Applies LiDAR config
5. Verifies success

**Duration:** ~20 minutes

---

## Manual Step-by-Step Option

If you prefer to run steps individually:

### 1. Pull Scripts
```bash
cd ~/shadowhound && git pull origin dev
```

### 2. Upgrade Isaac Lab
```bash
bash ~/shadowhound/scripts/tower_upgrade_isaaclab.sh
```

### 3. Test Simulation
```bash
bash ~/shadowhound/scripts/tower_test_sim_after_upgrade.sh
```

### 4. Apply LiDAR Config
```bash
bash ~/shadowhound/scripts/tower_fix_lidar_config.sh
```

### 5. Final Verification
```bash
cd ~/workspace/go2_omniverse && ./run_sim.sh
```

---

## Why This Works

**The Problem:**
- Tower: Isaac Lab v2.1.0 (April 2025)
- Repo: Updated May 2025 for Isaac Lab v2.2.0+
- Result: Module naming incompatibility

**The Solution:**
- Upgrade to Isaac Lab v2.2.1 (August 2025)
- Module naming now matches repo expectations
- LiDAR config can be applied successfully

**Version Timeline:**
```
April 24 ─── May 28 ─────────── August 7 ─── August 29
v2.1.0       Repo Updated        v2.2.0       v2.2.1
(Tower)      (added_copter)      (Upgrade)    (Latest)
   ↑                                            ↑
   └────────────── UPGRADE TO ──────────────────┘
```

---

## Success Criteria

**After upgrade, you should see:**
- ✅ Robot loads in simulation
- ✅ No module import errors
- ✅ No LiDAR config warnings
- ✅ Clean terminal output

**You should NOT see:**
- ❌ `ModuleNotFoundError: No module named 'omni.isaac.sensor'`
- ❌ `getProfileJsonAtPaths could not find config file`

---

## Rollback If Needed

If anything goes wrong:

```bash
cd ~/workspace/IsaacLab
git checkout v2.1.0
conda activate env_isaaclab
./isaaclab.sh --install
```

This restores the working v2.1.0 state.

---

## Files Created

**Scripts:**
- `scripts/tower_upgrade_isaaclab.sh` - Main upgrade logic
- `scripts/tower_test_sim_after_upgrade.sh` - Quick sim test
- `scripts/tower_upgrade_complete.sh` - Full orchestration

**Documentation:**
- `docs/deployment/tower_isaaclab_upgrade_guide.md` - Complete guide

**Total commits:** 34 on dev branch

---

## Next Steps After Upgrade

Once the upgrade succeeds and simulation works:

1. **Verify ROS2 topics** (original goal before this detour):
   ```bash
   ros2 topic list | grep go2
   ```

2. **Test with RViz2**:
   ```bash
   rviz2
   # Add displays for camera, LiDAR, TF
   ```

3. **Document Isaac Lab v2.2.1 as new baseline** in project docs

4. **Celebrate** 🎉 - We identified and fixed a subtle version mismatch!

---

## Support

Full documentation: `docs/deployment/tower_isaaclab_upgrade_guide.md`

Questions? The guide includes:
- Detailed step explanations
- Version compatibility matrix
- Expected outputs for each step
- Troubleshooting tips
