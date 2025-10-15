---
tags: [mvp, roadmap, implementation, planning, dimos]
status: draft
related:
  - local_planning_architecture.md
  - hybrid_perception_architecture.md
  - persistent_intelligence_dimos_integration.md
  - ../project_overview/mvp_embodied_ai_platform.md
summary: >
  Revised MVP implementation roadmap leveraging local planning discovery. Shows how VFH local planner
  enables 1-week path to embodied AI missions (vs 2-3 weeks with SLAM). Defines concrete phases,
  deliverables, and success criteria.
---

# MVP Implementation Roadmap: Local Planning First Approach

## Executive Summary

**Critical Discovery**: DIMOS VFH local planner eliminates SLAM dependency for MVP.

**Revised Timeline**: **~1 week** to working embodied AI mission (vs 2-3 weeks with global planning)

**Key Phases**:
1. **MockRobot** (1-2 days) - Enable CI/CD
2. **Local Planning Validation** (2-3 days) - Test VFH on hardware  
3. **Perception Integration** (1-2 days) - Connect YOLO to navigation
4. **End-to-End Mission** (1 day) - "Find the ball" working

**Success Criteria**: Robot executes "Find the red ball" mission using camera perception + reactive navigation.

---

## Background: What Changed

### Original Plan (BLOCKED)

```
Week 1-2: Map environment with SLAM
    ↓
Week 2-3: Test Nav2 global planning
    ↓
Week 3-4: Add camera perception
    ↓
Week 4: End-to-end mission

Risk: SLAM + Nav2 untested, complex, high failure rate
Timeline: 3-4 weeks minimum
```

### New Plan (UNBLOCKED) ✅

```
Week 1: Test local planner + Add YOLO
    ↓
Week 1: End-to-end mission

Risk: Low (simpler stack, fewer dependencies)
Timeline: 1 week
```

### Why Local Planning First

**Benefits**:
- ✅ No mapping phase required
- ✅ No localization failures
- ✅ Simpler to test and debug
- ✅ More robust (reactive vs planned)
- ✅ Sufficient for object search missions

**Trade-offs**:
- ⚠️ Less optimal paths (reactive not planned)
- ⚠️ Odometry drift over long missions
- ⚠️ Can't return to specific locations

**MVP Verdict**: Benefits >> Trade-offs for "find object" missions

---

## Phase 0: MockRobot Foundation (1-2 days)

### Objective
Enable rapid development and CI/CD without hardware dependency.

### Deliverables

**1. MockRobot Class** (`shadowhound_robot/mock_robot.py`)
```python
class MockRobot:
    """Mock robot for testing without hardware."""
    
    def __init__(self):
        self.pose = {"x": 0.0, "y": 0.0, "theta": 0.0}
        self.local_planner = MockLocalPlanner()
        self.camera = MockCamera()
        self.lidar = MockLiDAR()
    
    def move_vel_control(self, x: float, y: float, yaw: float):
        """Mock velocity control (updates internal pose)."""
        self.pose["x"] += x * 0.1  # Simple integration
        self.pose["theta"] += yaw * 0.1
    
    def get_ros_video_stream(self) -> Observable:
        """Return mock video stream with test images."""
        return rx.interval(0.033).pipe(  # 30 FPS
            ops.map(lambda _: self.camera.get_frame())
        )
```

**2. MockLocalPlanner** (stub VFH interface)
```python
class MockLocalPlanner:
    def __init__(self):
        self.goal_xy = None
        self.goal_reached = False
    
    def set_goal(self, goal_xy, frame="odom"):
        self.goal_xy = goal_xy
        self.goal_reached = False
    
    def plan(self) -> Dict[str, float]:
        """Return mock velocity commands."""
        if self.goal_xy is None:
            return {"x_vel": 0.0, "angular_vel": 0.0}
        
        # Simple proportional controller
        dx = self.goal_xy[0] - robot.pose["x"]
        dy = self.goal_xy[1] - robot.pose["y"]
        distance = math.sqrt(dx**2 + dy**2)
        
        if distance < 0.2:
            self.goal_reached = True
            return {"x_vel": 0.0, "angular_vel": 0.0}
        
        return {"x_vel": 0.3, "angular_vel": math.atan2(dy, dx)}
    
    def is_goal_reached(self) -> bool:
        return self.goal_reached
```

