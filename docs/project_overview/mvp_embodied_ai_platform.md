---
tags: [project, mvp, roadmap, planning, transformers, embodied-ai]
status: active
related: [roadmap.md, project_history_oct_2025.md]
summary: >
  MVP definition and roadmap for ShadowHound embodied AI robot platform
---

# ShadowHound MVP: Embodied AI Robot Platform

**Created**: 2025-10-14  
**Status**: Planning  
**Target**: Embodied AI platform exploring transformer architectures in robotics (LLM, VLM, VLA)

---

## Executive Summary

Transform ShadowHound into an embodied AI platform for hands-on exploration of transformer architectures in robotics. The MVP focuses on natural language mission execution with vision-based perception, demonstrating LLM reasoning, VLM scene understanding, and autonomous navigation. Household missions ("find the red ball", "check if oven is on") serve as concrete test scenarios to validate the platform's capabilities, but the architecture is designed for broader applications beyond domestic environments.
---

**Project Goal**: Hands-on experience with transformer architectures in robotics, not limited to household assistance.

### Success Criteria

The MVP is complete when the robot can:

1. ✅ Accept voice commands OR console/web commands
2. ✅ Execute vision-based missions (find objects, check appliance states)
3. ✅ Navigate safely in dynamic environments (with/without prior map)
4. ✅ Respond with voice output expressing personality
5. ✅ Process all computation onboard Thor AGX (no cloud dependency for deployment)
6. ✅ Learn and remember spatial information over time

### Project Goals

**Primary Goal**: Hands-on experience with transformer architectures in robotics
- LLM (Large Language Models): Mission planning, reasoning, natural language understanding
- VLM (Vision-Language Models): Scene understanding, visual question answering
- VLA (Vision-Language-Action): Direct visuomotor control (future/stretch)

**Secondary Goal**: Demonstrate embodied AI capabilities through concrete test scenarios
- Household missions provide measurable success criteria
- Platform architecture supports diverse applications beyond domestic use
- Foundation for research and experimentation in robotics AI

**Note**: Household scenarios are initial test cases, not the sole application domain.

---

## MVP Definition

### Core Capabilities

**1. Natural Language Mission Execution**
- Input: "Find the red ball in the living room"
- System: Parse intent → Plan actions → Execute → Report findings
- Output: Voice response with personality + visual confirmation
- **Broader Use**: Any natural language task specification

**2. Vision-Based Perception (VLM)**
- Object detection and recognition (YOLO + VLM)
- Scene understanding ("Is the oven on?")
- Spatial awareness and obstacle avoidance
- **Broader Use**: Visual reasoning for any environment

**3. Navigation & SLAM**
- Start with no prior map ("birth" state)
- Build map while exploring
- Remember locations over time
- Navigate to semantic locations ("kitchen", "living room")
- **Broader Use**: Generalizable spatial learning for any space

**4. Voice Interaction**
- Bidirectional conversation capability
- Accept voice commands
- Speak responses with personality
- Ask clarifying questions when needed
- **Broader Use**: Natural human-robot interaction

**5. Personality System**
- Configurable personas (Tachikoma, TARS, etc.)
- TARS persona: Runtime-adjustable personality parameters (like the movie)
- Other personas: Fixed personality traits
- Persona influences interaction style and clarification behavior
- **Broader Use**: Configurable interaction styles for different contexts

---

## Current System State

### ✅ What's Working (Validated on Hardware)

- **ROS2 Humble** + DIMOS + Mission Agent (~2,100 LOC)
- **SLAM + Nav2** tested on Unitree Go2
- **Camera feed** streaming to mission agent
- **LiDAR** operational (depth/occupancy data for Nav2 costmaps)
- **Web UI** operational (dashboard, controls, camera view)
- **LLM backends**: OpenAI cloud (working) + vLLM Thor (partial)
- **Network architecture**: Laptop dev environment established

### 🔧 Hardware Configuration

