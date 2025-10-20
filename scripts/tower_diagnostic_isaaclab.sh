#!/bin/bash
# Check current Isaac Lab installation status after upgrade attempt

source ~/miniconda3/etc/profile.d/conda.sh
conda activate env_isaaclab

echo "============================================"
echo "Isaac Lab Installation Diagnostic"
echo "============================================"
echo ""

echo "PyTorch version:"
python -c "import torch; print(f'  {torch.__version__}')"

echo ""
echo "Isaac Lab version:"
cd ~/workspace/IsaacLab
git describe --tags

echo ""
echo "Isaac Lab Python package:"
python -c "import isaaclab; print(f'  Imported successfully from: {isaaclab.__file__}')"

echo ""
echo "Checking installed packages:"
pip list | grep -E "(isaac|torch|rsl)" || echo "  No matching packages found"

echo ""
echo "Checking for dependency conflicts:"
pip check 2>&1 | head -20

echo ""
echo "============================================"
echo "Quick Import Test"
echo "============================================"
python << 'PYEOF'
try:
    import torch
    print(f"✓ PyTorch {torch.__version__}")
    
    import isaaclab
    print(f"✓ Isaac Lab imported")
    
    import rsl_rl
    print(f"✓ rsl_rl imported")
    
    # Try importing key modules
    from isaaclab.envs import ManagerBasedRLEnv
    print(f"✓ ManagerBasedRLEnv imported")
    
    print("\n✅ All critical imports successful!")
except Exception as e:
    print(f"\n❌ Import failed: {e}")
PYEOF

echo ""
echo "============================================"
echo "Summary"
echo "============================================"
echo ""
echo "If you see '✅ All critical imports successful!' above,"
echo "then the upgrade worked despite pip dependency warnings."
echo ""
echo "Pip dependency warnings are often non-critical - what matters"
echo "is whether the code actually runs."
echo ""
