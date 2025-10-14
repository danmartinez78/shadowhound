---
tags: [tools, documentation, obsidian]
status: active
related: [guide.md, setup.md, persistence.md]
summary: >
  Overview of Obsidian integration for visualizing ShadowHound documentation with graph view.
---

# Obsidian Integration

## Purpose

Obsidian integration provides an optional **graph view visualization** of the ShadowHound documentation. This helps developers understand documentation structure, find related documents, and navigate the project more intuitively.

The documentation source remains standard Markdown in `docs/`. Obsidian is purely a viewing tool - no editing is done in the generated vault.

## Quick Start

```bash
# Generate the Obsidian vault from docs/
./scripts/generate_obsidian_vault.sh
```

This creates `docs_obs/` (gitignored) with:
- All documentation converted to Obsidian wikilinks
- Pre-configured graph view settings (from `.obsidian/` config)
- Color-coded directory groups for easy navigation

**To view:**
1. Open Obsidian
2. Click "Open folder as vault"
3. Select `docs_obs/` in the shadowhound directory
4. Press Ctrl/Cmd+G to open graph view

## How It Works

### 1. Source Documentation (docs/)
All documentation is authored in **standard Markdown** in the `docs/` directory:
- Uses standard markdown links: `[text](../path/to/file.md)`
- Works directly on GitHub.com, GitHub Pages, and Wiki
- Committed to the repository

### 2. Obsidian Configuration (docs/.obsidian/)
The `.obsidian/` directory (committed at the root of `docs/`) contains:
- Graph view color settings
- Physics settings for node layout
- Group filters for directory-based coloring

**Why committed?** The configuration ensures consistent graph view for all developers. When you generate the vault, these settings are automatically applied.

### 3. Generated Vault (docs_obs/)
Running `./scripts/generate_obsidian_vault.sh`:
1. Converts standard markdown links to Obsidian wikilinks
2. Copies all docs content to `docs_obs/`
3. Copies `.obsidian/` config for graph view settings
4. Result: A complete Obsidian vault (gitignored)

**When to regenerate:**
- After `git pull` to get latest documentation
- After editing documentation locally
- If the vault seems out of sync with `docs/`

## Documentation

- **[guide.md](guide.md)** - Complete guide to using the graph view
- **[setup.md](setup.md)** - Manual UI configuration (if script doesn't work)
- **[persistence.md](persistence.md)** - How graph settings persist

## Key Features

### Graph View Visualization
- **Hub structure**: Index → 16 directory hubs → documents
- **Color coding**: Each directory has a distinct color
- **Local graphs**: Focus on specific document clusters
- **Search integration**: Combine search with graph filters

### Color Groups
Each directory is automatically color-coded:
- **project_overview** - Pink (planning and status)
- **architecture** - Orange (system design)
- **development** - Blue (dev guides)
- **software** - Teal (ROS2 packages)
- **hardware** - Red (physical platform)
- _...and 11 more directories_

See [guide.md](guide.md) for complete color legend.

## Common Workflows

### Exploring a New Area
1. Open vault in Obsidian
2. Start at `index.md`
3. Click a directory hub (yellow nodes)
4. Use local graph to explore that area

### Finding Related Documents
1. Open any document
2. Right-click → "Open local graph"
3. See nearby connections (1-2 levels)
4. Follow links to related docs

### Searching Specific Topics
1. Use search bar: `path:software` or `tag:#llm`
2. Graph filters to specific area
3. Navigate results in graph view

## Troubleshooting

### Graph Too Dense?
- Enable "Hide Orphans" filter
- Increase "Repel Strength" to 12-15
- Use Local Graph instead of global view

### Colors Not Showing?
- Ensure `.obsidian/` config was copied
- Check Groups section in graph filters
- Try regenerating vault: `./scripts/generate_obsidian_vault.sh`

### Changes Not Persisting?
- Documentation edits go in `docs/`, not `docs_obs/`
- Regenerate vault after editing: `./scripts/generate_obsidian_vault.sh`
- `docs_obs/` is temporary and gitignored

## Technical Details

### Scripts
- **`scripts/generate_obsidian_vault.sh`** - Main vault generation script
- **`scripts/update_obsidian_graph.sh`** - Apply graph config while Obsidian closed
- **`tools/obsidian_convert.py`** - Python converter (markdown → wikilinks)

### Configuration Location
- **Committed**: `docs/.obsidian/` (source of truth for graph settings)
- **Generated**: `docs_obs/.obsidian/` (copied during vault generation)

### Why Not Edit in Obsidian Directly?
1. Standard Markdown works everywhere (GitHub, MkDocs, Wiki)
2. Obsidian wikilinks are Obsidian-specific
3. Keeping source in standard format ensures portability
4. Obsidian is purely a visualization layer

## References

- [Obsidian Graph View Documentation](https://help.obsidian.md/Plugins/Graph+view)
- [Documentation Root](../../index.md)
- [Generate Vault Script](../../../scripts/generate_obsidian_vault.sh)

## Validation

- [ ] Vault generates without errors
- [ ] Graph view displays with colors
- [ ] Links work between documents
- [ ] Local graph functions properly
- [ ] Configuration persists after Obsidian restart
