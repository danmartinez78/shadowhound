<div align="center">

# 🐺 ShadowHound

### Embodied AI Robot Platform

*Exploring transformer architectures in robotics through natural language mission execution*

[![ROS2 Humble](https://img.shields.io/badge/ROS2-Humble-blue?logo=ros)](https://docs.ros.org/en/humble/)
[![Platform](https://img.shields.io/badge/Platform-Unitree%20Go2-orange)](https://www.unitree.com/go2/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Dev Status](https://img.shields.io/badge/Status-Active%20Development-yellow)](docs/project_overview/mvp_embodied_ai_platform.md)

[📚 **Documentation**](https://danmartinez78.github.io/shadowhound/) • 
[🎯 **MVP Roadmap**](docs/project_overview/mvp_embodied_ai_platform.md) • 
[📖 **Wiki**](https://github.com/danmartinez78/shadowhound/wiki) • 
[🔬 **Experiments**](docs/development/experiments/)

</div>

---

## 🎯 Project Vision

**ShadowHound** is an embodied AI platform for hands-on exploration of transformer architectures in robotics. Built on the Unitree Go2 quadruped, it combines ROS2 navigation with LLM/VLM-driven task planning to execute natural language missions.

### Why This Project?

- 🧠 **LLM Integration**: Mission planning, reasoning, natural language understanding
- 👁️ **Vision Models (VLM)**: Scene understanding, visual question answering  
- 🤖 **Visuomotor Actions (VLA)**: Direct perception-to-action control *(stretch goal)*

**Note**: While initial test missions focus on household scenarios ("Find the red ball"), the architecture is designed for broader embodied AI research beyond domestic applications.

---

## ⚡ Quick Start

### Prerequisites

- Docker Desktop
- VS Code with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Git with submodule support

### Setup

```bash
# 1. Clone repository with submodules
git clone --recurse-submodules https://github.com/danmartinez78/shadowhound.git
cd shadowhound

# 2. Open in VS Code and reopen in container
code .

# 3. Build workspace
cb && source-ws

# 4. Verify installation
ros2 pkg list | grep shadowhound
```

✅ **Ready!** The dev container includes ROS2 Humble, DIMOS framework, and all dependencies.

---

## 🏗️ What's Built

<table>
<tr>
<td width="50%">

### ✅ Working System

**Mission Agent** (~2,100 LOC):
- `mission_agent.py` (713 LOC) - ROS2 node
- `mission_executor.py` (517 LOC) - Cognitive layer
- `web_interface.py` (479 LOC) - FastAPI dashboard
- `rag_memory_example.py` (392 LOC) - Memory patterns
- Unit tests (223 LOC)

**LLM Backends** *(hardware validated)*:
- ✅ OpenAI cloud (GPT-4o)
- ⚠️ vLLM local (Mistral 7B on Thor AGX)

**Infrastructure**:
- Complete ROS2 dev environment
- DIMOS framework integration
- Camera feed streaming (QoS matched)
- Custom web UI dashboard
- Configuration system

</td>
<td width="50%">

### 📊 Development Stats

- **389 commits** in 10 days *(Oct 3-13)*
- **3,500 LOC** across packages
- **6,271 lines** contributed to DIMOS docs
- **187 markdown files** organized
- **8x velocity** with cloud agents

### 🤖 Hardware Validated

- ✅ Physical Unitree Go2 testing
- ✅ SLAM + Nav2 navigation
- ✅ Camera, LiDAR, IMU, odometry
- ✅ Network architecture validated
- ✅ Motion commands executed

### ⚠️ Known Constraints

- WebRTC API skills non-functional
- MockRobot not implemented
- Thor GPU degraded (37→5 tok/s)
- Custom skills needed

</td>
</tr>
</table>

> 📖 **Deep Dive**: [Project History Oct 2025](docs/history/project_history_oct_2025.md) • [Development Log](docs/development/devlog.md)

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────┐
│  Application Layer                                  │
│  • Launch files  • Configurations  • Deployment    │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Agent Layer (shadowhound_mission_agent)            │
│  • LLM/VLM orchestration  • Mission planning       │
│  • Natural language processing  • Memory systems   │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Skills Layer (DIMOS MyUnitreeSkills)               │
│  • ~30 behaviors  • Safety validation              │
│  • Telemetry collection  • Error handling          │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Robot Layer (go2_ros2_sdk)                         │
│  • ROS2 bridge  • Hardware abstraction             │
│  • Sensor fusion  • Motor control                  │
└─────────────────────────────────────────────────────┘
```

### 📦 Core Packages

| Package | Purpose | Status |
|---------|---------|--------|
| `shadowhound_bringup` | Launch files, configurations | ✅ Operational |
| `shadowhound_mission_agent` | Mission execution, web UI | ✅ 2,100 LOC |
| `shadowhound_skills` | Skills registry | 🏗️ Scaffolded |
| `dimos-unitree` | DIMOS framework | ✅ Integrated |

> 🏛️ **Learn More**: [Architecture Hub](docs/architecture/architecture_hub.md) • [Software Hub](docs/software/software_hub.md)

---

## 🎯 MVP Roadmap

**Goal**: Household assistant with vision, voice, and semantic navigation

### Success Criteria

- ✅ Accept voice OR console/web commands
- ✅ Execute vision-based missions  
- ✅ Navigate safely with SLAM
- ⏳ Respond with voice + personality
- ⏳ Process onboard Thor AGX *(no cloud dependency)*
- ⏳ Learn and remember spatial information

### Current Milestone: Vision Foundation

**Focus**: Establish object detection baseline
- Test DIMOS perception stack vs VLM branch (Qwen)
- Compare accuracy, latency, compute budget
- Choose vision approach for MVP

### Test Missions

```python
"Find the red ball in the living room"
"Check if the oven is on"
"Navigate to the kitchen and describe what you see"
```

> 🗺️ **Full Plan**: [MVP Roadmap](docs/project_overview/mvp_embodied_ai_platform.md) • [Project Overview Hub](docs/project_overview/project_overview_hub.md)

---

## 🛠️ Development

### Pre-configured Aliases

```bash
cb              # colcon build --symlink-install
source-ws       # source install/setup.bash  
cbr             # build and source combined
rosdep-install  # install ROS dependencies
```

### Creating a Package

```bash
cd src/
ros2 pkg create --build-type ament_python \
    --dependencies rclpy std_msgs \
    shadowhound_<name>

cb --packages-select shadowhound_<name> && source-ws
```

### Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes and test
cb && source-ws
pytest src/shadowhound_<package>/test/

# 3. Format and lint
black src/ --line-length 99
isort src/
flake8 src/ --max-line-length 99

# 4. Commit with conventional commits
git commit -m "feat(skills): add navigation behavior"

# 5. Push and create PR
git push origin feature/my-feature
```

> 🔧 **Guides**: [Development Hub](docs/development/development_hub.md) • [Cloud Agent Workflow](docs/development/cloud_agent_workflow.md) • [Copilot Instructions](.github/copilot-instructions.md)

---

## 📚 Documentation

<div align="center">

| Resource | Description |
|----------|-------------|
| [📖 **GitHub Wiki**](https://github.com/danmartinez78/shadowhound/wiki) | Complete documentation *(auto-syncs from dev/main)* |
| [🌐 **GitHub Pages**](https://danmartinez78.github.io/shadowhound/) | Material theme site *(from main branch)* |
| [🎯 **MVP Roadmap**](docs/project_overview/mvp_embodied_ai_platform.md) | 5 milestones, success criteria |
| [🏛️ **Architecture Hub**](docs/architecture/architecture_hub.md) | System design, layer details |
| [📋 **Development Log**](docs/development/devlog.md) | Daily timeline *(Oct 14+)* |
| [📜 **Project History**](docs/history/project_history_oct_2025.md) | 389 commits analyzed *(Oct 3-13)* |
| [🔬 **Experiments**](docs/development/experiments/) | Detailed experimental work |

</div>

---

## 🤝 Contributing

We welcome contributions! Please follow these principles:

### Development Principles

1. **🐳 Container-First**: Always develop in devcontainer
2. **🎯 Skills-First**: Robot control through skills API, not ad-hoc code
3. **🛡️ Safety-First**: Validate inputs, implement timeouts, clamp velocities
4. **✅ Test-Driven**: Write tests alongside implementation
5. **📝 Document**: Update docs as you work

### Code Standards

```bash
# Format with Black & isort
black src/ --line-length 99
isort src/

# Lint with flake8 & mypy
flake8 src/ --max-line-length 99
mypy src/
```

### Commit Convention

```bash
feat(scope): add new feature
fix(scope): fix bug
docs(scope): update documentation
test(scope): add tests
refactor(scope): refactor code
```

> 📘 **Contributing Guide**: [AGENTS.md](AGENTS.md) • [Development Hub](docs/development/development_hub.md)

---

## 🌟 Recent Highlights

### Today (Oct 14, 2025)

- ✅ MVP roadmap defined with 5 milestones
- ✅ Project overview consolidated (14 → 6 files)
- ✅ Experiment documentation system created
- ✅ Wiki auto-sync operational (dev + main)
- ✅ Main branch protected (requires PR + status checks)
- ✅ Root directory cleaned and organized

### This Week (Oct 3-13, 2025)

- ✅ Built mission agent from scratch (~2,100 LOC)
- ✅ Integrated DIMOS framework (feature branch → tested → merged)
- ✅ Validated on physical Unitree Go2 (dual LLM backends)
- ✅ Created custom FastAPI web UI (479 LOC)
- ✅ Integrated local LLM (vLLM + Mistral on Thor AGX)
- ✅ Organized 187 documentation files
- ✅ Established cloud agent workflow (8x velocity)

> 📅 **Timeline**: [Development Log](docs/development/devlog.md) • [Project History](docs/history/project_history_oct_2025.md)

---

## 📊 Project Stats

```
📦 Packages:        9 ROS2 packages
📝 Documentation:   187 markdown files
🧪 Tests:           223 LOC (mission agent)
�� Code:            ~3,500 LOC (ShadowHound packages)
📚 DIMOS Contrib:   6,271 lines (upstream docs)
⏱️ Development:     10 days (Oct 3-13, 2025)
✨ Commits:         389 commits analyzed
```

---

## �� Acknowledgments

Built with open-source excellence:

- **[ROS2 Humble](https://docs.ros.org/en/humble/)** - Robot Operating System
- **[go2_ros2_sdk](https://github.com/unitreerobotics/go2_ros2_sdk)** - Unitree Go2 integration
- **[DIMOS](https://github.com/Dorteel/dimos-unitree)** - LLM orchestration framework
- **[Unitree Go2](https://www.unitree.com/go2/)** - Quadruped robot platform

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Ready to explore embodied AI?**

[🚀 Get Started](docs/development/development_hub.md) • 
[📖 Read the Docs](https://danmartinez78.github.io/shadowhound/) • 
[🎯 View MVP](docs/project_overview/mvp_embodied_ai_platform.md)

---

*Built with ❤️ for robotics research and transformer architecture exploration*

</div>
