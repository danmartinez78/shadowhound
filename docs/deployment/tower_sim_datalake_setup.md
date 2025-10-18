---
tags: [deployment, simulation, data-lake, tower, infrastructure]
status: active
related: 
  - ../networking/networking_hub.md
  - ../simulation/simulation_hub.md
  - ../hardware/hardware_hub.md
summary: >
  Tower setup guide for simulation and data lake infrastructure. Integrates with Thor/Spark for distributed ML workflows.
---

# Tower: Simulation & Data Lake Setup

**Purpose**: Production-grade installation of Isaac Sim, ROS 2, MinIO data lake, and MLflow tracking server on the Tower workstation.

**Role in System**: Tower serves as the simulation environment and central data repository for the robot system, accessible by Thor (onboard compute) and Spark (training workstation).

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Tower (Sim/Data Lake)                                      │
│  - Isaac Sim 4.5 + Isaac Lab                                │
│  - ROS 2 Humble                                             │
│  - MinIO (S3-compatible object storage)                     │
│  - MLflow (experiment tracking + model registry)            │
│  - Auto-starts on boot via systemd                          │
└─────────────────────────────────────────────────────────────┘
           ↑                    ↑                    ↑
           │                    │                    │
    ┌──────┴─────┐       ┌─────┴──────┐      ┌─────┴──────┐
    │   Thor     │       │   Spark    │      │  Laptop    │
    │  (Robot)   │       │  (DGX)     │      │   (Dev)    │
    │            │       │            │      │            │
    │ - Logs     │       │ - Train    │      │ - Develop  │
    │ - Upload   │       │ - Download │      │ - Test     │
    └────────────┘       └────────────┘      └────────────┘
```

---

## Quick Start

### Installation

```bash
# Download the script
cd ~/
curl -fsSL https://raw.githubusercontent.com/danmartinez78/shadowhound/main/scripts/sim_and_data_lake_setup.sh -o sim_and_data_lake_setup.sh

# Pre-flight check (no changes made)
bash sim_and_data_lake_setup.sh test

# Full install (requires sudo, ~1-2 hours)
bash sim_and_data_lake_setup.sh install

# Check status
bash sim_and_data_lake_setup.sh doctor
```

### Post-Install

```bash
# Add to shell profile
echo "source ~/.robot-simrc" >> ~/.bashrc
exec bash

# Launch Isaac Sim GUI
isaacsim-gui

# Open web UIs
mlflow-ui      # http://localhost:5001
minio-console  # http://localhost:9001
```

---

## What Gets Installed

### Simulation Stack
- **Isaac Sim 4.5**: NVIDIA's robot simulator (pip distribution)
- **Isaac Lab**: Reinforcement learning framework (source install)
- **ROS 2 Humble**: Robot middleware for Go2 integration
- **go2_omniverse**: Unitree Go2 simulation assets (added_copter branch)

### Data Infrastructure
- **MinIO**: S3-compatible object storage (multi-drive support)
  - Buckets: `models`, `datasets`, `logs`, `mlflow`
  - Ports: 9000 (API), 9001 (Console)
- **MLflow**: Experiment tracking and model registry
  - PostgreSQL backend for metadata
  - MinIO backend for artifacts
  - Port: 5001

### Development Tools
- **Python**: ipython, jupyter, tensorboard, matplotlib, pandas
- **Monitoring**: htop, iotop, nvtop, nethogs, ncdu
- **Storage Tools**: s3cmd, rclone
- **Network Tools**: nmap, mtr, traceroute

### System Integration
- **Systemd Service**: `robot-datalake.service` (auto-starts on boot)
- **Firewall Rules**: Ports open for Thor/Spark (192.168.x.x, 10.x.x.x)
- **Cache Redirection**: Omniverse, HF, Torch caches to data volume

---

## Optional Extensions

### LeRobot SO-ARM 101 (Robotic Arm)

Add low-cost robotic arm training to your Tower setup - **completely independent** of the Go2 robot:

**Independence**:
- ✅ **Separate hardware**: USB robotic arm (not networked)
- ✅ **Separate control**: Feetech SDK (not ROS2)
- ✅ **Separate workflows**: LeRobot training (not go2_ros2_sdk)
- ✅ **Can use alone**: Full manipulation research without Go2
- ✅ **Optional integration**: Combine with Go2 later (not required)

**What it adds**:
- Imitation learning for manipulation tasks
- USB-based robotic arm control (no network conflicts)
- Shares MinIO, MLflow, and conda environment
- Train in minutes on recorded demonstrations

**Quick install**:
```bash
# From existing conda environment
conda activate env_isaaclab
pip install lerobot[feetech]  # ~2 minutes
```

**Hardware needed**:
- SO-ARM 101 kit (~€228 for leader + follower arms)
- USB motor bus adapters (included)
- 3D printed parts

**Use cases (independent)**:
- 🤖 Pick and place tasks (tabletop manipulation)
- 🤖 Assembly operations (part mating, insertion)
- 🤖 Manipulation research (imitation learning experiments)
- 🤖 Pouring, scooping, stacking (dexterous tasks)

**Use cases (optional Go2 integration)**:
- 🚶🤖 Mobile manipulation (Go2 brings objects to arm)
- 🚶🤖 Warehouse tasks (Go2 navigates, arm manipulates)

**Full guide**: [LeRobot SO-ARM 101 Setup](tower_lerobot_soarm101_setup.md)

**Integration guide** (optional): [Combined Go2 + SO-ARM Workflows](combined_go2_soarm_workflows.md)

---

## Service Management

### Start/Stop Services

```bash
# Start services
sudo systemctl start robot-datalake

