# ShadowHound - Autonomous Mobile Robot with LLM Planning

An autonomous mobile robot system that combines ROS2 navigation with LLM/VLM-driven task planning for natural language mission execution on Unitree Go2.

**Status**: 🚀 Phase 1 (Active Development) - Mission agent operational with camera feed  
**Latest**: Fixed camera QoS, optimized web UI for laptop screens, multi-step execution working  
**Branch**: `feature/dimos-integration` (main development, ready to merge)

---

## Quick Start

### 🚀 Fastest Start (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/danmartinez78/shadowhound.git
cd shadowhound

# 2. Open in VS Code dev container
code .
# (Click "Reopen in Container" when prompted)

# 3. Run the start script
./start.sh --dev
```

That's it! The script handles everything:
- ✓ Checks dependencies
- ✓ Creates configuration (.env)
- ✓ Builds the workspace
- ✓ Launches the system
- ✓ Opens web dashboard at http://localhost:8080

Try a mission: "rotate to the right and take a step back" 🤖

**New Features**:
- 🎯 Multi-step sequential execution (PlanningAgent enabled by default)
- 📊 Real-time performance metrics in web UI
- 📹 Live camera feed with BEST_EFFORT QoS (working!)
- ⏱️ Detailed timing instrumentation
- 🎨 Optimized UI layout for laptop screens (camera + diagnostics + terminal fit on one screen)
- 📝 Collapsible topics list to save vertical space

### 📚 For More Control

See [Script Catalog](docs/software/scripts.md) for all available scripts and options:
- `./start.sh` - Smart interactive launcher
- `./scripts/quick-start-dev.sh` - One-command development start
- `./scripts/check-deps.sh` - Verify dependencies
- `./scripts/test-web-only.sh` - Test web interface alone

### Prerequisites
- **Docker** with dev containers support
- **VS Code** with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- **OpenAI API Key** - Get one from [OpenAI Platform](https://platform.openai.com/api-keys)

### Dev Container Features
The container provides everything you need:
- ✅ ROS2 Humble Desktop Full
- ✅ Navigation2 stack
- ✅ CycloneDDS middleware
- ✅ Python tools (black, isort, pylint, mypy, pytest)
- ✅ DIMOS framework with LLM integration
- ✅ Helpful aliases (`cb`, `source-ws`, `rosdep-install`)

### Manual Setup (if needed)

```bash
# Inside the container terminal:
cb              # Build with colcon (alias for colcon build --symlink-install)
source-ws       # Source the workspace (alias for source install/setup.bash)

# Verify setup
ros2 pkg list | grep shadowhound
```

### Documentation Workflow Quick Start

```bash
# Install MkDocs tooling (first time only)
pip install mkdocs mkdocs-material pyyaml

# Regenerate package references and converted docs
python tools/ros2_autodoc.py
python tools/link_convert.py docs docs_web

