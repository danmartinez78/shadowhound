---
tags: [development/cleanup, docs]
status: complete
related: [development/doc_root_cleanup, development/per_directory_review_plan]
summary: >
  COMPLETE: Inventory of documentation files in repository root with proposed destinations (work executed October 2025).
---

# Project Root Docs Cleanup Draft

## Purpose
Inventory documentation and text files at the repository root and propose moving them into the `docs/` tree (or archiving) to centralize knowledge and reduce duplication.

## Prerequisites
- Align with repository documentation conventions (front-matter, section order, wikilinks).
- Confirm which files are intentionally kept at root (e.g., README.md, mkdocs.yml).

## Steps
1. Inventory root-level docs.
2. Propose destinations and note any link changes required.
3. Execute moves in a PR, update links, and validate.

## Inventory (as of creation)
- `AGENTS.md` → Keep at root (authoritative rules). Add a mirrored index page under `docs/development/` linking back here.
- `ARCHITECTURE_REVIEW_SUMMARY.md` → Move to `docs/architecture/`.
- `CONVERSION_COMPLETE.md` → Move to `docs/history/` with a short context note.
- `LAPTOP_SYNC_COMMANDS.sh` → Keep as script; add entry in `docs/software/scripts.md`.
- `MERGE_CHECKLIST.md` → Move to `docs/development/` and cross-link from contributor docs.
- `PROJECT_SETUP_STATUS.md` → Move to `docs/project_overview/`.
- `QUICKSTART_DIMOS.md` → Move to `docs/integrations/` or `docs/software/agent/` depending on content; ensure canonical DIMOS pages exist.
- `README.md` → Keep at root (project landing). Ensure it links to key docs pages.
- `TODO.md` → Move to `docs/development/` or convert into GitHub issues/roadmap entries.
- `.env*` files → Keep in root for developer convenience. Leave these files untouched for now per current policy. Documentation should reference the standard single `.env` pattern going forward, but do not modify or remove existing `.env*` files in this pass.
- `.shadowhound_env` → Deprecated; retain file only for backward compatibility. Ensure all docs avoid referencing it.

## Validation
- Re-run wikilink validation after moves and update all cross-references.
- Confirm `mkdocs.yml` updates if new top-level docs are added to navigation.

## References
- `docs/development/per_directory_review_plan.md` for process and acceptance criteria.