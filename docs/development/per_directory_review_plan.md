---
tags: [development, docs]
status: draft
related: []
summary: >
  Standardize and clean documentation folder-by-folder with clear owners, checklists, and acceptance criteria.
---

# Per-directory Documentation Review Plan

## Purpose
Establish a consistent, repeatable process to review each directory under `docs/`, standardize structure and links, and eliminate duplication and drift. This plan defines what “good” looks like and provides a lightweight checklist you can copy for each directory.

## Prerequisites
- Agree on the repository-wide documentation rules (front-matter, section order, Obsidian wikilinks, media under `docs/_assets/`). See AGENTS.md in the repo root for the authoritative guidelines.
- Use only standard environment files (single `.env` approach). Avoid bespoke per-test files.
- Confirm site navigation rules in `mkdocs.yml` before large moves to prevent orphaned pages.

## Scope & Priorities
1. Networking (done): Canonical pages, diagram, and nav checked.
2. Hardware: Align wiring/topologies as canonical source; cross-link from related pages.
3. Development: Contributor guides, coding standards, scripts catalog, environment configuration.
4. Software: Package-specific guides, configuration, and API/autodoc anchors.
5. Troubleshooting/Issues: Normalize structure and link back to canonical guides.
6. Project overview/History/Research: De-duplicate, clarify status, add redirects if needed.

## Directory Review Checklist (Template)
Copy this template into a tracking note or PR description for each directory you review.

- Front-matter
  - [ ] Every Markdown file has required front-matter: tags, status, related, summary
  - [ ] Add `aliases` only when it reduces Obsidian ambiguity (e.g., multiple README.md files)
- Page structure
  - [ ] Each page uses sections: Purpose, Prerequisites, Steps, Validation, References
  - [ ] Consolidate fragmented content; remove redundant pages
  - [ ] Redirect or link from legacy locations to canonical page(s)
- Links & media
  - [ ] All internal links use Obsidian wikilinks or relative Markdown links consistently
  - [ ] Media stored under `docs/_assets/` with descriptive alt text
  - [ ] Run link validator: `python tools/validate_wikilinks.py --docs docs`
- Canonical sources
  - [ ] Identify canonical page(s) for the topic; other mentions should reference these
  - [ ] Avoid duplicating procedures across directories—prefer a single source of truth
- Environment policy
  - [ ] No bespoke `.env.webrtc_test` or `.shadowhound_env` references
  - [ ] Point to the standard Environment Configuration guidance
- Navigation
  - [ ] Ensure `mkdocs.yml` includes the directory’s key entry points
  - [ ] Avoid adding every minor page to nav; link from index pages instead

## Steps
1. Inventory the directory: list all pages and media; flag outdated or overlapping content.
2. Identify canonical pages and decide merges/deprecations.
3. Apply front-matter, section structure, and aliases (if useful in Obsidian).
4. Normalize links and embeds; move media to `_assets/` if needed.
5. Update `mkdocs.yml` navigation for the main index and principal guides.
6. Run the wikilink validator and fix any issues.
7. Open a focused PR per directory (or themed batch) with a concise summary of changes.

## Validation
- Wikilinks: `python tools/validate_wikilinks.py --docs docs` should report 0 broken links.
- Site nav: `mkdocs.yml` entries render the expected menu and land on canonical pages.
- Grep checks: no references to bespoke environment files remain.

## References
- Repository-wide docs & authoring rules: AGENTS.md (repo root)
- MkDocs configuration: `mkdocs.yml`
- Autodoc tool (for packages): `tools/ros2_autodoc.py`---
tags: [development, docs]
status: draft
related: [project_overview/status_2025-10-12]
summary: >
  Checklist and order of operations to review each docs directory for consistency and navigation.
---

# Per-Directory Review Plan

## Purpose
Define the order and checks to validate documentation consistency after the reorg.

## Order
1. `networking/`
2. `troubleshooting/`
3. `development/`
4. `software/llm/`
5. `project_overview/`
6. `performance/`
7. `policies/`
8. `issues/`

## Checks
- Index/README present with short purpose and links
- No obvious duplicates; redirects used when needed
- Wikilinks resolve within vault
- References to scripts match paths under `scripts/`
- Outbound references to DIMOS/go2 SDK are accurate

## Validation
- [ ] Networking index links to both DDS and WebRTC tests
- [ ] Troubleshooting links back to Networking where appropriate
- [ ] Development contains handoff/status guides
- [ ] LLM docs unchanged functionally after move
- [ ] Project overview reflects current branch and status

## Obsidian Graph View Optimization

To create a highly navigable graph view in Obsidian, apply these patterns during each directory review:

### Hierarchical Tags
- Use `/` in tags to create clusters: `software/llm`, `hardware/sensors`, `troubleshooting/network`
- Example: `tags: [software/llm, setup, guide]` instead of `tags: [software, llm, setup]`

### Bidirectional Linking
- If page A links to B, ensure B links back to A when semantically related
- Create hub-and-spoke: every page links to its directory README/index
- Add horizontal links between peer pages (not just vertical to index)

### "Related" Front-Matter
- Populate `related: []` with 2-5 semantically connected docs
- Example: `related: [software/llm/vllm_quickstart, software/llm/ollama_setup]`
- These show as connections in the graph even without explicit wikilinks

### Cross-References in Content
- Add "See also" sections near the bottom of each page
- Link to related guides in the content body, not just References
- Example:
  ```markdown
  ## See Also
  - [[software/llm/backend_quick_reference|Backend Comparison]]
  - [[software/llm/vllm_quickstart|vLLM Alternative]]
  ```

### Avoid Orphans
- Every page must have at least one incoming link (ideally from its directory index)
- Every page must have at least one outgoing link (back to index or to related content)
- Use grep to find orphans: `grep -L '\[\[' docs/**/*.md`

### Hub Pages
- Directory README/index pages should link to all major pages in that directory
- Use descriptive link text, not just filenames
- Group related links into sections

