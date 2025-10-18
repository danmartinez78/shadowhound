# Script Hardening Review - sim_and_data_lake_setup.sh

## Issues Found & Fixes Needed

### CRITICAL Issues

1. **Missing state file writes in install()**
   - `DATA_DIR` selected via `pick_data_dir()` but never written to `$MARKER_DIR/data_dir.txt`
   - `MINIO_DIR` never written to `$MARKER_DIR/minio_dir.txt`
   - This breaks all `reconfigure-*` commands which depend on loading these paths
   - **Impact**: Reconfiguration commands will fail

2. **Docker Compose v2 detection may fail**
   - `compose_cmd()` assumes "docker compose" works if available, but doesn't verify it's functional
   - Should test the command works before returning it
   - **Impact**: Silent failures in containerized deployments

3. **Missing error handling in credential file sourcing**
   - `reconfigure_credentials()` uses `source "$MINIO_DIR/.env"` without checking if variables loaded
   - If file is malformed, variables may be empty but script continues
   - **Impact**: Silent credential corruption

4. **Race condition in service health checks**
   - Multiple places use 5-second sleep loops without checking if services crashed
   - No detection of "service started then immediately failed"
   - **Impact**: Reports success when services are actually broken

### HIGH Priority Issues

5. **No validation that docker group membership is active**
   - Script adds user to docker group but doesn't check if they need to re-login
   - Continues trying to run docker commands that will fail with permission denied
   - **Impact**: Confusing errors about docker permissions

6. **Incomplete rollback in reconfigure_credentials()**
   - Backs up old credentials but no automatic rollback if services fail to start
   - User left with non-functional system and must manually restore
   - **Impact**: Downtime if rotation fails

7. **No disk space check before large operations**
   - Isaac Sim download is ~30GB, but no check if DATA_DIR has space
   - Could fill disk mid-install
   - **Impact**: Corrupt installation

8. **MinIO drive validation is weak**
   - `pick_minio_drives()` checks `[[ -d "$p" ]]` but not if writable
   - Doesn't check if drive is already mounted or has enough space
   - **Impact**: Services fail to start with cryptic errors

9. **No verification that systemd service actually starts**
   - Creates service file and enables it, but doesn't test it
   - May silently fail on next boot
   - **Impact**: Services don't auto-start despite configuration

### MEDIUM Priority Issues

10. **Hardcoded localhost in health checks**
    - Health checks use `localhost` and `127.0.0.1` but Tower IP may differ
    - Could report failure when services are actually running
    - **Impact**: False negatives in smoke tests

11. **No check for existing installations before install()**
    - Should detect if already installed and prompt to uninstall first
    - Could corrupt existing setup
    - **Impact**: Broken hybrid installations

12. **LiDAR config patch has silent failure path**
    - `clone_go2_omniverse_and_patch()` warns if patch fails but continues
    - User won't notice until simulation fails
    - **Impact**: Broken simulations with unclear cause

13. **Network setup doesn't validate firewall actually allows connections**
    - `configure_firewall_for_network()` adds rules but doesn't test them
    - UFW may be inactive or rules may not take effect
    - **Impact**: Thor/Spark can't connect

14. **No timeout on apt operations**
    - apt-get commands can hang forever if repos unreachable
    - No way to recover without killing script
    - **Impact**: Hung installations

### LOW Priority Issues

15. **Inconsistent error messaging**
    - Some functions use `echo "Error: ..."` others use `warn`
    - Makes parsing logs harder
    - **Impact**: Harder troubleshooting

16. **No progress indicators for long operations**
    - Isaac Sim install can take 15+ minutes with no feedback
    - User may think script hung
    - **Impact**: User confusion

17. **Backup directory not cleaned up**
    - `BACKUP_DIR` accumulates credential backups indefinitely
    - Could leak old credentials if not managed
    - **Impact**: Security risk from old credentials

18. **Profile file not automatically sourced**
    - Script tells user to add to ~/.bashrc manually
    - Easy to forget
    - **Impact**: User confusion about missing commands

## Recommended Fixes (Priority Order)

### Fix #1: Add state file writes in install()
```bash
# In install() function, after pick_data_dir():
echo "$DATA_DIR" > "$MARKER_DIR/data_dir.txt"
echo "$MINIO_DIR" > "$MARKER_DIR/minio_dir.txt"
chmod 600 "$MARKER_DIR/data_dir.txt" "$MARKER_DIR/minio_dir.txt"
```

