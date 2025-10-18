---
tags: [deployment, integration, thor, spark, tower]
status: draft
related: [tower_sim_datalake_setup.md]
summary: >
  Step-by-step guide for integrating Thor (robot AGX) and Spark (DGX training) with Tower (sim/data lake).
---

# Tower-Thor-Spark Integration Guide

## Purpose

This guide provides detailed step-by-step instructions for connecting Thor (robot onboard AGX) and Spark (DGX training workstation) to Tower's MinIO and MLflow services.

**Target Audience**: Developers setting up Thor/Spark machines to access Tower's data lake and experiment tracking.

**Prerequisites**:
- Tower fully installed and running (see `tower_sim_datalake_setup.md`)
- Thor/Spark machines on same network as Tower (192.168.x.x or 10.x.x.x)
- Network connectivity between machines
- Sudo access on Thor/Spark

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Network Architecture                     │
└─────────────────────────────────────────────────────────────────┘

  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
  │    Thor      │         │    Spark     │         │   Laptop     │
  │  (Robot AGX) │         │   (DGX A100) │         │   (Dev)      │
  │              │         │              │         │              │
  │ • Sensors    │         │ • Training   │         │ • ROS nodes  │
  │ • Vision     │         │ • Fine-tune  │         │ • Web UI     │
  │ • Control    │         │ • Eval       │         │ • Dev tools  │
  └──────┬───────┘         └──────┬───────┘         └──────┬───────┘
         │                        │                        │
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  │
                         192.168.x.x / 10.x.x.x
                                  │
                       ┌──────────▼──────────┐
                       │       Tower         │
                       │   (Sim + Data Lake) │
                       │                     │
                       │ ┌─────────────────┐ │
                       │ │  MinIO (S3)     │ │ :9000 (API)
                       │ │  - Sensor data  │ │ :9001 (Console)
                       │ │  - Trajectories │ │
                       │ │  - Checkpoints  │ │
                       │ └─────────────────┘ │
                       │                     │
                       │ ┌─────────────────┐ │
                       │ │  MLflow         │ │ :5001 (UI)
                       │ │  - Experiments  │ │
                       │ │  - Metrics      │ │
                       │ │  - Models       │ │
                       │ └─────────────────┘ │
                       │                     │
                       │ ┌─────────────────┐ │
                       │ │  Isaac Sim      │ │
                       │ │  - Training gen │ │
                       │ │  - Testing      │ │
                       │ └─────────────────┘ │
                       └─────────────────────┘
```

**Data Flows**:
1. **Thor → Tower**: Sensor data upload (images, LiDAR, IMU), experiment logs
2. **Spark → Tower**: Training checkpoints, evaluation metrics, fine-tuned models
3. **Tower → Thor/Spark**: Dataset download, checkpoint download, model artifacts

---

## Quick Start Checklist

- [ ] Tower installation complete (`bash sim_and_data_lake_setup.sh doctor`)
- [ ] Network connectivity confirmed (ping Tower from Thor/Spark)
- [ ] Credentials transferred from Tower to Thor/Spark
- [ ] AWS CLI / boto3 installed on Thor/Spark
- [ ] MLflow client installed on Thor/Spark
- [ ] Environment variables configured
- [ ] Connectivity tested (curl, aws s3 ls, python)
- [ ] Test upload/download successful
- [ ] Test MLflow experiment logged

---

## Step 1: Get Tower Credentials

On Tower, retrieve the network configuration document:

```bash
# On Tower
cat /srv/robot-data/NETWORK_SETUP.md
```

This document contains:
- Tower IP address
- MinIO access key and secret key
- MLflow tracking URI
- Service ports
- Example connection commands

**Example output**:
```
Tower IP: 192.168.10.100

MinIO S3 API:     http://192.168.10.100:9000
MinIO Console UI: http://192.168.10.100:9001
MLflow UI:        http://192.168.10.100:5001

Credentials:
  MinIO Access Key: minioadmin
  MinIO Secret Key: minio123
