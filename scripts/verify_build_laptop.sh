#!/bin/bash
# ============================================================================
# Build Verification Script for Laptop Host
# ============================================================================
# Run this on the laptop to verify full build:
#   cd ~/shadowhound
#   git pull origin dev
#   ./scripts/verify_build_laptop.sh
#
# This script will:
# 1. Pull latest changes from git
# 2. Update submodules
# 3. Clean build artifacts
# 4. Full rebuild
# 5. Report results
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}============================================================================${NC}"
    echo -e "${CYAN}  🚀 ShadowHound Build Verification (Laptop)${NC}"
    echo -e "${CYAN}============================================================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}── $1 ──────────────────────────────────────────────────────${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verify we're on laptop
print_header

if [ ! -d "/home/daniel/shadowhound" ]; then
    print_error "Not running on laptop! Expected /home/daniel/shadowhound"
    exit 1
fi

cd /home/daniel/shadowhound
print_success "Working directory: $(pwd)"

# Step 1: Git pull
print_section "Git Operations"
print_success "Current branch: $(git rev-parse --abbrev-ref HEAD)"
print_success "Latest commit: $(git log -1 --oneline)"

echo "Pulling latest changes..."
git pull origin dev
print_success "Git pull completed"

echo "Updating submodules..."
git submodule update --init --recursive
print_success "Submodules updated"

# Step 2: Check environment
print_section "Environment Check"

if command -v colcon &> /dev/null; then
    print_success "colcon found"
else
    print_error "colcon not found! Install: sudo apt install python3-colcon-common-extensions"
    exit 1
fi

if command -v python3 &> /dev/null; then
    python_version=$(python3 --version | cut -d' ' -f2)
    print_success "Python $python_version installed"
else
    print_error "Python3 not found"
    exit 1
fi

if [ -d "/opt/ros/humble" ]; then
    print_success "ROS2 Humble found"
else
    print_error "ROS2 Humble not found!"
    exit 1
fi

# Step 3: Clean build
print_section "Clean Build"

echo "Removing build artifacts..."
rm -rf build install log
print_success "Build artifacts cleaned"

# Step 4: Full build
print_section "Building Workspace"

echo "Building all packages..."
if colcon build --symlink-install 2>&1 | tee build_output.log; then
    print_success "Build completed successfully!"
else
    print_error "Build failed! Check build_output.log"
    exit 1
fi

# Step 5: Summary
print_section "Build Summary"

# Count packages
total_packages=$(find src -name "package.xml" | wc -l)
built_packages=$(grep -c "Finished" build_output.log || echo "0")

print_success "Total packages: $total_packages"
print_success "Successfully built: $built_packages"

# Check key packages
for pkg in shadowhound_mission_agent shadowhound_bringup shadowhound_skills; do
    if [ -d "install/$pkg" ]; then
        print_success "$pkg installed"
    else
        print_warning "$pkg NOT installed"
    fi
done

# Step 6: Final verification
print_section "Verification"

echo "Sourcing environment..."
source install/setup.bash

echo "Checking ROS2 packages..."
if ros2 pkg list | grep -q shadowhound_mission_agent; then
    print_success "shadowhound_mission_agent package found"
else
    print_warning "shadowhound_mission_agent not found in package list"
fi

print_section "✅ Build Verification Complete"

echo ""
echo "Next steps:"
echo "  1. Source environment: source install/setup.bash"
echo "  2. Test mission agent: ros2 launch shadowhound_mission_agent mission_agent.launch.py"
echo "  3. Check logs: cat build_output.log"
echo ""

exit 0
