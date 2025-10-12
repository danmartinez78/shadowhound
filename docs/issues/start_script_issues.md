# Start Script Issues and Improvements

**Date:** October 12, 2025  
**File:** `start.sh`  
**Status:** Multiple issues identified  
**Priority:** Medium to High

---

## Issue 1: `--agent-only` Still Requires Topics (CRITICAL)

**Severity:** HIGH  
**Lines:** 1248-1252  

### Problem

```bash
# Agent-only mode: skip driver and verification
if [ "$AGENT_ONLY" = true ]; then
    print_info "Agent-only mode: Skipping driver launch and verification"
    echo ""
    launch_mission_agent
    return $?
fi
```

**What happens:**
- Skips driver launch ✅
- Skips verification ✅
- But agent STILL subscribes to topics and hangs! ❌

**Root cause:** The `--agent-only` flag only affects the start script, not the agent itself. The agent (via DIMOS `UnitreeROSControl`) unconditionally subscribes to:
- `camera/compressed` (or `camera/image_raw` if `use_raw=True`)
- `go2_states`

### Why This Is Hard

Mock mode is not just about skipping topics - it requires **proper interface mocking**:

1. **ROS Control Layer** (`UnitreeROSControl`):
   - Subscribes to topics in `__init__`
   - Needs mock callbacks that simulate robot state
   - Needs mock action clients for navigation skills

2. **Skills Layer** (DIMOS):
   - Skills like `Move`, `SpinLeft` expect real robot responses
   - Need to simulate: pose updates, velocity feedback, completion signals
   - Need to track: virtual position, orientation, timing

3. **Memory Layer** (ChromaDB + embeddings):
   - This part already works! ✅ (we just fixed it)
   - Can test in isolation with `test_embeddings_fix.py`

### Quick Workaround (Not Full Solution)

Add `disable_video_stream=True` flag to DIMOS initialization:
```python
# In mission_agent.py
self.control = UnitreeROSControl(
    disable_video_stream=True,  # Skip camera subscription
    mock_connection=True,        # Skip action clients
)
```

**But this only helps camera** - `go2_states` still required!

### Proper Solution (Separate Issue)

Mock mode needs its own design and implementation. Recommend:
1. **Create:** `docs/issues/mock_mode_architecture.md` - Design document
2. **Implement:** Mock providers for all robot interfaces
3. **Test:** Comprehensive mock mode test suite

For now, testing requires either:
- Full hardware setup (`./start.sh --prod`)
- External driver running (`./start.sh --skip-driver`)
- Standalone scripts like `test_embeddings_fix.py` (for specific components)

**Related:** See `docs/issues/mock_mode_ros_topic_dependency.md`

---

## Issue 2: Mock Mode Still Launches Driver

**Severity:** MEDIUM  
**Lines:** 1258-1267

### Problem

```bash
# Stage 1: Launch robot driver (unless skipped)
if [ "$SKIP_DRIVER" != true ]; then
    if ! launch_robot_driver; then
        # ...
    fi
fi
```

**What happens when `--mock` is used:**
- Driver still launches unless explicitly skipped
- Mock mode should imply no driver needed
- Wastes time and confuses users

### Expected Behavior

Mock mode should automatically skip driver:

```bash
# Stage 1: Launch robot driver (unless skipped or mock)
if [ "$SKIP_DRIVER" != true ] && [ "$MOCK_ROBOT" != "true" ]; then
    if ! launch_robot_driver; then
        # ...
    fi
else
    if [ "$MOCK_ROBOT" = "true" ]; then
        print_info "Mock mode: Skipping robot driver launch"
    else
        print_info "Skipping robot driver launch (--skip-driver flag)"
    fi
fi
```

---

## Issue 3: Verification Runs Even When Driver Skipped

**Severity:** MEDIUM  
**Lines:** 1270-1278

### Problem

```bash
# Stage 2: Verify topics (unless skipped or mock mode)
if [ "$SKIP_DRIVER" != true ] && [ "$MOCK_ROBOT" != "true" ]; then
    if ! verify_robot_topics; then
        # ...
    fi
fi
```

**Logic is correct BUT:**
- If user manually does `--skip-driver` (without `--mock`), verification is skipped
- This means they're assuming driver is already running
- But we don't verify it's actually there!

