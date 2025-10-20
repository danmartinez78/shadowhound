# Tower Manual Isaac Sim Installation Guide

**Date:** October 20, 2025  
**Machine:** Tower (RTX 4070 Ti 12GB, i7-6850K, Ubuntu 22.04.5)  
**Purpose:** Clean manual installation after complete uninstall

---

## Prerequisites Verification

Before starting, verify these are still installed:
```bash
# Check Python
python3 --version  # Should be 3.10+

# Check Conda
conda --version

# Check NVIDIA Driver
nvidia-smi  # Should show driver 580.95.05

# Check CUDA
nvcc --version  # Should be available
```

---

## Step 1: Run Complete Uninstall

```bash
# From Tower machine (not devcontainer)
bash ~/shadowhound/scripts/tower_complete_uninstall_isaac.sh
```

This removes:
- ✅ Conda env `env_isaaclab`
- ✅ Isaac Lab repository
- ✅ Isaac Sim installation
- ✅ All cache/config files

---

## Step 2: Choose Your Installation Path

### 🎯 Option A: Isaac Sim 5.0 + Official Go2 (RECOMMENDED)

**Pros:**
- Official NVIDIA Go2 support
- Latest features
- Future-proof
- Clean version compatibility

**Cons:**
- Uncharted territory (never tested before)
- Potential API changes

### ⚡ Option B: Isaac Sim 4.5.0 + Isaac Lab 2.1.0 (KNOWN WORKING)

**Pros:**
- Previously validated
- Known to work with go2_omniverse
- Less risk

**Cons:**
- Older versions
- Cosmetic LiDAR warnings
- Dependent on community repo

---

## Installation: Option A (Isaac Sim 5.0)

### A1. Create Fresh Conda Environment
```bash
cd ~
conda create -n env_isaaclab python=3.10 -y
conda activate env_isaaclab
```

### A2. Install Isaac Sim 5.0
```bash
# Install pip dependencies first
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install Isaac Sim 5.0
pip install isaacsim==5.0.0

# Verify installation
python -c "from isaacsim import SimulationApp; print('Isaac Sim 5.0 installed successfully')"
```

### A3. Install Isaac Lab 2.2.1
```bash
cd ~/workspace/go2_omniverse
mkdir -p _isaac_sim
cd _isaac_sim

# Clone Isaac Lab
git clone https://github.com/isaac-sim/IsaacLab.git _isaac_lab
cd _isaac_lab
git checkout v2.2.1

# Install Isaac Lab
./isaaclab.sh --install

# This will:
# - Install dependencies
# - Set up Python bindings
# - Configure extensions
```

### A4. Test Official Go2 Asset
```bash
cd ~/workspace/go2_omniverse/_isaac_sim/_isaac_lab

# Create test script
cat > test_go2_official.py << 'EOF'
from isaacsim import SimulationApp
simulation_app = SimulationApp({"headless": False})

from isaacsim.core.utils.stage import add_reference_to_stage
from isaacsim.storage.native import get_assets_root_path

assets_root_path = get_assets_root_path()
go2_path = assets_root_path + "/Isaac/Robots/Unitree/Go2/go2.usd"

print(f"Loading official Go2 from: {go2_path}")
add_reference_to_stage(usd_path=go2_path, prim_path="/World/Go2")

print("Official Go2 loaded successfully!")
simulation_app.update()

input("Press Enter to exit...")
simulation_app.close()
EOF

# Run test
python test_go2_official.py
```

### A5. Configure ROS2 Bridge
```bash
cd ~/workspace/go2_omniverse/_isaac_sim

# Clone official ROS2 workspace
git clone https://github.com/isaac-sim/IsaacSim-ros_workspaces.git ros_workspaces
cd ros_workspaces

# Build Humble workspace
cd humble_ws
colcon build --symlink-install

# Source ROS2
source install/setup.bash
```

---

## Installation: Option B (Isaac Sim 4.5.0)

