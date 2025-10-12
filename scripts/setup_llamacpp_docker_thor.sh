#!/bin/bash
# llama.cpp Docker setup for Thor (Jetson AGX Orin)
# Uses official ghcr.io/ggml-org/llama.cpp:server-cuda image
# BACKUP option if vLLM has issues
# Related: Issue #12 - Evaluate alternatives to Ollama

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}llama.cpp Docker Setup for Thor${NC}"
echo -e "${BLUE}(Backup option - use if vLLM fails)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Configuration
CONTAINER_NAME="llamacpp-server"
IMAGE="ghcr.io/ggml-org/llama.cpp:server-cuda"
MODEL_DIR="${HOME}/llama_models"
MODEL_NAME="qwen2.5-coder-7b-instruct-q4_k_m.gguf"
MODEL_URL="Qwen/Qwen2.5-Coder-7B-Instruct-GGUF"
SERVER_PORT=8080
CTX_SIZE=8192
GPU_LAYERS=35

echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Container: ${CONTAINER_NAME}"
echo -e "  Image: ${IMAGE}"
echo -e "  Model: ${MODEL_NAME}"
echo -e "  Port: ${SERVER_PORT}"
echo -e "  Context: ${CTX_SIZE} tokens"
echo -e "  GPU Layers: ${GPU_LAYERS}"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker installed${NC}"

if ! docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi &> /dev/null 2>&1; then
    echo -e "${RED}Error: NVIDIA Docker runtime not working${NC}"
    exit 1
fi
echo -e "${GREEN}✓ NVIDIA Docker runtime working${NC}"
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo ""

# Step 2: Stop other LLM servers
echo -e "${YELLOW}[2/6] Stopping other LLM servers...${NC}"
docker stop ollama 2>/dev/null || true
docker stop vllm-server 2>/dev/null || true
echo -e "${GREEN}✓ Other servers stopped${NC}"
echo ""

# Step 3: Create model directory
echo -e "${YELLOW}[3/6] Setting up model directory...${NC}"
mkdir -p "${MODEL_DIR}"
echo -e "${GREEN}✓ Model directory: ${MODEL_DIR}${NC}"
echo ""

# Step 4: Download model if needed
echo -e "${YELLOW}[4/6] Downloading model...${NC}"
if [ -f "${MODEL_DIR}/${MODEL_NAME}" ]; then
    echo -e "${GREEN}✓ Model already downloaded${NC}"
else
    echo -e "${YELLOW}Downloading ~4.4GB GGUF model (this will take a while)...${NC}"
    
    # Install huggingface-cli if not present
    if ! command -v huggingface-cli &> /dev/null; then
        pip3 install --user huggingface-hub[cli]
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
    
    cd "${MODEL_DIR}"
    if huggingface-cli download "${MODEL_URL}" "${MODEL_NAME}" --local-dir . --local-dir-use-symlinks False; then
        echo -e "${GREEN}✓ Model downloaded${NC}"
    else
        echo -e "${RED}Error: Model download failed${NC}"
        exit 1
    fi
fi
echo ""

# Step 5: Pull Docker image
echo -e "${YELLOW}[5/6] Pulling llama.cpp Docker image...${NC}"
echo -e "${YELLOW}This may take a while (~8GB)...${NC}"
if docker pull "${IMAGE}"; then
    echo -e "${GREEN}✓ Docker image pulled${NC}"
else
    echo -e "${RED}Error: Failed to pull Docker image${NC}"
    exit 1
fi
echo ""

# Step 6: Clean up existing container
echo -e "${YELLOW}[6/6] Cleaning up existing container...${NC}"
if docker ps -a | grep -q "${CONTAINER_NAME}"; then
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
    echo -e "${GREEN}✓ Old container removed${NC}"
else
    echo -e "${GREEN}✓ No existing container${NC}"
fi
echo ""

# Clear memory
echo -e "${YELLOW}Clearing system memory cache...${NC}"
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
echo -e "${GREEN}✓ Memory cleared${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Starting llama.cpp Server${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Server will start and load model (~30 seconds)${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Start llama.cpp server
docker run --rm -it \
    --name "${CONTAINER_NAME}" \
    --gpus all \
    --network host \
    -v "${MODEL_DIR}:/models" \
    "${IMAGE}" \
    -m "/models/${MODEL_NAME}" \
    --ctx-size "${CTX_SIZE}" \
    --n-gpu-layers "${GPU_LAYERS}" \
    --port "${SERVER_PORT}" \
    --host 0.0.0.0 \
    --threads $(nproc) \
    --parallel 1

echo ""
echo -e "${GREEN}Server stopped${NC}"