**3. Pytest Fixtures** (`tests/conftest.py`)
```python
import pytest

@pytest.fixture
def mock_robot():
    """Provide MockRobot for tests."""
    return MockRobot()

@pytest.fixture
def mock_perception(mock_robot):
    """Provide mock perception stream."""
    return MockPerceptionStream(mock_robot)
```

**4. CI Workflow** (`.github/workflows/test.yml`)
```yaml
name: Unit Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov
      
      - name: Run unit tests
        run: |
          pytest tests/ --cov=shadowhound --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### Success Criteria
- ✅ MockRobot can be instantiated
- ✅ All existing tests pass with MockRobot
- ✅ CI workflow runs on every commit
- ✅ Test coverage > 80%

### Effort Estimate
- **Time**: 1-2 days
- **Resources**: 1 developer
- **Blockers**: None

---

## Phase 1: Local Planning Validation (2-3 days)

### Objective
Validate VFH local planner works on Go2 hardware with real LiDAR.

### Prerequisites
- [ ] go2_ros2_sdk publishing `/local_costmap/costmap`
- [ ] `/odom` topic available
- [ ] `/cmd_vel` topic connected
- [ ] Go2 battery charged, safe test environment

### Test Scenarios

**Test 1: Straight Line Navigation**
```python
# Goal: Drive forward 2 meters
robot.local_planner.set_goal((2.0, 0.0), frame="base_link")
success = navigate_to_goal_local(robot, (2.0, 0.0), timeout=20.0)
assert success

# Validate
final_distance = calculate_distance(robot.pose, (2.0, 0.0))
assert final_distance < 0.3  # Within 30cm
```

**Test 2: Obstacle Avoidance**
```python
# Place obstacle between robot and goal
# Goal: Navigate around obstacle
robot.local_planner.set_goal((2.0, 0.0), frame="base_link")
success = navigate_to_goal_local(robot, (2.0, 0.0), timeout=30.0)
assert success
assert no_collisions_detected()  # Robot avoided obstacle
```

**Test 3: Goal in Multiple Frames**
```python
# Test frame transformations work
robot.local_planner.set_goal((2.0, 1.0), frame="base_link")  # Robot frame
robot.local_planner.set_goal((5.0, 3.0), frame="odom")       # Odom frame

# Both should navigate correctly
```

**Test 4: Recovery Behavior**
```python
# Place robot in corner (trapped)
# Goal: Recovery behavior activates
robot.local_planner.set_goal((2.0, 0.0), frame="base_link")

# Robot should:
# 1. Detect stuck condition
# 2. Execute recovery (rotate in place)
# 3. Either escape or timeout gracefully
```

**Test 5: Dynamic Obstacles**
```python
# Human walks in front of robot
# Goal: Robot stops and waits
robot.local_planner.set_goal((3.0, 0.0), frame="base_link")

# Robot should:
# 1. Navigate toward goal
# 2. Stop when human appears
# 3. Resume when path clears
```

### Parameter Tuning

**Initial Parameters**:
```python
VFHPurePursuitPlanner(
    safety_threshold=0.8,      # 80cm from obstacles
    max_linear_vel=0.5,        # Conservative speed
    max_angular_vel=1.0,       # ~60°/s
    lookahead_distance=1.0,    # 1m lookahead
    goal_tolerance=0.2,        # 20cm goal accuracy
    control_frequency=10.0,    # 10 Hz control
)
```

**Tuning Process**:
1. Start conservative (slow speeds, large margins)
2. Run test scenarios
3. Adjust parameters based on behavior:
   - Too cautious? Reduce `safety_threshold`, increase `max_linear_vel`
   - Oscillating? Increase `lookahead_distance`
   - Overshooting? Reduce `goal_tolerance`

### Telemetry Collection

**Log Data**:
```python
# For each navigation attempt, log:
{
    "timestamp": "2025-10-14T10:30:00Z",
    "test_id": "straight_line_2m",
    "success": True,
    "duration_seconds": 12.3,
    "distance_traveled": 2.1,
    "final_error_meters": 0.15,
    "recovery_activations": 0,
    "parameters": {
        "safety_threshold": 0.8,
        "max_linear_vel": 0.5,
        # ...
    }
}
```

**Analysis**:
- Success rate per scenario
- Average navigation time
- Parameter sensitivity analysis

### Success Criteria
- ✅ 90%+ success rate on all test scenarios
- ✅ No collisions during testing
- ✅ Recovery behaviors work correctly
- ✅ Frame transformations validated
- ✅ Parameters documented and tuned

### Effort Estimate
- **Time**: 2-3 days
- **Resources**: 1 developer + Go2 hardware
- **Blockers**: go2_ros2_sdk local costmap availability

---

## Phase 2: Perception Integration (1-2 days)

### Objective
Connect YOLO object detection to local planning navigation.

### Architecture

```
Video Stream (30 FPS)
    ↓
