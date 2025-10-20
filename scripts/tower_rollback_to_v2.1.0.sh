#!/bin/bash
# Rollback Isaac Lab to v2.1.0 (working state)

set -e

echo "============================================"
echo "Rolling Back to Isaac Lab v2.1.0"
echo "============================================"
echo ""

cd ~/workspace/IsaacLab

echo "Current version:"
git describe --tags
echo ""

echo "Checking out v2.1.0..."
git checkout v2.1.0

echo ""
echo "Reinstalling Isaac Lab v2.1.0..."
source ~/miniconda3/etc/profile.d/conda.sh
conda activate env_isaaclab

# Clean install
./isaaclab.sh --install

echo ""
echo "============================================"
echo "✓ Rolled back to Isaac Lab v2.1.0"
echo "============================================"
echo ""
echo "Version:"
git describe --tags
echo ""
echo "This was the working configuration before upgrade."
echo "LiDAR warnings will return, but they are cosmetic."
echo ""
echo "Test simulation:"
echo "  cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo ""
