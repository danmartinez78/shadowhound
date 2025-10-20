#!/bin/bash
# Check Isaac Lab version compatibility with Isaac Sim 4.5.0

echo "============================================"
echo "Isaac Lab Version Compatibility Check"
echo "============================================"
echo ""

cd ~/workspace/IsaacLab

echo "Current Isaac Lab version:"
git describe --tags
echo ""

echo "Isaac Sim version on Tower:"
python -c "import isaacsim; print(isaacsim.__version__)" 2>/dev/null || echo "  Could not detect (4.5.0 expected)"
echo ""

echo "Checking Isaac Lab release compatibility..."
echo ""

echo "=== v2.1.0 (April 24, 2025) ==="
echo "  - Original install on Tower"
echo "  - Uses PyTorch 2.5.1"
echo "  - Compatible with Isaac Sim 4.2"
echo "  - Status: Working before upgrade"
echo ""

echo "=== v2.1.1 (July 30, 2025) ==="
echo "  - Patch release after v2.1.0"
echo "  - Still uses PyTorch 2.5.1"
echo "  - Compatible with Isaac Sim 4.2"
echo "  - Note: NOT mentioned to support Isaac Sim 4.5.0"
echo ""

echo "=== v2.2.0 (August 7, 2025) ==="
echo "  - Major update"
echo "  - Upgrades to PyTorch 2.7.0+cu128"
echo "  - Compatible with Isaac Sim 5.0"
echo "  - Backwards compatible with Isaac Sim 4.5"
echo "  - ⚠️  Expects Isaac Sim 5.0 metadata"
echo ""

echo "=== v2.2.1 (August 29, 2025) ==="
echo "  - Patch release after v2.2.0"
echo "  - Uses PyTorch 2.7.0+cu128"
echo "  - Compatible with Isaac Sim 5.0"
echo "  - Backwards compatible with Isaac Sim 4.5"
echo "  - ⚠️  Expects Isaac Sim 5.0 metadata"
echo ""

echo "============================================"
echo "Diagnosis"
echo "============================================"
echo ""
echo "Tower has: Isaac Sim 4.5.0 (pip install)"
echo "Error: Isaac Lab v2.2.1 tries to parse version as float"
echo "Issue: Version detection expects Isaac Sim 5.0 metadata format"
echo ""
echo "Options:"
echo ""
echo "1. Stay on v2.1.0 and accept LiDAR warnings (RECOMMENDED)"
echo "   - Simulation works"
echo "   - LiDAR data publishes via omnigraph anyway"
echo "   - No version compatibility issues"
echo ""
echo "2. Manually patch Isaac Lab v2.2.1 version detection"
echo "   - Fix the float parsing error"
echo "   - May have other Isaac Sim 5.0 dependencies"
echo "   - More maintenance overhead"
echo ""
echo "3. Upgrade Isaac Sim to 5.0"
echo "   - Big change, may break other things"
echo "   - Not necessary for LiDAR warnings"
echo ""