### Fix #2: Improve compose_cmd() detection
```bash
compose_cmd(){
  if docker compose version >/dev/null 2>&1; then 
    echo "docker compose"
  elif command -v docker-compose >/dev/null && docker-compose version >/dev/null 2>&1; then 
    echo "docker-compose"
  else 
    echo "ERROR: Neither 'docker compose' (v2) nor 'docker-compose' (v1) found or functional" >&2
    exit 1
  fi
}
```

### Fix #3: Validate credential sourcing
```bash
# In reconfigure_credentials(), after sourcing .env:
if [[ -z "${MINIO_ROOT_USER:-}" || -z "${MINIO_ROOT_PASSWORD:-}" || -z "${POSTGRES_PASSWORD:-}" ]]; then
  echo "Error: Failed to load credentials from $MINIO_DIR/.env"
  echo "File may be corrupted. Check: cat $MINIO_DIR/.env"
  exit 1
fi
```

### Fix #4: Improve health check with crash detection
```bash
# In wait loops, add service status check:
if ! docker ps --filter "name=minio" --filter "status=running" | grep -q minio; then
  warn "MinIO container crashed. Check logs: docker logs minio"
  ((failed++))
fi
```

### Fix #5: Check docker group is active
```bash
# After usermod -aG docker:
if ! id | grep -q docker; then
  warn "Docker group added but not yet active in current session"
  warn "You must log out and log back in (or run: newgrp docker)"
  warn "Then re-run: bash $SCRIPT_NAME install"
  exit 0
fi
```

### Fix #6: Add rollback to reconfigure_credentials()
```bash
# After service restart attempt, if health check fails:
if ! ((healthy)); then
  warn "Services failed to start with new credentials. Rolling back..."
  run "cp \"$backup_file\" \"$MINIO_DIR/.env\""
  (cd "$MINIO_DIR" && $cmd up -d)
  warn "Rolled back to old credentials. Check logs: docker logs minio"
  exit 1
fi
```

### Fix #7: Add disk space check
```bash
# In preflight_checks(), add:
local data_space_gb=$(df -BG "${DATA_DIR_DEFAULT}" | tail -1 | awk '{print $4}' | tr -d 'G')
if ((data_space_gb < 150)); then
  warn "Data directory has only ${data_space_gb}GB free (150GB+ recommended)"
  ((failed++))
fi
```

### Fix #8: Validate MinIO drives properly
```bash
# In pick_minio_drives(), replace [[ -d "$p" ]] check:
if [[ ! -d "$p" ]]; then
  warn "Not a directory: $p"
elif [[ ! -w "$p" ]]; then
  warn "Not writable: $p"
else
  local space_gb=$(df -BG "$p" | tail -1 | awk '{print $4}' | tr -d 'G')
  if ((space_gb < 50)); then
    warn "$p has only ${space_gb}GB free (50GB+ recommended per drive)"
  fi
  paths+=("$p")
fi
```

### Fix #9: Test systemd service
```bash
# After systemctl enable robot-datalake.service:
if sudo systemctl start robot-datalake; then
  sleep 5
  if sudo systemctl is-active robot-datalake >/dev/null 2>&1; then
    ok "Systemd service tested successfully"
  else
    warn "Systemd service failed to start. Check: sudo systemctl status robot-datalake"
  fi
else
  warn "Failed to start systemd service"
fi
```

### Fix #10: Fix localhost hardcoding
```bash
# Use tower_ip for network checks, localhost only for local checks
# Mark clearly which checks are local vs network
```

## Testing Checklist

- [ ] Fresh Ubuntu 22.04 VM install
- [ ] Install with insufficient disk space (should fail gracefully)
- [ ] Install with insufficient RAM (should fail gracefully)
- [ ] Install without NVIDIA GPU (should skip GPU components)
- [ ] Reconfigure credentials (should succeed and services remain healthy)
- [ ] Reconfigure credentials with broken services (should rollback)
- [ ] Reconfigure network after IP change
- [ ] Reconfigure drives with new mount points
- [ ] Uninstall and verify cleanup
- [ ] Install, reboot, verify auto-start
- [ ] Doctor command on healthy system
- [ ] Doctor command with services stopped
- [ ] Test mode on unconfigured system

## Estimate

- Critical fixes: ~2 hours
- High priority fixes: ~3 hours  
- Medium priority fixes: ~2 hours
- Testing: ~4 hours
- **Total: ~11 hours for bulletproof script**

## Notes

The script is already quite robust with:
- ✅ Comprehensive error handling (trap ERR)
- ✅ Preflight checks
- ✅ Logging
- ✅ Credential security
- ✅ Service health checks
- ✅ Detailed user guidance

Main gaps are edge cases and state management for reconfiguration commands.
