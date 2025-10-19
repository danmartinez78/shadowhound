#!/usr/bin/env bash
#
# PCIe Configuration Checker for Multi-GPU Systems
# Checks hardware configuration and suggests BIOS changes
#

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  PCIe Configuration Checker for Multi-GPU                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root for some commands
if [[ $EUID -ne 0 ]]; then
   echo "⚠️  Some checks require root. Consider running with: sudo $0"
   echo ""
fi

echo "═══ MOTHERBOARD INFO ═══"
sudo dmidecode -t baseboard 2>/dev/null | grep -E "(Manufacturer|Product Name|Version)" || echo "dmidecode not available"
echo ""

echo "═══ NVIDIA GPUs DETECTED BY PCI ═══"
lspci | grep -i nvidia | nl -v 0 -w 1 -s '. '
gpu_count=$(lspci | grep -i nvidia | wc -l)
echo ""
echo "Total GPUs on PCI bus: $gpu_count"
echo ""

if [[ $gpu_count -eq 0 ]]; then
    echo "❌ ERROR: No NVIDIA GPUs detected on PCI bus!"
    echo "   - Check GPU is seated properly"
    echo "   - Check PCIe power cables connected"
    echo "   - Check BIOS hasn't disabled PCIe slots"
    exit 1
fi

echo "═══ NVIDIA GPUs DETECTED BY DRIVER ═══"
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi -L
    driver_gpu_count=$(nvidia-smi -L | wc -l)
    echo ""
    echo "Total GPUs visible to driver: $driver_gpu_count"
    
    if [[ $driver_gpu_count -lt $gpu_count ]]; then
        echo ""
        echo "⚠️  WARNING: PCI sees $gpu_count GPU(s) but driver sees only $driver_gpu_count"
        echo "   This suggests a driver initialization problem"
    fi
else
    echo "nvidia-smi not available (driver not installed?)"
    driver_gpu_count=0
fi
echo ""

echo "═══ PCIe LINK STATUS ═══"
echo "Checking PCIe link speed and width for each GPU..."
echo ""

lspci | grep -i nvidia | while read -r line; do
    bus_id=$(echo "$line" | cut -d' ' -f1)
    gpu_name=$(echo "$line" | cut -d':' -f3-)
    
    echo "GPU: $gpu_name"
    echo "Bus: $bus_id"
    
    # Get link status
    link_status=$(sudo lspci -vv -s "$bus_id" 2>/dev/null | grep -A 2 "LnkSta:")
    
    if [[ -n "$link_status" ]]; then
        speed=$(echo "$link_status" | grep "LnkSta:" | sed 's/.*Speed \([^,]*\).*/\1/')
        width=$(echo "$link_status" | grep "LnkSta:" | sed 's/.*Width \([^,]*\).*/\1/')
        
        echo "  Current: $speed, $width"
        
        # Check capabilities
        capabilities=$(sudo lspci -vv -s "$bus_id" 2>/dev/null | grep "LnkCap:")
        max_speed=$(echo "$capabilities" | sed 's/.*Speed \([^,]*\).*/\1/')
        max_width=$(echo "$capabilities" | sed 's/.*Width \([^,]*\).*/\1/')
        echo "  Maximum: $max_speed, $max_width"
        
        # Warnings
        if [[ "$width" != "x16" ]] && [[ "$width" != "x8" ]]; then
            echo "  ⚠️  WARNING: Running at reduced width ($width)"
        fi
        
        if [[ "$speed" == "2.5GT/s" ]]; then
            echo "  ⚠️  WARNING: Running at PCIe 1.0 speed (very slow)"
        fi
    else
        echo "  ⚠️  Could not read PCIe link status (need root?)"
    fi
    echo ""
done

echo "═══ IOMMU / VT-d STATUS ═══"
if dmesg 2>/dev/null | grep -q "DMAR: IOMMU enabled"; then
    echo "✓ IOMMU (VT-d) is ENABLED"
    echo "  This is good for virtualization but not required for multi-GPU"
else
    echo "○ IOMMU (VT-d) is disabled or not supported"
    echo "  This is fine for normal multi-GPU usage"
fi
echo ""

