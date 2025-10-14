---
tags: [project, mvp, roadmap, planning]
status: active
related: [roadmap.md, project_history_oct_2025.md]
summary: >
  MVP definition and roadmap for ShadowHound household assistant robot
---

# ShadowHound MVP: Household Assistant Robot

**Created**: 2025-10-14  
**Status**: Planning  
**Target**: Functional household assistant with voice interaction and vision-based missions

---

## Executive Summary

Transform ShadowHound into an autonomous household assistant robot capable of executing natural language missions like "find the red ball in the living room" or "check if the oven is on in the kitchen." The robot will navigate dynamically, interact via voice with personality, and process everything onboard the Thor AGX compute platform.

### Success Criteria

The MVP is complete when the robot can:

1. ✅ Accept voice commands OR console/web commands
2. ✅ Execute vision-based missions (find objects, check appliance states)
3. ✅ Navigate safely in household environments (with/without prior map)
4. ✅ Respond with voice output expressing personality
5. ✅ Process all computation onboard Thor AGX (no cloud dependency for deployment)
6. ✅ Learn and remember spatial information over time

---

## MVP Definition

### Core Capabilities

**1. Natural Language Mission Execution**
- Input: "Find the red ball in the living room"
- System: Parse intent → Plan actions → Execute → Report findings
- Output: Voice response with personality + visual confirmation

**2. Vision-Based Perception**
- Object detection and recognition (YOLO + VLM)
- Scene understanding ("Is the oven on?")
- Spatial awareness and obstacle avoidance

**3. Navigation & SLAM**
- Start with no prior map ("birth" state)
- Build map while exploring
- Remember locations over time
- Navigate to semantic locations ("kitchen", "living room")

**4. Voice Interaction**
- Bidirectional conversation capability
- Accept voice commands
- Speak responses with personality
- Ask clarifying questions when needed

**5. Personality System**
- Configurable personas (Tachikoma, TARS, etc.)
- Runtime-adjustable personality parameters (TARS-style: humor, honesty, etc.)
- Persona influences interaction style and clarification behavior

---

## Current System State

### ✅ What's Working (Validated on Hardware)

- **ROS2 Humble** + DIMOS + Mission Agent (~2,100 LOC)
- **SLAM + Nav2** tested on Unitree Go2
- **Camera feed** streaming to mission agent
- **Web UI** operational (dashboard, controls, camera view)
- **LLM backends**: OpenAI cloud (working) + vLLM Thor (partial)
- **Network architecture**: Laptop dev environment established

### ⚠️ What's Available But Untested

- **DIMOS Perception Stack**:
  - `person_tracker.py` - YOLO-based person detection/tracking
  - `object_tracker.py` - Object detection with distance estimation
  - `object_detection_stream.py` - YOLO detection stream
  - `visual_servoing.py` - Visual servoing navigation
  - `spatial_perception.py` - Spatial memory system
  - `semantic_seg.py` - SAM2D segmentation

- **VLM Integration Branch** (`feature/vlm-integration`):
  - Qwen VLM integration complete
  - Vision skills package implemented
  - Documentation written
  - Status: Not merged, never tested on hardware

### ❌ Known Gaps

- **Voice Interface**: TTS/STT not implemented
- **Semantic Mapping**: No room-level understanding ("kitchen" vs "living room")
- **Map Persistence**: No save/load/localize system
- **Personality System**: Not implemented
- **WebRTC API Skills**: Majority broken (documented constraint)
- **Thor GPU**: Performance degraded (37→5 tok/s documented)
- **Compute Budget**: Unknown if Thor sufficient for full stack

---

## Architecture Overview

### Four-Layer Stack

```
┌─────────────────────────────────────────────────────────┐
│ APPLICATION LAYER                                        │
│ • Launch files, configs, deployment                      │
│ • Mission definition and orchestration                   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ AGENT LAYER (Mission Intelligence)                       │
│ • LLM/VLM reasoning (OpenAI or vLLM)                    │
│ • Mission planning and adaptation                        │
│ • Personality system                                     │
│ • Voice interaction (TTS/STT)                           │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ SKILLS LAYER (DIMOS Execution Engine)                   │
│ • ~30 behaviors in MyUnitreeSkills                      │
│ • Perception pipeline (YOLO, VLM, tracking)            │
│ • Navigation skills (goto, rotate, explore)             │
│ • Semantic memory and spatial awareness                  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ ROBOT LAYER (Hardware Interface)                         │
│ • ROS2 bridge to go2_ros2_sdk                           │
│ • Sensor data (camera, IMU, odometry)                   │
│ • Motor control and safety                              │
└─────────────────────────────────────────────────────────┘
```

