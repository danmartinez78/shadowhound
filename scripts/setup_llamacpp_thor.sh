#!/bin/bash
# Setup script for llama.cpp on Thor (Jetson AGX Orin)
# This replaces Ollama for more stable local LLM inference
# Related: Issue #12 - Evaluate alternatives to Ollama

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}llama.cpp Setup for Thor (Jetson AGX Orin)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Configuration
LLAMACPP_DIR="${HOME}/llama.cpp"
MODEL_DIR="${LLAMACPP_DIR}/models"
MODEL_NAME="qwen2.5-coder-7b-instruct-q4_k_m.gguf"
MODEL_URL="Qwen/Qwen2.5-Coder-7B-Instruct-GGUF"
SERVER_PORT=8080
CTX_SIZE=8192
GPU_LAYERS=35  # Adjust based on your GPU memory

# Step 1: Check if running on Thor
echo -e "${YELLOW}[1/8] Checking system...${NC}"
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}Error: nvidia-smi not found. Is this running on Thor with CUDA?${NC}"
    exit 1
fi
echo -e "${GREEN}✓ CUDA detected${NC}"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
echo ""

# Step 2: Stop Ollama if running
echo -e "${YELLOW}[2/8] Stopping Ollama (to free GPU memory)...${NC}"
if docker ps | grep -q ollama; then
    docker stop ollama || echo -e "${YELLOW}Could not stop Ollama container${NC}"
    echo -e "${GREEN}✓ Ollama stopped${NC}"
else
    echo -e "${GREEN}✓ Ollama not running${NC}"
fi
echo ""

# Step 3: Install dependencies
echo -e "${YELLOW}[3/8] Installing dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    python3-pip \
    libopenblas-dev

# Install huggingface-cli for model downloads
pip3 install --user huggingface-hub[cli]
export PATH="${HOME}/.local/bin:${PATH}"
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 4: Clone llama.cpp if needed
echo -e "${YELLOW}[4/8] Setting up llama.cpp...${NC}"
if [ -d "${LLAMACPP_DIR}" ]; then
    echo -e "${YELLOW}llama.cpp directory exists, pulling latest...${NC}"
    cd "${LLAMACPP_DIR}"
    git pull
else
    echo -e "${YELLOW}Cloning llama.cpp...${NC}"
    git clone https://github.com/ggerganov/llama.cpp "${LLAMACPP_DIR}"
    cd "${LLAMACPP_DIR}"
fi
echo -e "${GREEN}✓ llama.cpp ready${NC}"
echo ""

# Step 5: Build llama.cpp with CUDA support
echo -e "${YELLOW}[5/8] Building llama.cpp with CUDA support...${NC}"
echo -e "${YELLOW}This may take 5-10 minutes...${NC}"
cd "${LLAMACPP_DIR}"

# Clean previous build
make clean || true

# Build with CUDA
if make LLAMA_CUDA=1 -j$(nproc); then
    echo -e "${GREEN}✓ llama.cpp built successfully${NC}"
else
    echo -e "${RED}Error: Build failed. Check output above.${NC}"
    exit 1
fi
echo ""

# Step 6: Download model
echo -e "${YELLOW}[6/8] Downloading Qwen2.5-Coder 7B GGUF model...${NC}"
mkdir -p "${MODEL_DIR}"
cd "${MODEL_DIR}"

if [ -f "${MODEL_NAME}" ]; then
    echo -e "${GREEN}✓ Model already downloaded${NC}"
else
    echo -e "${YELLOW}Downloading ~4.4GB model (this will take a while)...${NC}"
    if huggingface-cli download "${MODEL_URL}" "${MODEL_NAME}" --local-dir . --local-dir-use-symlinks False; then
        echo -e "${GREEN}✓ Model downloaded${NC}"
    else
        echo -e "${RED}Error: Model download failed${NC}"
        exit 1
    fi
fi
echo ""

# Step 7: Create systemd service
echo -e "${YELLOW}[7/8] Creating systemd service for llama.cpp server...${NC}"