# Stop services
sudo systemctl stop robot-datalake

# Restart services
sudo systemctl restart robot-datalake

# Check status
sudo systemctl status robot-datalake

# View logs
sudo journalctl -u robot-datalake -f
```

### Manual Docker Control

```bash
# Navigate to MinIO directory
cd /srv/robot-data/minio  # or your chosen data dir

# Check running services
docker compose ps

# View logs
docker compose logs -f minio
docker compose logs -f mlflow

# Restart individual service
docker compose restart minio
docker compose restart mlflow
```

---

## Reconfiguration Commands

### Change Storage Drives

If you need to add or change MinIO storage drives:

```bash
bash scripts/sim_and_data_lake_setup.sh reconfigure-drives
```

**What it does**: Updates Docker Compose to use different storage paths. **Requires manual data migration**.

### Update Network IP

If Tower's IP address changes:

```bash
bash scripts/sim_and_data_lake_setup.sh reconfigure-network
```

**What it does**: Detects new IP, updates firewall rules, regenerates network documentation.

### Rotate Credentials

To generate new random credentials (security best practice):

```bash
bash scripts/sim_and_data_lake_setup.sh reconfigure-credentials
```

**What it does**:
- Backs up old credentials
- Generates new cryptographic random passwords
- Restarts services with new credentials
- Provides Thor/Spark update instructions

**⚠️ IMPORTANT**: After rotation, you **must** update Thor/Spark configuration with new credentials.

See: [Tower Security & Credentials Guide](tower_security_credentials.md) for details.

---

## Network Configuration

### Tower Services

| Service | Port | Local URL | Network URL |
|---------|------|-----------|-------------|
| MinIO S3 API | 9000 | http://localhost:9000 | http://TOWER_IP:9000 |
| MinIO Console | 9001 | http://localhost:9001 | http://TOWER_IP:9001 |
| MLflow | 5001 | http://localhost:5001 | http://TOWER_IP:5001 |

### Find Tower IP

```bash
# From Tower
hostname -I | awk '{print $1}'

# Or read from install
cat ~/.go2_stack_state/tower_ip.txt
```

### Firewall Configuration

Firewall rules automatically configured for:
- **Local networks**: 192.168.0.0/16, 10.0.0.0/8
- **Ports**: 9000, 9001, 5001

```bash
# Check firewall status
sudo ufw status

# Allow additional IP/network
sudo ufw allow from 172.16.0.0/12 to any port 9000

# Reload rules
sudo ufw reload
```

---

## Thor/Spark Integration

### Environment Setup on Thor/Spark

Add to `~/.bashrc` on Thor or Spark:

```bash
# Tower connection (replace TOWER_IP)
export TOWER_IP="192.168.10.116"  # Example

# MinIO/S3 configuration
export AWS_ACCESS_KEY_ID="<from Tower ~/.go2_stack_state/minio_creds.txt>"
export AWS_SECRET_ACCESS_KEY="<from Tower ~/.go2_stack_state/minio_creds.txt>"
export MLFLOW_S3_ENDPOINT_URL="http://$TOWER_IP:9000"

