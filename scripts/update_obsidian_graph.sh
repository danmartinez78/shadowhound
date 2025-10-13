#!/bin/bash
# Update Obsidian graph.json WHILE OBSIDIAN IS RUNNING
# Run this script, then immediately switch to Obsidian and open graph view

cd "$(dirname "$0")/../docs/.obsidian"

echo "Updating graph.json with optimized settings..."
echo "⚠️  IMPORTANT: Keep Obsidian OPEN while running this!"
echo ""

cat > graph.json << 'EOF'
{
  "collapse-filter": false,
  "search": "",
  "showTags": false,
  "showAttachments": false,
  "hideUnresolved": true,
  "showOrphans": false,
  "collapse-color-groups": false,
  "colorGroups": [
    {
      "query": "path:project_overview",
      "color": {
        "a": 1,
        "rgb": 14701138
      }
    },
    {
      "query": "path:architecture",
      "color": {
        "a": 1,
        "rgb": 14725458
      }
    },
    {
      "query": "path:development",
      "color": {
        "a": 1,
        "rgb": 11621088
      }
    },
    {
      "query": "path:deployment",
      "color": {
        "a": 1,
        "rgb": 5431378
      }
    },
    {
      "query": "path:software",
      "color": {
        "a": 1,
        "rgb": 5431473
      }
    },
    {
      "query": "path:hardware",
      "color": {
        "a": 1,
        "rgb": 16711680
      }
    },
    {
      "query": "path:networking",
      "color": {
        "a": 1,
        "rgb": 65535
      }
    },
    {
      "query": "path:troubleshooting",
      "color": {
        "a": 1,
        "rgb": 16755200
      }
    },
    {
      "query": "path:simulation",
      "color": {
        "a": 1,
        "rgb": 11184810
      }
    },
    {
      "query": "path:research",
      "color": {
        "a": 1,
        "rgb": 16711935
      }
    },
    {
      "query": "path:performance",
      "color": {
        "a": 1,
        "rgb": 16744448
      }
    },
    {
      "query": "path:integrations",
      "color": {
        "a": 1,
        "rgb": 8900346
      }
    },
    {
      "query": "path:issues",
      "color": {
        "a": 1,
        "rgb": 16737792
      }
    },
    {
      "query": "path:history",
      "color": {
        "a": 1,
        "rgb": 6316128
      }
    },
    {
      "query": "file:index",
      "color": {
        "a": 1,
        "rgb": 16777215
      }
    },
    {
      "query": "path:_hub",
      "color": {
        "a": 1,
        "rgb": 16776960
      }
    }
  ],
  "collapse-display": false,
  "showArrow": true,
  "textFadeMultiplier": -0.5,
  "nodeSizeMultiplier": 1.2,
  "lineSizeMultiplier": 1,
  "collapse-forces": false,
  "centerStrength": 0.4,
  "repelStrength": 12,
  "linkStrength": 0.6,
  "linkDistance": 300,
  "scale": 1.0,
  "close": false
}
EOF

echo "✅ graph.json updated!"
echo ""
echo "Next steps:"
echo "1. Switch to Obsidian (keep it open!)"
echo "2. Open Graph View (Ctrl+G)"
echo "3. Click anywhere in the graph to refresh"
echo "4. You should see colors and better spacing!"
echo ""
echo "If colors don't show:"
echo "- Click the filters icon (right side)"
echo "- Expand 'Groups' section"
echo "- Ensure groups are not collapsed"
