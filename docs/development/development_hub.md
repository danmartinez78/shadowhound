---
tags: [development, index]
status: active
related: []
aliases: [Development Index]
summary: >
  Development documentation index covering policies, workflows, contribution guidelines, and process documentation.
---

# Development Index

## Purpose
Central hub for ShadowHound development policies, workflows, and contributor guidelines. This index covers git workflows, DIMOS integration, documentation standards, and development tracking.

## Prerequisites
- Familiarity with git and ROS 2 development workflows
- Access to the ShadowHound repository
- Understanding of the project architecture (see [Architecture Index](../architecture/architecture_hub.md))

## Active Policies & Workflows

### Collaboration & Velocity
- **[Cloud Agent Workflow](../development/cloud_agent_workflow.md)** — ⭐ High-velocity development with GitHub Copilot cloud agents
- **[Merge Checklist](../development/merge_checklist.md)** — Template and example for feature branch merges

### Git & Submodule Management
- **[Git Submodule Policy](../development/submodule_policy.md)** — Standard git workflow for submodules (not vcstool)
- **[DIMOS Development Policy](../development/dimos_development_policy.md)** — Never edit DIMOS in submodule directory; principled workflow
- **[DIMOS Branch Consolidation](../development/dimos_branch_consolidation.md)** — Plan for consolidating divergent branches

### Documentation Standards
- **[Per-Directory Review Plan](../development/per_directory_review_plan.md)** — Systematic documentation cleanup with Obsidian graph optimization
- **[Documentation Cleanup Plan](../development/cleanup_plan.md)** — Master plan for docs organization and GitHub Wiki
- **[PR Checklist: Docs](../development/pr_checklist_docs_cleanup.md)** — Pull request checklist for documentation changes

### Development Tracking
- **[TODO List](../development/todo.md)** — Active development tasks and priorities

## Completed Work

### Cleanup Inventories
- **[Docs Root Cleanup](../development/doc_root_cleanup.md)** — Completed inventory and organization (October 2025)
- **[Project Root Cleanup](../development/project_root_docs_cleanup.md)** — Completed inventory and organization (October 2025)

## Key Principles

### DIMOS Development
> **CRITICAL:** Never edit DIMOS files in the ShadowHound submodule directory (`src/dimos-unitree/`).
> All DIMOS development must happen in a separate clone. See [DIMOS Development Policy](../development/dimos_development_policy.md).

### Documentation Standards
- Use Obsidian-style wikilinks for internal references
- Include front-matter on all Markdown files (tags, status, related, summary)
- Follow section structure: Purpose, Prerequisites, Steps, Validation, References
- Apply hierarchical tags (e.g., `development/policy`, `development/process`)
- Populate "related" fields with 2-5 connected documents
- Add "See Also" sections for horizontal navigation

### Git Workflow
- Feature branches from `dev` branch
- Descriptive commit messages with `docs(<area>):`, `feat(<scope>):`, `fix(<scope>):` prefixes
- Submodules managed with standard git (not vcstool)
- Recursive submodule updates: `git submodule update --init --recursive`

## Common Tasks

### Setting Up Development Environment
1. Clone repository with submodules:
   ```bash
   git clone --recursive https://github.com/danmartinez78/shadowhound.git
   ```

2. Update submodules (if already cloned):
   ```bash
   git submodule update --init --recursive
   ```

3. Follow platform-specific setup guides:
   - [ROS 2 Setup](../software/ros2_setup.md)
   - [DIMOS Quick Start](../integrations/quickstart_dimos.md)

### Contributing Documentation
1. Create feature branch: `git checkout -b docs/<description>`
2. Follow [review plan guidelines](../development/per_directory_review_plan.md)
3. Use [PR checklist](../development/pr_checklist_docs_cleanup.md) before submitting
4. Validate wikilinks: `python tools/validate_wikilinks.py --docs docs`

### Working with DIMOS
1. Clone DIMOS separately: `git clone git@github.com:danmartinez78/dimos-unitree.git`
2. Make changes in separate DIMOS clone
3. Push changes and create PR in dimos-unitree repo
4. Update submodule pointer in ShadowHound after merge
5. See [full policy](../development/dimos_development_policy.md) for details

## Validation
- [ ] All active policies reviewed and up-to-date
- [ ] Documentation standards consistently applied
- [ ] Git workflows documented and validated
- [ ] Legacy content archived appropriately

## See Also
- [Architecture Documentation](../architecture/architecture_hub.md) — System design and components
- [Software Documentation](../software/software_hub.md) — ROS 2 packages and configuration
- [Project Overview](../project_overview/project_overview_hub.md) — Planning, status, and quick-start guides
- [Documentation Root](../development/development_hub.md) — Complete documentation map

## References
- [Documentation Root](../development/development_hub.md)
- Git Submodules Documentation: https://git-scm.com/book/en/v2/Git-Tools-Submodules
- Obsidian Documentation: https://help.obsidian.md/
- GitHub Wiki Best Practices