# Preview the Material site locally
mkdocs serve
```

The conversion step writes GitHub-friendly Markdown into `docs_web/`, which MkDocs consumes for local previews and GitHub Pages deployments.

## For Agents & Copilots

- Follow [`AGENTS.md`](AGENTS.md) for repository-wide authoring rules.
- Review [`.github/copilot-instructions.md`](.github/copilot-instructions.md) for AI and automation-specific guidance.
- Use the `docs(<scope>): ...` commit prefix when landing documentation updates.

## Documentation Ecosystem

ShadowHound maintains a single Obsidian vault under `docs/`, then converts it for every public surface to guarantee consistent rendering:

1. **Authoring:** Write Markdown in `docs/` with wikilinks, embeds, and the required front-matter. Media belongs in `docs/_assets/`.
2. **Autodoc:** Run `python tools/ros2_autodoc.py` whenever ROS 2 packages change. This regenerates package references in `docs/software/autodoc/`.
3. **Conversion:** `python tools/link_convert.py docs docs_web` rewrites wikilinks to standard Markdown and mirrors the tree for MkDocs.
4. **Publishing:** The `Documentation` GitHub Action builds MkDocs Material from `docs_web/`, uploads the site to GitHub Pages, and syncs the converted docs to the GitHub Wiki via `tools/wiki_sync.py`.

Because every outward-facing site consumes the converted Markdown, links and media render identically on GitHub, Pages, and the Wiki.

### Architecture Diagrams

Visual architecture diagrams are available in `docs/_assets/`:
- **`system-architecture.png`** - Layered architecture from Web UI to hardware
- **`data-flow.png`** - Mission commands, telemetry, camera feeds, and skill execution flows
- **`network-topology.png`** - Network connections between laptop, Thor (Jetson), and GO2 robot
- **`docs-ecosystem.png`** - Documentation authoring workflow and publication pipeline

These diagrams are embedded in:
- [`docs/index.md`](docs/index.md) - Main documentation landing page
- [`docs/project_overview/architecture_review_summary.md`](docs/project_overview/architecture_review_summary.md) - Architecture review details
- [`docs/networking/README.md`](docs/networking/README.md) - Networking guide

---

## Architecture Overview

ShadowHound uses a **four-layer architecture** built on the DIMOS framework:

![System Architecture](docs/_assets/system-architecture.png)

*System architecture showing the layered design from Web UI through Mission Agent, DIMOS Skills Engine, ROS2 Bridge, to the Unitree GO2 hardware. See [full documentation](docs/index.md) for detailed architecture diagrams including data flow and network topology.*

```
┌─ Application ─┐  Launch files, configs, deployment
┌─ Agent ───────┐  LLM/VLM orchestration, mission planning
┌─ Skills ──────┐  Execution engine, safety, telemetry
┌─ Robot ───────┐  ROS2 bridge to go2_ros2_sdk
└─ Hardware ────┘  Unitree Go2 quadruped
```

### Core Packages

- **`shadowhound_mission_agent/`** ✅ - ROS2 node with DIMOS integration, web UI, mission execution
- **`shadowhound_utils/`** ✅ - Utilities including robot interface and skills framework
- **`shadowhound_skills/`** ✅ - Vision skills package with VLM integration (Qwen, object detection)
- **`shadowhound_bringup/`** ✅ - Launch files and configurations

**Integration**: Built on [DIMOS framework](https://github.com/Dorteel/dimos-unitree) with Unitree Go2 SDK

See [`docs/project.md`](docs/project_context.md) and [`docs/DIMOS_VISION_CAPABILITIES.md`](docs/DIMOS_VISION_CAPABILITIES.md) for detailed architecture.

---

## Development Workflow

### Useful Aliases (Pre-configured)

```bash
cb              # colcon build --symlink-install
cbt             # colcon test
cbr             # colcon build && source install/setup.bash
source-ws       # source install/setup.bash (if workspace is built)
rosdep-install  # rosdep install --from-paths src --ignore-src -r -y
```

### Creating a New Package

```bash
cd src/
ros2 pkg create --build-type ament_python \
    --dependencies rclpy std_msgs \
    shadowhound_<name>

# Build and test
cb --packages-select shadowhound_<name>
source-ws
ros2 run shadowhound_<name> <node_name>
```

### Testing

```bash
# Run ROS2 tests
cbt --packages-select shadowhound_<name>

# Run Python unit tests
pytest src/shadowhound_<name>/test/

# Run specific test
pytest src/shadowhound_skills/test/test_registry.py -v
```

---

## Skills API Concept

The **Skills API** is the primary interface for robot control. Skills are typed, safe wrappers over ROS2 operations with built-in validation, timeouts, and telemetry.

### Example: Calling a Skill

```python
from shadowhound_skills import SkillRegistry

# Execute a navigation skill
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

### Example: Implementing a Skill

```python
from shadowhound_skills import Skill, SkillResult, register_skill

@register_skill("report.say")
class SaySkill(Skill):
    """Text-to-speech skill."""
    
    def validate_params(self, text: str) -> tuple[bool, str]:
        if not text or len(text) > 500:
            return False, "Text must be 1-500 characters"
        return True, ""
    
    def execute(self, text: str) -> SkillResult:
        # Implementation here
        return SkillResult(success=True, data={"spoken": text})
```

---

## Environment Variables

```bash
# ROS2 Configuration (pre-set in devcontainer)
ROS_DOMAIN_ID=42                      # Isolated network
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp # DDS implementation
RCUTILS_LOGGING_BUFFERED_STREAM=1     # Logging optimization

# Robot Connection (set when needed)
GO2_IP=192.168.1.103                  # Go2 robot IP
GO2_MODE=webrtc                       # webrtc or ethernet

# Agent Configuration (set when needed)
AGENT_BACKEND=cloud                   # cloud or local
OPENAI_API_KEY=<your-key>             # For cloud LLM (required)
ALIBABA_API_KEY=<your-key>            # For Qwen VLM (optional, for vision skills)

# Agent Settings
USE_PLANNING_AGENT=true               # true=sequential multi-step, false=single-shot (default: true)
AGENT_MODEL=gpt-4-turbo               # LLM model (gpt-4-turbo, gpt-3.5-turbo)
```

---

## Current Status & Roadmap

