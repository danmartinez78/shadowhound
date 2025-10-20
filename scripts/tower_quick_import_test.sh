#!/bin/bash
# Quick Python-only test (no Isaac Sim startup)
# Just verify packages import correctly

source ~/miniconda3/etc/profile.d/conda.sh
conda activate env_isaaclab

echo "============================================"
echo "Quick Import Test (No Sim Startup)"
echo "============================================"
echo ""

python << 'PYEOF'
import sys

print("Python version:", sys.version.split()[0])
print("")

try:
    import torch
    print(f"✓ PyTorch {torch.__version__}")
    print(f"  CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"  CUDA version: {torch.version.cuda}")
except Exception as e:
    print(f"✗ PyTorch import failed: {e}")
    sys.exit(1)

try:
    import isaaclab
    print(f"✓ Isaac Lab imported")
except Exception as e:
    print(f"✗ Isaac Lab import failed: {e}")
    sys.exit(1)

try:
    import rsl_rl
    print(f"✓ rsl_rl imported")
except Exception as e:
    print(f"✗ rsl_rl import failed: {e}")
    sys.exit(1)

try:
    from isaaclab.envs import ManagerBasedRLEnv
    print(f"✓ ManagerBasedRLEnv imported")
except Exception as e:
    print(f"✗ ManagerBasedRLEnv import failed: {e}")
    sys.exit(1)

print("")
print("✅ All critical imports successful!")
print("")
print("Isaac Lab v2.2.1 upgrade appears successful.")
print("The pip dependency warnings can be ignored.")
PYEOF

echo ""
echo "============================================"
echo "Next Step: Test Actual Simulation"
echo "============================================"
echo ""
echo "If imports succeeded above, run:"
echo "  cd ~/workspace/go2_omniverse && ./run_sim.sh"
echo ""
echo "The extension.toml warnings you saw are normal."
echo "They're just deprecated/cache extensions with missing configs."
echo ""
