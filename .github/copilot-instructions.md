# ShadowHound AI Coding Agent Instructions

## Project Context

ShadowHound is an autonomous mobile robot system combining ROS2 navigation with LLM/VLM-driven planning. You're working on a **Unitree Go2 quadruped** that executes natural language missions through DIMOS framework integration.

**Current State**: WORKING END-TO-END SYSTEM
- ✅ Physical robot validated (Unitree Go2)
- ✅ Two LLM backends proven (OpenAI cloud + vLLM Thor)
- ✅ Mission agent implemented (~2,100 LOC)
- ⚠️ WebRTC API issues limit available skills

**Active Blockers**: 
- WebRTC API skills (majority of DIMOS skills non-functional)
- MockRobot not implemented (needed for dev velocity)

---

## **CRITICAL: MVP Roadmap is Source of Truth** 🎯

### YOU MUST READ AND PROTECT THE MVP ROADMAP

**Before starting ANY significant work**:
1. **READ**: `docs/project_overview/mvp_embodied_ai_platform.md` (MVP roadmap - SOURCE OF TRUTH)
2. **READ**: `docs/project_overview/MVP_PROTECTION_POLICY.md` (how to protect scope)
3. Extract: MVP scope, current milestone, success criteria, constraints

**Purpose**: This roadmap defines project scope after comprehensive requirements gathering. Without it, scope becomes confused and shifts unintentionally (historical problem).

**When proposing changes to the roadmap**:
1. ❌ **DO NOT** edit automatically
2. ✅ **DO** explain proposed change clearly
3. ✅ **DO** explain WHY it's needed  
4. ✅ **DO** show impact on scope/milestones
5. ✅ **WAIT** for explicit user approval

**When detecting scope creep**:
```
⚠️  SCOPE ALERT: This request would add [X] to MVP scope.
Current MVP: [list 5 core capabilities]
Proposed addition: [describe]
Impact: [timeline/complexity/risk]
Recommendation: Add to Future Work instead?
```

**Exception**: Typo fixes and factual corrections (e.g., sensor specs) can be made but should be noted in commit.

---

## **CRITICAL: Devlog Requirements** 📝

### YOU MUST UPDATE THE DEVLOG

**Before starting work**:
1. Read `docs/development/recent_work.md` (last 5 days context)
2. Check `docs/development/devlog.md` (recent entries)
3. Verify you understand current system state

**After completing significant work** (REQUIRED):
1. Run: `./scripts/add-devlog-entry.sh` (interactive)
2. Or manually add entry to `docs/development/devlog.md`
3. Follow the template (Type, Status, Impact, Activities, Commits, Decisions)
4. Commit with message: `docs(devlog): [your activity title]`

**What counts as "significant work"**:
- ✅ Feature complete (any new functionality)
- ✅ PR merged (document what was merged)
- ✅ Major fix (bugs that required investigation)
- ✅ Architectural decision (design choice affecting future work)
- ✅ Integration work (connecting systems/components)
- ✅ End of work session (daily summary)

**Failure to update devlog = incomplete work**

Example entry format:
```markdown
## 2025-10-13 (Sunday)

### 14:00-18:00: DIMOS Integration Merge
**Type**: Integration  
**PR/Issue**: #21  
**Status**: ✅ Complete  
**Impact**: DIMOS validated on physical robot, major milestone

**Activities**:
- Merged feature/dimos-integration branch
- Validated on Unitree Go2 hardware
- Documented network architecture

**Commits**: 
- `f16bda8` - Feature branch merge

**Decisions**:
- Validate on hardware before merging (de-risks architecture changes)

**Notes**: Working end-to-end with physical robot
```

---

## **CRITICAL: Development Environment Setup**

### Network Architecture
```
Desktop (VS Code) ←─────→ Laptop (Host: 192.168.10.167) ←─────→ Thor (Jetson: 192.168.10.116)
     │                         │                                        │
     │                         ├─ ROS2 nodes (host)                   ├─ vLLM container (port 8000)
     │                         ├─ Mission agent (host)                 ├─ Go2 SDK (if needed)
     │                         └─ /home/daniel/shadowhound/            └─ Models cached
     │
     └─ VS Code Remote SSH
        Editing: /workspaces/shadowhound/ (devcontainer)
        BUT Code runs from: /home/daniel/shadowhound/ (laptop host)
```

### **FILE PATH CRITICAL WARNING** ⚠️
- **You edit files in:** `/workspaces/shadowhound/` (devcontainer - for git, tools, editing)
- **Code actually runs from:** `/home/daniel/shadowhound/` (laptop host - what Python executes)
- **ALWAYS check both paths when debugging runtime errors!**
- **Error tracebacks will show:** `/home/daniel/shadowhound/...` (not `/workspaces/...`)

