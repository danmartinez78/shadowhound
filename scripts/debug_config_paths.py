#!/usr/bin/env python3
"""Debug script to show what config paths the launch file computes"""

import os
from ament_index_python.packages import get_package_share_directory

print("=" * 60)
print("Config Path Debug")
print("=" * 60)

# Mimic the launch file logic
shadowhound_dir = get_package_share_directory("shadowhound_bringup")
go2_sdk_dir = get_package_share_directory("go2_robot_sdk")

print(f"\nshadowhound_bringup package: {shadowhound_dir}")
print(f"go2_robot_sdk package: {go2_sdk_dir}")

# Compute the config dir the same way the launch file does
shadowhound_config_dir = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(shadowhound_dir))),
    "config",
)

print(f"\nComputed config dir: {shadowhound_config_dir}")
print(f"Config dir exists: {os.path.exists(shadowhound_config_dir)}")

# Check for simulation configs
nav2_sim_config = os.path.join(shadowhound_config_dir, "nav2_params_simulation.yaml")
slam_sim_config = os.path.join(shadowhound_config_dir, "mapper_params_simulation.yaml")

print(f"\nNav2 sim config: {nav2_sim_config}")
print(f"  Exists: {os.path.exists(nav2_sim_config)}")
if os.path.exists(nav2_sim_config):
    print(f"  Size: {os.path.getsize(nav2_sim_config)} bytes")
    
print(f"\nSLAM sim config: {slam_sim_config}")
print(f"  Exists: {os.path.exists(slam_sim_config)}")
if os.path.exists(slam_sim_config):
    print(f"  Size: {os.path.getsize(slam_sim_config)} bytes")

# Show what would be selected
if os.path.exists(nav2_sim_config):
    print(f"\n✅ Would use: {nav2_sim_config}")
else:
    fallback = os.path.join(go2_sdk_dir, "config", "nav2_params.yaml")
    print(f"\n❌ Sim config not found, would fall back to: {fallback}")

print("=" * 60)
