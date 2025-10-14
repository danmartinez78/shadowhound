---
tags: [planning, meta]
status: complete
related: [ideas_backlog, roadmap, todo]
summary: >
  Summary of how user's running todo/ideas list was analyzed and integrated into project planning documents.
---

# Ideas Integration Summary

**Date**: 2025-10-13  
**Task**: Integrate user's chaotic running todo/ideas list into structured planning docs

## What Was Done

### 1. Cross-Checked Against Existing Work

Searched codebase and docs for:
- **Personality system** - Found in `docs/history/` (planned but not implemented)
- **WebRTC skills** - Found extensive documentation of debugging efforts and MVP pivot decision
- **Compressed images** - Found in DIMOS submodule code (exists there, not in ShadowHound repo)

### 2. Created `ideas_backlog.md`

New file: `docs/project_overview/ideas_backlog.md`

**Purpose**: Capture nascent/exploratory ideas that aren't ready for TODO or Roadmap

**Categories**:
- 🎭 **Personality System** - Tachikoma-inspired with corpus-based generation
- 🗣️ **Voice & Speech** - Whisper STT + TTS realtime API
- 🔧 **Hardware Integration** - Mic on robot, power Thor from battery, cyberdeck
- 🧠 **AI Enhancements** - RAG, NVIDIA tools (greenwave_monitor, ReMEmbR, GR00T)
- 📊 **Visualization** - Foxglove transition, Web UI enhancements (BEV, 360° camera, terminal mode)
- 🤖 **Advanced Skills** - ros.topic_echo, SLAM Toolbox, additional Nav2 skills
- 🔬 **Research** - ODD (Operational Design Domain), Obsidian integration
- 🚨 **Known Issues** - Camera compressed, lidar voxels, WebRTC breaks Nav2, pickup breaks commands

### 3. Classification Results

#### ✅ Already Documented (Don't Need to Add)
- **Personality system** - Extensively documented in `docs/history/roadmap_detailed.md` and `docs/history/agent_tasks.md`
- **Voice/TTS** - In historical roadmap
- **WebRTC skills debugging** - **ABANDONED per MVP pivot decision**
  - See `docs/history/mvp_plan_pivot.md`
  - See `docs/history/command_mode_conflict.md` for technical details
  - Decision: Nav2 provides equivalent functionality, WebRTC skills too problematic
- **Compressed camera** - In DIMOS submodule code, needs work in `go2_ros2_sdk` (upstream)

#### 🔴 Added to Phase 0-1 (Critical Testing)
None from user's list (these were all future features)

#### 🟡 Added to Ideas Backlog (Exploratory)
All items categorized and documented with:
- Related existing work links
- Questions to resolve
- Blockers and prerequisites
- Next steps when actionable

## Key Findings

### 1. WebRTC Skills - Temporarily Abandoned
**User's Note**: "webrtc skills do not work (only via cli pub), cli pub breaks nav2"

**Reality**: This was **extensively debugged and documented**, then **temporarily set aside** in October 2025 MVP pivot.

**Documentation**:
- `docs/history/mvp_plan_pivot.md` - Strategic decision to deprioritize WebRTC skills for MVP
- `docs/history/command_mode_conflict.md` - Full technical analysis (407 lines)

**Key Points**:
- WebRTC skills (sit, stand) technically work via CLI but break Nav2/teleop
- Root cause: Sport Mode vs. Nav2 control mode conflict
- Working alternative: `joy_node` allows both without breaking
- Decision: Focus on Nav2 for MVP, revisit WebRTC skills post-Phase 3

**Status**: ⏸️ Temporarily abandoned (not permanently), ✅ Extensively documented

**When to Revisit**: After Phase 3 (Hardware Validation) when real robot testing can investigate mode switching

---

### 2. Personality System - Planned Not Implemented
**User's Note**: "personality feature branch work/status?"

**Reality**: No feature branch exists, but **extensively planned** in historical docs.

**Documentation**:
- `docs/history/roadmap_detailed.md` - Agent Personality System section
- `docs/history/agent_tasks.md` - TASK-AI-01 with implementation details

