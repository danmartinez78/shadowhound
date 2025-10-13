---
tags: [issues, index]
status: active
related: []
aliases: [Issues Index]
summary: >
  Known issues, workarounds, and tracked bugs for ShadowHound system.
---

# Issues Index

## Purpose
Track known issues, workarounds, and bug investigation notes for the ShadowHound system.

## Prerequisites
- Understanding of affected subsystems
- Access to logs and diagnostic tools

## Active Issues

### vLLM & LLM Backends
- **[vLLM Mistral Tokenizer Hang](../issues/vllm_mistral_tokenizer_hang.md)** — Inference hang issue with Mistral models
- **[Forcing Function Calling](../issues/forcing_function_calling_with_prompts.md)** — Workaround for function calling reliability
- **[vLLM Tool Calling Configuration](../issues/vllm_tool_calling_configuration.md)** — Configuration requirements
- **[vLLM Tool Calling Not Executing](../issues/vllm_tool_calling_not_executing.md)** — Debugging tool execution

### System Issues
- **[Start Script Issues](../issues/start_script_issues.md)** — Start script troubleshooting
- **[Thor System Utilities](../issues/thor_system_utilities.md)** — Thor-specific system utilities
- **[Mock Mode ROS Topic Dependency](../issues/mock_mode_ros_topic_dependency.md)** — ROS topic dependencies in mock mode

### Legacy Issues
- known_issues.md (legacy, needs review)
- multi_step_execution_issue.md (legacy, needs review)

## Issue Workflow

### Reporting New Issues
1. Check if issue already documented
2. Create new issue document with:
   - Symptoms and reproduction steps
   - Environment details (hardware, software versions)
   - Diagnostic output (logs, error messages)
   - Attempted workarounds

### Resolving Issues
1. Document investigation steps
2. Update issue document with root cause
3. Link to fix/workaround in relevant docs
4. Consider moving to [history/](../history/.md) if resolved

## Validation
- [ ] Active issues have reproduction steps
- [ ] Workarounds documented and tested
- [ ] Resolved issues moved to history or marked complete

## See Also
- [Troubleshooting Documentation](../troubleshooting/troubleshooting_hub.md) — Diagnostic procedures
- [LLM Backend Validation](../software/llm/llm_backend_validation.md) — Backend health checks
- [Development Documentation](../development/development_hub.md) — Contribution guidelines
- [Documentation Index](../issues/issues_hub.md) — Complete documentation map

## References
- [Documentation Root](../index.md)
- GitHub Issues: https://github.com/danmartinez78/shadowhound/issues
