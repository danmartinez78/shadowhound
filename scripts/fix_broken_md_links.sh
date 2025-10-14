#!/bin/bash
# Fix broken markdown-style links that create phantom nodes in Obsidian graph
# These are [text](file.md) style links (not wikilinks)

cd /home/daniel/shadowhound/docs

echo "Fixing broken markdown-style links..."

# Fix case-sensitive OLLAMA references → lowercase ollama
sed -i 's|OLLAMA_SETUP\.md|ollama_setup.md|g' software/llm/*.md
sed -i 's|OLLAMA_BACKEND_INTEGRATION\.md|ollama_backend_integration.md|g' software/llm/*.md
sed -i 's|OLLAMA_QUALITY_SCORING\.md|ollama_quality_scoring.md|g' software/llm/*.md
sed -i 's|OLLAMA_BENCHMARKING\.md|ollama_benchmarking.md|g' software/llm/*.md
sed -i 's|OLLAMA_MODELS\.md|ollama_models.md|g' software/llm/*.md

# Fix broken relative paths in integrations/vlm_integration_summary.md
sed -i 's|\.\./src/shadowhound_skills/README\.md|../../src/shadowhound_skills/README.md|g' integrations/vlm_integration_summary.md
sed -i 's|\.\./docs/dimos_vision_capabilities\.md|dimos_vision_capabilities.md|g' integrations/vlm_integration_summary.md
sed -i 's|\.\./docs/vision_integration_design\.md|vision_integration_design.md|g' integrations/vlm_integration_summary.md
sed -i 's|\.\./docs/camera_architecture\.md|../architecture/camera_architecture.md|g' integrations/vlm_integration_summary.md

# Fix broken paths in software/llm/vllm_quickstart.md
sed -i 's|\.\./scripts/README\.md|../../scripts/README.md|g' software/llm/vllm_quickstart.md
sed -i 's|\.\./docs/vllm_huggingface_auth\.md|vllm_huggingface_auth.md|g' software/llm/vllm_quickstart.md

# Fix architecture/architecture_hub.md
sed -i 's|\.\./README\.md|../index.md|g' architecture/architecture_hub.md

echo ""
echo "✅ Fixed broken markdown-style links!"
echo "   - Case-corrected OLLAMA → ollama (5 files)"
echo "   - Fixed relative paths in integrations/"
echo "   - Fixed relative paths in software/llm/"
echo "   - Updated architecture hub"
echo ""
echo "Note: development/cleanup_plan.md has many broken links but it's a historical"
echo "planning doc, not critical for navigation. Consider moving to history/ if needed."