```

**⚠️ Security**: Transfer credentials securely (SSH, encrypted channel). Do not commit to git!

---

## Step 2: Transfer Credentials to Thor/Spark

### Option A: Manual Copy (Secure)

```bash
# On Tower, retrieve credentials
TOWER_IP=$(hostname -I | awk '{print $1}')
MINIO_ACCESS_KEY=$(grep MINIO_ROOT_USER /srv/robot-data/minio/.env | cut -d= -f2)
MINIO_SECRET_KEY=$(grep MINIO_ROOT_PASSWORD /srv/robot-data/minio/.env | cut -d= -f2)

echo "Tower IP: $TOWER_IP"
echo "MinIO Access Key: $MINIO_ACCESS_KEY"
echo "MinIO Secret Key: $MINIO_SECRET_KEY"
```

Then **manually** SSH to Thor/Spark and configure.

### Option B: Automated Transfer (for trusted networks)

```bash
# On Tower
TOWER_IP=$(hostname -I | awk '{print $1}')
MINIO_ACCESS_KEY=$(grep MINIO_ROOT_USER /srv/robot-data/minio/.env | cut -d= -f2)
MINIO_SECRET_KEY=$(grep MINIO_ROOT_PASSWORD /srv/robot-data/minio/.env | cut -d= -f2)

# SSH to Thor and configure (replace THOR_IP)
ssh daniel@THOR_IP "bash -s" <<EOF
cat >> ~/.bashrc <<'BASHRC_END'

# Tower Data Lake Configuration
export TOWER_IP=$TOWER_IP
export AWS_ACCESS_KEY_ID=$MINIO_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$MINIO_SECRET_KEY
export AWS_ENDPOINT_URL=http://\$TOWER_IP:9000

# MLflow Configuration
export MLFLOW_TRACKING_URI=http://\$TOWER_IP:5001
export MLFLOW_S3_ENDPOINT_URL=http://\$TOWER_IP:9000

BASHRC_END
source ~/.bashrc
echo "Configuration added to ~/.bashrc"
EOF
```

Repeat for Spark, replacing `THOR_IP` with `SPARK_IP`.

---

## Step 3: Configure Environment Variables

On **Thor** and **Spark**, add to `~/.bashrc`:

```bash
# Tower Data Lake Configuration
export TOWER_IP=192.168.10.100          # Replace with actual Tower IP
export AWS_ACCESS_KEY_ID=minioadmin      # From Tower credentials
export AWS_SECRET_ACCESS_KEY=minio123    # From Tower credentials
export AWS_ENDPOINT_URL=http://$TOWER_IP:9000

# MLflow Configuration
export MLFLOW_TRACKING_URI=http://$TOWER_IP:5001
export MLFLOW_S3_ENDPOINT_URL=http://$TOWER_IP:9000
```

Source the file:

```bash
source ~/.bashrc
```

**Validation**:
```bash
echo "Tower IP: $TOWER_IP"
echo "AWS Endpoint: $AWS_ENDPOINT_URL"
echo "MLflow Tracking URI: $MLFLOW_TRACKING_URI"
```

---

## Step 4: Install AWS CLI and Python Clients

### Install AWS CLI

```bash
# Ubuntu/Debian
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### Install Python Clients

```bash
pip install boto3 mlflow
```

**Versions**:
- `boto3>=1.26.0` (AWS SDK for Python)
- `mlflow>=2.0.0` (Experiment tracking)

---

## Step 5: Test Network Connectivity

### Ping Test

```bash
ping -c 3 $TOWER_IP
```

**Expected**: 3 successful pings with <10ms latency (local network).

### Port Accessibility

```bash
# MinIO API (S3)
nc -zv $TOWER_IP 9000

# MinIO Console
nc -zv $TOWER_IP 9001

# MLflow
nc -zv $TOWER_IP 5001
```

**Expected**: All ports report "Connection succeeded".

### HTTP Health Checks

```bash
# MinIO health
curl -f http://$TOWER_IP:9000/minio/health/live
# Expected: 200 OK (no output)

# MinIO Console
curl -I http://$TOWER_IP:9001
# Expected: 200 OK (HTML header)

# MLflow
curl -I http://$TOWER_IP:5001
# Expected: 200 OK (MLflow UI)
```

