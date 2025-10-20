#!/bin/bash
# Diagnose Isaac Sim freezing issues on Tower
# Run this WHILE Isaac Sim is frozen

echo "=== ISAAC SIM FREEZE DIAGNOSTICS ==="
echo "Timestamp: $(date)"
echo ""

# Check GPU status
echo "=== GPU STATUS ==="
nvidia-smi
echo ""

# Check for GPU memory issues
echo "=== GPU MEMORY USAGE ==="
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
echo ""

# Check for hung processes
echo "=== ISAAC SIM PROCESSES ==="
ps aux | grep -E "isaac|omni|kit" | grep -v grep
echo ""

# Check X11/display
echo "=== DISPLAY STATUS ==="
echo "DISPLAY: $DISPLAY"
xdpyinfo | head -20 2>&1 || echo "xdpyinfo failed - X11 issue?"
echo ""

# Check system load
echo "=== SYSTEM LOAD ==="
uptime
free -h
echo ""

# Check for I/O wait
echo "=== I/O WAIT ==="
iostat -x 1 2 2>/dev/null || echo "iostat not available"
echo ""

# Check journalctl for recent errors
echo "=== RECENT SYSTEM ERRORS ==="
sudo journalctl -n 50 --no-pager | grep -i "error\|segfault\|gpu\|nvidia" || echo "No recent errors"
echo ""

# Suggest recovery options
echo "=== RECOVERY OPTIONS ==="
echo "1. Kill frozen Isaac Sim:"
echo "   pkill -9 -f isaac"
echo ""
echo "2. Reset GPU (if driver hung):"
echo "   sudo nvidia-smi --gpu-reset"
echo ""
echo "3. Try headless mode (no GUI):"
echo "   cd ~/workspace/go2_omniverse"
echo "   python main.py --robot go2 --headless"
echo ""
echo "4. Check logs:"
echo "   tail -100 ~/.nvidia-omniverse/logs/Kit/Isaac-Sim/*/kit*.log"
echo ""