YOLO Detector (10 FPS sampling)
    ↓
Metric3D Depth Estimation
    ↓
3D Position Calculation (base_link)
    ↓
Transform to Odom Frame
    ↓
Local Planner Goal Setting
    ↓
VFH Navigation
```

### Implementation

**1. ObjectDetectionStream Setup**
```python
# shadowhound_perception/object_detection_node.py
from dimos.perception.object_detection_stream import ObjectDetectionStream
from dimos.perception.detection2d.yolo_2d_det import Yolo2DDetector

class PerceptionNode(Node):
    def __init__(self):
        super().__init__('perception_node')
        
        # Initialize YOLO detector
        self.detector = Yolo2DDetector(
            model="yolo11n.pt",  # Nano model for speed
            device="cuda",
            threshold=0.6
        )
        
        # Create detection stream
        self.detection_stream = ObjectDetectionStream(
            detector=self.detector,
            camera_intrinsics=robot.camera_intrinsics,
            transform_to_map=robot.ros_control.transform_pose,
            video_stream=robot.get_ros_video_stream()
        ).get_stream()
        
        # Subscribe to detections
        self.detection_stream.pipe(
            ops.sample(0.1),  # 10 FPS
        ).subscribe(
            on_next=self.on_detection,
            on_error=self.on_error
        )
    
    def on_detection(self, detection):
        """Handle new detection."""
        objects = detection.get("objects", [])
        
        # Filter for target class
        target_objects = [obj for obj in objects if obj["label"] == self.target_class]
        
        if target_objects:
            # Navigate to closest object
            closest = min(target_objects, key=lambda obj: obj["position"]["distance"])
            self.navigate_to_object(closest)
    
    def navigate_to_object(self, obj):
        """Navigate to detected object."""
        position = obj["position"]
        
        # Set goal in odom frame (already transformed)
        self.robot.local_planner.set_goal(
            (position["x"], position["y"]),
            frame="odom"
        )
```

**2. Frame Validation Tests**
```python
def test_frame_transformation():
    """Validate detections transform correctly."""
    # Mock detection in base_link
    detection_base_link = {
        "position": {"x": 2.0, "y": 0.0, "z": 0.5},
        "frame": "base_link"
    }
    
    # Transform to odom
    detection_odom = transform_detection(detection_base_link, "odom")
    
    # Validate
    assert detection_odom["frame"] == "odom"
    assert detection_odom["position"]["x"] > 0  # Forward in odom

def test_detection_to_navigation():
    """Test full pipeline: detection → navigation."""
    # Place object at known position
    object_pos_base_link = (2.0, 1.0)
    
    # Detect object
    detections = yolo_stream.pipe(ops.take(1)).run()
    assert len(detections["objects"]) > 0
    
    # Verify position accuracy
    detected_pos = detections["objects"][0]["position"]
    error = calculate_distance(detected_pos, object_pos_base_link)
    assert error < 0.5  # Within 50cm (depth estimation error)
```

**3. Integration Test (Real Hardware)**
```bash
# Terminal 1: Launch robot + perception
ros2 launch shadowhound_bringup perception.launch.py

# Terminal 2: Place ball 2m in front of robot

# Terminal 3: Trigger detection
ros2 topic pub /perception/target_class std_msgs/String "data: 'ball'"

