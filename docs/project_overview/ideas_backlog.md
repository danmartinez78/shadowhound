---
tags: [planning, ideas, future]
status: draft
related: [project_overview/roadmap, development/todo]
summary: >
  Nascent ideas, exploratory features, and future work items that are not yet actionable or difficult to prioritize into the roadmap.
---

# Ideas & Future Work Backlog

**Last Updated**: 2025-10-13

## Purpose

This document captures ideas, exploratory features, and future work that:
- **Are not yet actionable** - Need research, design, or prerequisites
- **Lack clear requirements** - Too vague for TODO items
- **Are exploratory** - May or may not be pursued
- **Are long-term** - Beyond Phase 4 horizon

**When an idea becomes actionable**, move it to:
- `todo.md` - If it's a clear task with acceptance criteria
- `roadmap.md` - If it's a phase-level feature with multiple deliverables
- Create dedicated design doc - If it needs detailed technical planning

## Prerequisites

- Familiarity with [Roadmap](roadmap.md) Phases 0-4
- Understanding of [TODO](../development/todo.md) structure

---

## 🎭 Personality System

### Tachikoma-Inspired Personality
**Concept**: Ghost in the Shell Tachikoma personality with humor, curiosity, and philosophical musings

**Inspiration**:
- [Tachikoma Wiki](https://ghostintheshell.fandom.com/wiki/Tachikoma)
- [Tachikoma Days Episodes](https://ghostintheshell.fandom.com/wiki/Transcript:Tachikomatic_Days)

**Implementation Ideas**:
- Corpus-based personality generation from Tachikoma Days subtitles
- Pull episode transcripts and train personality prompt
- Configurable personality traits (humor, verbosity, formality, emotional_tone)
- Multiple personas selectable via `.env` variable

**Questions to Resolve**:
- Single robot persona with configs OR multiple distinct personas?
- Robot name? ("Enigma"? "Tachikoma"? User-configurable?)
- Male/female voice options?
- How to integrate into Web UI (personality selector, trait sliders)?

**Related Existing Work**:
- `docs/history/roadmap_detailed.md` - Agent Personality System section
- `docs/history/agent_tasks.md` - TASK-AI-01: Agent Personality System

**Blockers**:
- Phase 2 (Mission Agent) must be complete first
- Voice/TTS system needs to exist
- Need corpus collection and processing tools

**Next Steps**:
- Create `docs/research/personality_system.md` with detailed design
- Evaluate LLM fine-tuning vs. prompt engineering approaches
- Collect and process Tachikoma Days corpus

---

## 🗣️ Voice & Speech

### Whisper + TTS Realtime API
**Concept**: Voice interface for natural conversation with robot

**Features**:
- Listen mode (Whisper STT)
- Talk mode (TTS with personality voice parameters)
- Realtime API for low-latency interaction
- Voice mode toggle in Web UI

**Questions to Resolve**:
- Which TTS provider? (OpenAI Realtime, Azure, Coqui, ElevenLabs?)
- On-robot microphone OR laptop/phone microphone?
- Continuous listening vs. push-to-talk?
- How to handle background noise in robotics environment?

**Related Existing Work**:
- `docs/history/roadmap_detailed.md` - Voice Interface section

**Blockers**:
- Phase 2 complete (Web UI, agent working)
- Microphone hardware integration (Phase 3)
- Personality system design (for voice parameters)

**Next Steps**:
- Research TTS latency benchmarks
- Test Whisper on Jetson Thor
- Design microphone mounting and cabling

---

## 🔧 Hardware Integration

### Microphone on Robot
**Concept**: Integrated microphone for on-robot voice commands

**Requirements**:
- USB microphone or I2S MEMS mic
- Cable routing through robot body
- Power from robot's 5V rail or USB
- Noise cancellation (motor/servo sounds)

**Questions**:
- Where to mount? (head area, body?)
- Wired to Jetson Thor or GO2 internal computer?
- How to prevent motor noise interference?

**Blockers**:
- Phase 3 (Hardware Validation) complete
- Voice system working (Phase 2)

---

### Power Thor from Robot Battery
**Concept**: Eliminate external battery for Jetson Thor, power from GO2's battery

**Requirements**:
- Voltage step-down converter (GO2 battery ~24V → Thor ~19V)
- Power cable routing
- Safe disconnection mechanism
- Overcurrent protection

**Safety Concerns**:
- Can't risk damaging GO2's power system
- Need emergency cutoff if Thor draws too much power
- Thermal management in confined space

**Questions**:
- Where to tap power from GO2?
- How much current can Thor draw safely?
- Impact on GO2's runtime?

**Blockers**:
- Phase 3 complete
- Electrical engineering consultation needed

---

### Cyberdeck / Steam Deck Integration
**Concept**: Portable control interface mounted on robot or carried by operator

**Options**:
1. **Cyberdeck** - Custom Raspberry Pi-based terminal
2. **Steam Deck** - Gaming handheld running Linux

**Features**:
- Web UI access without laptop
- QR code on deck for WiFi connection info
- Emergency stop button
- Battery status display

**Questions**:
- Mounted on robot OR handheld by operator?
- Which platform? (weight, cost, power consumption trade-offs)
- How to secure mounting if robot-mounted?

**Blockers**:
- Phase 3 complete
- Web UI working reliably

---

## 🧠 AI & Agent Enhancements

### RAG (Retrieval Augmented Generation)
**Concept**: Agent can access codebase + docs for self-diagnosis and learning

**Use Cases**:
- Agent explains its own capabilities
- Agent troubleshoots issues by reading docs
- Agent learns from mission history

**Implementation**:
- Embed codebase and docs with sentence-transformers
- Vector database (ChromaDB, FAISS, or in-memory)
- Integrate into DIMOS agent's context

**Questions**:
- Embed on Thor (resource-constrained) or laptop?
- How to keep embeddings updated as code changes?
- Privacy concerns if using cloud embeddings?

**Blockers**:
- Phase 2 complete
- Embedding infrastructure

**Next Steps**:
- Prototype with ChromaDB locally
- Test embedding quality on technical docs

---

### NVIDIA Tools Exploration

#### greenwave_monitor
**Concept**: ROS2 performance monitoring with NVIDIA Isaac ROS

**Link**: https://github.com/NVIDIA-ISAAC-ROS/greenwave_monitor

**Use Cases**:
- Real-time node performance tracking
- Identify bottlenecks in ROS2 graph
- Optimize message flow

**Questions**:
- Does it work on Jetson Orin (Thor)?
- Compatible with our ROS2 Humble setup?

---

#### ReMEmbR
**Concept**: NVIDIA's memory/learning system (need more research)

**Status**: Very nascent, need to investigate if applicable to quadruped

---

#### GR00T
**Concept**: NVIDIA's humanoid foundation model

**Status**: Likely **not applicable** to quadruped robots (designed for humanoids)

---

## 📊 Visualization & UI

### Transition from RViz to Foxglove
**Concept**: Replace RViz with Foxglove Studio for visualization

**Benefits**:
- Better performance (web-based, GPU-accelerated)
- Cross-platform (desktop + web)
- Custom layouts and panels
- Recording and playback features

**Migration Work**:
- Convert RViz configs to Foxglove layouts
- Test all visualization features (camera, lidar, tf, map)
- Update documentation

**Questions**:
- Open-source self-hosted OR Foxglove Cloud?
- Performance on laptop vs. Thor?

**Blockers**:
- Phase 2 complete (need working visualization first)

---

### Web UI Enhancements

#### Terminal / Command Mode
**Concept**: Interactive command-line interface in Web UI

**Features**:
- Continuous prompt and response (like a shell)
- Command history and autocomplete
- Pre-canned ROS2 commands (topic list, node list, etc.)
- Diagnostic commands (battery, sensors, errors)

**Implementation**:
- WebSocket connection for bidirectional streaming
- Command parser with aliases
- Permission system (safe vs. dangerous commands)

---

#### Bird's Eye View (BEV)
**Concept**: Top-down visualization of robot in environment

**Features**:
- Real-time robot position on 2D map
- Lidar overlay
- Planned path visualization
- Obstacle markers

**Questions**:
- Use existing map OR generate from lidar?
- Integration with Nav2 costmaps?

---

#### 360° Camera Support
**Concept**: Display panoramic or multi-camera view in Web UI

**Requirements**:
- Stitch multiple GO2 camera feeds OR use 360° camera
- Interactive pan/zoom
- Low-latency streaming

**Blockers**:
- Need 360° camera hardware OR GO2 has multiple cameras to stitch

---

## 🤖 Advanced Skills

### `ros.topic_echo` Skill
**Concept**: Agent can access full `ros2 topic echo` data for any topic

**Use Cases**:
- "What's the robot's current velocity?"
- "Show me the latest lidar scan"
- "What's the battery voltage?"

**Implementation**:
- Skill parameter: `topic_name`, `msg_type` (optional)
- Subscribe dynamically to requested topic
- Return last N messages or specific fields

**Safety Concerns**:
- Could subscribe to high-bandwidth topics (camera, lidar)
- Need rate limiting and timeout

---

### SLAM Toolbox Skills
**Concept**: Integration with SLAM Toolbox for mapping and localization

**Skills**:
- `slam.start_mapping` - Begin SLAM session
- `slam.save_map` - Save current map
- `slam.load_map` - Load existing map
- `slam.relocalize` - Re-localize robot on map

**Blockers**:
- Phase 3 (Hardware + Navigation) complete
- SLAM Toolbox tested on GO2

---

### Additional Nav2 Skills
**Concept**: Expand beyond basic rotate/translate

**Skills**:
- `nav.follow_waypoints` - Sequential waypoint following
- `nav.patrol` - Continuous patrol pattern
- `nav.return_home` - Navigate to starting position
- `nav.set_speed` - Adjust navigation speed profile

---

## 🔬 Research & Standards

### ODD (Operational Design Domain)
**Concept**: Define where and when robot can safely operate

**Framework**: ASAM OpenODD
- **Link**: https://github.com/asam-oss/OpenODD (if exists)

**Use Cases**:
- Geofencing (robot won't leave safe areas)
- Weather restrictions (don't operate in rain)
- Time restrictions (no autonomous missions at night)
- Surface restrictions (no stairs, no gravel, etc.)

**Implementation**:
- ODD configuration file
- Runtime ODD checker
- Mission planner respects ODD constraints

**Questions**:
- Is there a ROS2 OpenODD implementation?
- How to detect ODD violations in real-time?

---

### Obsidian Integration
**Concept**: Two-way integration between documentation and robot

**Ideas**:
- Robot generates mission reports as Obsidian notes
- Agent can search documentation via RAG
- Automatic devlog entries from mission telemetry

**Questions**:
- What's the actual use case? (seems exploratory)
- Obsidian vault on robot OR sync to laptop?

---

## 📝 Documentation & Content

### Tachikoma Days Corpus Collection
**Tasks**:
- Pull subtitle files from Tachikoma Days episodes
- Convert to text corpus
- Clean and format for personality training
- Create prompt templates incorporating corpus

**Links**:
- [Tachikoma Days Transcripts](https://ghostintheshell.fandom.com/wiki/Transcript:Tachikomatic_Days#01)

---

## 🚨 Known Issues (Documented but Unresolved)

### Camera Compressed Topic
**Issue**: GO2 ROS2 SDK doesn't publish `camera/compressed` topic

**Status**: Documented in status analysis, needs work in `go2_ros2_sdk` subrepo (not ShadowHound repo)

**Options**:
1. Fork `go2_ros2_sdk` and add compressed publisher
2. Add image_transport republisher node in ShadowHound
3. Wait for upstream fix

**Documentation**: See `docs/project_overview/status_analysis_2025_10.md` - DIMOS Submodule section

---

### Lidar Accumulated Voxels
**Issue**: Voxels persist between bringups, causing phantom obstacles

**Symptoms**:
- Accumulated voxels remain after shutdown
- Moving robot between runs causes misaligned voxels
- Only fixed by rebooting physical robot

**Questions**:
- C++ lidar node vs. Python node - which has issue?
- Need probabilistic occupancy mapping with voxel clearing?
- Is there existing ROS2 package for raytracing-based voxel clearing?

**Next Steps**:
- Test C++ vs. Python lidar node
- Research ROS2 occupancy grid packages
- Check if Nav2 costmap has built-in clearing

---

### WebRTC Skills Break Nav2
**Issue**: Agent can call WebRTC skills (sit, stand) but they don't execute on robot. CLI publishing of WebRTC skills breaks Nav2 and teleop.

**Status**: **Documented and TEMPORARILY ABANDONED for MVP** (see `docs/history/mvp_plan_pivot.md`)

**Root Cause**: Mode conflict between Sport Mode (WebRTC skills) and Nav2 control

**Working Alternative**: `joy_node` allows translation/rotation AND sit/stand without breaking either

**Documentation**:
- `docs/history/mvp_plan_pivot.md` - Decision to temporarily abandon WebRTC skills
- `docs/history/command_mode_conflict.md` - Detailed analysis of the issue

**Future Investigation** (Post-Phase 3):
- Investigate `joy_node` implementation for clues
- May need mode switching logic in robot interface
- May need to flush command queue on mode change

**Blockers**:
- Phase 3 (Hardware validation) - needs real robot testing
- Currently low priority (Nav2 provides equivalent functionality)

**When to Revisit**:
- After Phase 3 hardware validation complete
- If use cases emerge requiring WebRTC-specific skills (sit, stand, wave, etc.)
- If mode switching mechanism becomes clearer

---

### Pickup Robot Breaks Commands
**Issue**: Picking up the physical robot breaks command execution

**Status**: Needs testing with teleop

**Test Procedure**:
1. Start teleop
2. Pickup robot
3. Put down robot
4. Try teleop again
5. Ask in Unitree Discord if others see same issue

---

### RCL Logging Rosout Warning
**Issue**: Duplicate publisher registration warning on startup

```
[WARN] [1759879365.424167315] [rcl.logging_rosout]: Publisher already registered for provided node name...
```

**Impact**: Cosmetic only (logs still work)

**Cause**: Multiple nodes with same name OR node restarts without proper cleanup

**Next Steps**:
- Identify which node is causing duplicate
- Fix node naming or cleanup logic

---

## 🎯 When to Move Items Out

### To `todo.md`
**Criteria**:
- Clear acceptance criteria defined
- Prerequisites met or in-progress
- Can be completed in 1-4 weeks
- No major design questions remaining

**Example**: "Test lidar accumulated voxels (C++ vs Python node)"

### To `roadmap.md`
**Criteria**:
- Large feature spanning multiple tasks
- Belongs to a specific phase
- Has estimated effort (weeks/months)
- Dependencies identified

**Example**: "Voice Interface System (Phase 2 enhancement)"

### To New Design Doc
**Criteria**:
- Complex technical design needed
- Multiple implementation approaches to compare
- Cross-cutting concerns (affects multiple packages)
- Requires team discussion

**Example**: "Personality System Architecture"

---

## Validation

- [ ] New ideas added to appropriate category
- [ ] Related existing documentation linked
- [ ] Blockers and prerequisites identified
- [ ] Questions/unknowns documented

---

## References

- [Roadmap](roadmap.md) - Phase-by-phase plan
- [TODO](../development/todo.md) - Active task list
- [Status Analysis](status_analysis_2025_10.md) - Current state assessment
- [MVP Plan Pivot](../history/mvp_plan_pivot.md) - WebRTC skills decision
- [Command Mode Conflict](../history/command_mode_conflict.md) - WebRTC technical analysis
- [Roadmap Detailed (History)](../history/roadmap_detailed.md) - Original personality/voice planning

---

**Maintenance**: Review quarterly, move actionable items to TODO/Roadmap, archive stale ideas.
