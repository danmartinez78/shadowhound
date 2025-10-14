# Thor System Utilities Setup

**Priority:** Medium  
**Status:** Backlog  
**Related:** Issue #12 - Local LLM Support

## Problem

Thor needs better system monitoring and memory management tools for working with LLMs:

1. **jtop not installed** - Can't monitor GPU usage, memory, thermals in real-time
2. **Manual memory clearing** - Users report needing to clear memory cache between model loads
3. **No automated cleanup** - Switching models requires manual intervention

From NVIDIA forum users:
> "I also note that every time I switch models I have to go into jtop and clear the memory cache manually. Am I missing something?"

## Required Tools

### 1. jtop (jetson-stats)
**What:** Real-time monitoring for Jetson systems (GPU, CPU, RAM, thermal, power)  
**Install:**
```bash
sudo apt update
sudo apt install python3-pip
sudo pip3 install -U jetson-stats
sudo systemctl restart jtop.service
# Reboot required
sudo reboot
# Then run: jtop
```

**Usage:**
- Real-time GPU memory monitoring
- Thermal throttling detection
- Power consumption tracking
- Memory cache clearing (via UI)

### 2. Automated Memory Management
**What:** Script to clear caches before model loads  
**Commands:**
```bash
# Clear page cache, dentries, and inodes
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# Kill zombie processes
sudo pkill -9 python3

# Check available memory
free -h
```

### 3. Model Switching Helper
**What:** Script to safely switch between models with cleanup

**Pseudocode:**
```bash
switch_model.sh <model_name>
  1. Stop current vLLM container
  2. Clear GPU memory
  3. Clear system caches
  4. Wait 5 seconds
  5. Start new model
  6. Verify health
```

## Acceptance Criteria

- [ ] jtop installed and working on Thor
- [ ] Document jtop usage in Thor setup guide
- [ ] Create memory cleanup script (scripts/thor_cleanup_memory.sh)
- [ ] Create model switching script (scripts/thor_switch_model.sh)
- [ ] Add cleanup to vLLM startup script (automatic)
- [ ] Test: Switch between 3 different models without manual intervention
- [ ] Document when/why manual cleanup might still be needed

## Nice to Have

- Telegraf + Grafana dashboard for Thor metrics
- Automated alerts on OOM conditions
- Model memory requirements database
- Pre-flight checks before model load

## Timeline

**Phase 1 (Quick Fix):** Add memory cleanup to existing vLLM script  
**Phase 2 (Full Solution):** Install jtop, create helper scripts  
**Phase 3 (Advanced):** Monitoring dashboard

## Notes

Current vLLM script already does:
```bash
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
```

But may need more aggressive cleanup between model switches.

**Priority:** Do this AFTER we validate vLLM works end-to-end. Don't want to debug jtop installation issues when testing LLM functionality.
