---
tags: [deployment, security, credentials, tower]
status: complete
related: [tower_sim_datalake_setup.md, tower_thor_spark_integration_guide.md]
summary: >
  Security guide for Tower credentials - generation, storage, and safe transfer to Thor/Spark.
---

# Tower Security & Credentials Guide

## Overview

The Tower setup script (`scripts/sim_and_data_lake_setup.sh`) generates **secure random credentials** for all services during installation. Credentials are **never hardcoded** in the script or committed to version control.

## Credential Generation

### What Gets Generated

During installation, the script generates:

1. **MinIO Access Keys** (16 random hex characters)
   - Access Key ID (username)
   - Secret Access Key (password)

2. **PostgreSQL Password** (32 random hex characters)
   - Used by MLflow backend database
   - Only accessible from Docker network

### Generation Method

```bash
MINIO_USER="$(openssl rand -hex 8)"           # 16-character hex string
MINIO_PASS="$(openssl rand -hex 16)"          # 32-character hex string  
POSTGRES_PASSWORD="$(openssl rand -hex 16)"   # 32-character hex string
```

**Security properties**:
- Cryptographically secure random generation (via OpenSSL)
- Unique per installation (no default passwords)
- High entropy (128-256 bits)
- Not stored in git history or public code

## Credential Storage

### Files Created (All Gitignored)

1. **`$MINIO_DIR/CREDENTIALS.txt`** (Human-readable)
   - Complete credentials with examples
   - AWS CLI configuration snippets
   - Python boto3 configuration examples
   - Transfer instructions
   - **Permissions**: `chmod 600` (owner read/write only)

2. **`$MINIO_DIR/.env`** (Machine-readable)
   - Docker Compose environment file
   - Used by container services
   - **Permissions**: `chmod 600` (owner read/write only)

3. **`~/.go2_stack_state/credentials.txt`** (Backup)
   - Recovery backup in case files are lost
   - Colon-separated format
   - **Permissions**: `chmod 600` (owner read/write only)

### .gitignore Protection

The repository `.gitignore` includes:

```gitignore
# Credentials (NEVER commit)
CREDENTIALS.txt
**/CREDENTIALS.txt
credentials.txt
**/credentials.txt
minio_creds.txt
tower_credentials.txt
.env
*.env.local
```

**Result**: Impossible to accidentally commit credentials to git.

## Viewing Credentials

### Human-Readable Format

```bash
cat /srv/robot-data/minio/CREDENTIALS.txt
```

**Output example**:
```
MinIO S3 API:
  URL:       http://192.168.10.100:9000
  User:      a3f2e8c9b1d4f6a2
  Password:  e4d2a9f8c3b1e5d7a2f9c8b3e1d4a7f2

AWS CLI Configuration:
  export AWS_ACCESS_KEY_ID="a3f2e8c9b1d4f6a2"
  export AWS_SECRET_ACCESS_KEY="e4d2a9f8c3b1e5d7a2f9c8b3e1d4a7f2"
  export AWS_ENDPOINT_URL="http://localhost:9000"
```

### Machine-Readable Format

```bash
source /srv/robot-data/minio/.env
echo "User: $MINIO_ROOT_USER"
echo "Pass: $MINIO_ROOT_PASSWORD"
echo "PostgreSQL: $POSTGRES_PASSWORD"
```

## Transferring Credentials to Thor/Spark

### Secure Transfer via SCP

```bash
# From Tower
scp /srv/robot-data/minio/CREDENTIALS.txt thor:~/tower_credentials.txt
scp /srv/robot-data/minio/CREDENTIALS.txt spark:~/tower_credentials.txt
```

### On Thor/Spark (Setup Environment)

```bash
# Extract credentials from file
source ~/tower_credentials.txt  # If formatted as shell script

# Or manually copy values
export AWS_ACCESS_KEY_ID="<from CREDENTIALS.txt>"
export AWS_SECRET_ACCESS_KEY="<from CREDENTIALS.txt>"
export MLFLOW_S3_ENDPOINT_URL="http://tower:9000"
export MLFLOW_TRACKING_URI="http://tower:5001"

# Add to ~/.bashrc for persistence
echo 'export AWS_ACCESS_KEY_ID="..."' >> ~/.bashrc
echo 'export AWS_SECRET_ACCESS_KEY="..."' >> ~/.bashrc
echo 'export MLFLOW_S3_ENDPOINT_URL="http://tower:9000"' >> ~/.bashrc
echo 'export MLFLOW_TRACKING_URI="http://tower:5001"' >> ~/.bashrc
```

