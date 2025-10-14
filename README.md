# ShadowHound - Autonomous Mobile Robot with LLM Planning

An autonomous mobile robot system that combines ROS2 navigation with LLM/VLM-driven task planning for natural language mission execution on Unitree Go2.

**Status**: 🏗️ Phase 0 (Infrastructure - 90% Complete)  
**Latest**: Cloud agent workflow documented, project planning updated with reality check  
**Branch**: `dev` (main development)

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

# 3. Build the workspace
cb              # colcon build --symlink-install
source-ws       # source install/setup.bash

# 4. Verify packages
ros2 pkg list | grep shadowhound
```

**What Works Now**:
- ✅ Devcontainer with ROS2 Humble + DIMOS
- ✅ Package structure (bringup, mission_agent, skills)
- ✅ Build system with helpful aliases
- ✅ Documentation pipeline with 8x velocity gains
- ✅ Cloud agent collaboration workflow

**What's Next**:
- 🔄 Testing infrastructure (pytest, mocks, CI)
- 🔄 Skills implementation (starting with 3 basic skills)
- 🔄 Mission agent integration (after skills proven)

### Prerequisites
- **Docker** with dev containers support
- **VS Code** with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- **Git** with submodule support

**Note**: LLM backend configuration will be needed for Phase 2 (Mission Agent), not required for current Phase 0-1 development.

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

# Validate wikilinks before committing
python tools/validate_wikilinks.py --docs docs
```

The conversion step writes GitHub-friendly Markdown into `docs_web/`, which MkDocs consumes for local previews and GitHub Pages deployments.

**CI Validation**: All pull requests that modify `docs/**` automatically run wikilink validation to prevent broken internal links. The validator checks:
- All wikilink targets exist
- Relative paths (e.g., `[[../file]]`) resolve correctly
- Same-directory references (e.g., `[[sibling]]`) are valid
- Cross-directory absolute paths (e.g., `[[software/scripts]]`) point to existing files

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

