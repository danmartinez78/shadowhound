---
tags: [architecture, perception, vision, yolo, vlm, hybrid, dimos, mvp]
status: draft
related:
  - local_planning_architecture.md
  - mvp_implementation_roadmap.md
  - persistent_intelligence_dimos_integration.md
summary: >
  Technical architecture for hybrid YOLO + VLM perception system. Defines three integration patterns
  (parallel, sequential, adaptive) with streaming implementations. Shows how to combine real-time
  object detection with semantic reasoning for embodied AI missions.
---

# Hybrid Perception Architecture: YOLO + VLM Integration

## Executive Summary

**Problem**: Pure YOLO is fast but limited to fixed classes. Pure VLM is flexible but too slow for real-time navigation.

**Solution**: **Hybrid architecture** that combines YOLO's speed (30 FPS) with VLM's semantic reasoning (0.2-1 FPS) using RxPY streaming operators.

**Three Patterns**:
1. **Parallel Streams**: YOLO and VLM run independently, merge results
2. **Sequential Pipeline**: YOLO filters candidates, VLM verifies semantics
3. **Adaptive Switching**: Change strategy based on mission phase

**Impact**: Enables nuanced queries ("Find the RED ball") while maintaining real-time tracking performance.

---

## Perception System Overview

### DIMOS ObjectDetectionStream Architecture

**Pipeline**:
```
Video Stream (30 FPS)
    ↓
Detector (YOLO/Detic/VLM) → Bounding boxes
    ↓
Depth Estimation (Metric3D) → 3D position
    ↓
Frame Transform (base_link → odom) → Navigation coordinates
    ↓
Local Planner → Goal setting
```

**Key Code** (`object_detection_stream.py`):
```python
class ObjectDetectionStream:
    def __init__(
        self,
        camera_intrinsics,          # [fx, fy, cx, cy]
        detector,                   # YOLO | Detic | VLM (pluggable!)
        transform_to_map,           # Frame transformation function
        video_stream,               # Observable[frame]
    ):
        self.detector = detector
        self.depth_model = Metric3D()
        
    def create_stream(self, video_stream) -> Observable:
        """Create detection stream from video."""
        return video_stream.pipe(
            ops.map(self._process_frame)  # Detect + depth + transform
        )
    
    def _process_frame(self, frame):
        # 1. Detect objects
        bboxes, confidences, labels = self.detector.process_image(frame)
        
        # 2. Estimate depth
        depths = [calculate_depth(frame, bbox) for bbox in bboxes]
        
        # 3. Calculate 3D positions (in base_link)
        positions = [calculate_position(bbox, depth) for bbox, depth in zip(bboxes, depths)]
        
        # 4. Transform to odom frame
        positions_odom = [self.transform_to_map(pos, "base_link") for pos in positions]
        
        return {"objects": list(zip(labels, positions_odom, confidences))}
```

**Detector Interface** (pluggable):
```python
class Detector(ABC):
    @abstractmethod
    def process_image(self, frame: np.ndarray) -> Tuple[List, List, List]:
        """
        Returns:
            bboxes: List of [x1, y1, x2, y2]
            confidences: List of float (0-1)
            labels: List of str
        """
        pass
```

---

## Pattern 1: Parallel Streams

### Architecture

**Use Case**: Run YOLO and VLM independently, merge results

**When to Use**:
- Need both fast tracking (YOLO) and semantic understanding (VLM)
- Different update rates appropriate (YOLO 10 Hz, VLM 0.2 Hz)
- Want redundancy (if YOLO misses, VLM might catch)

**Data Flow**:
```
Video Stream (30 FPS)
    ├─→ YOLO Stream (10 FPS sampling) → "ball" detections
    └─→ VLM Stream (0.2 FPS sampling) → "red ball" detections
              ↓
        rx.merge() → Combined stream
              ↓
        Navigation (use first valid detection)
```

### Implementation

