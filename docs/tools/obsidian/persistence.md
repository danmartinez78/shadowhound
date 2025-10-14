# Obsidian Graph Configuration Persistence

## Problem
Obsidian overwrites `.obsidian/graph.json` when the app closes, losing our optimized settings.

## Solution
Apply the configuration while Obsidian is **closed**, then open Obsidian:

```bash
# 1. Close Obsidian completely

# 2. Apply graph config
cd /home/daniel/shadowhound/scripts
./update_obsidian_graph.sh

# 3. Open Obsidian
# The settings will now be loaded and persist
```

## What Gets Applied
- **16 Color Groups**: Directories and hubs color-coded
- **Improved Physics**: Better node spacing (repel: 12, distance: 300)
- **Hide Unresolved**: Phantom nodes hidden
- **Hide Orphans**: Disconnected nodes hidden

## Color Legend
| Color | Path | Purpose |
|-------|------|---------|
| White | `file:index` | Main index |
| Yellow | `path:_hub` | All hub files |
| Pink | `path:project_overview` | Project docs |
| Orange | `path:architecture` | Architecture |
| Blue | `path:development` | Development |
| Green | `path:deployment` | Deployment |
| Teal | `path:software` | Software |
| Red | `path:hardware` | Hardware |
| Cyan | `path:networking` | Networking |
| Orange | `path:troubleshooting` | Troubleshooting |
| Lime | `path:simulation` | Simulation |
| Magenta | `path:research` | Research |
| Orange | `path:performance` | Performance |
| Dark Teal | `path:integrations` | Integrations |
| Coral | `path:issues` | Issues |
| Gray | `path:history` | Historical docs |

## Verifying It Worked
After opening Obsidian:
1. Press `Ctrl+G` to open graph view
2. Right side → **Filters** panel → **Groups** section
3. You should see 16 color groups listed
4. Nodes should be color-coded by directory

## If It Gets Reset Again
Obsidian writes graph.json on close. If you manually edit graph settings in the UI:
1. Your changes will persist (they're saved immediately)
2. But closing and running our script will overwrite your manual changes

**Recommendation**: Either use the script OR manually configure through UI, not both.

## Manual Configuration Alternative
See `setup.md` for step-by-step UI configuration if you prefer not to use the script.
