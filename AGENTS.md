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
- To generate Python API reference documentation with docstrings, run `python tools/ros2_autodoc.py --api`.
  - This extracts classes, functions, methods with type hints and docstrings
  - Supports Google-style and NumPy-style docstrings
  - Generates `{package_name}_api.md` files with full API documentation
  - Requires `docstring_parser` library: `pip install docstring_parser`
- Do **not** push directly to the GitHub Wiki; CI handles synchronization through `tools/wiki_sync.py`.
- Use `tools/link_convert.py` for any manual exports to ensure wikilinks and embeds become GitHub-compatible links.
- **Before committing documentation changes**, run `python tools/validate_wikilinks.py --docs docs` to check for broken internal links. The CI pipeline will automatically validate wikilinks on all pull requests that modify `docs/**`.

## Documentation Link Validation
- All wikilinks in `/docs` are automatically validated by CI to prevent broken internal navigation.
- The validator supports all wikilink formats:
  - Same-directory: `[[file]]` → references file in same directory
  - Absolute from docs root: `[[path/to/file]]` → references file relative to docs/
  - Relative paths: `[[../file]]` or `[[../../file]]` → explicit relative navigation
  - With labels: `[[target|Display Text]]`
  - With anchors: `[[target#section]]` or `[[target#section|Label]]`
- Fix broken links before pushing to ensure CI passes. Run locally: `python tools/validate_wikilinks.py --docs docs`

## Git Hygiene
- Keep the Obsidian workspace clean. The `.obsidian/` directory is ignored except for optional `themes/` and `snippets/` subfolders, which may be committed if intentionally curated.
- Use the commit message prefix `docs(<area>): ...` for documentation-related changes.
- Do not commit build artifacts from MkDocs (`site/`) or wiki sync outputs (`wiki/`).

## Review Expectations
- Validate procedures before marking checkboxes in the **Validation** section.
- Ensure new or updated docs appear in the MkDocs navigation (`mkdocs.yml`) when appropriate.
- Mention cross-links in pull request descriptions so reviewers can verify navigation integrity.
