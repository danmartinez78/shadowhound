---
tags: [development, workflow, quick-reference]
status: active
related: [cloud_agent_workflow.md, development_hub.md]
summary: >
  Quick reference card for using GitHub Copilot cloud agents for high-velocity development.
---

# Cloud Agent Quick Start

**TL;DR**: Use GitHub Copilot cloud agents for well-defined, time-consuming tasks to achieve 8-10x velocity gains. Full details: [Cloud Agent Workflow](cloud_agent_workflow.md)

---

## When to Use Cloud Agents

✅ **Good For**:
- Refactors with clear input/output
- Templated implementations (many similar files)
- Time-consuming but straightforward work
- Well-documented API integrations

❌ **Not Good For**:
- Exploratory/research work
- High-ambiguity tasks
- Architectural decisions
- Complex debugging

---

## 5-Step Process

### 1️⃣ **Decompose** (Local Agent + You)
```bash
# Break task into 4-8 phases with clear deliverables
# Define success criteria and validation commands
```

### 2️⃣ **Create Issue** (Local Agent)
```markdown
## Problem
[2-3 sentences]

## Implementation Plan
- [ ] Phase 1: [Name] (X-Y hours)
- [ ] Phase 2: [Name] (X-Y hours)

## Prerequisites
```bash
# Commands to understand context
```

## Success Criteria
- [ ] Specific outcome 1
- [ ] Specific outcome 2

## Validation
```bash
# Commands to verify success
```
```

### 3️⃣ **Prep Branch** (Local Agent)
```bash
# Create feature branch with context
git checkout -b feature/descriptive-name

# Add reference materials, verification artifacts
# Push to remote
git push origin feature/descriptive-name
```

### 4️⃣ **Assign** (You)
```
Comment on issue: @copilot please implement this
Continue other work while agent works async
```

### 5️⃣ **Review & Merge** (Local Agent + You)
```bash
# Fetch PR
gh pr checkout <number>

# Validate
pytest
mkdocs build
./scripts/validation.sh

# Merge if good
git checkout dev
git merge feature/name --no-ff
git push origin dev
```

---

## Success Pattern: Issue #20

**Task**: Reverse documentation pipeline (175 files, 6 phases)

**Results**:
- ⏱️ **Traditional**: 2-3 days focused work
- ⚡ **Cloud Agent**: 6 hours async + 1 hour review
- 📈 **Velocity**: 8x faster
- ✅ **Quality**: Passed all tests, caught by code review

**Key Success Factors**:
1. Exhaustively detailed implementation plan
2. Reference code to study (`link_convert.py`)
3. Both input/output formats available
4. Clear validation commands
5. Thorough human review caught edge case

---

## Quick Issue Template

Copy-paste this into new GitHub issues:

```markdown
## Problem
[Description]

## Current State
[What exists today]

## Desired State
[What should exist after]

## Prerequisites
```bash
# Commands to run before starting
```

## Implementation Plan

### Phase 1: [Name]
**Tool**: `path/to/tool.py`
**Actions**:
1. [Step 1]
2. [Step 2]
**Testing**: [How to verify]

### Phase 2-N: [Continue]

## Validation
```bash
# Test phase 1
command1

# Test phase 2
command2

# Final integration
final_command
```

## Success Criteria
- [ ] All phases complete
- [ ] Tests passing
- [ ] Documentation updated

## Definition of Done
- [ ] Implementation complete
- [ ] Tests passing
- [ ] Docs updated
- [ ] PR opened
- [ ] CI passing
```

---

## Review Checklist

```bash
# 1. Checkout PR
gh pr checkout <number>

# 2. Review code
gh pr diff <number>

# 3. Verify files created
ls -la new/files/

# 4. Run validation
pytest
mkdocs build
./scripts/validate.sh

# 5. Test edge cases
# [Project-specific]

# 6. Check docs updated
git diff origin/dev -- AGENTS.md docs/

# 7. Verify CI
gh pr checks <number>
```

**Decision**:
- ✅ **Approve**: All checks pass → merge
- 🔄 **Request Changes**: Comment specific issues
- ❌ **Close**: Major issues → update issue, reassign

---

## Pro Tips

### For Better Cloud Agent Results

1. **Be Exhaustively Detailed** - Don't assume context
2. **Provide References** - Link to similar code
3. **Define Success Precisely** - Exact commands & outputs
4. **List Pitfalls** - Known edge cases & gotchas
5. **Review Thoroughly** - Don't assume they tested everything

### For Faster Iteration

1. **Start Small** - First cloud agent task should be simple
2. **Iterate on Template** - Improve issue format each time
3. **Track Metrics** - Note what works and what doesn't
4. **Parallel Work** - Run 2-3 cloud agents simultaneously
5. **Document Lessons** - Update workflow doc after each use

---

## Metrics to Track

After each cloud agent task, note:

- ⏱️ **Time saved**: Estimated manual time - actual time
- ✅ **Quality**: Pass rate, issues found in review
- 🔄 **Iterations**: How many rounds of changes needed
- 📊 **Complexity**: Simple/Medium/Complex task

**Target Performance**:
- ⏱️ Time savings: 5-10x
- ✅ First-pass quality: >90%
- 🔄 Iterations: 0-1 rounds of changes
- 📊 Sweet spot: Medium complexity tasks

---

## Need Help?

- 📖 **Full Workflow**: [Cloud Agent Workflow](cloud_agent_workflow.md)
- 💬 **Questions**: Ask in issue comments or team chat
- 📝 **Updates**: Improve this doc with your learnings!

---

**Last Updated**: 2025-10-13  
**Next Review**: After next 3 cloud agent collaborations
