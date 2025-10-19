#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Robot Simulation Stack Installer (Ubuntu 22.04)
# - Isaac Sim 4.5 (pip, with cached extensions) + Isaac Lab (source)
# - ROS 2 Humble
# - Data lake: MinIO (single-node, multi-drive via Docker Compose)
# - Local model repo: MLflow Server + PostgreSQL, artifacts in MinIO (S3)
# - HF/Transformers/Datasets cache pinned to data volume
# - Robust uninstall and doctor
# =============================================================================

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$HOME/.go2_stack_install.log"
MARKER_DIR="$HOME/.go2_stack_state"
BACKUP_DIR="$HOME/.go2_stack_backup"
mkdir -p "$MARKER_DIR" "$BACKUP_DIR"

CONDA_ROOT="${HOME}/miniconda3"
ENV_NAME="env_isaaclab"
PY_VER="3.10"

ISAACSIM_PIP_VERSION="4.5.0"
ISAACSIM_PIP_EXTRAS='[all,extscache]'   # cache Omniverse extensions for faster start
ROS_DISTRO="humble"

PROFILE_FILE="$HOME/.robot-simrc"      # source manually from ~/.bashrc after install
DATA_DIR_DEFAULT="/srv/robot-data"

MINIO_DIR=""                           # set during install
MINIO_COMPOSE_YAML=""                  # set during install

# Network configuration for Thor/Spark integration
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
MLFLOW_PORT=5001

# Minimum requirements
MIN_DISK_GB=100
MIN_RAM_GB=16
REQUIRED_PORTS=($MINIO_PORT $MINIO_CONSOLE_PORT $MLFLOW_PORT)

trap 'handle_error $? $LINENO' ERR

handle_error(){
  local exit_code=$1 line_no=$2
  echo -e "\033[31m[ERROR]\033[0m Install failed at line $line_no (exit code: $exit_code)" >&2
  echo "Check log: $LOG_FILE" >&2
  echo "To retry: bash $SCRIPT_NAME install" >&2
  exit "$exit_code"
}

say(){ echo -e "$*"; }
run(){ echo "+ $*" | tee -a "$LOG_FILE"; eval "$@" >>"$LOG_FILE" 2>&1; }
ok(){  echo -e "\033[32m[ok]\033[0m $*"; }
warn(){ echo -e "\033[33m[warn]\033[0m $*"; }
confirm(){ local p="${1:-Proceed?} [y/N]: "; read -r -p "$p" a || true; [[ "${a,,}" =~ ^y(es)?$ ]]; }

require_ubuntu_2204(){
  command -v lsb_release >/dev/null || run "sudo apt-get update && sudo apt-get install -y lsb-release"
  local d v; d="$(lsb_release -is || true)"; v="$(lsb_release -rs || true)"
  [[ "$d" == "Ubuntu" && "$v" == 22.04* ]] || { echo "Needs Ubuntu 22.04; found $d $v"; exit 1; }
}

preflight_checks(){
  say "\n=== PRE-FLIGHT CHECKS ==="
  local failed=0
  
  # OS version
  local d v; d="$(lsb_release -is 2>/dev/null || echo unknown)"; v="$(lsb_release -rs 2>/dev/null || echo unknown)"
  if [[ "$d" == "Ubuntu" && "$v" == 22.04* ]]; then
    ok "OS: Ubuntu 22.04"
  else
    warn "OS: $d $v (expected Ubuntu 22.04)"
    ((failed++))
  fi
  
  # RAM check
  local ram_gb; ram_gb=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
  if ((ram_gb >= MIN_RAM_GB)); then
    ok "RAM: ${ram_gb}GB (>= ${MIN_RAM_GB}GB)"
  else
    warn "RAM: ${ram_gb}GB (recommended: >= ${MIN_RAM_GB}GB)"
  fi
  
  # Disk space check (root and data directory)
  local avail_gb; avail_gb=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')
  if ((avail_gb >= MIN_DISK_GB)); then
    ok "Disk space /: ${avail_gb}GB available (>= ${MIN_DISK_GB}GB)"
  else
    warn "Disk space /: ${avail_gb}GB (recommended: >= ${MIN_DISK_GB}GB)"
    ((failed++))
  fi
  
  # Check data directory space if it's a different filesystem
  if [[ -e "${DATA_DIR_DEFAULT}" ]]; then
    local data_avail_gb; data_avail_gb=$(df -BG "${DATA_DIR_DEFAULT}" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G' || echo "$avail_gb")
    local data_mount; data_mount=$(df "${DATA_DIR_DEFAULT}" 2>/dev/null | tail -1 | awk '{print $6}' || echo "/")
    if [[ -n "$data_mount" && "$data_mount" != "/" ]]; then
      if ((data_avail_gb >= 150)); then
        ok "Data directory space: ${data_avail_gb}GB available (150GB+ recommended)"
      else
        warn "Data directory ${DATA_DIR_DEFAULT}: ${data_avail_gb}GB (150GB+ recommended for Isaac Sim caches)"
        ((failed++))
      fi
    fi
  else
    ok "Data directory ${DATA_DIR_DEFAULT} will be created during install"
  fi
  
  # NVIDIA GPU check
  if command -v nvidia-smi >/dev/null 2>&1; then
    local gpu_count; gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l || echo "0")
    ok "NVIDIA GPU: ${gpu_count} GPU(s) detected"
  else
    warn "NVIDIA GPU: nvidia-smi not found (will install driver)"
  fi
  
  # Port availability check
  for port in "${REQUIRED_PORTS[@]}"; do
    if ! sudo lsof -i ":$port" >/dev/null 2>&1; then
      ok "Port $port: available"
    else
      warn "Port $port: already in use"
      sudo lsof -i ":$port" | head -5
    fi
  done
  
  # Internet connectivity - try multiple methods
  local internet_ok=false
  
  # Method 1: curl to google.com (preferred)
  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL --connect-timeout 10 https://google.com >/dev/null 2>&1; then
      internet_ok=true
    fi
  fi
  
  # Method 2: wget fallback
  if [[ "$internet_ok" == "false" ]] && command -v wget >/dev/null 2>&1; then
    if wget -q --spider --timeout=10 https://google.com 2>/dev/null; then
      internet_ok=true
    fi
  fi
  
  # Method 3: DNS resolution test (minimal check)
  if [[ "$internet_ok" == "false" ]] && command -v getent >/dev/null 2>&1; then
    if getent hosts google.com >/dev/null 2>&1; then
      warn "Internet: DNS works but HTTPS connectivity failed (may be proxy/firewall)"
      # Don't fail - DNS working is enough for apt to work with local mirrors
      internet_ok=true
    fi
  fi
  
  if [[ "$internet_ok" == "true" ]]; then
    ok "Internet: connected"
  else
    warn "Internet: connectivity issue (required for downloads)"
    echo "     Troubleshoot: Check DNS (/etc/resolv.conf), firewall, or proxy settings"
    ((failed++))
  fi
  
  if ((failed > 0)); then
    warn "Found $failed critical issues. Proceed with caution."
    confirm "Continue anyway?" || exit 1
  else
    ok "All pre-flight checks passed"
  fi
  say "=== END PRE-FLIGHT CHECKS ===\n"
}

ensure_base_tools(){
  if [[ -f "$MARKER_DIR/base_tools_installed" ]]; then
    ok "Base tools already installed - skipping"
    return 0
  fi
  say "\n--- Installing Base System Tools ---"
  run "sudo apt-get update"
  # Essential build tools and utilities
  run "sudo apt-get install -y \
    curl wget git unzip zip jq \
    ca-certificates build-essential cmake pkg-config \
    apt-transport-https gnupg software-properties-common \
    lsb-release dmidecode pciutils usbutils \
    net-tools dnsutils iputils-ping \
    vim nano less tree \
    python3-pip python3-dev python3-venv"
  
  # Isaac Sim dependencies
  say "Installing Isaac Sim dependencies..."
  run "sudo apt-get install -y \
    libfuse2 \
    libglu1-mesa \
    libsm6 \
    libxi6 \
    libxrandr2 \
    libxxf86vm1 \
    libgl1-mesa-glx \
    libglew2.2 \
    libopengl0 \
    vulkan-tools \
    mesa-utils"
  
  ok "Base tools and Isaac Sim dependencies installed"
  touch "$MARKER_DIR/base_tools_installed"
}

install_dev_tools(){
  if [[ -f "$MARKER_DIR/dev_tools_installed" ]]; then
    ok "Dev tools already installed - skipping"
    return 0
  fi
  say "\n--- Development & Monitoring Tools ---"
  # System monitoring
  run "sudo apt-get install -y htop iotop nethogs ncdu"
  # GPU monitoring (nvtop for newer driver versions)
  if command -v nvidia-smi >/dev/null; then
    run "sudo apt-get install -y nvtop || warn 'nvtop unavailable (requires newer repos)'"
  fi
  # Python dev tools (in conda env)
  # shellcheck source=/dev/null
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
  run "conda run -n \"$ENV_NAME\" python -m pip install ipython jupyter tensorboard matplotlib seaborn pandas plotly"
  # S3/MinIO CLI tools
  run "sudo apt-get install -y s3cmd"
  run "curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.deb -o /tmp/rclone.deb && sudo dpkg -i /tmp/rclone.deb || warn 'rclone install failed'"
  # Network debugging
  run "sudo apt-get install -y nmap traceroute mtr dnsutils"
  # Container debugging
  run "sudo apt-get install -y docker-compose-plugin || true"
  ok "Dev tools installed (htop, nvtop, jupyter, tensorboard, s3cmd, rclone, etc.)"
  touch "$MARKER_DIR/dev_tools_installed"
}

install_driver_if_needed(){
  if [[ -f "$MARKER_DIR/nvidia_driver_checked" ]]; then
    ok "NVIDIA driver already checked - skipping"
    return 0
  fi
  say "\n--- NVIDIA Driver for Isaac Sim 4.5.0 ---"
  
  # Check Secure Boot status
  if command -v mokutil >/dev/null 2>&1; then
    if mokutil --sb-state 2>/dev/null | grep -qi "SecureBoot enabled"; then
      warn "╔════════════════════════════════════════════════════════════════╗"
      warn "║  SECURE BOOT IS ENABLED                                        ║"
      warn "╚════════════════════════════════════════════════════════════════╝"
      warn ""
      warn "Secure Boot requires signing NVIDIA kernel modules (MOK enrollment)"
      warn "This adds complexity and potential boot issues."
      warn ""
      warn "RECOMMENDED: Disable Secure Boot in BIOS for smoother installation"
      warn ""
      warn "To disable Secure Boot:"
      warn "  1. Reboot and press Del to enter BIOS"
      warn "  2. Go to Boot → Secure Boot → Disabled"
      warn "  3. Save and exit (F10)"
      warn ""
      confirm "Continue with Secure Boot enabled (not recommended)?" || exit 1
    fi
  fi
  
  # Get kernel version to determine required driver
  local kernel_ver; kernel_ver="$(uname -r)"
  local kernel_major; kernel_major="$(echo "$kernel_ver" | cut -d. -f1)"
  local kernel_minor; kernel_minor="$(echo "$kernel_ver" | cut -d. -f2)"
  local kernel_patch; kernel_patch="$(echo "$kernel_ver" | cut -d. -f3 | cut -d- -f1)"
  
  # Determine target driver version based on kernel
  # Ubuntu 22.04.5+ with kernel 6.8.0-48+ requires driver 535.216.01+
  # Using 535-server for long-term stability (5+ year support vs 1 year for regular)
  local target_driver="535"
  local target_driver_full="535-server"
  
  if [[ "$kernel_major" -eq 6 ]] && [[ "$kernel_minor" -eq 8 ]]; then
    say "Kernel 6.8.x detected - using driver 535-server (>= 535.216.01)"
  else
    say "Using driver 535-server for Isaac Sim 4.5.0 (long-term support branch)"
  fi
  
  # Check if nvidia-smi exists and can communicate with driver
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    local v; v="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 || echo "")"
    
    # Check if we got a valid version string
    if [[ -z "$v" ]] || [[ ! "$v" =~ ^[0-9]+\.[0-9]+ ]]; then
      say "nvidia-smi found but cannot communicate with driver"
      say "Driver may be installed but not loaded. Installing/reinstalling driver..."
      
      # Purge and reinstall
      run "sudo apt-get purge -y 'nvidia-*' 'libnvidia-*' || true"
      run "sudo apt-get autoremove -y"
      run "sudo apt-get autoclean"
      run "sudo apt-get update"
      run "sudo apt-get install -y nvidia-driver-$target_driver_full"
      
      touch "$MARKER_DIR/nvidia_driver_checked"
      warn "Driver $target_driver_full installed. REBOOT REQUIRED before continuing."
      warn "After reboot, verify with: nvidia-smi"
      warn "Expected driver version: 535.129.03 or higher"
      warn "Then re-run: bash $SCRIPT_NAME install"
      exit 0
    fi
    
    say "Detected driver: $v"
    
    # Extract version components
    local major; major="$(echo "$v" | cut -d. -f1)"
    local minor; minor="$(echo "$v" | cut -d. -f2)"
    
    # Isaac Sim 4.5.0 requires driver >= 535.129.03
    # Check if driver is sufficient
    local driver_ok=false
    
    if [[ "$major" -eq 535 ]] && [[ "$minor" -ge 129 ]]; then
      # 535.129+ is perfect
      driver_ok=true
    elif [[ "$major" -eq 545 ]]; then
      # 545.x also works
      driver_ok=true
    elif [[ "$major" -gt 545 ]]; then
      # Newer than 545 might work but not officially tested
      warn "Driver $v is newer than tested range (535.129-545.x)"
      warn "This may work but is not officially supported by Isaac Sim 4.5.0"
      driver_ok=true
    fi
    
    if [[ "$driver_ok" == "true" ]]; then
      ok "Driver $v is compatible with Isaac Sim 4.5.0"
      
      # Enable persistence mode for multi-GPU stability
      say "Enabling NVIDIA persistence mode..."
      sudo nvidia-smi -pm 1 >>"$LOG_FILE" 2>&1 || warn "Could not enable persistence mode (non-fatal)"
      
      touch "$MARKER_DIR/nvidia_driver_checked"
    else
      warn "Driver $v detected. Isaac Sim 4.5.0 REQUIRES driver >= 535.129.03"
      warn "Your driver ($v) is too old and will cause RTX verification failures."
      say "Installing correct driver version ($target_driver_full)..."
      
      # Purge existing NVIDIA drivers completely
      say "Removing existing NVIDIA drivers..."
      run "sudo apt-get purge -y 'nvidia-*' 'libnvidia-*' || true"
      run "sudo apt-get autoremove -y"
      run "sudo apt-get autoclean"
      
      # Install driver 535-server (should provide 535.129.03 or higher)
      run "sudo apt-get update"
      run "sudo apt-get install -y nvidia-driver-$target_driver_full"
      
      touch "$MARKER_DIR/nvidia_driver_checked"
      warn "Driver $target_driver_full installed. REBOOT REQUIRED before continuing."
      warn "After reboot, verify driver version with: nvidia-smi"
      warn "Expected driver version: 535.129.03 or higher"
      warn "Then re-run: bash $SCRIPT_NAME install"
      exit 0
    fi
  else
    say "No NVIDIA driver detected. Installing driver $target_driver_full..."
    run "sudo apt-get update"
    run "sudo apt-get install -y nvidia-driver-$target_driver_full"
    touch "$MARKER_DIR/nvidia_driver_checked"
    warn "Driver $target_driver_full installed. REBOOT REQUIRED before continuing."
    warn "After reboot, verify with: nvidia-smi"
    warn "Expected driver version: 535.129.03 or higher"
    warn "Then re-run: bash $SCRIPT_NAME install"
    exit 0
  fi
}

