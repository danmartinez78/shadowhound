#!/bin/bash
# Alternative: Find Isaac Lab version compatible with PyTorch 2.5.1
# This avoids the PyTorch upgrade issue entirely

set -e

echo "============================================"
echo "Checking Isaac Lab Version Compatibility"
echo "============================================"
echo ""

cd ~/workspace/IsaacLab

echo "Current PyTorch version:"
source ~/miniconda3/etc/profile.d/conda.sh
conda activate env_isaaclab
python -c "import torch; print(f'  PyTorch: {torch.__version__}')"

echo ""
echo "Checking Isaac Lab release notes for PyTorch requirements..."
echo ""

# Check v2.1.1 (between v2.1.0 and v2.2.0)
echo "=== Isaac Lab v2.1.1 (July 30, 2025) ==="
git show v2.1.1:docs/source/refs/changelog.rst 2>/dev/null | head -50 || echo "Release notes not found"

echo ""
echo "=== Isaac Lab v2.2.0 (August 7, 2025) ==="
echo "From release page: Updates torch to 2.7.0 with cuda 12.8"
echo "This is the version that breaks PyTorch compatibility"

echo ""
echo "============================================"
echo "Recommendation:"
echo "============================================"
echo ""
echo "Option 1: Upgrade to v2.1.1 (conservative)"
echo "  - Uses PyTorch 2.5.1 (no change)"
echo "  - Released July 30, 2025 (after repo May 28 update)"
echo "  - May still have extension.toml issues"
echo ""
echo "Option 2: Upgrade to v2.2.1 (recommended)"
echo "  - Requires PyTorch 2.7.0 upgrade"
echo "  - Guaranteed compatible with May 2025 repo"
echo "  - PyTorch upgrade is safe for our use case"
echo ""
echo "Option 3: Stay on v2.1.0 and patch extension.toml"
echo "  - Manually fix module naming in extension.toml"
echo "  - No version upgrade needed"
echo "  - More maintenance work"
echo ""