### Development Phases

**Phase 1: Development Environment (Laptop)**
- Laptop runs: Go2 SDK, DIMOS, ShadowHound mission agent
- Laptop I/O: Speaker + microphone for voice
- Compute: LLM/VLM on cloud OR Thor (flexible)
- Robot: Unitree Go2 on local network
- Goal: Rapid iteration, easy debugging

**Phase 2: Deployment Environment (Onboard)**
- Thor runs: Everything (ROS2, DIMOS, agent, LLM/VLM)
- Onboard I/O: Dedicated speaker + 4-mic array
- Robot: Fully autonomous Go2
- Goal: No external dependencies, all onboard processing

---

## Capability Areas (Detailed Requirements)

### 1. Vision & Perception 👁️

**Current State**:
- Camera feed: `/camera/image_raw` (BEST_EFFORT QoS) ✅
- DIMOS perception: Available but untested ⚠️
- VLM branch: Qwen integration ready but not merged ⚠️

**MVP Requirements**:
- Detect and identify household objects (balls, appliances, furniture)
- Answer visual questions ("Is the oven on?", "What color is the ball?")
- Track objects in 3D space for navigation
- Scene understanding for semantic mapping

**Experimental Approaches** (Will Test):
- **Option A**: DIMOS perception stack (YOLO + tracking)
- **Option B**: VLM branch (Qwen for scene understanding)
- **Option C**: Hybrid (YOLO for detection, VLM for reasoning)

**Deliverables**:
- [ ] Test DIMOS perception modules on real missions
- [ ] Evaluate VLM branch performance (merge or iterate)
- [ ] Choose vision stack based on Thor compute budget
- [ ] Implement object detection skill for mission agent
- [ ] Implement visual question answering skill

### 2. Voice Interface 🎤🔊

**Current State**:
- Voice I/O: Not implemented ❌
- Text commands: Working via web UI and ROS topics ✅

**MVP Requirements**:
- **Input**: Accept voice commands from user
- **Output**: Speak responses with personality
- **Bidirectional**: Support back-and-forth conversation
- **Clarification**: Ask questions when mission is ambiguous

**Development Hardware**:
- Laptop speaker + microphone (easy testing)

**Deployment Hardware**:
- Onboard speaker (robot-mounted)
- 4-microphone array (robot-mounted)

**Implementation Strategy**:
1. **TTS (Text-to-Speech)**:
   - First: Explore DIMOS/Go2 SDK built-in TTS features
   - Fallback: Integrate dedicated TTS library (piper, coqui, cloud API)
   - Requirement: Must support personality/emotion parameters

2. **STT (Speech-to-Text)**:
   - Strong candidate: OpenAI Whisper (proven, multilingual)
   - Must run efficiently on Thor or have cloud fallback
   - Requirement: Handle household noise/environment

**Deliverables**:
- [ ] Survey DIMOS/Go2 SDK for built-in TTS/STT
- [ ] Implement TTS with personality parameters
- [ ] Implement STT with wake word detection
- [ ] Integrate voice pipeline into mission agent
- [ ] Test with laptop speaker/mic
- [ ] Validate onboard hardware (speaker + 4-mic array)

### 3. Navigation & SLAM 🗺️

**Current State**:
- SLAM + Nav2: Tested and working on Go2 ✅
- Semantic mapping: Not implemented ❌
- Map persistence: Not implemented ❌

**MVP Requirements**:
- Start with no map ("birth" state)
- Explore and build map dynamically
- Navigate to semantic locations ("go to kitchen")
- Remember locations over time
- Save/load maps for relocalization

**Strategy: "Birth → Learn → Remember"**

1. **Birth State**: Robot starts with no prior knowledge
2. **Learning**: Explores environment, builds spatial map
3. **Remembering**: Persists map, adds semantic labels
4. **Relocalization**: Wakes up, recognizes known spaces

**Experimental Approaches** (Will Test):

**A. Semantic Mapping**:
- **Manual Labeling**: User designates rooms via web UI
- **VLM Auto-Detection**: Robot identifies rooms visually
- **Hybrid**: Manual hints + VLM confirmation

**B. Map Persistence**:
- **SLAM Toolbox**: Save/load/localize with ROS map files
- **Visual Spatial Memory**: Vector DB of visual features
- **Hybrid**: Metric map (SLAM) + semantic layer (vector DB)

**Deliverables**:
- [ ] Implement semantic location tagging (manual first)
- [ ] Test SLAM Toolbox save/load functionality
- [ ] Explore DIMOS spatial memory system
- [ ] Experiment with VLM room detection
- [ ] Choose persistence strategy based on results
- [ ] Implement "go to [room]" navigation skill

