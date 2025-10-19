#!/bin/bash
# Quick laptop sync commands - copy/paste into laptop terminal

# OPTION 1: Automated Script (Recommended)
cd /home/daniel/shadowhound
curl -o /tmp/sync.sh https://raw.githubusercontent.com/danmartinez78/shadowhound/feature/local-llm-support/scripts/laptop_sync_submodules.sh
bash /tmp/sync.sh

# OPTION 2: Manual Commands
cd /home/daniel/shadowhound

# Pull conversion
git checkout feature/local-llm-support
git pull origin feature/local-llm-support

# Discard any local DIMOS changes (per submodule policy)
cd src/dimos-unitree
git reset --hard HEAD
git clean -fd
cd ../..

# Initialize submodules
git submodule sync
git submodule update --init --recursive

# Verify Go2 SDK packages
ls src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk/
# Should see: go2_interfaces, unitree_go, go2_robot_sdk, etc.

# Install embeddings dependencies
pip install chromadb langchain-chroma sentence-transformers

# Clean build
rm -rf build/ install/ log/

# Build and test
./start.sh