**📚 View the documentation:**
- **[GitHub Wiki](https://github.com/danmartinez78/shadowhound/wiki)** - Browse the complete documentation in wiki format
- **[GitHub Pages](https://danmartinez78.github.io/shadowhound/)** - Material theme documentation site

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

```
┌─ Application ─┐  Launch files, configs, deployment
┌─ Agent ───────┐  LLM/VLM orchestration, mission planning  
┌─ Skills ──────┐  Execution engine, safety, telemetry
┌─ Robot ───────┐  ROS2 bridge to go2_ros2_sdk
└─ Hardware ────┘  Unitree Go2 quadruped
```

### Core Packages

- **`shadowhound_bringup/`** ✅ - Launch files and configurations
- **`shadowhound_mission_agent/`** 🏗️ - ROS2 node for mission execution (scaffolded, not implemented)
- **`shadowhound_skills/`** 🏗️ - Skills registry and implementations (scaffolded, not implemented)

**Integration**: Designed to integrate with [DIMOS framework](https://github.com/Dorteel/dimos-unitree) with Unitree Go2 SDK

**Current Reality**: Packages exist but contain minimal implementation. See [Status Analysis](docs/project_overview/status_analysis_2025_10.md) for honest assessment.

See [`docs/architecture/`](docs/architecture/) for detailed architecture documentation.

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

## Environment Variables

```bash
# ROS2 Configuration (pre-set in devcontainer)
ROS_DOMAIN_ID=42                      # Isolated network
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp # DDS implementation
RCUTILS_LOGGING_BUFFERED_STREAM=1     # Logging optimization

# Robot Connection (Phase 3 - Hardware validation)
GO2_IP=192.168.1.103                  # Go2 robot IP (when needed)

# Agent Configuration (Phase 2 - Mission agent)
AGENT_BACKEND=cloud                   # cloud or local (when needed)
OPENAI_API_KEY=<your-key>             # For cloud LLM (Phase 2+)
```

---

## Current Status & Roadmap

### ✅ Phase 0: Infrastructure (90% Complete)
**Target**: November 1, 2025

**Completed**:
- [x] Devcontainer with ROS2 Humble + DIMOS
- [x] Workspace structure and build system
- [x] Package scaffolding (3 packages created)
- [x] Documentation pipeline (standard Markdown authoring)
- [x] Cloud agent workflow (8x velocity on suitable tasks)
- [x] Development environment with helpful aliases
- [x] Submodule integration and protection
- [x] Project planning documents aligned with reality

**Remaining (10%)**:
- [ ] Testing infrastructure (pytest setup, mocks)
- [ ] CI/CD for automated tests
- [ ] Documentation of testing patterns

### 🔄 Phase 1: Skills Foundation (0% Complete, Next Priority)
**Target**: November 15, 2025

**Core Infrastructure** (Must complete first):
- [ ] RobotInterface design and implementation
- [ ] SkillRegistry with type safety and validation
- [ ] Testing framework with mocks
- [ ] First 3 skills as examples (stop, rotate, log)

**Additional Skills** (After core proven):
- [ ] 5-10 more navigation skills
- [ ] 3 perception skills
- [ ] 2-3 system skills

**Success Criteria**: "Can execute 'rotate 90 degrees, move forward 1 meter, stop' in simulation"

### 🔜 Phase 2: Mission Agent (Target: December - January 2026)
- [ ] DIMOS agent integration
- [ ] Web UI dashboard
- [ ] Camera feed integration
- [ ] Natural language mission execution
- [ ] 5+ example missions

### � Phase 3: Hardware Validation (Target: February - March 2026)
- [ ] Testing on actual Unitree Go2
- [ ] Safety validation
- [ ] Performance tuning
- [ ] Documentation of lessons learned

### 🌟 Phase 4: Advanced Features (Target: April - May 2026)
- [ ] VLM integration for vision
- [ ] Outdoor navigation
- [ ] Multi-step autonomous missions
- [ ] Advanced perception and planning

**See**: [Detailed Roadmap](docs/project_overview/roadmap.md) for complete phase breakdown with deliverables, dependencies, and risks.

---

## Key Documentation

### Architecture & Planning
- **[Architecture Hub](docs/architecture/architecture_hub.md)** - Complete system architecture
- **[Project Overview](docs/project_overview/project_overview_hub.md)** - Vision, roadmap, status
- **[Status Analysis (Oct 2025)](docs/project_overview/status_analysis_2025_10.md)** - Comprehensive reality check
- **[Roadmap](docs/project_overview/roadmap.md)** - Phase-by-phase plan with deliverables
- **[TODO List](docs/development/todo.md)** - Active task list organized by phase

### Development Guides
- **[Development Hub](docs/development/development_hub.md)** - All development processes
- **[Cloud Agent Workflow](docs/development/cloud_agent_workflow.md)** - High-velocity collaboration (8x gains)
- **[Cloud Agent Quick Start](docs/development/cloud_agent_quick_start.md)** - Quick reference card
- **[Copilot Instructions](.github/copilot-instructions.md)** - AI agent development guide
- **[Agent Guidelines](AGENTS.md)** - Repository-wide authoring rules

### Technical References
- **[Software Hub](docs/software/software_hub.md)** - ROS2 packages and tools
- **[Networking Hub](docs/networking/networking_hub.md)** - Network architecture
- **[Simulation Hub](docs/simulation/simulation_hub.md)** - Gazebo and testing

---

## Recent Changes

### October 13, 2025 - Project Management & Reality Check
- ✅ **Comprehensive status analysis**: Documented actual Phase 0 state vs. aspirational claims
- ✅ **Roadmap revision**: 5 specific phases with measurable deliverables and timelines
- ✅ **TODO restructure**: Organized by phase with clear priorities and acceptance criteria
- ✅ **README reality update**: Removed false completion claims, aligned with actual progress

**Key Insights**:
- Project has excellent infrastructure (devcontainer, docs, workflow) but minimal implementation
- Actually in Phase 0 (90% complete), not Phase 1 as previously claimed
- Cloud agent workflow provides 8-10x velocity on well-defined tasks (Issue #20 proof)
- Clear path forward: Complete Phase 0 testing, start Phase 1 skills implementation

### October 12, 2025 - Documentation & Workflow
- ✅ **Documentation pipeline reversal** (Issue #20): 8x velocity improvement
- ✅ **Cloud agent workflow documentation**: 600+ lines comprehensive guide
- ✅ **Issue templates**: Cloud agent, feature, and bug report templates
- ✅ **Development hub updates**: Added Collaboration & Velocity section

See [Status Analysis](docs/project_overview/status_analysis_2025_10.md) for complete assessment and lessons learned.

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
# Check logs in terminal
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

**See**: [Troubleshooting Hub](docs/troubleshooting/troubleshooting_hub.md) for comprehensive guides

---

## Development Tracking

### 📖 Planning Documents

We maintain organized tracking of development progress and tasks:

- **[Roadmap](docs/project_overview/roadmap.md)** - Strategic milestones with specific deliverables
  - 5 phases with timelines and success criteria
  - Dependencies, risks, and velocity multipliers
  - Currently in Phase 0 (90% complete)

- **[TODO List](docs/development/todo.md)** - Active task list organized by phase
  - 🔴 High / 🟡 Medium / 🟢 Low priority markers
  - Clear acceptance criteria
  - Cloud agent candidate indicators
  - Recently completed section

- **[Status Analysis](docs/project_overview/status_analysis_2025_10.md)** - Comprehensive assessment
  - Honest evaluation of actual vs. claimed state
  - Lessons learned from cloud agent workflow success
  - Revised priorities and path forward

### Quick Commands

```bash
# View current priorities
grep -A 3 "## 🔴 Phase 0" docs/development/todo.md

# Check roadmap status
head -n 50 docs/project_overview/roadmap.md

# View recent completions
grep -A 20 "## ✅ Recently Completed" docs/development/todo.md
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

- Built with [ROS2 Humble](https://docs.ros.org/en/humble/)
- Designed to integrate with [go2_ros2_sdk](https://github.com/unitreerobotics/go2_ros2_sdk)
- Uses [DIMOS framework](https://github.com/Dorteel/dimos-unitree) for LLM integration (Phase 2+)

---

**Ready to start developing?** Check [Development Hub](docs/development/development_hub.md) for complete guides and [Roadmap](docs/project_overview/roadmap.md) for next steps!