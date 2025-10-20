---
tags: [tower, simulation, troubleshooting, isaac-sim]
status: active
related: [tower_go2_isaac_sim_quickstart.md]
summary: >
  Fix for KeyError: 'obs_groups' in go2_omniverse simulation
---

# Go2 Omniverse obs_groups Error Fix

## Problem

```
KeyError: 'obs_groups'
File: rsl_rl/runners/on_policy_runner.py line 44
```

This error occurs when launching the Go2 simulation because of an API mismatch between:
- **Isaac Lab 0.47.1** includes `rsl_rl` version 2.x
- **go2_omniverse** expects `rsl_rl` version 1.x API

## Root Cause

The `obs_groups` configuration parameter was added in `rsl_rl` 2.0+ but the `go2_omniverse` repository's `agent_cfg.py` doesn't include it (expects v1.x).

## Solution Options

### Option 1: Add obs_groups to Config (Quick Fix)

Edit `~/workspace/go2_omniverse/agent_cfg.py`:

```python
# Around line 10-15, in the config dictionary, add:
'obs_groups': None,  # Use default observation grouping
```

### Option 2: Downgrade rsl_rl (Compatibility Fix)

```bash
conda activate env_isaaclab
pip install rsl-rl==1.0.2
```

**Warning**: This may break other Isaac Lab examples that expect rsl_rl 2.x.

### Option 3: Use Go2 with Isaac Lab Directly (Recommended)

Instead of using the `go2_omniverse` repository, use Isaac Lab's built-in quadruped examples:

```bash
cd ~/workspace/IsaacLab
source install/setup.bash

# List available tasks
python scripts/train.py --help

# Example: Train Unitree Go2 with PPO
python scripts/train.py --task Isaac-Velocity-Flat-Unitree-Go2-v0
```

Isaac Lab has native support for Unitree Go2 and doesn't require the external go2_omniverse repository.

## Verification

After applying fix, test:

```bash
cd ~/workspace/go2_omniverse
./run_sim.sh
```

Should launch without `obs_groups` error.

## Related Issues

- go2_omniverse uses older rsl_rl API
- Isaac Lab 0.47.1 updated to rsl_rl 2.x
- API breaking change in observation handling

## References

- rsl_rl GitHub: https://github.com/leggedrobotics/rsl_rl
- Isaac Lab Quadruped Tasks: `IsaacLab/source/extensions/omni.isaac.lab_tasks/omni/isaac/lab_tasks/manager_based/locomotion/velocity/`