### ✅ Phase 0: Bootstrap (COMPLETE)
- [x] Devcontainer with ROS2 Humble + DIMOS
- [x] Workspace structure and build system
- [x] Package scaffolding created
- [x] Integration with go2_ros2_sdk

### ✅ Phase 1: Mission Agent (COMPLETE)
- [x] DIMOS integration with OpenAI/PlanningAgent
- [x] Web UI with real-time camera feed
- [x] Mission execution via natural language
- [x] Performance metrics and timing instrumentation
- [x] Multi-step sequential execution (PlanningAgent)
- [x] Robot skills framework (via DIMOS)

### 🔄 Phase 2: Vision Skills (IN PROGRESS - `feature/vlm-integration`)
- [x] Vision skills package with 4 skills
  - [x] SnapshotSkill - Capture and save images
  - [x] DescribeSceneSkill - VLM scene description
  - [x] LocateObjectSkill - VLM object detection with bounding boxes
  - [x] DetectObjectsSkill - VLM multi-object detection
- [x] DIMOS Qwen VLM integration
- [x] Comprehensive test suite (4/4 passing)
- [ ] **NEXT**: Wire vision skills to mission_agent camera feed
- [ ] **NEXT**: Register skills with DIMOS MyUnitreeSkills
- [ ] End-to-end vision mission testing

### 🔜 Phase 3: Performance Optimization
- [ ] Collect baseline performance data
- [ ] Analyze bottlenecks (cloud API vs DIMOS)
- [ ] Optimize model selection (gpt-3.5-turbo for simple commands)
- [ ] Add streaming responses for better UX
- [ ] Target: <2s simple commands, <5s multi-step

### 🔮 Phase 4: Advanced Features
- [ ] Hybrid agent selection (OpenAI for simple, Planning for complex)
- [ ] Local LLM option for offline operation
- [ ] Advanced vision: depth estimation, 3D object tracking
- [ ] Multi-robot coordination
- [ ] Persistent memory and learning

See [Project TODO Backlog](docs/project_overview/todo.md) for detailed task tracking and [Development Log](docs/research/devlog.md) for development history.

---

## Key Documentation

### Architecture & Planning
- **[`docs/project_context.md`](docs/project_context.md)** - Complete project context and architecture
- **[`.github/copilot-instructions.md`](.github/copilot-instructions.md)** - AI agent development guide
- **[`docs/DIMOS_VISION_CAPABILITIES.md`](docs/DIMOS_VISION_CAPABILITIES.md)** - DIMOS vision system analysis

### Recent Improvements
- **[`docs/MULTI_STEP_EXECUTION_ISSUE.md`](docs/MULTI_STEP_EXECUTION_ISSUE.md)** - PlanningAgent vs OpenAIAgent guide
- **[`docs/AGENT_QUICK_REFERENCE.txt`](docs/AGENT_QUICK_REFERENCE.txt)** - Agent selection quick reference
- **[`docs/WEB_UI_PERFORMANCE_METRICS.md`](docs/WEB_UI_PERFORMANCE_METRICS.md)** - Performance monitoring guide
- **[`docs/PERFORMANCE_ANALYSIS_PLAN.md`](docs/PERFORMANCE_ANALYSIS_PLAN.md)** - Optimization strategy
- **[`docs/TIMING_DISPLAY_FIX.md`](docs/TIMING_DISPLAY_FIX.md)** - Clean terminal output fix

### Package Documentation
- **[`src/shadowhound_skills/README.md`](src/shadowhound_skills/README.md)** - Vision skills package guide
- **[`src/shadowhound_mission_agent/`](src/shadowhound_mission_agent/)** - Mission agent implementation

---

## Recent Changes

### October 7, 2025
- ✅ **Multi-step execution fix**: Enabled PlanningAgent by default for proper sequential command execution
- ✅ **Performance metrics**: Added real-time timing instrumentation to web UI
- ✅ **Clean terminal output**: Combined timing info with responses to avoid clutter
- ✅ **IndentationError fix**: Resolved web interface startup issue
- ✅ **Comprehensive documentation**: Added 6 new docs (1,500+ lines) covering architecture, troubleshooting, and optimization strategies

**Key Improvements**:
- Commands like "rotate right and step back" now execute sequentially (not simultaneously)
- Web UI shows agent duration, overhead, and total execution time with color-coded indicators
- Performance averages calculated over last 50 commands for trend analysis

See [Development Log](docs/research/devlog.md) for complete development history.

---

## Troubleshooting

### Container Issues

**Problem**: Container fails to build
```bash
# Check Docker is running
docker ps

# Rebuild container from scratch
# Ctrl+Shift+P → "Dev Containers: Rebuild Container Without Cache"
```