```python
import reactivex as rx
from reactivex import operators as ops

class ParallelPerceptionStream:
    """Runs YOLO and VLM in parallel at different rates."""
    
    def __init__(self, robot):
        self.robot = robot
        self.video_stream = robot.get_ros_video_stream()
        
        # Initialize detectors
        self.yolo_detector = Yolo2DDetector()
        self.vlm_detector = VLMDetector(model="qwen-vl")
        
        # Initialize depth model (shared)
        self.depth_model = Metric3D()
    
    def create_yolo_stream(self) -> Observable:
        """High-frequency YOLO detection stream."""
        return ObjectDetectionStream(
            detector=self.yolo_detector,
            camera_intrinsics=self.robot.camera_intrinsics,
            transform_to_map=self.robot.ros_control.transform_pose,
            video_stream=self.video_stream
        ).get_stream().pipe(
            ops.sample(0.1),  # 10 FPS (throttle from 30 FPS)
            ops.map(lambda det: {**det, "source": "yolo"})
        )
    
    def create_vlm_stream(self, query: str) -> Observable:
        """Low-frequency VLM detection stream."""
        return self.video_stream.pipe(
            ops.sample(5.0),  # Every 5 seconds (VLM is slow)
            ops.map(lambda frame: self._vlm_detect(frame, query)),
            ops.filter(lambda det: det is not None),  # Only valid detections
            ops.map(lambda det: {**det, "source": "vlm"})
        )
    
    def _vlm_detect(self, frame, query: str):
        """Query VLM for object detection."""
        # Query VLM (e.g., "Find the red ball in this image")
        bbox, confidence = self.vlm_detector.detect(frame, query)
        
        if bbox is None:
            return None
        
        # Calculate 3D position
        depth = calculate_depth_from_bbox(self.depth_model, frame, bbox)
        position, rotation = calculate_position_rotation_from_bbox(
            bbox, depth, self.robot.camera_intrinsics
        )
        
        # Transform to odom
        position_odom, _ = self.robot.ros_control.transform_pose(
            position, rotation, source_frame="base_link"
        )
        
        return {
            "label": query,
            "bbox": bbox,
            "position": position_odom,
            "confidence": confidence,
            "frame": frame
        }
    
    def create_merged_stream(self, query: str) -> Observable:
        """Merge YOLO and VLM streams."""
        yolo_stream = self.create_yolo_stream()
        vlm_stream = self.create_vlm_stream(query)
        
        # Merge streams (interleaved)
        return rx.merge(yolo_stream, vlm_stream).pipe(
            ops.filter(lambda det: self._is_relevant(det, query))
        )
    
    def _is_relevant(self, detection, query: str):
        """Filter detections based on query."""
        # YOLO: Check if label matches base class
        if detection["source"] == "yolo":
            base_class = self._extract_base_class(query)  # "red ball" → "ball"
            return any(obj["label"] == base_class for obj in detection.get("objects", []))
        
        # VLM: Already filtered by query
        return True

# Usage
perception = ParallelPerceptionStream(robot)
stream = perception.create_merged_stream(query="red ball")

# Navigate to first detection
stream.pipe(ops.take(1)).subscribe(
    on_next=lambda det: navigate_to_detection(det)
)
```

### Pros and Cons

**Pros**:
- ✅ Real-time tracking (YOLO maintains lock)
- ✅ Semantic verification (VLM adds confidence)
- ✅ Redundancy (multiple detection sources)
- ✅ Independent tuning (adjust rates separately)

**Cons**:
- ⚠️ Conflicting detections (need merge logic)
- ⚠️ Duplicate processing (both run on same frames)
- ⚠️ Complex synchronization

**Best For**: High-reliability missions where redundancy is valuable

---

## Pattern 2: Sequential Pipeline (Recommended)

### Architecture

**Use Case**: YOLO finds candidates, VLM verifies semantics

**When to Use**:
- Nuanced queries ("red ball" not just "ball")
- Want efficiency (VLM only on candidates)
- Prefer accuracy over latency

**Data Flow**:
```
Video Stream (30 FPS)
    ↓
YOLO Detector (10 FPS) → All "ball" detections
    ↓
Filter (only balls with confidence > 0.6)
    ↓
Sample (every 2 seconds) → Throttle VLM load
    ↓
VLM Verifier → "Is this ball red?"
    ↓
Filter (only confirmed red balls)
    ↓
Navigation
```

### Implementation

