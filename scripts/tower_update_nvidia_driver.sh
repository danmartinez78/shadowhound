#!/bin/bash
# Update NVIDIA driver on Tower to version 550 (latest stable)
# Run this on Tower: bash ~/shadowhound/scripts/tower_update_nvidia_driver.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

say() { echo -e "${BLUE}==>${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
say "🔧 NVIDIA Driver Update to 550 (Tower)"
echo ""

# Check we're on Tower (has GPU)
if ! command -v nvidia-smi &> /dev/null; then
    err "nvidia-smi not found. Is this the Tower machine?"
fi

# Show current driver
say "Current driver:"
nvidia-smi | grep "Driver Version" || err "Failed to get driver version"

# Confirm with user
echo ""
warn "This will:"
warn "  1. Update NVIDIA driver from 535.x to 550.x"
warn "  2. Require a system reboot"
warn "  3. Take about 5-10 minutes"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    say "Cancelled by user"
    exit 0
fi

# Update package list
say "Updating package lists..."
sudo apt update
ok "Package lists updated"

# Check available driver versions
say "Available NVIDIA drivers:"
apt-cache search nvidia-driver | grep "^nvidia-driver-[0-9]" | sort -V | tail -5

# Install driver 550
say "Installing nvidia-driver-550..."
sudo apt install -y nvidia-driver-550
ok "Driver 550 installed"

# Verify installation
say "Verifying installation..."
if dpkg -l | grep -q "nvidia-driver-550"; then
    ok "nvidia-driver-550 package installed"
else
    err "nvidia-driver-550 package not found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "Driver update complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
warn "⚠️  REBOOT REQUIRED to activate new driver"
echo ""
echo "To reboot now:"
echo "  sudo reboot"
echo ""
echo "After reboot, verify driver:"
echo "  nvidia-smi | grep 'Driver Version'"
echo "  # Should show: Driver Version: 550.xx"
echo ""
