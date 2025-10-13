---
tags: [development, index]
status: active
related: [development/dimos_development_policy, development/submodule_policy, development/per_directory_review_plan]
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
- Understanding of the project architecture (see [[architecture/architecture_hub|Architecture Index]])

## Active Policies & Workflows

### Git & Submodule Management
- **[[development/submodule_policy|Git Submodule Policy]]** — Standard git workflow for submodules (not vcstool)
- **[[development/dimos_development_policy|DIMOS Development Policy]]** — Never edit DIMOS in submodule directory; principled workflow
- **[[development/dimos_branch_consolidation|DIMOS Branch Consolidation]]** — Plan for consolidating divergent branches

### Documentation Standards
- **[[development/per_directory_review_plan|Per-Directory Review Plan]]** — Systematic documentation cleanup with Obsidian graph optimization
- **[[development/cleanup_plan|Documentation Cleanup Plan]]** — Master plan for docs organization and GitHub Wiki
- **[[development/pr_checklist_docs_cleanup|PR Checklist: Docs]]** — Pull request checklist for documentation changes

### Development Tracking
- **[[development/todo|TODO List]]** — Active development tasks and priorities
- **[[development/merge_checklist|Merge Checklist]]** — Template and example for feature branch merges

## Completed Work

### Cleanup Inventories
- **[[development/doc_root_cleanup|Docs Root Cleanup]]** — Completed inventory and organization (October 2025)
- **[[development/project_root_docs_cleanup|Project Root Cleanup]]** — Completed inventory and organization (October 2025)

## Key Principles

### DIMOS Development
> **CRITICAL:** Never edit DIMOS files in the ShadowHound submodule directory (`src/dimos-unitree/`).
> All DIMOS development must happen in a separate clone. See [[development/dimos_development_policy|DIMOS Development Policy]].

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
   - [[../software/ros2_setup|ROS 2 Setup]]
   - [[../integrations/quickstart_dimos|DIMOS Quick Start]]

### Contributing Documentation
1. Create feature branch: `git checkout -b docs/<description>`
2. Follow [[development/per_directory_review_plan|review plan guidelines]]
3. Use [[development/pr_checklist_docs_cleanup|PR checklist]] before submitting
4. Validate wikilinks: `python tools/validate_wikilinks.py --docs docs`

### Working with DIMOS
1. Clone DIMOS separately: `git clone git@github.com:danmartinez78/dimos-unitree.git`
2. Make changes in separate DIMOS clone
3. Push changes and create PR in dimos-unitree repo
4. Update submodule pointer in ShadowHound after merge
5. See [[development/dimos_development_policy|full policy]] for details

## Validation
- [ ] All active policies reviewed and up-to-date
- [ ] Documentation standards consistently applied
- [ ] Git workflows documented and validated
- [ ] Legacy content archived appropriately

## See Also
- [[architecture/architecture_hub|Architecture Documentation]] — System design and components
- [[software/software_hub|Software Documentation]] — ROS 2 packages and configuration
- [[project_overview/project_overview_hub|Project Overview]] — Planning, status, and quick-start guides
- [[development/development_hub|Documentation Root]] — Complete documentation map

## References
- [[development/development_hub|Documentation Root]]
- Git Submodules Documentation: https://git-scm.com/book/en/v2/Git-Tools-Submodules
- Obsidian Documentation: https://help.obsidian.md/
- GitHub Wiki Best Practices
