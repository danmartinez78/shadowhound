---
tags: [project, legacy]
status: draft
related: []
summary: >
  Legacy documentation preserved from earlier phases for review and migration.
---

# Web UI Redesign Requirements

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
**Date:** October 6, 2025  
**Status:** 📝 Requirements documented, to be implemented in Phase 5 (Polish)  
**Priority:** Medium - After core functionality works

---

## Current State: Problems

### Visual Design Issues
- ❌ **Looks "cutesy"** - Not professional enough for demo
- ❌ **WebRTC skill buttons** - These don't work reliably, clutter the UI
- ❌ **Lacks technical feel** - Should look more like mission control

### Missing Features
- ❌ **No camera feed** - Can't see what robot sees
- ❌ **No diagnostics** - No visibility into robot state
- ❌ **No spatial awareness** - Can't see where robot is

---

## Target Aesthetic: "Science Fiction Mission Control"

### Design References
Think:
- **NASA Mission Control** - Clean, technical, information-dense
- **Sci-fi interfaces** - Blade Runner, Minority Report, Iron Man's JARVIS
- **Military UAV control** - Dark theme, tactical displays
- **Professional robotics** - Boston Dynamics control interfaces

### Visual Style
```
Color Palette:
  Background: Dark (#0a0e1a, #141b2d)
  Primary: Electric blue (#00d4ff, #0099ff)
  Accent: Cyan/teal (#00ffaa, #00ccaa)
  Warning: Amber (#ffa500)
  Error: Red (#ff3333)
  Text: Light gray (#e0e0e0)
  
Typography:
  Monospace for data (Roboto Mono, SF Mono)
  Sans-serif for labels (Inter, SF Pro)
  
UI Elements:
  - Glowing borders on active elements
  - Subtle grid patterns in backgrounds
  - Hexagonal or angular panels (not rounded)
  - Animated data streams
  - Scanline effects (subtle)
```

---

## New UI Layout

### Main Dashboard (Full Screen)
```
┌─────────────────────────────────────────────────────────────┐
│ SHADOWHOUND MISSION CONTROL              [STATUS] [BATTERY] │
├─────────────────────────┬───────────────────────────────────┤
│                         │                                   │
│   CAMERA FEED           │   MAP VIEW / BEV LIDAR            │
│   (1280x720)            │   - Robot position                │
│                         │   - Lidar point cloud (BEV)       │
│   [Front Camera]        │   - Waypoints                     │
│   [Left Camera]         │   - Path visualization            │
│   [Right Camera]        │   - Obstacle overlay              │
│                         │                                   │
│                         │   Toggle: [MAP] [LIDAR] [BOTH]    │
├─────────────────────────┼───────────────────────────────────┤
│                         │                                   │
│   MISSION CONTROL       │   DIAGNOSTICS (Optional Panel)    │
│                         │                                   │
│   [Text Input]          │   System Status:                  │
│   > Enter mission...    │   • CPU: 45%    • Temp: 52°C      │
│                         │   • RAM: 2.1GB  • Battery: 87%    │
│   [EXECUTE] [CANCEL]    │                                   │
│                         │   Navigation:                     │
│   Mission Log:          │   • Position: (2.3, 1.5, 45°)    │
│   ▸ Navigating to...    │   • Velocity: 0.3 m/s             │
│   ▸ Capturing image...  │   • Status: MOVING                │
│   ✓ Mission complete    │                                   │
│                         │   Sensors:                        │
│   Skills API Status:    │   • Lidar: OK   • IMU: OK         │
│   ✓ nav.goto           │   • Camera: OK  • Wifi: -52dBm    │
│   ✓ vision.snapshot    │                                   │
│   ✓ lidar.scan         │   [Toggle Diagnostics]            │
│                         │                                   │
└─────────────────────────┴───────────────────────────────────┘
```

---

## Component Specifications

### 1. Camera Feed (Required)

**Location:** Top-left quadrant  
**Size:** ~640x480 or 1280x720 depending on bandwidth

**Features:**
- Live video stream from robot's front camera
- Camera selector tabs: [Front] [Left] [Right]
- Overlay information:
  - Timestamp
  - Resolution
  - FPS counter
  - Object detection bounding boxes (if enabled)
- Click to fullscreen
- "Snapshot" button to capture current frame

**Tech Stack:**
```javascript
// Use WebRTC or MJPEG stream
<video id="robotCamera" autoplay>
  <source src="/camera/stream" type="video/webrtc">
</video>

// Overlay canvas for annotations
<canvas id="cameraOverlay"></canvas>
```

