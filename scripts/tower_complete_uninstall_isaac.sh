#!/bin/bash
# Complete uninstall of Isaac Sim and Isaac Lab from Tower
# This removes ALL traces for a clean manual reinstall

set -e  # Exit on any error

echo "=========================================="
echo "COMPLETE ISAAC SIM + ISAAC LAB UNINSTALL"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will remove:"
echo "   - Isaac Sim pip installation"
echo "   - Isaac Lab git repository"
echo "   - Conda environment: env_isaaclab"
echo "   - All cached files and configs"
echo ""
read -p "Are you sure you want to proceed? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "Starting complete uninstall..."
echo ""

# Step 1: Deactivate conda if active
echo "Step 1/8: Deactivating conda environment..."
if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    echo "  Deactivating: $CONDA_DEFAULT_ENV"
    conda deactivate 2>/dev/null || true
fi

# Step 2: Remove conda environment
echo ""
echo "Step 2/8: Removing conda environment 'env_isaaclab'..."
if conda env list | grep -q "env_isaaclab"; then
    echo "  Found env_isaaclab, removing..."
    conda env remove -n env_isaaclab -y
    echo "  ✅ Conda environment removed"
else
    echo "  ℹ️  Conda environment not found (already removed)"
fi

# Step 3: Remove Isaac Lab repository
echo ""
echo "Step 3/8: Removing Isaac Lab repository..."
ISAAC_LAB_PATH="${HOME}/workspace/go2_omniverse/_isaac_sim/_isaac_lab"
if [[ -d "$ISAAC_LAB_PATH" ]]; then
    echo "  Removing: $ISAAC_LAB_PATH"
    rm -rf "$ISAAC_LAB_PATH"
    echo "  ✅ Isaac Lab repository removed"
else
    echo "  ℹ️  Isaac Lab directory not found (already removed)"
fi

# Step 4: Remove Isaac Sim _isaac_sim directory
echo ""
echo "Step 4/8: Removing _isaac_sim directory..."
ISAAC_SIM_PATH="${HOME}/workspace/go2_omniverse/_isaac_sim"
if [[ -d "$ISAAC_SIM_PATH" ]]; then
    echo "  Removing: $ISAAC_SIM_PATH"
    rm -rf "$ISAAC_SIM_PATH"
    echo "  ✅ _isaac_sim directory removed"
else
    echo "  ℹ️  _isaac_sim directory not found (already removed)"
fi

# Step 5: Remove pip-installed Isaac Sim packages
echo ""
echo "Step 5/8: Cleaning pip-installed Isaac Sim packages..."
if command -v pip &> /dev/null; then
    echo "  Uninstalling isaacsim packages..."
    pip uninstall -y isaacsim 2>/dev/null || echo "  ℹ️  isaacsim not found in pip"
    pip uninstall -y isaacsim-rl 2>/dev/null || echo "  ℹ️  isaacsim-rl not found in pip"
    pip uninstall -y isaacsim-replicator 2>/dev/null || echo "  ℹ️  isaacsim-replicator not found in pip"
    pip uninstall -y isaacsim-extscache-physics 2>/dev/null || echo "  ℹ️  isaacsim-extscache-physics not found in pip"
    pip uninstall -y isaacsim-extscache-kit 2>/dev/null || echo "  ℹ️  isaacsim-extscache-kit not found in pip"
    echo "  ✅ Pip packages cleaned"
else
    echo "  ℹ️  pip not available (conda env already removed)"
fi

# Step 6: Remove Isaac Sim cache directories
echo ""
echo "Step 6/8: Removing Isaac Sim cache directories..."
CACHE_DIRS=(
    "${HOME}/.cache/ov"
    "${HOME}/.cache/pip"
    "${HOME}/.local/share/ov"
    "${HOME}/.nvidia-omniverse"
    "${HOME}/.nv"
)

for cache_dir in "${CACHE_DIRS[@]}"; do
    if [[ -d "$cache_dir" ]]; then
        echo "  Removing: $cache_dir"
        rm -rf "$cache_dir"
    fi
done
echo "  ✅ Cache directories cleaned"

# Step 7: Remove Isaac Sim config files
echo ""
echo "Step 7/8: Removing Isaac Sim config files..."
CONFIG_FILES=(
    "${HOME}/.local/share/ov/data"
    "${HOME}/.local/share/ov/logs"
)

for config_file in "${CONFIG_FILES[@]}"; do
    if [[ -e "$config_file" ]]; then
        echo "  Removing: $config_file"
        rm -rf "$config_file"
    fi
done
echo "  ✅ Config files cleaned"

# Step 8: Clean Python cache files
echo ""
echo "Step 8/8: Cleaning Python cache files..."
PYTHON_CACHE_DIRS=(
    "${HOME}/workspace/go2_omniverse/__pycache__"
    "${HOME}/workspace/go2_omniverse/**/__pycache__"
)

for cache_pattern in "${PYTHON_CACHE_DIRS[@]}"; do
    find "${HOME}/workspace/go2_omniverse" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "${HOME}/workspace/go2_omniverse" -type f -name "*.pyc" -delete 2>/dev/null || true
done
echo "  ✅ Python cache cleaned"

echo ""
echo "=========================================="
echo "✅ COMPLETE UNINSTALL FINISHED"
echo "=========================================="
echo ""
echo "What was removed:"
echo "  ✓ Conda environment: env_isaaclab"
echo "  ✓ Isaac Lab repository: ~/workspace/go2_omniverse/_isaac_sim/_isaac_lab"
echo "  ✓ Isaac Sim directory: ~/workspace/go2_omniverse/_isaac_sim"
echo "  ✓ Pip-installed Isaac Sim packages"
echo "  ✓ Cache directories (~/.cache/ov, ~/.nvidia-omniverse, etc.)"
echo "  ✓ Config files"
echo "  ✓ Python cache files"
echo ""
echo "Your system is now clean for manual installation."
echo ""
echo "📋 NEXT STEPS FOR MANUAL INSTALLATION:"
echo ""
echo "Option A: Isaac Sim 5.0 + Official Go2 (Recommended)"
echo "==========================================="
echo "1. Install Isaac Sim 5.0:"
echo "   pip install isaacsim==5.0.0"
echo ""
echo "2. Install Isaac Lab 2.2.1:"
echo "   cd ~/workspace/go2_omniverse"
echo "   git clone https://github.com/isaac-sim/IsaacLab.git _isaac_sim/_isaac_lab"
echo "   cd _isaac_sim/_isaac_lab"
echo "   git checkout v2.2.1"
echo "   ./isaaclab.sh --install"
echo ""
echo "3. Load official Go2 asset:"
echo "   assets_root_path + '/Isaac/Robots/Unitree/Go2/go2.usd'"
echo ""
echo "Option B: Isaac Sim 4.5.0 + Isaac Lab 2.1.0 (Current)"
echo "==========================================="
echo "1. Install Isaac Sim 4.5.0:"
echo "   pip install isaacsim==4.5.0"
echo ""
echo "2. Install Isaac Lab 2.1.0:"
echo "   cd ~/workspace/go2_omniverse"
echo "   git clone https://github.com/isaac-sim/IsaacLab.git _isaac_sim/_isaac_lab"
echo "   cd _isaac_sim/_isaac_lab"
echo "   git checkout v2.1.0"
echo "   ./isaaclab.sh --install"
echo ""
echo "3. Use go2_omniverse repo as before"
echo ""
echo "📄 See NVIDIA_GO2_SUPPORT_FINDINGS.md for detailed comparison."
echo ""