# MLflow tracking
export MLFLOW_TRACKING_URI="http://$TOWER_IP:5001"
```

### Test Connectivity from Thor/Spark

```bash
# Test MinIO health
curl http://$TOWER_IP:9000/minio/health/live

# Test MLflow
curl http://$TOWER_IP:5001/health

# List buckets
aws --endpoint-url http://$TOWER_IP:9000 s3 ls

# Test with Python
python3 -c "
import boto3
s3 = boto3.client('s3', endpoint_url='http://$TOWER_IP:9000')
print(s3.list_buckets())
"
```

### Upload/Download Examples

```bash
# Upload trajectory log from Thor
aws --endpoint-url http://$TOWER_IP:9000 \
    s3 cp trajectory_2025-10-18.json s3://logs/

# Upload trained model from Spark
aws --endpoint-url http://$TOWER_IP:9000 \
    s3 cp model.safetensors s3://models/go2-nav-v1.safetensors

# Download dataset on Spark for training
aws --endpoint-url http://$TOWER_IP:9000 \
    s3 sync s3://datasets/go2-trajectories/ ./data/

# Sync with rclone (faster for large transfers)
rclone sync /local/datasets/ tower-minio:datasets/ --progress
```

---

## MLflow Usage

### From Thor (Logging Metrics)

```python
import mlflow

# Connect to Tower MLflow
mlflow.set_tracking_uri("http://TOWER_IP:5001")

# Log a mission
with mlflow.start_run(run_name="mission_kitchen_explore"):
    mlflow.log_param("mission_type", "exploration")
    mlflow.log_param("duration_s", 120)
    mlflow.log_metric("distance_traveled_m", 15.3)
    mlflow.log_metric("success", 1)
    mlflow.log_artifact("trajectory.json")
```

### From Spark (Training Experiments)

```python
import mlflow
import mlflow.pytorch

mlflow.set_tracking_uri("http://TOWER_IP:5001")

with mlflow.start_run(run_name="nav_policy_v1"):
    mlflow.log_params({
        "learning_rate": 3e-4,
        "batch_size": 256,
        "architecture": "PPO",
    })
    
    # Training loop
    for epoch in range(100):
        loss = train_step()
        mlflow.log_metric("loss", loss, step=epoch)
    
    # Save model to MinIO via MLflow
    mlflow.pytorch.log_model(model, "model")
```

### Query Experiments

```python
import mlflow

mlflow.set_tracking_uri("http://TOWER_IP:5001")

# Get best run
runs = mlflow.search_runs(
    experiment_names=["navigation"],
    filter_string="metrics.success = 1",
    order_by=["metrics.distance_traveled_m DESC"]
)

print(runs[["run_id", "params.mission_type", "metrics.distance_traveled_m"]].head())
```

---

## Isaac Sim Usage

### Launch GUI

```bash
# From Tower terminal
isaacsim-gui

# Or manually
conda activate env_isaaclab
isaacsim isaacsim.exp.full.kit
```

### Headless Mode (for Rendering Jobs)

```bash
isaacsim-headless

# Or with script
conda activate env_isaaclab
isaacsim --headless --/isaac/startup/startup_script=/path/to/script.py
```

### Isaac Lab Workflows

```bash
cd ~/workspace/IsaacLab

# Test installation
./isaaclab.sh -p source/standalone/tutorials/00_sim/create_empty.py

# Run Go2 environment
./isaaclab.sh -p source/standalone/environments/state_machine/go2_exploration.py
```

---

## Data Management

### Bucket Organization

```
models/           - Trained model checkpoints (.safetensors, .pt)
datasets/         - Training datasets (trajectories, images)
  ├── go2-nav/
  ├── go2-manipulation/
  └── sim-rollouts/
logs/             - Robot telemetry and mission logs
mlflow/           - MLflow artifacts (auto-managed)
```

### Storage Policies

- **Retention**: Logs older than 90 days auto-archived (configure via MinIO lifecycle)
- **Replication**: Single-node setup (use >=4 drives for erasure coding)
- **Backup**: Use `rclone` to sync to external storage

### Manage Storage

```bash
# Check bucket sizes
aws --endpoint-url http://localhost:9000 s3 ls --summarize --recursive s3://logs/