**WebRTC Stream:**
- Already have WebRTC connection to robot
- Can we tap into existing video channel?
- Or subscribe to ROS2 compressed image topic and relay

---

### 2. BEV Lidar Display (Required)

**Location:** Top-right quadrant  
**Size:** Square aspect ratio

**Features:**
- Bird's-eye view of robot and surroundings
- Lidar points rendered as dots (color by distance)
- Robot icon at center (oriented correctly)
- Detected obstacles highlighted
- Path planning visualization
- Waypoint markers
- Grid overlay with distance rings

**Visualization:**
```
        ↑ North
        |
  5m ─  • • •        • = Lidar points
        •   •        ■ = Robot
  3m ─  • ■ •        → = Heading
        •   •        ◆ = Waypoint
  1m ─  • • •        ═ = Planned path
        |
    ────┼────→ East
        0m  3m  5m
```

**Tech Stack:**
```javascript
// Canvas-based rendering
const canvas = document.getElementById('lidarView');
const ctx = canvas.getContext('2d');

// Subscribe to /scan topic via rosbridge
ros.subscribe('/scan', 'sensor_msgs/LaserScan', (msg) => {
  renderLidarScan(msg, ctx);
});

// Or use three.js for 3D point cloud
import * as THREE from 'three';
```

**Toggle Modes:**
- [MAP] - Show static map with robot position
- [LIDAR] - Show live lidar point cloud
- [BOTH] - Overlay lidar on map

---

### 3. Mission Control Panel (Required)

**Location:** Bottom-left quadrant

**Features:**
- Natural language mission input
  ```
  ┌─────────────────────────────────────┐
  │ > Go to the kitchen and tell me    │
  │   what you see                      │
  └─────────────────────────────────────┘
  [EXECUTE MISSION]  [EMERGENCY STOP]
  ```

- Mission execution log (scrollable)
  ```
  12:34:01 ▸ Planning mission...
  12:34:02 ✓ Generated 5-step plan
  12:34:03 ▸ Executing nav.goto(5.0, 2.0)
  12:34:15 ✓ Navigation complete
  12:34:16 ▸ Executing vision.snapshot()
  12:34:17 ✓ Image captured
  12:34:18 ▸ Analyzing image with VLM...
  12:34:22 ✓ Analysis complete
  12:34:22 📊 REPORT: I see a kitchen...
  ```

- Active skill indicators
  ```
  Skills Available:
  ✓ nav.goto        ✓ vision.snapshot
  ✓ nav.spin        ✓ vision.describe
  ✓ nav.stop        ✓ lidar.scan
  ```

**Removed:**
- ❌ WebRTC API skill buttons (sit, stand, wave, etc.)
- These don't work reliably and aren't needed for MVP

---

### 4. Diagnostics Panel (Optional/Collapsible)

**Location:** Bottom-right quadrant  
**Default State:** Collapsed to icon bar

**Toggle Button:** `[⚙️ Show Diagnostics]` / `[× Hide Diagnostics]`

**When Expanded:**
```
┌─────────────────────────────────┐
│ SYSTEM DIAGNOSTICS              │
├─────────────────────────────────┤
│ Hardware:                       │
│  CPU Usage:    ████████░░  45%  │
│  Memory:       ███░░░░░░░  2.1G │
│  Temperature:  52°C / 85°C max  │
│  Battery:      ██████████  87%  │
│                ↓ 0.3A charging  │
├─────────────────────────────────┤
│ Navigation:                     │
│  Position:     (2.34, 1.56)     │
│  Orientation:  45.2° (NE)       │
│  Velocity:     0.32 m/s         │
│  Status:       MOVING           │
│  Path Length:  12.5m remaining  │
├─────────────────────────────────┤
│ Sensors:                        │
│  Lidar:        ✓ OK (10Hz)      │
│  IMU:          ✓ OK (100Hz)     │
│  Camera:       ✓ OK (30fps)     │
│  GPS:          ✗ No signal      │
├─────────────────────────────────┤
│ Network:                        │
│  WiFi RSSI:    -52 dBm (Good)   │
│  ROS Topics:   ✓ 47 active      │
│  WebRTC:       ✓ Connected      │
│  Latency:      23ms             │
└─────────────────────────────────┘
```

**When Collapsed:**
Just show icon bar with key metrics:
```
[🔋87%] [🌡️52°C] [📡-52dBm] [⚙️45%] [▶️ Show More]
```

---

