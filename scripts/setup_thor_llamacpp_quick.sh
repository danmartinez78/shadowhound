#!/bin/bash
# Quick setup for llama.cpp on Thor
# Run this on Thor: ./setup_thor_llamacpp_quick.sh

set -e

echo "=== llama.cpp Quick Setup for Thor ==="
echo ""
echo "This will:"
echo "  1. Stop Ollama"
echo "  2. Build llama.cpp with CUDA"
echo "  3. Download Qwen2.5-Coder GGUF model"
echo "  4. Start llama.cpp server on port 8080"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Stop Ollama
echo "Stopping Ollama..."
docker stop ollama 2>/dev/null || echo "Ollama not running"

# Install deps
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential cmake git wget python3-pip
pip3 install --user huggingface-hub[cli]
export PATH="${HOME}/.local/bin:${PATH}"

# Clone/update llama.cpp
if [ -d "${HOME}/llama.cpp" ]; then
    echo "Updating llama.cpp..."
    cd "${HOME}/llama.cpp"
    git pull
else
    echo "Cloning llama.cpp..."
    cd "${HOME}"
    git clone https://github.com/ggerganov/llama.cpp
    cd llama.cpp
fi

# Build
echo "Building llama.cpp (this takes ~5 min)..."
make clean
make LLAMA_CUDA=1 -j$(nproc)

# Download model
echo "Downloading model (~4.4GB)..."
mkdir -p models
cd models
if [ ! -f "qwen2.5-coder-7b-instruct-q4_k_m.gguf" ]; then
    huggingface-cli download Qwen/Qwen2.5-Coder-7B-Instruct-GGUF \
        qwen2.5-coder-7b-instruct-q4_k_m.gguf --local-dir . --local-dir-use-symlinks False
else
    echo "Model already downloaded"
fi

# Start server
echo ""
echo "=== Starting llama.cpp server ==="
echo "Port: 8080"
echo "Model: qwen2.5-coder-7b-instruct-q4_k_m.gguf"
echo ""
echo "Press Ctrl+C to stop"
echo ""

cd "${HOME}/llama.cpp"
./llama-server \
    --model ./models/qwen2.5-coder-7b-instruct-q4_k_m.gguf \
    --ctx-size 8192 \
    --n-gpu-layers 35 \
    --port 8080 \
    --host 0.0.0.0 \
    --threads $(nproc) \
    --parallel 1