# Expected:
# 1. YOLO detects ball
# 2. Position calculated: (2.0, 0.0) in odom
# 3. Local planner set_goal((2.0, 0.0))
# 4. Robot navigates to ball
# 5. Stops within 1m of ball
```

### Success Criteria
- ✅ YOLO detections appear in stream (10 FPS)
- ✅ Depth estimation working (< 20% error)
- ✅ Frame transforms correct (detection → odom)
- ✅ Navigation starts when object detected
- ✅ Robot reaches object (within 1m)

### Effort Estimate
- **Time**: 1-2 days
- **Resources**: 1 developer + Go2 hardware
- **Blockers**: Phase 1 completion

---

## Phase 3: End-to-End Mission (1 day)

### Objective
Demonstrate complete embodied AI mission: "Find the red ball"

### Mission Specification

**Natural Language**: "Find the red ball"

**Decomposition**:
1. **Search**: Rotate and scan environment with camera
2. **Detect**: YOLO finds "ball" candidates
3. **Verify**: VLM confirms "red" (optional for MVP)
4. **Navigate**: Local planner drives to ball
5. **Stop**: Stop within 1m of ball
6. **Report**: Confirm mission success

### Implementation

**Option A: YOLO Only (MVP Minimum)**
```python
class FindBallMission:
    def __init__(self, robot):
        self.robot = robot
        self.target_class = "ball"
        self.found = False
    
    def execute(self):
        # Phase 1: Search (rotate 360°)
        logger.info("Searching for ball...")
        self.rotate_and_scan()
        
        # Phase 2: Detect + Navigate
        detection_stream = self.create_detection_stream()
        detection_stream.pipe(
            ops.take(1)  # First detection
        ).subscribe(
            on_next=self.navigate_to_object,
            on_error=self.on_failure
        )
        
        # Wait for completion
        timeout = 60.0
        start_time = time.time()
        while not self.found and time.time() - start_time < timeout:
            time.sleep(0.1)
        
        if self.found:
            logger.info("Mission complete: Ball found!")
            return True
        else:
            logger.error("Mission failed: Ball not found")
            return False
    
    def rotate_and_scan(self):
        """Rotate 360° to scan for objects."""
        for angle in range(0, 360, 45):  # 45° increments
            self.robot.local_planner.set_goal(
                (0.0, 0.0),  # Don't move
                goal_theta=math.radians(angle)
            )
            time.sleep(2)  # Wait for rotation
    
    def navigate_to_object(self, detection):
        """Navigate to detected object."""
        logger.info(f"Ball detected at {detection['position']}")
        
        success = navigate_to_goal_local(
            self.robot,
            goal_xy_robot=(detection["position"]["x"], 
                          detection["position"]["y"]),
            distance=1.0,  # Stop 1m away
            timeout=30.0
        )
        
        self.found = success
```

**Option B: YOLO + VLM (Better)**
```python
class FindRedBallMission:
    def execute(self):
        # Phase 1: YOLO finds "ball" candidates
        yolo_stream = self.create_yolo_stream(target_class="ball")
        
        # Phase 2: VLM verifies "red"
        verified_stream = yolo_stream.pipe(
            ops.sample(2.0),  # Throttle VLM
            ops.map(lambda det: self.verify_with_vlm(det, "Is this ball red?")),
            ops.filter(lambda det: det["verified"])
        )
        
        # Phase 3: Navigate to verified red ball
        verified_stream.pipe(ops.take(1)).subscribe(
            on_next=self.navigate_to_object
        )
```

### Test Protocol

**Setup**:
1. Place red ball 3m in front of robot
2. Add distractors (blue ball, yellow ball)
3. Clear obstacles in path

**Execution**:
```bash
# Launch system
ros2 launch shadowhound_bringup full_stack.launch.py

# Send mission
ros2 service call /mission/execute shadowhound_interfaces/srv/ExecuteMission \
  "command: 'Find the red ball'"