**⚠️ IMPORTANT**: Set `chmod 600 ~/tower_credentials.txt` on Thor/Spark after transfer.

## Credential Rotation

### Automated Rotation (Recommended)

The setup script provides a built-in credential rotation command:

```bash
bash scripts/sim_and_data_lake_setup.sh reconfigure-credentials
```

**What it does**:
1. ✅ Backs up old credentials to `~/.go2_stack_backup/`
2. ✅ Generates new cryptographic random credentials
3. ✅ Stops all services gracefully
4. ✅ Updates `.env` and `CREDENTIALS.txt` files
5. ✅ Restarts services with new credentials
6. ✅ Validates services are healthy
7. ✅ Provides Thor/Spark update instructions

**When to rotate**:
- After initial setup (if you want different credentials)
- Every 90 days (security best practice)
- After personnel changes (someone loses access)
- After suspected credential exposure
- Compliance requirements (audit findings)

### Rotation Output Example

```
═══ NEW CREDENTIALS ═══
Location:               /srv/robot-data/minio/CREDENTIALS.txt
Backup (old):           /home/user/.go2_stack_backup/credentials_20251018_143522.env

MinIO User:             a3f2e8c9b1d4f6a2
MinIO Password:         e4d2a9f8c3b1e5d7a2f9c8b3e1d4a7f2

═══ REQUIRED ACTIONS ═══
⚠️  You MUST update Thor/Spark configuration:

1. Transfer new credentials to Thor/Spark:
   scp /srv/robot-data/minio/CREDENTIALS.txt thor:~/tower_credentials.txt
   scp /srv/robot-data/minio/CREDENTIALS.txt spark:~/tower_credentials.txt

2. On Thor/Spark, update environment variables:
   export AWS_ACCESS_KEY_ID="a3f2e8c9b1d4f6a2"
   export AWS_SECRET_ACCESS_KEY="e4d2a9f8c3b1e5d7a2f9c8b3e1d4a7f2"

3. Update ~/.bashrc on Thor/Spark for persistence

4. Test connectivity:
   aws --endpoint-url http://tower:9000 s3 ls
```

### Manual Rotation (Advanced)

If you need manual control:

1. **Generate new credentials**:
   ```bash
   NEW_USER="$(openssl rand -hex 8)"
   NEW_PASS="$(openssl rand -hex 16)"
   NEW_PG_PASS="$(openssl rand -hex 16)"
   ```

2. **Backup current credentials**:
   ```bash
   cp /srv/robot-data/minio/.env ~/.go2_stack_backup/credentials_backup_$(date +%Y%m%d).env
   ```

3. **Update Docker Compose .env**:
   ```bash
   cd /srv/robot-data/minio
   echo "MINIO_ROOT_USER=$NEW_USER" > .env
   echo "MINIO_ROOT_PASSWORD=$NEW_PASS" >> .env
   echo "POSTGRES_PASSWORD=$NEW_PG_PASS" >> .env
   chmod 600 .env
   ```

4. **Restart services**:
   ```bash
   cd /srv/robot-data/minio
   docker compose down
   docker compose up -d
   ```

5. **Verify health**:
   ```bash
   curl http://localhost:9000/minio/health/live
   curl http://localhost:5001/health
   ```

6. **Update Thor/Spark** (same as automated process above)

### Rotation Best Practices

✅ **DO**:
- Use automated rotation command (less error-prone)
- Rotate every 90 days minimum
- Test connectivity after rotation
- Keep backup of old credentials for 30 days
- Document rotation in change log
- Rotate immediately after personnel changes

❌ **DON'T**:
- Rotate during active missions (plan downtime)
- Forget to update Thor/Spark (will break connectivity)
- Delete old credential backups immediately (keep for rollback)
- Skip health checks after rotation
- Use predictable passwords if doing manual rotation

### Rollback Procedure

If rotation causes issues:

1. **Find backup**:
   ```bash
   ls -lt ~/.go2_stack_backup/credentials_*.env | head -1
   ```