install_docker_nvidia(){
  if [[ -f "$MARKER_DIR/docker_nvidia_installed" ]]; then
    ok "Docker + NVIDIA toolkit already installed - skipping"
    return 0
  fi
  say "\n--- Docker + NVIDIA Container Toolkit ---"
  
  # Note: CUDA toolkit NOT needed - Isaac Sim pip package includes CUDA runtime
  say "Note: CUDA toolkit not required - Isaac Sim includes CUDA runtime"
  
  local docker_installed=0
  if ! command -v docker >/dev/null; then
    run "curl -fsSL https://get.docker.com -o /tmp/get-docker.sh"
    run "sh /tmp/get-docker.sh"
    run "sudo usermod -aG docker \"$USER\""
    docker_installed=1
  fi
  
  # Check if docker group is active in current session
  if ! id | grep -q docker; then
    if ((docker_installed)); then
      # Docker was just installed in this session
      warn "╔════════════════════════════════════════════════════════════════╗"
      warn "║  DOCKER GROUP MEMBERSHIP REQUIRES SESSION REFRESH              ║"
      warn "╚════════════════════════════════════════════════════════════════╝"
      warn ""
      warn "Docker has been installed and your user added to the 'docker' group."
      warn "However, group membership only takes effect after refreshing your session."
      warn ""
      warn "OPTION 1 (Recommended): Log out and log back in completely"
      warn "  1. Log out of Ubuntu desktop"
      warn "  2. Log back in"
      warn "  3. Open terminal and run: cd ~/shadowhound && ./scripts/sim_and_data_lake_setup.sh install"
      warn ""
      warn "OPTION 2 (Advanced): Use newgrp to refresh in current session"
      warn "  Run: newgrp docker"
      warn "  Then in the NEW shell: cd ~/shadowhound && ./scripts/sim_and_data_lake_setup.sh install"
      warn ""
      say "After refreshing your session, the installation will continue automatically."
      exit 0
    else
      # Docker was already installed but user somehow not in group
      warn "User '$USER' is not in 'docker' group."
      warn "Adding user to docker group..."
      run "sudo usermod -aG docker $USER"
      warn ""
      warn "Group membership added. Please log out and log back in, then re-run:"
      warn "  bash $SCRIPT_NAME install"
      exit 0
    fi
  fi
  
  run "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
  run "curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null"
  run "sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit"
  run "sudo nvidia-ctk runtime configure --runtime=docker || true"
  run "sudo systemctl restart docker"
  touch "$MARKER_DIR/docker_nvidia_installed"
}

install_miniconda(){
  say "\n--- Miniconda ---"
  if [[ ! -d "$CONDA_ROOT" ]]; then
    run "curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh"
    bash /tmp/miniconda.sh -b -p "$CONDA_ROOT" >>"$LOG_FILE" 2>&1
  fi
  # shell hook
  # shellcheck source=/dev/null
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
  conda config --set auto_activate_base false >>"$LOG_FILE" 2>&1 || true
  
  # Accept Anaconda Terms of Service (required for recent conda versions)
  say "Accepting Anaconda Terms of Service..."
  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main >>"$LOG_FILE" 2>&1 || true
  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r >>"$LOG_FILE" 2>&1 || true
}

create_env_and_install_isaacsim(){
  say "\n--- Isaac Sim 4.5 (pip) ---"
  say "⏱️  This may take 15-30 minutes (downloading ~30GB)..."
  # shellcheck source=/dev/null
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
  
  # Ensure conda ToS is accepted (belt and suspenders approach)
  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main >>"$LOG_FILE" 2>&1 || true
  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r >>"$LOG_FILE" 2>&1 || true
  
  conda env list | awk '{print $1}' | grep -q "^${ENV_NAME}\$" || run "conda create -y -n \"$ENV_NAME\" python=${PY_VER}"
  run "conda run -n \"$ENV_NAME\" python -V"

  export OMNI_KIT_ACCEPT_EULA=YES  # accept Omniverse EULA for non-interactive pip install

  say "Upgrading pip..."
  run "conda run -n \"$ENV_NAME\" python -m pip install --upgrade pip"
  
  say "Installing Isaac Sim (this is the long step - be patient)..."
  run "conda run -n \"$ENV_NAME\" python -m pip install --timeout 300 \"isaacsim${ISAACSIM_PIP_EXTRAS}==${ISAACSIM_PIP_VERSION}\" --extra-index-url https://pypi.nvidia.com"

  # Warm caches to data dir later; capture env site-packages for sensor patching
  local env_site
  env_site="$(conda run -n \"$ENV_NAME\" python -c 'import sys;print(next(p for p in sys.path if p.endswith(\"site-packages\")))' 2>/dev/null || true)"
  echo "$env_site" > "$MARKER_DIR/env_site.txt"
  ok "Isaac Sim installed successfully"
}

install_ros2_humble(){
  # Check if actually installed (marker file alone not sufficient)
  if [[ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]] && [[ -f "$MARKER_DIR/ros2_installed" ]]; then
    ok "ROS 2 Humble already installed - skipping"
    return 0
  fi
  say "\n--- ROS 2 Humble ---"
  run "sudo apt-get update"
  run "sudo apt-get install -y curl gnupg lsb-release"
  run "sudo mkdir -p /etc/apt/keyrings"
  run "curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | sudo gpg --dearmor -o /etc/apt/keyrings/ros-archive-keyring.gpg"
  run "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/ros2.list >/dev/null"
  run "sudo apt-get update && sudo apt-get install -y ros-${ROS_DISTRO}-desktop ros-dev-tools"
  touch "$MARKER_DIR/ros2_installed"
}

clone_isaaclab(){
  local ws="$HOME/workspace"; run "mkdir -p \"$ws\""
  
  # Check if Isaac Lab is actually installed (not just cloned)
  if [[ -f "$MARKER_DIR/isaac_lab_cloned" ]] && [[ -d "$ws/IsaacLab/_isaac_sim" ]]; then
    ok "Isaac Lab already installed - skipping"
    return 0
  fi
  
  say "\n--- Isaac Lab (source) ---"
  if [[ -d "$ws/IsaacLab/.git" ]]; then run "git -C \"$ws/IsaacLab\" pull --ff-only"
  else run "git clone https://github.com/isaac-sim/IsaacLab.git \"$ws/IsaacLab\""; fi
  
  # Install Isaac Lab extensions
  say "Installing Isaac Lab extensions (this may take 5-10 minutes)..."
  # shellcheck source=/dev/null
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
  run "conda run -n \"$ENV_NAME\" bash -lc 'cd \"$ws/IsaacLab\" && ./isaaclab.sh --install'"
  touch "$MARKER_DIR/isaac_lab_cloned"
}

clone_go2_omniverse_and_patch(){
  if [[ -f "$MARKER_DIR/go2_omniverse_cloned" ]]; then
    ok "go2_omniverse already cloned - skipping"
    return 0
  fi
  say "\n--- go2_omniverse (added_copter) ---"
  local ws="$HOME/workspace"; run "mkdir -p \"$ws\""
  if [[ -d "$ws/go2_omniverse/.git" ]]; then
    run "git -C \"$ws/go2_omniverse\" fetch && git -C \"$ws/go2_omniverse\" checkout added_copter && git -C \"$ws/go2_omniverse\" pull --ff-only"
  else
    run "git clone --branch added_copter https://github.com/abizovnuralem/go2_omniverse \"$ws/go2_omniverse\""
  fi
  # Initialize submodules (contains IsaacSim-ros_workspaces and go2_omniverse_ws)
  say "Initializing go2_omniverse submodules..."
  run "git -C \"$ws/go2_omniverse\" submodule update --init --recursive"
  ok "Submodules initialized"
  # Copy Unitree LiDAR config into Isaac Sim sensor configs if present
  local env_site; env_site="$(cat "$MARKER_DIR/env_site.txt" 2>/dev/null || true)"
  if [[ -n "$env_site" && -f "$ws/go2_omniverse/repifis/l1.json" ]]; then
    local target_path="$env_site/isaacsim/_isaac_sim/kit/shared/rtx_sensor/sensor_config/config_files/RTXS_Lidar.json"
    if [[ -d "$(dirname "$target_path")" ]]; then
      run "cp -f \"$ws/go2_omniverse/repifis/l1.json\" \"$target_path\""
      ok "LiDAR config patched: $target_path"
    else
      warn "LiDAR config target path not found (Isaac Sim structure may have changed): $(dirname "$target_path")"
    fi
  else
    warn "LiDAR config source not found or env_site unavailable. Sensor config NOT patched."
  fi
  touch "$MARKER_DIR/go2_omniverse_cloned"
}

build_go2_ros2_workspaces(){
  if [[ -f "$MARKER_DIR/go2_workspaces_built" ]]; then
    ok "go2_omniverse ROS2 workspaces already built - skipping"
    return 0
  fi
  
  say "\n--- Building go2_omniverse ROS2 Workspaces ---"
  
  local ws="$HOME/workspace/go2_omniverse"
  if [[ ! -d "$ws" ]]; then
    warn "go2_omniverse not found at $ws - skipping workspace build"
    return 0
  fi
  
  # Get conda environment path - try multiple methods
  local env_site
  env_site="$(cat "$MARKER_DIR/env_site.txt" 2>/dev/null || true)"
  
  # Fallback: detect conda environment path directly
  if [[ -z "$env_site" ]]; then
    say "Detecting conda environment path..."
    # Source conda and activate environment
    # shellcheck source=/dev/null
    source "$CONDA_ROOT/etc/profile.d/conda.sh" 2>/dev/null || true
    conda activate "$ENV_NAME" 2>/dev/null || true
    env_site="$(python -c 'import sys;print(next(p for p in sys.path if p.endswith("site-packages")))' 2>/dev/null || true)"
  fi
  
  if [[ -z "$env_site" ]]; then
    warn "Cannot determine conda environment path - skipping Go2 workspace build"
    warn "You can build manually later with: bash $SCRIPT_DIR/tower_setup_go2_sim.sh"
    return 0
  fi
  
  ok "Using conda environment: $env_site"
  
  # Install empy package (required for ROS2 message generation)
  # NOTE: ROS2 Humble requires empy 3.3.4 specifically (not latest 4.x)
  say "Installing Python package 'empy==3.3.4'..."
  "$env_site/../../bin/pip" install empy==3.3.4 >> "$LOG_FILE" 2>&1
  ok "empy 3.3.4 installed"
  
  # Initialize rosdep if not already done
  if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    say "Initializing rosdep..."
    run "sudo rosdep init"
    ok "rosdep initialized"
  else
    ok "rosdep already initialized"
  fi
  
  say "Updating rosdep database..."
  run "rosdep update"
  ok "rosdep updated"
  
  # Source ROS2 Humble
  if [[ -f /opt/ros/humble/setup.bash ]]; then
    # shellcheck disable=SC1091
    source /opt/ros/humble/setup.bash
  else
    warn "ROS2 Humble not found - workspace build may fail"
  fi
  
  # Build IsaacSim-ros_workspaces/humble_ws
  local isaac_ws="$ws/IsaacSim-ros_workspaces/humble_ws"
  if [[ -d "$isaac_ws/src" ]]; then
    say "Building IsaacSim ROS2 workspace..."
    cd "$isaac_ws" || return 1
    
    # Install dependencies
    rosdep install --from-paths src --ignore-src -r -y >> "$LOG_FILE" 2>&1 || true
    
    # Build workspace
    if colcon build --symlink-install >> "$LOG_FILE" 2>&1; then
      ok "IsaacSim ROS2 workspace built"
    else
      warn "IsaacSim workspace build had issues - check $LOG_FILE"
    fi
    
    # Source built workspace
    if [[ -f "$isaac_ws/install/setup.bash" ]]; then
      # shellcheck disable=SC1091
      source "$isaac_ws/install/setup.bash"
    fi
  else
    warn "IsaacSim workspace src not found at $isaac_ws/src"
  fi
  
  # Build go2_omniverse_ws
  local go2_ws="$ws/go2_omniverse_ws"
  if [[ -d "$go2_ws/src" ]]; then
    say "Building go2_omniverse workspace..."
    cd "$go2_ws" || return 1
    
    # Install dependencies
    rosdep install --from-paths src --ignore-src -r -y >> "$LOG_FILE" 2>&1 || true
    
    # Build workspace
    if colcon build --symlink-install >> "$LOG_FILE" 2>&1; then
      ok "go2_omniverse workspace built"
    else
      warn "go2_omniverse workspace build had issues - check $LOG_FILE"
    fi
    
    # Source built workspace
    if [[ -f "$go2_ws/install/setup.bash" ]]; then
      # shellcheck disable=SC1091
      source "$go2_ws/install/setup.bash"
    fi
  else
    warn "go2_omniverse workspace src not found at $go2_ws/src"
  fi
  
  # Return to original directory
  cd "$HOME" || return 1
  
  # Verify builds succeeded
  if [[ -f "$isaac_ws/install/setup.bash" ]] && [[ -f "$go2_ws/install/setup.bash" ]]; then
    ok "Both ROS2 workspaces built successfully"
    touch "$MARKER_DIR/go2_workspaces_built"
  else
    warn "One or more workspaces failed to build - simulation may not work"
    warn "Check build logs: /tmp/go2_build_isaac_ws.log and /tmp/go2_build_go2_ws.log"
  fi
}

