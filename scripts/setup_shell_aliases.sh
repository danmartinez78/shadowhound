#!/usr/bin/env bash
#
# Setup convenient shell aliases for ShadowHound development
#

set -euo pipefail

BASHRC="$HOME/.bashrc"

echo "Setting up ShadowHound shell aliases..."
echo ""

# Check if aliases already exist
if grep -q "# ShadowHound Aliases" "$BASHRC" 2>/dev/null; then
    echo "⚠️  ShadowHound aliases already present in ~/.bashrc"
    echo "   Remove them manually if you want to regenerate"
    exit 0
fi

# Add aliases to .bashrc
cat >> "$BASHRC" <<'EOF'

# ShadowHound Aliases
# Added by setup_shell_aliases.sh

# Activate Isaac Lab environment
alias isaac='source ~/.robot-simrc && conda activate env_isaaclab'

# Activate ROS 2 environment
alias ros2-env='source /opt/ros/humble/setup.bash'

# Activate both Isaac Lab + ROS 2 (full robot development environment)
alias shadowhound='source ~/.robot-simrc && conda activate env_isaaclab && source /opt/ros/humble/setup.bash'

# Quick navigation
alias cdisaac='cd ~/workspace/IsaacLab'
alias cdgo2='cd ~/workspace/go2_omniverse'
alias cdsh='cd ~/shadowhound'

# Service management
alias tower-status='sudo systemctl status robot-datalake'
alias tower-logs='sudo journalctl -u robot-datalake -f'
alias tower-restart='sudo systemctl restart robot-datalake'

# Isaac Sim shortcuts (requires isaac environment active)
alias isaac-sim='cd ~/workspace/IsaacLab && ./isaaclab.sh'
alias isaac-python='cd ~/workspace/IsaacLab && ./isaaclab.sh -p'

# MinIO/MLflow shortcuts
alias minio-ui='echo "MinIO UI: http://$(hostname -I | awk "{print \$1}"):9001"'
alias mlflow-ui='echo "MLflow UI: http://$(hostname -I | awk "{print \$1}"):5001"'
EOF

echo "✓ Aliases added to $BASHRC"
echo ""
echo "Available aliases:"
echo ""
echo "  Environment Activation:"
echo "    isaac          - Activate Isaac Lab conda environment"
echo "    ros2-env       - Activate ROS 2 Humble environment"
echo "    shadowhound    - Activate both Isaac Lab + ROS 2"
echo ""
echo "  Navigation:"
echo "    cdisaac        - cd ~/workspace/IsaacLab"
echo "    cdgo2          - cd ~/workspace/go2_omniverse"
echo "    cdsh           - cd ~/shadowhound"
echo ""
echo "  Services:"
echo "    tower-status   - Check robot-datalake service status"
echo "    tower-logs     - View robot-datalake logs (live)"
echo "    tower-restart  - Restart robot-datalake services"
echo ""
echo "  Isaac Sim:"
echo "    isaac-sim      - Run Isaac Sim/Isaac Lab launcher"
echo "    isaac-python   - Run Isaac Lab Python scripts"
echo ""
echo "  Web UIs:"
echo "    minio-ui       - Show MinIO web UI URL"
echo "    mlflow-ui      - Show MLflow web UI URL"
echo ""
echo "To activate aliases in current session:"
echo "  source ~/.bashrc"
echo ""
echo "Or open a new terminal window"