```

**Expected Behavior**:
1. Robot rotates to scan environment (5-10 seconds)
2. YOLO detects balls (blue, yellow, red)
3. VLM verifies red ball (optional)
4. Local planner navigates to red ball (10-15 seconds)
5. Robot stops 1m from red ball
6. Mission reports success

**Success Metrics**:
- Mission completion time: < 30 seconds
- Navigation accuracy: Within 1m of ball
- Success rate: > 90% (10 trials)

### Edge Cases to Test

1. **No object found**: Robot rotates 360°, reports failure
2. **Object out of reach**: Robot navigates as close as possible, reports partial success
3. **Multiple objects**: Robot navigates to closest one
4. **Object moves**: Robot re-detects and updates goal
5. **Path blocked**: Local planner avoids obstacle, finds alternate path

### Success Criteria
- ✅ Mission completes in < 30 seconds
- ✅ Robot finds correct object (red ball, not distractors)
- ✅ Navigation successful (reaches within 1m)
- ✅ No collisions during mission
- ✅ Success rate > 90% over 10 trials

### Effort Estimate
- **Time**: 1 day
- **Resources**: 1 developer + Go2 hardware
- **Blockers**: Phase 1 and 2 completion

---

## Phase 4: VLM Integration (Optional, +1-2 days)

### Objective
Add semantic reasoning to handle nuanced queries.

### Use Cases
- "Find the RED ball" (not just any ball)
- "Find the person in the blue shirt" (specific person)
- "Find the open door" (state reasoning)

### Implementation
See `hybrid_perception_architecture.md` for detailed patterns.

**Quick Integration** (use existing DIMOS code):
```python
from dimos.models.qwen.video_query import get_bbox_from_qwen_frame

def verify_with_vlm(detection, query: str) -> bool:
    """Verify detection with VLM."""
    frame = detection["frame"]
    bbox = detection["bbox"]
    
    # Crop to object
    x1, y1, x2, y2 = map(int, bbox)
    roi = frame[y1:y2, x1:x2]
    
    # Query Qwen VLM
    vlm_bbox, confidence = get_bbox_from_qwen_frame(roi, object_name=query)
    
    # If VLM finds object in ROI, verification succeeds
    return vlm_bbox is not None and confidence > 0.5
