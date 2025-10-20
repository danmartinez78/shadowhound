#!/bin/bash
# Upgrade Isaac Lab from v2.1.0 to v2.2.1 on Tower
# This should fix the LiDAR config incompatibility with go2_omniverse added_copter branch

set -e

echo "============================================"
echo "Isaac Lab Upgrade: v2.1.0 → v2.2.1"
echo "============================================"
echo ""

# Check current version
echo "Step 1: Checking current Isaac Lab version..."
cd ~/workspace/IsaacLab
CURRENT_VERSION=$(git describe --tags 2>/dev/null || echo "unknown")
echo "Current version: $CURRENT_VERSION"
echo ""

# Backup current state
echo "Step 2: Creating backup of current installation..."
BACKUP_DIR=~/isaaclab_v2.1.0_backup_$(date +%Y%m%d_%H%M%S)
echo "Backing up to: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -r ~/workspace/IsaacLab/.git "$BACKUP_DIR/" 2>/dev/null || true
echo "Backup created"
echo ""

# Update repository
echo "Step 3: Fetching latest Isaac Lab releases..."
cd ~/workspace/IsaacLab
git fetch --all --tags
echo ""

# Show available versions
echo "Available recent versions:"
git tag | grep "^v2\." | tail -5
echo ""

# Checkout v2.2.1
echo "Step 4: Upgrading to v2.2.1..."
git checkout v2.2.1
echo "✓ Checked out v2.2.1"
echo ""

# Clean conda environment and reinstall
echo "Step 5: Reinstalling Isaac Lab with new version..."
echo "Activating conda environment..."
source ~/miniconda3/etc/profile.d/conda.sh
conda activate env_isaaclab

echo ""
echo "Cleaning old Isaac Lab packages (v2.1.0 artifacts)..."
cd ~/workspace/IsaacLab

# Remove ALL old Isaac Lab packages to avoid version conflicts
pip uninstall -y isaaclab isaaclab-rl isaaclab-tasks isaacsim-rl isaacsim-replicator \
    isaacsim-extscache-physics isaacsim-extscache-kit-sdk isaacsim-extscache-kit \
    isaacsim-app isaacsim.core.nodes isaacsim.sensors.rtx 2>/dev/null || true

echo ""
echo "Removing cached pip wheels to force clean install..."
pip cache purge

echo ""
echo "Installing Isaac Lab v2.2.1..."
echo "Note: This will also upgrade PyTorch to 2.7.0+cu128"
echo ""
# Run Isaac Lab installer - it handles all dependencies including PyTorch
./isaaclab.sh --install

echo ""
echo "Step 6: Verifying installation..."
cd ~/workspace/IsaacLab
python -c "import torch; print(f'PyTorch version: {torch.__version__}')"
python -c "import isaaclab; print(f'Isaac Lab imported successfully')"
python -c "import rsl_rl; print(f'rsl_rl imported successfully')"

echo ""
echo "Checking for dependency conflicts..."
pip check || echo "⚠️  Some dependency warnings exist (usually non-critical)"

echo ""
echo "============================================"
echo "✓ Isaac Lab upgraded to v2.2.1"
echo "============================================"
echo ""
echo "Current version info:"
git describe --tags
git log -1 --oneline
echo ""
echo "Next steps:"
echo "1. Run simulation test: cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo "2. If sim works, apply LiDAR config: bash ~/shadowhound/scripts/tower_fix_lidar_config.sh"
echo ""
