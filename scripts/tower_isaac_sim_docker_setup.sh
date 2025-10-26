#!/bin/bash
# Complete Docker-based Isaac Sim Setup for Fresh Ubuntu
# Installs: NVIDIA Driver 580 + Docker + NVIDIA Container Toolkit + Isaac Sim Container
# Run on Tower/fresh Ubuntu: bash ~/shadowhound/scripts/tower_isaac_sim_docker_setup.sh

set -euo pipefail

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

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$HOME/.isaac_sim_docker_setup.log"
MARKER_DIR="$HOME/.isaac_sim_docker_state"
mkdir -p "$MARKER_DIR"

# Logging
run() { echo "+ $*" | tee -a "$LOG_FILE"; "$@" >> "$LOG_FILE" 2>&1; }

echo ""
say "╔════════════════════════════════════════════════════════════════╗"
say "║  Isaac Sim Docker Setup (Complete)                            ║"
say "║  Fresh Ubuntu 22.04 → Running Isaac Sim Container             ║"
say "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check OS
if ! grep -q "Ubuntu 22.04" /etc/os-release 2>/dev/null; then
    warn "This script is designed for Ubuntu 22.04"
    warn "Detected: $(lsb_release -ds 2>/dev/null || echo 'Unknown OS')"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

# ============================================================================
# Phase 1: System Prerequisites
# ============================================================================

install_prerequisites() {
    if [[ -f "$MARKER_DIR/prerequisites_installed" ]]; then
        ok "Prerequisites already installed - skipping"
        return 0
    fi
    
    say "\n=== Phase 1: System Prerequisites ==="
    
    say "Updating package lists..."
    run sudo apt-get update
    
    say "Installing essential packages..."
    run sudo apt-get install -y \
        curl wget git \
        build-essential \
        lsb-release \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg
    
    ok "Prerequisites installed"
    touch "$MARKER_DIR/prerequisites_installed"
}

# ============================================================================
# Phase 2: NVIDIA Driver 580
# ============================================================================

install_nvidia_driver() {
    if [[ -f "$MARKER_DIR/nvidia_driver_installed" ]]; then
        ok "NVIDIA driver already checked - skipping"
        return 0
    fi
    
    say "\n=== Phase 2: NVIDIA Driver 580 ==="
    
    # Check if driver already present
    if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
        local version
        version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 || echo "")
        
        if [[ -n "$version" ]]; then
            local major
            major=$(echo "$version" | cut -d. -f1)
            
            if [[ "$major" -ge 580 ]]; then
                ok "NVIDIA driver $version already installed (>= 580)"
                touch "$MARKER_DIR/nvidia_driver_installed"
                return 0
            else
                warn "NVIDIA driver $version detected (need >= 580)"
                warn "Will upgrade to driver 580..."
            fi
        fi
    else
        say "No NVIDIA driver detected. Installing driver 580..."
    fi
    
    # Install driver 580
    run sudo apt-get update
    run sudo apt-get install -y nvidia-driver-580
    
    touch "$MARKER_DIR/nvidia_driver_installed"
    
    warn "╔════════════════════════════════════════════════════════════════╗"
    warn "║  NVIDIA DRIVER INSTALLED - REBOOT REQUIRED                     ║"
    warn "╚════════════════════════════════════════════════════════════════╝"
    warn ""
    warn "Driver 580 has been installed but requires a reboot to activate."
    warn ""
    warn "After reboot, verify with: nvidia-smi"
    warn "Then re-run this script: bash $0"
    warn ""
    
    read -p "Reboot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        say "Rebooting in 5 seconds... (Ctrl+C to cancel)"
        sleep 5
        sudo reboot
    else
        say "Please reboot manually and re-run this script"
        exit 0
    fi
}

# ============================================================================
# Phase 3: Docker Engine
# ============================================================================

install_docker() {
    if [[ -f "$MARKER_DIR/docker_installed" ]]; then
        ok "Docker already installed - skipping"
        return 0
    fi
    
    say "\n=== Phase 3: Docker Engine ==="
    
    # Check if Docker already installed
    if command -v docker &>/dev/null; then
        ok "Docker already installed"
        
        # Add user to docker group if not already
        if ! groups | grep -q docker; then
            say "Adding user to docker group..."
            run sudo usermod -aG docker "$USER"
            warn "Docker group added. Log out and log back in for group to take effect."
            warn "Or run: newgrp docker"
        fi
        
        touch "$MARKER_DIR/docker_installed"
        return 0
    fi
    
    say "Installing Docker from official repository..."
    
    # Add Docker GPG key
    run curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    run sudo apt-get update
    run sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    run sudo usermod -aG docker "$USER"
    
    # Start and enable Docker
    run sudo systemctl start docker
    run sudo systemctl enable docker
    
    ok "Docker installed"
    touch "$MARKER_DIR/docker_installed"
    
    # Check if docker group is active
    if ! groups | grep -q docker; then
        warn "╔════════════════════════════════════════════════════════════════╗"
        warn "║  DOCKER GROUP MEMBERSHIP - SESSION REFRESH REQUIRED           ║"
        warn "╚════════════════════════════════════════════════════════════════╝"
        warn ""
        warn "Docker installed and user added to 'docker' group."
        warn "However, group membership requires session refresh."
        warn ""
        warn "OPTION 1 (Recommended): Log out and log back in"
        warn "  Then re-run: bash $0"
        warn ""
        warn "OPTION 2: Use newgrp in current session"
        warn "  Run: newgrp docker"
        warn "  Then re-run: bash $0"
        warn ""
        exit 0
    fi
}

