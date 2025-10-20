#!/bin/bash
# Try Isaac Lab v2.1.1 - the sweet spot version
# Released July 30, 2025 (after repo update May 28)
# Should have Isaac Sim 4.5.0 compatibility

set -e

echo "============================================"
echo "Testing Isaac Lab v2.1.1"
echo "============================================"
echo ""
echo "Timeline:"
echo "  April 24: v2.1.0 released (Tower original)"
echo "  May 28:   go2_omniverse updated"
echo "  July 30:  v2.1.1 released ← TESTING THIS"
echo "  August 7: v2.2.0 released (broke compatibility)"
echo ""

cd ~/workspace/IsaacLab

echo "Checking out v2.1.1..."
git checkout v2.1.1

echo ""
echo "Installing Isaac Lab v2.1.1..."
source ~/miniconda3/etc/profile.d/conda.sh
conda activate env_isaaclab

# Clean install
./isaaclab.sh --install

echo ""
echo "============================================"
echo "✓ Isaac Lab v2.1.1 installed"
echo "============================================"
echo ""
echo "Version:"
git describe --tags
echo ""
echo "Next: Test if simulation works"
echo "  cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo ""