# Delete old logs
aws --endpoint-url http://localhost:9000 s3 rm s3://logs/2025-01/ --recursive

# Copy bucket to backup
rclone sync tower-minio:datasets/ /backup/datasets/ --progress
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check Docker daemon
sudo systemctl status docker

# Check compose file
cat /srv/robot-data/minio/docker-compose.yml

# Manual start for debugging
cd /srv/robot-data/minio
docker compose up  # (without -d to see logs)
```

### Network Connection Issues

```bash
# From Thor/Spark, test connectivity
ping TOWER_IP
telnet TOWER_IP 9000
curl http://TOWER_IP:9000/minio/health/live

# Check Tower firewall
sudo ufw status verbose

# Check Tower services listening
sudo lsof -i :9000
sudo lsof -i :5001
```

### MinIO Access Denied

```bash
# Verify credentials match on both sides
# Tower:
cat /srv/robot-data/minio/.env

# Thor/Spark:
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY

# Test with mc (MinIO client)
mc alias set tower http://TOWER_IP:9000 $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY
mc ls tower/
```

### Disk Full

```bash
# Check disk usage
df -h
ncdu /srv/robot-data

# Clean Docker volumes
docker system prune -a --volumes

# Archive old logs
aws --endpoint-url http://localhost:9000 s3 sync s3://logs/ /backup/logs/
aws --endpoint-url http://localhost:9000 s3 rm s3://logs/2025-01/ --recursive
```

### Isaac Sim GPU Issues

```bash
# Check GPU driver
nvidia-smi

# Check Vulkan (required for Isaac Sim)
vulkaninfo | grep "deviceName"

# Reinstall driver if needed
sudo ubuntu-drivers autoinstall
sudo reboot
```

---

## Maintenance

### Regular Tasks

**Weekly**:
- Check disk space: `df -h /srv/robot-data`
- Review service logs: `docker compose logs --tail=100`
- Backup credentials: `cp /srv/robot-data/minio/.env ~/backup/`

**Monthly**:
- Update packages: `sudo apt update && sudo apt upgrade`
- Archive old logs to external storage
- Review MLflow experiments and clean up test runs

**Quarterly**:
- Test restore from backup
- Review and update firewall rules
- Update Isaac Sim / Isaac Lab to latest versions

### Backup Strategy

```bash
# Critical files to backup
/srv/robot-data/minio/.env                  # Credentials
/srv/robot-data/minio/docker-compose.yml    # Service config
~/.robot-simrc                               # Environment config

# Data to backup (large)
/srv/robot-data/minio/data/                 # MinIO data (or drives)
/srv/robot-data/mlflow/pgdata/              # MLflow metadata

# Backup command
tar -czf tower-backup-$(date +%F).tar.gz \
    /srv/robot-data/minio/.env \
    /srv/robot-data/minio/docker-compose.yml \
    ~/.robot-simrc

# For large data, use rclone to cloud/NAS
rclone sync /srv/robot-data/minio/data/ backup-remote:robot-data/
```

---

## Uninstall

**WARNING**: This removes all data. Backup first!

```bash
# Run uninstaller (prompts for each step)
bash sim_and_data_lake_setup.sh uninstall

# Manual cleanup if needed
sudo systemctl stop robot-datalake
sudo systemctl disable robot-datalake
sudo rm /etc/systemd/system/robot-datalake.service
```

---

## References

### Documentation
- **Installation Script**: `scripts/sim_and_data_lake_setup.sh`
- **Network Setup**: Generated at `/srv/robot-data/NETWORK_SETUP.md`
- **Install Log**: `~/.go2_stack_install.log`

### External Links
- [Isaac Sim Docs](https://docs.omniverse.nvidia.com/isaacsim/latest/)
- [Isaac Lab GitHub](https://github.com/isaac-sim/IsaacLab)
- [MinIO Docs](https://min.io/docs/)
- [MLflow Docs](https://mlflow.org/docs/latest/index.html)
- [ROS 2 Humble](https://docs.ros.org/en/humble/)

### Internal Links
- [[../hardware/hardware_hub|Hardware Hub]]
- [[../simulation/simulation_hub|Simulation Hub]]
- [[../networking/networking_hub|Networking Hub]]

---

**Last Updated**: 2025-10-18  
**Maintained By**: ShadowHound Team
