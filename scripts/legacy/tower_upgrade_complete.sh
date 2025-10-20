#!/bin/bash
# Complete Tower Isaac Lab Upgrade - All Steps in One Script
# This orchestrates the entire upgrade process

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Tower Isaac Lab Upgrade: v2.1.0 → v2.2.1                     ║"
echo "║  Fixing go2_omniverse LiDAR Config Compatibility              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Pull latest scripts
echo "Step 1: Updating scripts from dev branch..."
cd ~/shadowhound
git pull origin dev
echo "✓ Scripts updated"
echo ""

# Run Isaac Lab upgrade
echo "Step 2: Upgrading Isaac Lab..."
bash ~/shadowhound/scripts/tower_upgrade_isaaclab.sh

# Test simulation
echo ""
echo "Step 3: Testing simulation after upgrade..."
echo "This will run a 60-second test..."
bash ~/shadowhound/scripts/tower_test_sim_after_upgrade.sh

# Prompt user before continuing
echo ""
read -p "Did the simulation test succeed? (y/n): " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Simulation test failed. Run rollback:"
    echo "  cd ~/workspace/IsaacLab && git checkout v2.1.0"
    echo "  ./isaaclab.sh --install"
    exit 1
fi

# Apply LiDAR config
echo ""
echo "Step 4: Applying LiDAR configuration..."
bash ~/shadowhound/scripts/tower_fix_lidar_config.sh

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  ✓ Upgrade Complete!                                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Final verification:"
echo "  cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo ""
echo "You should see:"
echo "  ✓ Robot loads successfully"
echo "  ✓ No LiDAR config errors"
echo "  ✓ Clean terminal output"
echo ""
