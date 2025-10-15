---
tags: [mvp, persistent-intelligence, local-planning, roadmap, learning]
status: draft
related:
  - ../project_overview/mvp_embodied_ai_platform.md
  - local_planning_architecture.md
  - hybrid_perception_architecture.md
  - persistent_intelligence_dimos_integration.md
summary: >
  Persistent Intelligence MVP proposal that builds on original ShadowHound MVP. Proposes local planning
  first approach for faster development, then adds learning capabilities on top of working system.
---

# Persistent Intelligence MVP

**Created**: 2025-10-14  
**Status**: Proposal  
**Foundation**: Builds on [ShadowHound MVP: Embodied AI Platform](../project_overview/mvp_embodied_ai_platform.md)

---

## Executive Summary

This document proposes enhancements to the **original ShadowHound MVP** that enable **persistent intelligence** — a robot that learns from experience and improves over time. Rather than replacing the original MVP, this proposal identifies **early wins** that accelerate development while establishing the foundation for continuous learning.

**Key Insight**: Recent discovery of DIMOS's local planning capabilities enables a **local-first navigation strategy** that delivers autonomous navigation in ~1 week (vs 2-3 weeks with global planning), while still supporting global planning when needed.

**Strategy**:
1. **Phase 1**: Implement original MVP with local planning first (faster path)
2. **Phase 2**: Add trajectory logging and learning infrastructure
3. **Phase 3**: Integrate persistent intelligence (multi-brain, day/night learning)

---

## Proposed Changes to Original MVP

### Reference: Original MVP Goals

From [mvp_embodied_ai_platform.md](../project_overview/mvp_embodied_ai_platform.md), the original MVP aims to:

1. ✅ Accept voice/console/web commands
2. ✅ Execute vision-based missions
3. ✅ Navigate safely in dynamic environments
4. ✅ Respond with voice output and personality
5. ✅ Process onboard Thor AGX (no cloud)
6. ✅ Learn and remember spatial information

**Core Approach**: SLAM + Nav2 for navigation, VLM for perception

---

### Proposed Enhancement: Local Planning First

**Discovery**: DIMOS includes a complete **VFH (Vector Field Histogram) + Pure Pursuit local planner** that enables autonomous navigation **without requiring global maps or SLAM localization**.

#### Why This Matters

**Original MVP Approach**:
```
Week 1-2: Map environment with SLAM
Week 2-3: Test Nav2 global planning
Week 3-4: Add camera perception
Week 4: End-to-end mission

Risk: High (SLAM + Nav2 untested, complex stack)
Timeline: 3-4 weeks
```

**Enhanced MVP Approach** (Local Planning First):
```
Week 1: Test local planner + Add YOLO perception
Week 1: Working end-to-end mission "Find the ball"

Then (optional): Add SLAM + Nav2 for multi-room
Timeline: 1 week for basic, 2-3 weeks for full
```

#### Benefits of Local-First Approach

| Aspect | Local Planning First | SLAM + Nav2 First |
|--------|---------------------|-------------------|
| **Development Speed** | ✅ 1 week to working mission | ⚠️ 2-3 weeks |
| **Risk** | ✅ Low (simpler stack) | ⚠️ High (untested, complex) |
| **Testing** | ✅ Easy (no mapping phase) | ⚠️ Requires mapping first |
| **Robustness** | ✅ Reactive (always works) | ⚠️ Can lose localization |
| **Use Cases** | ✅ Object search missions | ✅ Multi-room navigation |
| **Learning Data** | ✅ Rich reactive decisions | ⚠️ Sparse waypoints |

#### Hybrid Navigation Strategy (Recommended)

**Proposal**: Support BOTH local and global planning, use whichever is appropriate:

```python
class NavigationStrategy:
    """Choose navigation approach based on mission requirements."""
    
    def plan_navigation(self, mission):
        # Check if global map available and needed
        if mission.requires_multi_room() and self.has_valid_map():
            return self.global_planner.plan(mission.goal)
        
        # Check if goal is visible (camera perception)
        if mission.goal_visible():
            return self.local_planner.plan(mission.goal)
        
        # Fallback: Explore until goal visible
        return self.exploration_planner.plan()
```

**When to use local planning**:
- ✅ Object search ("Find the red ball")
- ✅ Person following
- ✅ Visual navigation ("Go to the chair")
- ✅ Exploration

**When to use global planning**:
- ✅ Multi-room navigation ("Go to the kitchen")
- ✅ Return to specific locations ("Go back to where you saw the ball")
- ✅ Optimal path planning
- ✅ Return to dock/charging station

**Key Point**: Local planning enables fast MVP delivery WITHOUT blocking future global planning integration.

---

### Navigation Success Criteria (Revised)

**Original MVP Success Criterion #3**:
> "Navigate safely in dynamic environments (with/without prior map)"

**Enhanced Success Criteria** (more specific):

**Tier 1: Local Planning** (Week 1 - MVP Minimum):
- ✅ Navigate to visible objects detected by camera
- ✅ Avoid obstacles using LiDAR (VFH collision avoidance)
- ✅ Handle dynamic obstacles (people walking by)
- ✅ Execute recovery behaviors when stuck
- ✅ Success rate > 90% for object search missions

