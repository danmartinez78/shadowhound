---
tags: [issues, index]
status: active
related: [troubleshooting/README, software/llm/llm_backend_validation]
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
- **[[issues/vllm_mistral_tokenizer_hang|vLLM Mistral Tokenizer Hang]]** — Inference hang issue with Mistral models
- **[[issues/forcing_function_calling_with_prompts|Forcing Function Calling]]** — Workaround for function calling reliability
- **[[issues/vllm_tool_calling_configuration|vLLM Tool Calling Configuration]]** — Configuration requirements
- **[[issues/vllm_tool_calling_not_executing|vLLM Tool Calling Not Executing]]** — Debugging tool execution

### System Issues
- **[[issues/start_script_issues|Start Script Issues]]** — Start script troubleshooting
- **[[issues/thor_system_utilities|Thor System Utilities]]** — Thor-specific system utilities
- **[[issues/mock_mode_ros_topic_dependency|Mock Mode ROS Topic Dependency]]** — ROS topic dependencies in mock mode

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
4. Consider moving to [[../history/|history/]] if resolved

## Validation
- [ ] Active issues have reproduction steps
- [ ] Workarounds documented and tested
- [ ] Resolved issues moved to history or marked complete

## See Also
- [[troubleshooting/troubleshooting_hub|Troubleshooting Documentation]] — Diagnostic procedures
- [[../software/llm/llm_backend_validation|LLM Backend Validation]] — Backend health checks
- [[development/development_hub|Development Documentation]] — Contribution guidelines
- [[issues/issues_hub|Documentation Index]] — Complete documentation map

## References
- [[../index|Documentation Root]]
- GitHub Issues: https://github.com/danmartinez78/shadowhound/issues
