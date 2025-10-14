<div align="center"># ShadowHound - Embodied AI Robot Platform# ShadowHound - Autonomous Mobile Robot with LLM Planning



# 🐺 ShadowHound



### Embodied AI Robot PlatformAn autonomous mobile robot system combining ROS2 navigation with LLM/VLM-driven task planning for natural language mission execution on Unitree Go2.An autonomous mobile robot system that combines ROS2 navigation with LLM/VLM-driven task planning for natural language mission execution on Unitree Go2.



*Exploring transformer architectures in robotics through natural language mission execution*



[![ROS2 Humble](https://img.shields.io/badge/ROS2-Humble-blue?logo=ros)](https://docs.ros.org/en/humble/)**Primary Goal**: Hands-on experience with transformer architectures in robotics (LLM, VLM, VLA)  **Status**: 🏗️ Active Development  

[![Platform](https://img.shields.io/badge/Platform-Unitree%20Go2-orange)](https://www.unitree.com/go2/)

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)](https://www.python.org/)**Status**: 🏗️ Active Development  **Latest**: MVP roadmap defined, documentation infrastructure complete  

[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[![Dev Status](https://img.shields.io/badge/Status-Active%20Development-yellow)](docs/project_overview/mvp_embodied_ai_platform.md)**Branch**: `dev` (active) | `main` (stable, protected)**Branch**: `dev` (active) | `main` (stable, protected)



[📚 **Documentation**](https://danmartinez78.github.io/shadowhound/) • 

[🎯 **MVP Roadmap**](docs/project_overview/mvp_embodied_ai_platform.md) • 

[📖 **Wiki**](https://github.com/danmartinez78/shadowhound/wiki) • ------

[🔬 **Experiments**](docs/development/experiments/)



</div>

## Quick Start## Quick Start

---



## 🎯 Project Vision

```bash```bash

**ShadowHound** is an embodied AI platform for hands-on exploration of transformer architectures in robotics. Built on the Unitree Go2 quadruped, it combines ROS2 navigation with LLM/VLM-driven task planning to execute natural language missions.

# 1. Clone with submodules# 1. Clone and open in dev container

### Why This Project?

git clone --recurse-submodules https://github.com/danmartinez78/shadowhound.gitgit clone --recurse-submodules https://github.com/danmartinez78/shadowhound.git

- 🧠 **LLM Integration**: Mission planning, reasoning, natural language understanding

- 👁️ **Vision Models (VLM)**: Scene understanding, visual question answering  cd shadowhoundcd shadowhound

- 🤖 **Visuomotor Actions (VLA)**: Direct perception-to-action control *(stretch goal)*

code .  # Click "Reopen in Container"

**Note**: While initial test missions focus on household scenarios ("Find the red ball"), the architecture is designed for broader embodied AI research beyond domestic applications.

# 2. Open in VS Code dev container

---

code .  # Click "Reopen in Container"# 2. Build workspace

## ⚡ Quick Start

cb && source-ws

### Prerequisites

# 3. Build workspace

- Docker Desktop

- VS Code with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)cb && source-ws# 3. Verify

- Git with submodule support

ros2 pkg list | grep shadowhound

### Setup (< 5 minutes)

# 4. Verify packages```

```bash

# 1. Clone repository with submodulesros2 pkg list | grep shadowhound

git clone --recurse-submodules https://github.com/danmartinez78/shadowhound.git

cd shadowhound```**What Works**:



# 2. Open in VS Code- ✅ Complete dev environment (ROS2 Humble + DIMOS + helpers)

code .

# Click "Reopen in Container" when prompted**Prerequisites**: Docker, VS Code with Dev Containers extension, Git with submodule support- ✅ Mission agent with dual LLM backends (OpenAI cloud + local vLLM)



# 3. Build workspace (inside container)- ✅ Custom web UI (FastAPI-based)

cb && source-ws

---- ✅ Documentation infrastructure (auto-sync to Wiki + Pages)

# 4. Verify installation

ros2 pkg list | grep shadowhound- ✅ Experiment documentation system

```

## What We've Built (Oct 3-13, 2025)- ✅ Cloud agent workflow (8x velocity)

**✅ You're ready!** The dev container includes ROS2 Humble, DIMOS framework, and all dependencies pre-configured.



---

### ✅ Working System (Validated on Physical Robot)**MVP Goal**: Household assistant robot - "Find the red ball in the living room"

## 🏗️ What's Built



<table>

<tr>**Mission Agent** (~2,100 LOC):See **[MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)** for complete plan.

<td width="50%">

- `mission_agent.py` - ROS2 node (713 LOC)

### ✅ Working System

- **Mission Agent** (~2,100 LOC)- `mission_executor.py` - Cognitive layer (517 LOC)  ---

  - `mission_agent.py` (713 LOC) - ROS2 node

  - `mission_executor.py` (517 LOC) - Cognitive layer- `web_interface.py` - FastAPI server built from scratch (479 LOC)

  - `web_interface.py` (479 LOC) - FastAPI dashboard

  - `rag_memory_example.py` (392 LOC) - Memory patterns- `rag_memory_example.py` - Memory patterns (392 LOC)## Documentation

  - Unit tests (223 LOC)

- Unit tests (223 LOC)

- **LLM Backends** *(hardware validated)*

  - ✅ OpenAI cloud (GPT-4o)📚 **View Documentation:**

  - ⚠️ vLLM local (Mistral 7B on Thor AGX)

**LLM Backends** (both validated on hardware):- **[GitHub Wiki](https://github.com/danmartinez78/shadowhound/wiki)** - Complete docs (auto-syncs from dev/main)

- **Infrastructure**

  - Complete ROS2 dev environment- ✅ OpenAI cloud (GPT-4o) - weekend testing successful- **[GitHub Pages](https://danmartinez78.github.io/shadowhound/)** - Material theme site (from main)

  - DIMOS framework integration

  - Camera feed streaming (QoS matched)- ⚠️ vLLM local on Thor AGX (Mistral 7B) - recent testing partial success- **[Project Overview Hub](docs/project_overview/project_overview_hub.md)** - Vision, MVP, status

  - Custom web UI dashboard

  - Configuration system- **[Development Log](docs/development/devlog.md)** - Daily timeline



</td>**Infrastructure**:- **[Experiments](docs/development/experiments/)** - Detailed experimental work

<td width="50%">

- Complete ROS2 Humble dev environment (devcontainer)

### 📊 Development Stats

- **389 commits** in 10 days *(Oct 3-13)*- DIMOS framework integration (git submodule)**For Contributors**: See [AGENTS.md](AGENTS.md) for authoring guidelines.

- **3,500 LOC** across packages

- **6,271 lines** contributed to DIMOS docs- Custom web UI dashboard

- **187 markdown files** organized

- **8x velocity** with cloud agents- Camera feed streaming (QoS matched - BEST_EFFORT)---



### 🤖 Hardware Validated- Configuration system (.env files)

- ✅ Physical Unitree Go2 testing

- ✅ SLAM + Nav2 navigation- Network topology: Desktop → Laptop (192.168.10.167) → Thor (192.168.10.116) → Go2## Architecture

- ✅ Camera, LiDAR, IMU, odometry

- ✅ Network architecture validated

- ✅ Motion commands executed

**Documentation** (187 markdown files):Four-layer stack built on DIMOS framework:

### ⚠️ Known Constraints

- WebRTC API skills non-functional- Comprehensive architecture docs

- MockRobot not implemented

- Thor GPU degraded (37→5 tok/s)- Cloud agent workflow (8x velocity proven)```

- Custom skills needed

- Hub structure for navigationApplication  → Launch files, configs, deployment

</td>

</tr>- Auto-sync to Wiki + GitHub PagesAgent        → LLM/VLM orchestration, mission planning  

</table>

- Experiment documentation systemSkills       → Execution engine, safety, telemetry

> 📖 **Deep Dive**: [Project History Oct 2025](docs/history/project_history_oct_2025.md) • [Development Log](docs/development/devlog.md)

Robot        → ROS2 bridge to go2_ros2_sdk hardware

---

**Hardware Testing**:```

## 🏛️ Architecture

- ✅ Successfully executed motion commands on physical Unitree Go2

```

┌─────────────────────────────────────────────────────┐- ✅ SLAM + Nav2 tested**Core Packages**:

│  Application Layer                                  │

│  • Launch files  • Configurations  • Deployment    │- ✅ Camera, LiDAR, IMU, odometry operational- `shadowhound_bringup/` - Launch files

└─────────────────────────────────────────────────────┘

                         ↓- ✅ Network architecture validated- `shadowhound_mission_agent/` - Mission execution node (~2,100 LOC)

┌─────────────────────────────────────────────────────┐

│  Agent Layer (shadowhound_mission_agent)            │- `shadowhound_skills/` - Skills registry (scaffolded)

│  • LLM/VLM orchestration  • Mission planning       │

│  • Natural language processing  • Memory systems   │### ⚠️ Known Constraints

└─────────────────────────────────────────────────────┘

                         ↓See **[Architecture Hub](docs/architecture/architecture_hub.md)** for details.

┌─────────────────────────────────────────────────────┐

│  Skills Layer (DIMOS MyUnitreeSkills)               │- **WebRTC API Skills**: Majority of DIMOS MyUnitreeSkills use WebRTC API and are non-functional (working with limited skill set)

│  • ~30 behaviors  • Safety validation              │

│  • Telemetry collection  • Error handling          │- **MockRobot**: Not implemented (blocks hardware-free development)---

└─────────────────────────────────────────────────────┘

                         ↓- **Thor GPU**: Performance degraded (37→5 tok/s) - needs investigation

┌─────────────────────────────────────────────────────┐

│  Robot Layer (go2_ros2_sdk)                         │- **Custom Skills**: None beyond DIMOS built-ins## Development

│  • ROS2 bridge  • Hardware abstraction             │

│  • Sensor fusion  • Motor control                  │

└─────────────────────────────────────────────────────┘

```### 📈 Development Velocity**Helpful Aliases** (pre-configured):



### 📦 Core Packages```bash



| Package | Purpose | Status |- **389 commits** in 10 days (Oct 3-13)cb              # colcon build --symlink-install

|---------|---------|--------|

| `shadowhound_bringup` | Launch files, configurations | ✅ Operational |- **3,500 LOC** across ShadowHound packagessource-ws       # source install/setup.bash

| `shadowhound_mission_agent` | Mission execution, web UI | ✅ 2,100 LOC |

| `shadowhound_skills` | Skills registry | 🏗️ Scaffolded |- **6,271 lines** contributed to DIMOS upstream docscbr             # build and source combined

| `dimos-unitree` | DIMOS framework | ✅ Integrated |

- **8x velocity** on documentation with cloud agentsrosdep-install  # install dependencies

> 🏛️ **Learn More**: [Architecture Hub](docs/architecture/architecture_hub.md) • [Software Hub](docs/software/software_hub.md)

```

---

See [Project History](docs/history/project_history_oct_2025.md) for complete Oct 3-13 timeline.

## 🎯 MVP Roadmap

**Key Guides**:

**Goal**: Household assistant with vision, voice, and semantic navigation

---- **[Development Hub](docs/development/development_hub.md)** - Complete dev guide

### Success Criteria

- **[Cloud Agent Workflow](docs/development/cloud_agent_workflow.md)** - 8x velocity collaboration

- ✅ Accept voice OR console/web commands

- ✅ Execute vision-based missions  ## MVP: Embodied AI Platform- **[Copilot Instructions](.github/copilot-instructions.md)** - AI agent guide

- ✅ Navigate safely with SLAM

- ⏳ Respond with voice + personality

- ⏳ Process onboard Thor AGX *(no cloud dependency)*

- ⏳ Learn and remember spatial information**Primary Goal**: Build an embodied AI platform for exploring transformer-based robotics, not limited to any single application domain.---



### Current Milestone: Vision Foundation



**Focus**: Establish object detection baseline**Why Transformers in Robotics**:## MVP Roadmap

- Test DIMOS perception stack vs VLM branch (Qwen)

- Compare accuracy, latency, compute budget- **LLM**: Mission planning, reasoning, natural language understanding

- Choose vision approach for MVP

- **VLM**: Scene understanding, visual question answering**🎯 Goal**: Household assistant with vision, voice, semantic navigation

### Test Missions

- **VLA**: Direct visuomotor control (future/stretch goal)

```python

"Find the red ball in the living room"**Current Focus**: Milestone 1 - Vision Foundation

"Check if the oven is on"

"Navigate to the kitchen and describe what you see"**Initial Test Missions** (household scenarios for validation):- Test DIMOS perception vs VLM branch

```

- "Find the red ball in the living room"- Establish object detection baseline

> 🗺️ **Full Plan**: [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md) • [Project Overview Hub](docs/project_overview/project_overview_hub.md)

- "Check if the oven is on"- Choose vision approach

---

- "Navigate to the kitchen"

## 🛠️ Development

**Recent Work** (Oct 14, 2025):

### Pre-configured Aliases

**Note**: Household missions are concrete test scenarios to validate the platform's capabilities. The architecture is designed for broader applications beyond domestic environments.- ✅ MVP roadmap defined (5 milestones)

```bash

cb              # colcon build --symlink-install- ✅ Project overview consolidated (14 → 6 files)

source-ws       # source install/setup.bash  

cbr             # build and source combined**Success Criteria**:- ✅ Experiment docs system created

rosdep-install  # install ROS dependencies

```1. Accept voice OR console/web commands- ✅ Wiki auto-sync working (dev + main)



### Creating a Package2. Execute vision-based missions- ✅ Dual LLM backends (OpenAI + vLLM)



```bash3. Navigate safely with SLAM

cd src/

ros2 pkg create --build-type ament_python \4. Respond with voice + personality**Known Constraints**:

    --dependencies rclpy std_msgs \

    shadowhound_<name>5. Process onboard Thor AGX (no cloud dependency)- WebRTC API skills non-functional



cb --packages-select shadowhound_<name> && source-ws6. Learn and remember spatial information- Thor compute budget unknown

```

- MockRobot not implemented

### Development Workflow

See **[MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)** for complete specification.

```bash

# 1. Create feature branchSee **[MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)** and **[Project History](docs/history/project_history_oct_2025.md)** (389 commits analyzed).

git checkout -b feature/my-feature

---

# 2. Make changes and test

cb && source-ws---

pytest src/shadowhound_<package>/test/

## Architecture

# 3. Format and lint

black src/ --line-length 99## Key Documentation

isort src/

flake8 src/ --max-line-length 99### Four-Layer Stack



# 4. Commit with conventional commits**Project Planning**:

git commit -m "feat(skills): add navigation behavior"

```- [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)

# 5. Push and create PR

git push origin feature/my-featureApplication  → Launch files, configs, deployment- [Project Overview Hub](docs/project_overview/project_overview_hub.md)

```

Agent        → LLM/VLM reasoning, mission planning  - [Development Log](docs/development/devlog.md)

> 🔧 **Guides**: [Development Hub](docs/development/development_hub.md) • [Cloud Agent Workflow](docs/development/cloud_agent_workflow.md) • [Copilot Instructions](.github/copilot-instructions.md)

Skills       → DIMOS execution engine (~30 behaviors)- [Experiments](docs/development/experiments/)

---

Robot        → ROS2 bridge to go2_ros2_sdk

## 📚 Documentation

```**Development**:

<div align="center">

- [Development Hub](docs/development/development_hub.md)

| Resource | Description |

|----------|-------------|**Core Packages**:- [Cloud Agent Workflow](docs/development/cloud_agent_workflow.md)

| [📖 **GitHub Wiki**](https://github.com/danmartinez78/shadowhound/wiki) | Complete documentation *(auto-syncs from dev/main)* |

| [🌐 **GitHub Pages**](https://danmartinez78.github.io/shadowhound/) | Material theme site *(from main branch)* |- `shadowhound_bringup/` - Launch files and configs- [Agent Guidelines](AGENTS.md)

| [🎯 **MVP Roadmap**](docs/project_overview/mvp_embodied_ai_platform.md) | 5 milestones, success criteria |

| [🏛️ **Architecture Hub**](docs/architecture/architecture_hub.md) | System design, layer details |- `shadowhound_mission_agent/` - Mission execution (~2,100 LOC implemented)- [Copilot Instructions](.github/copilot-instructions.md)

| [📋 **Development Log**](docs/development/devlog.md) | Daily timeline *(Oct 14+)* |

| [📜 **Project History**](docs/history/project_history_oct_2025.md) | 389 commits analyzed *(Oct 3-13)* |- `shadowhound_skills/` - Skills registry (scaffolded)

| [🔬 **Experiments**](docs/development/experiments/) | Detailed experimental work |

- `dimos-unitree/` - DIMOS framework (git submodule)**Technical**:

</div>

- [Architecture Hub](docs/architecture/architecture_hub.md)

---

**Network Topology** (actual deployment):- [Software Hub](docs/software/software_hub.md)

## 🤝 Contributing

- Laptop: Agent + ROS2 + Mission execution- [Networking Hub](docs/networking/networking_hub.md)

We welcome contributions! Please follow these principles:

- Thor AGX: vLLM backend (when not using cloud)

### Development Principles

- Go2: Physical robot hardware---

1. **🐳 Container-First**: Always develop in devcontainer

2. **🎯 Skills-First**: Robot control through skills API, not ad-hoc code- ROS_DOMAIN_ID=42 for isolation

3. **🛡️ Safety-First**: Validate inputs, implement timeouts, clamp velocities

4. **✅ Test-Driven**: Write tests alongside implementation## Contributing

5. **📝 Document**: Update docs as you work

See [Architecture Hub](docs/architecture/architecture_hub.md) for details.

### Code Standards

**Development Principles**:

```bash

# Format with Black & isort---1. Container-first development

black src/ --line-length 99

isort src/2. Skills-first robot control



# Lint with flake8 & mypy## Documentation3. Safety-first validation

flake8 src/ --max-line-length 99

mypy src/4. Test-driven implementation  

```

📚 **View Documentation:**5. Document as you go

### Commit Convention

- **[GitHub Wiki](https://github.com/danmartinez78/shadowhound/wiki)** - Auto-syncs from dev and main

```bash

feat(scope): add new feature- **[GitHub Pages](https://danmartinez78.github.io/shadowhound/)** - Material theme (main branch)**Code Style**:

fix(scope): fix bug

docs(scope): update documentation- **[Project Overview Hub](docs/project_overview/project_overview_hub.md)** - Vision, MVP, status```bash

test(scope): add tests

refactor(scope): refactor code- **[Development Log](docs/development/devlog.md)** - Daily timeline (Oct 14+)# Format

```

- **[Project History](docs/history/project_history_oct_2025.md)** - Oct 3-13 comprehensive historyblack src/ --line-length 99

> 📘 **Contributing Guide**: [AGENTS.md](AGENTS.md) • [Development Hub](docs/development/development_hub.md)

- **[Experiments](docs/development/experiments/)** - Detailed experimental workisort src/

---



## 🌟 Recent Highlights

**For Contributors**: See [AGENTS.md](AGENTS.md) for authoring guidelines.# Lint

### Today (Oct 14, 2025)

- ✅ MVP roadmap defined with 5 milestonesflake8 src/ --max-line-length 99

- ✅ Project overview consolidated (14 → 6 files)

- ✅ Experiment documentation system created---mypy src/

- ✅ Wiki auto-sync operational (dev + main)

- ✅ Main branch protected (requires PR + status checks)```

- ✅ README redesigned with professional formatting

## Development

### This Week (Oct 3-13, 2025)

- ✅ Built mission agent from scratch (~2,100 LOC)**Commits**: Use conventional commits (`feat:`, `fix:`, `docs:`, etc.)

- ✅ Integrated DIMOS framework (feature branch → tested → merged)

- ✅ Validated on physical Unitree Go2 (dual LLM backends)### Helpful Aliases (Pre-configured)

- ✅ Created custom FastAPI web UI (479 LOC)

- ✅ Integrated local LLM (vLLM + Mistral on Thor AGX)---

- ✅ Organized 187 documentation files

- ✅ Established cloud agent workflow (8x velocity)```bash



> 📅 **Timeline**: [Development Log](docs/development/devlog.md) • [Project History](docs/history/project_history_oct_2025.md)cb              # colcon build --symlink-install## License



---source-ws       # source install/setup.bash



## 📊 Project Statscbr             # build and source combined[Add license]



```rosdep-install  # install dependencies

📦 Packages:        9 ROS2 packages

📝 Documentation:   187 markdown files```## Acknowledgments

🧪 Tests:           223 LOC (mission agent)

💻 Code:            ~3,500 LOC (ShadowHound packages)

📚 DIMOS Contrib:   6,271 lines (upstream docs)

⏱️ Development:     10 days (Oct 3-13, 2025)### Creating a New Package- [ROS2 Humble](https://docs.ros.org/en/humble/)

✨ Commits:         389 commits analyzed

```- [go2_ros2_sdk](https://github.com/unitreerobotics/go2_ros2_sdk)



---```bash- [DIMOS framework](https://github.com/Dorteel/dimos-unitree)



## 🙏 Acknowledgmentscd src/



Built with open-source excellence:ros2 pkg create --build-type ament_python \---



- **[ROS2 Humble](https://docs.ros.org/en/humble/)** - Robot Operating System    --dependencies rclpy std_msgs \

- **[go2_ros2_sdk](https://github.com/unitreerobotics/go2_ros2_sdk)** - Unitree Go2 integration

- **[DIMOS](https://github.com/Dorteel/dimos-unitree)** - LLM orchestration framework    shadowhound_<name>**Ready to develop?** Check [Development Hub](docs/development/development_hub.md) and [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md)!

- **[Unitree Go2](https://www.unitree.com/go2/)** - Quadruped robot platform



---cb --packages-select shadowhound_<name> && source-ws

```

## 📄 License

### Key Development Guides

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

- [Development Hub](docs/development/development_hub.md) - Complete dev guide

---- [Cloud Agent Workflow](docs/development/cloud_agent_workflow.md) - 8x velocity collaboration

- [Copilot Instructions](.github/copilot-instructions.md) - AI agent guide

<div align="center">- [Agent Guidelines](AGENTS.md) - Repository-wide authoring rules



**Ready to explore embodied AI?**---



[🚀 Get Started](docs/development/development_hub.md) • ## Recent Accomplishments (Oct 14, 2025)

[📖 Read the Docs](https://danmartinez78.github.io/shadowhound/) • 

[🎯 View MVP](docs/project_overview/mvp_embodied_ai_platform.md)**Today's Work**:

- ✅ MVP roadmap defined with 5 milestones

---- ✅ Project overview consolidated (14 → 6 files)

- ✅ Experiment documentation system created

*Built with ❤️ for robotics research and transformer architecture exploration*- ✅ Wiki infrastructure operational (auto-sync working)

- ✅ Main branch protected (requires PR, status checks)

</div>- ✅ README corrected to reflect actual system state


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