# ============================================================================
# Phase 4: NVIDIA Container Toolkit
# ============================================================================

install_nvidia_container_toolkit() {
    if [[ -f "$MARKER_DIR/nvidia_toolkit_installed" ]]; then
        ok "NVIDIA Container Toolkit already installed - skipping"
        return 0
    fi
    
    say "\n=== Phase 4: NVIDIA Container Toolkit ==="
    
    # Add NVIDIA Container Toolkit repository
    say "Adding NVIDIA Container Toolkit repository..."
    run curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
    
    # Install toolkit
    run sudo apt-get update
    run sudo apt-get install -y nvidia-container-toolkit
    
    # Configure Docker to use NVIDIA runtime
    run sudo nvidia-ctk runtime configure --runtime=docker
    
    # Restart Docker
    run sudo systemctl restart docker
    
    ok "NVIDIA Container Toolkit installed"
    touch "$MARKER_DIR/nvidia_toolkit_installed"
    
    # Test GPU access
    say "Testing GPU access in container..."
    if docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi &>/dev/null; then
        ok "GPU accessible in containers!"
    else
        err "GPU test failed. Check: docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi"
    fi
}

# ============================================================================
# Phase 5: Isaac Sim Container
# ============================================================================

pull_isaac_sim_container() {
    if [[ -f "$MARKER_DIR/isaac_sim_pulled" ]]; then
        ok "Isaac Sim container already pulled - skipping"
        return 0
    fi
    
    say "\n=== Phase 5: Isaac Sim Container ==="
    
    say "Pulling Isaac Sim 4.5.0 container..."
    say "⏱️  This is a ~25GB download and may take 15-30 minutes..."
    echo ""
    
    # Pull with progress
    if docker pull nvcr.io/nvidia/isaac-sim:4.5.0; then
        ok "Isaac Sim container pulled successfully"
        touch "$MARKER_DIR/isaac_sim_pulled"
    else
        err "Failed to pull Isaac Sim container"
    fi
    
    # Verify image
    say "Verifying container..."
    if docker images | grep -q "nvidia/isaac-sim.*4.5.0"; then
        ok "Container image verified"
    else
        err "Container image not found in docker images"
    fi
}

# ============================================================================
# Phase 6: Helper Scripts & Configuration
# ============================================================================

create_helper_scripts() {
    say "\n=== Phase 6: Helper Scripts & Configuration ==="
    
    # Create bin directory
    mkdir -p "$HOME/bin"
    
    # Create isaacsim-docker launcher
    cat > "$HOME/bin/isaacsim-docker" <<'BASH'
#!/bin/bash
# Launch Isaac Sim 4.5.0 in Docker container
# Usage: isaacsim-docker [command]

# Enable X11 forwarding
xhost +local:docker 2>/dev/null || true

# Build volume mounts
VOLUMES=(
  "-v /tmp/.X11-unix:/tmp/.X11-unix:ro"
)

# Mount workspaces if they exist
[ -d "$HOME/workspace/go2_omniverse" ] && \
  VOLUMES+=("-v $HOME/workspace/go2_omniverse:/workspace/go2_omniverse:rw")

[ -d "$HOME/workspace/isaac_lab" ] && \
  VOLUMES+=("-v $HOME/workspace/isaac_lab:/isaac-sim/isaac_lab:rw")

[ -d "$HOME/workspace/shadowhound" ] && \
  VOLUMES+=("-v $HOME/workspace/shadowhound:/workspace/shadowhound:ro")

# Run container
docker run --rm -it \
  --gpus all \
  --network host \
  --ipc host \
  -e DISPLAY="${DISPLAY:-:0}" \
  -e ACCEPT_EULA=Y \
  -e PRIVACY_CONSENT=Y \
  "${VOLUMES[@]}" \
  nvcr.io/nvidia/isaac-sim:4.5.0 \
  "$@"
BASH
    
    chmod +x "$HOME/bin/isaacsim-docker"
    ok "Created: ~/bin/isaacsim-docker"
    
    # Create docker-compose file for Isaac Sim (optional, for systemd)
    local isaac_dir="$HOME/.isaac-sim-docker"
    mkdir -p "$isaac_dir"
    
    cat > "$isaac_dir/docker-compose.yml" <<YAML
# Isaac Sim Docker Compose Configuration
# Launch with: cd ~/.isaac-sim-docker && docker compose up
version: '3.8'

services:
  isaac-sim:
    image: nvcr.io/nvidia/isaac-sim:4.5.0
    container_name: isaac-sim
    runtime: nvidia
    stdin_open: true
    tty: true
    network_mode: host
    ipc: host
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
      - DISPLAY=\${DISPLAY:-:0}
      - ACCEPT_EULA=Y
      - PRIVACY_CONSENT=Y
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:ro
      - \${HOME}/workspace/go2_omniverse:/workspace/go2_omniverse:rw
      - \${HOME}/workspace/isaac_lab:/isaac-sim/isaac_lab:rw
      - isaac-sim-cache:/root/.cache
      - isaac-sim-data:/root/.local/share/ov/data
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

volumes:
  isaac-sim-cache:
  isaac-sim-data:
YAML
    
    ok "Created: ~/.isaac-sim-docker/docker-compose.yml"
    
    # Add to PATH if needed
    if ! echo "$PATH" | grep -q "$HOME/bin"; then
        echo "" >> "$HOME/.bashrc"
        echo '# Add ~/bin to PATH for Isaac Sim Docker launcher' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        ok "Added ~/bin to PATH in ~/.bashrc"
        warn "Run 'source ~/.bashrc' or open new terminal for PATH to update"
    fi
}

