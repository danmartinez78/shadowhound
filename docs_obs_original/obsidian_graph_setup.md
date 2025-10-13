# How to Configure Obsidian Graph View (Manual UI Method)

Since Obsidian overwrites `graph.json` when it closes, you need to configure the graph view through the UI while Obsidian is running.

## Option 1: Run the Update Script (Easiest)

**While Obsidian is OPEN**:
```bash
cd /home/daniel/shadowhound
./scripts/update_obsidian_graph.sh
```

Then in Obsidian:
1. Press `Ctrl+G` to open Graph View
2. Click anywhere in the graph to refresh
3. Colors and better spacing should appear!

---

## Option 2: Manual UI Configuration (If Script Doesn't Work)

### Step 1: Open Graph View Settings
1. Press `Ctrl+G` to open Graph View
2. Look for the **Filters** icon on the right side
3. Click to expand the filters panel

### Step 2: Configure Display Settings
In the Filters panel:
- ✅ **Orphans**: Toggle OFF (hide orphaned notes)
- ✅ **Unresolved**: Toggle OFF (hide broken links)  
- ✅ **Arrows**: Toggle ON (show link direction)

### Step 3: Adjust Forces (Bottom of Filters Panel)
Click the **Forces** dropdown:
- **Center force**: ~0.4 (medium)
- **Repel force**: 12-15 (higher = more spacing)
- **Link force**: ~0.6 (flexible)
- **Link distance**: 300-400 (larger = more spread)

### Step 4: Add Color Groups
Click the **Groups** section in Filters:

1. Click "+ Add group"
2. In the query field, type: `path:project_overview`
3. Click the color circle and choose **Pink** (#E00972)
4. Repeat for each directory:

| Query | Color Name | Hex Code |
|-------|-----------|----------|
| `path:architecture` | Orange | #E09452 |
| `path:development` | Blue | #B13E00 |
| `path:deployment` | Dark Green | #52D452 |
| `path:software` | Teal | #52D4D1 |
| `path:hardware` | Red | #FF0000 |
| `path:networking` | Cyan | #00FFFF |
| `path:troubleshooting` | Orange | #FF8000 |
| `path:simulation` | Light Blue | #AAC7FA |
| `path:research` | Magenta | #FF00FF |
| `path:performance` | Light Orange | #FFA500 |
| `path:integrations` | Purple | #87CEFA |
| `path:issues` | Coral | #FF8080 |
| `path:history` | Gray | #606060 |
| `file:index` | White | #FFFFFF |
| `path:_hub` | Yellow | #FFFF00 |

### Step 5: Adjust Display
In the Display section:
- **Text fade threshold**: Move slider left (labels always visible)
- **Node size**: Increase to ~1.2x
- **Link line width**: Keep at 1x

### Result
You should see:
- 🤍 White `index` node in center
- 💛 Yellow hub nodes (`*_hub.md` files)
- 🎨 Color-coded directory clusters
- Better spacing and organization

---

## Troubleshooting

### Colors Not Showing
- Make sure "Groups" section is expanded (not collapsed)
- Check that each group has a proper `path:` query
- Try toggling a group off and on

### Still Too Dense
- Increase "Repel force" to 15-20
- Increase "Link distance" to 400-500
- Try **Local Graph** view instead (right-click any note → "Open local graph")

### Changes Don't Persist
- Obsidian saves `graph.json` when you close the app
- Changes made in UI should persist automatically
- Don't manually edit `graph.json` while Obsidian is open

---

## Quick Wins for Cleaner Graph

Even without colors, these help a lot:

1. **Hide orphans** - Toggle off the "Orphans" filter
2. **Increase repel strength** - Slider to 12-15
3. **Use Local Graph** - Right-click any document → "Open local graph"
   - Much cleaner view showing only nearby connections
   - Perfect for exploring one directory at a time

---

**Tip**: Once you have it configured how you like, Obsidian will remember these settings!
