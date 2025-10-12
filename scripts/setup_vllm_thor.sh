#!/bin/bash
# vLLM Docker setup for Thor (Jetson AGX Orin)
# Uses official NVIDIA vLLM container optimized for Thor
# Related: Issue #12 - Evaluate alternatives to Ollama

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}vLLM Setup for Thor (Jetson AGX Orin)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Configuration
CONTAINER_NAME="vllm-server"
IMAGE="nvcr.io/nvidia/vllm:25.09-py3"
MODEL="mistralai/Mistral-7B-Instruct-v0.3"
SERVER_PORT=8000
MAX_MODEL_LEN=8192
GPU_MEMORY=0.8

# Note: Qwen model requires HuggingFace authentication
# Run: huggingface-cli login
# Token will be saved to ~/.cache/huggingface/token and persist across sessions
# Alternative: Set HF_TOKEN environment variable

echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Container: ${CONTAINER_NAME}"
echo -e "  Image: ${IMAGE}"
echo -e "  Model: ${MODEL}"
echo -e "  Port: ${SERVER_PORT}"
echo -e "  Max Length: ${MAX_MODEL_LEN}"
echo ""

# Note: Mistral has built-in tool calling and is Apache 2.0 licensed (no gating!)
echo -e "${GREEN}ℹ️  Mistral-7B-Instruct-v0.3:${NC}"
echo -e "  - Native tool calling support"
echo -e "  - Apache 2.0 license (no restrictions!)"
echo -e "  - Officially validated with vLLM"
echo -e "  - No HuggingFace authentication required"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"

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

# Step 2: Stop Ollama if running
echo -e "${YELLOW}[2/5] Stopping Ollama (to free GPU memory)...${NC}"
if docker ps | grep -q ollama; then
    docker stop ollama 2>/dev/null || true
    echo -e "${GREEN}✓ Ollama stopped${NC}"
else
    echo -e "${GREEN}✓ Ollama not running${NC}"
fi
echo ""

# Step 3: Pull vLLM image
echo -e "${YELLOW}[3/5] Pulling NVIDIA vLLM container...${NC}"
echo -e "${YELLOW}This is ~10GB, may take a while...${NC}"
if docker pull "${IMAGE}"; then
    echo -e "${GREEN}✓ Image pulled${NC}"
else
    echo -e "${RED}Error: Failed to pull image${NC}"
    exit 1
fi
echo ""

# Step 4: Stop existing container if running
echo -e "${YELLOW}[4/5] Cleaning up existing container...${NC}"
if docker ps -a | grep -q "${CONTAINER_NAME}"; then
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
    echo -e "${GREEN}✓ Old container removed${NC}"
else
    echo -e "${GREEN}✓ No existing container${NC}"
fi
echo ""

# Step 5: Create cache directory
echo -e "${YELLOW}[5/5] Setting up cache directory...${NC}"
mkdir -p "$HOME/.cache/huggingface"
echo -e "${GREEN}✓ Cache directory ready${NC}"
echo ""

# Clear memory cache
echo -e "${YELLOW}Clearing system memory cache...${NC}"
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
echo -e "${GREEN}✓ Memory cache cleared${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Starting vLLM Server${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo -e "  1. Download model (~4-5GB) on first run"
echo -e "  2. Load model into GPU memory (~30-60 seconds)"
echo -e "  3. Start OpenAI-compatible API on port ${SERVER_PORT}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""
echo -e "${YELLOW}Starting container...${NC}"

docker run --rm -it --network host \
  --name "${CONTAINER_NAME}" \
  --shm-size=16g \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  --runtime=nvidia \
  --gpus all \
  -e HF_TOKEN="${HF_TOKEN}" \
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
  "${IMAGE}" \
  vllm serve "${MODEL}" \
    --port 8000 \
    --host 0.0.0.0 \
    --trust-remote-code \
    --tokenizer "${MODEL}" \
    --max-model-len ${MAX_MODEL_LEN} \
    --gpu-memory-utilization ${GPU_MEMORY} \
    --tensor-parallel-size 1 \
    --enable-auto-tool-choice \
    --tool-call-parser mistral \
    --disable-frontend-multiprocessing

echo ""
echo -e "${GREEN}Server stopped${NC}"
