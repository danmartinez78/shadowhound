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
  
  # Internet connectivity
  if curl -fsSL --connect-timeout 5 https://google.com >/dev/null 2>&1; then
    ok "Internet: connected"
  else
    warn "Internet: connectivity issue (required for downloads)"
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
  run "sudo apt-get update"
  run "sudo apt-get install -y curl wget git unzip zip jq ca-certificates build-essential cmake pkg-config apt-transport-https gnupg software-properties-common"
}

install_dev_tools(){
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
}

install_driver_if_needed(){
  say "\n--- NVIDIA driver ---"
  if command -v nvidia-smi >/dev/null; then
    local v; v="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1 || true)"
    say "Detected driver: $v"
  else
    run "sudo add-apt-repository -y ppa:graphics-drivers/ppa"
    run "sudo apt-get update"
    run "sudo ubuntu-drivers autoinstall"
    warn "A reboot may be required before continuing. Re-run: bash $SCRIPT_NAME install"
    exit 0
  fi
}

install_docker_nvidia(){
  say "\n--- Docker + NVIDIA Container Toolkit ---"
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
      warn "Docker installed and user added to docker group"
      warn "You must log out and log back in for group membership to take effect"
      warn "Or run: newgrp docker"
      warn "Then re-run: bash $SCRIPT_NAME install"
      exit 0
    else
      warn "User not in docker group. This may cause permission errors."
      warn "Run: sudo usermod -aG docker $USER && newgrp docker"
    fi
  fi
  
  run "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
  run "curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null"
  run "sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit"
  run "sudo nvidia-ctk runtime configure --runtime=docker || true"
  run "sudo systemctl restart docker"
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
}

create_env_and_install_isaacsim(){
  say "\n--- Isaac Sim 4.5 (pip) ---"
  say "⏱️  This may take 15-30 minutes (downloading ~30GB)..."
  # shellcheck source=/dev/null
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
  conda env list | awk '{print $1}' | grep -q "^${ENV_NAME}\$" || run "conda create -y -n \"$ENV_NAME\" python=${PY_VER}"
  run "conda run -n \"$ENV_NAME\" python -V"

  export OMNI_KIT_ACCEPT_EULA=YES  # accept Omniverse EULA for non-interactive pip install

  say "Upgrading pip..."
  run "conda run -n \"$ENV_NAME\" python -m pip install --upgrade pip"
  
  say "Installing Isaac Sim (this is the long step - be patient)..."
  run "conda run -n \"$ENV_NAME\" python -m pip install \"isaacsim${ISAACSIM_PIP_EXTRAS}==${ISAACSIM_PIP_VERSION}\" --extra-index-url https://pypi.nvidia.com"

  # Warm caches to data dir later; capture env site-packages for sensor patching
  local env_site
  env_site="$(conda run -n \"$ENV_NAME\" python -c 'import sys;print(next(p for p in sys.path if p.endswith(\"site-packages\")))' 2>/dev/null || true)"
  echo "$env_site" > "$MARKER_DIR/env_site.txt"
  ok "Isaac Sim installed successfully"
}

install_ros2_humble(){
  say "\n--- ROS 2 Humble ---"
  run "sudo apt-get update"
  run "sudo apt-get install -y curl gnupg lsb-release"
  run "sudo mkdir -p /etc/apt/keyrings"
  run "curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | sudo gpg --dearmor -o /etc/apt/keyrings/ros-archive-keyring.gpg"
  run "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/ros2.list >/dev/null"
  run "sudo apt-get update && sudo apt-get install -y ros-${ROS_DISTRO}-desktop ros-dev-tools"
}

