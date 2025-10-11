# ShadowHound Documentation & Contribution Guidelines

These rules apply to the entire repository.

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
- Prefer Obsidian-style wikilinks (`[[like/this]]`) during authoring. The CI pipeline converts them to standard Markdown for GitHub Pages and the Wiki.
- Structure every page with the following sections in this order: **Purpose**, **Prerequisites**, **Steps**, **Validation**, **References**.
- Store all media, diagrams, and exported canvases under `docs/_assets/` and reference them with relative paths (for example `![](_assets/diagram.png)`).
- Canvas files (`*.canvas`) should be committed alongside a PNG snapshot exported to `_assets/` for public readers.
- Avoid absolute URLs to repository files; use relative links to Markdown pages.

## Automation & Tooling
- After adding or modifying ROS 2 packages, run `python tools/ros2_autodoc.py` to regenerate autodoc stubs under `docs/software/autodoc/`.
- Do **not** push directly to the GitHub Wiki; CI handles synchronization through `tools/wiki_sync.py`.
- Use `tools/link_convert.py` for any manual exports to ensure wikilinks and embeds become GitHub-compatible links.

## Git Hygiene
- Keep the Obsidian workspace clean. The `.obsidian/` directory is ignored except for optional `themes/` and `snippets/` subfolders, which may be committed if intentionally curated.
- Use the commit message prefix `docs(<area>): ...` for documentation-related changes.
- Do not commit build artifacts from MkDocs (`site/`) or wiki sync outputs (`wiki/`).

## Review Expectations
- Validate procedures before marking checkboxes in the **Validation** section.
- Ensure new or updated docs appear in the MkDocs navigation (`mkdocs.yml`) when appropriate.
- Mention cross-links in pull request descriptions so reviewers can verify navigation integrity.