### 5. Header Bar (Always Visible)

```
┌──────────────────────────────────────────────────────┐
│ 🐕 SHADOWHOUND MISSION CONTROL                       │
│                                                       │
│ Status: OPERATIONAL  Battery: 87%  Signal: ████▌     │
│ Mission: "Explore Kitchen" - Step 3/5 - ETA: 2:34    │
│                                                       │
│                    [⚠️ E-STOP]  [⚙️ Settings]  [👤]  │
└──────────────────────────────────────────────────────┘
```

---

## Implementation Details

### Technology Stack

**Frontend:**
```javascript
// Core framework
React + TypeScript (already using?)

// UI Components
- Tailwind CSS for styling
- Framer Motion for animations
- React Three Fiber for 3D lidar viz (optional)

// ROS Communication
- roslibjs for websocket bridge
- rosbridge_suite on backend

// Camera Streaming
- WebRTC (already connected?)
- Or MJPEG fallback via Flask endpoint
```

**Backend:**
```python
# Already have shadowhound_mission_agent
# Add endpoints:
- /api/camera/stream    # Video stream
- /api/diagnostics      # System metrics
- /api/lidar/scan       # Latest lidar data
- /ws/rosbridge         # Websocket bridge
```

### File Structure
```
shadowhound_ui/
├── src/
│   ├── components/
│   │   ├── CameraFeed.tsx          # Video stream component
│   │   ├── LidarDisplay.tsx        # BEV lidar visualization
│   │   ├── MissionControl.tsx      # Command input & log
│   │   ├── DiagnosticsPanel.tsx    # System metrics
│   │   └── HeaderBar.tsx           # Status bar
│   ├── styles/
│   │   ├── theme.css               # Dark sci-fi theme
│   │   └── animations.css          # Glows, scanlines
│   ├── hooks/
│   │   ├── useROS.ts               # ROS topic subscriptions
│   │   ├── useCamera.ts            # Camera stream hook
│   │   └── useLidar.ts             # Lidar data hook
│   └── utils/
│       ├── rosbridge.ts            # ROS websocket client
│       └── coordinate.ts           # Transform helpers
└── public/
    └── assets/
        ├── robot-icon.svg          # For lidar display
        └── grid-pattern.svg        # Background texture
```

---

## Visual Design Mockup

### Color Scheme Example
```css
:root {
  /* Background layers */
  --bg-primary: #0a0e1a;
  --bg-secondary: #141b2d;
  --bg-panel: #1a2332;
  
  /* UI elements */
  --border-dim: #2a3f5f;
  --border-active: #00d4ff;
  
  /* Text */
  --text-primary: #e0e6ed;
  --text-secondary: #8b95a5;
  --text-dim: #5a6470;
  
  /* Status colors */
  --status-ok: #00ffaa;
  --status-warning: #ffa500;
  --status-error: #ff3333;
  --status-active: #00d4ff;
  
  /* Effects */
  --glow-blue: 0 0 10px rgba(0, 212, 255, 0.5);
  --glow-green: 0 0 10px rgba(0, 255, 170, 0.5);
}

/* Panel style */
.panel {
  background: var(--bg-panel);
  border: 1px solid var(--border-dim);
  border-radius: 2px; /* Minimal rounding */
  box-shadow: 
    inset 0 0 50px rgba(0, 212, 255, 0.02),
    0 0 20px rgba(0, 0, 0, 0.5);
}

/* Active panel */
.panel.active {
  border-color: var(--border-active);
  box-shadow: var(--glow-blue);
}

/* Data text (monospace) */
.data-value {
  font-family: 'Roboto Mono', monospace;
  color: var(--status-active);
  text-shadow: var(--glow-blue);
}

/* Subtle scanline effect */
.scanlines::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: linear-gradient(
    transparent 50%,
    rgba(0, 212, 255, 0.02) 50%
  );
  background-size: 100% 4px;
  pointer-events: none;
  animation: scan 8s linear infinite;
}
```

### Typography
```css
/* Headers */
h1, h2 {
  font-family: 'Inter', sans-serif;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--text-primary);
}

/* Data displays */
.metric-value {
  font-family: 'Roboto Mono', monospace;
  font-size: 1.2em;
  font-weight: 500;
  color: var(--status-active);
}

/* Mission log */
.log-entry {
  font-family: 'Roboto Mono', monospace;
  font-size: 0.9em;
  line-height: 1.6;
  color: var(--text-secondary);
}
```

---

## Animation & Effects

