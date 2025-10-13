#!/bin/bash
# Fix phantom nodes caused by related: [] field in YAML front-matter
# Obsidian treats these as wikilinks even without [[ ]] brackets

cd /home/daniel/shadowhound/docs

echo "Fixing related: field phantom nodes..."

# Simply clear all related fields to empty arrays
# This removes the phantom nodes without losing file structure
find . -name "*.md" -type f | while read file; do
    if grep -q "^related: \[.*[a-zA-Z].*\]" "$file"; then
        echo "  Clearing related field in: $file"
        sed -i 's/^related: \[.*\]/related: []/' "$file"
    fi
done

echo ""
echo "✅ Done! All related: fields cleared."
echo ""
echo "The related: field is just metadata and wasn't being used for navigation."
echo "This removes the phantom nodes without affecting actual wikilinks."
echo ""
echo "Reopen Obsidian to see the cleaned graph."