**Problem**: Setup script fails
```bash
# Check setup.sh logs in terminal
# Common fix: permissions
sudo chown -R ros:ros /workspaces/shadowhound
```

### ROS Issues

**Problem**: Packages not found after build
```bash
# Always source after building
source-ws

# Or use the combined alias
cbr
```

**Problem**: Dependencies missing
```bash
# Install ROS dependencies
rosdep-install

# Check what's missing
rosdep check --from-paths src --ignore-src
```

**Problem**: Can't find ROS topics
```bash
# Check ROS environment
printenv | grep ROS

# List topics
ros2 topic list

# Check network (if using real robot)
ros2 daemon stop && ros2 daemon start
```

### Mission Agent Issues

**Problem**: Multi-step commands execute incorrectly
```bash
# Verify PlanningAgent is enabled (default since Oct 7, 2025)
ros2 param get /shadowhound_mission_agent use_planning_agent
# Should return: True

# Check logs for "PlanningAgent initialized" (not "OpenAIAgent")
```

**Problem**: Performance seems slow
```bash
# This is EXPECTED with PlanningAgent (sequential execution)
# Check web UI performance panel for timing breakdown
# - Simple commands: ~1.5s (acceptable)
# - Multi-step commands: ~3-5s (acceptable, ensures correctness)

# See docs/PERFORMANCE_ANALYSIS_PLAN.md for optimization strategies
```

**Problem**: Web UI not showing performance metrics
```bash
# Rebuild mission_agent
colcon build --packages-select shadowhound_mission_agent
source install/setup.bash

# Restart and check http://localhost:8080
ros2 launch shadowhound_bringup shadowhound.launch.py
```

**Problem**: IndentationError on startup
```bash
# This was fixed in commit fa517f2
# Pull latest changes:
git pull origin feature/dimos-integration
colcon build --packages-select shadowhound_mission_agent
```

### Vision Skills Issues

**Problem**: Vision skills not working
```bash
# Check ALIBABA_API_KEY is set (required for Qwen VLM)
echo $ALIBABA_API_KEY

# Vision skills will gracefully skip if API key missing
# See src/shadowhound_skills/README.md for setup
```

---

## Development Tracking

### 📖 DevLog & TODO System

We maintain organized tracking of development progress and tasks:

- **[Development Log](docs/research/devlog.md)** - Chronological record of what was done and why
  - Major features and fixes
  - Technical decisions
  - Key learnings
  - Add entries after completing significant work

- **[Project TODO Backlog](docs/project_overview/todo.md)** - Organized task list with priorities
  - 🔴 High / 🟡 Medium / 🟢 Low priority
  - Clear acceptance criteria
  - Recently completed section

- **[`docs/DEVELOPMENT_TRACKING.md`](docs/DEVELOPMENT_TRACKING.md)** - Complete guide
  - When and how to update
  - Workflows and best practices
  - Example entries

### Quick Commands

```bash
# Add a devlog entry (interactive)
./scripts/add-devlog-entry.sh

# View priorities
grep -A 3 "## 🔴 High Priority" docs/project_overview/todo.md

# View recent entries
head -n 50 docs/research/devlog.md
```

---

## Contributing

### Development Principles
1. **Container-First**: Always develop inside the devcontainer
2. **Skills-First**: Implement robot control as skills, not ad-hoc ROS code
3. **Safety-First**: Validate inputs, add timeouts, clamp velocities
4. **Test-Driven**: Write tests alongside implementation
5. **Document**: Keep `docs/project.md` updated

### Code Style
- **Python**: black (line length 99), isort, flake8, mypy
- **ROS2**: Follow [ROS2 conventions](https://docs.ros.org/en/humble/The-ROS2-Project/Contributing/Code-Style-Language-Versions.html)
- **Commits**: Use conventional commits (feat:, fix:, docs:, etc.)

### Before Submitting
```bash
# Format code
black src/shadowhound_*/shadowhound_*/ --line-length 99
isort src/shadowhound_*/shadowhound_*/

# Lint
flake8 src/shadowhound_*/shadowhound_*/ --max-line-length 99

# Type check
mypy src/shadowhound_*/shadowhound_*/

# Test
cbt
pytest src/
```

---

## License

[Add your license here]

## Acknowledgments

- Built on [go2_ros2_sdk](https://github.com/unitreerobotics/go2_ros2_sdk)
- Uses [ROS2 Humble](https://docs.ros.org/en/humble/)
- Inspired by LLM-based robotics research

---

**Ready to start developing?** Check [`docs/project.md`](docs/project.md) for the complete architecture and next steps!