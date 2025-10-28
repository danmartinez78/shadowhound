#!/usr/bin/env bash
# Lightweight wrapper to run the Python autonomy validator with sensible defaults.
# Usage:
#   bash test_scripts/test_autonomy.sh --ns robot0 --timeout 8.0
#
# Exits non-zero if any validation check fails.

set -euo pipefail

NS="robot0"
TIMEOUT="8.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ns)
      NS="$2"; shift 2;;
    --timeout)
      TIMEOUT="$2"; shift 2;;
    -h|--help)
      echo "Usage: $0 [--ns <robot_namespace>] [--timeout <seconds>]"; exit 0;;
    *)
      echo "Unknown arg: $1"; exit 2;;
  esac
done

# Basic sanity: ensure ROS 2 CLI is available (user should have sourced the workspace)
if ! command -v ros2 >/dev/null 2>&1; then
  echo "ERROR: 'ros2' CLI not found. Source your ROS 2 workspace (e.g., 'source install/setup.bash') and retry." >&2
  exit 3
fi

# Run the Python validator
python3 "$(dirname "$0")/test_autonomy.py" --ns "$NS" --timeout "$TIMEOUT"