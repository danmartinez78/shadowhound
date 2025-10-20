# Isaac Sim Docker Setup Scripts - Comparison

## Two Scripts, Different Purposes

### `test_isaac_sim_docker.sh` - Proof of Concept
**Use case**: Test containerized Isaac Sim on a system that **already has** Docker and NVIDIA driver installed.

**Prerequisites** (assumes already installed):
- ✅ Ubuntu 22.04
- ✅ NVIDIA Driver (any version >= 535)
- ✅ Docker Engine
- ✅ NVIDIA Container Toolkit

**What it does**:
1. Checks prerequisites (fails if missing)
2. Pulls Isaac Sim container
3. Tests GPU access
4. Tests Isaac Sim import
5. Creates helper script

**Best for**:
- Testing on Tower (which already has everything)
- Adding containerized Isaac Sim to existing setup
- Proof-of-concept validation

**Run on**: Tower, Laptop (with existing Docker setup)

---

### `tower_isaac_sim_docker_setup.sh` - Complete Installation
**Use case**: Set up containerized Isaac Sim on **fresh Ubuntu** or system without prerequisites.

**Prerequisites**: 
- ✅ Ubuntu 22.04 (fresh install OK)
- ❌ Nothing else required!

**What it installs**:
1. System prerequisites (curl, wget, git, etc.)
2. **NVIDIA Driver 580** (with reboot handling)
3. **Docker Engine** (official repo)
4. **NVIDIA Container Toolkit**
5. Isaac Sim 4.5.0 container
6. Helper scripts and docker-compose config

**Best for**:
- Fresh Ubuntu installations
- Systems without Docker or NVIDIA driver
- Complete end-to-end setup
- Replacing `sim_and_data_lake_setup.sh` pip install method

**Run on**: Fresh Ubuntu, Tower rebuild, Laptop fresh install

---

## Quick Decision Matrix

| Your Situation | Use This Script |
|---------------|-----------------|
| Fresh Ubuntu 22.04 install | `tower_isaac_sim_docker_setup.sh` |
| Tower with existing pip Isaac Sim | `test_isaac_sim_docker.sh` |
| System with Docker but no GPU driver | `tower_isaac_sim_docker_setup.sh` |
| System with GPU driver but no Docker | `tower_isaac_sim_docker_setup.sh` |
| Testing container alongside pip version | `test_isaac_sim_docker.sh` |
| Want complete automated setup | `tower_isaac_sim_docker_setup.sh` |

---

## Comparison Table

| Feature | test_isaac_sim_docker.sh | tower_isaac_sim_docker_setup.sh |
|---------|-------------------------|--------------------------------|
| **Installs NVIDIA Driver** | ❌ (checks only) | ✅ Driver 580 |
| **Installs Docker** | ❌ (checks only) | ✅ Official repo |
| **Installs NVIDIA Toolkit** | ❌ (checks only) | ✅ Full setup |
| **Pulls Isaac Sim Container** | ✅ | ✅ |
| **Creates Helper Scripts** | ✅ | ✅ |
| **Handles Reboots** | ❌ | ✅ (after driver install) |
| **Handles Docker Group** | ❌ | ✅ (with session refresh) |
| **Idempotent** | ✅ | ✅ (uses markers) |
| **Runtime** | 15-30 min (pull only) | 30-60 min (full install) |
| **Log File** | None | ~/.isaac_sim_docker_setup.log |

---

## Example Usage

### Scenario 1: Fresh Ubuntu → Running Isaac Sim
```bash
# On fresh Ubuntu 22.04
git clone https://github.com/danmartinez78/shadowhound
cd shadowhound
bash scripts/tower_isaac_sim_docker_setup.sh

# Script will:
# 1. Install everything (driver, docker, toolkit)
# 2. Prompt for reboot after driver install
# 3. Resume automatically after reboot
# 4. Pull Isaac Sim container
# 5. Create helper scripts
# 6. Run validation tests

# After completion:
isaacsim-docker  # Launch Isaac Sim!
```

### Scenario 2: Tower (existing setup) → Add Container
```bash
# On Tower with existing pip install
cd ~/shadowhound
bash scripts/test_isaac_sim_docker.sh

# Script will:
# 1. Check prerequisites (already installed)
# 2. Pull Isaac Sim container
# 3. Test GPU access
# 4. Create helper scripts

# After completion:
isaacsim-docker  # Container version
# OR
conda activate env_isaaclab && isaacsim  # Pip version

# Both work! Test and compare.
```

---

## Which Script Should You Use?

### Use `tower_isaac_sim_docker_setup.sh` if:
- ✅ Starting from fresh Ubuntu
- ✅ Don't have NVIDIA driver installed
- ✅ Don't have Docker installed
- ✅ Want automated end-to-end setup
- ✅ Want to replace pip install method entirely

### Use `test_isaac_sim_docker.sh` if:
- ✅ Already have Docker + NVIDIA driver (from sim_and_data_lake_setup.sh)
- ✅ Want to test container alongside pip install
- ✅ Just need proof-of-concept
- ✅ Don't want to modify existing setup

---

## Migration Path

### Current: Pip Install → Future: Container

**Step 1**: Test container (non-destructive)
```bash
bash scripts/test_isaac_sim_docker.sh  # Adds container, keeps pip
```

**Step 2**: Compare performance
```bash
# Test pip version
conda activate env_isaaclab
python -c "import isaacsim"

# Test container version
isaacsim-docker python -c "import isaacsim"
```

**Step 3**: If satisfied, switch to container
```bash
# Uninstall pip version (optional)
conda run -n env_isaaclab pip uninstall isaacsim

# Use container as default
isaacsim-docker
```

**Step 4**: Clean up (optional)
```bash
# Remove conda env (if only used for Isaac Sim)
conda env remove -n env_isaaclab
```

---

## Future: Integration into sim_and_data_lake_setup.sh

Eventually, `tower_isaac_sim_docker_setup.sh` will be integrated into the main setup script:

```bash
# Traditional method (pip install)
bash sim_and_data_lake_setup.sh install

# Container method (future)
ISAAC_SIM_INSTALL_METHOD=docker bash sim_and_data_lake_setup.sh install
```

For now, use the standalone script for fresh installs.