**Tier 2: Global Planning** (Week 2-3 - Enhanced):
- ✅ Build map while exploring (SLAM)
- ✅ Localize in known environments
- ✅ Navigate to semantic locations ("kitchen")
- ✅ Remember and return to specific locations
- ✅ Plan optimal paths avoiding obstacles

**Tier 3: Hybrid** (Week 3-4 - Complete):
- ✅ Switch between local and global planning automatically
- ✅ Use global planning for efficiency when map available
- ✅ Fallback to local planning if localization fails
- ✅ Explore unknown areas while maintaining global awareness

**Deliverable Sequence**:
1. Week 1: Tier 1 working → **Ship MVP v1**
2. Week 2-3: Add Tier 2 → **Ship MVP v2** 
3. Week 3-4: Add Tier 3 → **Ship MVP v3**

This enables early validation and iterative delivery.

---

### Perception Success Criteria (Clarified)

**Original MVP Success Criterion #2**:
> "Execute vision-based missions (find objects, check appliance states)"

**Enhanced Success Criteria** (implementation details):

**Tier 1: YOLO Object Detection** (Week 1 - MVP Minimum):
- ✅ Detect common objects (COCO dataset classes)
- ✅ Estimate 3D position from depth
- ✅ Transform detections to navigation frame (odom)
- ✅ Real-time tracking at 10 FPS
- ✅ Navigate to detected objects

**Tier 2: VLM Semantic Verification** (Week 2 - Enhanced):
- ✅ Verify object properties ("Is this ball RED?")
- ✅ Answer visual questions ("Is the oven on?")
- ✅ Scene understanding ("What room is this?")
- ✅ Hybrid YOLO+VLM pipeline (YOLO fast → VLM verify)
- ✅ Sample VLM at 0.2-1 Hz (balance latency vs accuracy)

**Tier 3: Spatial Memory** (Week 3-4 - Complete):
- ✅ Remember object locations over time
- ✅ Semantic queries ("What did I see in the kitchen?")
- ✅ Update beliefs as environment changes
- ✅ CLIP embeddings for semantic similarity

**Note**: DIMOS already has implementations for all tiers (untested). See:
- Tier 1: `object_detection_stream.py` + `yolo_2d_det.py`
- Tier 2: `qwen/video_query.py` + `get_bbox_from_qwen_frame()`
- Tier 3: `spatial_perception.py` + `SpatialMemory` class

---

## Early Wins Identified

### Win #1: MockRobot for Development Velocity

**Problem**: Hardware testing is slow, risky, and blocks parallel development.

**Solution**: Implement MockRobot (pure Python, no dependencies).

**Benefits**:
- ✅ Unit tests run in milliseconds
- ✅ CI/CD on every commit (GitHub Actions)
- ✅ Multiple developers can work in parallel
- ✅ Test edge cases without hardware risk

**Effort**: 1-2 days

**Priority**: **CRITICAL** - Enables all other work

**Implementation**: See `local_planning_quickstart.md` Phase 0

---

### Win #2: Local Planning Eliminates SLAM Dependency

**Problem**: SLAM + Nav2 untested, high risk, 2-3 week timeline.

**Solution**: VFH local planner (already in DIMOS, just needs testing).

**Benefits**:
- ✅ Working autonomous navigation in 1 week
- ✅ No localization failures (reactive not planned)
- ✅ Simpler to test and debug
- ✅ Sufficient for object search missions
- ✅ Can add global planning later if needed

**Effort**: 2-3 days testing + parameter tuning

**Priority**: **HIGH** - Unblocks perception integration

**Implementation**: See `local_planning_architecture.md`

---

### Win #3: Sequential YOLO+VLM Pipeline

**Problem**: Pure YOLO can't handle nuanced queries ("red ball"). Pure VLM too slow for real-time.

**Solution**: Hybrid pipeline (YOLO finds candidates → VLM verifies).

**Benefits**:
- ✅ Real-time tracking (YOLO at 10 FPS)
- ✅ Semantic reasoning (VLM for verification)
- ✅ Efficient (VLM only on candidates)
- ✅ Handles complex queries ("person in blue shirt")

**Effort**: 1-2 days integration

**Priority**: **MEDIUM** - Enables nuanced missions

**Implementation**: See `hybrid_perception_architecture.md` Pattern 2

---

### Win #4: Trajectory Logging for Learning

**Problem**: No data capture, can't learn from experience.

**Solution**: Log reactive navigation decisions (local planning choices).

**Benefits**:
- ✅ Foundation for persistent intelligence
- ✅ Rich data (VFH decisions, perception, outcomes)
- ✅ Enables offline analysis and adaptation
- ✅ Prepares for multi-brain architecture

**Effort**: 1-2 days (simple JSON logging first)

**Priority**: **MEDIUM** - Enables Phase 2

**Implementation**: See persistent_intelligence_dimos_integration.md Section 3.2

---

### Win #5: Semantic Memory & RAG Already Implemented

