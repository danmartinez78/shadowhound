# Environment Configuration

ShadowHound uses a two-file environment configuration system to keep sensitive credentials out of git while allowing configuration templates to be version controlled.

## Quick Start

### 1. Setup Secrets (One-Time)
```bash
# Copy the secrets template
cp .env.secrets.example .env.secrets

# Edit with your actual API keys
nano .env.secrets
# Add your OPENAI_API_KEY (required)
```

### 2. Choose Environment Configuration
```bash
# Development (mock robot, no hardware)
cp .env.development .env

# OR Simulation (Isaac Sim on Tower)
cp .env.simulation .env

# OR Hardware (real Unitree Go2)
cp .env.hardware .env
```

### 3. Launch
```bash
./start.sh
# Automatically loads both .env and .env.secrets
```

## File Structure

```
.env.secrets          # Your API keys (NEVER committed to git)
.env.secrets.example  # Template for API keys (committed to git)

.env                  # Your active config (gitignored)
.env.development      # Mock robot template (committed to git)
.env.simulation       # Isaac Sim template (committed to git)
.env.hardware         # Real robot template (committed to git)
```

## Why Two Files?

**`.env.secrets`** (gitignored):
- Contains sensitive API keys and credentials
- Never committed to git
- Same secrets used across all environments
- Created once, reused everywhere

**`.env`** (gitignored, copied from templates):
- Contains non-sensitive configuration
- Robot mode, network settings, backend choice
- Different for each environment (dev/sim/prod)
- Templates are version controlled

## Configuration Templates

### Development Mode (Mock Robot)
```bash
cp .env.development .env
```
- **Robot:** Pure software mock (no hardware/sim needed)
- **LLM:** Ollama (fast, free) or OpenAI (cloud)
- **Use Case:** Pure development, testing agent logic

### Simulation Mode (Isaac Sim)
```bash
cp .env.simulation .env
```
- **Robot:** Isaac Sim on Tower, agent on laptop
- **LLM:** OpenAI (recommended for sim testing)
- **Network:** ROS_DOMAIN_ID=0, ROS_LOCALHOST_ONLY=0
- **Topics:** Automatic robot0 namespace remapping
- **Use Case:** Nav stack testing, distributed architecture

### Hardware Mode (Real Robot)
```bash
cp .env.hardware .env
```
- **Robot:** Real Unitree Go2
- **LLM:** OpenAI (most reliable)
- **Connection:** WebRTC (WiFi) or CycloneDDS (Ethernet)
- **Use Case:** Production deployment, real missions

## Security Best Practices

### ✅ Do:
- Keep `.env.secrets` out of git (already in `.gitignore`)
- Use different API keys for dev/staging/production
- Rotate keys if compromised
- Use environment variables in CI/CD instead of files

### ❌ Don't:
- Never commit `.env.secrets` to git
- Never share API keys publicly
- Never hardcode keys in source code
- Never use production keys in development

## Updating Configuration

### Add a New Secret
1. Add to `.env.secrets.example` (with placeholder)
2. Add to your `.env.secrets` (with actual value)
3. Commit `.env.secrets.example` to git

### Change Environment Settings
1. Edit the template file (`.env.development`, etc.)
2. Commit template changes to git
3. Users: `cp .env.simulation .env` to get new settings

## CI/CD Integration

For GitHub Actions or other CI systems:

```yaml
# Don't use .env.secrets in CI
# Instead, use repository secrets:
env:
  OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
  ROBOT_MODE: mock
  AGENT_BACKEND: openai
```

## Troubleshooting

### "OPENAI_API_KEY not set"
```bash
# Check .env.secrets exists and has key
cat .env.secrets | grep OPENAI_API_KEY

# If not, create it
cp .env.secrets.example .env.secrets
nano .env.secrets  # Add your key
```

### "Configuration not loading"
```bash
# Verify files exist
ls -la .env .env.secrets

# Check start.sh loads both
grep "env.secrets" start.sh

# Manually source to test
set -a
source .env
source .env.secrets
set +a
echo $OPENAI_API_KEY  # Should show your key
```

### "Wrong environment active"
```bash
# Check which template you copied
head -5 .env  # Shows environment type in header

# Copy correct template
cp .env.simulation .env  # For sim testing
```

## Migration from Old Setup

If you have an existing `.env` with API keys:

```bash
# 1. Extract secrets
grep "API_KEY" .env > .env.secrets

# 2. Copy appropriate template
cp .env.simulation .env  # Or .env.development, .env.hardware

# 3. Your .env.secrets has your keys, .env has config
# Both will be loaded automatically
```

## Related Documentation

- [Robot Modes](docs/software/robot_modes.md) - Understanding hardware/simulation/mock modes
- [Simulation Testing](TESTING_SIM.md) - Quick start for Isaac Sim
- [Start Script](start.sh) - Automatic environment loading
