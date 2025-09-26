#!/usr/bin/env bash
# scripts/ci_preflight.sh
# Last updated: 2025-09-26
set -euo pipefail

export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}"
export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-7}"

echo "==> ShadowHound CI preflight starting"
echo "RMW_IMPLEMENTATION=$RMW_IMPLEMENTATION  ROS_DOMAIN_ID=$ROS_DOMAIN_ID"

rm -rf build/ install/ log/

test -s shadowhound.repos || (echo "ERROR: shadowhound.repos missing/empty" && exit 1)

mkdir -p src
vcs import src < shadowhound.repos

rosdep update || true
rosdep install --from-paths src -iry || true

source /opt/ros/humble/setup.bash
colcon build --symlink-install

source install/setup.bash
ros2 pkg list | grep -E 'shadowhound_(mission_agent|utils)' >/dev/null || (echo "ERROR: ShadowHound packages not found" && exit 1)

echo "✅ Preflight OK"
