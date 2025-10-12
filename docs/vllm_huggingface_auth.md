# vLLM HuggingFace Authentication Fix

## Problem

vLLM can't download Qwen/Qwen2.5-Coder-7B-Instruct without HuggingFace authentication:
```
401 Client Error: Unauthorized
Invalid credentials in Authorization header
```

## Solution

You need a HuggingFace token and must accept the model's license.

### Step 1: Get HuggingFace Token

1. Go to: https://huggingface.co/settings/tokens
2. Create new token (read access is enough)
3. Copy the token (starts with `hf_...`)

### Step 2: Accept Model License

1. Go to: https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct
2. Click "Agree and access repository" if prompted
3. Accept any terms/conditions

### Step 3: Configure vLLM with Token

**Option A: Environment Variable (Recommended)**

On Thor, before running vLLM:
```bash
export HF_TOKEN="hf_your_token_here"
./scripts/setup_vllm_thor.sh
```

**Option B: Update Script**

Edit `scripts/setup_vllm_thor.sh`, add before the docker run command:
```bash
# Add your HuggingFace token here
HF_TOKEN="hf_your_token_here"
```

Then update the docker run to include:
```bash
docker run --rm -it --network host \
  --name "${CONTAINER_NAME}" \
  --shm-size=16g \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  --runtime=nvidia \
  --gpus all \
  -e HF_TOKEN="${HF_TOKEN}" \  # <-- ADD THIS LINE
  -v "$HOME/.cache:/root/.cache" \
  ...
```

### Step 4: Alternative - Pre-download Model

If you don't want to use tokens in the container:

```bash
# On Thor, download model first
export HF_TOKEN="hf_your_token_here"
huggingface-cli login --token $HF_TOKEN

mkdir -p ~/vllm_models
cd ~/vllm_models
huggingface-cli download Qwen/Qwen2.5-Coder-7B-Instruct --local-dir Qwen2.5-Coder-7B-Instruct

# Then in vLLM script, change MODEL to local path:
# MODEL="/root/.cache/huggingface/hub/models--Qwen--Qwen2.5-Coder-7B-Instruct/snapshots/..."
```

## Alternative Models (No Auth Required)

If you want to skip authentication, try these public models:

### Microsoft Phi-3.5-mini (3.8B)
```bash
MODEL="microsoft/Phi-3.5-mini-instruct"
```
- No authentication required
- Smaller, faster
- Good for coding

### TinyLlama (1.1B)
```bash
MODEL="TinyLlama/TinyLlama-1.1B-Chat-v1.0"
```
- No authentication required
- Very fast, minimal memory
- Good for testing

### Meta Llama 3.1 (8B) - May require auth
```bash
MODEL="meta-llama/Llama-3.1-8B-Instruct"
```
- Requires Meta license acceptance
- General purpose, good quality

## Quick Test

To verify token works:
```bash
export HF_TOKEN="hf_your_token_here"
huggingface-cli whoami
# Should show your username

# Test download
huggingface-cli download Qwen/Qwen2.5-Coder-7B-Instruct --repo-type model --max-workers 4
```

## Recommended Quick Fix

**Use Phi-3.5-mini** - No auth needed, good quality, smaller/faster:

1. Edit `scripts/setup_vllm_thor.sh`
2. Change line: `MODEL="microsoft/Phi-3.5-mini-instruct"`
3. Run: `./scripts/setup_vllm_thor.sh`

This will work immediately without any HuggingFace setup!
