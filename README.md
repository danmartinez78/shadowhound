# ShadowHound - Embodied AI Robot Platform# ShadowHound - Autonomous Mobile Robot with LLM Planning



An autonomous mobile robot system combining ROS2 navigation with LLM/VLM-driven task planning for natural language mission execution on Unitree Go2.An autonomous mobile robot system that combines ROS2 navigation with LLM/VLM-driven task planning for natural language mission execution on Unitree Go2.



**Primary Goal**: Hands-on experience with transformer architectures in robotics (LLM, VLM, VLA)  **Status**: 🏗️ Active Development  

**Status**: 🏗️ Active Development  **Latest**: MVP roadmap defined, documentation infrastructure complete  

**Branch**: `dev` (active) | `main` (stable, protected)**Branch**: `dev` (active) | `main` (stable, protected)



------



## Quick Start## Quick Start



```bash```bash

# 1. Clone with submodules# 1. Clone and open in dev container

git clone --recurse-submodules https://github.com/danmartinez78/shadowhound.gitgit clone --recurse-submodules https://github.com/danmartinez78/shadowhound.git

cd shadowhoundcd shadowhound

code .  # Click "Reopen in Container"

# 2. Open in VS Code dev container

code .  # Click "Reopen in Container"# 2. Build workspace

cb && source-ws

# 3. Build workspace

cb && source-ws# 3. Verify

ros2 pkg list | grep shadowhound

# 4. Verify packages```

ros2 pkg list | grep shadowhound

```**What Works**:

- ✅ Complete dev environment (ROS2 Humble + DIMOS + helpers)

**Prerequisites**: Docker, VS Code with Dev Containers extension, Git with submodule support- ✅ Mission agent with dual LLM backends (OpenAI cloud + local vLLM)

- ✅ Custom web UI (FastAPI-based)

---- ✅ Documentation infrastructure (auto-sync to Wiki + Pages)

- ✅ Experiment documentation system

## What We've Built (Oct 3-13, 2025)- ✅ Cloud agent workflow (8x velocity)



### ✅ Working System (Validated on Physical Robot)**MVP Goal**: Household assistant robot - "Find the red ball in the living room"



**Mission Agent** (~2,100 LOC):See **[MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)** for complete plan.

- `mission_agent.py` - ROS2 node (713 LOC)

- `mission_executor.py` - Cognitive layer (517 LOC)  ---

- `web_interface.py` - FastAPI server built from scratch (479 LOC)

- `rag_memory_example.py` - Memory patterns (392 LOC)## Documentation

- Unit tests (223 LOC)

📚 **View Documentation:**

**LLM Backends** (both validated on hardware):- **[GitHub Wiki](https://github.com/danmartinez78/shadowhound/wiki)** - Complete docs (auto-syncs from dev/main)

- ✅ OpenAI cloud (GPT-4o) - weekend testing successful- **[GitHub Pages](https://danmartinez78.github.io/shadowhound/)** - Material theme site (from main)

- ⚠️ vLLM local on Thor AGX (Mistral 7B) - recent testing partial success- **[Project Overview Hub](docs/project_overview/project_overview_hub.md)** - Vision, MVP, status

- **[Development Log](docs/development/devlog.md)** - Daily timeline

**Infrastructure**:- **[Experiments](docs/development/experiments/)** - Detailed experimental work

- Complete ROS2 Humble dev environment (devcontainer)

- DIMOS framework integration (git submodule)**For Contributors**: See [AGENTS.md](AGENTS.md) for authoring guidelines.

- Custom web UI dashboard

- Camera feed streaming (QoS matched - BEST_EFFORT)---

- Configuration system (.env files)

- Network topology: Desktop → Laptop (192.168.10.167) → Thor (192.168.10.116) → Go2## Architecture



**Documentation** (187 markdown files):Four-layer stack built on DIMOS framework:

- Comprehensive architecture docs

- Cloud agent workflow (8x velocity proven)```

- Hub structure for navigationApplication  → Launch files, configs, deployment

- Auto-sync to Wiki + GitHub PagesAgent        → LLM/VLM orchestration, mission planning  

- Experiment documentation systemSkills       → Execution engine, safety, telemetry

Robot        → ROS2 bridge to go2_ros2_sdk hardware

**Hardware Testing**:```

- ✅ Successfully executed motion commands on physical Unitree Go2

- ✅ SLAM + Nav2 tested**Core Packages**:

- ✅ Camera, LiDAR, IMU, odometry operational- `shadowhound_bringup/` - Launch files

- ✅ Network architecture validated- `shadowhound_mission_agent/` - Mission execution node (~2,100 LOC)

- `shadowhound_skills/` - Skills registry (scaffolded)

### ⚠️ Known Constraints

See **[Architecture Hub](docs/architecture/architecture_hub.md)** for details.

- **WebRTC API Skills**: Majority of DIMOS MyUnitreeSkills use WebRTC API and are non-functional (working with limited skill set)

- **MockRobot**: Not implemented (blocks hardware-free development)---

- **Thor GPU**: Performance degraded (37→5 tok/s) - needs investigation

- **Custom Skills**: None beyond DIMOS built-ins## Development



### 📈 Development Velocity**Helpful Aliases** (pre-configured):

```bash

