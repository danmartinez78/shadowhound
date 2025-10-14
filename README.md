# ShadowHound - Autonomous Mobile Robot with LLM Planning

An autonomous mobile robot system that combines ROS2 navigation with LLM/VLM-driven task planning for natural language mission execution on Unitree Go2.

**Status**: 🏗️ Active Development  
**Latest**: MVP roadmap defined, documentation infrastructure complete  
**Branch**: `dev` (active) | `main` (stable, protected)

---

## Quick Start

```bash
# 1. Clone and open in dev container
git clone --recurse-submodules https://github.com/danmartinez78/shadowhound.git
cd shadowhound
code .  # Click "Reopen in Container"

# 2. Build workspace
cb && source-ws

# 3. Verify
ros2 pkg list | grep shadowhound
```

**What Works**:
- ✅ Complete dev environment (ROS2 Humble + DIMOS + helpers)
- ✅ Mission agent with dual LLM backends (OpenAI cloud + local vLLM)
- ✅ Custom web UI (FastAPI-based)
- ✅ Documentation infrastructure (auto-sync to Wiki + Pages)
- ✅ Experiment documentation system
- ✅ Cloud agent workflow (8x velocity)

**MVP Goal**: Household assistant robot - "Find the red ball in the living room"

See **[MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)** for complete plan.

---

## Documentation

📚 **View Documentation:**
- **[GitHub Wiki](https://github.com/danmartinez78/shadowhound/wiki)** - Complete docs (auto-syncs from dev/main)
- **[GitHub Pages](https://danmartinez78.github.io/shadowhound/)** - Material theme site (from main)
- **[Project Overview Hub](docs/project_overview/project_overview_hub.md)** - Vision, MVP, status
- **[Development Log](docs/development/devlog.md)** - Daily timeline
- **[Experiments](docs/development/experiments/)** - Detailed experimental work

**For Contributors**: See [AGENTS.md](AGENTS.md) for authoring guidelines.

---

## Architecture

Four-layer stack built on DIMOS framework:

```
Application  → Launch files, configs, deployment
Agent        → LLM/VLM orchestration, mission planning  
Skills       → Execution engine, safety, telemetry
Robot        → ROS2 bridge to go2_ros2_sdk hardware
```

**Core Packages**:
- `shadowhound_bringup/` - Launch files
- `shadowhound_mission_agent/` - Mission execution node (~2,100 LOC)
- `shadowhound_skills/` - Skills registry (scaffolded)

See **[Architecture Hub](docs/architecture/architecture_hub.md)** for details.

---

## Development

**Helpful Aliases** (pre-configured):
```bash
cb              # colcon build --symlink-install
source-ws       # source install/setup.bash
cbr             # build and source combined
rosdep-install  # install dependencies
```

**Key Guides**:
- **[Development Hub](docs/development/development_hub.md)** - Complete dev guide
- **[Cloud Agent Workflow](docs/development/cloud_agent_workflow.md)** - 8x velocity collaboration
- **[Copilot Instructions](.github/copilot-instructions.md)** - AI agent guide

---

## MVP Roadmap

**🎯 Goal**: Household assistant with vision, voice, semantic navigation

**Current Focus**: Milestone 1 - Vision Foundation
- Test DIMOS perception vs VLM branch
- Establish object detection baseline
- Choose vision approach

**Recent Work** (Oct 14, 2025):
- ✅ MVP roadmap defined (5 milestones)
- ✅ Project overview consolidated (14 → 6 files)
- ✅ Experiment docs system created
- ✅ Wiki auto-sync working (dev + main)
- ✅ Dual LLM backends (OpenAI + vLLM)

**Known Constraints**:
- WebRTC API skills non-functional
- Thor compute budget unknown
- MockRobot not implemented

See **[MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)** and **[Project History](docs/history/project_history_oct_2025.md)** (389 commits analyzed).

---

## Key Documentation

**Project Planning**:
- [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)
- [Project Overview Hub](docs/project_overview/project_overview_hub.md)
- [Development Log](docs/development/devlog.md)
- [Experiments](docs/development/experiments/)

**Development**:
- [Development Hub](docs/development/development_hub.md)
- [Cloud Agent Workflow](docs/development/cloud_agent_workflow.md)
- [Agent Guidelines](AGENTS.md)
- [Copilot Instructions](.github/copilot-instructions.md)

**Technical**:
- [Architecture Hub](docs/architecture/architecture_hub.md)
- [Software Hub](docs/software/software_hub.md)
- [Networking Hub](docs/networking/networking_hub.md)

---

## Contributing

**Development Principles**:
1. Container-first development
2. Skills-first robot control
3. Safety-first validation
4. Test-driven implementation  
5. Document as you go

**Code Style**:
```bash
# Format
black src/ --line-length 99
isort src/

# Lint
flake8 src/ --max-line-length 99
mypy src/
```

**Commits**: Use conventional commits (`feat:`, `fix:`, `docs:`, etc.)

---

## License

[Add license]

## Acknowledgments

- [ROS2 Humble](https://docs.ros.org/en/humble/)
- [go2_ros2_sdk](https://github.com/unitreerobotics/go2_ros2_sdk)
- [DIMOS framework](https://github.com/Dorteel/dimos-unitree)

---

**Ready to develop?** Check [Development Hub](docs/development/development_hub.md) and [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)!