### Expected Behavior

Should verify topics when driver is skipped (assuming external driver):

```bash
# Stage 2: Verify topics
if [ "$MOCK_ROBOT" != "true" ]; then
    if [ "$SKIP_DRIVER" = true ]; then
        print_info "Driver launch skipped - verifying external driver topics..."
    else
        print_info "Verifying driver launched successfully..."
    fi
    
    if ! verify_robot_topics; then
        print_error "Topic verification failed"
        if [ "$SKIP_DRIVER" = true ]; then
            print_info "Is the external driver running?"
        fi
        read -p "Launch mission agent anyway? [y/N]: " continue_choice
        # ...
    fi
else
    print_info "Mock mode: Skipping topic verification"
fi
```

---

## Issue 4: Topic Verification Should Match Actual Configuration

**Severity:** LOW  
**Lines:** 1120-1128

### Problem

```bash
local critical_topics=(
    "/go2_states"
    "/camera/image_raw"
    "/imu"
    "/odom"
)
```

**Issues:**
1. Hard-codes `/camera/image_raw` but DIMOS uses **configurable** camera topics:
   - Default: `camera/compressed` (when `use_raw=False`)
   - Optional: `camera/image_raw` (when `use_raw=True`)
2. Mission agent also subscribes to `/camera/image_raw` for web UI
3. `/imu` and `/odom` are checked but agent doesn't strictly require them

### Context

From `dimos/robot/unitree/unitree_ros_control.py`:
```python
CAMERA_TOPICS = {
    "raw": {"topic": "camera/image_raw", "type": Image},
    "compressed": {"topic": "camera/compressed", "type": CompressedImage},
}

# Line 101: Default uses compressed
active_camera_topics = {
    "main": self.CAMERA_TOPICS["raw" if use_raw else "compressed"]
}
```

### Expected Behavior

**Option 1: Check both camera topics** (one will exist)
```bash
local critical_topics=(
    "/go2_states"  # Robot state (always required)
)

local camera_topics=(
    "/camera/image_raw"    # Used by: mission agent web UI, DIMOS if use_raw=True
    "/camera/compressed"   # Used by: DIMOS default
)

# Check if at least one camera topic exists
```

**Option 2: Make it configurable** (read from launch params)
```bash
# Get camera topic from environment or launch args
local camera_topic=${CAMERA_TOPIC:-/camera/compressed}
```

### Note

This is LOW priority because:
- In production, driver publishes BOTH topics (webrtc bridge converts)
- Verification will pass either way
- Only matters for minimal test setups

---

## Issue 5: Misleading "Topics Look Good" Message

**Severity:** LOW  
**Lines:** 1149-1155

### Problem

```bash
# If critical topics are missing, abort
if [ "$topics_ok" = false ]; then
    print_error "Critical topics are missing - cannot launch mission agent"
    # ...
    return 1
fi

# Topics look good, ask for final confirmation
read -p "Topics look good? Continue to launch mission agent? [Y/n]: " continue_choice
```

**Issue:** If topics are missing, we abort. But then we ask for confirmation even though we already checked. Redundant interaction.

### Expected Behavior

Only ask if there are warnings (not errors):

```bash
if [ "$topics_ok" = false ]; then
    print_error "Critical topics are missing - cannot launch mission agent"
    read -p "Launch anyway (may fail)? [y/N]: " continue_choice
    if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
        return 1
    fi
elif [ "$topics_warnings" = true ]; then
    print_warning "Some optional topics are missing"
    read -p "Continue to launch mission agent? [Y/n]: " continue_choice
    if [[ "$continue_choice" = "n" || "$continue_choice" = "N" ]]; then
        return 1
    fi
else
    print_success "All topics available - proceeding to launch"
fi
```

---

## Issue 6: PYTHONPATH and DIMOS Import

**Severity:** LOW  
**Lines:** 1238

### Problem

```bash
# Set PYTHONPATH for DIMOS
export PYTHONPATH="${SCRIPT_DIR}/src/dimos-unitree:${PYTHONPATH}"
```

**Issue:** This assumes DIMOS is a submodule at that exact path. If structure changes or DIMOS is installed differently, this breaks.

### Expected Behavior

Check if path exists before adding:

```bash
# Set PYTHONPATH for DIMOS
if [ -d "${SCRIPT_DIR}/src/dimos-unitree" ]; then
    export PYTHONPATH="${SCRIPT_DIR}/src/dimos-unitree:${PYTHONPATH}"
    print_info "Added DIMOS to PYTHONPATH"
else
    print_warning "DIMOS submodule not found at src/dimos-unitree"
    print_info "Agent may fail if DIMOS is not installed"
fi
```

---

## Issue 7: CONN_TYPE Default May Be Wrong

**Severity:** MEDIUM  
**Lines:** 1241

### Problem

```bash
# Export CONN_TYPE for DIMOS (defaults to webrtc if not set)
export CONN_TYPE=${CONN_TYPE:-webrtc}
```

**Issue:** Hardcodes webrtc as default. But:
- CycloneDDS mode exists and is valid
- Should respect .env configuration
- WebRTC requires WiFi, CycloneDDS requires Ethernet

### Expected Behavior

Get default from .env or make it explicit:

```bash
# Export CONN_TYPE for DIMOS
if [ -z "$CONN_TYPE" ]; then
    print_warning "CONN_TYPE not set - defaulting to 'webrtc'"
    print_info "Set CONN_TYPE in .env for CycloneDDS mode"
    export CONN_TYPE="webrtc"
else
    print_info "Using CONN_TYPE=$CONN_TYPE"
fi
```

---

## Issue 8: No Validation of Required Environment Variables

**Severity:** MEDIUM  
**Lines:** N/A (missing feature)

### Problem

Script doesn't validate that required environment variables are set before launching:
- `OPENAI_API_KEY` (if using OpenAI backend)
- `OPENAI_BASE_URL` (if using vLLM/Ollama)
- `OPENAI_MODEL` or `OLLAMA_MODEL`

**What happens:**
- Agent launches
- Fails during initialization
- Cryptic error messages

### Expected Behavior

Add validation before launch:

```bash
validate_environment() {
    print_section "Environment Validation"
    
    local agent_backend=${AGENT_BACKEND:-openai}
    local all_ok=true
    
    if [ "$agent_backend" = "openai" ]; then
        if [ -z "$OPENAI_BASE_URL" ] || [[ "$OPENAI_BASE_URL" == *"api.openai.com"* ]]; then
            # Using OpenAI cloud
            if [ -z "$OPENAI_API_KEY" ]; then
                print_error "OPENAI_API_KEY not set (required for OpenAI cloud)"
                all_ok=false
            else
                print_success "OPENAI_API_KEY configured"
            fi
        else
            # Using local LLM (vLLM, LocalAI, etc.)
            print_success "Using local LLM: $OPENAI_BASE_URL"
            print_info "No API key required for local LLM"
        fi
        
        if [ -z "$OPENAI_MODEL" ]; then
            print_warning "OPENAI_MODEL not set - will use default"
        else
            print_success "Model: $OPENAI_MODEL"
        fi
    elif [ "$agent_backend" = "ollama" ]; then
        if [ -z "$OLLAMA_BASE_URL" ]; then
            print_warning "OLLAMA_BASE_URL not set - using default (http://localhost:11434)"
        else
            print_success "Ollama: $OLLAMA_BASE_URL"
        fi
        
        if [ -z "$OLLAMA_MODEL" ]; then
            print_error "OLLAMA_MODEL not set (required)"
            all_ok=false
        else
            print_success "Model: $OLLAMA_MODEL"
        fi
    fi
    
    echo ""
    
    if [ "$all_ok" = false ]; then
        print_error "Environment validation failed"
        print_info "Check your .env file and try again"
        return 1
    fi
    
    return 0
}
```

---

## Issue 9: No Health Check for LLM Backend

**Severity:** LOW  
**Lines:** N/A (missing feature)

### Problem

Script doesn't verify that the LLM backend (vLLM, Ollama, OpenAI) is actually accessible before launching agent.

**What happens:**
- Agent launches
- Tries to connect to LLM
- Fails during first query
- Not user-friendly

### Expected Behavior

Add optional health check:

```bash
check_llm_backend() {
    print_section "LLM Backend Health Check"
    
    local agent_backend=${AGENT_BACKEND:-openai}
    
    if [ "$agent_backend" = "openai" ]; then
        local base_url=${OPENAI_BASE_URL:-https://api.openai.com/v1}
        
        print_info "Checking LLM endpoint: $base_url"
        
        if [[ "$base_url" == *"api.openai.com"* ]]; then
            print_info "OpenAI cloud endpoint - skipping health check"
        else
            # Local LLM - check if accessible
            local models_url="${base_url}/models"
            if curl -s -f -m 5 "$models_url" >/dev/null 2>&1; then
                print_success "LLM endpoint accessible"
                
                # Try to get model list
                local models=$(curl -s -m 5 "$models_url" 2>/dev/null)
                if [ -n "$models" ]; then
                    print_info "Available models:"
                    echo "$models" | jq -r '.data[].id' 2>/dev/null | head -5 | sed 's/^/  - /'
                fi
            else
                print_warning "LLM endpoint not accessible (may be down)"
                print_info "Check if vLLM/Ollama is running"
                read -p "Continue anyway? [y/N]: " continue_choice
                if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
                    return 1
                fi
            fi
        fi
    fi
    
    echo ""
    return 0
}
```

---

## Issue 10: Cleanup Doesn't Kill Background Driver

**Severity:** LOW  
**Lines:** 1340-1348

### Problem

```bash
# Kill robot driver if we started it
if [ -f "/tmp/shadowhound_driver.pid" ]; then
    local driver_pid=$(cat /tmp/shadowhound_driver.pid 2>/dev/null)
    if [ -n "$driver_pid" ]; then
        print_info "Stopping robot driver (PID: $driver_pid)..."
        kill $driver_pid 2>/dev/null || true
        sleep 1
        kill -9 $driver_pid 2>/dev/null || true
    fi
    rm -f /tmp/shadowhound_driver.pid
fi
```

**Issue:** PID file approach is fragile:
- What if driver crashes and PID is reused?
- What if PID file is stale?
- What if driver was started externally?

### Expected Behavior

Use process name matching:

```bash
# Kill robot driver processes
print_info "Stopping robot driver..."
pkill -f "go2_driver_node" 2>/dev/null && print_success "Driver stopped" || print_info "No driver found"
pkill -f "robot.launch.py" 2>/dev/null || true

# Clean up PID file
rm -f /tmp/shadowhound_driver.pid 2>/dev/null || true
```

---

## Summary of Critical Issues

| Issue | Severity | Impact | Blocks |
|-------|----------|--------|--------|
| #1: --agent-only hangs | HIGH | Can't test agent in isolation | Testing |
| #2: Mock launches driver | MEDIUM | Wastes time, confusing | UX |
| #3: Verification skipped | MEDIUM | May miss problems | Reliability |
| #8: No env validation | MEDIUM | Cryptic errors | UX |

**Note:** Issue #4 (camera topics) downgraded to LOW - both topics published in production, verification passes either way.

---

## Recommended Fix Priority

1. **DEFER (needs architecture work):**
   - Issue #1: Mock mode requires proper interface mocking (not a quick fix)
   - **Action:** Create `docs/issues/mock_mode_architecture.md` design document
   - **Workaround:** Use full driver or component-specific test scripts
   
2. **HIGH (usability - quick wins):**
   - Issue #8: Add environment validation (prevents cryptic errors)
   - Issue #2: Mock mode skips driver automatically (1-line fix)
   
3. **MEDIUM (correctness):**
   - Issue #3: Verify topics when driver skipped
   - Issue #7: CONN_TYPE handling
   
4. **LOW (nice to have):**
   - Issue #4: Camera topic detection (works in production anyway)
   - Issue #5: Better user prompts
   - Issue #6: PYTHONPATH validation
   - Issue #9: LLM health check
   - Issue #10: Better cleanup

---

## Related Files

- `start.sh` - Main launch script
- `docs/issues/mock_mode_ros_topic_dependency.md` - Root cause of Issue #1
- `src/shadowhound_mission_agent/launch/mission_agent.launch.py` - Agent launch file
- `.env` - Environment configuration

---

## Next Steps

1. Fix Issue #1 as quick workaround (1 line change)
2. Create comprehensive fix PR addressing all issues
3. Add integration tests for different launch modes
4. Update documentation with launch mode examples