### B1. Create Fresh Conda Environment
```bash
cd ~
conda create -n env_isaaclab python=3.10 -y
conda activate env_isaaclab
```

### B2. Install Isaac Sim 4.5.0
```bash
# Install pip dependencies
pip install torch==2.5.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install Isaac Sim 4.5.0
pip install isaacsim==4.5.0

# Verify installation
python -c "from isaacsim import SimulationApp; print('Isaac Sim 4.5.0 installed successfully')"
```

### B3. Install Isaac Lab 2.1.0
```bash
cd ~/workspace/go2_omniverse
mkdir -p _isaac_sim
cd _isaac_sim

# Clone Isaac Lab
git clone https://github.com/isaac-sim/IsaacLab.git _isaac_lab
cd _isaac_lab
git checkout v2.1.0

# Install Isaac Lab
./isaaclab.sh --install
```

### B4. Test with go2_omniverse
```bash
cd ~/workspace/go2_omniverse

# Run existing test script
./run_sim.sh

# LiDAR warnings are cosmetic, data works via omnigraph
```

---

## Post-Installation Verification

### 1. Test Isaac Sim Import
```bash
conda activate env_isaaclab
python -c "from isaacsim import SimulationApp; print('✅ Isaac Sim imports successfully')"
```

### 2. Test Isaac Lab Import
```bash
python -c "from isaacsim.core.api import World; print('✅ Isaac Lab imports successfully')"
```

### 3. Check GPU Access
```bash
python -c "import torch; print(f'✅ CUDA available: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\"}')"
```

### 4. Test Simulation Window
```bash
cd ~/workspace/go2_omniverse/_isaac_sim/_isaac_lab

python -c "
from isaacsim import SimulationApp
simulation_app = SimulationApp({'headless': False})
print('✅ Simulation window opened successfully')
import time
time.sleep(3)
simulation_app.close()
"
```

---

## Troubleshooting

### Issue: Import errors
```bash
# Solution: Ensure conda env is activated
conda activate env_isaaclab

# Check Python path
which python
# Should show: ~/miniconda3/envs/env_isaaclab/bin/python
```

### Issue: CUDA not found
```bash
# Solution: Check CUDA installation
nvidia-smi
nvcc --version

# Reinstall PyTorch with correct CUDA
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### Issue: Display not opening (headless mode)
```bash
# Solution: Check X11 forwarding (if remote)
echo $DISPLAY
# Should show: :0 or :1

# Or run in headless mode for testing
simulation_app = SimulationApp({'headless': True})
```

### Issue: Permission denied
```bash
# Solution: Check directory ownership
ls -la ~/workspace/go2_omniverse
sudo chown -R $USER:$USER ~/workspace/go2_omniverse
```

---

## What To Do After Installation

### Option A (Isaac Sim 5.0):
1. ✅ Test official Go2 asset loads
2. ✅ Configure ROS2 bridge for sensors
3. ✅ Integrate with go2_ros2_sdk
4. ✅ Validate sensor data in RViz2

### Option B (Isaac Sim 4.5.0):
1. ✅ Run go2_omniverse simulation
2. ✅ Verify ROS2 topics with `ros2 topic list`
3. ✅ Launch RViz2 for visualization
4. ✅ Accept LiDAR warnings (cosmetic)

---

## Documentation References

- **Isaac Sim 5.1.0 Docs:** https://docs.isaacsim.omniverse.nvidia.com/5.1.0/
- **Isaac Lab GitHub:** https://github.com/isaac-sim/IsaacLab
- **ROS2 Workspaces:** https://github.com/isaac-sim/IsaacSim-ros_workspaces
- **Go2 Findings:** `NVIDIA_GO2_SUPPORT_FINDINGS.md`

---

## Need Help?

If you encounter issues:
1. Check error messages carefully
2. Verify conda environment is activated
3. Confirm Python version (3.10)
4. Check GPU driver with `nvidia-smi`
5. Review Isaac Sim logs in `~/.local/share/ov/data/logs`

---

**Good luck with the manual installation!** 🚀
