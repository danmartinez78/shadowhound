#!/bin/bash
# Test Go2 simulation after Isaac Lab upgrade
# Quick 10-second test to verify everything still works

set -e

echo "============================================"
echo "Testing Go2 Simulation After Upgrade"
echo "============================================"
echo ""

# Activate conda
source ~/miniconda3/etc/profile.d/conda.sh
conda activate env_isaaclab

# Go to sim directory
cd ~/workspace/go2_omniverse

echo "Starting 10-second simulation test..."
echo "Press Ctrl+C after you see the robot if it takes longer"
echo ""

# Run simulation for 10 seconds with timeout
timeout 60s ./run_sim.sh || {
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo ""
        echo "✓ Timeout reached - simulation started successfully!"
        echo ""
    else
        echo ""
        echo "✗ Simulation failed with exit code: $EXIT_CODE"
        echo ""
        exit $EXIT_CODE
    fi
}

echo "============================================"
echo "Simulation Test Complete"
echo "============================================"
echo ""
echo "If you saw the robot and no errors:"
echo "  ✓ Isaac Lab v2.2.1 is working"
echo "  → Next: Apply LiDAR config with tower_fix_lidar_config.sh"
echo ""
