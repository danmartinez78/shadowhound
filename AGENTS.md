# ShadowHound Documentation & Contribution Guidelines

These rules apply to the entire repository.

## **CRITICAL: MVP Roadmap is Source of Truth** 🎯

### YOU MUST READ AND PROTECT THE MVP ROADMAP

**Before starting ANY significant work**:
1. **READ**: `docs/project_overview/mvp_embodied_ai_platform.md` (MVP roadmap - SOURCE OF TRUTH)
2. **READ**: `docs/project_overview/MVP_PROTECTION_POLICY.md` (how to protect scope)
3. Extract: MVP scope, current milestone, success criteria, constraints

**Purpose**: This roadmap defines project scope after comprehensive requirements gathering. Without it, scope becomes confused and shifts unintentionally (historical problem).

**When proposing changes to the roadmap**:
1. ❌ **DO NOT** edit automatically
2. ✅ **DO** explain proposed change clearly
3. ✅ **DO** explain WHY it's needed  
4. ✅ **DO** show impact on scope/milestones
5. ✅ **WAIT** for explicit user approval

**When detecting scope creep**:
```
⚠️  SCOPE ALERT: This request would add [X] to MVP scope.
Current MVP: [list 5 core capabilities]
Proposed addition: [describe]
Impact: [timeline/complexity/risk]
Recommendation: Add to Future Work instead?
```

**Exception**: Typo fixes and factual corrections (e.g., sensor specs) can be made but should be noted in commit.

---

## **CRITICAL: Development Documentation** 📝

### YOU MUST UPDATE DOCUMENTATION AFTER WORK

**Before starting work**:
1. Read `docs/development/recent_work.md` (last 5 days context - START HERE)
2. Check `docs/development/devlog.md` (recent timeline)
3. Check `docs/development/experiments/` (active experimental work)
4. Verify you understand current system state

**After completing work** (REQUIRED):

### For Simple/Straightforward Work (use devlog)
Simple features, bug fixes, documentation updates, refactoring:

1. Add **lightweight entry** to `docs/development/devlog.md`
2. Include: date, time, type, status, key results, commits
3. Link to experiment doc if building on experimental work
4. Commit: `docs(devlog): [activity title]`

**Devlog Entry Format** (SIMPLIFIED):
```markdown
### Evening: Local LLM Integration Complete
**Type**: Feature
**Status**: ✅ Complete
**Experiment Doc**: [experiments/local_llm_exploration_oct10_2025.md](experiments/local_llm_exploration_oct10_2025.md)

Tested 4 LLM models, selected Mistral 7B for 24x speed improvement.

**Key Results**:
- vLLM on Thor: 37 tok/s baseline
- Tool calling validated
- Local embeddings working

**Commits**: `3ac1e01`, `45618b2`
```

### For Experimental/Research Work (use experiment docs)
Large feature branches, testing multiple approaches, extensive investigation:

1. Create experiment doc: `docs/development/experiments/{feature}_{topic}_{date}.md`
2. Use template: `docs/development/experiments/template_experiment.md`
3. Document: Context, Hypothesis, all Experiments tried, Final Results
4. Add lightweight devlog entry with link to experiment doc
5. Commit experiment doc: `docs(experiments): [experiment title]`

**When to create experiment doc**:
- ✅ Testing multiple approaches (e.g., 4 LLM models)
- ✅ Feature branch spans multiple days with iteration
- ✅ Extensive debugging or investigation
- ✅ Need to document "what we tried" not just "what worked"
- ✅ Research-driven development with exploration

**See**: `docs/development/experiments/README.md` for complete guide

**Example experiment docs**:
- `local_llm_exploration_oct10_2025.md` - LLM model selection
- `dimos_integration_oct05_2025.md` - Feature branch work

### Why This Pattern?

**Benefits**:
- ✅ No merge conflicts (experiment docs are unique per branch)
- ✅ Preserves experimental learning (what worked, what didn't, why)
- ✅ Lightweight devlog timeline (easy to scan)
- ✅ Detailed experiment docs (full narrative when needed)
- ✅ Works with parallel development and large feature branches

**Failure to document = incomplete work**

### Quick Reference Files for Context

**docs/development/recent_work.md** (READ THIS FIRST):
- Last 5 days at a glance
- Current system state
- Active blockers
- Quick stats

**docs/development/devlog.md** (LIGHTWEIGHT TIMELINE):
- Daily development timeline
- Chronological, most recent first
- Links to detailed experiment docs

**docs/development/experiments/** (DETAILED EXPERIMENTS):
- Full experimental narratives
- Research-driven development
- What worked, what didn't, why

**docs/history/project_history_oct_2025.md** (HISTORICAL):
- Comprehensive 10-day history (Oct 3-13)
- 389 commits analyzed
- Major milestones and achievements

---

## Authoring Markdown
- All new documentation **must** live under `/docs` and include the YAML front-matter block:
  ```
  ---
  tags: [topic, component]
  status: draft
  related: []
  summary: >
    One-line summary.
  ---
  ```
- Use **standard Markdown links**: `[text](path/to/file.md)` for all internal documentation links. These work directly on GitHub.com, GitHub Pages, and in the Wiki.
- For **Obsidian graph view**: Run `./scripts/generate_obsidian_vault.sh` to create a local vault at `docs_obs/` (gitignored). Open `docs_obs/` in Obsidian to view the documentation graph with wikilinks.
- Structure every page with the following sections in this order: **Purpose**, **Prerequisites**, **Steps**, **Validation**, **References**.
- Store all media, diagrams, and exported canvases under `docs/_assets/` and reference them with relative paths (for example `![](_assets/diagram.png)`).
- Canvas files (`*.canvas`) should be committed alongside a PNG snapshot exported to `_assets/` for public readers.
- Avoid absolute URLs to repository files; use relative links to Markdown pages.

## Automation & Tooling
- After adding or modifying ROS 2 packages, run `python tools/ros2_autodoc.py` to regenerate autodoc stubs under `docs/software/autodoc/`.
- To generate Python API reference documentation with docstrings, run `python tools/ros2_autodoc.py --api`.
  - This extracts classes, functions, methods with type hints and docstrings
  - Supports Google-style and NumPy-style docstrings
  - Generates `{package_name}_api.md` files with full API documentation
  - Requires `docstring_parser` library: `pip install docstring_parser`
- Do **not** push directly to the GitHub Wiki; CI handles synchronization through `tools/wiki_sync.py` on pushes to `dev` and `main` branches when `docs/**` changes.
- To view documentation in Obsidian with graph view, run `./scripts/generate_obsidian_vault.sh` to generate a local vault.

## Documentation Link Validation
- All internal links in `/docs` use standard Markdown format: `[text](path/to/file.md)`
- Links are validated by MkDocs during the CI build process
- Broken links will cause the build to fail when using `mkdocs build --strict`
- Test locally: `mkdocs build --strict` to catch broken links before pushing

## Git Hygiene
- The `docs/tools/obsidian/.obsidian/` directory is committed and contains Obsidian configuration template for the generated vault.
- The generated vault `docs_obs/` is gitignored. Regenerate it locally with `./scripts/generate_obsidian_vault.sh` after pulling changes.
- Use the commit message prefix `docs(<area>): ...` for documentation-related changes.
- Do not commit build artifacts from MkDocs (`site/`) or wiki sync outputs (`wiki/`).

## Review Expectations
- Validate procedures before marking checkboxes in the **Validation** section.
- Ensure new or updated docs appear in the MkDocs navigation (`mkdocs.yml`) when appropriate.
- Mention cross-links in pull request descriptions so reviewers can verify navigation integrity.
