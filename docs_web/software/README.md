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
3. Use [Autodoc landing](software/autodoc/_index.md) to locate generated package references.

### Quick Links
- [ROS 2 Workstation Setup](software/ros2_setup.md)
- [Script Catalog](software/scripts.md)
- [Environment Configuration Guide](software/environment_configuration.md)
- [Start Script Reference](software/start_script_reference.md)
- [DIMOS Integration Quick Start](software/dimos_quick_start.md)
- [Isaac Sim Remote Streaming](software/isaac_sim_remote.md)
- [Autodoc Index](software/autodoc/_index.md)

## Validation
- [ ] Autodoc stubs regenerate without errors.
- [ ] All setup guides reference validated commands.
- [ ] MkDocs navigation renders the same hierarchy as the vault.

## References
- [Vault Index](../index.md)
- `tools/ros2_autodoc.py`
- `tools/link_convert.py`