# ============================================================================
# Phase 7: Validation Tests
# ============================================================================

run_validation_tests() {
    say "\n=== Phase 7: Validation Tests ==="
    
    # Test 1: GPU access
    say "Test 1: GPU access in container..."
    if docker run --rm --gpus all nvcr.io/nvidia/isaac-sim:4.5.0 nvidia-smi &>/dev/null; then
        ok "✓ GPU accessible"
    else
        err "✗ GPU test failed"
    fi
    
    # Test 2: Isaac Sim import
    say "Test 2: Isaac Sim Python import..."
    if docker run --rm --gpus all nvcr.io/nvidia/isaac-sim:4.5.0 \
        python -c "import isaacsim; print(f'Isaac Sim {isaacsim.__version__}')" &>/dev/null; then
        ok "✓ Isaac Sim imports successfully"
    else
        err "✗ Isaac Sim import failed"
    fi
    
    # Test 3: Helper script
    say "Test 3: Helper script..."
    if [ -x "$HOME/bin/isaacsim-docker" ]; then
        ok "✓ isaacsim-docker launcher ready"
    else
        warn "✗ isaacsim-docker not executable"
    fi
    
    ok "All validation tests passed!"
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    say "Starting installation at $(date)"
    say "Log file: $LOG_FILE"
    echo ""
    
    # Run phases
    install_prerequisites
    install_nvidia_driver
    install_docker
    install_nvidia_container_toolkit
    pull_isaac_sim_container
    create_helper_scripts
    run_validation_tests
    
    # Success summary
    echo ""
    say "╔════════════════════════════════════════════════════════════════╗"
    say "║  ✅ Installation Complete!                                     ║"
    say "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    ok "System configured:"
    echo "  ✓ NVIDIA Driver 580 installed"
    echo "  ✓ Docker Engine installed"
    echo "  ✓ NVIDIA Container Toolkit configured"
    echo "  ✓ Isaac Sim 4.5.0 container pulled"
    echo "  ✓ Helper scripts created"
    echo ""
    
    say "Quick Start:"
    echo ""
    echo "1. Launch Isaac Sim GUI:"
    echo "   isaacsim-docker"
    echo ""
    echo "2. Run Python script:"
    echo "   isaacsim-docker python your_script.py"
    echo ""
    echo "3. Test Isaac Sim import:"
    echo "   isaacsim-docker python -c 'import isaacsim; print(isaacsim.__version__)'"
    echo ""
    
    say "Next Steps:"
    echo ""
    echo "• Install Isaac Lab v2.1.0:"
    echo "  cd ~/workspace"
    echo "  git clone https://github.com/isaac-sim/IsaacLab.git isaac_lab"
    echo "  cd isaac_lab && git checkout v2.1.0"
    echo "  isaacsim-docker bash -c 'cd /isaac-sim/isaac_lab && ./isaaclab.sh --install'"
    echo ""
    echo "• Clone go2_omniverse:"
    echo "  cd ~/workspace"
    echo "  git clone --branch added_copter https://github.com/danmartinez78/go2_omniverse"
    echo ""
    echo "• Run Go2 simulation:"
    echo "  cd ~/workspace/go2_omniverse"
    echo "  isaacsim-docker python sim/go2_sim.py"
    echo ""
    
    say "Documentation:"
    echo "  ~/shadowhound/docs/deployment/isaac_sim_containerized_setup.md"
    echo ""
    
    say "Installed at: $(date)"
}

# Run main installation
main