### When Making Code Changes:
1. ✅ Edit in `/workspaces/shadowhound/` (devcontainer) - git works here
2. ✅ Commit and push changes
3. ⚠️ **Verify host has same changes:** Check `/home/daniel/shadowhound/` if runtime errors persist
4. ⚠️ **Rebuild on host if needed:** User runs `./start.sh` on laptop host, not in devcontainer

### Why This Matters:
- Python cache (`.pyc`, `__pycache__`) may differ between devcontainer and host
- Submodule commits may not be synced between paths
- Build artifacts (`install/`, `build/`) are on the host
- ROS2 runs on the host, not in devcontainer

### Git Submodules (Not vcs!)
**IMPORTANT:** This project uses **git submodules**, not vcstool (.repos files).

- DIMOS is a git submodule: `src/dimos-unitree/`
- To sync: `git submodule update --init --recursive`
- Never edit submodule files directly (see `docs/policies/submodule_policy.md`)
- AI agents: Use standard git submodule commands

---

## Architecture Quick Reference

### Four-Layer Stack
```
Application  → Launch files, configs, deployment
Agent        → LLM/VLM orchestration, mission planning (DIMOS)
Skills       → Execution engine (DIMOS MyUnitreeSkills ~30 behaviors)
Robot        → ROS2 bridge to go2_ros2_sdk hardware
```

### Package Map
- `shadowhound_interfaces/` - Custom ROS2 messages/services/actions
- `shadowhound_mission_agent/` - Mission agent + web UI (~2,100 LOC implemented)
- `shadowhound_bringup/` - Launch files and configurations
- `src/dimos-unitree/` - DIMOS framework (git submodule)

### Key Principles
1. **DIMOS-First**: Skills exist in DIMOS MyUnitreeSkills, leverage them
2. **Safety-First**: Every skill has timeout, validation, and error handling
3. **Container-First**: All development in devcontainer
4. **Type-First**: Use type hints, validate inputs, return structured results
5. **Devlog-First**: Document all significant work in devlog

---

## Development Workflow

### Standard Commands (Available in Devcontainer)
```bash
cb              # colcon build --symlink-install
source-ws       # source install/setup.bash
rosdep-install  # install ROS dependencies
cbt             # colcon test
cbr             # build and source
```

### Creating a New Package
```bash
cd src/
ros2 pkg create --build-type ament_python \
    --dependencies rclpy std_msgs \
    shadowhound_<name>

# Then: Edit package.xml, setup.py, implement nodes
cb --packages-select shadowhound_<name>
source-ws
```

### Testing Pattern
```python
# In test/test_<module>.py
import pytest
from shadowhound_skills import SkillRegistry

def test_skill_registration():
    skill = SkillRegistry.get("nav.rotate")
    assert skill is not None

def test_skill_execution():
    result = SkillRegistry.execute("nav.rotate", yaw=1.57)
    assert result.success == True
```

Run with: `pytest src/<package>/test/`

---

## Skills API Patterns

### Skill Implementation Template
```python
# In shadowhound_skills/skills/<category>.py
from shadowhound_skills.skill_base import Skill, SkillResult
from shadowhound_skills.skill_registry import register_skill

@register_skill("category.action_name")
class ActionSkill(Skill):
    """Brief description of what this skill does."""
    
    # Define parameters with types
    timeout: float = 30.0
    max_retries: int = 3
    
    def validate_params(self, **kwargs) -> tuple[bool, str]:
        """Validate input parameters before execution."""
        # Check required params exist and are valid
        if "param" not in kwargs:
            return False, "Missing required parameter 'param'"
        return True, ""
    
    def execute(self, **kwargs) -> SkillResult:
        """Execute the skill with safety and telemetry."""
        # 1. Validate
        valid, error = self.validate_params(**kwargs)
        if not valid:
            return SkillResult(success=False, error=error)
        
        # 2. Execute with timeout
        try:
            # Do the work
            result_data = self._do_work(**kwargs)
            
            # 3. Return structured result
            return SkillResult(
                success=True,
                data=result_data,
                telemetry={"duration_ms": 100}
            )
        except Exception as e:
            return SkillResult(success=False, error=str(e))
    
    def _do_work(self, **kwargs):
        """Internal implementation - interacts with robot interface."""
        # Access robot via self.robot_interface
        pass
```

### Calling Skills
```python
# From agent or test code
from shadowhound_skills import SkillRegistry

result = SkillRegistry.execute(
    "nav.goto",
    x=1.0, y=2.0, yaw=0.0,
    timeout=20.0
)

if result.success:
    print(f"Navigation complete: {result.data}")
else:
    print(f"Navigation failed: {result.error}")
```

---

## Robot Interface Patterns