clone_isaaclab(){
  say "\n--- Isaac Lab (source) ---"
  local ws="$HOME/workspace"; run "mkdir -p \"$ws\""
  if [[ -d "$ws/IsaacLab/.git" ]]; then run "git -C \"$ws/IsaacLab\" pull --ff-only"
  else run "git clone https://github.com/isaac-sim/IsaacLab.git \"$ws/IsaacLab\""; fi
  # shellcheck source=/dev/null
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
  run "conda run -n \"$ENV_NAME\" bash -lc 'cd \"$ws/IsaacLab\" && ./isaaclab.sh --install'"
}

clone_go2_omniverse_and_patch(){
  say "\n--- go2_omniverse (added_copter) ---"
  local ws="$HOME/workspace"; run "mkdir -p \"$ws\""
  if [[ -d "$ws/go2_omniverse/.git" ]]; then
    run "git -C \"$ws/go2_omniverse\" fetch && git -C \"$ws/go2_omniverse\" checkout added_copter && git -C \"$ws/go2_omniverse\" pull --ff-only"
  else
    run "git clone --branch added_copter https://github.com/abizovnuralem/go2_omniverse \"$ws/go2_omniverse\""
  fi
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
}

pick_data_dir(){
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
  say "\n--- Select one or more mounted directories to back MinIO ---"
  say "Tip: Use >=4 drives of similar size for erasure-coded resilience. (Smaller drive caps total.)"
  run "lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL | sed '1!b; s/.*/(mounted paths you might choose are in the MOUNTPOINT column) &/' || true"
  local paths=()
  while :; do
    read -r -p "Add a mounted path (ENTER to finish, e.g., /mnt/disk1): " p
    [[ -z "${p:-}" ]] && break
    
    # Validate directory exists
    if [[ ! -d "$p" ]]; then
      warn "Not a directory: $p"
      continue
    fi
    
    # Validate writable
    if [[ ! -w "$p" ]]; then
      warn "Not writable: $p (check permissions)"
      continue
    fi
    
    # Check available space
    local space_gb; space_gb=$(df -BG "$p" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G' || echo "0")
    if ((space_gb < 50)); then
      warn "$p has only ${space_gb}GB free (50GB+ recommended per drive)"
      confirm "Use anyway?" || continue
    else
      ok "$p: ${space_gb}GB available"
    fi
    
    paths+=("$p")
  done
  if ((${#paths[@]}==0)); then
    warn "No drives selected. Using base data dir as a single drive."
    paths+=("${DATA_DIR}/lake") ; run "mkdir -p \"${DATA_DIR}/lake\""
  fi
  printf "%s\n" "${paths[@]}" > "$MARKER_DIR/minio_drives.txt"
  ok "Drives selected: ${paths[*]}"
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
  local paths=() i=1 vlines="" dargs=""
  mapfile -t paths < "$MARKER_DIR/minio_drives.txt"
  run "mkdir -p \"$MINIO_DIR\" \"$MINIO_DIR/config\" \"$MINIO_DIR/data\" \"$DATA_DIR/mlflow\" \"$DATA_DIR/mlflow/pgdata\""
  # credentials - generate secure random passwords
  local MINIO_USER MINIO_PASS POSTGRES_PASSWORD
  MINIO_USER="$(openssl rand -hex 8)"
  MINIO_PASS="$(openssl rand -hex 16)"
  POSTGRES_PASSWORD="$(openssl rand -hex 16)"
  
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

  # Compose file
  cat > "$MINIO_COMPOSE_YAML" <<YAML
services:
  minio:
    image: minio/minio:latest
    container_name: minio
    restart: unless-stopped
    env_file: [.env]
    command: server --console-address ":9001"${dargs}
    volumes:
${vlines}    ports:
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
    entrypoint: ["/bin/sh","-c"]
    command: >
      mc alias set local http://minio:9000 $$MINIO_ROOT_USER $$MINIO_ROOT_PASSWORD &&
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
    command: >
      sh -c "mlflow server --host 0.0.0.0 --port 5001
      --backend-store-uri postgresql+psycopg2://mlflow:$$POSTGRES_PASSWORD@mlflow-db:5432/mlflow
      --default-artifact-root s3://mlflow"
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
    source "/opt/ros/${ROS_DISTRO}/setup.bash"
    if ros2 --version >/dev/null 2>&1; then
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
  local cmd; cmd="$(compose_cmd)"; cmd="${cmd:-docker compose}"

  # Bring down MLflow/MinIO
  if [[ -f "$MINIO_COMPOSE_YAML" ]]; then
    (cd "$MINIO_DIR" && $cmd down -v || true)
  else
    if [[ -f "$DATA_DIR_DEFAULT/minio/docker-compose.yml" ]]; then
      (cd "$DATA_DIR_DEFAULT/minio" && $cmd down -v || true)
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
  echo "$(date -Iseconds)" > "$MARKER_DIR/install_started.txt"
  
  require_ubuntu_2204
  ensure_base_tools
  install_driver_if_needed
  install_docker_nvidia
  install_miniconda
  create_env_and_install_isaacsim
  install_ros2_humble
  clone_isaaclab
  clone_go2_omniverse_and_patch
  install_dev_tools
  pick_data_dir
  link_caches_to_data_dir
  pick_minio_drives
  generate_minio_mlflow_compose
  setup_systemd_services
  configure_firewall_for_network
  write_network_config_doc
  write_profile_rc
  smoke_tests
  
  # Mark install complete
  echo "$(date -Iseconds)" > "$MARKER_DIR/install_completed.txt"
  
  ok "\n╔════════════════════════════════════════════════════════════════╗"
  ok "║  Installation Complete!                                        ║"
  ok "╚════════════════════════════════════════════════════════════════╝\n"
  
  local tower_ip; tower_ip=$(cat "$MARKER_DIR/tower_ip.txt" 2>/dev/null || echo "TOWER_IP")
  
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
  
  # Show current network config
  local old_ip; old_ip=$(cat "$MARKER_DIR/tower_ip.txt" 2>/dev/null || echo "unknown")
  say "Current Tower IP: $old_ip"
  
  # Detect current IP
  local current_ip; current_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1 || echo "unknown")
  say "Detected IP: $current_ip"
  
  if [[ "$current_ip" != "$old_ip" ]]; then
    say "\n⚠️  IP address has changed! Updating configuration..."
  else
    say "\nIP unchanged, but you can force a full network reconfiguration."
  fi
  
  confirm "Update network configuration?" || exit 0
  
  # Update IP in state
  echo "$current_ip" > "$MARKER_DIR/tower_ip.txt"
  
  # Regenerate firewall rules
  configure_firewall_for_network
  
  # Regenerate network documentation
  write_network_config_doc
  
  ok "Network configuration updated."
  say "\nNew Tower IP: $current_ip"
  say "Network guide updated: $DATA_DIR/NETWORK_SETUP.md"
  say ""
  say "⚠️  UPDATE Thor/Spark configuration:"
  say "  1. Update TOWER_IP in ~/.bashrc on Thor/Spark"
  say "  2. Update MLFLOW_TRACKING_URI and MLFLOW_S3_ENDPOINT_URL"
  say "  3. Test connectivity: curl http://$current_ip:$MINIO_PORT/minio/health/live"
  say ""
  say "See: $DATA_DIR/NETWORK_SETUP.md for details"
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
  
  test               - Dry-run validation (no changes)
                       Check system requirements before installing
  
  reconfigure-drives - Change/add MinIO storage drives
                       Requires manual data migration
  
  reconfigure-network - Update IP address and firewall rules
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
  
  # Change storage drives (after moving data to new drives)
  bash $SCRIPT_NAME reconfigure-drives
  
  # Update IP address (after network change)
  bash $SCRIPT_NAME reconfigure-network
  
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
  help|--help|-h) show_help ;;
  *) echo "Unknown command: $1"; echo ""; show_help; exit 1 ;;
esac
