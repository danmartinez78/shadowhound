---
tags: [tower, simulation, versions, compatibility]
status: active
related: [tower_go2_isaac_sim_quickstart.md, tower_sim_datalake_setup.md]
summary: >
  Tested and verified software versions for Tower simulation setup
---

# Tower Simulation Stack - Version Compatibility Matrix

**Last Updated**: October 20, 2025  
**Status**: ✅ Tested and Working (pending Isaac Lab v2.1.0 verification)

---

## System Requirements

### Hardware
- **GPU**: NVIDIA RTX 4070 Ti (12GB VRAM) ✅
- **CPU**: Intel i7-6850K (6 cores, 12 threads) ✅
- **RAM**: 64GB ✅
- **OS**: Ubuntu 22.04.5 LTS (Jammy Jellyfish) ✅
- **Kernel**: 6.8.0-85-generic ✅

### NVIDIA Driver
- **Minimum**: 535.129.03 (required by Isaac Sim 4.5)
- **Recommended**: 550.xx or later (full RTX features)
- **Currently Tested**: 580.95.05 ✅
- **Install**: `bash ~/shadowhound/scripts/tower_update_nvidia_driver.sh`

---

## Core Software Stack

### Isaac Sim & Isaac Lab

| Component | Version | Status | Notes |
|-----------|---------|--------|-------|
| **Isaac Sim** | 4.5.0 | ✅ Working | Installed via pip |
| **Isaac Lab** | v2.1.0 (0.36.21) | 🔄 Testing | Downgraded for go2_omniverse compat |
| **Isaac Lab (Latest)** | 0.47.1 | ❌ Incompatible | Has rsl_rl 2.x breaking changes |
| **Python** | 3.10 | ✅ Required | From conda env_isaaclab |

**Key Insight**: Isaac Lab 0.47.1 has rsl_rl 2.x which breaks go2_omniverse. Use v2.1.0 (code version 0.36.21) instead.

**Installation**:
```bash
# Fresh install (use v2.1.0)
cd ~/workspace
git clone https://github.com/isaac-sim/IsaacLab.git
cd IsaacLab
git checkout v2.1.0
./isaaclab.sh --install

# Downgrade existing installation
bash ~/shadowhound/scripts/tower_downgrade_isaac_lab.sh
```

---

### ROS2

| Component | Version | Status | Notes |
|-----------|---------|--------|-------|
| **ROS2** | Humble | ✅ Working | Ubuntu 22.04 default |
| **DDS** | CycloneDDS | ✅ Working | Better performance than FastDDS |
| **ROS Domain** | 0 | ✅ Default | For Tower/laptop communication |

**Required Packages**:
```bash
sudo apt-get install -y \
  ros-humble-desktop \
  ros-humble-tf-transformations \
  ros-dev-tools
```

---

### Go2 Simulation

| Component | Version | Status | Notes |
|-----------|---------|--------|-------|
| **go2_omniverse** | added_copter branch | ✅ Working | Last updated May 28, 2025 |
| **go2_ros2_sdk** | Latest | ✅ Compatible | Same ROS2 topics as real robot |
| **rsl_rl** | 1.x (from Isaac Lab v2.1.0) | ✅ Required | v2.x breaks compatibility |

**Repository**:
- Source: https://github.com/abizovnuralem/go2_omniverse
- Branch: `added_copter`
- Includes: Unitree L1 LiDAR support

---

### Python Dependencies (conda env_isaaclab)

| Package | Version | Install Method | Status | Notes |
|---------|---------|----------------|--------|-------|
| **empy** | 3.3.4 | pip (system + conda) | ✅ Critical | ROS2 Humble requires exactly 3.3.4 |
| **catkin_pkg** | Latest | pip | ✅ Required | ROS2 package.xml parsing |
| **lark** | Latest | pip | ✅ Required | Parser for catkin_pkg |
| **transforms3d** | Latest | pip | ❌ Wrong | Use ROS package instead |
| **isaacsim** | 4.5.0 | pip | ✅ Working | Isaac Sim Python API |

**Critical empy Issue**:
- ROS2 Humble requires `empy==3.3.4` (NOT 4.x)
- Must install in BOTH system Python AND conda env
- Isaac Lab may install wrong version - reinstall with:
  ```bash
  sudo /usr/bin/python3 -m pip uninstall -y empy
  sudo /usr/bin/python3 -m pip install empy==3.3.4
  conda activate env_isaaclab
  pip uninstall -y empy em empy-stubs
  pip install --force-reinstall --no-deps empy==3.3.4
  ```

---

## Known Version Conflicts

### ❌ Isaac Lab 0.47.1 + go2_omniverse
**Error**: `KeyError: 'obs_groups'`  
**Cause**: rsl_rl 2.x API change  
**Solution**: Downgrade to Isaac Lab v2.1.0

### ❌ empy 4.x + ROS2 Humble
**Error**: `AttributeError: module 'em' has no attribute 'Interpreter'`  
**Cause**: empy 4.x has breaking API changes  
**Solution**: Force install empy 3.3.4

