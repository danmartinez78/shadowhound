# Fresh Ubuntu 22.04 Installation Guide for ShadowHound Tower

## Pre-Installation Checklist

### 1. BIOS Settings (Before Ubuntu Installation)

**CRITICAL: Disable Secure Boot**
```
1. Enter BIOS (press Del during boot)
2. Go to: Boot → Secure Boot
3. Set to: Disabled
4. Press F10 to save and exit
```

**Why?** Secure Boot requires signing NVIDIA driver kernel modules (MOK enrollment), which adds complexity and can cause boot issues. Not needed for workstation use.

**Other recommended BIOS settings (X99-E WS):**
- Advanced → System Agent → Memory Remap: **Enabled**
- Boot → Fast Boot: **Disabled**

### 2. Ubuntu 22.04 Installation
- ✅ Install Ubuntu 22.04.5 LTS Desktop (fresh install)
- ✅ During installation:
  - Choose "Minimal installation" (faster, cleaner)
  - Enable "Download updates while installing"
  - Install third-party software (WiFi, graphics drivers - **UNCHECK THIS**)
- ✅ Create user account: `daniel` (or your preferred username)
- ✅ Set hostname: `sim-tower`

### 3. First Boot Setup

### 3. First Boot Setup
After Ubuntu desktop loads:

```bash
# Update package lists
sudo apt-get update

# Install git and curl (minimum needed to clone repo)
sudo apt-get install -y git curl

# Clone the repository
cd ~
git clone https://github.com/danmartinez78/shadowhound.git
cd shadowhound
git checkout dev
```

## Installation - One Command

```bash
cd ~/shadowhound
./scripts/sim_and_data_lake_setup.sh install
```

**That's it!** The script will:
1. ✅ Install all base tools (curl, wget, git, build-essential, etc.)
2. ✅ Install Isaac Sim dependencies (libfuse2, mesa, vulkan, etc.)
3. ✅ Install NVIDIA driver 535-server (535.129.03+) - **REBOOT REQUIRED**
4. ✅ After reboot, continue with Docker + NVIDIA Container Toolkit
5. ✅ Install Miniconda3
6. ✅ Create Python 3.10 environment
7. ✅ Install Isaac Sim 4.5.0 via pip (~30GB download, 15-30 minutes)
8. ✅ Install ROS 2 Humble
9. ✅ Clone Isaac Lab and install extensions
10. ✅ Clone go2_omniverse (Unitree Go2 robot for Isaac Sim)
11. ✅ Configure MinIO (S3-compatible storage) with drive selection
12. ✅ Configure MLflow (experiment tracking) with PostgreSQL backend
13. ✅ Set up systemd service for auto-start
14. ✅ Configure firewall rules
15. ✅ Enable GPU persistence mode

## Expected Timeline

- **Base tools + dependencies**: 2-3 minutes
- **NVIDIA driver installation**: 3-5 minutes
- **REBOOT**: Required after driver install
- **Docker + container toolkit**: 3-5 minutes
- **Miniconda**: 2-3 minutes
- **Isaac Sim pip install**: 15-30 minutes (depends on download speed)
- **ROS 2 Humble**: 5-10 minutes
- **Isaac Lab extensions**: 5-10 minutes
- **MinIO/MLflow setup**: 2-3 minutes

**Total: ~45-60 minutes** (mostly automated, requires one reboot)

## Installation Flow

### Step 1: Driver Installation + Reboot
```bash
cd ~/shadowhound
./scripts/sim_and_data_lake_setup.sh install
```

**Output:**
```
╔════════════════════════════════════════════════════════════════╗
║  Robot Simulation + Data Lake Setup                            ║
║  Tower (sim-tower) Installation                                ║
╚════════════════════════════════════════════════════════════════╝

--- Installing Base System Tools ---
✓ Base tools and Isaac Sim dependencies installed

--- NVIDIA Driver for Isaac Sim 4.5.0 ---
Using recommended driver 535-server for Isaac Sim 4.5.0
No NVIDIA driver detected. Installing driver 535-server...
⚠ Driver 535-server installed. REBOOT REQUIRED before continuing.
⚠ After reboot, verify with: nvidia-smi
⚠ Expected driver version: 535.129.03 or higher
⚠ Then re-run: bash ./scripts/sim_and_data_lake_setup.sh install
```

**Action: REBOOT NOW**
```bash
sudo reboot
```

### Step 2: After Reboot - Verify Driver
```bash
nvidia-smi
```

**Expected output:**
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.129.03             Driver Version: 535.129.03   CUDA Version: 12.2     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 3080        On  |   00000000:05:00.0  On |                  N/A |
|   1  NVIDIA GeForce RTX 4070 Ti     On  |   00000000:09:00.0 Off |                  N/A |
```

✅ **Both GPUs detected**
✅ **Persistence-M: On** (script enables this automatically)
✅ **Driver version: 535.x**

### Step 3: Continue Installation
```bash
cd ~/shadowhound
./scripts/sim_and_data_lake_setup.sh install
```

**The script will:**
- Detect driver 535 is installed ✓
- Skip driver installation
- Continue with Docker, Isaac Sim, ROS2, etc.

**Interactive prompts:**
1. **Data directory selection**: Choose where to store robot data (e.g., `/mnt/disk1/robot-data`)
2. **MinIO drives selection**: Choose drives for S3 storage (numbered menu, select with spaces)

### Step 4: Verify Installation
After installation completes:

```bash
# Check system health
~/shadowhound/scripts/sim_and_data_lake_setup.sh doctor

