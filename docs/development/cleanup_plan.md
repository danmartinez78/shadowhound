---
tags: [development/process, docs, planning]
status: active
related: [development/per_directory_review_plan, development/doc_root_cleanup, development/pr_checklist_docs_cleanup]
summary: >
  Master plan for documentation cleanup and GitHub Wiki creation - organize structure, improve discoverability.
---

# Documentation Cleanup & Wiki Plan

**Date**: October 12, 2025  
**Branch**: `docs/wiki-and-cleanup`  
**Goal**: Organize documentation, create GitHub Wiki, improve discoverability

---

## Current State Assessment

### Existing Structure ✅
```
docs/
├── _assets/              # Images, diagrams
├── _templates/           # Page templates
├── hardware/            # Hardware setup docs
├── networking/          # Network configuration
├── research/            # Development notes
├── simulation/          # Simulation setup
├── software/            # ROS2, DIMOS, scripts
│   └── autodoc/        # Auto-generated API docs
├── troubleshooting/     # Debugging guides
├── project_overview/    # Quick refs, TODO, roadmap
└── issues/             # Specific bug/issue docs
```

### Problems to Fix 🔴

1. **Root-level clutter**: ~50+ markdown files in `docs/` root
2. **Naming inconsistency**: Mix of CAPS.md, snake_case.md, kebab-case.md
3. **Duplicate content**: Multiple versions of similar docs
4. **Stale docs**: Old merge summaries, temporary notes
5. **No index**: Hard to find docs without browsing
6. **Wiki not populated**: GitHub Wiki exists but empty

---

## Cleanup Strategy

### Phase 1: Root-Level Organization 📁

**Move files to appropriate subdirectories**:

```bash
# Agent/Planning docs → software/agent/
agent_refactor_analysis.md
agent_tasks.md
dimos_agent_architecture.md

# Architecture docs → architecture/
architecture_clarification.md
arch_update_summary.md
camera_architecture.md
deployment_topology.md

# Configuration docs → software/configuration/
environment_variables.md
embeddings_auto_detection.md
BACKEND_QUICK_REFERENCE.md

# LLM/Backend docs → software/llm/
BACKEND_VALIDATION_SUMMARY.md
FEATURE_COMPLETE_OLLAMA.md
OLLAMA_*.md
local_llm_*.md
vllm_*.md
llama_cpp_*.md

# Merge/EOD summaries → history/
EOD_SUMMARY_*.md
merge_*.md
MERGE_*.md
doc_validation_summary.md

# Integration docs → integrations/
chatgpt_integration.md
dimos_integration.md
rag_integration.md
vlm_integration_summary.md
vision_integration_design.md

# UI/Web docs → software/web/
ui_*.md
web_*.md
webrtc_*.md

# Deployment docs → deployment/
deployment_sync.md
codex_*.md
laptop_*.md
thor_*.md
startup_validation.md

# Development process → development/
development_tracking.md
dimos_development_policy.md
cache_clearing_guide.md
indentation_fix.md
```

### Phase 2: Naming Standardization 📝

**Convention**: `lowercase_with_underscores.md`

- CAPS.md → lowercase.md
- kebab-case.md → snake_case.md
- Keep consistency across entire docs/

### Phase 3: Content Audit & Archive 🗑️

**Archive (move to `docs/archive/`)**:
- Old merge summaries older than 1 month
- Temporary debugging notes (once resolved)
- Duplicate/superseded documentation
- EOD summaries (keep only recent)

**Delete**:
- Empty placeholder files
- Build artifacts in docs_web/ (should be gitignored)
- Obsolete configuration examples

**Update**:
- Fix broken wikilinks
- Update outdated information
- Add YAML front-matter to all docs

### Phase 4: Create Master Index 📚

**docs/README.md** (the main hub):
```markdown
# ShadowHound Documentation

## 🚀 Quick Start
- [Quick Start Guide](project_overview/quick_start.md)
- [Quick Reference](project_overview/quick_reference.md)
- [Setup Status](project_overview/setup_status.md)

## 📖 Core Documentation
- [Project Overview](project.md)
- [Architecture](architecture/overview.md)
- [Hardware Setup](hardware/README.md)
- [Software Setup](software/README.md)

## 🛠️ Development
- [Development Guide](development/guide.md)
- [DIMOS Integration](software/dimos_quick_start.md)
- [ROS2 Setup](software/ros2_setup.md)

## 🔧 Configuration
- [Environment Variables](software/configuration/environment_variables.md)
- [LLM Backends](software/llm/backend_guide.md)
- [Network Setup](networking/README.md)

## 🐛 Troubleshooting
- [Troubleshooting Guide](troubleshooting/README.md)
- [Known Issues](troubleshooting/known_issues.md)

## 📊 Project Management
- [TODO](project_overview/todo.md)
- [Roadmap](project_overview/roadmap.md)
```

### Phase 5: GitHub Wiki Setup 📖