**Current Sensors (MVP)**:
- **Camera**: Front-facing (Go2 built-in) - RGB for VLM/object detection
- **LiDAR**: 2D planar LiDAR (Go2 built-in) - Depth/occupancy for Nav2 costmaps
- **IMU**: Inertial measurement unit (Go2 built-in) - Orientation, motion
- **Joint States**: Leg joint encoders (Go2 built-in) - Available via SDK
- **Odometry**: Published by Go2 SDK - Position estimation for navigation

**Potential Sensor Upgrades (Future/Optional)**:
- **RealSense Depth Camera**: RGB-D for better 3D understanding (not essential for MVP)
- **360° Camera** (Insta360 X4 or DreamVU): Omnidirectional vision (not essential for MVP)
- **4-Mic Array**: Voice interaction (deployment hardware, not dev)
- **Speaker**: TTS output (deployment hardware, not dev)

**Note**: LiDAR is essential for MVP navigation (costmap generation). RGB-D and 360° cameras are potential enhancements for future work but not required for initial missions.

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
- **WebRTC API Skills**: **MAJOR BLOCKER** - Majority of DIMOS MyUnitreeSkills use WebRTC API directly and are non-functional. Working with limited set of non-WebRTC skills. This significantly limits available robot behaviors until resolved or Nav2-based custom skills implemented.
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
│ • LLM reasoning (mission planning, language)            │
│ • VLM reasoning (visual understanding)                  │
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
│ • Sensor data (camera, IMU, LiDAR, joint states, odom) │
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
- LiDAR: 2D planar LiDAR operational (depth/occupancy only, no semantic data) ✅
- DIMOS perception: Available but untested ⚠️
- VLM branch: Qwen integration ready but not merged ⚠️

**MVP Requirements**:
- Detect and identify household objects (balls, appliances, furniture)
- Answer visual questions ("Is the oven on?", "What color is the ball?")
- Track objects in 3D space for navigation
- Scene understanding for semantic mapping

**Sensor Capabilities**:
- **Camera (RGB)**: Primary sensor for VLM/object detection, semantic understanding
- **LiDAR**: Depth/occupancy data for Nav2 costmaps and obstacle avoidance (essential for MVP)
- **Note**: LiDAR provides geometric data but no color/semantic information - vision handles object recognition

**Experimental Approaches** (Will Test):
- **Option A**: DIMOS perception stack (YOLO + tracking)
- **Option B**: VLM branch (Qwen for scene understanding)
- **Option C**: Hybrid (YOLO for detection, VLM for reasoning)

**Future Sensor Upgrades** (Optional):
- RealSense depth camera: RGB-D for better 3D understanding
- 360° camera (Insta360 X4/DreamVU): Omnidirectional vision

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

### 4. Navigation & SLAM 🗺️

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

### 5. Compute Budget & Performance ⚡

**Current State**:
- Thor AGX: Available, performance unknown for full stack ⚠️
- GPU degradation: Documented (37→5 tok/s) ⚠️
- Full stack: Never profiled together ❌

**MVP Requirements**:
- Run concurrently on Thor:
  - LLM inference (mission planning, language understanding)
  - VLM inference (visual reasoning, scene understanding)
  - VLA inference (complex terrain locomotion) - when triggered
  - ROS2 nodes (Nav2, SLAM, perception)
  - TTS/STT processing
- Target: < 5s end-to-end mission response time
- Acceptable: Graceful degradation if compute insufficient

**Unknown (High Priority Investigation)**:
- Can Thor run full stack simultaneously (LLM + VLM + VLA + ROS2)?
- What's the bottleneck? (GPU, CPU, memory, I/O)
- Which models are viable? (Llama 3.1 70B? Qwen VLM? Which VLA?)
- Framework choice: vLLM vs llama.cpp vs other
- Can we time-multiplex models? (VLA only when needed)

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

### 6. Personality System 🎭

**Current State**:
- Personality: Not implemented ❌
- Mission responses: Functional but robotic ⚠️

