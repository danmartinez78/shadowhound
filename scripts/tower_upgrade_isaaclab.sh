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
echo "Reinstalling Isaac Lab packages..."
cd ~/workspace/IsaacLab

# Remove old installed packages to force reinstall
pip uninstall -y isaaclab isaacsim-rl isaacsim-replicator isaacsim-extscache-physics isaacsim-extscache-kit-sdk isaacsim-extscache-kit isaacsim-app 2>/dev/null || true

# Run Isaac Lab installer
./isaaclab.sh --install

echo ""
echo "Step 6: Verifying installation..."
python -c "import isaaclab; print(f'Isaac Lab imported successfully')"
python -c "import rsl_rl; print(f'rsl_rl version: {rsl_rl.__version__}')"

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
