---
tags: [deployment, lerobot, so-arm-101, robotic-arm, tower, optional]
status: complete
related: [tower_sim_datalake_setup.md, tower_security_credentials.md]
summary: >
  Optional LeRobot SO-ARM 101 installation on Tower for low-cost robotic arm training alongside Unitree Go2.
---

# LeRobot SO-ARM 101 Setup (Optional Extension)

## Overview

This guide adds **LeRobot SO-ARM 101** support to your Tower system as an optional extension. The SO-ARM 101 is a low-cost (€114 per arm) robotic arm that can be trained using imitation learning.

### **Can Be Used Completely Independently** ✅

The SO-ARM 101 is **entirely separate** from the Unitree Go2 robot:

**Independence**:
- ✅ **No Go2 required**: Use SO-ARM for pure manipulation research
- ✅ **Separate hardware**: USB connection (no robot networking)
- ✅ **Separate control**: Feetech motor SDK (not ROS2)
- ✅ **Separate workflows**: LeRobot training pipeline (not go2_ros2_sdk)
- ✅ **Separate use cases**: Tabletop manipulation, assembly, pouring tasks

**Shared Infrastructure**:
- ✅ **MinIO storage**: Store SO-ARM datasets in same S3 buckets
- ✅ **MLflow tracking**: Track experiments alongside Go2 (or alone)
- ✅ **Conda environment**: Same Python env (but independent libraries)

**Optional Integration** (not required):
- 🔗 Can combine with Go2 later for mobile manipulation
- 🔗 See [Combined Workflows](combined_go2_soarm_workflows.md) if interested
- 🔗 But this is **optional future work**, not a prerequisite

### **Key Points**:
- ✅ **No conflicts** with Unitree Go2 setup (completely independent)
- ✅ **Shares infrastructure** (MinIO, MLflow, conda environment)
- ✅ **USB-based** (no network configuration needed)
- ✅ **Quick training** (train in minutes on laptop)
- ✅ **Use standalone**: Full value without Go2 robot

## Prerequisites

### Required Hardware

1. **SO-ARM 101 Kit** (~€228 for leader + follower):
   - 1x Leader arm (for teleoperation)
   - 1x Follower arm (the robot that learns)
   - 2x Motor bus USB adapters
   - 12x Feetech servo motors (various ratios)
   - 3D printed parts
   - Hardware (screws, cables)

2. **Tower System** (already installed):
   - Ubuntu 22.04
   - MinIO + MLflow (from main setup)
   - Miniconda with env_isaaclab

### Bill of Materials

Follow the official BOM: https://github.com/TheRobotStudio/SO-ARM100

**Motors needed**:
- **Follower arm**: 6x STS3215 motors (1/345 gearing)
- **Leader arm**: Mixed gearing for ergonomics
  - Base/Shoulder Pan: 1/191
  - Shoulder Lift: 1/345
  - Elbow Flex: 1/191
  - Wrist Flex: 1/147
  - Wrist Roll: 1/147
  - Gripper: 1/147

## Installation

### Step 1: Activate Conda Environment

```bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate env_isaaclab
```

### Step 2: Install LeRobot with Feetech Support

```bash
# Install LeRobot in the existing Isaac Lab environment
pip install lerobot[feetech]
```

**What this installs**:
- LeRobot core library (imitation learning, datasets, policies)
- Feetech motor SDK (USB serial communication)
- Dependencies: PyTorch (already present), Hugging Face libraries

### Step 3: Verify Installation

```bash
# Check LeRobot installed
python -c "import lerobot; print(lerobot.__version__)"

# Check Feetech SDK
python -c "from lerobot.common.robot_devices.motors.feetech import FeetechMotorsBus; print('OK')"
```

## Hardware Setup

### Step 1: Assemble the Arms

Follow the official assembly guide: https://huggingface.co/docs/lerobot/so101

**Summary**:
1. 3D print all parts (STL files in SO-ARM100 repo)
2. Clean support material from prints
3. Assemble joints 1-5 (shoulder → wrist)
4. Install gripper (follower) or handle (leader)
5. Connect 3-pin cables between motors (daisy chain)