```python
class SequentialPerceptionStream:
    """YOLO finds candidates, VLM verifies semantics."""
    
    def __init__(self, robot):
        self.robot = robot
        self.video_stream = robot.get_ros_video_stream()
        self.yolo_detector = Yolo2DDetector()
        self.vlm_verifier = VLMVerifier()
    
    def create_stream(self, base_class: str, semantic_filter: str) -> Observable:
        """
        Args:
            base_class: YOLO class to detect (e.g., "ball")
            semantic_filter: VLM verification query (e.g., "Is this ball red?")
        """
        # Stage 1: YOLO candidate detection
        yolo_stream = ObjectDetectionStream(
            detector=self.yolo_detector,
            camera_intrinsics=self.robot.camera_intrinsics,
            transform_to_map=self.robot.ros_control.transform_pose,
            video_stream=self.video_stream
        ).get_stream()
        
        # Stage 2: Extract candidates
        candidate_stream = yolo_stream.pipe(
            # Flatten objects array
            ops.flat_map(lambda det: rx.from_(det.get("objects", []))),
            
            # Filter by class
            ops.filter(lambda obj: obj["label"] == base_class),
            
            # Keep frame reference for VLM
            ops.map(lambda obj: {**obj, "needs_verification": True})
        )
        
        # Stage 3: VLM verification (throttled)
        verified_stream = candidate_stream.pipe(
            ops.sample(2.0),  # Every 2 seconds (throttle VLM)
            ops.map(lambda obj: self._verify_with_vlm(obj, semantic_filter)),
            ops.filter(lambda obj: obj["verified"])
        )
        
        return verified_stream
    
    def _verify_with_vlm(self, detection, query: str):
        """Verify detection with VLM."""
        frame = detection["frame"]
        bbox = detection["bbox"]
        
        # Crop to object
        x1, y1, x2, y2 = map(int, bbox)
        roi = frame[y1:y2, x1:x2]
        
        # Query VLM
        response = self.vlm_verifier.query(roi, query)
        
        # Parse response (e.g., "Yes, this is a red ball" → True)
        verified = self._parse_vlm_response(response, query)
        
        return {
            **detection,
            "verified": verified,
            "vlm_response": response
        }
    
    def _parse_vlm_response(self, response: str, query: str) -> bool:
        """Parse VLM natural language response."""
        # Simple keyword matching
        positive_keywords = ["yes", "correct", "true", "is"]
        response_lower = response.lower()
        
        return any(keyword in response_lower for keyword in positive_keywords)

# Usage Example 1: Find red ball
perception = SequentialPerceptionStream(robot)
stream = perception.create_stream(
    base_class="ball",              # YOLO finds all balls
    semantic_filter="Is this ball red?"  # VLM verifies color
)

stream.subscribe(
    on_next=lambda det: navigate_to_detection(det)
)

# Usage Example 2: Find person in blue shirt
stream = perception.create_stream(
    base_class="person",
    semantic_filter="Is this person wearing a blue shirt?"
)
```

### Advanced: Multi-Stage Verification

```python
class MultiStagePerceptionStream(SequentialPerceptionStream):
    """Multiple VLM verification stages."""
    
    def create_stream(self, filters: List[Dict]) -> Observable:
        """
        Args:
            filters: List of {"yolo_class": str, "vlm_queries": List[str]}
        """
        # Stage 1: YOLO detection
        yolo_stream = self._create_yolo_stream()
        
        # Stage 2: First VLM filter
        first_filter = yolo_stream.pipe(
            ops.filter(lambda obj: obj["label"] == filters[0]["yolo_class"]),
            ops.sample(2.0),
            ops.map(lambda obj: self._verify(obj, filters[0]["vlm_queries"][0])),
            ops.filter(lambda obj: obj["verified"])
        )
        
        # Stage 3: Second VLM filter (more specific)
        second_filter = first_filter.pipe(
            ops.sample(5.0),  # Less frequent (more expensive query)
            ops.map(lambda obj: self._verify(obj, filters[0]["vlm_queries"][1])),
            ops.filter(lambda obj: obj["verified"])
        )
        
        return second_filter

# Usage: Find specific person
stream = MultiStagePerceptionStream(robot).create_stream([
    {
        "yolo_class": "person",
        "vlm_queries": [
            "Is this person wearing blue?",  # Fast check
            "Is this person wearing a blue shirt and black pants?"  # Detailed check
        ]
    }
])
```