**MVP Requirements**:
- Multiple configurable personas (Tachikoma, TARS, custom)
- **TARS Persona Only**: Runtime-adjustable personality parameters (like in the movie)
- **Other Personas**: Fixed personality characteristics (no user adjustment)
- Persona influences voice response style and clarification behavior

**Persona Examples**:

**Tachikoma (Ghost in the Shell)**:
- Curious, enthusiastic, childlike AI
- Frequent questions and commentary
- High verbosity, explores proactively
- **Fixed Personality**: User cannot adjust, always behaves consistently

**TARS (Interstellar)**:
- Direct, efficient, mission-focused
- **User-Adjustable Parameters**: Humor, honesty, verbosity (0-100%)
- Minimal unnecessary speech (unless humor turned up)
- User commands: "Set humor to 60%", "Set honesty to 90%"

**Implementation Strategy**:

1. **MVP Scope**: 
   - Fixed personality per persona (Tachikoma, custom personas)
   - TARS with adjustable parameters (special case)
   - Select persona at startup or via voice command

2. **Stretch Goal**: 
   - Evolving personality based on experiences (backlog)
   
3. **Initial Focus**: 
   - Personality affects voice responses only
   
4. **Future Expansion**: 
   - Personality influences decision-making (cautious vs exploratory)

**TARS Personality Parameters**:

User-facing (0-100% scale):
- `humor` (0-100%): Frequency of jokes/wit in responses
- `honesty` (0-100%): Directness vs diplomatic responses  
- `verbosity` (0-100%): Talkative vs concise

**Implementation Note**: 
User interface uses 0-100% scale ("Set humor to 60%"), but the actual LLM prompt engineering strategy to achieve these behaviors remains to be determined. May involve:
- System prompt modifications
- Temperature/sampling adjustments
- Few-shot examples in context
- Fine-tuning (if needed)

**Other Personas**:
- Defined by static system prompts
- No runtime adjustment by user
- Consistent behavior across sessions

**Deliverables**:
- [ ] Design persona configuration schema (YAML/JSON)
- [ ] Implement persona selection system
- [ ] Create Tachikoma persona profile (fixed personality)
- [ ] Create TARS persona profile (adjustable parameters)
- [ ] Implement TARS parameter adjustment ("Set humor to 60%")
- [ ] Research LLM prompt engineering strategies for personality control
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
- [ ] Define minimal skill set needed for MVP missions (see [Skills Inventory](../software/skills_inventory.md))
- [ ] Audit DIMOS MyUnitreeSkills to identify working vs WebRTC-blocked skills
- [ ] Decide on skill implementation approach (DIMOS native vs custom wrapper)
- [ ] **Success Metric**: "Find the red ball" mission succeeds with 80% accuracy

#### Testing Infrastructure Setup
- [ ] Configure pytest with fixtures and test utilities
- [ ] Implement mock robot interface for unit testing
- [ ] Set up CI pipeline (GitHub Actions):
  - [ ] Run tests on every PR
  - [ ] Code quality checks (black, flake8, mypy)
  - [ ] Test coverage reporting (target: >80%)
- [ ] Document testing patterns and best practices

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

- [ ] Profile Thor with all systems running (LLM + VLM + Nav2 + SLAM + TTS/STT)
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
- [ ] Test TARS personality parameter adjustment
- [ ] Document known limitations and future work
- [ ] **Success Metrics**:
  - 3 complex missions succeed end-to-end
  - >90% mission success rate in controlled environment (20 test runs)
  - <5s average response time for multi-step commands
  - No safety incidents during validation testing

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

### Vision-Language-Action (VLA) for Complex Terrain 🦾

**Priority**: LOW - Tackle last after MVP complete and stable

**Why VLA is Post-MVP**:
- **High Complexity**: Requires simulation environment, fine-tuning, extensive testing
- **Safety Risk**: Direct motor control on physical robot requires careful validation
- **Research Scope**: Cutting-edge area, significant learning curve
- **Infrastructure Needed**: Sim2real pipeline, data collection, model training
- **Design Work**: Integration strategy with existing DIMOS skills