**Assembly time**: ~2-3 hours per arm

### Step 2: Find USB Ports

Connect both motor bus adapters to Tower via USB:

```bash
# Activate environment first
conda activate env_isaaclab

# Find ports
lerobot-find-port
```

**Example output**:
```
Finding all available ports for the MotorBus.
['/dev/ttyUSB0', '/dev/ttyUSB1']
Remove the USB cable from your MotorsBus and press Enter when done.

[Disconnect follower arm and press Enter]

The port of this MotorsBus is /dev/ttyUSB0
Reconnect the USB cable.
```

**Record the ports**:
- Follower arm: `/dev/ttyUSB0`
- Leader arm: `/dev/ttyUSB1`

### Step 3: Configure Motor IDs

Each motor needs a unique ID (1-6) on the bus.

#### Follower Arm

```bash
lerobot-setup-motors \
  --robot.type=so101_follower \
  --robot.port=/dev/ttyUSB0  # Use your port from step 2
```

**Process**:
1. Connect **only the gripper motor** to the board
2. Press Enter → motor ID set to 6
3. Disconnect gripper, connect **wrist_roll motor**
4. Press Enter → motor ID set to 5
5. Repeat for remaining motors (wrist_flex=4, elbow_flex=3, shoulder_lift=2, shoulder_pan=1)

#### Leader Arm

```bash
lerobot-setup-motors \
  --teleop.type=so101_leader \
  --teleop.port=/dev/ttyUSB1  # Use your port from step 2
```

**Same process as follower** (connect motors one at a time, press Enter).

### Step 4: Calibrate Arms

Calibration ensures leader and follower positions match.

#### Follower Arm

```bash
lerobot-calibrate \
  --robot.type=so101_follower \
  --robot.port=/dev/ttyUSB0 \
  --robot.id=tower_follower_arm
```

**Process**:
1. Move arm to middle position (all joints mid-range)
2. Press Enter
3. Move each joint through its **full range of motion**
4. Calibration values saved to `~/.cache/calibration/so101_follower_tower_follower_arm.json`

#### Leader Arm

```bash
lerobot-calibrate \
  --teleop.type=so101_leader \
  --teleop.port=/dev/ttyUSB1 \
  --teleop.id=tower_leader_arm
```

**Same process as follower**.

## Training Workflow

### Step 1: Record Demonstrations

Connect both arms and record teleoperation data:

```bash
lerobot-record \
  --robot-path lerobot/configs/robot/so101_follower.yaml \
  --robot-overrides robot.port=/dev/ttyUSB0 robot.id=tower_follower_arm \
  --teleop-path lerobot/configs/robot/so101_leader.yaml \
  --teleop-overrides teleop.port=/dev/ttyUSB1 teleop.id=tower_leader_arm \
  --repo-id ${HF_USER}/my_soarm_task \
  --root /srv/robot-data/lerobot_datasets \
  --num-episodes 50
```

**What this does**:
- Records 50 episodes of you manipulating the leader arm
- Follower arm mimics your movements in real-time
- Saves dataset to MinIO-backed storage (`/srv/robot-data/lerobot_datasets/`)
- Format: LeRobotDataset (HDF5 + videos)

**Recording tips**:
- Each episode = one task demonstration (e.g., pick and place)
- Move smoothly (no jerky motions)
- Complete the task fully each time
- 50 episodes ~= 10-15 minutes of recording

### Step 2: Train Policy

Train an imitation learning policy on recorded data:

```bash
lerobot-train \
  --config-path lerobot/configs/policy/act_so101_real.yaml \
  --dataset-repo-id ${HF_USER}/my_soarm_task \
  --root /srv/robot-data/lerobot_datasets \
  --output-dir /srv/robot-data/lerobot_policies \
  --wandb-disable  # Or configure W&B for tracking
```

**Training parameters**:
- Policy: ACT (Action Chunking Transformer)
- Training time: ~30-60 minutes on Tower GPU
- Checkpoints saved to `/srv/robot-data/lerobot_policies/`