# Create service file
sudo tee /etc/systemd/system/llamacpp.service > /dev/null <<EOF
[Unit]
Description=llama.cpp Server for ShadowHound
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${LLAMACPP_DIR}
ExecStart=${LLAMACPP_DIR}/llama-server \\
    --model ${MODEL_DIR}/${MODEL_NAME} \\
    --ctx-size ${CTX_SIZE} \\
    --n-gpu-layers ${GPU_LAYERS} \\
    --port ${SERVER_PORT} \\
    --host 0.0.0.0 \\
    --threads $(nproc) \\
    --parallel 1 \\
    --log-disable
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable llamacpp.service
echo -e "${GREEN}✓ Systemd service created${NC}"
echo ""

# Step 8: Start the server
echo -e "${YELLOW}[8/8] Starting llama.cpp server...${NC}"
sudo systemctl restart llamacpp.service
sleep 3

# Check if server is running
if sudo systemctl is-active --quiet llamacpp.service; then
    echo -e "${GREEN}✓ llama.cpp server started${NC}"
else
    echo -e "${RED}Error: Server failed to start. Check logs with: sudo journalctl -u llamacpp -n 50${NC}"
    exit 1
fi
echo ""

# Step 9: Test the server
echo -e "${YELLOW}Testing server...${NC}"
sleep 2
if curl -s http://localhost:${SERVER_PORT}/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server responding${NC}"
else
    echo -e "${YELLOW}Warning: Server not responding yet (may still be loading model)${NC}"
fi
echo ""

# Print summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}llama.cpp server is running on Thor${NC}"
echo ""
echo -e "Configuration:"
echo -e "  Model: ${MODEL_NAME}"
echo -e "  Port: ${SERVER_PORT}"
echo -e "  Context: ${CTX_SIZE} tokens"
echo -e "  GPU Layers: ${GPU_LAYERS}"
echo ""
echo -e "Service commands:"
echo -e "  Status:  ${YELLOW}sudo systemctl status llamacpp${NC}"
echo -e "  Logs:    ${YELLOW}sudo journalctl -u llamacpp -f${NC}"
echo -e "  Stop:    ${YELLOW}sudo systemctl stop llamacpp${NC}"
echo -e "  Start:   ${YELLOW}sudo systemctl start llamacpp${NC}"
echo -e "  Restart: ${YELLOW}sudo systemctl restart llamacpp${NC}"
echo ""
echo -e "Test API:"
echo -e "  ${YELLOW}curl -X POST http://localhost:${SERVER_PORT}/v1/chat/completions \\${NC}"
echo -e "    ${YELLOW}-H 'Content-Type: application/json' \\${NC}"
echo -e "    ${YELLOW}-d '{\"model\":\"${MODEL_NAME}\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}]}'${NC}"
echo ""
echo -e "${BLUE}Next steps on laptop:${NC}"
echo -e "1. Update ${YELLOW}.env${NC} file:"
echo -e "   ${YELLOW}AGENT_BACKEND=openai${NC}"
echo -e "   ${YELLOW}OPENAI_BASE_URL=http://192.168.10.116:${SERVER_PORT}/v1${NC}"
echo -e "   ${YELLOW}OPENAI_MODEL=${MODEL_NAME}${NC}"
echo -e "   ${YELLOW}USE_PLANNING_AGENT=false${NC}"
echo ""
echo -e "2. Rebuild and test:"
echo -e "   ${YELLOW}cd ~/shadowhound${NC}"
echo -e "   ${YELLOW}git pull origin feature/local-llm-support${NC}"
echo -e "   ${YELLOW}colcon build --packages-select shadowhound_mission_agent${NC}"
echo -e "   ${YELLOW}source install/setup.bash${NC}"
echo -e "   ${YELLOW}./start.sh${NC}"
echo ""
echo -e "${GREEN}Done! Issue #12 - llama.cpp setup complete${NC}"
