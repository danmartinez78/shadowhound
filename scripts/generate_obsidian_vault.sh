#!/bin/bash
#
# Generate Obsidian vault from standard Markdown documentation
#
# This script converts docs/ (standard markdown) to docs_obs/ (Obsidian wikilinks)
# for local viewing in Obsidian. The generated vault is gitignored.
#

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Generating Obsidian vault from standard Markdown...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Paths
DOCS_DIR="$REPO_ROOT/docs"
VAULT_DIR="$REPO_ROOT/docs_obs"
OBSIDIAN_CONFIG="$DOCS_DIR/.obsidian"

# Check if docs directory exists
if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${YELLOW}❌ Error: docs/ directory not found at $DOCS_DIR${NC}"
    exit 1
fi

# Check if obsidian config exists
if [ ! -d "$OBSIDIAN_CONFIG" ]; then
    echo -e "${YELLOW}⚠️  Warning: .obsidian config not found at $OBSIDIAN_CONFIG${NC}"
    echo "   Vault will be created without Obsidian configuration."
fi

# Clean old vault
if [ -d "$VAULT_DIR" ]; then
    echo "🗑️  Removing old vault at $VAULT_DIR"
    rm -rf "$VAULT_DIR"
fi

# Convert docs → vault
echo "📝 Converting markdown links to wikilinks..."
python3 "$REPO_ROOT/tools/obsidian_convert.py" "$DOCS_DIR" "$VAULT_DIR"

# Copy Obsidian config if it exists
if [ -d "$OBSIDIAN_CONFIG" ]; then
    echo "⚙️  Copying Obsidian configuration..."
    cp -r "$OBSIDIAN_CONFIG" "$VAULT_DIR/.obsidian"
fi

echo ""
echo -e "${GREEN}✅ Vault generated successfully!${NC}"
echo ""
echo "📍 Location: $VAULT_DIR"
echo "👁️  To view: Open '$VAULT_DIR' as a vault in Obsidian"
echo "🔗 Graph view: Cmd/Ctrl+G in Obsidian"
echo ""
echo -e "${YELLOW}Note: docs_obs/ is gitignored. Regenerate after pulling changes.${NC}"
