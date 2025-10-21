#!/bin/bash
# Setup script for ShadowHound development environment on laptop
# Run once: source setup_laptop_env.sh
# This adds the necessary environment variables to your ~/.bashrc

echo "Setting up ShadowHound environment on laptop..."

# Check if PyTorch is installed
TORCH_CMAKE_PATH=$(python3 -c "import torch; print(torch.utils.cmake_prefix_path)" 2>/dev/null)

if [ -z "$TORCH_CMAKE_PATH" ]; then
    echo "❌ PyTorch not found! Install with: pip install torch torchvision"
    exit 1
fi

echo "✓ PyTorch found at: $TORCH_CMAKE_PATH"

# Get TorchVision path
TORCHVISION_CMAKE_PATH=$(python3 -c "import torchvision; import os; print(os.path.dirname(torchvision.__file__) + '/share/cmake')" 2>/dev/null)

if [ -z "$TORCHVISION_CMAKE_PATH" ]; then
    echo "❌ TorchVision not found! Install with: pip install torchvision"
    exit 1
fi

echo "✓ TorchVision found at: $TORCHVISION_CMAKE_PATH"

# Add to bashrc
BASHRC_ENTRY="
# ShadowHound Development Environment
export CMAKE_PREFIX_PATH=$TORCH_CMAKE_PATH:$TORCHVISION_CMAKE_PATH:\$CMAKE_PREFIX_PATH
export ROS_DOMAIN_ID=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
alias cb='colcon build --symlink-install'
alias source-ws='source install/setup.bash'
"

if grep -q "ShadowHound Development Environment" ~/.bashrc; then
    echo "⚠️  Environment already configured in ~/.bashrc"
else
    echo "$BASHRC_ENTRY" >> ~/.bashrc
    echo "✓ Added to ~/.bashrc"
fi

echo ""
echo "Setup complete! Run: source ~/.bashrc"
echo "Then: cd ~/shadowhound && colcon build --symlink-install"
