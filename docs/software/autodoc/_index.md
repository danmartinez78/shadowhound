---
tags: [software, autodoc]
status: draft
related: []
summary: >
  Auto-generated ROS 2 package documentation hub for ShadowHound.
---

# Autodoc Index

## Purpose
Track auto-generated documentation for each ShadowHound ROS 2 package.

## Prerequisites
- Completed ROS 2 workspace setup per [[../ros2_setup|ROS 2 Workstation Setup]].
- Python 3.10+ available for running the autodoc tooling.
- `docstring_parser` library installed for API documentation extraction.

## Steps
1. Execute `python tools/ros2_autodoc.py` from the repository root after adding or updating packages.
2. Execute `python tools/ros2_autodoc.py --api` to generate API reference documentation from Python docstrings.
3. Review generated Markdown files under `docs/software/autodoc/` for accuracy and fill in manual details as needed.
4. Commit regenerated documentation using the `docs(<area>): <summary>` convention.

## Package Documentation

### ShadowHound Packages

- [[shadowhound_mission_agent|shadowhound_mission_agent]] - Mission agent for autonomous control
  - [[shadowhound_mission_agent_api|API Reference]]
- [[shadowhound_skills|shadowhound_skills]] - Mission-specific skills
  - [[shadowhound_skills_api|API Reference]]
- [[shadowhound_bringup|shadowhound_bringup]] - Launch files and configurations

## Validation
- [ ] Script runs without errors and updates package docs.
- [ ] Generated docs include the correct dependencies and launch files.
- [ ] API documentation includes classes, methods, and docstrings.
- [ ] MkDocs and the Wiki reflect the new pages after CI completes.

## References
- `tools/ros2_autodoc.py`
- [[index|Software Index]]
- [Repository README](../../../README.md)