- **389 commits** in 10 days (Oct 3-13)cb              # colcon build --symlink-install

- **3,500 LOC** across ShadowHound packagessource-ws       # source install/setup.bash

- **6,271 lines** contributed to DIMOS upstream docscbr             # build and source combined

- **8x velocity** on documentation with cloud agentsrosdep-install  # install dependencies

```

See [Project History](docs/history/project_history_oct_2025.md) for complete Oct 3-13 timeline.

**Key Guides**:

---- **[Development Hub](docs/development/development_hub.md)** - Complete dev guide

- **[Cloud Agent Workflow](docs/development/cloud_agent_workflow.md)** - 8x velocity collaboration

## MVP: Embodied AI Platform- **[Copilot Instructions](.github/copilot-instructions.md)** - AI agent guide



**Primary Goal**: Build an embodied AI platform for exploring transformer-based robotics, not limited to any single application domain.---



**Why Transformers in Robotics**:## MVP Roadmap

- **LLM**: Mission planning, reasoning, natural language understanding

- **VLM**: Scene understanding, visual question answering**🎯 Goal**: Household assistant with vision, voice, semantic navigation

- **VLA**: Direct visuomotor control (future/stretch goal)

**Current Focus**: Milestone 1 - Vision Foundation

**Initial Test Missions** (household scenarios for validation):- Test DIMOS perception vs VLM branch

- "Find the red ball in the living room"- Establish object detection baseline

- "Check if the oven is on"- Choose vision approach

- "Navigate to the kitchen"

**Recent Work** (Oct 14, 2025):

**Note**: Household missions are concrete test scenarios to validate the platform's capabilities. The architecture is designed for broader applications beyond domestic environments.- ✅ MVP roadmap defined (5 milestones)

- ✅ Project overview consolidated (14 → 6 files)

**Success Criteria**:- ✅ Experiment docs system created

1. Accept voice OR console/web commands- ✅ Wiki auto-sync working (dev + main)

2. Execute vision-based missions- ✅ Dual LLM backends (OpenAI + vLLM)

3. Navigate safely with SLAM

4. Respond with voice + personality**Known Constraints**:

5. Process onboard Thor AGX (no cloud dependency)- WebRTC API skills non-functional

6. Learn and remember spatial information- Thor compute budget unknown

- MockRobot not implemented

See **[MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)** for complete specification.

See **[MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)** and **[Project History](docs/history/project_history_oct_2025.md)** (389 commits analyzed).

---

---

## Architecture

## Key Documentation

### Four-Layer Stack

**Project Planning**:

```- [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)

Application  → Launch files, configs, deployment- [Project Overview Hub](docs/project_overview/project_overview_hub.md)

Agent        → LLM/VLM reasoning, mission planning  - [Development Log](docs/development/devlog.md)

Skills       → DIMOS execution engine (~30 behaviors)- [Experiments](docs/development/experiments/)

Robot        → ROS2 bridge to go2_ros2_sdk

```**Development**:

- [Development Hub](docs/development/development_hub.md)

**Core Packages**:- [Cloud Agent Workflow](docs/development/cloud_agent_workflow.md)

- `shadowhound_bringup/` - Launch files and configs- [Agent Guidelines](AGENTS.md)

- `shadowhound_mission_agent/` - Mission execution (~2,100 LOC implemented)- [Copilot Instructions](.github/copilot-instructions.md)

- `shadowhound_skills/` - Skills registry (scaffolded)

- `dimos-unitree/` - DIMOS framework (git submodule)**Technical**:

- [Architecture Hub](docs/architecture/architecture_hub.md)

**Network Topology** (actual deployment):- [Software Hub](docs/software/software_hub.md)

- Laptop: Agent + ROS2 + Mission execution- [Networking Hub](docs/networking/networking_hub.md)

- Thor AGX: vLLM backend (when not using cloud)

- Go2: Physical robot hardware---

- ROS_DOMAIN_ID=42 for isolation

## Contributing

See [Architecture Hub](docs/architecture/architecture_hub.md) for details.

**Development Principles**:

---1. Container-first development

2. Skills-first robot control

## Documentation3. Safety-first validation

4. Test-driven implementation  

📚 **View Documentation:**5. Document as you go

- **[GitHub Wiki](https://github.com/danmartinez78/shadowhound/wiki)** - Auto-syncs from dev and main

- **[GitHub Pages](https://danmartinez78.github.io/shadowhound/)** - Material theme (main branch)**Code Style**:

- **[Project Overview Hub](docs/project_overview/project_overview_hub.md)** - Vision, MVP, status```bash