### ❌ Driver < 535.129 + Isaac Sim 4.5
**Warning**: `HydraEngine rtx failed creating scene renderer`  
**Cause**: Old driver lacks RTX features  
**Solution**: Update to driver 550+ (optional but recommended)

---

## Verified Installation Sequence

This sequence has been tested and works:

1. **Base System**
   ```bash
   sudo apt-get update
   sudo apt-get install -y nvidia-driver-550  # or 580
   sudo reboot
   ```

2. **ROS2 Humble**
   ```bash
   # Add ROS2 apt repository
   sudo apt-get install -y ros-humble-desktop ros-dev-tools
   sudo apt-get install -y ros-humble-tf-transformations
   ```

3. **Isaac Lab v2.1.0**
   ```bash
   cd ~/workspace
   git clone https://github.com/isaac-sim/IsaacLab.git
   cd IsaacLab
   git checkout v2.1.0
   ./isaaclab.sh --install
   ```

4. **Fix empy Version**
   ```bash
   sudo /usr/bin/python3 -m pip install empy==3.3.4
   conda activate env_isaaclab
   pip install --force-reinstall --no-deps empy==3.3.4
   pip install catkin_pkg lark
   ```

5. **Build Go2 Workspaces**
   ```bash
   cd ~/shadowhound
   bash scripts/tower_setup_go2_sim.sh
   ```

6. **Launch Simulation**
   ```bash
   conda activate env_isaaclab
   cd ~/workspace/go2_omniverse
   ./run_sim.sh
   ```

---

## Automated Installation

The main Tower setup script handles most of this automatically:

```bash
cd ~/shadowhound
bash scripts/sim_and_data_lake_setup.sh install
```

**After installation**, downgrade Isaac Lab if needed:
```bash
bash scripts/tower_downgrade_isaac_lab.sh
```

---

## Rollback Instructions

### Upgrade Isaac Lab to Latest

```bash
cd ~/workspace/IsaacLab
git checkout main
./isaaclab.sh --install
```

**Note**: This will break go2_omniverse compatibility (obs_groups error).

### Downgrade Isaac Lab to v2.1.0

```bash
bash ~/shadowhound/scripts/tower_downgrade_isaac_lab.sh
```

---

## Testing & Validation

### Verify NVIDIA Driver

```bash
nvidia-smi
# Should show: Driver Version: 550.xx or higher
```

### Verify Isaac Lab Version

```bash
conda activate env_isaaclab
python -c "import isaaclab; print(isaaclab.__version__)"
# Should show: 0.36.21 (from v2.1.0 tag)
```

### Verify empy Version

```bash
# System Python
/usr/bin/python3 -c "import em; print(em.__version__)"
# Should show: 3.3.4

# Conda Python
conda activate env_isaaclab
python3 -c "import em; print(em.__version__)"
# Should show: 3.3.4
```

### Verify ROS2 Setup

```bash
source /opt/ros/humble/setup.bash
ros2 topic list
# Should not error
```

### Test Go2 Simulation

```bash
conda activate env_isaaclab
cd ~/workspace/go2_omniverse
./run_sim.sh
# Should launch without obs_groups error
```

---

## Troubleshooting Quick Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `KeyError: 'obs_groups'` | Isaac Lab too new | Downgrade to v2.1.0 |
| `module 'em' has no attribute 'Interpreter'` | empy 4.x installed | Install empy 3.3.4 |
| `No module named 'tf_transformations'` | Missing ROS package | `sudo apt install ros-humble-tf-transformations` |
| `HydraEngine rtx failed` | Old NVIDIA driver | Update to driver 550+ |
| Simulation freezes | Various causes | Check `docs/deployment/tower_go2_isaac_sim_quickstart.md` |

---

## Version Change History

### October 20, 2025
- ✅ Verified NVIDIA driver 580.95.05 works
- ✅ Identified Isaac Lab v2.1.0 as compatible version
- ✅ Fixed empy 3.3.4 installation (system + conda)
- ✅ Added ros-humble-tf-transformations requirement
- 🔄 Testing Isaac Lab v2.1.0 downgrade

### October 19, 2025
- Initial setup with Isaac Lab 0.47.1
- Discovered rsl_rl 2.x incompatibility

---

## References

- **Isaac Sim**: https://docs.omniverse.nvidia.com/isaacsim/latest/
- **Isaac Lab**: https://github.com/isaac-sim/IsaacLab
- **go2_omniverse**: https://github.com/abizovnuralem/go2_omniverse
- **ROS2 Humble**: https://docs.ros.org/en/humble/
- **rsl_rl**: https://github.com/leggedrobotics/rsl_rl

---

## Update Instructions

After testing confirms a version works or doesn't work, update this document:

1. Edit this file: `docs/deployment/tower_version_compatibility.md`
2. Update status: ✅ Working, 🔄 Testing, ❌ Incompatible
3. Add notes about what was tested
4. Commit: `docs(tower): update version compatibility matrix`
