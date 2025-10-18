# Tower Setup Quick Reference

## Commands

### Installation
```bash
# Pre-flight check (recommended)
bash sim_and_data_lake_setup.sh test

# Full install
bash sim_and_data_lake_setup.sh install

# Check system health
bash sim_and_data_lake_setup.sh doctor
```

### Maintenance
```bash
# Rotate credentials (security)
bash sim_and_data_lake_setup.sh reconfigure-credentials

# Update after IP change
bash sim_and_data_lake_setup.sh reconfigure-network

# Change storage drives
bash sim_and_data_lake_setup.sh reconfigure-drives

# Remove everything
bash sim_and_data_lake_setup.sh uninstall
```

### Service Control
```bash
# Status
sudo systemctl status robot-datalake

# Start/stop/restart
sudo systemctl start robot-datalake
sudo systemctl stop robot-datalake
sudo systemctl restart robot-datalake

# View logs
sudo journalctl -u robot-datalake -f

# Docker container logs
docker logs minio
docker logs mlflow
docker logs mlflow-db
```

---

## File Locations

### Credentials (SECURE - 600 permissions)
- Docker: `<data_dir>/minio/.env`
- Human-readable: `<data_dir>/minio/CREDENTIALS.txt`
- Backup: `~/.go2_stack_backup/credentials_*.env`

### Documentation
- Network setup: `<data_dir>/NETWORK_SETUP.md`
- Profile: `~/robot_setup_profile.sh`

### Logs
- Install: `~/robot_install.log`
- Services: `docker logs <container>`
- Systemd: `sudo journalctl -u robot-datalake`

### State
- Install marker: `~/.robot_install_state/install_completed.txt`
- Configuration: `~/.robot_install_state/{data_dir,minio_dir,tower_ip}.txt`

---

## Service URLs

### Local Access
- MinIO S3 API: `http://localhost:9000`
- MinIO Console: `http://localhost:9001`
- MLflow: `http://localhost:5001`

### Network Access (Thor/Spark)
- MinIO S3 API: `http://<tower_ip>:9000`
- MinIO Console: `http://<tower_ip>:9001`
- MLflow: `http://<tower_ip>:5001`

---

## Common Tasks

### View Credentials
```bash
cat <data_dir>/minio/CREDENTIALS.txt
```

### Transfer to Thor/Spark
```bash
scp <data_dir>/minio/CREDENTIALS.txt thor:~/tower_credentials.txt
scp <data_dir>/minio/CREDENTIALS.txt spark:~/tower_credentials.txt
```

### Test S3 Access (Local)
```bash
source <data_dir>/minio/.env
aws --endpoint-url http://localhost:9000 s3 ls
```

### Test S3 Access (Thor/Spark)
```bash
export AWS_ACCESS_KEY_ID="<from Tower>"
export AWS_SECRET_ACCESS_KEY="<from Tower>"
aws --endpoint-url http://<tower_ip>:9000 s3 ls
```

### Check MinIO Health
```bash
curl http://localhost:9000/minio/health/live
curl http://<tower_ip>:9000/minio/health/live  # from network
```

### Check MLflow Health
```bash
curl http://localhost:5001/health
curl http://<tower_ip>:5001/health  # from network
```

---

## Troubleshooting

### Services Not Running
```bash
# Check status
docker ps
sudo systemctl status robot-datalake

# Start manually
sudo systemctl start robot-datalake

# Check logs
docker logs minio
docker logs mlflow
sudo journalctl -u robot-datalake -n 50
```

### Can't Access from Thor/Spark
```bash
# Check firewall on Tower
sudo ufw status

# Test from Tower itself first
curl http://localhost:9000/minio/health/live

# Test from Thor/Spark
curl http://<tower_ip>:9000/minio/health/live

# If timeout, check firewall rules
sudo ufw allow from 192.168.0.0/16 to any port 9000 proto tcp
```

### Forgot Credentials
```bash
# View current credentials
cat <data_dir>/minio/CREDENTIALS.txt

# Or from .env
cat <data_dir>/minio/.env
```

### IP Address Changed
```bash
# Update configuration
bash sim_and_data_lake_setup.sh reconfigure-network

# New IP will be shown
# Update Thor/Spark configuration
```

### Need to Rotate Credentials
```bash
# Automatic rotation with rollback
bash sim_and_data_lake_setup.sh reconfigure-credentials

# New credentials shown at end
# Transfer to Thor/Spark:
scp <data_dir>/minio/CREDENTIALS.txt thor:~/tower_credentials.txt
```

### Disk Full
```bash
# Check space
df -h

# Check MinIO usage
du -sh <data_dir>/minio

# Clean old data if needed
# Then reconfigure drives if adding new storage
bash sim_and_data_lake_setup.sh reconfigure-drives
```

---

## Safety Notes

### Before Uninstall
- ⚠️ Backup any important data from MinIO buckets
- ⚠️ Export MLflow experiments if needed
- ⚠️ Save credential files if you need them later

### Before Credential Rotation
- ✅ Automatic backup created
- ✅ Automatic rollback if services fail
- ⚠️ Thor/Spark will need new credentials immediately

### Before Drive Reconfiguration
- ⚠️ Manual data migration required
- ⚠️ Backup data before moving
- ⚠️ Services stopped until you restart them

---

## Quick Status Check
```bash
bash sim_and_data_lake_setup.sh doctor
```

This shows:
- System info (OS, RAM, disk, GPU)
- Software versions (Docker, Conda, ROS2)
- Service status (running/stopped)
- Network connectivity (local/remote)
- File locations
- Install history

---

## Emergency Recovery

### Services Won't Start
```bash
# Check logs
docker logs minio
docker logs mlflow

# Try manual restart
cd <data_dir>/minio
docker compose down
docker compose up -d

# Wait 30 seconds then check
docker ps
curl http://localhost:9000/minio/health/live
```

### Corrupt Credentials
```bash
# Restore from latest backup
cp ~/.go2_stack_backup/credentials_<date>.env <data_dir>/minio/.env

# Restart services
cd <data_dir>/minio
docker compose restart
```

### Complete Reset
```bash
# Nuclear option: uninstall and reinstall
bash sim_and_data_lake_setup.sh uninstall
# Answer prompts carefully
bash sim_and_data_lake_setup.sh install
```

---

## Getting Help

### Check Documentation
- Network setup: `<data_dir>/NETWORK_SETUP.md`
- Install log: `~/robot_install.log`

### Run Diagnostics
```bash
bash sim_and_data_lake_setup.sh doctor
```

### Check Logs
```bash
# Recent events
tail -100 ~/robot_install.log

# Service logs
docker logs --tail 100 minio
docker logs --tail 100 mlflow

# System logs
sudo journalctl -u robot-datalake -n 100
```

### Manual Health Checks
```bash
# Services running?
docker ps

# Ports listening?
sudo lsof -i :9000
sudo lsof -i :5001

# Can connect?
curl -v http://localhost:9000/minio/health/live
```