**Problem**: Need spatial memory for queries like "What did I see in the kitchen?" and scene similarity matching for transfer learning.

**Discovery**: DIMOS already has complete semantic memory infrastructure!

**What's Already Implemented**:

1. **SpatialMemory** (`dimos/perception/spatial_perception.py`)
   - Stores video frames with XY locations
   - Links images to spatial coordinates
   - Supports named locations ("kitchen", "living room")
   - Persistent storage via ChromaDB

2. **Image Embeddings** (`dimos/agents/memory/image_embedding.py`)
   - CLIP embeddings (512D vectors)
   - ResNet embeddings (alternative)
   - Semantic similarity search
   - Scene understanding capability

3. **Vector Database** (`dimos/agents/memory/spatial_vector_db.py`)
   - ChromaDB integration
   - Spatial queries (find images near XY location)
   - Semantic queries (find similar scenes)
   - Cosine similarity search

4. **Text/Semantic Memory** (`dimos/agents/memory/chroma_impl.py`)
   - OpenAI embeddings (cloud option)
   - Local SentenceTransformers (onboard option)
   - RAG query interface
   - Persistent collections

**How This Enables Persistent Intelligence**:

```python
# Example 1: Remember where objects were seen
spatial_memory.add_observation(
    image=camera_frame,
    location=(x, y, theta),
    label="red_ball",
    embedding=clip_embedding
)

# Later: Query semantic memory
results = spatial_memory.query_by_text("red ball", limit=5)
# Returns: Images of red balls with their XY locations

# Example 2: Find similar scenes for transfer learning
current_scene_embedding = clip_model.encode(current_frame)
similar_trajectories = vector_db.query_by_embedding(
    current_scene_embedding,
    limit=10
)
# Returns: Past trajectories in similar scenes
# Use for: "This looks like that hallway where I got stuck"

# Example 3: Spatial queries
objects_in_kitchen = spatial_memory.query_by_location(
    x=5.0, y=3.0, radius=2.0
)
# Returns: All observations within 2m of kitchen center
```

**Integration Points**:

| Phase | Semantic Memory Use Case | Implementation |
|-------|-------------------------|----------------|
| **Phase 2** | Log scene embeddings with trajectory | Add CLIP encoding to trajectory logger |
| **Phase 3** | VLM queries use spatial memory | "Did I see a red ball?" → Query vector DB |
| **Phase 4** | Semantic locations | "Go to the kitchen" → Named location query |
| **Phase 5** | Transfer learning | Find similar scenes → Retrieve relevant trajectories |
| **Phase 6** | Multi-brain RAG | Spark queries Thor's spatial memory for curation |

**Benefits**:
- ✅ Already implemented and tested (DIMOS has tests)
- ✅ Supports both cloud (OpenAI) and local (SentenceTransformers) embeddings
- ✅ Persistent storage (survives robot restarts)
- ✅ Efficient similarity search (ChromaDB HNSW index)
- ✅ Spatial + semantic queries (location AND scene similarity)
- ✅ Enables episodic memory ("When did I see X?")
- ✅ Scene similarity for transfer learning
- ✅ RAG for LLM context ("Show me images of the living room")

**Effort**: 1-2 days integration (infrastructure already exists!)

**Priority**: **HIGH** - Critical for persistent intelligence, already implemented

**Example Mission Flow with Semantic Memory**:

```
User: "Find the red ball"

1. Agent: Query spatial memory for past "red ball" observations
   → Result: "Last seen at (3.2, 1.5) 10 minutes ago"

2. Agent: Navigate to last known location (local planner)
   → Arrive at (3.2, 1.5)

3. Agent: Camera scan + YOLO detection
   → Not found at last location (object moved)

4. Agent: Query similar scenes in spatial memory
   → "Where else have I seen similar rooms with toys?"
   → Result: Bedroom at (5.0, 8.0) has similar scene embedding

5. Agent: Explore high-probability locations
   → Navigate to bedroom

6. Agent: Find red ball, update spatial memory
   → Store new location with timestamp
```

**Why This is a Game-Changer**:

Traditional robotics: "Ball not found at last location → Give up"

Persistent intelligence: "Ball moved → Query similar contexts → Infer likely locations → Continue search intelligently"

**Technical Details**:

**CLIP Model** (openai/clip-vit-base-patch32):
- 512D image embeddings
- Text-image similarity
- Pre-trained on 400M image-text pairs
- Runs on Thor AGX

**ChromaDB Storage**:
```python
# Initialize persistent spatial memory
spatial_memory = SpatialMemory(
    collection_name="shadowhound_spatial",
    embedding_model="clip",  # or "resnet"
    db_path="/data/chromadb",  # Persistent storage
    min_distance_threshold=0.5,  # Store frame every 0.5m
    min_time_threshold=2.0,  # Or every 2 seconds
)

# Spatial memory auto-updates from video stream
spatial_memory.connect_video_stream(robot.camera_stream)
spatial_memory.connect_transform_provider(robot.get_pose)

# Now spatial memory builds automatically as robot explores!
```

**Query Examples**:

```python
# Semantic query
results = spatial_memory.query_by_text(
    "red ball on carpet",
    limit=5
)

# Spatial query
results = spatial_memory.query_by_location(
    x=3.0, y=2.0, radius=1.5
)

# Hybrid query (semantic + spatial)
results = spatial_memory.query_hybrid(
    text="red ball",
    location=(3.0, 2.0),
    radius=2.0,
    limit=5
)

# Scene similarity (for transfer learning)
similar_scenes = spatial_memory.find_similar_scenes(
    current_image,
    limit=10
)
```

---

## Persistent Intelligence MVP Roadmap

### Phase 1: Foundation (Week 1) - Original MVP Tier 1

**Goal**: Working embodied AI mission with local planning

**Deliverables**:
1. MockRobot implementation (CI/CD enabled)
2. VFH local planner validated on hardware
3. YOLO object detection integrated
4. End-to-end mission: "Find the ball"

**Success Criteria**:
- ✅ Robot finds and navigates to visible objects
- ✅ Success rate > 90% (10 trials)
- ✅ No collisions
- ✅ Mission completion < 30 seconds

**Aligns with Original MVP**: Success criteria #2 (vision missions) and #3 (navigation) Tier 1

**Detailed Timeline**: See `local_planning_quickstart.md`

---

### Phase 2: Learning Infrastructure (Week 2) - Beyond Original MVP

**Goal**: Capture decision data for future learning + Enable semantic spatial memory

**Deliverables**:
1. Trajectory logging system
   - JSON format (simple, readable)
   - Logs: perception, decisions, actions, outcomes
   - Frame consistency (all in odom)
2. **Semantic spatial memory integration**
   - CLIP embeddings for every frame
   - Link observations to XY locations
   - Persistent ChromaDB storage
   - Query interface (text, location, similarity)
3. Session management
   - Unique session IDs
   - Monotonic timestamps
   - Domain tags (real vs sim)
4. Data viewer/analyzer
   - CLI tool to inspect trajectories
   - Success rate analysis
   - Parameter correlation
   - Spatial memory visualization

**Success Criteria**:
- ✅ Every mission logged completely
- ✅ Logs are parseable and queryable
- ✅ Can replay decisions offline
- ✅ Storage < 10MB per hour (trajectories)
- ✅ **Semantic queries work: "Where did I see a red ball?"**
- ✅ **Spatial queries work: "What's in the kitchen?"**
- ✅ **Scene similarity: Find trajectories in similar environments**

**New Capability**: Foundation for persistent intelligence (not in original MVP)

**Implementation Details**:

**Trajectory Log Format** (with semantic memory):
```python
{
    "session_id": "2025-10-14-12-34-56-abc123",
    "domain": "real",
    "mission": {
        "instruction": "Find the red ball",
        "start_time": 1234567890.123,
        "end_time": 1234567920.456,
        "result": "success"
    },
    "trajectory": [
        {
            "step": 0,
            "timestamp": 1234567890.234,
            "perception": {
                "detections": [
                    {"label": "ball", "position": [2.0, 0.5], "confidence": 0.8}
                ],
                "frame": "odom",
                "scene_embedding_id": "clip_abc123"  # Links to ChromaDB
            },
            "decision": {
                "type": "set_goal",
                "goal_xy": [2.0, 0.5],
                "reason": "yolo_detection"
            },
            "vfh_state": {
                "safety_threshold": 0.8,
                "selected_direction": 0.35,
                "obstacle_density": 0.2
            },
            "action": {
                "linear_vel": 0.3,
                "angular_vel": 0.15
            },
            "outcome": {
                "distance_to_goal": 1.2,
                "collision": false
            }
        }
        // ... more steps
    ]
}
```

**Semantic Memory Initialization**:
```python
from dimos.perception.spatial_perception import SpatialMemory
from dimos.agents.memory.image_embedding import ImageEmbeddingProvider

# Initialize spatial memory (persistent across runs)
spatial_memory = SpatialMemory(
    collection_name="shadowhound_missions",
    embedding_model="clip",  # CLIP embeddings for semantic similarity
    embedding_dimensions=512,
    db_path="/data/spatial_memory/chromadb",  # Persistent storage
    visual_memory_path="/data/spatial_memory/images",
    min_distance_threshold=0.5,  # Store frame every 0.5 meters
    min_time_threshold=2.0,  # Or every 2 seconds
    new_memory=False,  # Load existing memory if available
)

# Connect to robot's video and pose streams
spatial_memory.connect_video_stream(robot.camera_stream)
spatial_memory.connect_transform_provider(robot.get_pose)

# Now spatial memory auto-updates as robot operates!
# Every 0.5m or 2s: Capture frame, generate CLIP embedding, store with XY location

# Query examples:
# 1. Semantic: "Where did I see a red ball?"
results = spatial_memory.query_by_text("red ball", limit=5)

# 2. Spatial: "What did I see in the kitchen?"
results = spatial_memory.query_by_location(x=5.0, y=3.0, radius=2.0)

# 3. Similarity: "Find scenes like this one"
similar_scenes = spatial_memory.find_similar_scenes(current_image)

# 4. Episodic: "Show me everywhere I've been"
all_locations = spatial_memory.get_all_locations()
```

