#!/bin/bash
# System tuning for CycloneDDS network performance with large messages
# Reference: https://docs.ros.org/en/humble/How-To-Guides/DDS-tuning.html

set -e

echo "=== CycloneDDS Network Tuning ==="
echo ""
echo "This script tunes Linux kernel parameters for reliable delivery"
echo "of large messages (like LiDAR point clouds) over network with CycloneDDS."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script requires root privileges."
    echo "Run with: sudo $0"
    exit 1
fi

echo "Current kernel buffer settings:"
echo "  rmem_max: $(sysctl -n net.core.rmem_max) bytes"
echo "  ipfrag_high_thresh: $(sysctl -n net.ipv4.ipfrag_high_thresh) bytes"
echo "  ipfrag_time: $(sysctl -n net.ipv4.ipfrag_time) seconds"
echo ""

# Recommended values for large message transfer
RMEM_MAX=2147483647  # 2GB - maximum receive buffer size
IPFRAG_THRESH=134217728  # 128MB - IP fragment reassembly buffer
IPFRAG_TIME=3  # 3s - reduce fragment timeout from 30s default

echo "Applying recommended settings..."
echo ""

# Set maximum receive buffer size (for large messages)
echo "Setting net.core.rmem_max = $RMEM_MAX (2GB)"
sysctl -w net.core.rmem_max=$RMEM_MAX

# Increase IP fragment reassembly buffer (prevents dropped fragments)
echo "Setting net.ipv4.ipfrag_high_thresh = $IPFRAG_THRESH (128MB)"
sysctl -w net.ipv4.ipfrag_high_thresh=$IPFRAG_THRESH

# Reduce fragment timeout (prevents 30s hangs)
echo "Setting net.ipv4.ipfrag_time = $IPFRAG_TIME seconds"
sysctl -w net.ipv4.ipfrag_time=$IPFRAG_TIME

echo ""
echo "✓ Kernel parameters updated (temporary - will reset on reboot)"
echo ""

# Make permanent by creating sysctl config file
SYSCTL_CONF="/etc/sysctl.d/10-cyclonedds-network.conf"

echo "Creating permanent configuration: $SYSCTL_CONF"
cat > "$SYSCTL_CONF" <<EOF
# CycloneDDS network tuning for large message transfer
# Reference: https://docs.ros.org/en/humble/How-To-Guides/DDS-tuning.html
# Applied: $(date)

# Maximum receive buffer size (for large messages like point clouds)
net.core.rmem_max=$RMEM_MAX

# IP fragment reassembly buffer (prevents dropped fragments over network)
net.ipv4.ipfrag_high_thresh=$IPFRAG_THRESH

# IP fragment timeout (prevents 30s hangs when fragments are dropped)
net.ipv4.ipfrag_time=$IPFRAG_TIME
EOF

echo ""
echo "✓ Permanent configuration created"
echo ""
echo "New settings:"
echo "  rmem_max: $(sysctl -n net.core.rmem_max) bytes"
echo "  ipfrag_high_thresh: $(sysctl -n net.ipv4.ipfrag_high_thresh) bytes"
echo "  ipfrag_time: $(sysctl -n net.ipv4.ipfrag_time) seconds"
echo ""
echo "✓ Settings will persist across reboots"
echo ""
echo "Next steps:"
echo "  1. Make sure CYCLONEDDS_URI is set in your environment:"
echo "     export CYCLONEDDS_URI=file://\$(pwd)/config/cyclonedds_network.xml"
echo ""
echo "  2. Restart ROS 2 nodes for changes to take effect"
echo ""