### Pros and Cons

**Pros**:
- ✅ Efficient (VLM only on candidates)
- ✅ Accurate (semantic verification)
- ✅ Flexible (chain multiple filters)
- ✅ Predictable latency (throttled VLM)

**Cons**:
- ⚠️ Higher latency (multi-stage pipeline)
- ⚠️ Can miss fast-moving objects (throttling)
- ⚠️ YOLO must detect base class first

**Best For**: Nuanced queries where accuracy > speed

---

## Pattern 3: Adaptive Switching

### Architecture

**Use Case**: Change perception strategy based on mission phase

**When to Use**:
- Mission has distinct phases (search → approach → verify)
- Want to optimize for each phase
- Complexity acceptable for performance gain

**Phase Transitions**:
```
Phase 1: SEARCH (VLM only, 0.3 Hz)
  "Where is the red ball?" → Find it
  ↓
Phase 2: APPROACH (YOLO only, 10 Hz)
  "Track that ball" → Navigate toward it
  ↓
Phase 3: VERIFY (VLM once)
  "Is this really a red ball?" → Confirm before grasping
```

### Implementation

```python
from enum import Enum
from typing import Callable

class MissionPhase(Enum):
    SEARCH = "search"      # VLM: Find object anywhere
    APPROACH = "approach"  # YOLO: Track object while navigating
    VERIFY = "verify"      # VLM: Final confirmation

class AdaptivePerceptionStream:
    """Switches perception strategy based on mission phase."""
    
    def __init__(self, robot):
        self.robot = robot
        self.video_stream = robot.get_ros_video_stream()
        self.current_phase = MissionPhase.SEARCH
        
        # Detectors
        self.yolo = Yolo2DDetector()
        self.vlm = VLMDetector()
        
        # Phase-specific streams
        self._search_stream = None
        self._approach_stream = None
        self._verify_stream = None
    
    def create_stream(self, mission_config: Dict) -> Observable:
        """
        Args:
            mission_config: {
                "search_query": "Find a red ball",
                "yolo_class": "ball",
                "verify_query": "Is this ball red and smooth?"
            }
        """
        # Create phase-specific streams
        self._search_stream = self._create_search_stream(
            mission_config["search_query"]
        )
        self._approach_stream = self._create_approach_stream(
            mission_config["yolo_class"]
        )
        self._verify_stream = self._create_verify_stream(
            mission_config["verify_query"]
        )
        
        # Merge streams with phase gating
        return rx.merge(
            self._search_stream.pipe(
                ops.filter(lambda _: self.current_phase == MissionPhase.SEARCH)
            ),
            self._approach_stream.pipe(
                ops.filter(lambda _: self.current_phase == MissionPhase.APPROACH)
            ),
            self._verify_stream.pipe(
                ops.filter(lambda _: self.current_phase == MissionPhase.VERIFY)
            )
        )
    
    def _create_search_stream(self, query: str) -> Observable:
        """VLM-based search (slow but thorough)."""
        return self.video_stream.pipe(
            ops.sample(3.0),  # Every 3 seconds
            ops.map(lambda frame: self._vlm_detect(frame, query)),
            ops.filter(lambda det: det is not None),
            ops.do_action(lambda det: self._on_object_found(det))
        )
    
    def _create_approach_stream(self, yolo_class: str) -> Observable:
        """YOLO-based tracking (fast)."""
        yolo_stream = ObjectDetectionStream(
            detector=self.yolo,
            camera_intrinsics=self.robot.camera_intrinsics,
            transform_to_map=self.robot.ros_control.transform_pose,
            video_stream=self.video_stream
        ).get_stream()
        
        return yolo_stream.pipe(
            ops.sample(0.1),  # 10 FPS
            ops.flat_map(lambda det: rx.from_(det.get("objects", []))),
            ops.filter(lambda obj: obj["label"] == yolo_class),
            ops.do_action(lambda obj: self._check_approach_complete(obj))
        )
    
    def _create_verify_stream(self, query: str) -> Observable:
        """VLM verification (once)."""
        return self.video_stream.pipe(
            ops.take(1),  # Only once
            ops.map(lambda frame: self._vlm_verify(frame, query)),
            ops.do_action(lambda result: self._on_verification_complete(result))
        )
    
    def _on_object_found(self, detection):
        """Callback when object found in search phase."""
        logger.info(f"Object found: {detection['label']}")
        self.switch_phase(MissionPhase.APPROACH)
    
    def _check_approach_complete(self, detection):
        """Check if close enough to object."""
        distance = detection["position"]["distance"]
        if distance < 1.0:  # Within 1 meter
            logger.info("Approach complete, verifying...")
            self.switch_phase(MissionPhase.VERIFY)
    
    def _on_verification_complete(self, result):
        """Callback when verification done."""
        if result["verified"]:
            logger.info("Object verified! Mission complete.")
        else:
            logger.warning("Verification failed, re-searching...")
            self.switch_phase(MissionPhase.SEARCH)
    
    def switch_phase(self, new_phase: MissionPhase):
        """Change mission phase."""
        logger.info(f"Phase transition: {self.current_phase.value} → {new_phase.value}")
        self.current_phase = new_phase

# Usage
perception = AdaptivePerceptionStream(robot)
stream = perception.create_stream({
    "search_query": "Find a red ball",
    "yolo_class": "ball",
    "verify_query": "Is this a smooth red ball?"
})

# Subscribe to stream
stream.subscribe(
    on_next=lambda det: handle_detection(det, perception.current_phase)
)

def handle_detection(detection, phase):
    if phase == MissionPhase.SEARCH:
        # VLM found object, start navigation
        navigate_to_detection(detection)
    
    elif phase == MissionPhase.APPROACH:
        # YOLO tracking, update goal continuously
        update_navigation_goal(detection)
    
    elif phase == MissionPhase.VERIFY:
        # VLM verification, stop and confirm
        if detection["verified"]:
            mission_success()
        else:
            restart_search()
```

