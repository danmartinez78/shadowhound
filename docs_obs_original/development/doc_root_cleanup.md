---
tags: [development/cleanup, docs]
status: complete
related: []
summary: >
  COMPLETE: Inventory of unstructured files at docs/ root with proposed destinations (work executed October 2025).
---

# Docs Root Cleanup Draft

## Purpose
Collect and triage top-level files in `docs/` that don’t belong to a specific topic folder, then propose moves, merges, or archival to reduce clutter and improve discoverability.

## Prerequisites
- Review the Per-directory Documentation Review Plan for standards and acceptance criteria.
- Confirm MkDocs nav rules before moving popular entry points like `index.md`.

## Steps
1. Inventory the current top-level files.
2. For each item, propose a destination (or archival) and any needed link updates.
3. Apply changes in a single PR and re-run wikilink validation.

## Inventory (as of creation)
- `AGENT_QUICK_REFERENCE.txt` → Move to `docs/project_overview/` or convert to Markdown and integrate into an index page.
- `CLEANUP_PLAN.md` → Move to `docs/development/` and merge with this plan if overlapping.
- `COLCON_IGNORE` → Keep as-is; build system control file (document its purpose in `docs/development/build_conventions.md` if needed).
- `Jetson-Thor-Setup-and-Demo-Guide.pdf` → Move to `docs/hardware/` and add a short README that links to it; consider converting to Markdown later.
- `QUICK_START_ROBOT_TEST.md` → Move to `docs/simulation/` or `docs/troubleshooting/` depending on scope; ensure consistency with canonical quick start.
- `README.md` → Keep; acts as docs root landing page. Ensure it has proper front-matter and mirrors site `index.md` as needed.
- `WEB_UI_MOCKUP.txt` → Move to `docs/software/` under a `web/` subfolder, or integrate into a design notes page.
- `index.md` → Keep; site entry point.
- `project.md` → Move to `docs/project_overview/` or merge into roadmap/index; avoid duplication.
- `submodule_policy.md` → Move to `docs/development/` (policy) and cross-link from contributor docs.
- `vllm_env_example.txt` → Move to `docs/software/configuration/` and convert to Markdown with standard `.env` policy notes.
- `webrtc_direct_test.md` → Ensure this is a redirect/alias pointing to `docs/networking/webrtc_direct_test.md`; eventually remove duplicate content.

## Validation
- After moves, run: `python tools/validate_wikilinks.py --docs docs` and fix any reported links.
- Search for old paths referenced elsewhere and update.

## References
- See `docs/development/per_directory_review_plan.md` for the canonical process.