**Track with MLflow** (optional):

```python
# Add to training script
import mlflow

mlflow.set_tracking_uri("http://localhost:5001")
mlflow.set_experiment("soarm_training")

with mlflow.start_run():
    mlflow.log_params({"policy": "ACT", "episodes": 50})
    # Training happens here
    mlflow.log_metric("final_success_rate", success_rate)
```

### Step 3: Deploy Policy

Run the trained policy autonomously:

```bash
lerobot-deploy \
  --robot-path lerobot/configs/robot/so101_follower.yaml \
  --robot-overrides robot.port=/dev/ttyUSB0 robot.id=tower_follower_arm \
  --policy-path /srv/robot-data/lerobot_policies/my_soarm_task/checkpoints/last \
  --num-episodes 10
```

**Result**: Follower arm executes the learned task autonomously 10 times.

## Data Management

### Dataset Storage

LeRobot datasets are stored in MinIO-backed storage and can be shared:

```bash
# Datasets location
/srv/robot-data/lerobot_datasets/
  └── ${HF_USER}/
      └── my_soarm_task/
          ├── data/  # HDF5 episode data
          ├── videos/  # Compressed videos
          └── meta/  # Dataset metadata
```

### Upload to Hugging Face Hub

Share your datasets with the community:

```bash
lerobot-push-dataset \
  --repo-id ${HF_USER}/my_soarm_task \
  --root /srv/robot-data/lerobot_datasets \
  --push-videos  # Include videos (large)
```

**Access control**:
- Public: Anyone can download
- Private: Only you can access
- Set via Hugging Face settings: https://huggingface.co/${HF_USER}/my_soarm_task

### Track Experiments with MLflow

Log SO-ARM training runs to Tower's MLflow:

```python
import mlflow

mlflow.set_tracking_uri("http://localhost:5001")
mlflow.set_experiment("soarm_experiments")

with mlflow.start_run(run_name="pick_and_place_v1"):
    mlflow.log_params({
        "policy": "ACT",
        "episodes": 50,
        "robot": "so101_follower",
        "task": "pick_and_place"
    })
    
    # Train model...
    
    mlflow.log_metrics({
        "train_loss": final_loss,
        "success_rate": success_rate
    })
    
    # Log trained policy
    mlflow.log_artifact("/srv/robot-data/lerobot_policies/my_policy.pth")
```

**View experiments**: http://tower:5001

## Integration with Unitree Go2

### No Conflicts

SO-ARM 101 and Unitree Go2 setups are **completely independent**:

| Component | Unitree Go2 | SO-ARM 101 | Shared? |
|-----------|-------------|------------|---------|
| Communication | ROS2 DDS (network) | USB serial | ❌ Separate |
| Hardware | Robot dog | Robotic arm | ❌ Separate |
| Control | go2_ros2_sdk | Feetech SDK | ❌ Separate |
| Simulation | Isaac Sim | LeRobot gym envs | ⚠️ Different |
| Data Storage | MinIO buckets | LeRobot datasets | ✅ Shared |
| Experiment Tracking | MLflow | MLflow | ✅ Shared |
| Python Environment | env_isaaclab | env_isaaclab | ✅ Shared |

### Shared Infrastructure

Both systems use the same Tower services:

**MinIO (S3 Storage)**:
```bash
# Unitree Go2 data
s3://sensor-data/thor/...
s3://models/go2_navigation/...

# SO-ARM 101 data
s3://lerobot/datasets/my_soarm_task/...
s3://lerobot/policies/pick_and_place/...
```

**MLflow (Experiment Tracking)**:
```bash
# Unitree Go2 experiments
http://tower:5001/#/experiments/go2_navigation

# SO-ARM 101 experiments
http://tower:5001/#/experiments/soarm_experiments
```

### Combined Workflows (Future)

Potential multi-robot scenarios:

1. **Mobile Manipulation**: Go2 navigates + SO-ARM manipulates
2. **Coordinated Tasks**: Go2 holds object + SO-ARM assembles
3. **Shared Perception**: Go2 cameras + SO-ARM wrist camera

**Not yet implemented** - requires custom integration layer.

## Troubleshooting

### USB Permission Denied

If you get permission errors accessing `/dev/ttyUSB*`:

```bash
# Add user to dialout group
sudo usermod -aG dialout $USER

# Logout and login again
# Or use sudo temporarily:
sudo chmod 666 /dev/ttyUSB0 /dev/ttyUSB1
```

### Motor Not Responding

**Symptoms**: Motor doesn't move during setup or calibration.

**Solutions**:
1. **Check power**: Verify 7.4V power supply connected
2. **Check cables**: Ensure 3-pin cable fully inserted
3. **Check ID**: Motor may already have a different ID
   ```bash
   # Scan bus for motors
   python -c "
   from lerobot.common.robot_devices.motors.feetech import FeetechMotorsBus
   bus = FeetechMotorsBus(port='/dev/ttyUSB0')
   bus.connect()
   print('Found motors:', bus.scan())
   "
   ```
4. **Reset motor**: Hold motor horn, power cycle, release

### Calibration Values Wrong

**Symptoms**: Leader and follower don't match positions.

**Solution**: Re-run calibration, ensure:
- Both arms start in **same physical position**
- Move through **full range** of each joint
- Don't skip any joints
- Save completes without errors

### Import Error: lerobot module not found

**Solution**: Make sure you're in the correct conda environment:

```bash
conda activate env_isaaclab
python -c "import lerobot; print('OK')"
```

If still fails:
```bash
# Reinstall LeRobot
pip uninstall lerobot
pip install lerobot[feetech]
```

### Dataset Upload Fails

**Symptoms**: `lerobot-push-dataset` times out or fails.

**Solutions**:
1. **Check Hugging Face login**:
   ```bash
   huggingface-cli login
   ```
2. **Check dataset size**: Videos are large (~GB per 50 episodes)
   ```bash
   du -sh /srv/robot-data/lerobot_datasets/${HF_USER}/my_soarm_task
   ```
3. **Upload without videos** (faster):
   ```bash
   lerobot-push-dataset --repo-id ${HF_USER}/my_soarm_task --no-push-videos
   ```

## Performance Optimization

### Training Speed

**GPU utilization**:
- Training uses Tower's NVIDIA GPU (same as Isaac Sim)
- No conflict: Train SO-ARM when Isaac Sim not running
- Or run both: GPU memory permits (~12GB for Isaac Sim + ~4GB for training)

**Check GPU usage**:
```bash
nvidia-smi
```

### Recording Quality

**Video compression**:
- Default: H.264 (good balance)
- High quality: Add `--video-quality 35` (lower number = higher quality)
- Fast encoding: Uses Tower's ffmpeg with libsvtav1

**Episode length**:
- Shorter episodes (10-30s) → faster training
- Longer episodes (60s+) → more context but slower

### Storage Optimization

**Dataset size**:
- 50 episodes × 30s × 2 cameras = ~2-3GB
- Store in MinIO (`/srv/robot-data/`) to leverage multi-drive RAID

**Cleanup old datasets**:
```bash
# List datasets
ls -lh /srv/robot-data/lerobot_datasets/

# Remove old dataset
rm -rf /srv/robot-data/lerobot_datasets/${HF_USER}/old_task
```

## Standalone Exploration (Without Go2)

### Pure Manipulation Research

The SO-ARM 101 provides **complete manipulation research capability** without requiring the Unitree Go2:

**Standalone Use Cases**:

1. **Tabletop Manipulation**:
   - Pick and place objects
   - Stacking blocks
   - Object sorting
   - Assembly tasks (peg-in-hole, part mating)

2. **Dexterous Skills**:
   - Pouring liquids
   - Scooping granular materials
   - Opening containers
   - Tool use (screwdriver, wrench)

3. **Imitation Learning Research**:
   - Test different policies (ACT, Diffusion, VQ-BeT)
   - Collect demonstration datasets
   - Study sim-to-real transfer
   - Multi-task learning