### Phase Transition Logic

```python
class MissionStateMachine:
    """State machine for adaptive perception."""
    
    def __init__(self):
        self.phase = MissionPhase.SEARCH
        self.detection_history = []
    
    def transition(self, event: str, data: Dict):
        """Handle phase transitions."""
        if self.phase == MissionPhase.SEARCH:
            if event == "object_detected":
                # VLM found something
                self.phase = MissionPhase.APPROACH
                return "start_navigation"
        
        elif self.phase == MissionPhase.APPROACH:
            if event == "distance_threshold":
                # Close enough to object
                if data["distance"] < 1.5:
                    self.phase = MissionPhase.VERIFY
                    return "request_verification"
            elif event == "object_lost":
                # Lost tracking
                self.phase = MissionPhase.SEARCH
                return "restart_search"
        
        elif self.phase == MissionPhase.VERIFY:
            if event == "verification_complete":
                if data["verified"]:
                    return "mission_complete"
                else:
                    self.phase = MissionPhase.SEARCH
                    return "restart_search"
```

### Pros and Cons

**Pros**:
- ✅ Optimized for each phase
- ✅ Efficient (right tool for right job)
- ✅ Robust (handles failures gracefully)
- ✅ Extensible (add more phases)

**Cons**:
- ⚠️ Complex state management
- ⚠️ Harder to debug
- ⚠️ Phase transition logic required
- ⚠️ Potential for state confusion

**Best For**: Complex missions with distinct phases

---

## VLM Integration Details

### VLM Detector Interface

