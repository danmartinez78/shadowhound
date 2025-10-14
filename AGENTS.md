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

## **CRITICAL: Development Logging** 📝

### YOU MUST UPDATE THE DEVLOG

**Before starting any work**:
1. Read `docs/development/recent_work.md` (last 5 days summary - START HERE)
2. Check `docs/development/devlog.md` (detailed recent activity log)
3. Verify you understand the current system state

**After completing ANY significant work** (MANDATORY):
1. **Preferred**: Run `./scripts/add-devlog-entry.sh` (interactive helper)
2. **Alternative**: Manually add entry to `docs/development/devlog.md` using template
3. Include: Type, Status, Impact, Activities, Commits, Files, Decisions
4. Commit with: `docs(devlog): [your activity title]`

**What requires a devlog entry**:
- ✅ Feature complete (any new functionality, no matter how small)
- ✅ PR merged (document what was merged and impact)
- ✅ Major bug fix (anything requiring investigation)
- ✅ Architectural decision (design choices affecting future work)
- ✅ Integration work (connecting systems or components)
- ✅ End of work session (daily summary if multiple activities)
- ✅ Failed attempts with learnings (document what didn't work and why)

**Devlog entry template**:
```markdown
## YYYY-MM-DD (Day Name)

### [Time Range]: [Activity Title]
**Type**: Feature | Fix | Integration | Documentation | Testing | Infrastructure  
**PR/Issue**: #123 (if applicable)  
**Status**: ✅ Complete | 🔄 In Progress | ⚠️ Blocked  
**Impact**: One-line description of what changed and why it matters

**Activities**:
- Bullet list of what was done
- Key implementation details

**Commits**: 
- `abc123` - Commit message

**Files Created/Updated**:
- `path/to/file.py` (brief description)

**Decisions**:
- Key technical or architectural decisions with rationale

**Discoveries**:
- Unexpected findings, constraints, or learnings

**Notes**: Additional context, gotchas, future work
```

### Quick Reference Files for Context

**docs/development/recent_work.md** (READ THIS FIRST):
- Last 5 days at a glance
- Current system state
- Active blockers
- Quick stats

**docs/development/devlog.md** (DETAILED LOG):
- All development activity since project start
- Chronological, most recent first
- Full details with commits, files, decisions

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
- Do **not** push directly to the GitHub Wiki; CI handles synchronization through `tools/wiki_sync.py`.
- To view documentation in Obsidian with graph view, run `./scripts/generate_obsidian_vault.sh` to generate a local vault.

## Documentation Link Validation
- All internal links in `/docs` use standard Markdown format: `[text](path/to/file.md)`
- Links are validated by MkDocs during the CI build process
- Broken links will cause the build to fail when using `mkdocs build --strict`
- Test locally: `mkdocs build --strict` to catch broken links before pushing

## Git Hygiene
- The `docs/.obsidian/` directory is committed and contains Obsidian configuration for the generated vault.
- The generated vault `docs_obs/` is gitignored. Regenerate it locally with `./scripts/generate_obsidian_vault.sh` after pulling changes.
- Use the commit message prefix `docs(<area>): ...` for documentation-related changes.
- Do not commit build artifacts from MkDocs (`site/`) or wiki sync outputs (`wiki/`).

## Review Expectations
- Validate procedures before marking checkboxes in the **Validation** section.
- Ensure new or updated docs appear in the MkDocs navigation (`mkdocs.yml`) when appropriate.
- Mention cross-links in pull request descriptions so reviewers can verify navigation integrity.