pick_data_dir(){
  # Skip if data dir already configured
  if [[ -f "$MARKER_DIR/data_dir.txt" ]] && [[ -f "$MARKER_DIR/minio_dir.txt" ]]; then
    DATA_DIR=$(cat "$MARKER_DIR/data_dir.txt")
    MINIO_DIR=$(cat "$MARKER_DIR/minio_dir.txt")
    MINIO_COMPOSE_YAML="${MINIO_DIR}/docker-compose.yml"
    ok "Data directories already configured:"
    ok "  DATA_DIR:  $DATA_DIR"
    ok "  MINIO_DIR: $MINIO_DIR"
    return 0
  fi
  
  say "\n--- Base data directory for caches & configs ---"
  run "lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL || true"
  read -r -p "Path for base data directory [$DATA_DIR_DEFAULT]: " DATA_DIR
  DATA_DIR="${DATA_DIR:-$DATA_DIR_DEFAULT}"
  run "mkdir -p \"$DATA_DIR\""
  MINIO_DIR="${DATA_DIR}/minio"
  MINIO_COMPOSE_YAML="${MINIO_DIR}/docker-compose.yml"
  ok "Base data dir: $DATA_DIR"
  
  # Save state for reconfiguration commands
  echo "$DATA_DIR" > "$MARKER_DIR/data_dir.txt"
  echo "$MINIO_DIR" > "$MARKER_DIR/minio_dir.txt"
  chmod 600 "$MARKER_DIR/data_dir.txt" "$MARKER_DIR/minio_dir.txt"
}

