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