### 4. Compute Budget & Performance ⚡

**Current State**:
- Thor AGX: Available, performance unknown for full stack ⚠️
- GPU degradation: Documented (37→5 tok/s) ⚠️
- Full stack: Never profiled together ❌

**MVP Requirements**:
- Run concurrently on Thor:
  - vLLM inference (mission planning)
  - VLM inference (visual reasoning) OR YOLO (object detection)
  - ROS2 nodes (Nav2, SLAM, perception)
  - TTS/STT processing
- Target: < 5s end-to-end mission response time
- Acceptable: Graceful degradation if compute insufficient

**Unknown (High Priority Investigation)**:
- Can Thor run full stack simultaneously?
- What's the bottleneck? (GPU, CPU, memory, I/O)
- Which models are viable? (Llama 3.1 70B? Qwen VLM? Smaller models?)
- Framework choice: vLLM vs llama.cpp vs other

**Fallback Options** (If Thor Insufficient):
1. **Cloud Compute**: LLM/VLM inference in cloud, everything else onboard
2. **Local GPU Workstation**: Inference on powerful desktop, robot executes
3. **Orin Nano Super**: Add compute module to robot (complexity: networking, power, mounting)

**Deliverables**:
- [ ] Profile Thor with mission agent + vLLM + Nav2 + SLAM
- [ ] Measure end-to-end mission latency
- [ ] Identify bottlenecks (GPU, CPU, memory)
- [ ] Test model selection (70B, 8B, 3B variants)
- [ ] Compare vLLM vs llama.cpp performance
- [ ] Document compute budget and constraints
- [ ] Choose deployment architecture based on results

### 5. Personality System 🎭

**Current State**:
- Personality: Not implemented ❌
- Mission responses: Functional but robotic ⚠️

**MVP Requirements**:
- Configurable personas (Tachikoma, TARS, custom)
- Runtime-adjustable personality parameters (TARS-style)
- Persona influences voice response style
- Persona affects clarification behavior

**Persona Examples**:

**Tachikoma (Ghost in the Shell)**:
- Curious, enthusiastic, childlike
- Frequent questions and commentary
- High verbosity, explores proactively
- Parameters: `curiosity=0.9, enthusiasm=0.8, verbosity=0.7`

**TARS (Interstellar)**:
- Direct, efficient, configurable
- Adjustable humor and honesty settings
- Minimal unnecessary speech
- Parameters: `humor=0.6, honesty=0.9, verbosity=0.3`

**Implementation Strategy**:
1. **MVP Scope**: Fixed personality per persona (select at startup)
2. **Stretch Goal**: Evolving personality based on experiences (backlog)
3. **Initial Focus**: Personality affects voice responses only
4. **Future Expansion**: Personality influences decision-making (cautious vs exploratory)

**Personality Parameters** (TARS-Inspired):
- `humor` (0.0-1.0): Frequency of jokes/wit in responses
- `honesty` (0.0-1.0): Directness vs diplomatic responses
- `curiosity` (0.0-1.0): Proactive exploration vs wait for commands
- `verbosity` (0.0-1.0): Talkative vs concise
- `caution` (0.0-1.0): Risk-averse vs bold decisions

**Deliverables**:
- [ ] Design persona configuration schema (YAML/JSON)
- [ ] Implement persona selection system
- [ ] Create Tachikoma persona profile
- [ ] Create TARS persona profile
- [ ] Integrate personality into LLM system prompts
- [ ] Test personality parameters with voice output
- [ ] (Stretch) Implement personality-influenced decision making

---

## Development Milestones

### Milestone 1: Vision Foundation (2-3 weeks)
**Goal**: Robot can detect objects and answer visual questions

- [ ] Test DIMOS perception modules (person tracker, object tracker)
- [ ] Evaluate VLM branch on test missions
- [ ] Choose vision stack (DIMOS vs VLM vs hybrid)
- [ ] Implement object detection skill integrated with mission agent
- [ ] Test on real household objects (balls, appliances, furniture)
- [ ] **Success Metric**: "Find the red ball" mission succeeds with 80% accuracy

### Milestone 2: Voice Interaction (2-3 weeks)
**Goal**: Robot accepts voice commands and responds with personality

- [ ] Survey DIMOS/Go2 SDK TTS/STT capabilities
- [ ] Implement TTS with personality parameters
- [ ] Implement STT with wake word
- [ ] Integrate voice pipeline into mission agent
- [ ] Test with laptop hardware (speaker + mic)
- [ ] Implement basic Tachikoma persona
- [ ] **Success Metric**: Complete voice mission: "Go find the ball" → spoken response

