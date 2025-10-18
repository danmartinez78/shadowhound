# Tower Setup Script Test Plan

## Purpose
Validate the `sim_and_data_lake_setup.sh` script is bulletproof and handles all edge cases gracefully.

## Test Environment Requirements
- Fresh Ubuntu 22.04 VM or physical machine
- Ability to snapshot/restore for repeated testing
- At least 200GB disk space for full tests
- NVIDIA GPU (or ability to test without)
- Network connectivity

## Pre-Test Checklist
- [ ] Create VM snapshot (clean Ubuntu 22.04 install)
- [ ] Verify no Docker installed
- [ ] Verify no NVIDIA drivers installed
- [ ] Verify no conda installed
- [ ] Verify firewall (ufw) not configured

---

## Test Suite 1: Preflight Checks

### Test 1.1: Insufficient RAM (if possible)
**Setup**: VM with 8GB RAM  
**Command**: `bash sim_and_data_lake_setup.sh test`  
**Expected**: Warning about insufficient RAM, suggests upgrading  
**Pass Criteria**: Script warns but doesn't exit (shows other checks)

### Test 1.2: Insufficient Disk Space
**Setup**: VM with < 100GB disk  
**Command**: `bash sim_and_data_lake_setup.sh test`  
**Expected**: Warning about disk space in preflight checks  
**Pass Criteria**: Failed count increases, script warns

### Test 1.3: Port Already in Use
**Setup**: Run `python3 -m http.server 9000` in background  
**Command**: `bash sim_and_data_lake_setup.sh test`  
**Expected**: Warning that port 9000 is in use  
**Pass Criteria**: Script detects port conflict, shows process using port

### Test 1.4: No Internet Connectivity
**Setup**: Disconnect network or block DNS  
**Command**: `bash sim_and_data_lake_setup.sh test`  
**Expected**: Warning about internet connectivity  
**Pass Criteria**: Script detects no internet, warns user

### Test 1.5: All Preflight Checks Pass
**Setup**: Clean Ubuntu 22.04 with 16GB RAM, 200GB disk, internet  
**Command**: `bash sim_and_data_lake_setup.sh test`  
**Expected**: All checks pass, green "✓" for each  
**Pass Criteria**: "All pre-flight checks passed" message

---

## Test Suite 2: Installation

### Test 2.1: Fresh Install (Happy Path)
**Setup**: Clean Ubuntu 22.04 VM  
**Command**: `bash sim_and_data_lake_setup.sh install`  
**Expected**: 
- All components install successfully
- Services start and become healthy
- Credentials generated and saved
- State files written to `~/.robot_install_state/`

**Pass Criteria**:
- [ ] Isaac Sim installed in conda env
- [ ] ROS 2 Humble installed
- [ ] Docker + NVIDIA toolkit installed
- [ ] MinIO + MLflow running (`docker ps`)
- [ ] Services healthy (curl checks pass)
- [ ] CREDENTIALS.txt exists with valid format
- [ ] data_dir.txt and minio_dir.txt written
- [ ] Systemd service enabled
- [ ] No errors in install.log

**Validation Commands**:
```bash
# Check conda env
conda env list | grep env_isaaclab

# Check ROS2
source /opt/ros/humble/setup.bash && ros2 --version

# Check Docker
docker ps | grep -E "minio|mlflow"

# Check services
curl http://localhost:9000/minio/health/live
curl http://localhost:5001/health

# Check state files
ls -lh ~/.robot_install_state/
cat ~/.robot_install_state/data_dir.txt
cat ~/.robot_install_state/minio_dir.txt

# Check systemd
sudo systemctl status robot-datalake
```

### Test 2.2: Install Without NVIDIA GPU
**Setup**: Ubuntu VM without GPU  
**Command**: `bash sim_and_data_lake_setup.sh install`  
**Expected**: 
- Warns about missing GPU
- Installs NVIDIA driver via ubuntu-drivers
- May require reboot
- Continues without GPU for software components

**Pass Criteria**: Script handles missing GPU gracefully, installs driver