**Integration with Mission Agent**:
```python
class MissionAgent:
    def __init__(self):
        self.spatial_memory = SpatialMemory(...)  # Initialize as above
        self.trajectory_logger = TrajectoryLogger(...)
    
    def execute_mission(self, instruction: str):
        # Check spatial memory BEFORE searching
        if "find" in instruction.lower():
            # Query past observations
            query = extract_object(instruction)  # "red ball"
            past_obs = self.spatial_memory.query_by_text(query, limit=3)
            
            if past_obs:
                # Navigate to last known location first
                last_location = past_obs[0]["metadata"]["location"]
                self.logger.info(f"Found {query} in memory at {last_location}")
                self.navigate_to(last_location)
        
        # Execute mission with local planner...
        # Spatial memory auto-updates as robot moves
```

---

### Phase 3: Enhanced Perception (Week 2-3) - Original MVP Tier 2

**Goal**: Add VLM semantic reasoning + Query spatial memory

**Deliverables**:
1. VLM detector integration (Qwen or local LLaVA)
2. Sequential YOLO+VLM pipeline
3. Enhanced missions: "Find the RED ball" (not just any ball)
4. **VLM queries spatial memory**: "Did I see a red ball earlier?"
5. **LLM context from RAG**: Show relevant images when planning

**Success Criteria**:
- ✅ Can distinguish objects by properties (color, state)
- ✅ VLM latency < 5 seconds
- ✅ Correct object found in 90% of trials
- ✅ **Agent can query memory: "Where did I see X?"**
- ✅ **LLM uses image context: "I saw a red ball in the living room 5 mins ago"**

**Aligns with Original MVP**: Success criteria #2 (vision missions) Tier 2

**Implementation Details**:

**VLM + Spatial Memory Integration**:
```python
class EnhancedMissionAgent:
    def plan_mission(self, instruction: str) -> list[dict]:
        # Query spatial memory for context
        relevant_memories = self.spatial_memory.query_by_text(
            instruction,
            limit=5
        )
        
        # Build LLM prompt with image context
        context = self._build_memory_context(relevant_memories)
        
        prompt = f"""
        Instruction: {instruction}
        
        Relevant past observations:
        {context}
        
        Generate a skill plan considering what I know from memory.
        """
        
        plan = self.llm.generate(prompt)
        return plan
    
    def _build_memory_context(self, memories: list) -> str:
        context_lines = []
        for mem in memories:
            loc = mem["metadata"]["location"]
            timestamp = mem["metadata"]["timestamp"]
            label = mem["metadata"].get("label", "object")
            
            context_lines.append(
                f"- Saw {label} at location ({loc[0]:.1f}, {loc[1]:.1f}) "
                f"{self._format_time_ago(timestamp)}"
            )
        
        return "\n".join(context_lines)

# Example mission with memory
instruction = "Find the red ball"

# Agent checks memory first
memories = agent.spatial_memory.query_by_text("red ball", limit=3)

if memories:
    # Found in memory!
    last_seen = memories[0]
    location = last_seen["metadata"]["location"]
    time_ago = calculate_time_since(last_seen["metadata"]["timestamp"])
    
    agent.say(f"I remember seeing a red ball at {location} {time_ago} ago")
    agent.navigate_to(location)
    
    # Check if still there
    if agent.detect_object("red ball"):
        agent.say("Found it! It's still here")
    else:
        agent.say("It moved. Let me check similar locations...")
        # Query similar scenes
        similar = agent.spatial_memory.find_similar_scenes(
            last_seen["image"]
        )
        agent.explore_locations([s["metadata"]["location"] for s in similar])
else:
    # Not in memory, search from scratch
    agent.say("I don't remember seeing a red ball. Starting search...")
    agent.explore()
```

**Implementation**: See `hybrid_perception_architecture.md` Pattern 2 (Sequential)

---

### Phase 4: Global Planning (Week 3-4) - Original MVP Tier 2-3

**Goal**: Add SLAM + Nav2 for multi-room navigation

**Deliverables**:
1. SLAM Toolbox mapping
2. Nav2 global planner integration
3. Hybrid navigation (local + global)
4. Semantic location memory ("kitchen")

**Success Criteria**:
- ✅ Can build map while exploring
- ✅ Can localize in known map
- ✅ Can navigate to semantic locations
- ✅ Switches automatically between local/global

**Aligns with Original MVP**: Success criteria #3 (navigation) Tier 2-3 and #6 (spatial memory)

---

### Phase 5: Persistent Intelligence (Week 4-6) - New Capabilities

**Goal**: Enable learning from experience + Transfer learning via semantic similarity

**Deliverables**:
1. **WAL (Write-Ahead Logging)**
   - Power-loss safe trajectory logging
   - Segment + manifest pattern
   - Can survive robot crashes/power loss

2. **Offline Analysis Tools**
   - Trajectory visualization
   - Success factor analysis
   - Parameter sensitivity studies
   - Failure mode identification
   - **Scene similarity clustering**

