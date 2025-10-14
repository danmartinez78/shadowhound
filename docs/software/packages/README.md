---
tags: [software, packages, ros2, index]
status: active
related: [software_hub.md, autodoc/_index.md]
summary: >
  Index of all ShadowHound ROS2 packages with links to documentation
---

# ShadowHound ROS2 Packages

**Purpose**: Index of all ROS2 packages in the ShadowHound workspace  
**Audience**: Developers, AI agents, contributors  
**Maintenance**: Update when adding/removing packages

---

## Package Overview

ShadowHound consists of three core ROS2 packages that integrate with the DIMOS framework:

| Package | Type | Purpose | Status |
|---------|------|---------|--------|
| [shadowhound_bringup](#shadowhound_bringup) | ament_cmake | Launch files and system configuration | ✅ Active |
| [shadowhound_skills](#shadowhound_skills) | ament_python | Vision skills extending DIMOS | ✅ Active |
| [shadowhound_mission_agent](#shadowhound_mission_agent) | ament_python | ROS2 wrapper for DIMOS agents | ✅ Active |

---

## shadowhound_bringup

**Type**: `ament_cmake`  
**Location**: `src/shadowhound_bringup/`  
**Documentation**: [README](shadowhound_bringup/README.md)

### Purpose
Launch files and configurations for the complete ShadowHound system, integrating DIMOS and ShadowHound components.

### Key Features
- Main system launch file (`shadowhound.launch.py`)
- Mock robot support for development
- Configurable agent backends (cloud/local)
- Environment and parameter management

### Quick Start
```bash
ros2 launch shadowhound_bringup shadowhound.launch.py
```

---

## shadowhound_skills

**Type**: `ament_python`  
**Location**: `src/shadowhound_skills/`  
**Documentation**: [README](shadowhound_skills/README.md)

### Purpose
Vision capabilities for ShadowHound using DIMOS Qwen VLM integration. Provides 4 vision skills that enable the robot to understand its visual environment.

### Key Features
- **vision.snapshot** - Capture and save camera frames
- **vision.describe_scene** - Get VLM description of scenes
- **vision.locate_object** - Find specific objects with bounding boxes
- **vision.detect_objects** - Detect all prominent objects in view

### Key Technologies
- DIMOS Qwen VLM integration
- Alibaba Cloud API for vision models
- PIL and OpenCV for image processing

---

## shadowhound_mission_agent

**Type**: `ament_python`  
**Location**: `src/shadowhound_mission_agent/`  
**Documentation**: 
- [README](shadowhound_mission_agent/README.md) - Overview and usage
- [Agent Architecture](shadowhound_mission_agent/agent_architecture.md) - Architecture design
- [Agent Design](shadowhound_mission_agent/agent_design.md) - Detailed design docs
- [Web Interface](shadowhound_mission_agent/web_interface.md) - Web dashboard docs

### Purpose
ROS2 package that provides autonomous mission execution for the Unitree Go2 robot using the DIMOS framework. Acts as the integration layer between ROS2 and DIMOS agents.

### Key Features
- Natural language mission commands via ROS2 topics
- DIMOS agent integration (OpenAI, Planning)
- 40+ robot skills accessible
- Mock robot support for development
- Web dashboard for robot control
- Flexible LLM backend configuration

### ROS2 Interface
- **Subscribes**: `/mission_command` (std_msgs/String)
- **Publishes**: `/mission_status` (std_msgs/String)
- **Parameters**: `agent_backend`, `mock_robot`, `use_planning_agent`

### Quick Start
```bash
ros2 launch shadowhound_mission_agent mission_agent.launch.py
ros2 topic pub /mission_command std_msgs/String "data: 'stand up and wave'"
```

---

## External Dependencies

### DIMOS Framework
- **Location**: `src/dimos-unitree/` (git submodule)
- **Purpose**: Core robotics framework providing agents, skills, and robot abstraction
- **Repository**: https://github.com/danmartinez78/dimos-unitree

### go2_ros2_sdk
- **Location**: Nested in DIMOS as submodule
- **Purpose**: Low-level Unitree Go2 SDK with ROS2 bridge
- **Repository**: https://github.com/danmartinez78/go2_ros2_sdk

---

## Development Workflow

### Building Packages
```bash
# Build all packages
colcon build --symlink-install

# Build specific package
colcon build --packages-select shadowhound_mission_agent

# Source workspace
source install/setup.bash
```

### Testing Packages
```bash
# Run all tests
colcon test

# Test specific package
colcon test --packages-select shadowhound_skills

# View test results
colcon test-result --verbose
```

### Package Dependencies
```bash
# Check dependencies
rosdep check --from-paths src --ignore-src

# Install missing dependencies
rosdep install --from-paths src --ignore-src -r -y
```

---

## Adding a New Package

### 1. Create Package Structure
```bash
cd src/
ros2 pkg create --build-type ament_python \
    --dependencies rclpy std_msgs \
    shadowhound_<name>
```

### 2. Add Documentation
Create `docs/software/packages/shadowhound_<name>/README.md` with:
- Purpose and overview
- Key features
- Installation instructions
- Usage examples
- Testing information

### 3. Update This Index
Add entry to the table and detailed section in this file.

### 4. Update Related Documentation
- Update `docs/software/software_hub.md`
- Update `docs/project_overview/mvp_embodied_ai_platform.md` if relevant
- Update `.github/copilot-instructions.md` if needed

---

## Package Standards

### Code Style
- **Python**: black (99 chars), isort, flake8
- **ROS2**: Follow [ROS2 style guide](https://docs.ros.org/en/humble/The-ROS2-Project/Contributing/Code-Style-Language-Versions.html)
- **Commits**: [Conventional commits](https://www.conventionalcommits.org/)
- **Docstrings**: Google style

### Documentation Requirements
Each package must have:
- ✅ README.md with clear purpose and usage
- ✅ Type hints on all functions
- ✅ Unit tests with reasonable coverage
- ✅ Integration test examples
- ✅ Dependencies listed in `package.xml`

### Testing Requirements
- ✅ Unit tests for core functionality
- ✅ Integration tests for ROS2 interfaces
- ✅ Mock-based tests that don't require hardware
- ✅ CI/CD compatible tests

---

## References

- **Project Overview**: `docs/project_overview/mvp_embodied_ai_platform.md`
- **Software Hub**: `docs/software/software_hub.md`
- **Autodoc Index**: `docs/software/autodoc/_index.md`
- **Source Code**: `src/` directory
- **DIMOS Docs**: `src/dimos-unitree/README.md`

---

**Last Updated**: 2025-10-14  
**Maintained By**: ShadowHound Development Team