echo "═══ MEMORY MAPPING ═══"
echo "Checking if GPUs have proper memory BAR allocation..."
echo ""

lspci | grep -i nvidia | while read -r line; do
    bus_id=$(echo "$line" | cut -d' ' -f1)
    gpu_name=$(echo "$line" | cut -d':' -f3- | xargs)
    
    echo "$gpu_name ($bus_id):"
    
    # Get memory regions
    sudo lspci -vv -s "$bus_id" 2>/dev/null | grep "Region" | head -n 3
    echo ""
done

echo "═══ KERNEL MESSAGES (NVIDIA) ═══"
echo "Last 20 NVIDIA-related kernel messages:"
echo ""
dmesg 2>/dev/null | grep -i nvidia | tail -20 || echo "Could not read dmesg (need root?)"
echo ""

echo "═══ RECOMMENDATIONS ═══"

issues_found=0

# Check GPU count mismatch
if [[ $driver_gpu_count -lt $gpu_count ]] && [[ $driver_gpu_count -gt 0 ]]; then
    echo "❌ GPU COUNT MISMATCH"
    echo "   PCI detects $gpu_count GPU(s) but driver sees $driver_gpu_count"
    echo "   BIOS Action: None needed, this is a driver issue"
    echo "   Fix: Reinstall/downgrade NVIDIA driver to 550"
    echo ""
    issues_found=$((issues_found + 1))
fi

# Check for BAR allocation errors in dmesg
if dmesg 2>/dev/null | grep -i nvidia | grep -qi "BAR.*no space"; then
    echo "❌ GPU MEMORY ALLOCATION ERROR"
    echo "   Kernel cannot allocate memory space for GPU"
    echo "   BIOS Action: Enable 'Memory Remap Feature' or 'Memory Hole Remapping'"
    echo "   Location: Advanced → System Agent Configuration"
    echo ""
    issues_found=$((issues_found + 1))
fi

# Check for PCIe errors
if dmesg 2>/dev/null | grep -i nvidia | grep -qi "error\|fail\|timeout"; then
    echo "⚠️  PCIE COMMUNICATION ERRORS DETECTED"
    echo "   Check: dmesg | grep -i nvidia | grep -i error"
    echo "   BIOS Action: Disable Fast Boot"
    echo "   Location: Boot → Fast Boot → Disabled"
    echo ""
    issues_found=$((issues_found + 1))
fi

# Check link width
if lspci -vv 2>/dev/null | grep -A 2 nvidia | grep "LnkSta:" | grep -q "Width x[1-4]"; then
    echo "⚠️  GPU RUNNING AT REDUCED PCIE WIDTH"
    echo "   One or more GPUs running at x4 or less"
    echo "   BIOS Action: Check PCIe slot configuration"
    echo "   Physical: Ensure GPU is fully seated in slot"
    echo ""
    issues_found=$((issues_found + 1))
fi

if [[ $issues_found -eq 0 ]]; then
    echo "✓ No obvious PCIe configuration issues detected!"
    echo ""
    echo "If GPU still disappears after boot:"
    echo "  1. Downgrade to driver 550 (run install script)"
    echo "  2. Enable persistence mode: sudo nvidia-smi -pm 1"
    echo "  3. Monitor with: watch -n 2 nvidia-smi"
fi

echo ""
echo "═══ BIOS SETTINGS CHECKLIST ═══"
echo ""
echo "Settings to verify in BIOS (ASUS X99-E WS):"
echo ""
echo "  Advanced → System Agent Configuration:"
echo "    [ ] Memory Remap Feature: ENABLED"
echo ""
echo "  Advanced → Onboard Devices Configuration:"
echo "    [ ] Primary Graphics: PCIe or PCIE_1"
echo ""
echo "  Boot:"
echo "    [ ] Fast Boot: DISABLED"
echo ""
echo "  (Optional) Advanced → CPU Configuration:"
echo "    [ ] C-States: DISABLED (if GPU disappears)"
echo ""

echo "═══ NEXT STEPS ═══"
echo ""
echo "1. Review recommendations above"
echo "2. Enter BIOS (Del key at boot)"
echo "3. Make suggested changes"
echo "4. Save and reboot"
echo "5. Re-run this script to verify"
echo ""