**Wiki Structure** (mirrors docs/):
```
Home
├── Quick Start
├── Architecture
│   ├── System Overview
│   ├── Agent System
│   └── Skills Framework
├── Setup
│   ├── Hardware
│   ├── Software
│   └── Configuration
├── Development
│   ├── Contributing
│   ├── DIMOS Development
│   └── Testing
├── Troubleshooting
└── API Reference
```

**Wiki Sync Process**:
1. Use `tools/wiki_sync.py` to push docs
2. Convert wikilinks to GitHub Wiki format
3. Add navigation sidebar
4. Set up automatic sync via GitHub Actions

---

## Implementation Steps

### Step 1: Create New Directory Structure
```bash
mkdir -p docs/{architecture,development,integrations,deployment,history,archive}
mkdir -p docs/software/{agent,configuration,llm,web}
```

### Step 2: Move Files (with git mv for history)
```bash
# Example moves
git mv docs/agent_refactor_analysis.md docs/software/agent/
git mv docs/BACKEND_QUICK_REFERENCE.md docs/software/llm/
git mv docs/EOD_SUMMARY_*.md docs/history/
```

### Step 3: Update Internal Links
```bash
# Use find/replace or link_convert.py
python tools/link_convert.py --update-paths
```

### Step 4: Add Front-Matter
```bash
# Add to all .md files:
---
tags: [category, topic]
status: active|archived|outdated
related: []
summary: >
  Brief description
---
```

### Step 5: Validate Links
```bash
python tools/validate_wikilinks.py --docs docs
```

### Step 6: Create Indexes
- Write docs/README.md
- Update each subdirectory README.md
- Create navigation guides

### Step 7: Sync to Wiki
```bash
python tools/wiki_sync.py --push
```

---

## File Categorization

### Keep in Root (8 files max)
- README.md (master index)
- project.md (project overview)
- index.md (for MkDocs)
- CONTRIBUTING.md
- CHANGELOG.md
- ARCHITECTURE.md (high-level)
- FAQ.md
- GLOSSARY.md

### Move to Subdirectories (everything else)

**architecture/**:
- architecture_clarification.md
- arch_update_summary.md
- camera_architecture.md
- deployment_topology.md
- system_overview.md (new consolidation)

**software/agent/**:
- agent_refactor_analysis.md
- agent_tasks.md
- dimos_agent_architecture.md

**software/llm/**:
- BACKEND_QUICK_REFERENCE.md
- BACKEND_VALIDATION_SUMMARY.md
- FEATURE_COMPLETE_OLLAMA.md
- local_llm_integration_summary.md
- ollama_*.md
- vllm_*.md
- llama_cpp_*.md
- embeddings_auto_detection.md

**software/configuration/**:
- environment_variables.md
- startup_validation.md

**software/web/**:
- ui_*.md
- web_*.md
- webrtc_*.md (except hardware-specific ones → networking/)

**integrations/**:
- chatgpt_integration.md
- dimos_integration.md
- rag_integration.md
- vision_integration_design.md
- vlm_integration_summary.md

**deployment/**:
- deployment_sync.md
- codex_*.md
- laptop_*.md
- thor_*.md

**development/**:
- development_tracking.md
- dimos_development_policy.md
- dimos_branch_consolidation.md
- cache_clearing_guide.md
- testing_guide_ollama.md
- quality_scorer documentation

**history/** (archived summaries):
- EOD_SUMMARY_*.md
- merge_*.md
- MERGE_*.md
- doc_validation_summary.md

**issues/** (specific bug/issue tracking):
- Already organized ✅

---

## Success Criteria ✅

- [ ] All docs in appropriate subdirectories
- [ ] No more than 8 .md files in docs/ root
- [ ] Consistent naming convention (snake_case)
- [ ] All wikilinks validated and working
- [ ] Every subdirectory has README.md index
- [ ] Master docs/README.md created
- [ ] GitHub Wiki populated and synced
- [ ] MkDocs builds successfully
- [ ] No broken links in CI validation
- [ ] Front-matter added to all docs

---

## Timeline

- **Day 1**: Create structure, move files (2-3 hours)
- **Day 2**: Update links, add front-matter (2-3 hours)
- **Day 3**: Create indexes, validate (1-2 hours)
- **Day 4**: Wiki setup and sync (1-2 hours)

**Total effort**: 6-10 hours over 4 days

---

## Tools & Automation

- `tools/wiki_sync.py` - Sync docs to GitHub Wiki
- `tools/link_convert.py` - Convert wikilinks to various formats
- `tools/validate_wikilinks.py` - Check for broken links
- `.github/workflows/validate-docs.yml` - CI validation
- `.github/workflows/docs.yml` - Auto-deploy MkDocs

---

## Notes

- Keep `docs_web/` in .gitignore (build artifact)
- Keep `site/` in .gitignore (MkDocs build)
- Archive instead of delete (preserve history)
- Document the new structure in README
- Update AGENTS.md with new doc paths

---

**Next Action**: Start with Phase 1 - create directories and begin moving files systematically.
