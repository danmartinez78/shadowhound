---
tags: [documentation, obsidian, meta]
status: active
related: []
summary: >
  Guide to navigating the ShadowHound Obsidian vault and optimizing the graph view.
---

# Obsidian Graph View Guide

## Purpose
Explain the graph view configuration and how to navigate the ShadowHound documentation vault effectively.

## Graph View Settings

The graph view has been optimized for better visualization with these settings:

### Display Settings
- **Hide Orphans**: ✅ Enabled - only shows connected documents
- **Hide Unresolved**: ✅ Enabled - hides broken links
- **Show Arrows**: ✅ Enabled - shows link direction
- **Text Fade**: -0.5 - labels always visible
- **Node Size**: 1.2x - larger nodes for readability

### Physics Settings
- **Center Strength**: 0.4 - moderate pull to center
- **Repel Strength**: 12 - good spacing between nodes
- **Link Strength**: 0.6 - flexible connections
- **Link Distance**: 300 - spread out layout

### Color Groups

Each directory has a distinct color for easy identification:

| Directory | Color | Purpose |
|-----------|-------|---------|
| **index** | White | Root entry point |
| **Hub files** (_hub) | Yellow | Directory hubs |
| **project_overview** | Pink | Planning and status |
| **architecture** | Orange | System design |
| **development** | Blue | Dev guides |
| **deployment** | Dark Green | Ops guides |
| **software** | Teal | ROS2 packages |
| **hardware** | Red | Physical platform |
| **networking** | Cyan | Network config |
| **troubleshooting** | Orange | Diagnostics |
| **simulation** | Light Blue | Testing |
| **research** | Magenta | Experiments |
| **performance** | Light Orange | Benchmarks |
| **integrations** | Purple | External systems |
| **issues** | Coral | Known issues |
| **history** | Gray | Archived docs |

## Navigation Tips

### 1. Use Local Graph View
Instead of the global graph (Ctrl+G), use **Local Graph** on any note:
- Right-click a note → "Open local graph"
- Shows only nearby connections (1-2 levels)
- Much cleaner for focused exploration

### 2. Hub-Based Navigation
Start at `index.md` and:
1. Click a hub (yellow nodes with `_hub` suffix)
2. View that directory's documents
3. Use "See Also" sections for related areas

### 3. Search + Graph Filters
Combine search with graph filters:
- Search bar: `path:software` - show only software directory
- Search bar: `tag:#llm` - show LLM-related docs
- Use filters panel on right side

### 4. Zoom and Pan
- **Scroll wheel**: Zoom in/out
- **Click + drag**: Pan around
- **Double-click node**: Open that document
- **Hover over node**: See document name

## Graph Structure

The vault follows a **hierarchical hub-and-spoke** structure:

```
index (white center)
  ↓
16 Directory Hubs (yellow)
  ↓
Individual Documents (colored by directory)
```

### Key Characteristics
- **Index links to 16 hubs only** - clean star topology
- **Hubs link to their documents** - clear hierarchy
- **Documents cross-link sparingly** - minimal mesh
- **Hubs have "See Also"** - controlled cross-directory links

## Troubleshooting

### Graph Too Dense
1. Enable "Hide Orphans" filter
2. Increase "Repel Strength" (10-15 range)
3. Increase "Link Distance" (300-400 range)
4. Use Local Graph instead of global

### Can't Find a Document
1. Use search: Ctrl+O (Quick Switcher)
2. Search by filename, not full path
3. Hub files end with `_hub` suffix
4. Check directory list in index.md

### Colors Not Showing
1. Open graph view
2. Click filters icon (right panel)
3. Expand "Groups" section
4. Ensure groups are not collapsed

## Advanced Usage

### Custom Filters
Create temporary filters in the search bar:
- `path:software/llm` - LLM docs only
- `tag:#deployment` - deployment-tagged files
- `-path:history` - exclude history directory
- `file:hub` - show only hub files

### Focusing on One Area
1. Open a hub file (e.g., `software_hub.md`)
2. Click "Open local graph" in command palette
3. Adjust depth slider (1-3 levels)
4. Explore just that directory cluster

## Validation
- [ ] Graph view loads without errors
- [ ] Color groups display correctly
- [ ] Hub structure is clearly visible
- [ ] Local graph works for any document

## References
- [Obsidian Graph View Docs](https://help.obsidian.md/Plugins/Graph+view)
- [Documentation Root](index.md) - Start here for navigation
- [.obsidian/graph.json](.obsidian/graph.json) - Graph configuration file