### Milestone 3: Semantic Navigation (2-3 weeks)
**Goal**: Robot understands room names and navigates to semantic locations

- [ ] Implement manual room labeling via web UI
- [ ] Test SLAM Toolbox map save/load
- [ ] Implement "go to [room]" navigation skill
- [ ] Test semantic navigation on multi-room environment
- [ ] Experiment with VLM room detection (if compute allows)
- [ ] **Success Metric**: "Go to the kitchen" mission succeeds reliably

### Milestone 4: Compute Optimization (2-3 weeks)
**Goal**: Full stack runs efficiently on Thor or fallback identified

- [ ] Profile Thor with all systems running
- [ ] Measure end-to-end latency for typical missions
- [ ] Identify bottlenecks and optimize
- [ ] Test model alternatives (70B vs 8B vs 3B)
- [ ] Compare vLLM vs llama.cpp
- [ ] Document compute budget and deployment architecture
- [ ] **Success Metric**: < 5s end-to-end response time OR fallback plan validated

### Milestone 5: Integration & Validation (1-2 weeks)
**Goal**: All capabilities work together for end-to-end missions

- [ ] Integrate vision + voice + navigation + personality
- [ ] Test complete mission flows:
  - "Find the red ball in the living room"
  - "Check if the oven is on in the kitchen"
  - "Go to the bedroom and tell me what you see"
- [ ] Validate map persistence (shutdown + relocalize)
- [ ] Test onboard hardware (speaker + 4-mic array)
- [ ] Document known limitations and future work
- [ ] **Success Metric**: 3 complex missions succeed end-to-end

---

## Technical Risks & Mitigation

### High Priority Risks

**Risk 1: Thor Compute Insufficient**
- **Impact**: Cannot run full stack onboard
- **Likelihood**: Medium (GPU degradation documented)
- **Mitigation**: 
  - Early profiling (Milestone 4)
  - Model size experimentation
  - Fallback: Cloud compute or local workstation
  - Last resort: Add Orin Nano Super

**Risk 2: VLM Accuracy Too Low**
- **Impact**: Cannot answer visual questions reliably
- **Likelihood**: Medium (untested on real household scenes)
- **Mitigation**:
  - Test early (Milestone 1)
  - Fallback to YOLO + rule-based reasoning
  - Hybrid approach: YOLO for detection, simple classifiers for states

**Risk 3: Voice Recognition in Noisy Environment**
- **Impact**: Cannot reliably accept voice commands
- **Likelihood**: Medium (household noise, robot motor noise)
- **Mitigation**:
  - 4-mic array for beamforming
  - Whisper known to be robust
  - Fallback: Wake word + confirmation ("Did you say 'find the ball'?")

**Risk 4: Map Persistence Complexity**
- **Impact**: Robot "forgets" layout, relearns every boot
- **Likelihood**: Low (SLAM Toolbox proven)
- **Mitigation**:
  - Use established SLAM Toolbox save/load
  - Test early in development
  - Visual relocalization as backup

### Medium Priority Risks

**Risk 5: WebRTC API Limitations**
- **Impact**: Cannot use majority of DIMOS skills
- **Likelihood**: High (already documented)
- **Mitigation**:
  - Work around with CycloneDDS low-level control
  - Focus on nav/perception skills (less affected)
  - Document which skills are unavailable

**Risk 6: Personality System Complexity**
- **Impact**: Hard to tune, doesn't feel natural
- **Likelihood**: Medium (subjective UX challenge)
- **Mitigation**:
  - Start simple (fixed personas)
  - Iterate based on user testing
  - Parameter tuning UI for experimentation

---

## Success Metrics

### Functional Metrics
- [ ] Object detection accuracy > 80% (household objects)
- [ ] Voice command recognition accuracy > 90% (quiet environment)
- [ ] Navigation success rate > 95% (known map)
- [ ] End-to-end mission completion < 5s response time
- [ ] Map relocalization success > 90% (after reboot)

### User Experience Metrics
- [ ] Voice interaction feels natural (subjective)
- [ ] Personality is distinguishable between personas
- [ ] Clarifying questions are appropriate and helpful
- [ ] Robot can complete 3 complex missions end-to-end

### Technical Metrics
- [ ] System runs stable for > 1 hour continuous operation
- [ ] No crashes or hangs during normal missions
- [ ] Compute budget documented with utilization < 90%
- [ ] All core systems (vision, voice, nav, LLM) running concurrently

---

## Future Work (Post-MVP)

