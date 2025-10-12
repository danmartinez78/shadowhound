#!/bin/bash
# Quick test to check if embeddings dependencies are installed

echo "Checking embeddings dependencies..."
echo ""

packages=(
    "chromadb"
    "langchain_chroma"
    "sentence_transformers"
)

missing=()

for pkg in "${packages[@]}"; do
    if python3 -c "import ${pkg}" 2>/dev/null; then
        echo "✓ ${pkg}"
    else
        echo "✗ ${pkg} (missing)"
        missing+=("$pkg")
    fi
done

echo ""

if [ ${#missing[@]} -eq 0 ]; then
    echo "✓ All embeddings dependencies installed!"
    exit 0
else
    echo "✗ Missing: ${missing[*]}"
    echo ""
    echo "To install:"
    echo "  pip install chromadb langchain-chroma sentence-transformers"
    echo ""
    echo "Or run: ./start.sh (it will prompt to install automatically)"
    exit 1
fi
