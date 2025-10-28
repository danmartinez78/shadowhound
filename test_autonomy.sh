#!/bin/bash
# Autonomy stack launcher and validator wrapper
#
# Modes:
#   (default) launch-only  -> Launches the stack and blocks until Ctrl+C
#   --validate-only        -> Runs Python validator against a running stack
#   --both                 -> Launch in background, run validator, optionally exit
#
# Usage examples:
#   ./test_autonomy.sh --ns robot0                    # launch only
#   ./test_autonomy.sh --validate-only --ns robot0    # validate only
#   ./test_autonomy.sh --both --ns robot0 --timeout 8 --auto-exit  # launch, validate, then exit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  Quick Autonomy Stack Test Launcher"
echo "========================================"
echo ""

# Source environment
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Source ROS2
if [ -f "/opt/ros/humble/setup.bash" ]; then
    source /opt/ros/humble/setup.bash
fi

# Source workspace
if [ -f "$SCRIPT_DIR/install/setup.bash" ]; then
    source "$SCRIPT_DIR/install/setup.bash"
fi

# Set ROS environment
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
export ROS_LOCALHOST_ONLY=${ROS_LOCALHOST_ONLY:-0}

# Don't force RMW implementation unless already set
if [ -z "${RMW_IMPLEMENTATION:-}" ]; then
    echo "Using default RMW implementation (FastDDS)"
else
    echo "Using RMW implementation: $RMW_IMPLEMENTATION"
fi

MODE="launch"
ROBOT_NS="${ROBOT_NAMESPACE:-robot0}"
TIMEOUT="8.0"
AUTO_EXIT="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ns)
            ROBOT_NS="$2"; shift 2;;
        --timeout)
            TIMEOUT="$2"; shift 2;;
        --validate-only)
            MODE="validate"; shift 1;;
        --both)
            MODE="both"; shift 1;;
        --auto-exit)
            AUTO_EXIT="true"; shift 1;;
        -h|--help)
            echo "Usage: $0 [--ns <robot_namespace>] [--timeout <seconds>] [--validate-only|--both] [--auto-exit]"; exit 0;;
        *)
            echo "Unknown arg: $1"; exit 2;;
    esac
done

echo ""
echo "Configuration:"
echo "  Robot namespace: $ROBOT_NS"
echo "  Mode: $MODE"
echo "  Validator timeout: $TIMEOUT s"
echo "  ROS Domain ID: $ROS_DOMAIN_ID"
echo "  ROS Localhost Only: $ROS_LOCALHOST_ONLY"
echo "  RMW: ${RMW_IMPLEMENTATION:-default}"
echo ""

# Launch file
LAUNCH_FILE="$SCRIPT_DIR/src/shadowhound_bringup/launch/sim_autonomy.launch.py"

if [ ! -f "$LAUNCH_FILE" ]; then
        echo "ERROR: Launch file not found: $LAUNCH_FILE"
        exit 1
fi

# Helper to run the Python validator
run_validator() {
    local ns="$1"; local timeout="$2"
    if ! command -v python3 >/dev/null 2>&1; then
        echo "ERROR: python3 not found on PATH" >&2; return 10
    fi
    local script_path="$SCRIPT_DIR/test_scripts/test_autonomy.py"
    if [ ! -f "$script_path" ]; then
        echo "ERROR: validator not found: $script_path" >&2; return 11
    fi
    echo "Running autonomy validator (ns=$ns, timeout=$timeout)"
    python3 "$script_path" --ns "$ns" --timeout "$timeout"
}

case "$MODE" in
    launch)
        echo "Launching autonomy stack..."
        echo "  Launch file: $LAUNCH_FILE"
        echo "  Namespace: $ROBOT_NS"
        echo ""
        echo "Components launching:"
        echo "  - Pointcloud to laserscan converter"
        echo "  - Nav2 navigation stack"
        echo "  - SLAM Toolbox"
        echo "  - Foxglove Bridge"
        echo "  - RViz2"
        echo ""
        echo "Press Ctrl+C to stop"
        echo ""
        ros2 launch "$LAUNCH_FILE" \
            robot_namespace:="$ROBOT_NS" \
            rviz2:=True \
            nav2:=True \
            slam:=True \
            foxglove:=True
        echo ""; echo "Autonomy stack stopped";;
    validate)
        run_validator "$ROBOT_NS" "$TIMEOUT";;
    both)
        echo "Starting autonomy stack in background..."
        set +e  # We don't want the subshell background to trip -e
        ros2 launch "$LAUNCH_FILE" \
            robot_namespace:="$ROBOT_NS" \
            rviz2:=True \
            nav2:=True \
            slam:=True \
            foxglove:=True &
        LAUNCH_PID=$!
        set -e
        echo "Launch PID: $LAUNCH_PID"
        echo "Waiting for stack to initialize..."
        sleep 8
        run_validator "$ROBOT_NS" "$TIMEOUT"
        VALID_RC=$?
        if [ "$AUTO_EXIT" = "true" ]; then
            echo "AUTO_EXIT true: stopping launch (PID $LAUNCH_PID)"
            kill $LAUNCH_PID || true
            # Give processes time to terminate
            sleep 2
        else
            echo "Launch remains running. Press Ctrl+C to stop."
            wait $LAUNCH_PID
        fi
        exit $VALID_RC;;
esac