### Subtle Enhancements (Not Overdone)
```css
/* Pulse effect on active elements */
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

.status-active {
  animation: pulse 2s ease-in-out infinite;
}

/* Data stream effect */
@keyframes dataStream {
  from { transform: translateX(-100%); }
  to { transform: translateX(100%); }
}

.data-stream {
  animation: dataStream 3s linear infinite;
}

/* Glow on hover */
.button:hover {
  box-shadow: 0 0 20px rgba(0, 212, 255, 0.6);
  border-color: var(--status-active);
}
```

### NO Overdone Effects
- ❌ No spinning 3D graphics (unless functional)
- ❌ No excessive particle effects
- ❌ No distracting animations
- ✅ Subtle, purposeful motion only

---

## Responsive Behavior

### Desktop (Primary Target)
- Full 4-panel layout
- All features visible

### Tablet (Secondary)
- Stack panels vertically
- Camera on top, controls in middle, diagnostics collapsible

### Mobile (Tertiary Priority)
- Tabbed interface
- [Camera] [Map] [Control] [Diagnostics] tabs
- Mission input always visible

---

## Accessibility

Even with dark theme:
- ✅ High contrast text (WCAG AA)
- ✅ Keyboard navigation
- ✅ Screen reader labels
- ✅ Focus indicators
- ✅ Color not sole indicator (use icons too)

---

## Implementation Priority

### Phase 5 (Polish & Demo) Breakdown

**Week 1: Core Redesign**
1. Day 1-2: New layout structure, dark theme
2. Day 3: Camera feed integration
3. Day 4: BEV lidar display
4. Day 5: Mission control panel

**Week 2: Polish**
1. Day 6: Diagnostics panel
2. Day 7: Animations and effects
3. Day 8-9: Testing and refinement
4. Day 10: Final demo prep

---

## Before/After Comparison

### Current UI (Problems)
```
┌────────────────────────────┐
│  🤖 RobotControl           │  ← Cutesy
├────────────────────────────┤
│                            │
│  [Stand] [Sit] [Wave]      │  ← Broken buttons
│  [Hello] [Stretch]         │  ← Clutter
│                            │
│  Send command: [____]      │  ← Basic
│                            │
└────────────────────────────┘
```

### New UI (Professional)
```
┌─────────────────────────────────────────┐
│ SHADOWHOUND MISSION CONTROL    87% 🔋  │  ← Professional
├──────────────────┬──────────────────────┤
│ CAMERA FEED      │ LIDAR / MAP VIEW     │  ← Functional
│ [Live Stream]    │ [Bird's Eye View]    │  ← Information
├──────────────────┼──────────────────────┤
│ MISSION CONTROL  │ DIAGNOSTICS          │  ← Technical
│ > Enter mission  │ [System Status]      │  ← Sci-fi feel
│ [EXECUTE]        │ [Toggle Details]     │
└──────────────────┴──────────────────────┘
```

---

## Testing Checklist

Before calling UI "done":
- [ ] Camera stream works (low latency)
- [ ] Lidar visualization updates smoothly (10Hz+)
- [ ] Mission log scrolls and highlights current step
- [ ] Diagnostics toggle works
- [ ] Theme looks good in demo lighting
- [ ] No UI lag during robot operation
- [ ] Emergency stop button is obvious and works
- [ ] Works on 1920x1080 display (demo monitor)

---

## Inspiration References

**Good Examples to Study:**
1. NASA Mission Control - Information density, professionalism
2. DJI Drone App - Camera feed + map + telemetry
3. Boston Dynamics Spot UI - Clean, functional, technical
4. Military UAV interfaces - Dark theme, tactical displays
5. Star Citizen ship HUD - Sci-fi aesthetic done right

**Bad Examples to Avoid:**
1. Cutesy robot toys - Too playful
2. Over-animated dashboards - Distracting
3. Low-contrast dark themes - Hard to read
4. Skeuomorphic designs - Dated

---

**Status:** Requirements documented. UI redesign scheduled for Phase 5 (after core functionality works). Focus on professional, technical aesthetic with live camera feed and BEV lidar display. Remove broken WebRTC skill buttons. 🎨

**Next:** Build Phase 1-4 first, then return to UI once we have data to display.


## Validation
- [ ] Legacy guidance reviewed for accuracy and converted to the new workflow where applicable.
- [ ] Links updated to use vault-friendly wikilinks or confirmed for external references.
- [ ] Outstanding migration work captured as tasks in the backlog.

## References
- [[history/history_hub|Knowledge Base Index]]