3. **Adaptive Parameters**
   - Learn optimal VFH parameters from data
   - Adjust safety margins based on outcomes
   - Tune perception thresholds

4. **Transfer Learning via Semantic Memory**
   - Query similar scenes from past trajectories
   - Retrieve successful strategies for similar situations
   - "This hallway looks like that hallway where I got stuck"
   - Apply lessons learned to new situations

5. **Isaac Sim Integration** (Tower GPU)
   - Replay trajectories in simulation
   - Test parameter changes safely
   - Validate improvements before deployment

**Success Criteria**:
- ✅ Data survives robot crashes
- ✅ Can identify causes of failures
- ✅ Can test improvements in sim
- ✅ Parameter changes improve success rate
- ✅ **Can find similar past situations via scene embeddings**
- ✅ **Success rate improves in familiar environments (transfer learning)**

**New Capabilities**: Beyond original MVP scope

**Transfer Learning Example**:
```python
# Robot encounters difficult navigation scenario
current_scene = robot.get_camera_frame()
current_embedding = clip_model.encode(current_scene)

# Query spatial memory for similar scenes
similar_scenes = spatial_memory.query_by_embedding(
    current_embedding,
    limit=10
)

# Retrieve trajectories from similar scenes
similar_trajectories = []
for scene in similar_scenes:
    session_id = scene["metadata"]["session_id"]
    trajectory = load_trajectory(session_id)
    similar_trajectories.append(trajectory)

# Analyze what worked in similar situations
successful_params = analyze_successful_strategies(similar_trajectories)

# Apply learned parameters
if successful_params:
    logger.info(f"Applying strategy from similar scene (similarity: {similar_scenes[0]['distance']:.2f})")
    vfh_planner.update_parameters(successful_params)
```

**Implementation Details**:

**WAL Pattern**:
```
/data/trajectories/
  ├── 20251014/
  │   ├── segment_001.jsonl    # Active segment
  │   ├── segment_002.jsonl
  │   └── manifest.json         # Index of segments
  └── 20251015/
      └── ...
```

**Analysis Tools**:
```bash
# Analyze success factors
./analyze_trajectories.py --date 2025-10-14 --metric success_rate

# Find failure patterns
./analyze_trajectories.py --failures --group-by perception_confidence

# Visualize trajectory
./visualize_trajectory.py --session 2025-10-14-12-34-56-abc123
```

**Parameter Adaptation**:
```python
# Learn from data
optimizer = TrajectoryOptimizer(trajectories)
improved_params = optimizer.optimize_vfh_parameters()

# Test in simulation
sim_results = test_in_isaac_sim(improved_params, test_scenarios)

# Deploy if better
if sim_results.success_rate > current_success_rate:
    deploy_parameters(improved_params)
```

---

### Phase 6: Multi-Brain Architecture (Week 6-8) - Future Vision

**Goal**: Distributed intelligence (Thor + Spark + Tower)

**Deliverables**:
1. **Message Contracts** (Pydantic schemas)
   - Deliberation RPC
   - Trajectory Log format
   - Adapter metadata

2. **Spark Integration** (when hardware arrives)
   - Receives trajectories from Thor
   - Curates interesting examples
   - Fine-tunes skill adapters (LoRA)
   - Tests in Isaac Sim (Tower)
   - Deploys back to Thor

3. **Day/Night Learning Cycle**
   - Day: Thor operates, logs trajectories
   - Night: Spark learns, Thor tests in sim
   - Morning: Deploy improved adapters

**Success Criteria**:
- ✅ Thor logs trajectories reliably
- ✅ Spark receives and processes logs
- ✅ Adapters improve success rate
- ✅ Deployment is automatic

**Hardware Requirements**:
- Thor: Mobile brainstem (current)
- Spark: DGX Station (not yet acquired)
- Tower: Simulation testing (RTX 4070, available)

**Implementation**: See `persistent_intelligence_architecture_shadowHound.md`

---

## Implementation Priority Matrix

### Critical Path (Must Have for MVP)

| Phase | Item | Effort | Blocks | Priority |
|-------|------|--------|--------|----------|
| 1 | MockRobot | 1-2 days | All testing | 🔴 P0 |
| 1 | VFH local planner | 2-3 days | Perception | 🔴 P0 |
| 1 | YOLO integration | 1-2 days | Missions | 🔴 P0 |
| 1 | End-to-end mission | 1 day | MVP complete | 🔴 P0 |

**Total: ~1 week to working MVP**

### High Value (Should Have)

| Phase | Item | Effort | Blocks | Priority |
|-------|------|--------|--------|----------|
| 2 | Trajectory logging | 1-2 days | Learning | 🟡 P1 |
| 2 | **Semantic spatial memory** | 1-2 days | Episodic memory | 🟡 P1 |
| 3 | VLM integration | 1-2 days | Nuanced missions | 🟡 P1 |
| 3 | **VLM + memory queries** | 1 day | Smart search | 🟡 P1 |
| 4 | SLAM + Nav2 | 1 week | Multi-room | 🟡 P1 |