**Vision** (When Ready):
Enable direct visuomotor control for complex terrain navigation where standard motion skills fail.

**Use Cases**:
- **Stairs**: Climbing/descending stairs safely
- **Cluttered Environments**: Navigate through tight spaces with obstacles
- **Uneven Terrain**: Adapt gait to terrain features in real-time
- **Complex Manipulation**: Fine-grained control for object interaction

**Technical Requirements** (To Investigate):
- [ ] ROS2 Go2 SDK joint control interface (DDS mode support?)
- [ ] Simulation environment for VLA training (Gazebo, Isaac Sim, MuJoCo?)
- [ ] VLA model selection (RT-1, RT-2, OpenVLA, Octo, custom?)
- [ ] Data collection strategy (teleoperation, demonstration, sim?)
- [ ] Safety mechanisms (joint limits, collision detection, emergency stop)
- [ ] Integration with mission agent (when to invoke VLA vs normal skills?)

**Experimental Approach** (When Ready):
1. **Phase 1**: Investigate Go2 SDK joint control capabilities (DDS vs direct)
2. **Phase 2**: Set up simulation environment with Go2 model
3. **Phase 3**: Collect training data (sim + real demonstrations)
4. **Phase 4**: Train/fine-tune VLA model
5. **Phase 5**: Sim validation with safety checks
6. **Phase 6**: Careful real-robot validation (gradual rollout)

**Deliverables** (Future Work):
- [ ] Survey Go2 SDK for low-level joint control
- [ ] Research VLA architectures suitable for quadruped
- [ ] Design VLA integration architecture
- [ ] Set up simulation environment
- [ ] Implement data collection pipeline
- [ ] Train initial VLA model
- [ ] Validate in simulation
- [ ] Real-robot validation with extensive safety testing

---

### Immediate Enhancements (After MVP)

**Evolving Personality System** 🌱
- **Vision**: Personality adapts based on mission history, user interactions, and experiences
- **Example Behaviors**:
  - Tachikoma becomes more confident in familiar spaces
  - TARS adjusts humor based on successful joke reception
  - Robot remembers user preferences ("You usually ask me to be quiet in the morning")
  - Personality "grows" from naive (birth) to experienced over robot's lifetime
- **Implementation Approaches**:
  - Experience database: Track missions, outcomes, user feedback
  - Persona evolution rules: How traits shift based on experiences
  - Long-term memory integration: Recall past interactions
  - Fine-tuning: Periodically update LLM based on interaction logs (if compute allows)
- **Design Questions**:
  - Should evolution be per-persona or cross-persona learning?
  - How fast should personality evolve? (gradual vs rapid adaptation)
  - Can user reset personality to "factory defaults"?
  - Should evolution be observable/transparent to user?

**Sensor Upgrades for Enhanced Perception** 📷
- **RealSense Depth Camera**: RGB-D for improved 3D scene understanding
  - Better object detection in cluttered spaces
  - Precise distance estimation for manipulation tasks
  - Improved VLM input with depth information
- **360° Camera** (Insta360 X4 or DreamVU): Omnidirectional vision
  - Spatial awareness without rotation
  - Better semantic mapping (see entire room at once)
  - Safety: Detect approaching people/obstacles from any direction
  - Use case: "Look around and tell me what's in this room"

**Other Enhancements**:
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

## Action Items & TODOs

### Research & Investigation
- [ ] Review DIMOS skill extension patterns and decide implementation approach
- [ ] Determine appropriate task types for cloud agent collaboration (based on experience)
- [ ] Document cloud agent collaboration strategy when patterns are validated

### Documentation
- [ ] Complete skills inventory audit (working vs non-working DIMOS skills)
- [ ] Create testing infrastructure documentation when setup complete
- [ ] Produce video walkthrough covering architecture, mission authoring, and debugging

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