# Check GPU configuration
~/shadowhound/scripts/check_pcie_config.sh

# Test Isaac Sim
source ~/.robot-simrc
conda activate env_isaaclab
python -c "import isaacsim; print('✓ Isaac Sim OK')"

# Test Isaac Lab
cd ~/workspace/IsaacLab
./isaaclab.sh -p -c "import omni.isaac.lab; print('✓ Isaac Lab OK')"

# Test ROS2
source /opt/ros/humble/setup.bash
ros2 --version
```

## Troubleshooting

### GPU Not Detected After Reboot
```bash
# Check if GPUs are on PCI bus
lspci | grep -i nvidia

# Check kernel messages
dmesg | grep -i nvidia | tail -20

# Run full diagnostics
sudo ~/shadowhound/scripts/check_pcie_config.sh
```

### Driver Version Wrong
If `nvidia-smi` shows driver other than 535.x:

```bash
# Remove marker file to force reinstall
rm ~/.go2_stack_state/nvidia_driver_checked

# Run install again
cd ~/shadowhound
./scripts/sim_and_data_lake_setup.sh install
```

### Isaac Sim Import Fails
```bash
# Check Python environment
conda activate env_isaaclab
python --version  # Should be 3.10.x

# Check Isaac Sim installation
pip list | grep isaacsim  # Should show isaacsim 4.5.0.x

# Reinstall if needed
pip uninstall isaacsim
pip install isaacsim[all,extscache]==4.5.0
```

### Isaac Lab Extensions Not Installed
```bash
cd ~/workspace/IsaacLab
conda activate env_isaaclab
./isaaclab.sh --install
```

## What's Installed

### System Packages
- Base tools: curl, wget, git, build-essential, cmake, jq
- Graphics: libfuse2, mesa-utils, vulkan-tools, libglu1-mesa
- Networking: net-tools, dnsutils, nmap
- Monitoring: htop, nvtop, iotop
- Python: python3-pip, python3-dev, python3-venv

### NVIDIA Stack
- Driver: 535-server (535.129.03+)
- Container Toolkit: nvidia-docker2
- Persistence Mode: Enabled

### Python Environment
- Miniconda3: `~/miniconda3`
- Environment: `env_isaaclab` (Python 3.10)
- Isaac Sim: 4.5.0 with all extensions
- Additional: ipython, jupyter, tensorboard, matplotlib

### ROS 2
- Distribution: Humble (desktop + dev-tools)
- Location: `/opt/ros/humble`

### Isaac Lab
- Location: `~/workspace/IsaacLab`
- Branch: main
- Extensions: Installed with `./isaaclab.sh --install`

### Go2 Omniverse
- Location: `~/workspace/go2_omniverse`
- Branch: added_copter
- Patches: LiDAR configuration applied

### Data Lake
- MinIO: S3-compatible storage (ports 9000, 9001)
- MLflow: Experiment tracking (port 5001)
- PostgreSQL: MLflow backend store (internal)
- Systemd service: `robot-datalake.service` (auto-start on boot)

### Configuration Files
- Profile: `~/.robot-simrc` (add to `~/.bashrc`)
- Network docs: `<data_dir>/NETWORK_SETUP.md`
- Credentials: `<minio_dir>/CREDENTIALS.txt`
- Logs: `~/sim_setup.log`

## Post-Installation

### 1. Add Profile to Shell
```bash
echo "source ~/.robot-simrc" >> ~/.bashrc
exec bash
```

### 2. Transfer Credentials to Compute Nodes
```bash
# To Thor
scp <minio_dir>/CREDENTIALS.txt thor:~/tower_credentials.txt

# To Spark (if you have one)
scp <minio_dir>/CREDENTIALS.txt spark:~/tower_credentials.txt
```

### 3. Test Services
```bash
# MinIO web UI
firefox http://192.168.0.229:9001

# MLflow UI
firefox http://192.168.0.229:5001
```

### 4. Run First Simulation
```bash
cd ~/workspace/IsaacLab
conda activate env_isaaclab
./isaaclab.sh -p source/standalone/tutorials/00_sim/spawn_prims.py
```

## Network Configuration (Optional)

If you want to configure dual-NIC topology:
```bash
~/shadowhound/scripts/sim_and_data_lake_setup.sh reconfigure-network
```

## Backup Recommendations

After successful installation, backup:
- `~/.go2_stack_state/` - Installation markers
- `~/.robot-simrc` - Environment configuration
- `<data_dir>/NETWORK_SETUP.md` - Network documentation
- `<minio_dir>/CREDENTIALS.txt` - Service credentials

## Support

If issues occur:
1. Check logs: `cat ~/sim_setup.log`
2. Run diagnostics: `~/shadowhound/scripts/sim_and_data_lake_setup.sh doctor`
3. Check GPU: `sudo ~/shadowhound/scripts/check_pcie_config.sh`
4. Consult: `docs/troubleshooting/` in repo

## References

- Isaac Sim Requirements: https://docs.isaacsim.omniverse.nvidia.com/4.5.0/installation/requirements.html
- Isaac Lab: https://isaac-lab.github.io/
- ROS 2 Humble: https://docs.ros.org/en/humble/