**Total: +2 weeks for enhanced MVP**

### Future Work (Nice to Have)

| Phase | Item | Effort | Blocks | Priority |
|-------|------|--------|--------|----------|
| 5 | WAL logging | 2-3 days | Reliability | 🟢 P2 |
| 5 | Isaac Sim | 1-2 weeks | Safe testing | 🟢 P2 |
| 5 | Parameter adaptation | 3-5 days | Learning | 🟢 P2 |
| 6 | Multi-brain | 2-3 weeks | Distributed | 🔵 P3 |

---

## Alignment with Original MVP

### Success Criteria Mapping

| Original MVP Criterion | How Persistent Intelligence MVP Addresses |
|------------------------|------------------------------------------|
| **#1: Voice/console/web commands** | ✅ Console/web in Phase 1, voice deferred to Phase 4 |
| **#2: Vision-based missions** | ✅ Phase 1 (YOLO) + Phase 3 (VLM) |
| **#3: Navigate safely** | ✅ Phase 1 (local) + Phase 4 (global) |
| **#4: Voice output + personality** | ⏸️ Deferred (focus on autonomy first) |
| **#5: Onboard computation** | ✅ Thor AGX for all compute |
| **#6: Learn spatial information** | ✅ Phase 2 (logging) + Phase 5 (learning) |

### What We Add Beyond Original MVP

1. **Faster Development Path**: Local planning first (1 week vs 2-3 weeks)
2. **Learning Infrastructure**: Trajectory logging from day 1
3. **Adaptive System**: Parameters improve from experience
4. **Simulation Integration**: Safe testing in Isaac Sim
5. **Multi-Brain Architecture**: Foundation for distributed intelligence

### What We Defer

1. **Voice Interface**: Console/web sufficient for MVP validation
2. **Personality System**: Can add after autonomy working
3. **Multi-Brain Deployment**: Requires Spark hardware (not yet acquired)

---

## Risk Assessment

### High Risk Items

**1. go2_ros2_sdk Local Costmap**
- **Risk**: VFH planner needs `/local_costmap/costmap` topic
- **Impact**: Blocks Phase 1 (local planning)
- **Mitigation**: Generate costmap from `/scan` if needed
- **Probability**: Medium (30%)

**2. Thor GPU Performance**
- **Risk**: Degraded performance (5 tok/s vs 37 tok/s)
- **Impact**: VLM latency too high
- **Mitigation**: Use cloud VLM or troubleshoot Thor
- **Probability**: High (60%)

**3. WebRTC API Blocker**
- **Risk**: Most DIMOS skills non-functional
- **Impact**: Limited skill set available
- **Mitigation**: Use working skills, implement custom Nav2 skills
- **Probability**: High (100% - known issue)

### Medium Risk Items

**4. Frame Transformation Errors**
- **Risk**: base_link → odom transforms incorrect
- **Impact**: Wrong navigation goals
- **Mitigation**: Extensive validation in Phase 1
- **Probability**: Medium (40%)

**5. Depth Estimation Accuracy**
- **Risk**: Metric3D errors > 50cm
- **Impact**: Inaccurate object positions
- **Mitigation**: Calibrate, validate, consider RGB-D camera
- **Probability**: Low (20%)

### Mitigation Strategies

**Phase 1 Validation** (reduce risk before Phase 2):
- Validate every transform with known test positions
- Test obstacle avoidance extensively
- Benchmark perception accuracy
- Document failure modes

**Incremental Delivery** (fail fast):
- Ship Phase 1 before starting Phase 2
- Get user feedback at each phase
- Pivot if assumptions wrong

**Parallel Tracks** (reduce critical path):
- Phase 2 (logging) can start during Phase 1
- Phase 5 (Isaac Sim) can start during Phase 3-4
- Documentation continuously updated

---

## Success Metrics

### Phase 1 (MVP Minimum)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Mission Success Rate** | > 90% | 10 trials, "Find the ball" |
| **Navigation Accuracy** | < 1m error | Distance to object |
| **Mission Duration** | < 30s | Start to completion |
| **Collision Rate** | 0% | No collisions in 10 trials |

### Phase 2 (Learning Infrastructure + Semantic Memory)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Logging Reliability** | 100% | No lost data |
| **Storage Efficiency** | < 10MB/hr | Disk usage (trajectories) |
| **Replay Accuracy** | 100% | Can reconstruct all decisions |
| **Semantic Query Accuracy** | > 80% | "Where did I see X?" retrieves correct location |
| **Spatial Query Speed** | < 100ms | Query response time |
| **Scene Similarity Precision** | > 0.7 | CLIP embedding cosine similarity |

### Phase 3 (Enhanced Perception + Memory Integration)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **VLM + Memory Success** | > 85% | "Find red ball" uses memory first |
| **Memory-Guided Search** | 2x faster | Compare with/without memory |
| **RAG Context Quality** | > 80% | LLM uses relevant images |