pick_minio_drives(){
  # Skip if drives already selected
  if [[ -f "$MARKER_DIR/minio_drives.txt" ]] && [[ -s "$MARKER_DIR/minio_drives.txt" ]]; then
    local -a saved_drives
    mapfile -t saved_drives < "$MARKER_DIR/minio_drives.txt"
    ok "MinIO drives already selected (${#saved_drives[@]} drive(s)): ${saved_drives[*]}"
    return 0
  fi
  
  say "\n--- Select MinIO Storage Drives ---"
  say "Tip: Use >=4 drives of similar size for erasure-coded resilience."
  say ""
  
  # Detect all mounted directories with sufficient space
  local -a available_mounts=()
  local -a mount_sizes=()
  
  # Get all mount points with >10GB free space (excluding special mounts)
  while IFS= read -r line; do
    local mount size
    mount=$(echo "$line" | awk '{print $6}')
    size=$(echo "$line" | awk '{print $4}' | tr -d 'G')
    
    # Skip special mounts
    [[ "$mount" =~ ^/(dev|proc|sys|run|boot|snap) ]] && continue
    [[ "$mount" == "/" ]] && continue  # Skip root unless it's the only option
    [[ -z "$mount" ]] && continue
    
    # Check if writable and has >10GB
    if [[ -w "$mount" ]] && ((size > 10)); then
      available_mounts+=("$mount")
      mount_sizes+=("$size")
    fi
  done < <(df -BG | tail -n +2)
  
  # If no mounts found besides root, add root as option
  if ((${#available_mounts[@]} == 0)); then
    local root_size; root_size=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')
    available_mounts+=("/")
    mount_sizes+=("$root_size")
  fi
  
  # Display available mounts
  say "Available mounted directories:"
  say ""
  for i in "${!available_mounts[@]}"; do
    printf "  %d) %-30s (%sGB available)\n" $((i+1)) "${available_mounts[$i]}" "${mount_sizes[$i]}"
  done
  say ""
  say "  0) Custom path (manual entry)"
  say ""
  
  # Get user selection
  local selected_paths=()
  say "Select drives for MinIO storage (space-separated numbers, e.g., '1 2 3'):"
  say "Or press ENTER to use base data directory only."
  say ""
  read -r -p "Choice(s): " choices
  
  # Handle empty input
  if [[ -z "$choices" ]]; then
    warn "No drives selected. Using base data dir as single drive."
    selected_paths+=("${DATA_DIR}/lake")
    run "mkdir -p \"${DATA_DIR}/lake\""
  else
    # Parse choices
    for choice in $choices; do
      if [[ "$choice" == "0" ]]; then
        # Manual entry
        read -r -p "Enter custom path: " custom_path
        if [[ -n "$custom_path" ]]; then
          # Validate custom path
          if [[ ! -d "$custom_path" ]]; then
            warn "Not a directory: $custom_path (skipping)"
            continue
          fi
          if [[ ! -w "$custom_path" ]]; then
            warn "Not writable: $custom_path (skipping)"
            continue
          fi
          local space_gb; space_gb=$(df -BG "$custom_path" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G' || echo "0")
          ok "$custom_path: ${space_gb}GB available"
          selected_paths+=("$custom_path")
        fi
      elif [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#available_mounts[@]})); then
        # Valid numbered choice
        local idx=$((choice - 1))
        local path="${available_mounts[$idx]}"
        local size="${mount_sizes[$idx]}"
        ok "$path: ${size}GB available"
        selected_paths+=("$path")
      else
        warn "Invalid choice: $choice (skipping)"
      fi
    done
  fi
  
  # Fallback if no valid selections
  if ((${#selected_paths[@]} == 0)); then
    warn "No valid drives selected. Using base data dir as fallback."
    selected_paths+=("${DATA_DIR}/lake")
    run "mkdir -p \"${DATA_DIR}/lake\""
  fi
  
  # Save selections
  printf "%s\n" "${selected_paths[@]}" > "$MARKER_DIR/minio_drives.txt"
  ok "Drives selected: ${selected_paths[*]}"
}

compose_cmd(){
  if docker compose version >/dev/null 2>&1; then 
    echo "docker compose"
  elif command -v docker-compose >/dev/null && docker-compose version >/dev/null 2>&1; then 
    echo "docker-compose"
  else 
    echo "ERROR: Neither 'docker compose' (v2) nor 'docker-compose' (v1) found or functional" >&2
    echo "Install with: sudo apt-get install -y docker-compose-plugin" >&2
    exit 1
  fi
}

generate_minio_mlflow_compose(){
  say "\n--- Writing MinIO + MLflow docker-compose ---"
  
  # Check if already running successfully
  if docker ps --filter "name=minio" --filter "status=running" --format '{{.Names}}' 2>/dev/null | grep -q '^minio$' && \
     docker ps --filter "name=mlflow" --filter "status=running" --format '{{.Names}}' 2>/dev/null | grep -q '^mlflow$' && \
     curl -fsSL http://localhost:9000/minio/health/live >/dev/null 2>&1; then
    ok "MinIO + MLflow already running and healthy - skipping"
    return 0
  fi
  
  # Clean up any existing containers from previous installs
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qE '^(minio|mlflow|mlflow-db|mc-bootstrap)'; then
    warn "Found existing containers from previous install - cleaning up"
    if [[ -f "$MINIO_DIR/docker-compose.yml" ]]; then
      (cd "$MINIO_DIR" && docker compose down -v 2>/dev/null || docker-compose down -v 2>/dev/null || true)
    else
      # Remove containers manually if compose file doesn't exist
      docker rm -f minio mlflow mlflow-db 2>/dev/null || true
      docker rm -f minio-mc-bootstrap-1 mc-bootstrap 2>/dev/null || true
    fi
    ok "Cleaned up existing containers"
  fi
  
  local paths=() i=1 vlines="" dargs=""
  mapfile -t paths < "$MARKER_DIR/minio_drives.txt"
  run "mkdir -p \"$MINIO_DIR\" \"$MINIO_DIR/config\" \"$MINIO_DIR/data\" \"$DATA_DIR/mlflow\" \"$DATA_DIR/mlflow/pgdata\""
  
  # credentials - use simple fixed passwords for development
  # In production, users should change these via reconfigure-credentials command
  local MINIO_USER MINIO_PASS POSTGRES_PASSWORD
  MINIO_USER="minioadmin"
  MINIO_PASS="minioadmin123"
  POSTGRES_PASSWORD="mlflow123"
  
  # Write to .env file (used by Docker Compose)
  echo "MINIO_ROOT_USER=$MINIO_USER" > "$MINIO_DIR/.env"
  echo "MINIO_ROOT_PASSWORD=$MINIO_PASS" >> "$MINIO_DIR/.env"
  echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> "$MINIO_DIR/.env"
  run "chmod 600 \"$MINIO_DIR/.env\""
  # volumes + command args
  for p in "${paths[@]}"; do
    vlines+="      - \"$p:/data$i\"\n"
    dargs+=" /data$i"
    ((i++))
  done

  # MLflow Dockerfile (adds boto3 + psycopg2-binary)
  mkdir -p "$MINIO_DIR/mlflow"
  cat > "$MINIO_DIR/mlflow/Dockerfile" <<'DOCKER'
FROM ghcr.io/mlflow/mlflow:v3.4.0
RUN pip install --no-cache-dir boto3 psycopg2-binary
DOCKER

  # Compose file - use printf to properly expand \n in vlines
  cat > "$MINIO_COMPOSE_YAML" <<YAML
services:
  minio:
    image: minio/minio:latest
    container_name: minio
    restart: unless-stopped
    env_file: [.env]
    command: server --console-address ":9001"${dargs}
    volumes:
$(printf "%b" "$vlines")
    ports:
      - "9000:9000"
      - "9001:9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 5

  # one-shot bootstrap to create buckets
  mc-bootstrap:
    image: minio/mc:latest
    depends_on:
      minio:
        condition: service_healthy
    env_file: [.env]
    entrypoint: ["/bin/sh"]
    command:
      - -c
      - |
        mc alias set local http://minio:9000 \${MINIO_ROOT_USER} \${MINIO_ROOT_PASSWORD} &&
        mc mb -p local/models || true &&
        mc mb -p local/datasets || true &&
        mc mb -p local/logs || true &&
        mc mb -p local/mlflow || true &&
        mc anonymous set download local/models || true
    restart: "no"

  mlflow-db:
    image: postgres:15
    container_name: mlflow-db
    restart: unless-stopped
    env_file: [.env]
    environment:
      POSTGRES_USER: mlflow
      POSTGRES_DB: mlflow
    volumes:
      - ${DATA_DIR}/mlflow/pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL","pg_isready -U mlflow"]
      interval: 10s
      timeout: 5s
      retries: 10

  mlflow:
    build:
      context: ${MINIO_DIR}/mlflow
      dockerfile: Dockerfile
    container_name: mlflow
    restart: unless-stopped
    environment:
      MLFLOW_S3_ENDPOINT_URL: http://minio:9000
      AWS_ACCESS_KEY_ID: ${MINIO_USER}
      AWS_SECRET_ACCESS_KEY: ${MINIO_PASS}
    command:
      - sh
      - -c
      - |
        mlflow server --host 0.0.0.0 --port 5001 \
        --backend-store-uri postgresql+psycopg2://mlflow:\${POSTGRES_PASSWORD}@mlflow-db:5432/mlflow \
        --default-artifact-root s3://mlflow
    depends_on:
      mlflow-db:
        condition: service_healthy
      mc-bootstrap:
        condition: service_completed_successfully
    ports:
      - "5001:5001"
YAML

  local cmd; cmd="$(compose_cmd)"
  [[ -z "$cmd" ]] && { echo "docker compose not found"; exit 1; }
  (cd "$MINIO_DIR" && $cmd up -d --build)
  
  # Wait for services to be healthy
  say "Waiting for services to start (up to 60s)..."
  local retries=12 healthy=0
  for ((i=1; i<=retries; i++)); do
    say "  Attempt $i/$retries..."
    
    # Check containers are actually running
    if ! docker ps --filter "name=minio" --filter "status=running" --format '{{.Names}}' 2>/dev/null | grep -q '^minio$'; then
      warn "MinIO container not running. Check: docker logs minio"
      break
    fi
    
    if ! docker ps --filter "name=mlflow" --filter "status=running" --format '{{.Names}}' 2>/dev/null | grep -q '^mlflow$'; then
      warn "MLflow container not running. Check: docker logs mlflow"
      break
    fi
    
    # Check health endpoints
    if curl -fsSL http://localhost:9000/minio/health/live >/dev/null 2>&1 && \
       (curl -fsSL http://localhost:5001/health >/dev/null 2>&1 || curl -fsSL http://localhost:5001 >/dev/null 2>&1); then
      healthy=1; break
    fi
    sleep 5
  done
  
  if ((healthy)); then
    ok "MinIO ($MINIO_PORT/$MINIO_CONSOLE_PORT) + MLflow ($MLFLOW_PORT) are healthy"
  else
    warn "Services started but health checks incomplete."
    warn "Check status: docker ps"
    warn "Check logs: docker logs minio && docker logs mlflow"
  fi
  
  # Create human-readable credentials summary (gitignored)
  local creds_file="$MINIO_DIR/CREDENTIALS.txt"
  cat > "$creds_file" <<CREDS
# =============================================================================
# Robot Data Lake Credentials
# =============================================================================
# Generated: $(date)
# Location: $(hostname)
#
# ⚠️  SECURITY: This file contains sensitive credentials.
# ⚠️  Keep this file secure and NEVER commit to version control.
# ⚠️  Add to .gitignore if in a git repository.
# =============================================================================

MinIO S3 API:
  URL:       http://$(hostname -I | awk '{print $1}'):${MINIO_PORT}
  Console:   http://$(hostname -I | awk '{print $1}'):${MINIO_CONSOLE_PORT}
  User:      ${MINIO_USER}
  Password:  ${MINIO_PASS}

MLflow Tracking Server:
  URL:       http://$(hostname -I | awk '{print $1}'):${MLFLOW_PORT}
  (No authentication required)

PostgreSQL (MLflow Backend):
  Host:      localhost:5432
  Database:  mlflow
  User:      mlflow
  Password:  ${POSTGRES_PASSWORD}
  (Only accessible from Docker network)

AWS CLI Configuration:
  export AWS_ACCESS_KEY_ID="${MINIO_USER}"
  export AWS_SECRET_ACCESS_KEY="${MINIO_PASS}"
  export AWS_ENDPOINT_URL="http://localhost:${MINIO_PORT}"

Python boto3 Configuration:
  s3_client = boto3.client(
      's3',
      endpoint_url='http://localhost:${MINIO_PORT}',
      aws_access_key_id='${MINIO_USER}',
      aws_secret_access_key='${MINIO_PASS}'
  )

# =============================================================================
# Transfer these credentials to Thor/Spark:
# scp $MINIO_DIR/CREDENTIALS.txt thor:~/tower_credentials.txt
# scp $MINIO_DIR/CREDENTIALS.txt spark:~/tower_credentials.txt
# =============================================================================
CREDS
  run "chmod 600 \"$creds_file\""
  
  ok "Credentials saved:"
  ok "  - Docker Compose: $MINIO_DIR/.env"
  ok "  - Human-readable: $creds_file"
  
  # Backup credentials for recovery
  echo "$MINIO_USER:$MINIO_PASS:$POSTGRES_PASSWORD" > "$MARKER_DIR/credentials.txt"
  run "chmod 600 \"$MARKER_DIR/credentials.txt\""
}

link_caches_to_data_dir(){
  say "\n--- Redirecting caches to data dir ---"
  # Omniverse + GPU caches
  local ov_cache="${DATA_DIR}/ov_cache"
  run "mkdir -p \"$ov_cache/ov\" \"$ov_cache/GLCache\" \"$ov_cache/ComputeCache\""
  run "mkdir -p \"$HOME/.cache\" \"$HOME/.nv\" \"$HOME/.cache/nvidia\""
  [[ -e "$HOME/.cache/ov" ]] || run "ln -s \"$ov_cache/ov\" \"$HOME/.cache/ov\""
  [[ -e "$HOME/.cache/nvidia/GLCache" ]] || run "ln -s \"$ov_cache/GLCache\" \"$HOME/.cache/nvidia/GLCache\""
  [[ -e "$HOME/.nv/ComputeCache" ]] || run "ln -s \"$ov_cache/ComputeCache\" \"$HOME/.nv/ComputeCache\""
  # Hugging Face caches
  run "mkdir -p \"$DATA_DIR/hf-cache/transformers\" \"$DATA_DIR/hf-cache/datasets\" \"$DATA_DIR/hf-cache/hub\""
}

setup_systemd_services(){
  say "\n--- Systemd services for boot-time startup ---"
  
  # Create systemd service to start docker compose on boot
  local service_file="/etc/systemd/system/robot-datalake.service"
  sudo tee "$service_file" >/dev/null <<EOF
[Unit]
Description=Robot Data Lake (MinIO + MLflow)
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${MINIO_DIR}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=${USER}
Group=${USER}
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
EOF

  run "sudo systemctl daemon-reload"
  run "sudo systemctl enable robot-datalake.service"
  
  # Test that systemd service can start
  say "\nTesting systemd service..."
  if sudo systemctl start robot-datalake 2>>"$LOG_FILE"; then
    sleep 3
    if sudo systemctl is-active robot-datalake >/dev/null 2>&1; then
      ok "Systemd service tested successfully"
    else
      warn "Systemd service failed to start. Check: sudo systemctl status robot-datalake"
      warn "Continuing anyway (services may be running via docker compose)"
    fi
  else
    warn "Failed to start systemd service initially"
    warn "Check logs: sudo journalctl -u robot-datalake -n 50"
  fi
  
  ok "Systemd service created: robot-datalake.service (auto-starts on boot)"
  
  say "\nService commands:"
  say "  Start:   sudo systemctl start robot-datalake"
  say "  Stop:    sudo systemctl stop robot-datalake"
  say "  Status:  sudo systemctl status robot-datalake"
  say "  Logs:    sudo journalctl -u robot-datalake -f"
}

configure_dual_nic_if_available(){
  say "\n--- Dual NIC Configuration (if available) ---"
  
  # Detect available ethernet interfaces
  local nics=()
  mapfile -t nics < <(ip -o link show | awk -F': ' '$2 ~ /^(en|eth)/ {print $2}' | sort)
  
  if ((${#nics[@]} < 2)); then
    say "Single NIC detected: ${nics[0]:-none}"
    say "Skipping dual-NIC optimization"
    return 0
  fi
  
  say "Detected ${#nics[@]} ethernet interfaces: ${nics[*]}"
  say ""
  say "=== DUAL NIC OPTIMIZATION OPTIONS ==="
  say ""
  say "1. SEPARATE NETWORKS (Recommended for Robot Lab)"
  say "   - ${nics[0]}: Internet/Cloud (downloads, updates)"
  say "   - ${nics[1]}: Private Robot Network (Thor/Spark/Go2)"
  say "   Benefits: Traffic isolation, predictable bandwidth, security"
  say ""
  say "2. LINK AGGREGATION (Bonding)"
  say "   - Combines both NICs into single 2 Gbps interface"
  say "   Benefits: Higher bandwidth, automatic failover"
  say "   Requires: Managed switch with LACP (802.3ad) support"
  say ""
  say "3. SKIP (Manual configuration later)"
  say "   - Configure networking manually via /etc/netplan/"
  say ""
  
  read -r -p "Choose dual-NIC setup [1/2/3, default=3]: " nic_choice
  nic_choice="${nic_choice:-3}"
  
  case "$nic_choice" in
    1)
      configure_separate_networks "${nics[0]}" "${nics[1]}"
      ;;
    2)
      configure_bonding "${nics[0]}" "${nics[1]}"
      ;;
    3)
      say "Skipping automatic dual-NIC configuration"
      ok "Configure manually later in /etc/netplan/"
      ;;
    *)
      warn "Invalid choice. Skipping dual-NIC configuration"
      ;;
  esac
}

configure_separate_networks(){
  local nic_internet="$1"
  local nic_robot="$2"
  
  say "\n--- Configuring Separate Networks ---"
  say "Internet NIC: $nic_internet (DHCP)"
  say "Robot NIC: $nic_robot (Static 192.168.10.100/24)"
  
  # Backup existing netplan config
  run "sudo mkdir -p /etc/netplan.backup"
  run "sudo cp -a /etc/netplan/*.yaml /etc/netplan.backup/ 2>/dev/null || true"
  
  # Get current robot network IP (if any)
  local robot_ip
  robot_ip=$(ip -4 addr show dev "$nic_robot" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1 || echo "192.168.10.100")
  
  read -r -p "Robot network static IP [$robot_ip]: " input_ip
  robot_ip="${input_ip:-$robot_ip}"
  
  # Create netplan configuration
  local netplan_file="/etc/netplan/01-robot-dual-nic.yaml"
  sudo tee "$netplan_file" >/dev/null <<EOF
# Robot Lab Dual-NIC Configuration (generated by $SCRIPT_NAME)
# Backup: /etc/netplan.backup/
network:
  version: 2
  renderer: networkd
  ethernets:
    $nic_internet:
      dhcp4: true
      dhcp6: false
      optional: true
      # Used for: Internet access, cloud services, software updates
    
    $nic_robot:
      dhcp4: false
      dhcp6: false
      addresses:
        - $robot_ip/24
      mtu: 9000  # Jumbo frames for high throughput (ensure switch supports)
      optional: true
      # Used for: Thor/Spark/Go2 robot network (high-bandwidth, low-latency)
      # Subnet: 192.168.10.0/24
EOF
  
  run "sudo chmod 600 \"$netplan_file\""
  
  ok "Netplan configuration created: $netplan_file"
  say ""
  say "⚠️  IMPORTANT: Review configuration before applying!"
  say "    cat $netplan_file"
  say ""
  say "To apply (will disconnect temporarily):"
  say "    sudo netplan apply"
  say ""
  say "To test (auto-reverts in 120s if connection lost):"
  say "    sudo netplan try --timeout 120"
  say ""
  say "To rollback if needed:"
  say "    sudo cp /etc/netplan.backup/*.yaml /etc/netplan/"
  say "    sudo netplan apply"
  
  # Save robot network IP for service binding
  echo "$robot_ip" > "$MARKER_DIR/robot_network_ip.txt"
  
  confirm "Apply netplan configuration now?" || { warn "Skipped. Apply manually later."; return 0; }
  
  say "Applying netplan configuration..."
  if sudo netplan apply 2>>"$LOG_FILE"; then
    sleep 3
    ok "Network configuration applied successfully"
    ok "Robot network: $nic_robot @ $robot_ip (MTU 9000)"
    ok "Internet: $nic_internet (DHCP)"
  else
    warn "Failed to apply netplan configuration"
    warn "Check logs: sudo journalctl -xe"
    warn "Rollback: sudo cp /etc/netplan.backup/*.yaml /etc/netplan/ && sudo netplan apply"
  fi
}

configure_bonding(){
  local nic1="$1"
  local nic2="$2"
  
  say "\n--- Configuring Link Aggregation (LACP Bonding) ---"
  say "⚠️  Requirements:"
  say "    - Managed switch with LACP (802.3ad) support"
  say "    - Both ports connected to same switch"
  say "    - Switch ports configured for LACP"
  say ""
  
  confirm "Switch is configured for LACP?" || { warn "Configure switch first. Skipping bonding."; return 1; }
  
  # Backup existing netplan config
  run "sudo mkdir -p /etc/netplan.backup"
  run "sudo cp -a /etc/netplan/*.yaml /etc/netplan.backup/ 2>/dev/null || true"
  
  # Get IP configuration
  local bond_ip
  bond_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1 || echo "192.168.10.100")
  
  read -r -p "Bonded interface IP [$bond_ip]: " input_ip
  bond_ip="${input_ip:-$bond_ip}"
  
  # Create netplan configuration for bonding
  local netplan_file="/etc/netplan/01-robot-bonding.yaml"
  sudo tee "$netplan_file" >/dev/null <<EOF
# Robot Lab LACP Bonding Configuration (generated by $SCRIPT_NAME)
# Backup: /etc/netplan.backup/
network:
  version: 2
  renderer: networkd
  ethernets:
    $nic1:
      dhcp4: false
      dhcp6: false
    $nic2:
      dhcp4: false
      dhcp6: false
  
  bonds:
    bond0:
      interfaces: [$nic1, $nic2]
      addresses:
        - $bond_ip/24
      mtu: 9000  # Jumbo frames
      parameters:
        mode: 802.3ad           # LACP
        lacp-rate: fast         # Fast LACP heartbeats (1/sec)
        mii-monitor-interval: 100  # Link monitoring
        transmit-hash-policy: layer3+4  # Load balance by IP+port
EOF
  
  run "sudo chmod 600 \"$netplan_file\""
  
  ok "Netplan bonding configuration created: $netplan_file"
  say ""
  say "⚠️  CRITICAL: This will disconnect network temporarily!"
  say "    Ensure you have console/KVM access before proceeding"
  say ""
  say "To apply:"
  say "    sudo netplan apply"
  say ""
  say "To test (auto-reverts in 120s if connection lost):"
  say "    sudo netplan try --timeout 120"
  say ""
  say "To verify bonding:"
  say "    cat /proc/net/bonding/bond0"
  say "    ip addr show bond0"
  
  # Save bonded IP
  echo "$bond_ip" > "$MARKER_DIR/robot_network_ip.txt"
  
  warn "NOT applying automatically - test manually with: sudo netplan try --timeout 120"
}

configure_firewall_for_network(){
  say "\n--- Firewall configuration for Thor/Spark access ---"
  
  # Check if ufw is installed and active
  if ! command -v ufw >/dev/null 2>&1; then
    run "sudo apt-get install -y ufw"
  fi
  
  local ufw_status; ufw_status=$(sudo ufw status | head -1 || echo "inactive")
  
  if [[ "$ufw_status" == *"inactive"* ]]; then
    say "UFW firewall is inactive. Configuring rules but not enabling automatically."
    say "(Enable manually with: sudo ufw enable)"
  fi
  
  # Allow SSH (critical - don't lock yourself out)
  run "sudo ufw allow 22/tcp comment 'SSH'"
  
  # Allow MinIO ports from local network
  run "sudo ufw allow from 192.168.0.0/16 to any port $MINIO_PORT proto tcp comment 'MinIO S3 API'"
  run "sudo ufw allow from 192.168.0.0/16 to any port $MINIO_CONSOLE_PORT proto tcp comment 'MinIO Console'"
  run "sudo ufw allow from 10.0.0.0/8 to any port $MINIO_PORT proto tcp comment 'MinIO S3 API'"
  run "sudo ufw allow from 10.0.0.0/8 to any port $MINIO_CONSOLE_PORT proto tcp comment 'MinIO Console'"
  
  # Allow MLflow from local network
  run "sudo ufw allow from 192.168.0.0/16 to any port $MLFLOW_PORT proto tcp comment 'MLflow Tracking'"
  run "sudo ufw allow from 10.0.0.0/8 to any port $MLFLOW_PORT proto tcp comment 'MLflow Tracking'"
  
  ok "Firewall rules configured for Thor/Spark access"
  say "Allowed networks: 192.168.0.0/16, 10.0.0.0/8"
  say "Ports: MinIO ($MINIO_PORT, $MINIO_CONSOLE_PORT), MLflow ($MLFLOW_PORT)"
  
  # Get local IP for connection info
  local tower_ip; tower_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1 || echo "unknown")
  if [[ "$tower_ip" != "unknown" ]]; then
    echo "$tower_ip" > "$MARKER_DIR/tower_ip.txt"
    ok "Tower IP: $tower_ip"
  fi
}

write_network_config_doc(){
  say "\n--- Writing network configuration guide ---"
  local tower_ip; tower_ip=$(cat "$MARKER_DIR/tower_ip.txt" 2>/dev/null || echo "TOWER_IP")
  
  cat > "$DATA_DIR/NETWORK_SETUP.md" <<EOF
# Network Configuration for Thor/Spark Integration

## Tower (Sim/Data Lake) Services

**Hostname**: $(hostname)
**IP Address**: $tower_ip

### Service Endpoints

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| MinIO S3 API | $MINIO_PORT | http://$tower_ip:$MINIO_PORT | Object storage API |
| MinIO Console | $MINIO_CONSOLE_PORT | http://$tower_ip:$MINIO_CONSOLE_PORT | Web UI |
| MLflow Tracking | $MLFLOW_PORT | http://$tower_ip:$MLFLOW_PORT | Experiment tracking |

### Credentials

**Human-readable**: \`$MINIO_DIR/CREDENTIALS.txt\` (complete with examples)
**Docker Compose**: \`$MINIO_DIR/.env\` (machine-readable)

⚠️ **IMPORTANT**: These files contain sensitive credentials. Keep them secure!

To view credentials:
\`\`\`bash
cat $MINIO_DIR/CREDENTIALS.txt
\`\`\`

To transfer to Thor/Spark:
\`\`\`bash
scp $MINIO_DIR/CREDENTIALS.txt thor:~/tower_credentials.txt
scp $MINIO_DIR/CREDENTIALS.txt spark:~/tower_credentials.txt
\`\`\`

## Thor/Spark Configuration

### Environment Variables (add to Thor/Spark)

\`\`\`bash
# MinIO/S3 configuration
export AWS_ACCESS_KEY_ID="<from Tower $MINIO_DIR/.env>"
export AWS_SECRET_ACCESS_KEY="<from Tower $MINIO_DIR/.env>"
export MLFLOW_S3_ENDPOINT_URL="http://$tower_ip:$MINIO_PORT"

# MLflow tracking
export MLFLOW_TRACKING_URI="http://$tower_ip:$MLFLOW_PORT"
\`\`\`

### Test Connectivity from Thor/Spark

\`\`\`bash
# Test MinIO health
curl http://$tower_ip:$MINIO_PORT/minio/health/live

# Test MLflow
curl http://$tower_ip:$MLFLOW_PORT/health

# Test S3 with aws-cli
aws --endpoint-url http://$tower_ip:$MINIO_PORT s3 ls

# Test with Python
python3 << 'PYEOF'
import boto3
s3 = boto3.client('s3',
    endpoint_url='http://$tower_ip:$MINIO_PORT',
    aws_access_key_id='<from Tower>',
    aws_secret_access_key='<from Tower>')
print(s3.list_buckets())
PYEOF
\`\`\`

### Network Requirements

- **Firewall**: Ports $MINIO_PORT, $MINIO_CONSOLE_PORT, $MLFLOW_PORT must be accessible
- **DNS/Hosts**: Add Tower hostname to /etc/hosts if needed
- **Latency**: Low-latency network recommended (same rack/switch)

## Dual NIC Configuration (if available)

Tower has dual ethernet ports. Three optimization strategies:

### Option 1: Separate Networks (Recommended)
\`\`\`
┌─────────────┐
│   Tower     │
│ eno1 (NIC1) ├──→ Internet/Cloud (downloads, updates)
│             │     192.168.1.x
│ enp14s0     ├──→ Private Robot Network (Thor/Spark/Go2)
│    (NIC2)   │     192.168.10.x (MTU 9000 for high throughput)
└─────────────┘
\`\`\`

**Benefits:**
- Isolates robot traffic from internet (security + predictable bandwidth)
- No bandwidth competition between downloads and live sensor data
- Can use jumbo frames (MTU 9000) on robot network
- Simple troubleshooting

**Configuration:** See \`/etc/netplan/01-robot-dual-nic.yaml\` (auto-generated by installer)

**Thor/Spark connects to:** $tower_ip:$MINIO_PORT (robot network NIC)

### Option 2: Link Aggregation (LACP Bonding)
Combines both NICs into single 2 Gbps interface with automatic failover.

**Requirements:** Managed switch with LACP (802.3ad) support

**Configuration:** See \`/etc/netplan/01-robot-bonding.yaml\` (generated by installer)

### Option 3: Manual Configuration
Edit \`/etc/netplan/*.yaml\` for custom configurations.

**Verify configuration:**
\`\`\`bash
# Show interfaces and IPs
ip addr show

# Test throughput between Tower and Thor
# Tower: iperf3 -s
# Thor:  iperf3 -c <tower_ip> -t 30 -P 4

# Monitor network usage
sudo nethogs  # per-process bandwidth
sudo iftop    # real-time traffic
\`\`\`

## Buckets Created

- \`models\` - Trained model artifacts
- \`datasets\` - Training datasets
- \`logs\` - Trajectory logs and telemetry
- \`mlflow\` - MLflow artifact store

## Common Operations

### Upload from Thor/Spark

\`\`\`bash
# Using aws-cli
aws --endpoint-url http://$tower_ip:$MINIO_PORT s3 cp model.pt s3://models/

# Using Python boto3
import boto3
s3 = boto3.client('s3', endpoint_url='http://$tower_ip:$MINIO_PORT')
s3.upload_file('model.pt', 'models', 'my-model.pt')

# Using rclone (configure once)
rclone config  # Add 'tower-minio' remote
rclone copy /local/data tower-minio:datasets/
\`\`\`

### MLflow from Thor/Spark

\`\`\`python
import mlflow
mlflow.set_tracking_uri('http://$tower_ip:$MLFLOW_PORT')

# Log experiment
with mlflow.start_run():
    mlflow.log_param('lr', 0.001)
    mlflow.log_metric('loss', 0.5)
    mlflow.log_artifact('model.pt')
\`\`\`

## Troubleshooting

### Connection refused
- Check Tower firewall: \`sudo ufw status\`
- Verify services running: \`docker ps\`
- Test from Tower itself: \`curl http://localhost:$MINIO_PORT/minio/health/live\`

### Slow transfers
- Check network bandwidth: \`iperf3 -s\` (Tower), \`iperf3 -c $tower_ip\` (Thor)
- Monitor MinIO performance: MinIO Console → Metrics

### Permission denied
- Verify credentials match: \`source $MINIO_DIR/.env\`
- Check bucket policies: MinIO Console → Buckets → Policy
EOF

  ok "Network config guide: $DATA_DIR/NETWORK_SETUP.md"
}

write_profile_rc(){
  say "\n--- Writing $PROFILE_FILE ---"
  cat > "$PROFILE_FILE" <<EOF
# Autogenerated by $SCRIPT_NAME
export OMNI_KIT_ACCEPT_EULA=YES

# ROS 2
[ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ] && . "/opt/ros/${ROS_DISTRO}/setup.bash"

# Conda (Isaac Sim / Isaac Lab)
if [ -f "${CONDA_ROOT}/etc/profile.d/conda.sh" ]; then
  . "${CONDA_ROOT}/etc/profile.d/conda.sh"
  case "\$-" in *i*) conda activate ${ENV_NAME} >/dev/null 2>&1 || true ;; esac
fi

# MinIO/MLflow endpoints for local use
export MLFLOW_TRACKING_URI="http://127.0.0.1:5001"
# use the credentials written by compose (if present)
if [ -f "${MINIO_DIR}/.env" ]; then
  . "${MINIO_DIR}/.env"
  export AWS_ACCESS_KEY_ID="\${MINIO_ROOT_USER}"
  export AWS_SECRET_ACCESS_KEY="\${MINIO_ROOT_PASSWORD}"
  export MLFLOW_S3_ENDPOINT_URL="http://127.0.0.1:9000"
fi

# Hugging Face caches on data volume
export HF_HOME="${DATA_DIR}/hf-cache"
export TRANSFORMERS_CACHE="\$HF_HOME/transformers"
export HF_DATASETS_CACHE="\$HF_HOME/datasets"
export HF_HUB_CACHE="\$HF_HOME/hub"
# Optional: torch and wandb caches
  export TORCH_HOME="${DATA_DIR}/torch"
  export WANDB_DIR="${DATA_DIR}/wandb"

# Aliases for common operations
alias isaacsim-gui="conda activate ${ENV_NAME} && isaacsim isaacsim.exp.full.kit"
alias isaacsim-headless="conda activate ${ENV_NAME} && isaacsim --headless"
alias minio-console="xdg-open http://localhost:9001 || open http://localhost:9001"
alias mlflow-ui="xdg-open http://localhost:5001 || open http://localhost:5001"
EOF
  ok "Wrote $PROFILE_FILE. Add this to ~/.bashrc:  source $PROFILE_FILE"
}

smoke_tests(){
  say "\n--- Smoke Tests ---"
  local failed=0
  
  # shellcheck source=/dev/null
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
  
  # Test Isaac Sim import
  if conda run -n "$ENV_NAME" python -c "import isaacsim" 2>>"$LOG_FILE"; then
    ok "Isaac Sim import: PASS"
  else
    warn "Isaac Sim import: FAIL (check $LOG_FILE)"
    ((failed++))
  fi
  
  # Test ROS 2 sourcing
  if [[ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]]; then
    # shellcheck source=/dev/null
    # Temporarily disable set -u for ROS2 setup (it uses unset variables)
    set +u
    source "/opt/ros/${ROS_DISTRO}/setup.bash"
    set -u
    if command -v ros2 >/dev/null 2>&1; then
      ok "ROS 2 Humble: PASS"
    else
      warn "ROS 2 commands not available"
      ((failed++))
    fi
  fi
  
  # Test MinIO connectivity
  if curl -f http://localhost:$MINIO_PORT/minio/health/live >/dev/null 2>&1; then
    ok "MinIO health: PASS (port $MINIO_PORT)"
  else
    warn "MinIO not responding on port $MINIO_PORT"
    ((failed++))
  fi
  
  # Test MLflow connectivity
  if curl -f http://localhost:$MLFLOW_PORT/health >/dev/null 2>&1 || curl -f http://localhost:$MLFLOW_PORT >/dev/null 2>&1; then
    ok "MLflow health: PASS (port $MLFLOW_PORT)"
  else
    warn "MLflow not responding on port $MLFLOW_PORT"
    # Check if container is running
    if docker ps --filter "name=mlflow" --filter "status=running" --format '{{.Names}}' 2>/dev/null | grep -q '^mlflow$'; then
      warn "MLflow container is running but not responding yet (may need more time)"
      warn "Check logs: docker logs mlflow"
    else
      warn "MLflow container is not running"
      warn "Check status: docker ps -a | grep mlflow"
      warn "Check logs: docker logs mlflow"
    fi
    ((failed++))
  fi
  
  # Test network accessibility from external IP
  local tower_ip; tower_ip=$(cat "$MARKER_DIR/tower_ip.txt" 2>/dev/null || echo "")
  if [[ -n "$tower_ip" ]]; then
    say "\nTesting external access (for Thor/Spark):"
    if timeout 5 bash -c "curl -f http://$tower_ip:$MINIO_PORT/minio/health/live" >/dev/null 2>&1; then
      ok "MinIO accessible from network: http://$tower_ip:$MINIO_PORT"
    else
      warn "MinIO not accessible from $tower_ip (firewall/routing issue?)"
    fi
  fi
  
  if ((failed > 0)); then
    warn "Smoke tests: $failed failures detected"
    say "Review logs: $LOG_FILE"
    say "Check services: docker ps"
    say "Check firewall: sudo ufw status"
  else
    ok "All smoke tests passed!"
  fi
  
  say "--- Smoke Tests Complete ---"
}

doctor(){
  say "\n╔════════════════════════════════════════════════════════════════╗"
  say "║  System Health Check                                          ║"
  say "╚════════════════════════════════════════════════════════════════╝\n"
  
  say "═══ SYSTEM ═══"
  echo "OS: $(lsb_release -ds 2>/dev/null || echo unknown)"
  echo "Kernel: $(uname -r)"
  echo "Hostname: $(hostname)"
  local tower_ip; tower_ip=$(cat "$MARKER_DIR/tower_ip.txt" 2>/dev/null || ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1 || echo "unknown")
  echo "IP Address: $tower_ip"
  
  say "\n═══ HARDWARE ═══"
  local ram_gb; ram_gb=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
  echo "RAM: ${ram_gb}GB"
  local disk_avail; disk_avail=$(df -BG / | tail -1 | awk '{print $4}')
  echo "Disk available: $disk_avail"
  
  if command -v nvidia-smi >/dev/null 2>&1; then
    local gpu_count; gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l)
    local driver_ver; driver_ver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)
    echo "NVIDIA GPU: ${gpu_count} GPU(s), driver ${driver_ver}"
    nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader 2>/dev/null | nl -w2 -s'. '
  else
    echo "NVIDIA GPU: nvidia-smi not found"
  fi
  
  say "\n═══ SOFTWARE ═══"
  docker --version 2>/dev/null || echo "Docker: not installed"
  
  if [[ -d "$CONDA_ROOT" ]]; then
    echo "Conda: $CONDA_ROOT"
    # shellcheck source=/dev/null
    source "$CONDA_ROOT/etc/profile.d/conda.sh" 2>/dev/null
    if conda env list | awk '{print $1}' | grep -q "^${ENV_NAME}\$"; then
      local py_ver; py_ver=$(conda run -n "$ENV_NAME" python --version 2>&1 || echo "unknown")
      echo "Conda env '$ENV_NAME': present ($py_ver)"
    else
      echo "Conda env '$ENV_NAME': missing"
    fi
  else
    echo "Conda: not installed"
  fi
  
  if [[ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]]; then
    echo "ROS 2: ${ROS_DISTRO} installed"
  else
    echo "ROS 2: not installed"
  fi
  
  say "\n═══ SERVICES ═══"
  local services_ok=0
  
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^minio$'; then
    echo "✓ MinIO: running (ports $MINIO_PORT/$MINIO_CONSOLE_PORT)"
    ((services_ok++))
  else
    echo "✗ MinIO: not running"
  fi
  
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^mlflow$'; then
    echo "✓ MLflow: running (port $MLFLOW_PORT)"
    ((services_ok++))
  else
    echo "✗ MLflow: not running"
  fi
  
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^mlflow-db$'; then
    echo "✓ MLflow DB: running"
    ((services_ok++))
  else
    echo "✗ MLflow DB: not running"
  fi
  
  # Check systemd service
  if systemctl is-enabled robot-datalake.service >/dev/null 2>&1; then
    echo "✓ Systemd service: enabled (auto-starts on boot)"
  else
    echo "✗ Systemd service: not enabled"
  fi
  
  say "\n═══ NETWORK ═══"
  # Check port bindings
  for port in "${REQUIRED_PORTS[@]}"; do
    if sudo lsof -i ":$port" >/dev/null 2>&1; then
      echo "✓ Port $port: listening"
    else
      echo "✗ Port $port: not listening"
    fi
  done
  
  # Check firewall
  if command -v ufw >/dev/null 2>&1; then
    local ufw_status; ufw_status=$(sudo ufw status | head -1 || echo "unknown")
    echo "Firewall (ufw): $ufw_status"
  fi
  
  say "\n═══ CONNECTIVITY TESTS ═══"
  if curl -fsSL --max-time 3 http://localhost:$MINIO_PORT/minio/health/live >/dev/null 2>&1; then
    echo "✓ MinIO: localhost accessible"
  else
    echo "✗ MinIO: localhost not accessible"
  fi
  
  if curl -fsSL --max-time 3 http://localhost:$MLFLOW_PORT >/dev/null 2>&1; then
    echo "✓ MLflow: localhost accessible"
  else
    echo "✗ MLflow: localhost not accessible"
  fi
  
  if [[ -n "$tower_ip" && "$tower_ip" != "unknown" ]]; then
    if timeout 3 bash -c "curl -fsSL http://$tower_ip:$MINIO_PORT/minio/health/live" >/dev/null 2>&1; then
      echo "✓ MinIO: network accessible at http://$tower_ip:$MINIO_PORT"
    else
      echo "✗ MinIO: network not accessible (firewall?)"
    fi
  fi
  
  say "\n═══ INSTALL STATUS ═══"
  if [[ -f "$MARKER_DIR/install_completed.txt" ]]; then
    local install_date; install_date=$(cat "$MARKER_DIR/install_completed.txt")
    echo "Installation completed: $install_date"
  else
    echo "Installation: incomplete or not run"
  fi
  
  say "\n═══ GO2 SIMULATION ═══"
  if [[ -d "$HOME/workspace/go2_omniverse" ]]; then
    echo "✓ go2_omniverse: cloned"
    
    # Check if workspaces are built
    if [[ -f "$HOME/workspace/go2_omniverse/IsaacSim-ros_workspaces/humble_ws/install/setup.bash" ]]; then
      echo "✓ IsaacSim ROS2 workspace: built"
    else
      echo "✗ IsaacSim ROS2 workspace: not built"
    fi
    
    if [[ -f "$HOME/workspace/go2_omniverse/go2_omniverse_ws/install/setup.bash" ]]; then
      echo "✓ go2_omniverse workspace: built"
    else
      echo "✗ go2_omniverse workspace: not built"
    fi
    
    if [[ -f "$HOME/workspace/go2_omniverse/run_sim.sh" ]]; then
      echo "✓ Launch script: present"
      echo "  → To launch: cd ~/workspace/go2_omniverse && ./run_sim.sh"
    else
      echo "✗ Launch script: missing"
    fi
  else
    echo "✗ go2_omniverse: not cloned"
  fi
  
  say "\n═══ FILES & LOGS ═══"
  echo "Profile: $PROFILE_FILE ($(test -f "$PROFILE_FILE" && echo "present" || echo "missing"))"
  echo "Network guide: $DATA_DIR/NETWORK_SETUP.md ($(test -f "$DATA_DIR/NETWORK_SETUP.md" && echo "present" || echo "missing"))"
  echo "Credentials (secure): $MINIO_DIR/CREDENTIALS.txt ($(test -f "$MINIO_DIR/CREDENTIALS.txt" && echo "present" || echo "missing"))"
  echo "Credentials (docker): $MINIO_DIR/.env ($(test -f "$MINIO_DIR/.env" && echo "present" || echo "missing"))"
  echo "Install log: $LOG_FILE"
  
  if ((services_ok == 3)); then
    ok "\n✓ All services healthy"
  else
    warn "\n⚠ Some services not running. Start with: sudo systemctl start robot-datalake"
  fi
  
  say "\n╚════════════════════════════════════════════════════════════════╝"
}

uninstall_all(){
  say "\n--- Uninstall ---"
  
  # Load data directories from state if available
  local DATA_DIR MINIO_DIR MINIO_COMPOSE_YAML
  if [[ -f "$MARKER_DIR/data_dir.txt" ]]; then
    DATA_DIR=$(cat "$MARKER_DIR/data_dir.txt")
  else
    DATA_DIR="$DATA_DIR_DEFAULT"
  fi
  
  if [[ -f "$MARKER_DIR/minio_dir.txt" ]]; then
    MINIO_DIR=$(cat "$MARKER_DIR/minio_dir.txt")
  else
    MINIO_DIR="${DATA_DIR}/minio"
  fi
  MINIO_COMPOSE_YAML="${MINIO_DIR}/docker-compose.yml"
  
  local cmd; cmd="$(compose_cmd 2>/dev/null)" || cmd="docker compose"

  # Bring down MLflow/MinIO
  if [[ -f "$MINIO_COMPOSE_YAML" ]]; then
    say "Stopping MinIO/MLflow services..."
    (cd "$MINIO_DIR" && $cmd down -v 2>/dev/null || true)
  else
    if [[ -f "$DATA_DIR_DEFAULT/minio/docker-compose.yml" ]]; then
      say "Stopping MinIO/MLflow services..."
      (cd "$DATA_DIR_DEFAULT/minio" && $cmd down -v 2>/dev/null || true)
    fi
  fi

  # Remove workspaces?
  confirm "Remove ~/workspace/IsaacLab and ~/workspace/go2_omniverse?" && run "rm -rf \"$HOME/workspace/IsaacLab\" \"$HOME/workspace/go2_omniverse\""

  # Remove conda env?
  if [[ -d "$CONDA_ROOT" ]]; then
    # shellcheck source=/dev/null
    source "$CONDA_ROOT/etc/profile.d/conda.sh"
    conda env list | awk '{print $1}' | grep -q "^${ENV_NAME}\$" && confirm "Remove conda env '$ENV_NAME'?" && run "conda env remove -n \"$ENV_NAME\""
  fi

  # Remove ROS 2?
  confirm "Remove ROS 2 Humble packages?" && { run "sudo apt-get purge -y 'ros-${ROS_DISTRO}-*' ros-dev-tools || true"; run "sudo apt-get autoremove -y"; run "sudo rm -f /etc/apt/sources.list.d/ros2.list /etc/apt/keyrings/ros-archive-keyring.gpg || true"; }

  # Remove MinIO/MLflow configs and (optionally) data
  if [[ -d "$MINIO_DIR" ]]; then
    confirm "Remove MinIO/MLflow config directory ($MINIO_DIR)?" && run "rm -rf \"$MINIO_DIR\""
  fi
  confirm "Remove MinIO/MLflow data under $DATA_DIR (buckets, pgdata, caches)? (IRREVERSIBLE)" && run "rm -rf \"$DATA_DIR/minio\" \"$DATA_DIR/mlflow\" \"$DATA_DIR/ov_cache\" \"$DATA_DIR/hf-cache\" \"$DATA_DIR/torch\" \"$DATA_DIR/wandb\""

  # Optional: remove Docker + NVIDIA container toolkit
  confirm "Remove Docker engine and NVIDIA container toolkit?" && { run "sudo apt-get purge -y nvidia-container-toolkit || true"; run "sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io || true"; run "sudo apt-get autoremove -y"; }

  # Optional: remove NVIDIA drivers
  confirm "Remove NVIDIA driver packages as well?" && { run "sudo apt-get purge -y 'nvidia-*'"; run "sudo apt-get autoremove -y"; warn "Reboot to switch kernel modules."; }

  # Clean up symlinks
  [[ -L "$HOME/.cache/ov" ]] && run "rm -f \"$HOME/.cache/ov\""
  [[ -L "$HOME/.cache/nvidia/GLCache" ]] && run "rm -f \"$HOME/.cache/nvidia/GLCache\""
  [[ -L "$HOME/.nv/ComputeCache" ]] && run "rm -f \"$HOME/.nv/ComputeCache\""

  # Cleanup profile
  [[ -f "$PROFILE_FILE" ]] && confirm "Remove $PROFILE_FILE?" && run "rm -f \"$PROFILE_FILE\""

  ok "Uninstall complete."
}

install(){
  say "\n╔════════════════════════════════════════════════════════════════╗"
  say "║  Robot Simulation + Data Lake Installer                       ║"
  say "║  Tower Setup for Thor/Spark Integration                       ║"
  say "╚════════════════════════════════════════════════════════════════╝\n"
  
  # Load saved state if exists (for idempotent re-runs)
  if [[ -f "$MARKER_DIR/data_dir.txt" ]]; then
    DATA_DIR=$(cat "$MARKER_DIR/data_dir.txt")
    ok "Loaded DATA_DIR from previous run: $DATA_DIR"
  fi
  if [[ -f "$MARKER_DIR/minio_dir.txt" ]]; then
    MINIO_DIR=$(cat "$MARKER_DIR/minio_dir.txt")
    MINIO_COMPOSE_YAML="${MINIO_DIR}/docker-compose.yml"
    ok "Loaded MINIO_DIR from previous run: $MINIO_DIR"
  fi
  
  # Check for existing installation
  if [[ -f "$MARKER_DIR/install_completed.txt" ]]; then
    warn "⚠️  Existing installation detected!"
    say "Install completed: $(cat "$MARKER_DIR/install_completed.txt")"
    say ""
    say "Running install again may cause issues. Recommended actions:"
    say "  - Check status:     bash $SCRIPT_NAME doctor"
    say "  - Uninstall first:  bash $SCRIPT_NAME uninstall"
    say "  - Reconfigure:      bash $SCRIPT_NAME reconfigure-drives"
    say ""
    confirm "Continue with re-install anyway?" || exit 0
  fi
  
  preflight_checks
  
  # Create checkpoint
  date -Iseconds > "$MARKER_DIR/install_started.txt"
  
  require_ubuntu_2204
  ensure_base_tools
  install_driver_if_needed
  install_docker_nvidia
  
  # Ensure Docker daemon is running
  say "\n--- Starting Docker daemon ---"
  run "sudo systemctl start docker"
  run "sudo systemctl enable docker"
  sleep 2
  if ! sudo systemctl is-active docker >/dev/null 2>&1; then
    echo "Error: Docker daemon failed to start"
    echo "Check logs with: sudo journalctl -u docker -n 50"
    exit 1
  fi
  ok "Docker daemon running"
  
  install_miniconda
  create_env_and_install_isaacsim
  install_ros2_humble
  clone_isaaclab
  clone_go2_omniverse_and_patch
  build_go2_ros2_workspaces  # NEW: Build Go2 simulation workspaces
  install_dev_tools
  pick_data_dir
  link_caches_to_data_dir
  pick_minio_drives
  generate_minio_mlflow_compose
  setup_systemd_services
  configure_dual_nic_if_available  # NEW: Optimize dual ethernet if available
  configure_firewall_for_network
  write_network_config_doc
  write_profile_rc
  smoke_tests
  
  # Mark install complete
  date -Iseconds > "$MARKER_DIR/install_completed.txt"
  
  ok "\n╔════════════════════════════════════════════════════════════════╗"
  ok "║  Installation Complete!                                        ║"
  ok "╚════════════════════════════════════════════════════════════════╝\n"
  
  local tower_ip; tower_ip=$(cat "$MARKER_DIR/tower_ip.txt" 2>/dev/null || echo "TOWER_IP")
  
  say "═══ QUICK START: UNITREE GO2 SIMULATION ═══"
  say "1. Activate environment:    source ~/.robot-simrc && conda activate env_isaaclab"
  say "2. Launch Go2 simulation:   cd ~/workspace/go2_omniverse && ./run_sim.sh"
  say "3. Control robot:           Use W/A/S/D keys, ESC to exit"
  say "4. ROS2 topics available:   /camera/image_raw, /odom, /cmd_vel, /scan"
  say ""
  say "═══ LOCAL ACCESS ═══"
  say "1. Add to ~/.bashrc:        source $PROFILE_FILE"
  say "2. Reload shell:            exec bash"
  say "3. Launch Isaac Sim:        isaacsim-gui"
  say "4. MLflow UI:               http://localhost:$MLFLOW_PORT"
  say "5. MinIO Console:           http://localhost:$MINIO_CONSOLE_PORT"
  say ""
  say "═══ THOR/SPARK ACCESS ═══"
  say "Tower IP:                   $tower_ip"
  say "MinIO S3 API:               http://$tower_ip:$MINIO_PORT"
  say "MinIO Console:              http://$tower_ip:$MINIO_CONSOLE_PORT"
  say "MLflow Tracking:            http://$tower_ip:$MLFLOW_PORT"
  say ""
  say "⚠️  CREDENTIALS (Keep Secure!):"
  say "Human-readable:             $MINIO_DIR/CREDENTIALS.txt"
  say "Docker Compose:             $MINIO_DIR/.env"
  say "Network Setup Guide:        $DATA_DIR/NETWORK_SETUP.md"
  say ""
  say "Transfer credentials to Thor/Spark:"
  say "  scp $MINIO_DIR/CREDENTIALS.txt thor:~/tower_credentials.txt"
  say "  scp $MINIO_DIR/CREDENTIALS.txt spark:~/tower_credentials.txt"
  say ""
  say "═══ AUTO-START ═══"
  say "Services auto-start on boot via systemd"
  say "Control with:               sudo systemctl {start|stop|status} robot-datalake"
  say ""
  say "═══ VALIDATION ═══"
  say "Run smoke tests:            bash $SCRIPT_NAME doctor"
  say "View logs:                  tail -f $LOG_FILE"
  say ""
  say "═══ DOCUMENTATION ═══"
  say "Go2 Sim Quick Start:        ~/shadowhound/docs/deployment/tower_go2_isaac_sim_quickstart.md"
  say "Tower Setup Guide:          ~/shadowhound/docs/deployment/tower_sim_datalake_setup.md"
}

test_mode(){
  say "\n╔════════════════════════════════════════════════════════════════╗"
  say "║  TEST MODE - Validation Only (No Changes)                     ║"
  say "╚════════════════════════════════════════════════════════════════╝\n"
  
  preflight_checks
  
  say "\n═══ CHECKING EXISTING INSTALLATION ═══"
  doctor
  
  say "\n═══ TEST MODE COMPLETE ═══"
  say "To proceed with install: bash $SCRIPT_NAME install"
}

reconfigure_drives(){
  say "\n╔════════════════════════════════════════════════════════════════╗"
  say "║  Reconfigure MinIO Storage Drives                             ║"
  say "╚════════════════════════════════════════════════════════════════╝\n"
  
  # Check if MinIO is installed
  [[ -f "$MARKER_DIR/install_completed.txt" ]] || { warn "Installation not complete. Run: bash $SCRIPT_NAME install"; exit 1; }
  
  # Load existing data dir
  if [[ -f "$MARKER_DIR/data_dir.txt" ]]; then
    DATA_DIR=$(cat "$MARKER_DIR/data_dir.txt")
    MINIO_DIR="${DATA_DIR}/minio"
    MINIO_COMPOSE_YAML="${MINIO_DIR}/docker-compose.yml"
  else
    warn "Data directory not found in state. Cannot reconfigure."
    exit 1
  fi
  
  say "Current MinIO data directory: $MINIO_DIR"
  say "\nCurrent drives:"
  if [[ -f "$MARKER_DIR/minio_drives.txt" ]]; then
    nl -w2 -s'. ' "$MARKER_DIR/minio_drives.txt"
  else
    echo "  (not recorded)"
  fi
  
  say "\n⚠️  WARNING: Changing drives requires data migration!"
  say "Before proceeding:"
  say "  1. Backup existing data: rclone sync minio:/ /backup/"
  say "  2. Services will be stopped during reconfiguration"
  say "  3. Data must be manually moved to new drives"
  say ""
  confirm "Continue with drive reconfiguration?" || exit 0
  
  # Stop services
  say "\nStopping services..."
  (cd "$MINIO_DIR" && docker compose down)
  
  # Backup current config
  run "cp \"$MINIO_COMPOSE_YAML\" \"$BACKUP_DIR/docker-compose.yml.$(date +%Y%m%d-%H%M%S)\""
  run "cp \"$MARKER_DIR/minio_drives.txt\" \"$BACKUP_DIR/minio_drives.txt.$(date +%Y%m%d-%H%M%S)\" || true"
  
  # Select new drives
  pick_minio_drives
  
  # Regenerate compose file with new drives
  generate_minio_mlflow_compose
  
  ok "Drive configuration updated."
  say "\n⚠️  IMPORTANT: You must now migrate data to new drives!"
  say "Old drives are still listed in: $BACKUP_DIR/minio_drives.txt.*"
  say "New drives listed in: $MARKER_DIR/minio_drives.txt"
  say ""
  say "Migration steps:"
  say "  1. Manually copy data from old drives to new drives"
  say "  2. Verify data integrity: ls -lh /new/drive/path/"
  say "  3. Start services: sudo systemctl start robot-datalake"
  say "  4. Validate: bash $SCRIPT_NAME doctor"
}

reconfigure_network(){
  say "\n╔════════════════════════════════════════════════════════════════╗"
  say "║  Reconfigure Network Settings                                  ║"
  say "╚════════════════════════════════════════════════════════════════╝\n"
  
  # Check if MinIO is installed
  [[ -f "$MARKER_DIR/install_completed.txt" ]] || { warn "Installation not complete. Run: bash $SCRIPT_NAME install"; exit 1; }
  
  # Load existing data dir
  if [[ -f "$MARKER_DIR/data_dir.txt" ]]; then
    DATA_DIR=$(cat "$MARKER_DIR/data_dir.txt")
  else
    DATA_DIR="$DATA_DIR_DEFAULT"
  fi
  
  # Load MINIO_DIR
  if [[ -f "$MARKER_DIR/minio_dir.txt" ]]; then
    MINIO_DIR=$(cat "$MARKER_DIR/minio_dir.txt")
  else
    MINIO_DIR="${DATA_DIR}/minio"
  fi
  
  say "=== NETWORK RECONFIGURATION OPTIONS ===\n"
  say "What would you like to reconfigure?"
  say ""
  say "1. Dual-NIC Setup (change ethernet configuration)"
  say "   - Switch between separate networks/bonding/single NIC"
  say "   - Update network topology"
  say ""
  say "2. IP Address & Firewall (update after network change)"
  say "   - Update Tower IP address"
  say "   - Regenerate firewall rules"
  say "   - Update documentation"
  say ""
  say "3. Both (full network reconfiguration)"
  say ""
  say "4. Cancel"
  say ""
  
  read -r -p "Choose option [1/2/3/4, default=2]: " choice
  choice="${choice:-2}"
  
  case "$choice" in
    1)
      say "\n=== Reconfiguring Dual-NIC Setup ===\n"
      # Show current netplan configs
      if ls /etc/netplan/*.yaml >/dev/null 2>&1; then
        say "Current netplan configurations:"
        ls -lh /etc/netplan/*.yaml
        say ""
      fi
      
      # Offer to view current config
      if confirm "View current network configuration?"; then
        say "\n--- Current netplan config ---"
        for f in /etc/netplan/*.yaml; do
          [[ -f "$f" ]] || continue
          say "\n=== $f ==="
          cat "$f"
        done
        say "\n--- End config ---\n"
      fi
      
      # Run dual-NIC configuration
      configure_dual_nic_if_available
      
      # Update IP and firewall after NIC reconfiguration
      say "\n--- Updating IP and firewall after NIC reconfiguration ---"
      sleep 2  # Wait for network to settle
      local current_ip; current_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1 || echo "unknown")
      echo "$current_ip" > "$MARKER_DIR/tower_ip.txt"
      configure_firewall_for_network
      write_network_config_doc
      
      ok "\nDual-NIC reconfiguration complete!"
      say "New Tower IP: $current_ip"
      ;;
      
    2)
      say "\n=== Updating IP Address & Firewall ===\n"
      
      # Show current network config
      local old_ip; old_ip=$(cat "$MARKER_DIR/tower_ip.txt" 2>/dev/null || echo "unknown")
      say "Previous Tower IP: $old_ip"
      
      # Detect current IP
      local current_ip; current_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1 || echo "unknown")
      say "Detected IP: $current_ip"
      
      if [[ "$current_ip" != "$old_ip" ]]; then
        say "\n⚠️  IP address has changed! Updating configuration..."
      else
        say "\nIP unchanged, but you can force a full network reconfiguration."
      fi
      
      confirm "Update IP and firewall configuration?" || exit 0
      
      # Update IP in state
      echo "$current_ip" > "$MARKER_DIR/tower_ip.txt"
      
      # Regenerate firewall rules
      configure_firewall_for_network
      
      # Regenerate network documentation
      write_network_config_doc
      
      ok "\nNetwork configuration updated."
      say "New Tower IP: $current_ip"
      ;;
      
    3)
      say "\n=== Full Network Reconfiguration ===\n"
      
      # Step 1: Dual-NIC
      say "Step 1/2: Dual-NIC Configuration"
      configure_dual_nic_if_available
      
      # Step 2: IP and firewall
      say "\nStep 2/2: IP Address & Firewall"
      sleep 2  # Wait for network to settle
      local current_ip; current_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1 || echo "unknown")
      echo "$current_ip" > "$MARKER_DIR/tower_ip.txt"
      configure_firewall_for_network
      write_network_config_doc
      
      ok "\nFull network reconfiguration complete!"
      say "New Tower IP: $current_ip"
      ;;
      
    4)
      say "Cancelled."
      exit 0
      ;;
      
    *)
      warn "Invalid choice. Cancelled."
      exit 1
      ;;
  esac
  
  # Common final instructions
  say "\nNetwork guide updated: $DATA_DIR/NETWORK_SETUP.md"
  say ""
  say "⚠️  NEXT STEPS - Update Thor/Spark configuration:"
  say "  1. Update TOWER_IP in ~/.bashrc on Thor/Spark"
  say "  2. Update MLFLOW_TRACKING_URI and MLFLOW_S3_ENDPOINT_URL"
  say "  3. Test connectivity:"
  say "     curl http://$current_ip:$MINIO_PORT/minio/health/live"
  say "     curl http://$current_ip:$MLFLOW_PORT/health"
  say ""
  say "  4. Transfer updated credentials if needed:"
  say "     scp $MINIO_DIR/CREDENTIALS.txt thor:~/tower_credentials.txt"
  say ""
  say "See: $DATA_DIR/NETWORK_SETUP.md for complete configuration"
}

reconfigure_credentials(){
  say "\n╔════════════════════════════════════════════════════════════════╗"
  say "║  Credential Rotation                                           ║"
  say "╚════════════════════════════════════════════════════════════════╝\n"
  
  # Check if installed
  if [[ ! -f "$MARKER_DIR/install_completed.txt" ]]; then
    echo "Error: Installation not found. Run: bash $SCRIPT_NAME install"
    exit 1
  fi
  
  # Load paths
  if [[ -f "$MARKER_DIR/data_dir.txt" ]]; then
    DATA_DIR=$(cat "$MARKER_DIR/data_dir.txt")
  else
    DATA_DIR="$DATA_DIR_DEFAULT"
  fi
  
  if [[ -f "$MARKER_DIR/minio_dir.txt" ]]; then
    MINIO_DIR=$(cat "$MARKER_DIR/minio_dir.txt")
  else
    MINIO_DIR="$DATA_DIR/minio"
  fi
  
  MINIO_COMPOSE_YAML="$MINIO_DIR/docker-compose.yml"
  
  # Show current credentials (masked)
  if [[ -f "$MINIO_DIR/.env" ]]; then
    source "$MINIO_DIR/.env"
    
    # Validate credentials loaded successfully
    if [[ -z "${MINIO_ROOT_USER:-}" || -z "${MINIO_ROOT_PASSWORD:-}" || -z "${POSTGRES_PASSWORD:-}" ]]; then
      echo "Error: Failed to load credentials from $MINIO_DIR/.env"
      echo "File may be corrupted. Check: cat $MINIO_DIR/.env"
      exit 1
    fi
    
    say "Current credentials:"
    say "  MinIO User:       ${MINIO_ROOT_USER:0:4}...${MINIO_ROOT_USER: -4}"
    say "  MinIO Password:   ${MINIO_ROOT_PASSWORD:0:4}...${MINIO_ROOT_PASSWORD: -4}"
    say "  PostgreSQL Pass:  ${POSTGRES_PASSWORD:0:4}...${POSTGRES_PASSWORD: -4}"
    say ""
  else
    echo "Error: Credentials file not found: $MINIO_DIR/.env"
    exit 1
  fi
  
  warn "⚠️  WARNING: Credential rotation will:"
  say "  1. Generate new random credentials"
  say "  2. Backup old credentials to $BACKUP_DIR"
  say "  3. Stop all services (MinIO, MLflow, PostgreSQL)"
  say "  4. Update Docker Compose configuration"
  say "  5. Restart all services"
  say "  6. Require updating Thor/Spark configuration"
  say ""
  warn "⚠️  IMPORTANT: You MUST update Thor/Spark after this!"
  say ""
  
  confirm "Rotate credentials now?" || exit 0
  
  # Backup current credentials
  local backup_file="$BACKUP_DIR/credentials_$(date +%Y%m%d_%H%M%S).env"
  run "cp \"$MINIO_DIR/.env\" \"$backup_file\""
  if [[ -f "$MINIO_DIR/CREDENTIALS.txt" ]]; then
    run "cp \"$MINIO_DIR/CREDENTIALS.txt\" \"$backup_file.txt\""
  fi
  ok "Old credentials backed up to: $backup_file"
  
  # Stop services
  say "\nStopping services..."
  local cmd; cmd="$(compose_cmd)"; cmd="${cmd:-docker compose}"
  (cd "$MINIO_DIR" && $cmd down || true)
  ok "Services stopped"
  
  # Generate new credentials
  say "\nGenerating new credentials..."
  local NEW_MINIO_USER NEW_MINIO_PASS NEW_POSTGRES_PASSWORD
  NEW_MINIO_USER="$(openssl rand -hex 8)"
  NEW_MINIO_PASS="$(openssl rand -hex 16)"
  NEW_POSTGRES_PASSWORD="$(openssl rand -hex 16)"
  ok "New credentials generated"
  
  # Update .env file
  say "\nUpdating .env file..."
  echo "MINIO_ROOT_USER=$NEW_MINIO_USER" > "$MINIO_DIR/.env"
  echo "MINIO_ROOT_PASSWORD=$NEW_MINIO_PASS" >> "$MINIO_DIR/.env"
  echo "POSTGRES_PASSWORD=$NEW_POSTGRES_PASSWORD" >> "$MINIO_DIR/.env"
  run "chmod 600 \"$MINIO_DIR/.env\""
  ok ".env file updated"
  
  # Regenerate CREDENTIALS.txt
  say "\nRegenerating CREDENTIALS.txt..."
  local tower_ip; tower_ip=$(cat "$MARKER_DIR/tower_ip.txt" 2>/dev/null || hostname -I | awk '{print $1}')
  local creds_file="$MINIO_DIR/CREDENTIALS.txt"
  cat > "$creds_file" <<CREDS
# =============================================================================
# Robot Data Lake Credentials
# =============================================================================
# Generated: $(date)
# Location: $(hostname)
# ROTATED: Credentials were rotated for security
#
# ⚠️  SECURITY: This file contains sensitive credentials.
# ⚠️  Keep this file secure and NEVER commit to version control.
# ⚠️  Add to .gitignore if in a git repository.
# =============================================================================

MinIO S3 API:
  URL:       http://${tower_ip}:${MINIO_PORT}
  Console:   http://${tower_ip}:${MINIO_CONSOLE_PORT}
  User:      ${NEW_MINIO_USER}
  Password:  ${NEW_MINIO_PASS}

MLflow Tracking Server:
  URL:       http://${tower_ip}:${MLFLOW_PORT}
  (No authentication required)

PostgreSQL (MLflow Backend):
  Host:      localhost:5432
  Database:  mlflow
  User:      mlflow
  Password:  ${NEW_POSTGRES_PASSWORD}
  (Only accessible from Docker network)

AWS CLI Configuration:
  export AWS_ACCESS_KEY_ID="${NEW_MINIO_USER}"
  export AWS_SECRET_ACCESS_KEY="${NEW_MINIO_PASS}"
  export AWS_ENDPOINT_URL="http://localhost:${MINIO_PORT}"

Python boto3 Configuration:
  s3_client = boto3.client(
      's3',
      endpoint_url='http://localhost:${MINIO_PORT}',
      aws_access_key_id='${NEW_MINIO_USER}',
      aws_secret_access_key='${NEW_MINIO_PASS}'
  )

# =============================================================================
# Transfer these credentials to Thor/Spark:
# scp $MINIO_DIR/CREDENTIALS.txt thor:~/tower_credentials.txt
# scp $MINIO_DIR/CREDENTIALS.txt spark:~/tower_credentials.txt
# =============================================================================
CREDS
  run "chmod 600 \"$creds_file\""
  ok "CREDENTIALS.txt regenerated"
  
  # Update backup state file
  echo "$NEW_MINIO_USER:$NEW_MINIO_PASS:$NEW_POSTGRES_PASSWORD" > "$MARKER_DIR/credentials.txt"
  run "chmod 600 \"$MARKER_DIR/credentials.txt\""
  
  # Restart services
  say "\nRestarting services with new credentials..."
  (cd "$MINIO_DIR" && $cmd up -d --build)
  
  # Wait for services
  say "Waiting for services to become healthy..."
  local retries=12 healthy=0
  for ((i=1; i<=retries; i++)); do
    # Check if containers are running
    if ! docker ps --filter "name=minio" --filter "status=running" --format '{{.Names}}' 2>/dev/null | grep -q '^minio$'; then
      warn "MinIO container not running. May have crashed."
      break
    fi
    if ! docker ps --filter "name=mlflow" --filter "status=running" --format '{{.Names}}' 2>/dev/null | grep -q '^mlflow$'; then
      warn "MLflow container not running. May have crashed."
      break
    fi
    
    # Check health endpoints
    if curl -fsSL http://localhost:9000/minio/health/live >/dev/null 2>&1 && \
       (curl -fsSL http://localhost:5001/health >/dev/null 2>&1 || curl -fsSL http://localhost:5001 >/dev/null 2>&1); then
      healthy=1; break
    fi
    sleep 5
  done
  
  if ((healthy)); then
    ok "Services restarted successfully with new credentials"
  else
    warn "Services failed health checks. Rolling back to old credentials..."
    run "cp \"$backup_file\" \"$MINIO_DIR/.env\""
    say "Restarting with old credentials..."
    (cd "$MINIO_DIR" && $cmd down && $cmd up -d)
    warn "Rolled back to old credentials due to startup failure"
    warn "Check logs: docker logs minio && docker logs mlflow"
    warn "Old credentials restored from: $backup_file"
    exit 1
  fi
  
  # Summary
  ok "\n╔════════════════════════════════════════════════════════════════╗"
  ok "║  Credential Rotation Complete!                                 ║"
  ok "╚════════════════════════════════════════════════════════════════╝\n"
  
  say "═══ NEW CREDENTIALS ═══"
  say "Location:               $MINIO_DIR/CREDENTIALS.txt"
  say "Backup (old):           $backup_file"
  say ""
  say "MinIO User:             $NEW_MINIO_USER"
  say "MinIO Password:         $NEW_MINIO_PASS"
  say ""
  say "═══ REQUIRED ACTIONS ═══"
  warn "⚠️  You MUST update Thor/Spark configuration:"
  say ""
  say "1. Transfer new credentials to Thor/Spark:"
  say "   scp $MINIO_DIR/CREDENTIALS.txt thor:~/tower_credentials.txt"
  say "   scp $MINIO_DIR/CREDENTIALS.txt spark:~/tower_credentials.txt"
  say ""
  say "2. On Thor/Spark, update environment variables:"
  say "   export AWS_ACCESS_KEY_ID=\"$NEW_MINIO_USER\""
  say "   export AWS_SECRET_ACCESS_KEY=\"$NEW_MINIO_PASS\""
  say ""
  say "3. Update ~/.bashrc on Thor/Spark for persistence"
  say ""
  say "4. Test connectivity:"
  say "   aws --endpoint-url http://$tower_ip:$MINIO_PORT s3 ls"
  say ""
  say "═══ SERVICE STATUS ═══"
  say "Verify services:        bash $SCRIPT_NAME doctor"
  say "View logs:              docker logs minio"
  say "                        docker logs mlflow"
}

gpu_diagnostics(){
  say "╔════════════════════════════════════════════════════════════════╗"
  say "║  GPU Diagnostics & Monitoring                                  ║"
  say "╚════════════════════════════════════════════════════════════════╝\n"
  
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "ERROR: nvidia-smi not found. NVIDIA driver not installed."
    exit 1
  fi
  
  say "═══ CURRENT GPU STATUS ═══"
  nvidia-smi
  
  say "\n═══ DETAILED GPU INFORMATION ═══"
  nvidia-smi --query-gpu=index,name,driver_version,pci.bus_id,pci.device_id,memory.total,memory.free,memory.used,temperature.gpu,power.draw,power.limit,clocks.current.graphics,clocks.max.graphics --format=csv
  
  say "\n═══ GPU PERSISTENCE MODE ═══"
  nvidia-smi --query-gpu=index,name,persistence_mode --format=csv
  echo ""
  echo "Note: Persistence mode keeps driver loaded even when no processes use GPU"
  echo "Enable with: sudo nvidia-smi -pm 1"
  
  say "\n═══ PCI DEVICES ═══"
  lspci | grep -i nvidia
  
  say "\n═══ KERNEL MESSAGES (Last 50 NVIDIA-related) ═══"
  dmesg | grep -i nvidia | tail -50 || echo "No NVIDIA kernel messages found"
  
  say "\n═══ GPU POWER READINGS ═══"
  nvidia-smi -q | grep -A 5 "Power Readings" || echo "Power readings not available"
  
  say "\n═══ DRIVER MODULE INFO ═══"
  lsmod | grep nvidia
  modinfo nvidia 2>/dev/null | grep -E "^(version|srcversion|filename):" || echo "nvidia module info not available"
  
  say "\n═══ XORG PROCESSES ═══"
  ps aux | grep -E "(Xorg|gnome-shell|nxnode)" | grep -v grep
  
  say "\n═══ GPU MEMORY BY PROCESS ═══"
  nvidia-smi pmon -c 1 2>/dev/null || echo "Process monitoring not available"
  
  say "\n═══ RECOMMENDATIONS ═══"
  local gpu_count; gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l)
  local driver_ver; driver_ver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)
  local driver_major; driver_major=$(echo "$driver_ver" | cut -d. -f1)
  
  echo "GPUs Detected: $gpu_count"
  echo "Driver Version: $driver_ver"
  
  if [[ "$driver_major" -lt 535 ]] || [[ "$driver_major" -gt 545 ]]; then
    echo ""
    echo "⚠️  WARNING: Driver $driver_ver is outside recommended range (535-545)"
    echo "   Isaac Sim 4.5.0 officially recommends driver 535.129.03"
    echo "   Run: ./scripts/sim_and_data_lake_setup.sh install"
    echo "   (Will install correct driver automatically)"
  fi
  
  if nvidia-smi --query-gpu=persistence_mode --format=csv,noheader | grep -q "Disabled"; then
    echo ""
    echo "💡 TIP: Enable persistence mode to prevent GPU initialization issues:"
    echo "   sudo nvidia-smi -pm 1"
  fi
  
  say "\n═══ CONTINUOUS MONITORING ═══"
  echo "Watch GPU status in real-time:"
  echo "  watch -n 1 nvidia-smi"
  echo ""
  echo "Monitor for GPU disappearance:"
  echo "  while true; do nvidia-smi -L | tee -a gpu-monitor.log; sleep 5; done"
  echo ""
  echo "Check dmesg for errors:"
  echo "  sudo dmesg -w | grep -i nvidia"
}

show_help(){
  cat <<HELP
Robot Simulation + Data Lake Setup Script
Tower configuration for Thor/Spark integration

USAGE:
  bash $SCRIPT_NAME <command>

COMMANDS:
  install            - Full installation (Isaac Sim, ROS 2, MinIO, MLflow)
                       Sets up systemd auto-start and network access
  
  uninstall          - Remove all installed components
                       WARNING: Deletes data! Backup first.
  
  doctor             - System health check
                       Validates installation and service status
  
  gpu-diag           - GPU diagnostics and monitoring
                       Check driver, power, PCI status, kernel messages
                       Troubleshoot GPU disappearance issues
  
  test               - Dry-run validation (no changes)
                       Check system requirements before installing
  
  reconfigure-drives - Change/add MinIO storage drives
                       Requires manual data migration
  
  reconfigure-network - Reconfigure network setup (dual-NIC, IP, firewall)
                        Options: 1) Dual-NIC topology 2) IP/firewall 3) Both
                        Updates documentation for Thor/Spark
  
  reconfigure-credentials - Rotate MinIO and PostgreSQL passwords
                            Generates new random credentials securely
  
  help               - Show this help message

EXAMPLES:
  # Pre-flight check
  bash $SCRIPT_NAME test
  
  # Install everything
  bash $SCRIPT_NAME install
  
  # Check status
  bash $SCRIPT_NAME doctor
  
  # Diagnose GPU issues (disappearing GPU, driver problems)
  bash $SCRIPT_NAME gpu-diag
  
  # Change storage drives (after moving data to new drives)
  bash $SCRIPT_NAME reconfigure-drives
  
  # Switch from single NIC to dual-NIC separate networks
  bash $SCRIPT_NAME reconfigure-network  # Choose option 1
  
  # Update IP address after network change
  bash $SCRIPT_NAME reconfigure-network  # Choose option 2
  
  # Full network reconfiguration (NIC topology + IP + firewall)
  bash $SCRIPT_NAME reconfigure-network  # Choose option 3
  
  # Manual service control
  sudo systemctl status robot-datalake
  sudo systemctl restart robot-datalake

FILES:
  Profile:      $PROFILE_FILE
  Network doc:  $DATA_DIR_DEFAULT/NETWORK_SETUP.md
  Log:          $LOG_FILE
  State:        $MARKER_DIR/

NETWORK:
  MinIO S3:     http://TOWER_IP:$MINIO_PORT
  MinIO UI:     http://TOWER_IP:$MINIO_CONSOLE_PORT
  MLflow:       http://TOWER_IP:$MLFLOW_PORT

For more info, see: $DATA_DIR_DEFAULT/NETWORK_SETUP.md (after install)
HELP
}

case "${1:-help}" in
  install) install ;;
  uninstall) uninstall_all ;;
  doctor) doctor ;;
  test) test_mode ;;
  reconfigure-drives) reconfigure_drives ;;
  reconfigure-network) reconfigure_network ;;
  reconfigure-credentials) reconfigure_credentials ;;
  gpu-diag) gpu_diagnostics ;;
  help|--help|-h) show_help ;;
  *) echo "Unknown command: $1"; echo ""; show_help; exit 1 ;;
esac
