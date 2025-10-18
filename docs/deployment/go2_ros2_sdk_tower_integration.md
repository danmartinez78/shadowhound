---
tags: [deployment, integration, go2_ros2_sdk, thor, tower, data]
status: complete
related: [tower_thor_spark_integration_guide.md, tower_sim_datalake_setup.md]
summary: >
  How go2_ros2_sdk running on Thor integrates with Tower's MinIO/MLflow data lake for sensor logging, trajectory tracking, and experiment management.
---

# go2_ros2_sdk + Tower Integration

## Purpose

This document explains how the **go2_ros2_sdk** ROS2 driver running on **Thor** (Unitree Go2's onboard AGX) integrates with **Tower's MinIO and MLflow** services for data collection, experiment tracking, and model training workflows.

**Key Integration**: go2_ros2_sdk publishes sensor data to ROS2 topics → Custom logging nodes subscribe → Data uploaded to Tower (MinIO S3) → MLflow tracks experiments.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Thor (Unitree Go2 AGX Orin)                      │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  go2_ros2_sdk (github.com/danmartinez78/go2_ros2_sdk)       │   │
│  │  ┌──────────────────────────────────────────────────────┐   │   │
│  │  │  go2_driver_node                                     │   │   │
│  │  │  - Connects to Go2 robot via WebRTC/CycloneDDS     │   │   │
│  │  │  - Publishes sensor data to ROS2 topics            │   │   │
│  │  └──────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│           ↓                                                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  ROS2 Topics (published by go2_driver_node)               │   │
│  │  • /camera/image_raw       - Front camera (640x480)       │   │
│  │  • /camera/compressed      - Compressed JPEG              │   │
│  │  • /point_cloud2           - LiDAR point cloud            │   │
│  │  • /odom                   - Odometry (pose, velocity)    │   │
│  │  • /imu                    - IMU (accel, gyro, quat)      │   │
│  │  • /go2_states             - Robot state (battery, etc.)  │   │
│  │  • /joint_states           - 12 joint positions/velocities│   │
│  └─────────────────────────────────────────────────────────────┘   │
│           ↓                                                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  ShadowHound Mission Agent + Data Logger Nodes             │   │
│  │  ┌────────────────────────────────────────────────────┐    │   │
│  │  │  mission_agent (shadowhound_mission_agent)        │    │   │
│  │  │  - Subscribes to /camera/compressed               │    │   │
│  │  │  - Executes missions via DIMOS                    │    │   │
│  │  │  - Logs mission context to MLflow                 │    │   │
│  │  └────────────────────────────────────────────────────┘    │   │
│  │                                                              │   │
│  │  ┌────────────────────────────────────────────────────┐    │   │
│  │  │  sensor_logger_node (custom, not yet implemented) │    │   │
│  │  │  - Subscribes to sensor topics                    │    │   │
│  │  │  - Uploads to Tower MinIO S3 buckets              │    │   │
│  │  │  - Logs to MLflow experiments                     │    │   │
│  │  └────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│           ↓                                                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  boto3 / AWS CLI / MLflow Python Client                    │   │
│  │  - Configured with Tower credentials                       │   │
│  │  - MLFLOW_TRACKING_URI=http://TOWER_IP:5001                │   │
│  │  - AWS_ENDPOINT_URL=http://TOWER_IP:9000                   │   │
│  └─────────────────────────────────────────────────────────────┘   │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                        Network (WiFi/Ethernet)
                                │
┌───────────────────────────────▼───────────────────────────────────┐
│                    Tower (Sim + Data Lake Server)                  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  MinIO S3 (Docker Compose)                                  │  │
│  │  Port: 9000 (API), 9001 (Console)                           │  │
│  │                                                               │  │
│  │  Buckets:                                                     │  │
│  │  • sensor-data/                                               │  │
│  │    └── thor/camera/YYYYMMDD/HHMMSS_front.jpg                │  │
│  │    └── thor/lidar/YYYYMMDD/HHMMSS_scan.pcd                  │  │
│  │    └── thor/imu/YYYYMMDD/HHMMSS_imu.json                    │  │
│  │  • trajectories/                                              │  │
│  │    └── thor/missions/mission_patrol_20251018.csv            │  │
│  │  • mlflow/ (MLflow artifacts)                                │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  MLflow (Docker Compose)                                     │  │
│  │  Port: 5001                                                   │  │
│  │  Backend: PostgreSQL                                          │  │
│  │                                                                │  │
│  │  Experiments:                                                  │  │
│  │  • thor_missions/                                              │  │
│  │    └── run: patrol_20251018_120000                           │  │
│  │        - params: mission_type=patrol, duration_s=300         │  │
│  │        - metrics: distance_m, battery_consumed_pct           │  │
│  │        - artifacts: trajectory.csv, camera_summary.jpg       │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## go2_ros2_sdk: ROS2 Topics Published

The **go2_driver_node** from go2_ros2_sdk publishes the following sensor data:

### Camera Data

| Topic | Message Type | Rate | Description |
|-------|--------------|------|-------------|
| `/camera/image_raw` | `sensor_msgs/Image` | 30 Hz | Front camera raw RGB (640x480) |
| `/camera/compressed` | `sensor_msgs/CompressedImage` | 30 Hz | JPEG compressed (for bandwidth) |
| `/camera/camera_info` | `sensor_msgs/CameraInfo` | 30 Hz | Calibration parameters |

**Integration**: Subscribe to `/camera/compressed`, decompress, save to MinIO `sensor-data/thor/camera/`.

### LiDAR Data

| Topic | Message Type | Rate | Description |
|-------|--------------|------|-------------|
| `/point_cloud2` | `sensor_msgs/PointCloud2` | 10 Hz | 3D point cloud (up to 10m range) |
| `/utlidar/voxel_map_compressed` | `go2_interfaces/VoxelMapCompressed` | 10 Hz | Compressed voxel map (SLAM) |

**Integration**: Convert PointCloud2 to PCD format, upload to MinIO `sensor-data/thor/lidar/`.

### IMU / Odometry

| Topic | Message Type | Rate | Description |
|-------|--------------|------|-------------|
| `/imu` | `go2_interfaces/IMU` | 100 Hz | Accelerometer, gyroscope, quaternion |
| `/odom` | `nav_msgs/Odometry` | 50 Hz | Robot pose (x, y, yaw), velocity |

**Integration**: Batch IMU samples (e.g., 1 second = 100 samples), save as JSON to MinIO.

### Robot State

| Topic | Message Type | Rate | Description |
|-------|--------------|------|-------------|
| `/go2_states` | `go2_interfaces/Go2State` | 20 Hz | Battery, temperature, foot forces |
| `/joint_states` | `sensor_msgs/JointState` | 50 Hz | 12 joint positions/velocities |

**Integration**: Log robot state to MLflow as metrics (battery_pct, temperature_c).

---

## Integration Patterns

### Pattern 1: Real-Time Sensor Logging (Continuous)

**Use Case**: Log all sensor data during robot operation for later analysis.

**Implementation**:

```python
# sensor_logger_node.py (ROS2 node on Thor)
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import CompressedImage, PointCloud2
from nav_msgs.msg import Odometry
import boto3
from datetime import datetime
import os

class SensorLoggerNode(Node):
    def __init__(self):
        super().__init__('sensor_logger_node')
        
        # MinIO S3 client (configured via environment)
        self.s3 = boto3.client(
            's3',
            endpoint_url=os.getenv('AWS_ENDPOINT_URL'),  # http://TOWER_IP:9000
            aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY')
        )
        
        # Subscribe to camera (downsampled to 1 Hz for logging)
        self.camera_sub = self.create_subscription(
            CompressedImage,
            '/camera/compressed',
            self.camera_callback,
            10
        )
        self.camera_count = 0
        self.camera_skip = 30  # Log every 30th frame (1 Hz @ 30 FPS)
        
        # Subscribe to odometry (1 Hz)
        self.odom_sub = self.create_subscription(
            Odometry,
            '/odom',
            self.odom_callback,
            10
        )
        
        self.get_logger().info('Sensor logger started. Uploading to Tower MinIO.')
    
    def camera_callback(self, msg):
        """Log camera images to MinIO."""
        self.camera_count += 1
        if self.camera_count % self.camera_skip != 0:
            return  # Skip frame
        
        # Generate S3 key with timestamp
        timestamp = datetime.now().strftime('%Y%m%d/%H%M%S')
        s3_key = f'thor/camera/{timestamp}_front.jpg'
        
        try:
            # Upload JPEG to MinIO
            self.s3.put_object(
                Bucket='sensor-data',
                Key=s3_key,
                Body=bytes(msg.data),
                ContentType='image/jpeg'
            )
            self.get_logger().debug(f'Uploaded: s3://sensor-data/{s3_key}')
        except Exception as e:
            self.get_logger().error(f'Upload failed: {e}')
    
    def odom_callback(self, msg):
        """Log odometry to MinIO as JSON."""
        timestamp = datetime.now().strftime('%Y%m%d/%H%M%S')
        s3_key = f'thor/odom/{timestamp}_odom.json'
        
        odom_data = {
            'timestamp': timestamp,
            'position': {
                'x': msg.pose.pose.position.x,
                'y': msg.pose.pose.position.y,
                'z': msg.pose.pose.position.z
            },
            'orientation': {
                'x': msg.pose.pose.orientation.x,
                'y': msg.pose.pose.orientation.y,
                'z': msg.pose.pose.orientation.z,
                'w': msg.pose.pose.orientation.w
            },
            'linear_velocity': {
                'x': msg.twist.twist.linear.x,
                'y': msg.twist.twist.linear.y,
                'z': msg.twist.twist.linear.z
            }
        }
        
        try:
            import json
            self.s3.put_object(
                Bucket='sensor-data',
                Key=s3_key,
                Body=json.dumps(odom_data).encode('utf-8'),
                ContentType='application/json'
            )
        except Exception as e:
            self.get_logger().error(f'Odom upload failed: {e}')

def main():
    rclpy.init()
    node = SensorLoggerNode()
    rclpy.spin(node)
    rclpy.shutdown()
```

**Launch**:
```bash
# On Thor
export AWS_ENDPOINT_URL=http://TOWER_IP:9000
export AWS_ACCESS_KEY_ID=<from Tower>
export AWS_SECRET_ACCESS_KEY=<from Tower>

ros2 run shadowhound_data_logger sensor_logger_node
```

---

### Pattern 2: Mission-Based Logging (Event-Driven)

**Use Case**: Log sensor data only during mission execution, tagged with mission context.

**Implementation**:

```python
# mission_data_logger.py (integrated with mission_agent)
import mlflow
import boto3
import os
from datetime import datetime

class MissionDataLogger:
    """Logs mission data to Tower MLflow + MinIO."""
    
    def __init__(self):
        # Configure MLflow
        mlflow.set_tracking_uri(os.getenv('MLFLOW_TRACKING_URI'))  # http://TOWER_IP:5001
        
        # Configure S3 for MLflow artifacts
        os.environ['MLFLOW_S3_ENDPOINT_URL'] = os.getenv('AWS_ENDPOINT_URL')
        
        self.s3 = boto3.client(
            's3',
            endpoint_url=os.getenv('AWS_ENDPOINT_URL'),
            aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY')
        )
        
        self.current_run = None
    
    def start_mission(self, mission_type: str, mission_command: str):
        """Start logging a new mission."""
        experiment_name = "thor_missions"
        
        # Get or create experiment
        try:
            experiment = mlflow.get_experiment_by_name(experiment_name)
            experiment_id = experiment.experiment_id
        except:
            experiment_id = mlflow.create_experiment(experiment_name)
        
        # Start MLflow run
        run_name = f"{mission_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.current_run = mlflow.start_run(
            experiment_id=experiment_id,
            run_name=run_name
        )
        
        # Log mission parameters
        mlflow.log_param("mission_type", mission_type)
        mlflow.log_param("mission_command", mission_command)
        mlflow.log_param("robot", "thor")
        mlflow.log_param("timestamp", datetime.now().isoformat())
        
        return self.current_run.info.run_id
    
    def log_camera_frame(self, frame_data: bytes, frame_id: int):
        """Log camera frame to MinIO and reference in MLflow."""
        if not self.current_run:
            return
        
        # Upload to MinIO
        s3_key = f"thor/missions/{self.current_run.info.run_id}/camera/frame_{frame_id:06d}.jpg"
        self.s3.put_object(
            Bucket='sensor-data',
            Key=s3_key,
            Body=frame_data,
            ContentType='image/jpeg'
        )
        
        # Log artifact path in MLflow
        mlflow.log_metric(f"camera_frame_{frame_id}", 1.0, step=frame_id)
    
    def log_robot_state(self, battery_pct: float, temperature_c: float, step: int):
        """Log robot state metrics to MLflow."""
        if not self.current_run:
            return
        
        mlflow.log_metric("battery_pct", battery_pct, step=step)
        mlflow.log_metric("temperature_c", temperature_c, step=step)
    
    def log_trajectory(self, trajectory_csv_path: str):
        """Upload trajectory CSV as MLflow artifact."""
        if not self.current_run:
            return
        
        mlflow.log_artifact(trajectory_csv_path, artifact_path="trajectories")
    
    def end_mission(self, success: bool, distance_m: float, duration_s: float):
        """End mission logging."""
        if not self.current_run:
            return
        
        # Log final metrics
        mlflow.log_metric("success", 1.0 if success else 0.0)
        mlflow.log_metric("distance_traveled_m", distance_m)
        mlflow.log_metric("duration_s", duration_s)
        
        # End MLflow run
        mlflow.end_run()
        self.current_run = None
```

**Integration with Mission Agent**:

```python
# In mission_executor.py
class MissionExecutor:
    def __init__(self, config, logger=None):
        # ...existing init...
        self.data_logger = MissionDataLogger()  # New
    
    def execute_mission(self, command: str):
        # Start logging
        mission_type = self._infer_mission_type(command)  # "patrol", "explore", etc.
        run_id = self.data_logger.start_mission(mission_type, command)
        
        try:
            # Execute mission (existing code)
            result = self.agent.prompt(command, ...)
            
            # Log mission data
            if self._latest_camera_frame is not None:
                self.data_logger.log_camera_frame(
                    self._encode_frame_as_jpeg(self._latest_camera_frame),
                    frame_id=0
                )
            
            # Log robot state (if available)
            robot_state = self.robot.get_state()  # From DIMOS
            self.data_logger.log_robot_state(
                battery_pct=robot_state.battery_percentage,
                temperature_c=robot_state.temperature,
                step=0
            )
            
            # Log trajectory (if mission involved navigation)
            if mission_type in ["patrol", "explore"]:
                trajectory_path = "/tmp/trajectory.csv"
                self._save_trajectory_csv(trajectory_path)
                self.data_logger.log_trajectory(trajectory_path)
            
            # Calculate metrics
            distance_m = self._calculate_distance_traveled()
            duration_s = self._calculate_mission_duration()
            
            # End logging
            self.data_logger.end_mission(
                success=True,
                distance_m=distance_m,
                duration_s=duration_s
            )
            
            return result, timing
        
        except Exception as e:
            self.data_logger.end_mission(success=False, distance_m=0, duration_s=0)
            raise
```

---

### Pattern 3: Rosbag Recording + Upload (Full Fidelity)

**Use Case**: Record entire mission as rosbag for full replay, then upload to MinIO.

**Implementation**:

```bash
# On Thor, during mission
ros2 bag record -o /tmp/mission_patrol_20251018 \
    /camera/compressed \
    /point_cloud2 \
    /odom \
    /imu \
    /go2_states \
    /joint_states

# After mission, compress and upload
cd /tmp
tar -czf mission_patrol_20251018.tar.gz mission_patrol_20251018/
aws s3 cp mission_patrol_20251018.tar.gz s3://sensor-data/thor/rosbags/ \
    --endpoint-url $AWS_ENDPOINT_URL
```

**Automated Upload Script**:

```python
# auto_upload_rosbag.py
import subprocess
import boto3
import os
from datetime import datetime

def record_and_upload_rosbag(mission_name: str, duration_s: int):
    """Record rosbag and upload to Tower MinIO."""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    bag_name = f"{mission_name}_{timestamp}"
    bag_path = f"/tmp/{bag_name}"
    
    # Record rosbag
    topics = [
        '/camera/compressed',
        '/point_cloud2',
        '/odom',
        '/imu',
        '/go2_states'
    ]
    
    cmd = ['ros2', 'bag', 'record', '-o', bag_path, '-d', str(duration_s)] + topics
    subprocess.run(cmd, check=True)
    
    # Compress
    tar_path = f"{bag_path}.tar.gz"
    subprocess.run(['tar', '-czf', tar_path, bag_path], check=True)
    
    # Upload to MinIO
    s3 = boto3.client(
        's3',
        endpoint_url=os.getenv('AWS_ENDPOINT_URL'),
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY')
    )
    
    s3_key = f'thor/rosbags/{bag_name}.tar.gz'
    with open(tar_path, 'rb') as f:
        s3.upload_fileobj(f, 'sensor-data', s3_key)
    
    # Cleanup local files
    subprocess.run(['rm', '-rf', bag_path, tar_path])
    
    print(f"Uploaded: s3://sensor-data/{s3_key}")
```

---

## Data Organization on Tower MinIO

### Bucket Structure

```
sensor-data/
├── thor/
│   ├── camera/
│   │   ├── 20251018/
│   │   │   ├── 120000_front.jpg
│   │   │   ├── 120001_front.jpg
│   │   │   └── ...
│   │   └── 20251019/
│   ├── lidar/
│   │   ├── 20251018/
│   │   │   ├── 120000_scan.pcd
│   │   │   └── ...
│   ├── imu/
│   │   └── 20251018/
│   │       ├── 120000_imu.json
│   │       └── ...
│   ├── odom/
│   │   └── 20251018/
│   ├── missions/
│   │   ├── <mlflow_run_id>/
│   │   │   ├── camera/
│   │   │   ├── trajectory.csv
│   │   │   └── summary.json
│   └── rosbags/
│       ├── patrol_20251018_120000.tar.gz
│       └── explore_20251019_093000.tar.gz
├── spark/
│   └── (training data from Spark)
└── laptop/
    └── (development data from Laptop)

lerobot/
├── datasets/
│   ├── soarm/
│   │   ├── pick_and_place/
│   │   │   ├── data/                    # HDF5 episode data (LeRobotDataset format)
│   │   │   ├── videos/                  # Compressed MP4 videos
│   │   │   │   ├── episode_000000_observation_wrist_cam.mp4
│   │   │   │   └── ...
│   │   │   └── meta/                    # Metadata (episodes, stats, tasks)
│   │   ├── assembly/
│   │   └── pouring/
│   └── mobile_manipulation/             # Combined Go2 + SO-ARM (future)
│       ├── fetch_task/
│       │   ├── go2/                     # Go2 sensor data
│       │   │   ├── odometry.bag
│       │   │   ├── camera_front.mp4
│       │   │   └── joint_states.csv
│       │   ├── soarm/                   # SO-ARM demonstration data
│       │   │   ├── demonstrations.hdf5  # LeRobot format
│       │   │   ├── wrist_camera.mp4
│       │   │   └── joint_states.csv
│       │   └── synchronized/            # Synchronized multi-robot data
│       │       ├── timestamps.csv       # Sync both robots
│       │       └── detections.json      # Shared perception
│       └── warehouse_task/
├── policies/
│   ├── soarm/
│   │   ├── pick_place_act_v1/
│   │   │   ├── config.json              # Policy configuration
│   │   │   ├── model.safetensors        # Model weights
│   │   │   └── train_config.json        # Training configuration
│   │   └── assembly_diffusion_v2/
│   └── mobile_manipulation/
│       └── coordinated_policy_v1/

trajectories/
├── thor/
│   ├── patrol_20251018.csv
│   └── explore_20251019.csv

mlflow/
├── <mlflow_artifact_storage>/
```

---

## MLflow Experiment Tracking

### Experiment: `thor_missions`

**Logged Parameters**:
- `mission_type` - Type of mission (patrol, explore, test)
- `mission_command` - Natural language command
- `robot` - Robot identifier (thor)
- `timestamp` - Mission start time

**Logged Metrics** (time-series):
- `battery_pct` - Battery percentage over time
- `temperature_c` - Robot temperature
- `distance_traveled_m` - Cumulative distance
- `camera_frame_N` - Camera frame logged (1.0 = logged)

**Logged Artifacts**:
- `trajectories/trajectory.csv` - Full mission trajectory (x, y, yaw, timestamp)
- `camera/frame_NNNNNN.jpg` - Sampled camera frames
- `summary.json` - Mission summary (start/end time, result, errors)

**Example MLflow Query**:

```python
import mlflow

mlflow.set_tracking_uri("http://TOWER_IP:5001")

# Get all patrol missions
client = mlflow.tracking.MlflowClient()
experiment = client.get_experiment_by_name("thor_missions")

runs = client.search_runs(
    experiment_ids=[experiment.experiment_id],
    filter_string="params.mission_type = 'patrol'"
)

for run in runs:
    print(f"Run ID: {run.info.run_id}")
    print(f"  Command: {run.data.params['mission_command']}")
    print(f"  Distance: {run.data.metrics['distance_traveled_m']} m")
    print(f"  Success: {run.data.metrics['success']}")
```

---

## Training Workflow (Tower → Spark)

1. **Thor**: Collect sensor data during missions → Upload to MinIO `sensor-data/`
2. **Tower**: MLflow tracks missions with metadata
3. **Spark**: Download dataset from MinIO → Train models → Upload checkpoints

**Example Training Script (on Spark)**:

```python
# train_navigation_policy.py (on Spark DGX)
import boto3
import mlflow
import torch
import os

# Configure Tower access
os.environ['MLFLOW_TRACKING_URI'] = 'http://TOWER_IP:5001'
os.environ['AWS_ENDPOINT_URL'] = 'http://TOWER_IP:9000'

# Download training data from MinIO
s3 = boto3.client(
    's3',
    endpoint_url=os.getenv('AWS_ENDPOINT_URL'),
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY')
)

# Download all camera images from thor missions
paginator = s3.get_paginator('list_objects_v2')
for page in paginator.paginate(Bucket='sensor-data', Prefix='thor/camera/'):
    for obj in page.get('Contents', []):
        s3.download_file('sensor-data', obj['Key'], f"/data/{obj['Key']}")

# Train model
mlflow.set_experiment("navigation_policy_training")
with mlflow.start_run(run_name="resnet50_v1"):
    mlflow.log_param("architecture", "resnet50")
    mlflow.log_param("dataset", "thor_camera_20251018")
    
    model = train_model()  # Your training code
    
    # Save checkpoint
    torch.save(model.state_dict(), "checkpoint_1000.pth")
    mlflow.log_artifact("checkpoint_1000.pth", artifact_path="checkpoints")
    
    mlflow.log_metric("train_loss", 0.032)
    mlflow.log_metric("val_accuracy", 0.94)
```

---

## Integration Checklist

- [ ] **Tower Setup Complete**: MinIO + MLflow running (`bash sim_and_data_lake_setup.sh doctor`)
- [ ] **Network Access**: Thor can reach Tower (ping, curl health checks)
- [ ] **Credentials Configured**: `AWS_*` and `MLFLOW_*` environment variables set on Thor
- [ ] **go2_ros2_sdk Running**: `ros2 launch go2_robot_sdk robot.launch.py`
- [ ] **Sensor Topics Publishing**: `ros2 topic hz /camera/compressed /odom /imu`
- [ ] **Data Logger Node**: Custom sensor_logger_node implemented and running
- [ ] **Mission Agent Integration**: MissionDataLogger integrated with mission_executor.py
- [ ] **Test Upload**: Verify S3 upload works (`aws s3 ls s3://sensor-data/thor/ --endpoint-url ...`)
- [ ] **Test MLflow**: Verify experiment logging works (check MLflow UI at `http://TOWER_IP:5001`)

---

## Troubleshooting

### Issue: ROS Topics Not Visible

**Symptom**: `ros2 topic list` doesn't show go2_ros2_sdk topics on Thor.

**Solutions**:
1. Check go2_driver_node is running: `ps aux | grep go2_driver`
2. Verify robot connection: `ros2 topic echo /go2_states` (should show battery, temp)
3. Check ROS_DOMAIN_ID matches: `echo $ROS_DOMAIN_ID` (should be same across all nodes)

### Issue: MinIO Upload Fails (Connection Refused)

**Symptom**: `boto3.exceptions.EndpointConnectionError: Could not connect to endpoint`

**Solutions**:
1. Verify Tower firewall allows Thor: `sudo ufw status | grep 9000` (on Tower)
2. Test connectivity from Thor: `curl http://TOWER_IP:9000/minio/health/live`
3. Check credentials: `echo $AWS_ACCESS_KEY_ID` (should not be empty)

### Issue: Large Upload Lag

**Symptom**: Uploading camera frames causes mission delays.

**Solutions**:
1. Use async uploads (threading/multiprocessing):
   ```python
   from concurrent.futures import ThreadPoolExecutor
   
   executor = ThreadPoolExecutor(max_workers=4)
   executor.submit(s3.put_object, Bucket='...', Key='...', Body=data)
   ```
2. Reduce camera logging rate (e.g., 1 Hz instead of 30 Hz)
3. Use compression: JPEG quality 85 instead of 95
4. Batch uploads: collect 10 frames, upload as zip

### Issue: MLflow Artifacts Not Stored in MinIO

**Symptom**: MLflow run succeeds but artifacts missing in MinIO Console.

**Solutions**:
1. Verify `MLFLOW_S3_ENDPOINT_URL` set: `echo $MLFLOW_S3_ENDPOINT_URL`
2. Check MLflow can reach MinIO: `docker logs mlflow` (on Tower)
3. Test S3 access from Thor: `aws s3 ls s3://mlflow/ --endpoint-url ...`

---

## Future Enhancements

1. **Real-Time Streaming**: Stream camera/LiDAR to Tower for live monitoring (RTSP/WebRTC)
2. **Automated Rosbag Slicing**: Split large rosbags into chunks on upload
3. **Data Deduplication**: Hash-based dedup to avoid storing identical frames
4. **Data Lake Indexing**: Elasticsearch integration for fast sensor data queries
5. **Policy Deployment**: Download trained models from MLflow to Thor for inference

---

## References

- go2_ros2_sdk: https://github.com/danmartinez78/go2_ros2_sdk
- Tower Setup Guide: `docs/deployment/tower_sim_datalake_setup.md`
- Integration Guide: `docs/deployment/tower_thor_spark_integration_guide.md`
- MinIO Docs: https://min.io/docs/minio/linux/index.html
- MLflow Docs: https://mlflow.org/docs/latest/index.html
- ROS2 rosbag: https://docs.ros.org/en/humble/Tutorials/Beginner-CLI-Tools/Recording-And-Playing-Back-Data/Recording-And-Playing-Back-Data.html

---

**Status**: Integration pattern documented. Custom sensor logging nodes not yet implemented (future work).