### Phase 5 (Persistent Intelligence + Transfer Learning)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Learning Improvement** | +10% success rate | After parameter adaptation |
| **Sim-to-Real Transfer** | > 80% | Sim predictions → real outcomes |
| **Data Durability** | Zero loss | Survives crashes |
| **Transfer Learning Benefit** | +15% success | In similar scenes vs novel scenes |
| **Scene Retrieval Accuracy** | > 0.8 | Find relevant past situations |

---

## Hardware Evolution

### Current Hardware (MVP Phase 1-4)

- **Development**: Laptop (ROS2, DIMOS, mission agent)
- **Compute**: Thor AGX 128GB (LLM/VLM inference)
- **Robot**: Unitree Go2 Pro (sensors, actuators)
- **Simulation**: Tower RTX 4070 (available, unused)

### Future Hardware (Phase 6+)

- **Thor**: Mobile brainstem (real-time control)
- **Spark**: DGX Station (learning, fine-tuning) ← **Not yet acquired**
- **Tower**: Simulation avatar (Isaac Sim testing)
- **Go2**: Body (unchanged)

### Migration Path

**Phase 1-4**: Everything on laptop + Thor (current)
**Phase 5**: Add Tower for Isaac Sim (RTX 4070)
**Phase 6**: Add Spark when hardware arrives

---

## Open Questions

### Phase 1 Unknowns
- [ ] Does go2_ros2_sdk publish local costmap?
- [ ] What is costmap update rate?
- [ ] Camera calibration parameters available?
- [ ] Can Thor handle VLM inference?

### Phase 2-3 Unknowns
- [ ] Which VLM to use? (Qwen API vs local LLaVA)
- [ ] What VLM sample rate? (balance latency vs accuracy)
- [ ] How to handle conflicting detections? (YOLO vs VLM)

### Phase 4 Unknowns
- [ ] SLAM Toolbox parameters for Go2?
- [ ] Nav2 costmap layer configuration?
- [ ] Semantic map representation?

### Phase 5-6 Unknowns
- [ ] When does Spark hardware arrive?
- [ ] What adapter architecture? (LoRA, BitFit, etc.)
- [ ] How to transfer sim-to-real?

---

## Next Steps

### Immediate Actions (This Week)

1. **Decision**: Approve persistent intelligence MVP approach
2. **Action**: Create GitHub issues for Phase 1 tasks
3. **Action**: Set up MockRobot development environment
4. **Action**: Validate go2_ros2_sdk local costmap availability

### Week 1 Execution

- [ ] Day 1-2: Implement MockRobot (CI/CD)
- [ ] Day 3-4: Test VFH local planner on hardware
- [ ] Day 5: Integrate YOLO detection
- [ ] Day 6-7: End-to-end mission testing

### Week 2 Planning

- [ ] Review Phase 1 results
- [ ] Decide: Continue to Phase 2 or iterate Phase 1?
- [ ] Plan trajectory logging implementation
- [ ] Research VLM options (API vs local)

---

## Conclusion

### Why This Approach Works

1. **Builds on Original MVP**: Respects existing goals and success criteria
2. **Accelerates Development**: Local planning first gets to autonomous navigation faster
3. **Reduces Risk**: Simpler stack, fewer dependencies, iterative delivery
4. **Enables Learning**: Trajectory logging from day 1 prepares for persistent intelligence
5. **Hybrid Strategy**: Supports both local and global planning, use what's appropriate

### Key Differentiators

**vs Original MVP**:
- ✅ Faster timeline (1 week vs 3-4 weeks to first autonomous mission)
- ✅ Lower risk (proven local planning vs untested SLAM)
- ✅ Learning foundation (trajectory logging built in)
- ✅ Incremental delivery (ship Phase 1, then enhance)

**vs Pure Research**:
- ✅ Concrete deliverables (working robot at each phase)
- ✅ Measurable success criteria
- ✅ Practical constraints acknowledged (hardware, APIs)
- ✅ Migration path to future vision

### Recommendation

**Approve persistent intelligence MVP approach with local planning first strategy.**

This enables:
- Rapid validation of autonomous navigation (1 week)
- Early user feedback and iteration
- Foundation for continuous learning
- Clear path to multi-brain architecture

While maintaining:
- Original MVP goals and success criteria
- Flexibility to add global planning when needed
- Option to enhance with voice, personality, etc.

---

## References

### Related Documentation

- **Foundation**: [ShadowHound MVP: Embodied AI Platform](../project_overview/mvp_embodied_ai_platform.md)
- **Technical Deep Dive**: [Local Planning Architecture](local_planning_architecture.md)
- **Perception Patterns**: [Hybrid Perception Architecture](hybrid_perception_architecture.md)
- **Quick Start**: [Local Planning Quickstart](local_planning_quickstart.md)
- **Learning Integration**: [Persistent Intelligence DIMOS Integration](persistent_intelligence_dimos_integration.md)
- **Future Vision**: [Persistent Intelligence Architecture](persistent_intelligence_architecture_shadowHound.md)

### External References

- **VFH Algorithm**: Borenstein & Koren (1991)
- **Pure Pursuit**: Coulter (1992)
- **DIMOS Framework**: `src/dimos-unitree/`
- **Go2 SDK**: `go2_ros2_sdk` documentation