```python
class VLMDetector:
    """Vision-Language Model detector (Qwen, GPT-4V, LLaVA, etc.)."""
    
    def __init__(self, model: str = "qwen-vl", api_key: str = None):
        self.model = model
        self.api_key = api_key
    
    def detect(self, frame: np.ndarray, query: str) -> Tuple[List[float], float]:
        """
        Detect object based on natural language query.
        
        Args:
            frame: Image (H, W, 3) RGB
            query: Natural language query (e.g., "Find the red ball")
        
        Returns:
            bbox: [x1, y1, x2, y2] or None
            confidence: 0-1 score
        """
        # Convert frame to base64
        image_b64 = self._encode_image(frame)
        
        # Query VLM
        response = self._query_vlm(image_b64, query)
        
        # Parse response for bbox
        bbox = self._parse_bbox_from_response(response)
        confidence = self._estimate_confidence(response)
        
        return bbox, confidence
    
    def verify(self, frame: np.ndarray, query: str) -> Dict:
        """
        Verify object properties with yes/no question.
        
        Args:
            query: Yes/no question (e.g., "Is this ball red?")
        
        Returns:
            {"answer": bool, "confidence": float, "explanation": str}
        """
        image_b64 = self._encode_image(frame)
        response = self._query_vlm(image_b64, query)
        
        return {
            "answer": self._parse_yes_no(response),
            "confidence": self._estimate_confidence(response),
            "explanation": response
        }
    
    def _query_vlm(self, image_b64: str, query: str) -> str:
        """Query VLM API."""
        if self.model == "qwen-vl":
            return self._query_qwen(image_b64, query)
        elif self.model == "gpt-4v":
            return self._query_openai(image_b64, query)
        else:
            raise ValueError(f"Unknown VLM model: {self.model}")
    
    def _query_qwen(self, image_b64: str, query: str) -> str:
        """Query Alibaba Qwen VL."""
        # Use DIMOS existing implementation
        from dimos.models.qwen.video_query import get_bbox_from_qwen_frame
        # ... implementation
    
    def _parse_bbox_from_response(self, response: str) -> Optional[List[float]]:
        """Parse bbox from VLM response."""
        # VLMs may return bbox in various formats:
        # - "The object is at [100, 200, 300, 400]"
        # - "Box: x1=100, y1=200, x2=300, y2=400"
        # - JSON: {"bbox": [100, 200, 300, 400]}
        
        # Try regex patterns
        import re
        patterns = [
            r'\[(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\]',  # [x1, y1, x2, y2]
            r'x1=(\d+).*y1=(\d+).*x2=(\d+).*y2=(\d+)',  # x1=... y1=... x2=... y2=...
        ]
        
        for pattern in patterns:
            match = re.search(pattern, response)
            if match:
                return [int(match.group(i)) for i in range(1, 5)]
        
        return None
```

### DIMOS Qwen Integration (Already Exists!)

**Existing Code** (`NavigateWithText` skill, lines 110-120):
```python
from dimos.models.qwen.video_query import get_bbox_from_qwen_frame

# Query Qwen for object
frame = robot.get_ros_video_stream().pipe(ops.take(1)).run()
bbox, object_size = get_bbox_from_qwen_frame(frame, object_name="red ball")

if bbox is not None:
    # Start tracking
    robot.object_tracker.track(bbox, frame=frame)
```

**Can reuse this for VLM detector!**

---

## Frame Handling in Hybrid System

### Coordinate Frame Pipeline

```
Stage 1: Image Space (YOLO/VLM output)
  bbox: [x1, y1, x2, y2] pixels
  ↓
Stage 2: Camera Frame (base_link)
  Calculate 3D position from bbox + depth
  position: (x, y, z) in base_link (x=forward, y=left, z=up)
  ↓
Stage 3: Odometry Frame (odom)
  Transform using ROS tf2
  position: (x, y, z) in odom (integrated wheel odometry)
  ↓
Stage 4: Local Planner
  Set goal in odom
  VFH navigates while avoiding obstacles
```

### Frame Synchronization

**Problem**: Video and transforms have different timestamps

**Solution**: ROS tf2 buffer with time interpolation

```python
class FrameSynchronizer:
    """Synchronize video frames with robot pose transforms."""
    
    def __init__(self, robot):
        self.robot = robot
        self.tf_buffer_duration = 10.0  # Keep 10 seconds of transforms
    
    def transform_detection_to_odom(self, detection, frame_timestamp):
        """
        Transform detection from base_link to odom at frame time.
        
        Args:
            detection: Detection with position in base_link
            frame_timestamp: ROS time when frame was captured
        
        Returns:
            Detection with position in odom
        """
        try:
            # Get transform at frame time (not current time!)
            position_odom, rotation_odom = self.robot.ros_control.transform_pose(
                detection["position"],
                detection["rotation"],
                source_frame="base_link",
                target_frame="odom",
                time=frame_timestamp  # Use frame time!
            )
            
            return {
                **detection,
                "position": position_odom,
                "rotation": rotation_odom,
                "frame": "odom"
            }
        except Exception as e:
            logger.warning(f"Transform failed: {e}")
            return None
```

