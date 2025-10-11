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

## Steps
1. Execute `python tools/ros2_autodoc.py` from the repository root after adding or updating packages.
2. Review generated Markdown files under `docs/software/autodoc/` for accuracy and fill in manual details as needed.
3. Commit regenerated documentation using the `docs(<area>): <summary>` convention.

## Validation
- [ ] Script runs without errors and updates package docs.
- [ ] Generated docs include the correct dependencies and launch files.
- [ ] MkDocs and the Wiki reflect the new pages after CI completes.

## References
- `tools/ros2_autodoc.py`
- [[../README|Software Index]]
- [Repository README](../../../README.md)
