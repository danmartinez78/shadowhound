---
tags: [development, rviz, simulation]
status: draft
related: []
summary: >
  Fix RViz config parsing and cyclonedds filename issues affecting the test_autonomy simulation launch.
---

# Fix RViz config for test_autonomy (Simulation)

## Purpose
Resolve RViz startup failures and misbehavior when running `./test_autonomy.sh` with the simulation autonomy launch by:
- Correcting indentation in the custom RViz config (`sim_autonomy_robot0.rviz`) so RViz2 can parse display properties.
- Fixing a filename mismatch for CycloneDDS RViz config in `launch/go2_sdk/robot.launch.py`.

## Context
- Branch: `feature/laptop-sim-integration`
- Script: `test_autonomy.sh` launches `src/shadowhound_bringup/launch/sim_autonomy.launch.py` with RViz2 enabled.
- RViz config selection in `sim_autonomy.launch.py` prefers `shadowhound_bringup/config/rviz/sim_autonomy_robot0.rviz`.
- Observed issue: RViz either fails to load or shows errors due to malformed config; additionally, Go2 SDK launch used an incorrect CycloneDDS RViz filename.

## Changes
- src/shadowhound_bringup/config/rviz/sim_autonomy_robot0.rviz
  - Fixed indentation of LaserScan display properties (`Unreliable`, `Use Fixed Frame`, `Use rainbow`, `Value`).
- launch/go2_sdk/robot.launch.py
  - Corrected `cyclonedx_config.rviz` → `cyclonedds_config.rviz` to match actual file in `go2_robot_sdk/config/`.

## Steps
1. Update files as above.
2. Rebuild and re-install the bringup package so the corrected RViz config is copied into `install/share`:
   - `colcon build --packages-select shadowhound_bringup --symlink-install`
3. Run the quick autonomy test:
   - `./test_autonomy.sh --ns robot0` (default)

## Validation
- RViz should launch without parsing errors.
- Displays populated when Isaac Sim is publishing:
  - TF tree under `robot0/*` frames
  - `/robot0/scan` LaserScan display
  - Local/Global costmaps
  - `Global Path` subscribes to `/robot0/plan`

## Notes
- The RViz file is namespaced for `robot0`. If launching with a different namespace (e.g., `robot1`), either:
  - Use the fallback `go2_robot_sdk` config, or
  - Create a variant RViz config for that namespace, or
  - Consider parameterizing the config path selection in the launch to auto-pick based on `robot_namespace`.

## Next Steps
- Add a generic, namespace-agnostic RViz config that resolves topics relative to the namespace (or dynamically rewrites RViz config via a small generator).
- Extend the RViz layout to include Nav2 and Slam Toolbox panels if desired.