4. **Educational Projects**:
   - Learn robotics fundamentals
   - Experiment with control algorithms
   - Build manipulation skills library
   - Create shareable datasets

### Example: Complete Standalone Workflow

**Goal**: Train SO-ARM to pick and place objects (no Go2 needed)

**Step 1: Setup** (one-time):
```bash
# Install LeRobot (from Tower guide)
conda activate env_isaaclab
pip install lerobot[feetech]

# Calibrate arms (from SO-ARM guide)
lerobot-calibrate --robot.type=so101_follower --robot.port=/dev/ttyUSB0 --robot.id=tower_soarm
lerobot-calibrate --teleop.type=so101_leader --teleop.port=/dev/ttyUSB1 --teleop.id=tower_leader
```

**Step 2: Record Demonstrations**:
```bash
# Record 50 episodes of pick-and-place
lerobot-record \
  --robot-path lerobot/configs/robot/so101_follower.yaml \
  --robot-overrides robot.port=/dev/ttyUSB0 robot.id=tower_soarm \
  --teleop-path lerobot/configs/robot/so101_leader.yaml \
  --teleop-overrides teleop.port=/dev/ttyUSB1 teleop.id=tower_leader \
  --repo-id ${HF_USER}/pick_and_place_blocks \
  --root /srv/robot-data/lerobot_datasets \
  --num-episodes 50

# Takes ~15 minutes (50 episodes × 15-20 seconds each)
```

**Step 3: Train Policy**:
```bash
# Train ACT policy on demonstrations
lerobot-train \
  --config-path lerobot/configs/policy/act_so101_real.yaml \
  --dataset-repo-id ${HF_USER}/pick_and_place_blocks \
  --root /srv/robot-data/lerobot_datasets \
  --output-dir /srv/robot-data/lerobot_policies/pick_place_v1 \
  --num-epochs 500

# Takes ~30-45 minutes on Tower GPU
```

**Step 4: Deploy Autonomously**:
```bash
# Test trained policy
lerobot-deploy \
  --robot-path lerobot/configs/robot/so101_follower.yaml \
  --robot-overrides robot.port=/dev/ttyUSB0 robot.id=tower_soarm \
  --policy-path /srv/robot-data/lerobot_policies/pick_place_v1/checkpoints/last \
  --num-episodes 10

# Watch the arm execute autonomously!
```

**Result**: Fully autonomous pick-and-place behavior, trained in ~1 hour total, **no Go2 involved**.

### Data Management (Standalone)

Store SO-ARM datasets in MinIO (independent of Go2 data):

```bash
# Dataset structure
/srv/robot-data/lerobot_datasets/
└── ${HF_USER}/
    ├── pick_and_place_blocks/
    │   ├── data/              # HDF5 episode data
    │   ├── videos/            # Wrist camera videos
    │   └── meta/              # Dataset metadata
    ├── assembly_task/
    ├── pouring_task/
    └── stacking_task/

# Policies
/srv/robot-data/lerobot_policies/
├── pick_place_v1/
├── assembly_v2/
└── pouring_diffusion_v1/
```

**Track experiments in MLflow**:
```python
import mlflow

mlflow.set_tracking_uri("http://localhost:5001")
mlflow.set_experiment("soarm_manipulation")  # Separate from Go2 experiments

with mlflow.start_run(run_name="pick_place_act_v1"):
    mlflow.log_params({
        "policy": "ACT",
        "episodes": 50,
        "task": "pick_and_place_blocks"
    })
    
    # Training happens...
    
    mlflow.log_metrics({
        "final_loss": 0.023,
        "eval_success_rate": 0.92
    })
```

**View experiments**: http://tower:5001 (SO-ARM experiments separate from Go2)

### Research Directions (Standalone)

**Without Go2, you can explore**:

1. **Policy Comparisons**:
   - Train ACT, Diffusion, VQ-BeT on same task
   - Compare sample efficiency (50 vs 100 vs 200 episodes)
   - Evaluate generalization (test on new objects)