### Accessing Robot State
```python
# In shadowhound_robot/robot_interface.py
class RobotInterface:
    """Bridge to go2_ros2_sdk topics/services."""
    
    def get_pose(self) -> tuple[float, float, float]:
        """Get current robot pose (x, y, yaw)."""
        # Subscribe to /odom, return latest
        pass
    
    def publish_velocity(self, linear: float, angular: float):
        """Publish velocity command (with safety clamps)."""
        # Clamp values to safe ranges
        linear = np.clip(linear, -0.5, 0.5)
        angular = np.clip(angular, -1.0, 1.0)
        # Publish to /cmd_vel
        pass
    
    def get_camera_image(self) -> np.ndarray:
        """Get latest camera image."""
        # Subscribe to /camera/compressed, decompress
        pass
```

### Skills Use Robot Interface
```python
# Skills never publish directly - they use RobotInterface
@register_skill("nav.rotate")
class RotateSkill(Skill):
    def execute(self, yaw: float) -> SkillResult:
        robot = self.get_robot_interface()
        
        start_yaw = robot.get_pose()[2]
        target_yaw = start_yaw + yaw
        
        # Control loop with timeout
        while not self.is_at_target(robot.get_pose()[2], target_yaw):
            robot.publish_velocity(linear=0.0, angular=0.3)
            if self.timeout_exceeded():
                return SkillResult(success=False, error="Timeout")
        
        robot.publish_velocity(0.0, 0.0)  # Stop
        return SkillResult(success=True)
```

---

## Agent Integration Patterns

### LLM Client Setup
```python
# In shadowhound_agent/models/llm_client.py
from openai import OpenAI

class LLMClient:
    def __init__(self, model: str = "gpt-4-turbo"):
        self.client = OpenAI()
        self.model = model
    
    def plan_mission(self, instruction: str) -> list[dict]:
        """Convert natural language to skill plan."""
        prompt = f"""Given the instruction: "{instruction}"
        Generate a sequence of skills to execute.
        
        Available skills: nav.goto, nav.rotate, perception.snapshot, report.say
        
        Return JSON list of skill calls."""
        
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"}
        )
        
        return json.loads(response.choices[0].message.content)
```

### Plan Execution
```python
# In shadowhound_agent/plan_executor.py
class PlanExecutor:
    def execute_plan(self, plan: list[dict]) -> bool:
        """Execute sequence of skill calls."""
        for step in plan:
            skill_name = step["name"]
            params = step.get("args", {})
            
            result = SkillRegistry.execute(skill_name, **params)
            
            if not result.success:
                self.logger.error(f"Skill {skill_name} failed: {result.error}")
                return False
            
            # Publish telemetry
            self.publish_step_result(step, result)
        
        return True
```

---

## Common Patterns & Anti-Patterns

### ✅ DO: Skills API
```python
# Good - type-safe, validated, telemetered
result = SkillRegistry.execute("nav.goto", x=1.0, y=2.0, yaw=0.0)
```

### ❌ DON'T: Direct ROS Publishing
```python
# Bad - no validation, no safety, no telemetry
cmd_vel_pub.publish(Twist(linear=Vector3(x=1.0)))
```

### ✅ DO: Structured Results
```python
return SkillResult(
    success=True,
    data={"distance_traveled": 5.2, "time_elapsed": 10.3},
    telemetry={"cpu_usage": 45.2}
)
```

### ❌ DON'T: Bare Returns
```python
return True  # Lost information!
```

### ✅ DO: Safety Validation
```python
def validate_params(self, x: float, y: float) -> tuple[bool, str]:
    if abs(x) > 10.0 or abs(y) > 10.0:
        return False, "Position out of safe bounds"
    return True, ""
```

### ❌ DON'T: Assume Valid Input
```python
def execute(self, x, y):
    # No checks - could crash or damage robot
    robot.move_to(x, y)
```

---

## Configuration & Environment

### Key Environment Variables
```bash
ROS_DOMAIN_ID=42                 # Isolated ROS network
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
GO2_IP=192.168.1.103             # Robot IP address
AGENT_BACKEND=cloud              # or 'local'
OPENAI_API_KEY=sk-...            # For cloud LLM
```

### Launch File Pattern
```python
# In shadowhound_bringup/launch/skills.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package='shadowhound_skills',
            executable='skill_server',
            name='skill_server',
            parameters=[{
                'timeout_default': 30.0,
                'max_retries': 3,
            }]
        ),
    ])
```

---

## Phase-Specific Guidance

### Phase 0 (CURRENT): Bootstrap
**Focus**: Create package structure without hardware

**Tasks**:
1. Create `shadowhound_interfaces` with custom msgs/srvs
2. Create `shadowhound_robot` skeleton (stubs for now)
3. Create `shadowhound_skills` with registry + 2 basic skills
4. Create `shadowhound_agent` skeleton
5. Create `shadowhound_bringup` with launch files