---

## Step 6: Test S3 Access with AWS CLI

### Configure AWS CLI

```bash
aws configure
```

Enter credentials:
- AWS Access Key ID: `<MINIO_ACCESS_KEY>`
- AWS Secret Access Key: `<MINIO_SECRET_KEY>`
- Default region: `us-east-1` (arbitrary, MinIO doesn't care)
- Default output format: `json`

### List Buckets

```bash
aws s3 ls --endpoint-url $AWS_ENDPOINT_URL
```

**Expected output**:
```
2025-10-18 12:00:00 sensor-data
2025-10-18 12:00:00 trajectories
2025-10-18 12:00:00 checkpoints
2025-10-18 12:00:00 mlflow
```

### Test Upload (Thor)

```bash
# Create test file
echo "Test data from Thor $(date)" > /tmp/test_thor.txt

# Upload to sensor-data bucket
aws s3 cp /tmp/test_thor.txt s3://sensor-data/test_thor.txt --endpoint-url $AWS_ENDPOINT_URL

# Verify upload
aws s3 ls s3://sensor-data/ --endpoint-url $AWS_ENDPOINT_URL
```

**Expected**: `test_thor.txt` listed.

### Test Download (Spark)

```bash
# Download test file uploaded from Thor
aws s3 cp s3://sensor-data/test_thor.txt /tmp/test_thor.txt --endpoint-url $AWS_ENDPOINT_URL

# Verify content
cat /tmp/test_thor.txt
```

**Expected**: "Test data from Thor [timestamp]"

---

## Step 7: Test S3 Access with Python (boto3)

Create test script `test_s3.py`:

```python
import boto3
import os
from datetime import datetime

# Configuration from environment
endpoint = os.getenv("AWS_ENDPOINT_URL")
access_key = os.getenv("AWS_ACCESS_KEY_ID")
secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")

print(f"Endpoint: {endpoint}")
print(f"Access Key: {access_key[:8]}...")

# Create S3 client
s3 = boto3.client(
    's3',
    endpoint_url=endpoint,
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_key
)

# List buckets
print("\n=== Buckets ===")
response = s3.list_buckets()
for bucket in response['Buckets']:
    print(f"  {bucket['Name']}")

# Test upload
bucket = 'sensor-data'
key = f'test_python_{datetime.now().strftime("%Y%m%d_%H%M%S")}.txt'
data = f"Test from Python at {datetime.now()}"

print(f"\n=== Upload ===")
print(f"Uploading to s3://{bucket}/{key}")
s3.put_object(Bucket=bucket, Key=key, Body=data.encode('utf-8'))
print("Upload successful")

# Test download
print(f"\n=== Download ===")
print(f"Downloading s3://{bucket}/{key}")
response = s3.get_object(Bucket=bucket, Key=key)
content = response['Body'].read().decode('utf-8')
print(f"Content: {content}")

print("\n✅ S3 access test passed")
```

Run:

```bash
python test_s3.py
```

**Expected output**:
```
Endpoint: http://192.168.10.100:9000
Access Key: minioadm...

=== Buckets ===
  sensor-data
  trajectories
  checkpoints
  mlflow

=== Upload ===
Uploading to s3://sensor-data/test_python_20251018_120000.txt
Upload successful

=== Download ===
Downloading s3://sensor-data/test_python_20251018_120000.txt
Content: Test from Python at 2025-10-18 12:00:00

✅ S3 access test passed
```

---

## Step 8: Test MLflow Experiment Logging

Create test script `test_mlflow.py`:

```python
import mlflow
import os
from datetime import datetime

# Configuration from environment
tracking_uri = os.getenv("MLFLOW_TRACKING_URI")
s3_endpoint = os.getenv("MLFLOW_S3_ENDPOINT_URL")

print(f"MLflow Tracking URI: {tracking_uri}")
print(f"MLflow S3 Endpoint: {s3_endpoint}")

# Set tracking URI
mlflow.set_tracking_uri(tracking_uri)

# Create experiment
experiment_name = "test_integration"
try:
    experiment_id = mlflow.create_experiment(experiment_name)
    print(f"\nCreated experiment: {experiment_name} (ID: {experiment_id})")
except Exception as e:
    # Experiment already exists
    experiment_id = mlflow.get_experiment_by_name(experiment_name).experiment_id
    print(f"\nUsing existing experiment: {experiment_name} (ID: {experiment_id})")

# Start run
with mlflow.start_run(experiment_id=experiment_id, run_name=f"test_run_{datetime.now().strftime('%Y%m%d_%H%M%S')}"):
    # Log parameters
    mlflow.log_param("test_param", "test_value")
    mlflow.log_param("source_machine", os.uname().nodename)
    
    # Log metrics
    mlflow.log_metric("test_metric", 0.95)
    mlflow.log_metric("accuracy", 0.87)
    
    # Log text artifact
    with open("test_artifact.txt", "w") as f:
        f.write(f"Test artifact from {os.uname().nodename} at {datetime.now()}")
    mlflow.log_artifact("test_artifact.txt")
    
    print("\nLogged:")
    print("  - Parameters: test_param, source_machine")
    print("  - Metrics: test_metric, accuracy")
    print("  - Artifact: test_artifact.txt")

print(f"\n✅ MLflow test passed")
print(f"View experiment at: {tracking_uri}/#/experiments/{experiment_id}")
```

Run:

```bash
python test_mlflow.py
```

**Expected output**:
```
MLflow Tracking URI: http://192.168.10.100:5001
MLflow S3 Endpoint: http://192.168.10.100:9000

Created experiment: test_integration (ID: 1)

Logged:
  - Parameters: test_param, source_machine
  - Metrics: test_metric, accuracy
  - Artifact: test_artifact.txt

✅ MLflow test passed
View experiment at: http://192.168.10.100:5001/#/experiments/1
```

---

## Step 9: Verify in Tower UIs

### MinIO Console

1. Open browser: `http://TOWER_IP:9001`
2. Login with MinIO credentials
3. Navigate to **Buckets** → **sensor-data**
4. Verify test files uploaded from Thor/Spark:
   - `test_thor.txt`
   - `test_python_*.txt`

### MLflow UI

1. Open browser: `http://TOWER_IP:5001`
2. Click **Experiments** → **test_integration**
3. Verify test runs logged from Thor/Spark
4. Click on a run to see:
   - Parameters: `test_param`, `source_machine`
   - Metrics: `test_metric`, `accuracy`
   - Artifacts: `test_artifact.txt`

**✅ If you see test data in both UIs, integration is successful!**

---

## Step 10: Production Workflows

### Thor: Sensor Data Upload

```python
import boto3
import os
from datetime import datetime

s3 = boto3.client(
    's3',
    endpoint_url=os.getenv("AWS_ENDPOINT_URL"),
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY")
)

# Upload camera image
s3.upload_file(
    '/tmp/camera_front.jpg',
    'sensor-data',
    f'thor/camera/{datetime.now().strftime("%Y%m%d/%H%M%S")}_front.jpg'
)

# Upload LiDAR scan
s3.upload_file(
    '/tmp/lidar_scan.pcd',
    'sensor-data',
    f'thor/lidar/{datetime.now().strftime("%Y%m%d/%H%M%S")}_scan.pcd'
)
```

### Thor: Mission Logging

```python
import mlflow

mlflow.set_tracking_uri(os.getenv("MLFLOW_TRACKING_URI"))

with mlflow.start_run(experiment_id="missions", run_name="patrol_2025_10_18"):
    mlflow.log_param("mission_type", "patrol")
    mlflow.log_param("start_location", "base")
    
    # Log metrics during mission
    mlflow.log_metric("distance_traveled_m", 125.3, step=1)
    mlflow.log_metric("battery_pct", 87.0, step=1)
    
    # Log trajectory
    mlflow.log_artifact("trajectory.csv")
```

### Spark: Training Checkpoint Upload

```python
import mlflow
import torch

mlflow.set_tracking_uri(os.getenv("MLFLOW_TRACKING_URI"))

with mlflow.start_run(experiment_id="training", run_name="go2_policy_v1"):
    # Train model
    model = train_model()
    
    # Log metrics
    mlflow.log_metric("train_loss", 0.032, step=1000)
    mlflow.log_metric("val_accuracy", 0.94, step=1000)
    
    # Save checkpoint
    torch.save(model.state_dict(), "checkpoint_1000.pth")
    mlflow.log_artifact("checkpoint_1000.pth", artifact_path="checkpoints")
```

### Spark: Dataset Download

```bash
# Download entire dataset
aws s3 sync s3://sensor-data/thor/camera/ ./data/thor_camera/ --endpoint-url $AWS_ENDPOINT_URL

# Download specific date range
aws s3 sync s3://sensor-data/thor/camera/20251018/ ./data/today/ --endpoint-url $AWS_ENDPOINT_URL
```

---

## Troubleshooting

### Connection Refused

**Symptom**: `Connection refused` or `Connection timed out`

**Cause**: Network firewall or service not running

**Solutions**:
1. Verify Tower services running:
   ```bash
   # On Tower
   sudo systemctl status robot-datalake
   ```

2. Check Tower firewall:
   ```bash
   # On Tower
   sudo ufw status | grep -E "9000|9001|5001"
   ```
   Expected: ALLOW from 192.168.0.0/16 and 10.0.0.0/8

3. Test from Tower itself (should always work):
   ```bash
   # On Tower
   curl http://localhost:9000/minio/health/live
   ```

4. Check network connectivity:
   ```bash
   # On Thor/Spark
   ping $TOWER_IP
   traceroute $TOWER_IP
   ```

### Access Denied (403)

**Symptom**: `Access Denied` or `InvalidAccessKeyId`

**Cause**: Incorrect credentials

**Solutions**:
1. Verify credentials on Tower:
   ```bash
   # On Tower
   grep MINIO_ROOT_USER /srv/robot-data/minio/.env
   grep MINIO_ROOT_PASSWORD /srv/robot-data/minio/.env
   ```

2. Verify environment variables on Thor/Spark:
   ```bash
   echo $AWS_ACCESS_KEY_ID
   echo $AWS_SECRET_ACCESS_KEY
   ```

3. Re-configure AWS CLI:
   ```bash
   aws configure
   # Enter correct credentials
   ```

### Slow Uploads/Downloads

**Symptom**: Transfer speed < 10 MB/s on local network

**Cause**: Network congestion or MTU mismatch

**Solutions**:
1. Check network bandwidth:
   ```bash
   # Install iperf3 on Tower and Thor/Spark
   sudo apt install iperf3
   
   # On Tower
   iperf3 -s
   
   # On Thor/Spark
   iperf3 -c $TOWER_IP
   ```
   Expected: >500 Mbps on gigabit network

2. Check MTU:
   ```bash
   ip link show | grep mtu
   ```
   Expected: MTU 1500 (standard) or 9000 (jumbo frames)

3. Use parallel uploads:
   ```bash
   aws s3 sync ./data/ s3://sensor-data/ --endpoint-url $AWS_ENDPOINT_URL --no-progress
   ```

### MLflow Can't Store Artifacts

**Symptom**: `Could not store artifact` or S3 timeout

**Cause**: MLflow can't reach MinIO S3 backend

**Solutions**:
1. Verify `MLFLOW_S3_ENDPOINT_URL` set:
   ```bash
   echo $MLFLOW_S3_ENDPOINT_URL
   ```
   Expected: `http://TOWER_IP:9000`

2. Test S3 access:
   ```bash
   aws s3 ls s3://mlflow/ --endpoint-url $AWS_ENDPOINT_URL
   ```

3. Check MLflow logs on Tower:
   ```bash
   # On Tower
   cd /srv/robot-data/minio
   docker compose logs mlflow
   ```

### Permission Denied on Bucket

**Symptom**: `Access Denied` for specific bucket

**Cause**: Bucket doesn't exist or policy mismatch

**Solutions**:
1. List all buckets:
   ```bash
   aws s3 ls --endpoint-url $AWS_ENDPOINT_URL
   ```

2. Create missing bucket:
   ```bash
   aws s3 mb s3://sensor-data --endpoint-url $AWS_ENDPOINT_URL
   ```

3. Verify bucket policy in MinIO Console:
   - Open `http://TOWER_IP:9001`
   - Navigate to bucket → **Access** → **Summary**
   - Policy should be "Private" with admin access for `minioadmin`

---

## Network Reconfiguration

If Tower's IP address changes (e.g., DHCP reassignment, network move):

### On Tower

```bash
# Reconfigure network settings
cd /path/to/scripts
bash sim_and_data_lake_setup.sh reconfigure-network
```

This will:
- Detect new IP address
- Update firewall rules
- Regenerate `NETWORK_SETUP.md`

### On Thor/Spark

```bash
# Update environment variables in ~/.bashrc
nano ~/.bashrc

# Change TOWER_IP to new address
export TOWER_IP=192.168.10.NEW_IP

# Source changes
source ~/.bashrc

# Re-test connectivity
curl http://$TOWER_IP:9000/minio/health/live
```

---

## Security Best Practices

1. **Use strong credentials**: Change default `minioadmin/minio123` in `/srv/robot-data/minio/.env`

2. **Restrict firewall**: UFW rules currently allow 192.168.0.0/16 and 10.0.0.0/8. Tighten to specific IPs if needed:
   ```bash
   # On Tower
   sudo ufw delete allow from 192.168.0.0/16 to any port 9000
   sudo ufw allow from 192.168.10.116 to any port 9000  # Thor only
   ```

3. **Use HTTPS**: For production, configure nginx reverse proxy with TLS:
   ```nginx
   server {
       listen 443 ssl;
       server_name tower.example.com;
       
       ssl_certificate /etc/ssl/certs/tower.crt;
       ssl_certificate_key /etc/ssl/private/tower.key;
       
       location / {
           proxy_pass http://localhost:9000;
       }
   }
   ```

4. **Credential rotation**: Regularly change MinIO credentials:
   ```bash
   # On Tower
   nano /srv/robot-data/minio/.env
   # Change MINIO_ROOT_PASSWORD
   
   sudo systemctl restart robot-datalake
   
   # Update Thor/Spark credentials
   ```

---

## Maintenance

### Regular Tasks

- **Monitor disk space**: MinIO buckets grow with sensor data
  ```bash
  df -h /srv/robot-data
  aws s3 ls s3://sensor-data/ --recursive --summarize --endpoint-url $AWS_ENDPOINT_URL
  ```

- **Backup MLflow database**:
  ```bash
  # On Tower
  cd /srv/robot-data/minio
  docker compose exec postgres pg_dump -U mlflow mlflow > /backup/mlflow_$(date +%Y%m%d).sql
  ```

- **Check service health**:
  ```bash
  # On Tower
  bash sim_and_data_lake_setup.sh doctor
  ```

### Log Rotation

MinIO and MLflow logs can grow large. Configure log rotation:

```bash
# On Tower
sudo tee /etc/logrotate.d/robot-datalake <<EOF
/srv/robot-data/minio/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
EOF
```

---

## References

- Tower setup: `docs/deployment/tower_sim_datalake_setup.md`
- MinIO docs: https://min.io/docs/minio/linux/index.html
- MLflow docs: https://mlflow.org/docs/latest/index.html
- boto3 docs: https://boto3.amazonaws.com/v1/documentation/api/latest/index.html
- AWS CLI docs: https://docs.aws.amazon.com/cli/

---

## Validation Checklist

Integration is complete when:

- [x] Network connectivity confirmed (ping, nc)
- [x] S3 access working (AWS CLI and boto3)
- [x] MLflow logging working (Python client)
- [x] Test files visible in MinIO Console UI
- [x] Test experiments visible in MLflow UI
- [x] Production workflows documented

**Next Steps**: Integrate with robot mission code (Thor) and training pipelines (Spark).