- **[Development Log](docs/development/devlog.md)** - Daily timeline (Oct 14+)# Format

- **[Project History](docs/history/project_history_oct_2025.md)** - Oct 3-13 comprehensive historyblack src/ --line-length 99

- **[Experiments](docs/development/experiments/)** - Detailed experimental workisort src/



**For Contributors**: See [AGENTS.md](AGENTS.md) for authoring guidelines.# Lint

flake8 src/ --max-line-length 99

---mypy src/

```

## Development

**Commits**: Use conventional commits (`feat:`, `fix:`, `docs:`, etc.)

### Helpful Aliases (Pre-configured)

---

```bash

cb              # colcon build --symlink-install## License

source-ws       # source install/setup.bash

cbr             # build and source combined[Add license]

rosdep-install  # install dependencies

```## Acknowledgments



### Creating a New Package- [ROS2 Humble](https://docs.ros.org/en/humble/)

- [go2_ros2_sdk](https://github.com/unitreerobotics/go2_ros2_sdk)

```bash- [DIMOS framework](https://github.com/Dorteel/dimos-unitree)

cd src/

ros2 pkg create --build-type ament_python \---

    --dependencies rclpy std_msgs \

    shadowhound_<name>**Ready to develop?** Check [Development Hub](docs/development/development_hub.md) and [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)!


cb --packages-select shadowhound_<name> && source-ws
```

### Key Development Guides

- [Development Hub](docs/development/development_hub.md) - Complete dev guide
- [Cloud Agent Workflow](docs/development/cloud_agent_workflow.md) - 8x velocity collaboration
- [Copilot Instructions](.github/copilot-instructions.md) - AI agent guide
- [Agent Guidelines](AGENTS.md) - Repository-wide authoring rules

---

## Recent Accomplishments (Oct 14, 2025)

**Today's Work**:
- ✅ MVP roadmap defined with 5 milestones
- ✅ Project overview consolidated (14 → 6 files)
- ✅ Experiment documentation system created
- ✅ Wiki infrastructure operational (auto-sync working)
- ✅ Main branch protected (requires PR, status checks)
- ✅ README corrected to reflect actual system state

**This Week** (Oct 3-13):
- ✅ Built mission agent from scratch (~2,100 LOC)
- ✅ Integrated DIMOS framework (feature branch → tested → merged)
- ✅ Validated on physical Unitree Go2 (OpenAI + vLLM backends)
- ✅ Created custom FastAPI web UI (479 LOC)
- ✅ Integrated local LLM (vLLM + Mistral on Thor AGX)
- ✅ Organized 187 documentation files
- ✅ Established cloud agent workflow (8x velocity)
- ✅ Contributed 6,271 lines to DIMOS upstream

See [Development Log](docs/development/devlog.md) for daily updates.

---

## Current Focus

**Milestone 1: Vision Foundation** (Next up)
- Test DIMOS perception stack vs VLM branch (Qwen)
- Establish object detection baseline
- Choose vision approach for MVP

**Key Priorities**:
1. Debug WebRTC API skills (unblock DIMOS behaviors)
2. Implement MockRobot (enable hardware-free dev)
3. Build custom skills using Nav2/non-WebRTC APIs
4. Profile Thor compute budget

---

## Key Documentation

**Project Planning**:
- [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md) - Complete specification
- [Project Overview Hub](docs/project_overview/project_overview_hub.md) - Vision, goals, status
- [Project History](docs/history/project_history_oct_2025.md) - Oct 3-13 history (389 commits)
- [Development Log](docs/development/devlog.md) - Daily timeline
- [Experiments](docs/development/experiments/) - Detailed experimental work

**Development**:
- [Development Hub](docs/development/development_hub.md) - All dev processes
- [Cloud Agent Workflow](docs/development/cloud_agent_workflow.md) - High-velocity collaboration
- [Copilot Instructions](.github/copilot-instructions.md) - AI agent guide
- [Agent Guidelines](AGENTS.md) - Authoring rules

**Technical**:
- [Architecture Hub](docs/architecture/architecture_hub.md) - System architecture
- [Software Hub](docs/software/software_hub.md) - ROS2 packages
- [Networking Hub](docs/networking/networking_hub.md) - Network topology

---

## Contributing

**Development Principles**:
1. **Container-first**: Always develop in devcontainer
2. **Skills-first**: Robot control through skills, not ad-hoc code
3. **Safety-first**: Validate inputs, timeouts, velocity clamps
4. **Test-driven**: Write tests alongside implementation
5. **Document**: Update docs as you work

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

- Built with [ROS2 Humble](https://docs.ros.org/en/humble/)
- Integrates [go2_ros2_sdk](https://github.com/unitreerobotics/go2_ros2_sdk)
- Uses [DIMOS framework](https://github.com/Dorteel/dimos-unitree) for LLM integration

---

**Ready to develop?** Check [Development Hub](docs/development/development_hub.md) and [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)!