### Latency Budget

| Component | Latency | Notes |
|-----------|---------|-------|
| Camera capture | 33ms | 30 FPS |
| YOLO inference | 30ms | GPU (RTX 4070) |
| Depth estimation | 50ms | Metric3D |
| Frame transform | 5ms | tf2 lookup |
| Local planner | 50ms | VFH computation |
| **Total (YOLO)** | **~170ms** | Acceptable for 10 Hz |
| VLM inference | 2-5s | API call |
| **Total (VLM)** | **~2-5s** | Why we throttle |

---

## RxPY Streaming Patterns

### Useful Operators

```python
# Sampling
stream.pipe(ops.sample(2.0))  # Every 2 seconds
stream.pipe(ops.throttle_first(1.0))  # First in each 1s window

# Filtering
stream.pipe(ops.filter(lambda x: x["confidence"] > 0.8))
stream.pipe(ops.distinct_until_changed())  # Suppress duplicates

# Transformation
stream.pipe(ops.map(lambda x: transform(x)))
stream.pipe(ops.flat_map(lambda x: rx.from_(x)))  # Flatten lists

# Combining
rx.merge(stream1, stream2)  # Interleave
rx.concat(stream1, stream2)  # Sequential
rx.zip(stream1, stream2)  # Pair items

# Buffering
stream.pipe(ops.buffer_with_time(5.0))  # Collect 5s worth
stream.pipe(ops.take(10))  # First 10 items
```

### Backpressure Handling

**Problem**: VLM is slow, frames pile up

**Solution**: Sampling operators (drop frames)

```python
# Bad: Process every frame (overwhelms VLM)
video_stream.pipe(
    ops.map(lambda frame: vlm.detect(frame, "red ball"))  # 30 FPS → 30 VLM calls!
)

# Good: Sample at VLM rate
video_stream.pipe(
    ops.sample(5.0),  # Every 5 seconds (0.2 Hz)
    ops.map(lambda frame: vlm.detect(frame, "red ball"))  # Manageable
)

# Better: Throttle + buffer
video_stream.pipe(
    ops.throttle_first(3.0),  # First frame in each 3s window
    ops.map(lambda frame: vlm.detect(frame, "red ball")),
    ops.buffer_with_count(5),  # Batch 5 results
    ops.map(lambda batch: select_best(batch))  # Pick highest confidence
)
```

---

## Performance Optimization

### YOLO Optimization

```python
# Use smaller model for speed
yolo_detector = Yolo2DDetector(
    model="yolo11n.pt",  # Nano (fastest)
    # model="yolo11s.pt",  # Small
    # model="yolo11m.pt",  # Medium (more accurate)
)

# Reduce resolution
video_stream.pipe(
    ops.map(lambda frame: cv2.resize(frame, (640, 480))),  # Downscale
    ops.map(lambda frame: yolo_detector.process_image(frame))
)

# Use GPU
yolo_detector = Yolo2DDetector(device="cuda")
```

### VLM Optimization

```python
# Local VLM (no API latency)
vlm_detector = VLMDetector(
    model="llava-1.5-7b",  # Run on Thor GPU
    api_key=None  # Local inference
)

# Batch queries (if VLM supports it)
frames_batch = video_stream.pipe(
    ops.buffer_with_time(10.0),  # Collect 10s worth
    ops.map(lambda frames: vlm.batch_detect(frames, "red ball"))
)

# Cache results (avoid re-querying)
from functools import lru_cache

@lru_cache(maxsize=100)
def cached_vlm_query(frame_hash, query):
    return vlm.detect(frame, query)
```

---

## Testing Strategy

### Unit Tests