2. **Multi-Task Learning**:
   - Train single policy on multiple tasks
   - Test task switching and transfer
   - Build reusable manipulation primitives

3. **Sim-to-Real** (future):
   - Train in LeRobot sim environments
   - Transfer to real SO-ARM
   - Study domain randomization

4. **Human-Robot Interaction**:
   - Study demonstration quality effects
   - Test active learning (robot requests demos)
   - Explore online learning (robot improves with use)

### When to Add Go2 Integration

Consider adding Go2 **only if**:
- ✅ You've mastered standalone SO-ARM manipulation
- ✅ You need mobile manipulation (fetch objects from distance)
- ✅ You have specific warehouse/inspection use cases
- ✅ You want to research coordinated multi-robot systems

**Otherwise**: SO-ARM alone provides years of manipulation research!

---

## Advanced Topics

### Custom Tasks

Define new tasks in LeRobot config:

```yaml
# /srv/robot-data/lerobot_configs/my_task.yaml
robot:
  type: so101_follower
  port: /dev/ttyUSB0
  id: tower_follower_arm

task:
  name: "pick_and_place_cube"
  episode_length: 30  # seconds
  success_criteria:
    - cube_in_box: true
```

Use in recording:
```bash
lerobot-record --config /srv/robot-data/lerobot_configs/my_task.yaml
```

### Multi-Arm Setup

Add more SO-ARM 101 pairs for complex manipulation:

```bash
# Record with 2 follower arms
lerobot-record \
  --robot-path lerobot/configs/robot/so101_follower.yaml \
  --robot-overrides robot.port=/dev/ttyUSB0,/dev/ttyUSB2 \
  --teleop-path lerobot/configs/robot/so101_leader.yaml \
  --teleop-overrides teleop.port=/dev/ttyUSB1,/dev/ttyUSB3 \
  ...
```

### Sim-to-Real Transfer (Future)

LeRobot + Isaac Sim integration (not yet implemented):

1. Train policy in Isaac Sim (MuJoCo SO-ARM model)
2. Export policy to LeRobot format
3. Deploy on real SO-ARM 101
4. Fine-tune with real-world demonstrations

**Blocker**: SO-ARM 101 not yet available in Isaac Sim assets.

## References

### Official Documentation

- **LeRobot**: https://huggingface.co/docs/lerobot
- **SO-ARM 101 Guide**: https://huggingface.co/docs/lerobot/so101
- **SO-ARM 100 Hardware**: https://github.com/TheRobotStudio/SO-ARM100

### Related ShadowHound Docs

- **Tower Setup**: [tower_sim_datalake_setup.md](tower_sim_datalake_setup.md)
- **Security**: [tower_security_credentials.md](tower_security_credentials.md)
- **go2_ros2_sdk Integration**: [go2_ros2_sdk_tower_integration.md](go2_ros2_sdk_tower_integration.md)

### Community

- **LeRobot Discord**: https://discord.gg/s3KuuzsPFb
- **SO-ARM Builders**: https://discord.com/channels/879548962464493619/1234567890123456789

## Summary

**Advantages of SO-ARM 101 on Tower**:
- ✅ Low cost (~€228 for leader + follower)
- ✅ Quick training (minutes, not hours)
- ✅ Shared infrastructure (MinIO, MLflow, GPU)
- ✅ No conflicts with Unitree Go2 setup
- ✅ Active community and tutorials

**Use Cases**:
- Learning manipulation tasks (pick/place, assembly, pouring)
- Testing imitation learning algorithms
- Rapid prototyping before deploying to expensive robots
- Educational projects and research

**Next Steps**:
1. Order SO-ARM 101 kit (~€228)
2. 3D print parts (2-3 days)
3. Assemble arms (2-3 hours each)
4. Install LeRobot (5 minutes)
5. Calibrate arms (10 minutes)
6. Record and train first task (1 hour)

**Questions?** Ask in [LeRobot Discord](https://discord.gg/s3KuuzsPFb) or ShadowHound discussions.