2. **Restore old credentials**:
   ```bash
   cp ~/.go2_stack_backup/credentials_20251018_143522.env /srv/robot-data/minio/.env
   ```

3. **Restart services**:
   ```bash
   cd /srv/robot-data/minio
   docker compose down
   docker compose up -d
   ```

4. **Verify health**:
   ```bash
   bash scripts/sim_and_data_lake_setup.sh doctor
   ```

### Future Enhancements
- Automated rotation on schedule (cron job)
- MinIO user management (separate read-only users for Thor/Spark)
- Credential expiration policies
- Audit logging of credential access

## Security Best Practices

### ✅ DO

- **Use generated credentials** (never modify to something predictable)
- **Keep `chmod 600`** on all credential files
- **Transfer via SCP** (encrypted channel)
- **Delete transfer files** on Thor/Spark after environment setup
- **Add to .bashrc** on Thor/Spark for persistence
- **Use network isolation** (firewall rules limit access to 192.168.x.x, 10.x.x.x)

### ❌ DON'T

- **DON'T commit credentials** to git (protected by .gitignore)
- **DON'T hardcode credentials** in scripts or code
- **DON'T share credentials** via Slack/email/Discord (use secure channels)
- **DON'T use default passwords** (script generates random ones)
- **DON'T store in plain text** in public locations (keep in secure directories)
- **DON'T reuse credentials** across environments (prod vs dev)

## Verifying Security

### Check File Permissions

```bash
# Should all show: -rw------- (600)
ls -la /srv/robot-data/minio/CREDENTIALS.txt
ls -la /srv/robot-data/minio/.env
ls -la ~/.go2_stack_state/credentials.txt
```

### Check Git Status

```bash
# Should show: nothing to commit (credentials gitignored)
cd /path/to/shadowhound
git status
git ls-files | grep -i credentials  # Should return nothing
```

### Check Network Access

```bash
# MinIO console should NOT be accessible from internet
curl -I http://TOWER_PUBLIC_IP:9001  # Should timeout (firewall blocks)

# Only local networks should work
curl -I http://192.168.10.100:9001  # Should return 200
```

## Troubleshooting

### Credentials Lost

If you lose the CREDENTIALS.txt file:

1. **Recover from backup**:
   ```bash
   cat ~/.go2_stack_state/credentials.txt
   # Format: USER:PASS:POSTGRES_PASSWORD
   ```

2. **Or extract from running containers**:
   ```bash
   docker exec minio env | grep MINIO_ROOT
   docker exec mlflow-db env | grep POSTGRES_PASSWORD
   ```

### Credentials Not Working

1. **Verify file loaded correctly**:
   ```bash
   source /srv/robot-data/minio/.env
   echo "User: $MINIO_ROOT_USER"  # Should not be empty
   ```

2. **Test MinIO access**:
   ```bash
   export AWS_ACCESS_KEY_ID="$MINIO_ROOT_USER"
   export AWS_SECRET_ACCESS_KEY="$MINIO_ROOT_PASSWORD"
   aws --endpoint-url http://localhost:9000 s3 ls
   ```

3. **Check Docker Compose used correct values**:
   ```bash
   docker exec minio env | grep MINIO_ROOT
   # Should match .env file
   ```

### Thor/Spark Can't Connect

1. **Verify credentials transferred**:
   ```bash
   # On Thor/Spark
   cat ~/tower_credentials.txt  # Should exist
   ```

2. **Test network connectivity**:
   ```bash
   # From Thor/Spark
   curl http://tower:9000/minio/health/live
   ```

3. **Verify environment variables set**:
   ```bash
   # On Thor/Spark
   echo $AWS_ACCESS_KEY_ID  # Should match Tower credentials
   ```

## References

- **Setup Script**: `scripts/sim_and_data_lake_setup.sh`
- **Tower Setup Guide**: [tower_sim_datalake_setup.md](tower_sim_datalake_setup.md)
- **Integration Guide**: [tower_thor_spark_integration_guide.md](tower_thor_spark_integration_guide.md)
- **Network Config**: `/srv/robot-data/NETWORK_SETUP.md` (generated on Tower)

## Related Documentation

- MinIO Security: https://min.io/docs/minio/linux/administration/identity-access-management.html
- Docker Secrets: https://docs.docker.com/engine/swarm/secrets/
- PostgreSQL Security: https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