```

### Effort Estimate
- **Time**: 1-2 days
- **Resources**: 1 developer
- **Blockers**: Phase 3 completion
- **Priority**: Optional for MVP

---

## Timeline Summary

### Week 1: Core MVP

| Day | Phase | Deliverable | Status |
|-----|-------|-------------|--------|
| 1 | MockRobot | CI/CD enabled | Not started |
| 2 | MockRobot | Tests passing | Not started |
| 3 | Local Planning | VFH validated on hardware | Not started |
| 4 | Local Planning | Parameters tuned | Not started |
| 5 | Perception | YOLO → Navigation working | Not started |
| 6 | Perception | Frame transforms validated | Not started |
| 7 | End-to-End | "Find the ball" mission working | Not started |

**Deliverable**: Working embodied AI mission (YOLO + local planning)

---

### Week 2: Refinement (Optional)

| Day | Phase | Deliverable | Status |
|-----|-------|-------------|--------|
| 1-2 | VLM | Semantic verification working | Optional |
| 3-4 | Mission Agent | Natural language interface | Optional |
| 5 | Documentation | User guide, demos | Optional |

**Deliverable**: Enhanced mission with VLM reasoning

---

## Risk Assessment

### High Risk Items

**1. go2_ros2_sdk Local Costmap** 
- **Risk**: May not publish `/local_costmap/costmap`
- **Impact**: VFH planner can't run (blocks Phase 1)
- **Mitigation**: Check go2_ros2_sdk source, generate costmap from /scan if needed
- **Probability**: Medium (30%)

**2. Frame Transform Errors**
- **Risk**: base_link → odom transforms incorrect
- **Impact**: Robot navigates to wrong position
- **Mitigation**: Extensive frame validation tests in Phase 2
- **Probability**: Medium (40%)

**3. Depth Estimation Accuracy**
- **Risk**: Metric3D depth errors > 50cm
- **Impact**: Goal positions inaccurate
- **Mitigation**: Calibrate depth model, use stereo if available
- **Probability**: Low (20%)

### Medium Risk Items

**4. VFH Parameter Tuning**
- **Risk**: Default parameters don't work well
- **Impact**: Navigation jittery or fails
- **Mitigation**: Systematic tuning in Phase 1
- **Probability**: High (60%), low impact

**5. YOLO False Positives**
- **Risk**: Detects wrong objects
- **Impact**: Navigates to wrong target
- **Mitigation**: Add VLM verification
- **Probability**: Medium (30%)

### Low Risk Items

**6. Odometry Drift**
- **Risk**: Odom frame drifts over time
- **Impact**: Position errors accumulate
- **Mitigation**: Short missions (< 1 min), visual goal updates
- **Probability**: Low (10% for MVP missions)

---

## Success Metrics

### MVP Success Criteria (Must Have)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Mission Success Rate** | > 90% | 10 trials, "Find the ball" |
| **Navigation Accuracy** | < 1m error | Final distance to object |
| **Mission Duration** | < 30 seconds | Time to completion |
| **Collision Rate** | 0% | No collisions in 10 trials |
| **Code Coverage** | > 80% | Pytest coverage report |

### Quality Metrics (Nice to Have)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Detection Latency** | < 200ms | Frame → navigation goal |
| **Path Efficiency** | > 70% | Actual distance / straight line distance |
| **Recovery Success** | > 80% | Successful escapes from stuck |
| **Frame Transform Accuracy** | < 10cm | Detection position error |

---

## Hardware Requirements

### Minimum

- ✅ Unitree Go2 robot
- ✅ Laptop with ROS2 (Ubuntu 22.04)
- ✅ Wi-Fi connection to Go2
- ✅ Test environment (5m x 5m clear space)
- ✅ Test objects (colored balls, boxes)

### Optional (Improved Performance)

- ⏸️ External GPU (for VLM on laptop)
- ⏸️ Better depth camera (Intel RealSense)
- ⏸️ Motion capture system (ground truth validation)

---

## Deliverables

### Code

- [ ] `shadowhound_robot/mock_robot.py` - MockRobot implementation
- [ ] `shadowhound_perception/object_detection_node.py` - Perception node
- [ ] `shadowhound_mission/find_ball_mission.py` - Mission implementation
- [ ] `tests/` - Unit and integration tests
- [ ] Launch files for all phases

### Documentation

- [ ] `docs/guides/local_planning_quickstart.md` - Setup guide
- [ ] `docs/guides/perception_integration.md` - Integration guide
- [ ] `docs/guides/mission_creation.md` - Creating new missions
- [ ] Video demos of working missions

### Data

- [ ] Telemetry logs from Phase 1 testing
- [ ] Parameter tuning results
- [ ] Benchmark results (success rate, timing)

---

## Next Steps After MVP

### Phase 2: Advanced Capabilities (2-3 weeks)

**Global Planning Integration**
- Add Nav2 + SLAM for multi-room navigation
- Return to dock capability
- Persistent location memory

**VLM Enhancement**
- Local VLM deployment (LLaVA on Thor GPU)
- Advanced semantic reasoning
- Multi-step verification

**Mission Agent**
- Natural language mission interface
- Mission planning and decomposition
- Telemetry and logging

### Phase 3: Persistent Intelligence (4-6 weeks)

**Trajectory Logging**
- Log all decisions and outcomes
- WAL (Write-Ahead Logging) for durability
- Message contracts for data consistency

**Learning Loop**
- Offline analysis of trajectories
- Adapt parameters based on outcomes
- Test improvements in Isaac Sim

**Multi-Brain Deployment**
- Thor (mobile brainstem)
- Spark (cortex for learning)
- Tower (simulation/testing)

See `persistent_intelligence_dimos_integration.md` for details.

---

## Conclusion

### Key Takeaways

1. **Local planning is sufficient for MVP** - No SLAM required
2. **Timeline dramatically reduced** - 1 week vs 2-3 weeks
3. **Lower risk** - Simpler stack, fewer dependencies
4. **Clear path forward** - Well-defined phases and deliverables

### Decision Points

**After Phase 1** (Local Planning Validation):
- ✅ Continue to Phase 2 if VFH works well
- ⏸️ Debug/tune if navigation issues
- ⚠️ Fallback to global planning if critical issues

**After Phase 3** (End-to-End Mission):
- ✅ Ship MVP if success rate > 90%
- ⏸️ Add VLM if semantic reasoning needed
- ⏸️ Add global planning if multi-room needed

### Open Questions

- [ ] Does go2_ros2_sdk provide local costmap?
- [ ] What is costmap update rate?
- [ ] Camera calibration parameters available?
- [ ] Depth camera quality sufficient?
- [ ] VLM API keys / rate limits?

---

## References

- **Local Planning Architecture**: `local_planning_architecture.md`
- **Hybrid Perception**: `hybrid_perception_architecture.md`
- **Persistent Intelligence**: `persistent_intelligence_dimos_integration.md`
- **Original MVP**: `../project_overview/mvp_embodied_ai_platform.md`
- **DIMOS Documentation**: `src/dimos-unitree/docs/`