**Plans Include**:
- Personality traits as LLM system prompt modifiers
- Configuration schema (YAML)
- Presets: TARS, HAL9000, Helpful Assistant
- Traits: humor, verbosity, formality, emotional_tone
- Voice personality parameters for TTS

**Status**: 💡 Planned, not started

---

### 3. Camera Compressed - In DIMOS Submodule
**User's Note**: "add camera_compressed from dimos go2 ros2 sdk"

**Reality**: Compressed image handling **already exists in DIMOS submodule**:

**Code Locations**:
- `src/dimos-unitree/dimos/robot/unitree/unitree_ros_control.py:34`
  - `CAMERA_TOPICS` dict includes `"compressed": {"topic": "camera/compressed", "type": CompressedImage}`
- `src/dimos-unitree/dimos/robot/ros_control.py:402-403`
  - Handles `CompressedImage` conversion with `compressed_imgmsg_to_cv2`

**Missing**: GO2 ROS2 SDK doesn't actually **publish** the `camera/compressed` topic

**Solution**: Work needs to happen in `go2_ros2_sdk` repository (upstream), not ShadowHound

**Options**:
1. Fork `go2_ros2_sdk` and add compressed publisher
2. Add `image_transport` republisher node in ShadowHound
3. Wait for upstream fix

**Status**: ⏳ Blocked on upstream work

---

### 4. Lidar Accumulated Voxels - New Issue
**User's Note**: "odd artifacts upon multiple bringups, accumulated voxels remain"

**Status**: Not previously documented, added to Known Issues in `ideas_backlog.md`

**Questions Added**:
- C++ vs. Python lidar node - which has the issue?
- Need probabilistic occupancy mapping with voxel clearing?
- Existing ROS2 packages for raytracing-based clearing?

**Next Steps**:
- Test C++ vs. Python node
- Research Nav2 costmap clearing behavior
- Consider Phase 0 testing task

---

## Recommendations

### Immediate Actions (Phase 0)
1. **Test camera topics** - Verify what's actually published by GO2 SDK
   - Add to Phase 0 TODO
2. **Test lidar voxel issue** - C++ vs. Python node comparison
   - Add to Phase 0 TODO
3. **Test pickup robot command execution** - Reproduce and document
   - Add to Phase 0 TODO

### Phase 1+ Features
- Everything else in `ideas_backlog.md` stays there until prerequisites met

### Documentation Maintenance
- Review `ideas_backlog.md` quarterly
- Move actionable items to TODO when ready
- Archive stale ideas that are no longer relevant

---

## Files Created/Modified

### Created
- ✅ `docs/project_overview/ideas_backlog.md` (580+ lines)
  - Comprehensive catalog of all future ideas
  - Links to existing documentation
  - Questions and blockers identified
  - Criteria for moving items out

- ✅ `docs/project_overview/ideas_integration_summary.md` (this file)
  - Records what was found and how it was handled

### Next: Update TODO
Should add Phase 0 testing tasks:
- [ ] Test camera topics (raw vs. compressed availability)
- [ ] Test lidar voxel accumulation (C++ vs. Python node)
- [ ] Test pickup robot command execution issue
- [ ] Investigate RCL logging_rosout duplicate publisher warning

---

## Validation

- [x] All user's ideas analyzed and categorized
- [x] Cross-checked against existing documentation
- [x] WebRTC status clarified (temporarily abandoned, documented, will revisit post-Phase 3)
- [x] Personality status clarified (planned, not implemented)
- [x] Camera compressed status clarified (DIMOS has handler, SDK doesn't publish)
- [x] New issues documented (lidar voxels, pickup breaks commands)
- [x] Clear criteria for moving items from backlog to TODO/Roadmap
- [x] Maintenance plan documented

---

## References

- [Ideas Backlog](ideas_backlog.md) - Full catalog of future work
- [TODO](../development/todo.md) - Active task list
- [Roadmap](roadmap.md) - Phase plan
- [MVP Plan Pivot](../history/mvp_plan_pivot.md) - WebRTC abandonment decision
- [Command Mode Conflict](../history/command_mode_conflict.md) - WebRTC technical deep-dive
- [Roadmap Detailed](../history/roadmap_detailed.md) - Historical personality/voice planning