### Test 2.3: Install With Docker Already Installed
**Setup**: Ubuntu with Docker already present  
**Command**: `bash sim_and_data_lake_setup.sh install`  
**Expected**: Skips Docker install, continues with NVIDIA toolkit  
**Pass Criteria**: No errors, doesn't reinstall Docker

### Test 2.4: Docker Group Not Active (User Not in Group)
**Setup**: Manually install Docker, don't add user to group  
**Command**: `bash sim_and_data_lake_setup.sh install`  
**Expected**: 
- Adds user to docker group
- Detects group not active in session
- Exits with message to log out/in or use newgrp
- Doesn't continue with failing docker commands

**Pass Criteria**: Script exits gracefully with clear instructions

### Test 2.5: Existing Installation Detected
**Setup**: Run install once successfully  
**Command**: `bash sim_and_data_lake_setup.sh install` (second time)  
**Expected**: 
- Warns about existing installation
- Shows install date from marker file
- Prompts to uninstall first or continue anyway
- If continued, warns about potential issues

**Pass Criteria**: User given choice, clear warnings

### Test 2.6: Isaac Sim Download Interrupted
**Setup**: Kill script during Isaac Sim pip install  
**Command**: Restart `bash sim_and_data_lake_setup.sh install`  
**Expected**: 
- Resumes from checkpoint (doesn't re-do prior steps)
- Pip handles partial download gracefully

**Pass Criteria**: Can resume and complete

### Test 2.7: MinIO Drive Selection - No Drives
**Setup**: Install, when prompted for drives just press ENTER  
**Expected**: 
- Warns no drives selected
- Falls back to `${DATA_DIR}/lake` as single drive
- Creates directory and continues

**Pass Criteria**: Uses fallback, completes successfully

### Test 2.8: MinIO Drive Selection - Non-Writable Path
**Setup**: When prompted, enter `/root` (not writable as non-root user)  
**Expected**: 
- Validates directory not writable
- Warns user
- Prompts for another path

**Pass Criteria**: Rejects bad path, re-prompts

### Test 2.9: MinIO Drive Selection - Insufficient Space
**Setup**: Enter path with < 50GB free  
**Expected**: 
- Warns about insufficient space
- Prompts to use anyway
- If declined, re-prompts for path

**Pass Criteria**: User warned, can choose to proceed or not

---

## Test Suite 3: Reconfiguration Commands

### Test 3.1: Reconfigure Credentials (Happy Path)
**Setup**: Completed installation  
**Command**: `bash sim_and_data_lake_setup.sh reconfigure-credentials`  
**Expected**:
- Shows current credentials (masked)
- Warns about required Thor/Spark updates
- Backs up old credentials
- Generates new random credentials
- Stops services
- Updates .env and CREDENTIALS.txt
- Restarts services
- Services become healthy
- Shows new credentials (unmasked) for user to copy

**Pass Criteria**:
- [ ] Old credentials backed up to `~/.go2_stack_backup/credentials_*.env`
- [ ] New credentials in .env and CREDENTIALS.txt
- [ ] Services restart successfully
- [ ] curl checks pass with new credentials
- [ ] No downtime > 30 seconds

**Validation**:
```bash
# Check backup exists
ls -lh ~/.go2_stack_backup/credentials_*.env

# Verify new credentials differ
diff ~/.go2_stack_backup/credentials_*.env <data_dir>/minio/.env

# Check services healthy
docker ps
curl http://localhost:9000/minio/health/live
curl http://localhost:5001/health

# Test S3 access with new credentials
source <data_dir>/minio/.env
aws --endpoint-url http://localhost:9000 s3 ls
```

### Test 3.2: Reconfigure Credentials - Service Fails to Start
**Setup**: After backup, manually corrupt docker-compose.yml  
**Command**: `bash sim_and_data_lake_setup.sh reconfigure-credentials`  
**Expected**:
- Generates new credentials
- Attempts to restart services
- Services fail health check
- **AUTOMATIC ROLLBACK**: Restores old credentials from backup
- Attempts restart with old credentials
- Warns user about failure
- Exits with error code

**Pass Criteria**: 
- [ ] Old credentials restored
- [ ] Services running with original credentials
- [ ] Clear error message about what happened
- [ ] User not left with broken system

### Test 3.3: Reconfigure Credentials - Missing .env File
**Setup**: Delete `<data_dir>/minio/.env`  
**Command**: `bash sim_and_data_lake_setup.sh reconfigure-credentials`  
**Expected**: 
- Error message about missing credentials
- Clear path to file that's missing
- Exit without making changes

**Pass Criteria**: Fails gracefully with helpful error

### Test 3.4: Reconfigure Credentials - Corrupted .env File
**Setup**: Write garbage to .env: `echo "BROKEN" > <data_dir>/minio/.env`  
**Command**: `bash sim_and_data_lake_setup.sh reconfigure-credentials`  
**Expected**:
- Attempts to source .env
- Detects variables not loaded (empty)
- Error message about corrupted file
- Shows how to check file
- Exits without changes

**Pass Criteria**: Detects corruption, doesn't proceed with empty variables

### Test 3.5: Reconfigure Network After IP Change
**Setup**: 
- Complete install
- Change VM network (different subnet)
- Wait for new DHCP IP

**Command**: `bash sim_and_data_lake_setup.sh reconfigure-network`  
**Expected**:
- Detects old IP from state file
- Detects current IP differs
- Warns about IP change
- Updates tower_ip.txt
- Regenerates firewall rules
- Regenerates NETWORK_SETUP.md
- Shows new IP and instructions for Thor/Spark

**Pass Criteria**:
- [ ] New IP in tower_ip.txt
- [ ] Firewall rules updated
- [ ] NETWORK_SETUP.md reflects new IP
- [ ] Services remain running

### Test 3.6: Reconfigure Drives
**Setup**: Complete install with one drive  
**Command**: `bash sim_and_data_lake_setup.sh reconfigure-drives`  
**Expected**:
- Shows current drives
- Warns about data migration needed
- Prompts for confirmation
- Stops services
- Backs up old config
- Prompts for new drives
- Updates minio_drives.txt
- Regenerates docker-compose.yml
- Shows migration instructions
- Does NOT restart services (user must migrate data first)

**Pass Criteria**:
- [ ] Old config backed up
- [ ] New drives in minio_drives.txt
- [ ] docker-compose.yml updated with new volume mounts
- [ ] Clear instructions about data migration
- [ ] Services stopped (not auto-restarted)

---

## Test Suite 4: Diagnostic Commands

### Test 4.1: Doctor on Healthy System
**Setup**: Complete working installation  
**Command**: `bash sim_and_data_lake_setup.sh doctor`  
**Expected**:
- Shows system info (OS, hostname, IP)
- Shows hardware (RAM, disk, GPU)
- Shows software (Docker, Conda, ROS2 versions)
- Shows service status (all ✓ running)
- Shows port bindings (all ✓ listening)
- Shows connectivity tests (all ✓ accessible)
- Shows install status (completed, with date)
- Shows file locations (all present)
- Final summary: "All services healthy"

**Pass Criteria**: All checks green, clear summary

### Test 4.2: Doctor With Services Stopped
**Setup**: `sudo systemctl stop robot-datalake`  
**Command**: `bash sim_and_data_lake_setup.sh doctor`  
**Expected**:
- Service checks show ✗ not running
- Port checks show ✗ not listening
- Connectivity tests fail
- Clear recommendation: "Start with: sudo systemctl start robot-datalake"

**Pass Criteria**: Correctly identifies stopped services, helpful guidance

### Test 4.3: Doctor on Unconfigured System
**Setup**: Fresh Ubuntu 22.04  
**Command**: `bash sim_and_data_lake_setup.sh doctor`  
**Expected**:
- System/hardware checks work
- Software checks show "not installed"
- Service checks show "not running"
- Install status shows "incomplete or not run"
- Suggestion: "Run: bash <script> install"

**Pass Criteria**: Helpful diagnosis of unconfigured system

---

## Test Suite 5: Uninstall

### Test 5.1: Full Uninstall
**Setup**: Complete installation  
**Command**: `bash sim_and_data_lake_setup.sh uninstall`  
**Expected**:
- Prompts for confirmation on each major action
- Stops and removes Docker containers
- Optionally removes workspaces, conda env, ROS2, Docker, drivers
- Removes systemd service
- Cleans up symlinks
- Removes config files

**Pass Criteria**: 
- [ ] All containers stopped and removed
- [ ] User decides what to keep/remove
- [ ] System returned to pre-install state (if all selected)
- [ ] No orphaned config files

### Test 5.2: Uninstall Then Reinstall
**Setup**: Complete install, uninstall, reinstall  
**Command**: 
```bash
bash sim_and_data_lake_setup.sh install
bash sim_and_data_lake_setup.sh uninstall
bash sim_and_data_lake_setup.sh install
```
**Expected**: Second install works identically to first  
**Pass Criteria**: Clean reinstall, no conflicts or errors

---

## Test Suite 6: Edge Cases

### Test 6.1: Ctrl+C During Install
**Setup**: Start install, press Ctrl+C during Isaac Sim download  
**Command**: Resume with `bash sim_and_data_lake_setup.sh install`  
**Expected**: Error handler catches signal, logs line number, can resume  
**Pass Criteria**: Doesn't corrupt system, can resume

### Test 6.2: Disk Fill During Install
**Setup**: Small disk VM, install until disk fills  
**Expected**: Detects ENOSPC errors, fails gracefully with clear error  
**Pass Criteria**: Doesn't silently corrupt install

### Test 6.3: Network Loss During Install
**Setup**: Disconnect network during apt-get or pip install  
**Expected**: Command times out or fails, error handler catches it  
**Pass Criteria**: Clear error about network, can retry

### Test 6.4: Reboot During Install
**Setup**: Reboot VM mid-install  
**Command**: Resume with `bash sim_and_data_lake_setup.sh install`  
**Expected**: Detects partial install, can resume from checkpoint  
**Pass Criteria**: Resumes successfully, completes

### Test 6.5: Multiple Simultaneous Runs
**Setup**: Run `bash sim_and_data_lake_setup.sh install` in two terminals  
**Expected**: File locks or marker files prevent conflicts  
**Pass Criteria**: Second run detects first, exits or waits

---

## Test Suite 7: Integration Testing

### Test 7.1: Post-Install Thor Connection Simulation
**Setup**: Complete install on Tower VM  
**Simulate**: Another machine (or container) trying to connect  
**Test**:
```bash
# From "Thor" (another machine/container)
curl http://<tower_ip>:9000/minio/health/live
curl http://<tower_ip>:5001/health

# Test S3 with credentials
export AWS_ACCESS_KEY_ID="<from Tower>"
export AWS_SECRET_ACCESS_KEY="<from Tower>"
aws --endpoint-url http://<tower_ip>:9000 s3 ls
```

**Expected**: All connections succeed  
**Pass Criteria**: 
- [ ] MinIO accessible from network
- [ ] MLflow accessible from network
- [ ] S3 operations work with credentials

### Test 7.2: Firewall Blocks External Access
**Setup**: Install, then `sudo ufw deny 9000`  
**Command**: Try to connect from another machine  
**Expected**: Connection refused (expected behavior)  
**Validation**: Doctor command should warn about firewall blocking

### Test 7.3: Auto-Start After Reboot
**Setup**: Complete install  
**Command**: `sudo reboot`  
**Expected After Reboot**:
- Wait 60 seconds
- Services auto-started by systemd
- `docker ps` shows minio, mlflow, mlflow-db
- Curl checks pass

**Pass Criteria**:
- [ ] Services running after reboot
- [ ] No manual intervention needed

---

## Test Suite 8: Credential Security

### Test 8.1: Credentials File Permissions
**Setup**: Complete install  
**Command**: 
```bash
ls -l <data_dir>/minio/.env
ls -l <data_dir>/minio/CREDENTIALS.txt
ls -l ~/.robot_install_state/credentials.txt
```
**Expected**: All files have 600 permissions (rw-------)  
**Pass Criteria**: No world-readable credential files

### Test 8.2: Credentials Not in Git (if applicable)
**Setup**: Install in a git repo  
**Command**: `git status`  
**Expected**: Credential files are gitignored  
**Pass Criteria**: No credential files shown in `git status`

### Test 8.3: Credentials Backed Up Securely
**Setup**: Run reconfigure-credentials  
**Command**: `ls -lh ~/.go2_stack_backup/`  
**Expected**: Backup files have 600 permissions  
**Pass Criteria**: Old credentials secured

---

## Performance Benchmarks

### Benchmark 1: Installation Time
**Metric**: Total time for fresh install  
**Target**: < 45 minutes on fast internet  
**Factors**: Isaac Sim download is bottleneck (~30GB)

### Benchmark 2: Service Startup Time
**Metric**: Time from `docker compose up -d` to health checks passing  
**Target**: < 30 seconds  

### Benchmark 3: Credential Rotation Time
**Metric**: Downtime during reconfigure-credentials  
**Target**: < 30 seconds

---

## Automated Testing Script Stub

```bash
#!/bin/bash
# test_tower_setup.sh - Automated test runner

SCRIPT="./sim_and_data_lake_setup.sh"

test_preflight_checks() {
    echo "=== Test: Preflight Checks ==="
    bash "$SCRIPT" test 2>&1 | tee test_output.log
    
    # Verify all checks ran
    grep -q "Pre-flight checks" test_output.log || return 1
    grep -q "RAM:" test_output.log || return 1
    grep -q "Disk" test_output.log || return 1
    
    echo "✅ Preflight checks test passed"
}

test_fresh_install() {
    echo "=== Test: Fresh Install ==="
    
    # Pre-check: no prior install
    [[ ! -f ~/.robot_install_state/install_completed.txt ]] || {
        echo "❌ Prior install detected. Clean first."
        return 1
    }
    
    # Run install (non-interactive mode would require pre-answering prompts)
    # This is where you'd use `expect` or similar for automation
    
    echo "⚠️  Manual test required (interactive prompts)"
}

test_doctor_healthy() {
    echo "=== Test: Doctor on Healthy System ==="
    bash "$SCRIPT" doctor 2>&1 | tee test_output.log
    
    # Check for healthy indicators
    grep -q "services healthy" test_output.log || return 1
    
    echo "✅ Doctor test passed"
}

# Run tests
test_preflight_checks
test_doctor_healthy

echo "
=== Test Summary ===
See test_output.log for details
Manual tests require snapshot/restore cycles
"
```

---

## Sign-Off Checklist

Before marking script as "bulletproof":

- [ ] All 25+ tests passed on fresh Ubuntu 22.04
- [ ] Edge cases handled gracefully
- [ ] Rollback mechanisms work
- [ ] Error messages are actionable
- [ ] No silent failures
- [ ] Installation completes without user intervention (except prompts)
- [ ] Uninstall returns system to clean state
- [ ] Credentials remain secure (600 perms)
- [ ] Services auto-start after reboot
- [ ] Thor/Spark can connect from network
- [ ] Documentation matches actual behavior

---

## Test Log Template

```
Test Date: YYYY-MM-DD
Tester: <name>
Environment: Ubuntu 22.04.X, <RAM>GB RAM, <disk>GB disk, <GPU>

Test Suite 1: Preflight Checks
- [x] Test 1.1: Insufficient RAM - PASS (warned correctly)
- [x] Test 1.2: Insufficient Disk - PASS (failed check)
- [ ] Test 1.3: Port in use - SKIP (no conflicting service)
...

Issues Found:
1. Test 2.4 - Docker group check didn't exit cleanly (FIXED: added exit 0)
2. Test 3.2 - Rollback didn't restore (FIXED: added cp from backup)

Overall Status: PASS (with fixes applied)
```
