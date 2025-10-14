# ShadowHound Source Code

**Quick Reference**: This directory contains the ShadowHound ROS2 workspace source code.

---

## 📦 ROS2 Packages

ShadowHound consists of three core packages:

| Package | Purpose | Documentation |
|---------|---------|---------------|
| **shadowhound_bringup** | Launch files and system configuration | [📄 Docs](../docs/software/packages/shadowhound_bringup/README.md) |
| **shadowhound_skills** | Vision skills (Qwen VLM integration) | [📄 Docs](../docs/software/packages/shadowhound_skills/README.md) |
| **shadowhound_mission_agent** | ROS2 wrapper for DIMOS agents | [📄 Docs](../docs/software/packages/shadowhound_mission_agent/README.md) |

### External Dependencies
- **dimos-unitree/** - DIMOS framework (git submodule, [upstream fork](https://github.com/danmartinez78/dimos-unitree))

---

## 🚀 Quick Start

### Build Workspace
```bash
# Build all packages
colcon build --symlink-install

# Source workspace
source install/setup.bash
```

### Launch System
```bash
# Launch with mock robot (development)
ros2 launch shadowhound_bringup shadowhound.launch.py

# Launch with real robot
ros2 launch shadowhound_bringup shadowhound.launch.py mock_robot:=false
```

### Test Packages
```bash
# Run all tests
colcon test

# Test specific package
colcon test --packages-select shadowhound_mission_agent
```

---

## 📚 Documentation

### Primary Documentation
- **[Package Index](../docs/software/packages/README.md)** - Comprehensive package documentation
- **[Software Hub](../docs/software/software_hub.md)** - Software architecture and guides
- **[Project Overview](../docs/project_overview/mvp_embodied_ai_platform.md)** - MVP roadmap and scope

### Package-Specific Docs
Each package has detailed documentation in `docs/software/packages/{package_name}/`:
- README.md - Overview, features, and usage
- Additional design and architecture docs where applicable

### Development Guides
- **[ROS2 Setup](../docs/software/ros2_setup.md)** - Environment setup
- **[DIMOS Quick Start](../docs/software/dimos_quick_start.md)** - DIMOS framework guide
- **[Copilot Instructions](../.github/copilot-instructions.md)** - AI agent development patterns

---

## 🔧 Development Workflow

### Creating a New Package
```bash
cd src/
ros2 pkg create --build-type ament_python \
    --dependencies rclpy std_msgs \
    shadowhound_<name>

# Add documentation
mkdir -p docs/software/packages/shadowhound_<name>
# Create docs/software/packages/shadowhound_<name>/README.md
# Update docs/software/packages/README.md
```

### Package Standards
- ✅ Python code: black (99 chars), isort, flake8
- ✅ Type hints on all functions
- ✅ Google-style docstrings
- ✅ Unit tests with pytest
- ✅ Documentation in `docs/software/packages/`

### Code Quality
```bash
# Format
black src/shadowhound_*/shadowhound_*/ --line-length 99
isort src/shadowhound_*/shadowhound_*/

# Lint
flake8 src/shadowhound_*/shadowhound_*/ --max-line-length 99

# Type check
mypy src/shadowhound_*/shadowhound_*/

# Test
colcon test
pytest src/
```

---

## 🏗️ Architecture

### System Layers
```
Application Layer (shadowhound_bringup)
        ↓
DIMOS Agents (mission_agent ROS wrapper)
        ↓
DIMOS Skills + Vision Skills (shadowhound_skills)
        ↓
DIMOS Robot (UnitreeGo2, UnitreeROSControl)
        ↓
Hardware (go2_ros2_sdk)
```

### Key Principles
1. **DIMOS-First** - Leverage DIMOS infrastructure, extend via skills
2. **ROS2 Native** - Standard topics, parameters, and lifecycle
3. **Mock-First** - Develop and test without hardware
4. **Safety-First** - Validation, error handling, and controlled execution
5. **Type-First** - Type hints, structured results, validated inputs

---

## 📖 References

- **[DIMOS Framework](https://github.com/danmartinez78/dimos-unitree)** - Core robotics framework
- **[ROS2 Humble Docs](https://docs.ros.org/en/humble/)** - ROS2 documentation
- **[Unitree Go2](https://www.unitree.com/go2)** - Robot hardware specs
- **[Project Docs](../docs/)** - Complete documentation repository

---

## 🤝 Contributing

See [Package Index](../docs/software/packages/README.md#package-standards) for:
- Code style requirements
- Testing requirements
- Documentation standards
- Pull request process

---

**Need Help?** Check the [Software Hub](../docs/software/software_hub.md) or [Package Documentation](../docs/software/packages/README.md).
