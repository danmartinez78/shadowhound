#!/bin/bash
# Documentation reorganization script
# Moves files to appropriate subdirectories while preserving git history

set -e

cd "$(dirname "$0")/../docs"

echo "🔧 Starting documentation reorganization..."
echo ""

# Agent/Planning docs → software/agent/
echo "📁 Moving agent documentation..."
git mv agent_refactor_analysis.md software/agent/ 2>/dev/null || true
git mv agent_tasks.md software/agent/ 2>/dev/null || true
git mv dimos_agent_architecture.md software/agent/ 2>/dev/null || true

# Architecture docs → architecture/
echo "📁 Moving architecture documentation..."
git mv architecture_clarification.md architecture/ 2>/dev/null || true
git mv arch_update_summary.md architecture/ 2>/dev/null || true
git mv camera_architecture.md architecture/ 2>/dev/null || true
git mv deployment_topology.md architecture/ 2>/dev/null || true

# Configuration docs → software/configuration/
echo "📁 Moving configuration documentation..."
git mv environment_variables.md software/configuration/ 2>/dev/null || true
git mv embeddings_auto_detection.md software/configuration/ 2>/dev/null || true
git mv startup_validation.md software/configuration/ 2>/dev/null || true

# LLM/Backend docs → software/llm/
echo "📁 Moving LLM/backend documentation..."
git mv BACKEND_QUICK_REFERENCE.md software/llm/backend_quick_reference.md 2>/dev/null || true
git mv BACKEND_VALIDATION_SUMMARY.md software/llm/backend_validation_summary.md 2>/dev/null || true
git mv FEATURE_COMPLETE_OLLAMA.md software/llm/feature_complete_ollama.md 2>/dev/null || true
git mv OLLAMA_*.md software/llm/ 2>/dev/null || true
git mv ollama_*.md software/llm/ 2>/dev/null || true
git mv local_llm_*.md software/llm/ 2>/dev/null || true
git mv vllm_*.md software/llm/ 2>/dev/null || true
git mv llama_cpp_*.md software/llm/ 2>/dev/null || true
git mv EOD_SUMMARY_2025-10-10.md history/ 2>/dev/null || true
git mv THOR_PERFORMANCE_NOTES.md software/llm/ 2>/dev/null || true
git mv THOR_RESOURCES.md software/llm/ 2>/dev/null || true
git mv QUALITY_SCORING_SUMMARY.md software/llm/ 2>/dev/null || true
git mv TESTING_GUIDE_OLLAMA.md software/llm/ 2>/dev/null || true
git mv SECURITY_ANALYSIS_JTOP.md software/llm/ 2>/dev/null || true

# Integration docs → integrations/
echo "📁 Moving integration documentation..."
git mv chatgpt_integration.md integrations/ 2>/dev/null || true
git mv dimos_integration.md integrations/ 2>/dev/null || true
git mv rag_integration.md integrations/ 2>/dev/null || true
git mv vision_integration_design.md integrations/ 2>/dev/null || true
git mv vlm_integration_summary.md integrations/ 2>/dev/null || true

# UI/Web docs → software/web/
echo "📁 Moving UI/web documentation..."
git mv ui_*.md software/web/ 2>/dev/null || true
git mv web_*.md software/web/ 2>/dev/null || true
git mv webrtc_configuration.md software/web/ 2>/dev/null || true
git mv webrtc_discovery.md software/web/ 2>/dev/null || true
git mv webrtc_instant_commands_fix.md software/web/ 2>/dev/null || true

# Deployment docs → deployment/
echo "📁 Moving deployment documentation..."
git mv deployment_sync.md deployment/ 2>/dev/null || true
git mv codex_*.md deployment/ 2>/dev/null || true
git mv laptop_*.md deployment/ 2>/dev/null || true

# Development process → development/
echo "📁 Moving development documentation..."
git mv development_tracking.md development/ 2>/dev/null || true
git mv dimos_development_policy.md development/ 2>/dev/null || true
git mv dimos_branch_consolidation.md development/ 2>/dev/null || true
git mv cache_clearing_guide.md development/ 2>/dev/null || true
git mv indentation_fix.md development/ 2>/dev/null || true
git mv auto_update.md development/ 2>/dev/null || true

# Merge/EOD summaries → history/
echo "📁 Moving historical documentation..."
git mv merge_*.md history/ 2>/dev/null || true
git mv doc_validation_summary.md history/ 2>/dev/null || true

# Miscellaneous cleanup
echo "📁 Moving miscellaneous documentation..."
git mv camera_feed_integration.md integrations/ 2>/dev/null || true
git mv command_mode_conflict.md troubleshooting/ 2>/dev/null || true
git mv debugging_robot_commands.md troubleshooting/ 2>/dev/null || true
git mv copilot_cli_setup.md development/ 2>/dev/null || true
git mv topic_diagnostics.md troubleshooting/ 2>/dev/null || true
git mv troubleshooting_mission_agent.md troubleshooting/ 2>/dev/null || true
git mv mvp_plan_pivot.md history/ 2>/dev/null || true
git mv qol_improvements.md development/ 2>/dev/null || true

# DIMOS-specific
git mv dimos_capabilities.md integrations/ 2>/dev/null || true
git mv dimos_vision_capabilities.md integrations/ 2>/dev/null || true

# Roadmap/planning
git mv roadmap.md project_overview/ 2>/dev/null || true

# Orchestration
git mv orchestrated_launch*.md deployment/ 2>/dev/null || true

echo ""
echo "✅ Documentation reorganization complete!"
echo ""
echo "Next steps:"
echo "  1. Review moved files: git status"
echo "  2. Update internal links"
echo "  3. Create README.md files in new directories"
echo "  4. Validate links: python tools/validate_wikilinks.py --docs docs"