### Immediate Enhancements
- **Evolving Personality**: Learn from interactions, adapt over time
- **Personality Decision Influence**: Cautious vs exploratory behavior
- **Multi-Room Semantic Mapping**: Full house spatial understanding
- **Object Manipulation**: Pick up and move objects (requires gripper)
- **Advanced Vision**: Fine-grained object properties (texture, material)

### Longer-Term Ideas
- **Multi-Robot Coordination**: Tachikoma collective memory sharing
- **Continuous Learning**: Update object models from experiences
- **Natural Dialogue**: Multi-turn conversations with context
- **Emotional Intelligence**: React to user tone and sentiment
- **Proactive Assistance**: Suggest tasks, anticipate needs

### Stretch Goals (If Compute Allows)
- **Real-Time VLM Streaming**: Continuous scene understanding
- **Dynamic Replanning**: Adapt to unexpected obstacles/changes
- **Advanced Personality**: Emotional state machine, context-aware responses

---

## Open Questions & Decisions Needed

### Critical Decisions (Block Progress)
- [ ] **Vision Stack**: DIMOS perception vs VLM vs hybrid? (Milestone 1)
- [ ] **Compute Architecture**: Onboard vs cloud vs hybrid? (Milestone 4)
- [ ] **Map Persistence**: SLAM Toolbox vs visual memory vs hybrid? (Milestone 3)

### Important Decisions (Can Iterate)
- [ ] **TTS/STT Libraries**: Which specific implementations? (Milestone 2)
- [ ] **Initial Persona**: Tachikoma or TARS first? (Milestone 2)
- [ ] **LLM Model Size**: 70B vs 8B vs 3B? (Milestone 4)

### Nice-to-Decide (Low Priority)
- [ ] **Personality Evolution**: MVP or post-MVP?
- [ ] **Web UI Enhancements**: Persona configuration interface?
- [ ] **Logging/Telemetry**: What metrics to track long-term?

---

## Resources & References

### Documentation
- `docs/architecture/mission_agent_vs_executor.md` - Agent architecture
- `docs/history/project_history_oct_2025.md` - Complete project history
- `docs/development/devlog.md` - Daily development log
- `docs/development/recent_work.md` - Last 5 days summary

### Code Locations
- Mission Agent: `src/shadowhound_mission_agent/`
- DIMOS Integration: `src/dimos-unitree/` (submodule)
- VLM Branch: `feature/vlm-integration` (not merged)
- Launch Files: `src/shadowhound_bringup/launch/`

### External Research
- DIMOS Framework: Documentation in submodule
- Tachikoma Character: Ghost in the Shell (anime/manga)
- TARS Character: Interstellar (film)
- SLAM Toolbox: ROS2 package documentation
- Whisper STT: OpenAI research

---

## Appendix: Mission Examples

### Example Mission 1: Object Search
**Command**: "Find the red ball in the living room"

**Expected Flow**:
1. Voice input → STT → "find red ball living room"
2. Mission agent parses intent: object=red ball, location=living room
3. Navigate to living room (semantic location lookup)
4. Enable vision perception (YOLO or VLM)
5. Search area, detect red ball
6. Navigate closer, confirm detection
7. Report back: "I found the red ball near the couch"
8. TTS speaks response with personality

**Success**: Ball found and confirmed with < 2 minute total time

### Example Mission 2: Appliance Check
**Command**: "Check if the oven is on in the kitchen"

**Expected Flow**:
1. Voice input → STT → "check oven on kitchen"
2. Mission agent parses intent: task=check state, object=oven, location=kitchen
3. Navigate to kitchen
4. Locate oven (visual detection)
5. VLM analysis: "Is this appliance powered on?" (look for indicator lights, displays)
6. Report back: "The oven appears to be off. The display is dark and there are no indicator lights."
7. TTS speaks response with personality

**Success**: Correct state determination with visual reasoning

### Example Mission 3: Exploration & Reporting
**Command**: "Go to the bedroom and tell me what you see"

**Expected Flow**:
1. Voice input → STT → "go bedroom tell what see"
2. Mission agent parses intent: navigate=bedroom, task=observe+report
3. Navigate to bedroom (semantic location)
4. Capture camera frame
5. VLM scene understanding: describe contents
6. Report back: "I'm in the bedroom. I see a bed with blue sheets, a wooden nightstand with a lamp, and a closet with the door partially open. There's a pile of clothes on the floor near the closet."
7. TTS speaks response with personality (Tachikoma might add: "Looks like someone's been busy!")

**Success**: Accurate scene description with natural language

---

**Last Updated**: 2025-10-14  
**Next Review**: After Milestone 1 completion  
**Owner**: ShadowHound development team
