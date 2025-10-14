# vLLM HuggingFace Authentication

## Problem

vLLM can't download Qwen/Qwen2.5-Coder-7B-Instruct without HuggingFace authentication:
```
401 Client Error: Unauthorized
Invalid credentials in Authorization header
```

## Recommended Solution (Persistent)

### Step 1: Get HuggingFace Token

1. Go to: https://huggingface.co/settings/tokens
2. Create new token (read access is enough)
3. Copy the token (starts with `hf_...`)

### Step 2: Accept Model License

1. Go to: https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct
2. Click "Agree and access repository" if prompted
3. Accept any terms/conditions

### Step 3: Login with HuggingFace CLI

**On Thor:**
```bash
huggingface-cli login
```

When prompted:
- Paste your token (input will be hidden)
- Say **Yes** to "Add token as git credential?"

This will:
- Save token to `~/.cache/huggingface/token`
- Store token in git credential manager (persists across sessions)
- Mount token into vLLM container automatically

**Verify authentication:**
```bash
huggingface-cli whoami
# Should show your username
```

### Step 4: Run vLLM Setup

Now just run the setup script - it will detect your saved token:
```bash
./scripts/setup_vllm_thor.sh
```

The script will automatically:
- Check for saved token in `~/.cache/huggingface/token`
- Mount the HuggingFace cache directory into the container
- Pass `HF_TOKEN` environment variable if set

## Alternative: Temporary Token (Not Recommended)

If you need to use a temporary token for one session:

```bash
export HF_TOKEN="hf_your_token_here"
./scripts/setup_vllm_thor.sh
```

**Note:** This token won't persist after closing your terminal. Use `huggingface-cli login` for permanent setup.

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

To verify your authentication works:
```bash
# Check who you're logged in as
huggingface-cli whoami

# Test downloading the model
huggingface-cli download Qwen/Qwen2.5-Coder-7B-Instruct --repo-type model
# Should start downloading without 401 errors
```

## Troubleshooting

### "Token is already saved" message

If you see this when running `huggingface-cli login`:
```
A token is already saved on your machine. Run `hf auth whoami` to get more information
```

You're already authenticated! Just run the vLLM setup script.

### Container can't access token

If vLLM container shows 401 errors even after login:

1. **Check token file exists:**
   ```bash
   ls -la ~/.cache/huggingface/token
   ```

2. **Verify token in environment:**
   ```bash
   echo $HF_TOKEN
   ```

3. **Try setting explicitly:**
   ```bash
   export HF_TOKEN=$(cat ~/.cache/huggingface/token)
   ./scripts/setup_vllm_thor.sh
   ```

### Git credential helper not working

If token doesn't persist after login:

```bash
# Configure git to store credentials
git config --global credential.helper store

# Then login again
huggingface-cli login
```

## Recommended Quick Fix

**Use Phi-3.5-mini** - No auth needed, good quality, smaller/faster:

1. Edit `scripts/setup_vllm_thor.sh`
2. Change line: `MODEL="microsoft/Phi-3.5-mini-instruct"`
3. Run: `./scripts/setup_vllm_thor.sh`

This will work immediately without any HuggingFace setup!

## Summary

**Best Practice:**
1. Run `huggingface-cli login` (one time setup)
2. Accept "Add token as git credential" (persists forever)
3. Run `./scripts/setup_vllm_thor.sh` (uses saved token automatically)

**Token is stored in:**
- `~/.cache/huggingface/token` - Main token file
- Git credential store - Backup via git credential helper
- Container gets access via volume mount: `-v "$HOME/.cache/huggingface:/root/.cache/huggingface"`
