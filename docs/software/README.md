---
tags: [software, index]
status: draft
related: []
summary: >
  Software documentation index for ROS 2 packages, simulation, and tooling.
---

# Software Index

## Purpose
Organize the ShadowHound software stack documentation, including ROS 2 packages, simulation tooling, and automation scripts.

## Prerequisites
- Working ROS 2 Humble development environment.
- Familiarity with the repository layout (`src/`, `launch/`, `docs/`).

## Steps
1. Review the quick links below for setup guides and automation tools.
2. Generate auto-documentation stubs by running `python tools/ros2_autodoc.py` after package changes.
3. Use [[software/autodoc/_index|Autodoc landing]] to locate generated package references.

### Quick Links
- [[software/ros2_setup|ROS 2 Workstation Setup]]
- [[software/scripts|Script Catalog]]
- [[software/environment_configuration|Environment Configuration Guide]]
- [[software/start_script_reference|Start Script Reference]]
- [[software/dimos_quick_start|DIMOS Integration Quick Start]]
- [[software/isaac_sim_remote|Isaac Sim Remote Streaming]]
- [[software/autodoc/_index|Autodoc Index]]

## Validation
- [ ] Autodoc stubs regenerate without errors.
- [ ] All setup guides reference validated commands.
- [ ] MkDocs navigation renders the same hierarchy as the vault.

## References
- [[../index|Vault Index]]
- `tools/ros2_autodoc.py`
- `tools/link_convert.py`
