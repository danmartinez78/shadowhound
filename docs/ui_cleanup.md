---
tags: [project, legacy]
status: draft
related: []
summary: >
  Legacy documentation preserved from earlier phases for review and migration.
---

# UI Cleanup - Remove Old "Cutesy" Elements

## Purpose
Preserve historical context while signaling that this page requires verification against the current workflow.

## Prerequisites
- Review the legacy notes below to understand original assumptions and instructions.
- Cross-check commands and links with the latest tooling before execution.

## Steps
1. Read through the legacy notes captured under **Legacy Notes** and flag outdated guidance.
2. Update or replace the content with validated procedures as time permits.
3. Record verification outcomes in the validation checklist and mark follow-up tasks in the backlog.

### Legacy Notes
**Date**: October 8, 2025  
**Branch**: `feature/dimos-integration`  
**Commits**: `9a66364` (dog emoji + quick commands), `5f0a5e4` (terminal integration)

## Problem

User reported seeing old UI elements after pulling latest code:
- Dog emoji 🐕 in browser title and header
- "Quick Commands" section with skill buttons (STAND, SIT, WAVE, etc.)
- Terminal had no text entry field
- Text entry was in separate "🎮 COMMAND CENTER" panel
- Redundant "📡 MISSION STATUS" panel duplicating terminal output

These were remnants from an earlier, more playful UI design that should have been removed when we implemented the professional Performance Metrics interface.

## Investigation

Searched for old UI elements across codebase:
```bash
grep -r "🐕\|Quick Commands" src/
```

Found them in `dashboard_template.html`:
- Line 5: `<title>🐕 ShadowHound Mission Control</title>`
- Line 293: `<h1>🐕 SHADOWHOUND</h1>`
- Lines 400-407: Quick Commands section with 6 skill buttons

## Changes Made

### Commit 9a66364: Remove Dog Emoji and Quick Commands

#### File: `dashboard_template.html`

1. **Removed dog emoji from title**:
   ```diff
   - <title>🐕 ShadowHound Mission Control</title>
   + <title>ShadowHound Mission Control</title>
   ```

2. **Removed dog emoji from header**:
   ```diff
   - <h1>🐕 SHADOWHOUND</h1>
   + <h1>SHADOWHOUND</h1>
   ```

3. **Removed Quick Commands section** (10 lines):
   ```diff
   - <h3>Quick Commands</h3>
   - <div class="quick-commands">
   -     <button class="btn btn-secondary" onclick="sendQuick('stand up')">🧍 STAND</button>
   -     <button class="btn btn-secondary" onclick="sendQuick('sit down')">🪑 SIT</button>
   -     <button class="btn btn-secondary" onclick="sendQuick('wave hello')">👋 WAVE</button>
   -     <button class="btn btn-secondary" onclick="sendQuick('perform dance 1')">💃 DANCE</button>
   -     <button class="btn btn-secondary" onclick="sendQuick('stretch')">🤸 STRETCH</button>
   -     <button class="btn btn-secondary" onclick="sendQuick('balance stand')">⚖️ BALANCE</button>
   - </div>
   ```

### Commit 5f0a5e4: Integrate Command Input into Terminal

#### File: `dashboard_template.html`

4. **Integrated command input into Terminal panel**:
   - Moved text input and execute button from separate panel into Terminal
   - Added `<div style="margin-top: 15px;">` wrapper for spacing
   - Now users type commands directly within terminal context

5. **Removed "📡 MISSION STATUS" panel**:
   ```diff
   - <!-- Mission Status -->
   - <div class="panel">
   -     <h2>📡 MISSION STATUS</h2>
   -     <div class="status-box">
   -         <div id="status">Waiting for commands...</div>
   -     </div>
   - </div>
   ```
   - Status messages were redundant (already shown in terminal)
   - All status now flows exclusively through terminal output

6. **Removed "🎮 COMMAND CENTER" panel**:
   ```diff
   - <!-- Command Center -->
   - <div class="panel">
   -     <h2>🎮 COMMAND CENTER</h2>
   -     <h3>Custom Command</h3>
   -     [... input field and button moved to terminal ...]
   - </div>
   ```

7. **Removed emoji from Terminal header**:
   ```diff
   - <h2>💻 TERMINAL</h2>
   + <h2>TERMINAL</h2>
   ```

8. **Cleaned up unused CSS**:
   - Removed `.status-box` styles (10 lines)
   - Removed `.quick-commands` styles (6 lines)

9. **Updated JavaScript**:
   - Removed `const statusDiv = document.getElementById('status');`
   - Removed all `statusDiv.textContent = ...` assignments
   - Status messages now only use `addTerminalLine()` for clean output

### JavaScript Functions

**Note**: The `sendQuick()` function was **kept** because it's still used by the main "EXECUTE" button via `sendCommand()`. Only the UI buttons that called it directly were removed.

## Testing

After changes:
1. ✅ Rebuilt package: `colcon build --packages-select shadowhound_mission_agent`
2. ✅ Verified diff: Removed dog emoji + Quick Commands section
3. ✅ Committed and pushed to `feature/dimos-integration`

## Current UI State

The dashboard now has a clean, professional interface:

### Header
```
SHADOWHOUND
AUTONOMOUS ROBOT MISSION CONTROL
[CONNECTION STATUS]
```

### Layout
- **Left Column**: 
  - Camera Feed panel
  - Diagnostics panel (robot mode, topics, action servers)
- **Right Column**: 
  - Performance Metrics panel (Agent Call, Overhead, Total Time, Commands, Averages)
- **Bottom (Full Width)**: 
  - Terminal panel with **integrated command input** (text field + "▶️ EXECUTE" button)

### Removed Elements
- ❌ Dog emoji from title/header
- ❌ Quick command buttons (STAND, SIT, WAVE, DANCE, STRETCH, BALANCE)
- ❌ "📡 MISSION STATUS" panel (redundant with terminal output)
- ❌ "🎮 COMMAND CENTER" panel (merged into terminal)
- ❌ Emoji from Terminal header (💻 -> plain "TERMINAL")
- ❌ Unused CSS classes (.status-box, .quick-commands)

## Next Steps

For users seeing old UI:
1. Pull latest code: `git pull origin feature/dimos-integration`
2. Rebuild: `colcon build --packages-select shadowhound_mission_agent --symlink-install`
3. Restart node: `pkill -f mission_agent && ros2 launch ...`
4. **Hard refresh browser**: `Ctrl+Shift+R` (or `Cmd+Shift+R` on Mac)
5. Or use incognito window to bypass cache

## Why This Happened

The dashboard template file (`dashboard_template.html`) is **not** symlink-installed by colcon. It gets copied during the build process. Therefore:

1. Pulling code changes alone doesn't update the deployed template
2. Must run `colcon build` to copy updated template to `install/`
3. Must hard-refresh browser to clear cached HTML/CSS/JS

This is different from Python files, which use `--symlink-install` and update immediately.

## Related Documentation

- Performance Metrics: See commit `0790578` for implementation details
- Timing Display Fix: See `docs/TIMING_DISPLAY_FIX.md`
- Browser Cache: See `docs/CACHE_CLEARING_GUIDE.md`
- Deployment Sync: See `docs/LAPTOP_DIAGNOSTIC.md`


## Validation
- [ ] Legacy guidance reviewed for accuracy and converted to the new workflow where applicable.
- [ ] Links updated to use vault-friendly wikilinks or confirmed for external references.
- [ ] Outstanding migration work captured as tasks in the backlog.

## References
- [[index|Knowledge Base Index]]
