# ShadowHound Documentation

Welcome to the ShadowHound project documentation wiki!

ShadowHound is an autonomous mobile robot system combining ROS2 navigation with LLM/VLM-driven planning for the Unitree Go2 quadruped.

## 📚 Documentation

### Core Documentation
- **[[Project Context|project]]** - Complete architecture and implementation plan
- **[[DIMOS Integration|DIMOS-INTEGRATION]]** - Framework integration details
- **[[DIMOS Capabilities|DIMOS-CAPABILITIES]]** - Available features and APIs
- **[[Architecture Update Summary|ARCH-UPDATE-SUMMARY]]** - Recent architectural changes

## 🚀 Quick Start

See the main repository [README.md](https://github.com/danmartinez78/shadowhound) for quick start instructions.

### Development Setup
1. Clone the repository with devcontainer
2. Install DIMOS dependencies: `vcs import src < shadowhound.repos`
3. Build workspace: `cb` (colcon build --symlink-install)
4. Source environment: `source-ws`

## 🏗️ Architecture

ShadowHound is built on four layers:
1. **Application Layer** - Launch files, configs, deployment
2. **Agent Layer** - LLM/VLM orchestration, mission planning
3. **Skills Layer** - Execution engine, safety, telemetry
4. **Robot Interface** - ROS2 bridge to hardware

Built on the [DIMOS framework](https://github.com/dimensionalOS/dimos-unitree) for robot control and perception.

## 🔗 Links

- **GitHub Repository**: https://github.com/danmartinez78/shadowhound
- **DIMOS Framework**: https://github.com/dimensionalOS/dimos-unitree
- **Unitree Go2 Docs**: https://support.unitree.com/home/en/Go2_developer

## 📝 Contributing

This wiki is automatically synchronized from the `docs/` directory in the main repository. To update documentation:

1. Edit files in `docs/` directory
2. Commit and push to `dev` branch
3. CI automatically syncs to wiki

---

_Last synced: Auto-updated by CI_