```python
def test_yolo_detection():
    detector = Yolo2DDetector()
    frame = load_test_image("ball.jpg")
    bboxes, confidences, labels = detector.process_image(frame)
    assert "ball" in labels

def test_vlm_detection():
    detector = VLMDetector(model="mock")  # Mock VLM
    frame = load_test_image("red_ball.jpg")
    bbox, confidence = detector.detect(frame, "red ball")
    assert bbox is not None
    assert confidence > 0.5

def test_frame_transformation():
    detection = {"position": (2.0, 0.0, 0.5), "frame": "base_link"}
    detection_odom = transform_to_odom(detection)
    assert detection_odom["frame"] == "odom"
```

### Integration Tests

```python
def test_sequential_pipeline():
    perception = SequentialPerceptionStream(robot)
    stream = perception.create_stream("ball", "Is this ball red?")
    
    # Collect detections for 30 seconds
    detections = stream.pipe(
        ops.buffer_with_time(30.0),
        ops.take(1)
    ).run()
    
    # Verify pipeline worked
    assert len(detections) > 0
    assert all(det["verified"] for det in detections)

def test_adaptive_switching():
    perception = AdaptivePerceptionStream(robot)
    
    # Start in search phase
    assert perception.current_phase == MissionPhase.SEARCH
    
    # Trigger object found
    perception._on_object_found(mock_detection)
    assert perception.current_phase == MissionPhase.APPROACH
```

---

## Deployment Configuration

### Config File Pattern

```yaml
# config/perception.yaml
perception:
  mode: "sequential"  # parallel | sequential | adaptive
  
  yolo:
    model: "yolo11n.pt"
    confidence_threshold: 0.6
    device: "cuda"
    sample_rate_hz: 10.0
  
  vlm:
    model: "qwen-vl"
    api_key: "${QWEN_API_KEY}"
    sample_rate_hz: 0.2
    timeout_seconds: 10.0
  
  sequential:
    base_class: "ball"
    semantic_filter: "Is this ball red?"
    throttle_seconds: 2.0
  
  adaptive:
    search_query: "Find a red ball"
    approach_class: "ball"
    verify_query: "Is this a smooth red ball?"
    approach_distance_threshold: 1.5
```

### Launch File

```python
# shadowhound_bringup/launch/perception.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration

def generate_launch_description():
    return LaunchDescription([
        DeclareLaunchArgument('perception_mode', default_value='sequential'),
        DeclareLaunchArgument('yolo_model', default_value='yolo11n.pt'),
        
        Node(
            package='shadowhound_perception',
            executable='hybrid_perception_node',
            name='hybrid_perception',
            parameters=[{
                'mode': LaunchConfiguration('perception_mode'),
                'yolo_model': LaunchConfiguration('yolo_model'),
                'config_file': 'config/perception.yaml'
            }]
        )
    ])
```

---

## Conclusion

### Pattern Selection Guide

| Use Case | Pattern | Reason |
|----------|---------|--------|
| "Find any ball" | YOLO only | Fast, no semantics needed |
| "Find the RED ball" | **Sequential** | Efficient VLM verification |
| "Find ball OR person" | Parallel | Multiple object types |
| Complex mission | Adaptive | Optimize each phase |

### Recommended Starting Point

**For MVP**: **Sequential Pipeline**
- Start with YOLO only
- Add VLM verification when needed
- Simplest to implement and debug
- Good performance/accuracy tradeoff

### Next Steps

1. ✅ Implement VLMDetector class (wrap DIMOS Qwen)
2. ✅ Create SequentialPerceptionStream
3. ✅ Test on Go2 hardware
4. ⏸️ Add parallel/adaptive if needed

### Open Questions

- [ ] Which VLM to use? (Qwen API vs local LLaVA)
- [ ] VLM sample rate tuning? (balance latency vs accuracy)
- [ ] How to handle conflicting detections? (YOLO says ball, VLM says no)
- [ ] Frame synchronization tolerance? (how old can transforms be?)

---

## References

- **RxPY Documentation**: https://rxpy.readthedocs.io/
- **DIMOS ObjectDetectionStream**: `src/dimos-unitree/dimos/perception/object_detection_stream.py`
- **DIMOS Qwen Integration**: `src/dimos-unitree/dimos/models/qwen/video_query.py`
- **Related Docs**:
  - `local_planning_architecture.md` - Navigation system
  - `mvp_implementation_roadmap.md` - Implementation timeline