**Testing**: Verify builds with `cb`, run unit tests with `pytest`

### Phase 1 (NEXT): Basic Skills
**Focus**: Implement testable skills without robot

**Skills to Implement**:
- `report.say(text)` - Log or TTS
- `nav.stop()` - Set velocity to zero
- `nav.rotate(yaw)` - Simple rotation mock
- `perception.snapshot()` - Capture test image

**Testing**: CLI skill execution, unit tests with mocks

---

## Troubleshooting

### Build Issues
```bash
# Clean build
rm -rf build install log
cb

# Check package dependencies
rosdep check --from-paths src --ignore-src

# Install missing deps
rosdep-install
```

### Import Errors
```bash
# Make sure workspace is sourced
source-ws

# Check Python path
python3 -c "import sys; print('\n'.join(sys.path))"

# Verify package installation
ros2 pkg list | grep shadowhound
```

### ROS Communication Issues
```bash
# Check ROS environment
printenv | grep ROS

# List active topics
ros2 topic list

# Monitor topic
ros2 topic echo /shadowhound/status
```

---

## Code Quality Requirements

### Required for All Python Code
- **Type hints**: All function signatures
- **Docstrings**: Google style for public APIs
- **Error handling**: Try/except with specific exceptions
- **Logging**: Use ROS logging (self.get_logger())
- **Testing**: Unit tests for all skills

### Pre-commit Checks (Automated)
```bash
# Format code
black src/shadowhound_*/shadowhound_*/ --line-length 99
isort src/shadowhound_*/shadowhound_*/

# Lint
flake8 src/shadowhound_*/shadowhound_*/ --max-line-length 99
pylint src/shadowhound_*/shadowhound_*/

# Type check
mypy src/shadowhound_*/shadowhound_*/
```

---

## Quick Reference

### File Locations
- Architecture: `docs/project.md`
- User guide: `README.md`
- Interfaces: `src/shadowhound_interfaces/`
- Skills: `src/shadowhound_skills/shadowhound_skills/skills/`
- Tests: `src/<package>/test/`

### Getting Help
- ROS2 Docs: https://docs.ros.org/en/humble/
- Project Context: `docs/project.md` (read this first!)
- Package README: Each package has README.md with details

---

**Remember**: Always check `docs/project.md` for the latest architecture and phase status before starting new work.

---

## Documentation Guidelines

### Standard Markdown Authoring
- Author docs inside `/docs` using the required YAML front-matter:
  ```
  ---
  tags: [topic, component]
  status: draft
  related: []
  summary: >
    One-line summary.
  ---
  ```
- Use **standard Markdown links** (e.g., `[ROS2 Setup](../software/ros2_setup.md)`) for internal references. These work directly on GitHub.com, GitHub Pages, and the Wiki.
- Store images and other media in `docs/_assets/` and embed them with standard Markdown syntax (`![](_assets/image.png)`).

### Obsidian Graph View (Optional)
- To view documentation in Obsidian with graph visualization, run `./scripts/generate_obsidian_vault.sh`
- This generates `docs_obs/` (gitignored) with wikilinks for Obsidian viewing
- The generated vault includes the committed `.obsidian/` configuration for graph view colors and layout
- Regenerate the vault after pulling documentation changes
- See `docs/tools/obsidian/` for complete documentation

### Rendering on GitHub Surfaces
- Documentation is authored in standard Markdown and used directly by MkDocs and the Wiki
- Do **not** commit the generated `docs_obs/`, `wiki/`, or `site/` folders—these are build artifacts
- Prefer descriptive alt text for images to improve accessibility across GitHub renderers

### Navigation Placement
- Add new topic pages to the appropriate category index:
  - Project planning → `docs/project_overview/`
  - Hardware content → `docs/hardware/`
  - Software guides and ROS 2 packages → `docs/software/`
  - Networking, Simulation, Troubleshooting, and Research each have their own `README.md` index.
- Update `mkdocs.yml` whenever you add a top-level page so MkDocs navigation matches the vault structure.

### Automation Hooks
- After creating or modifying ROS 2 packages under `src/`, run `python tools/ros2_autodoc.py` to refresh autogenerated references in `docs/software/autodoc/`.
- Standard Markdown links are used directly by GitHub Pages and Wiki (no conversion needed).

### Commit Messaging
- Use the `docs(<scope>): <message>` format for documentation commits, e.g., `docs(simulation): add gazebo tuning guide`.

### Examples
- Link example: `[Autodoc Index](../software/autodoc/_index.md)` (standard markdown, works everywhere).
- Page skeleton:
  ```markdown
  ---
  tags: [software, setup]
  status: draft
  related: []
  summary: >
    Configure the ShadowHound development environment.
  ---

  # Title

  ## Purpose
  ## Prerequisites
  ## Steps
  ## Validation
  ## References
  ```
