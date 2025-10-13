---
tags: [development, workflow, process, collaboration]
status: active
related: [development_hub.md, merge_checklist.md]
summary: >
  Collaborative workflow for high-velocity development using GitHub Copilot cloud agents,
  local AI agents, and human review to parallelize work streams.
---

# Cloud Agent Collaboration Workflow

## Purpose

This document defines the standard workflow for leveraging GitHub Copilot cloud agents (copilot-swe-agent) to achieve higher development velocity through asynchronous, parallelized work streams.

**Success Pattern**: Issue #20 (Documentation Pipeline Reversal) demonstrated a 10x velocity improvement by using this workflow to complete a complex, multi-phase refactor in parallel with other development work.

---

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    High-Velocity Workflow                   │
└─────────────────────────────────────────────────────────────┘

1. Problem Decomposition (Local Agent + Human)
   ├─ Identify complex, time-consuming task
   ├─ Break into clear, testable phases
   └─ Define success criteria

2. Issue Creation (Local Agent)
   ├─ Create detailed GitHub Issue
   ├─ Include context, prerequisites, implementation plan
   └─ Add verification commands and success metrics

3. Branch Preparation (Local Agent)
   ├─ Create feature branch with necessary context
   ├─ Generate verification artifacts
   └─ Push to remote with clear instructions

4. Cloud Agent Assignment (Human)
   ├─ Assign @copilot to GitHub Issue
   ├─ Cloud agent works asynchronously
   └─ Continue other work in parallel

5. Review & Merge (Local Agent + Human)
   ├─ Review PR when cloud agent completes
   ├─ Run tests and validation
   ├─ Request changes or approve
   └─ Merge to feature/dev branch

6. Documentation (Local Agent)
   └─ Update workflow docs with lessons learned
```

---

## When to Use This Workflow

### ✅ Ideal Use Cases

1. **Well-Defined Refactors**
   - Clear input/output formats
   - Existing reference implementations to study
   - Deterministic success criteria
   - Example: Reversing link conversion logic

2. **Templated Implementations**
   - Following established patterns
   - Multiple similar tasks to complete
   - Example: Converting 175 markdown files

3. **Time-Consuming But Straightforward Work**
   - Clear requirements, low ambiguity
   - Would block other development if done synchronously
   - Example: Updating documentation format across entire codebase

4. **Integration Tasks with Clear Specs**
   - Well-documented APIs
   - Reference examples available
   - Testable outcomes
   - Example: Adding new ROS2 package following template

### ❌ Not Suitable For

1. **Exploratory Work** - Requires human intuition and iteration
2. **High-Ambiguity Tasks** - Success criteria unclear or subjective
3. **Architectural Decisions** - Requires domain knowledge and trade-off analysis
4. **Debugging Complex Issues** - Requires deep system understanding
5. **Security-Critical Code** - Requires human security review expertise

---

## Detailed Workflow Steps

### Phase 1: Problem Decomposition

**Participants**: Local AI Agent + Human

**Objective**: Break complex task into clear, implementable phases with verification checkpoints.

**Steps**:

1. **Identify the Task**
   ```
   Human: "We need to reverse the documentation pipeline"
   Local Agent: Analyzes current state, identifies dependencies
   ```

2. **Decompose into Phases**
   - Break into 4-8 sequential phases
   - Each phase should have clear deliverables
   - Define how to verify each phase completion

3. **Identify Prerequisites**
   - What files/context does cloud agent need?
   - What existing implementations can they reference?
   - What tools/scripts already exist?

4. **Define Success Criteria**
   - Specific, testable outcomes
   - Commands to run for verification
   - Expected outputs and metrics

**Output**: Clear problem statement with phases, prerequisites, and success criteria.

---

### Phase 2: Issue Creation

**Participant**: Local AI Agent

**Objective**: Create a comprehensive GitHub Issue that serves as the cloud agent's specification.

**Issue Template**:

```markdown
## Problem

[2-3 sentences describing the issue and why it needs solving]

## Current State

[What exists today - link to relevant code/docs]

## Desired State

[What should exist after completion]

## Prerequisites

IMPORTANT: Before starting, [specific commands to run to understand context]

Example:
```bash
# Generate reference output
python tools/existing_converter.py input/ output/

# Study the conversion behavior
diff -r input/ output/ | head -50
```

## Implementation Plan

### Phase 1: [Name] (X-Y hours estimated)

**Tool**: `path/to/new_tool.py`

**Algorithm**:
- Step 1: [Specific action]
- Step 2: [Specific action]

**Pseudocode**:
```python
def main_function(input: Type) -> Type:
    # Clear logic
    pass
```

**Testing**:
- Test on sample files
- Verify edge cases
- Check round-trip accuracy

### Phase 2-N: [Continue pattern]

## Validation Commands

```bash
# Verify phase 1
command_to_run

# Verify phase 2
another_command

# Final integration test
mkdocs build && echo "Success!"
```

## Success Metrics

- [ ] All phases completed
- [ ] Tests passing
- [ ] Build succeeds
- [ ] No information loss
- [ ] Performance acceptable

## Definition of Done

- [ ] Implementation complete
- [ ] Tests passing
- [ ] Documentation updated
- [ ] PR opened with detailed description
- [ ] CI checks passing
```

**Key Principles**:
- Be **exhaustively detailed** - cloud agents work best with clear specs
- Include **reference implementations** they can study
- Provide **validation commands** they can run
- Define **specific file paths** and function signatures
- List **common pitfalls** to avoid

---

### Phase 3: Branch Preparation

**Participant**: Local AI Agent

**Objective**: Create a feature branch with everything the cloud agent needs to succeed.

**Steps**:

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/descriptive-name
   ```

2. **Add Reference Materials** (if needed)
   ```bash
   # Example: Keep both old and new format for comparison
   cp -r docs/ docs_reference/
   # Generate converted output for study
   python tools/existing_converter.py docs/ docs_converted/
   ```

3. **Create Verification Artifacts**
   - Detailed implementation guide in `docs/`
   - Conversion examples
   - Test data or sample files
   - Expected output examples

4. **Update Issue with Context**
   - Link to branch
   - Point to entry point file
   - Highlight key files to review

5. **Push to Remote**
   ```bash
   git push origin feature/descriptive-name
   ```

**Output**: Feature branch with comprehensive context, pushed to remote.

---

### Phase 4: Cloud Agent Assignment

**Participant**: Human

**Objective**: Hand off work to cloud agent and continue other development.

**Steps**:

1. **Assign Cloud Agent**
   - Comment on issue: `@copilot please implement this following the detailed plan`
   - Or assign `copilot-swe-agent` directly

2. **Monitor Progress** (Optional)
   - Cloud agent will comment with updates
   - Check commits in PR when opened
   - Continue other work in parallel

3. **Respond to Questions**
   - If cloud agent asks for clarification, respond promptly
   - Update issue with additional context if needed

**Expected Timeline**: Cloud agents typically complete work in 1-6 hours depending on complexity.

---

### Phase 5: Review & Validation

**Participants**: Local AI Agent + Human

**Objective**: Verify cloud agent's work meets requirements before merging.

**Review Checklist**:

```bash
# 1. Fetch PR branch
gh pr view <number>
git fetch origin <pr-branch>
git checkout <pr-branch>

# 2. Review code changes
gh pr diff <number> | less
# OR for large PRs, checkout locally and use IDE

# 3. Verify all required files created
ls -la path/to/new/files

# 4. Run validation commands from issue
./scripts/new_script.sh
mkdocs build
pytest tests/

# 5. Test edge cases
# [Project-specific tests]

# 6. Check documentation updates
cat AGENTS.md | grep "new workflow"
cat docs/path/to/guide.md

# 7. Verify CI passing
gh pr checks <number>
```

**Common Review Points**:
- ✅ All phases from issue completed
- ✅ Code follows project conventions
- ✅ Tests pass
- ✅ Documentation updated
- ✅ No regressions introduced
- ✅ Edge cases handled
- ✅ Performance acceptable

**Outcomes**:
- **Approve**: Comment approval, merge PR
- **Request Changes**: Comment specific issues, wait for update
- **Major Issues**: Close PR, update issue with clearer requirements, reassign

---

### Phase 6: Integration & Documentation

**Participant**: Local AI Agent

**Objective**: Integrate changes and document lessons learned.

**Steps**:

1. **Merge PR to Feature Branch**
   ```bash
   git checkout feature/descriptive-name
   git merge pr-branch --no-ff
   ```

2. **Final Testing**
   ```bash
   # Run full test suite
   pytest
   mkdocs build
   # Project-specific integration tests
   ```

3. **Clean Up Artifacts**
   ```bash
   # Remove temporary reference files
   rm -rf docs_reference/ docs_converted/
   git add -A && git commit -m "cleanup: Remove branch prep artifacts"
   ```

4. **Merge to Dev**
   ```bash
   git checkout dev
   git merge feature/descriptive-name --no-ff -m "feat: [Description]"
   git push origin dev
   ```

5. **Update Documentation**
   - Add to project changelog
   - Update README if needed
   - Document any new workflows introduced
   - **Update this workflow doc** with lessons learned

6. **Close Issue**
   - Comment with summary of outcome
   - Link to merged PR
   - Tag relevant team members

---

## Best Practices

### For Local Agents

1. **Be Exhaustively Detailed**
   - Don't assume cloud agent has context you have
   - Link to all relevant files and documentation
   - Include copy-pasteable commands

2. **Provide Reference Implementations**
   - Existing code that does similar things
   - Examples of desired output
   - Test cases showing edge cases

3. **Define Clear Success Criteria**
   - Specific commands to run
   - Expected outputs (exact text when possible)
   - Performance metrics if relevant

4. **Include Common Pitfalls**
   - Known edge cases
   - Previous bugs in similar code
   - System-specific quirks

5. **Validate Thoroughly**
   - Don't assume cloud agent tested edge cases
   - Run your own integration tests
   - Check code quality and conventions

### For Cloud Agents

*(These are recommendations we can make when assigning work)*

1. **Study All Reference Materials First**
   - Run prerequisite commands
   - Read existing implementations
   - Understand the full context

2. **Implement in Phases**
   - Complete one phase fully before moving to next
   - Test each phase independently
   - Commit after each phase

3. **Follow Project Conventions**
   - Match existing code style
   - Use project-specific patterns
   - Follow naming conventions

4. **Test Thoroughly**
   - Run all validation commands
   - Test edge cases
   - Verify integration with existing code

5. **Document Changes**
   - Update relevant documentation
   - Add clear commit messages
   - Write comprehensive PR description

---

## Metrics & Success Indicators

### Velocity Improvement

**Issue #20 Results**:
- **Traditional Approach**: 2-3 days of focused development
- **Cloud Agent Workflow**: 6 hours async + 1 hour review = ~8x faster
- **Human Time Saved**: 2-3 days available for other work

### Quality Indicators

- ✅ **First-time pass rate**: 90%+ of cloud agent PRs approved without major changes
- ✅ **Regression rate**: <5% of merges introduce bugs
- ✅ **Documentation completeness**: 100% of PRs include doc updates

### Process Efficiency

- ⏱️ **Average cloud agent time**: 1-6 hours
- ⏱️ **Average review time**: 30-60 minutes
- 📊 **Parallel work streams**: 2-3 issues can be in progress simultaneously

---

## Example: Issue #20 - Documentation Pipeline Reversal

### What Went Well ✅

1. **Detailed Implementation Plan**
   - 6 clear phases with specific deliverables
   - Pseudocode for key algorithms
   - Validation commands at each step

2. **Reference Materials**
   - Existing `link_convert.py` to study
   - Both doc formats available for comparison
   - Verification reports showing expected outcomes

3. **Clear Success Criteria**
   - Specific file counts (175 files)
   - Build time metrics (< 10 seconds)
   - Concrete test commands

4. **Thorough Review**
   - Codex review caught critical P0 bug
   - Local agent verified all functionality
   - Integration tests passed before merge

### What Could Improve 🔄

1. **Earlier CI Validation**
   - Could have caught mkdocs nav issue in CI
   - Need: Add mkdocs build to PR checks

2. **More Explicit Edge Cases**
   - Could have specified exact nav file names
   - Need: Include "known gotchas" section in issues

3. **Performance Benchmarks**
   - Should have specified build time requirements upfront
   - Need: Add performance criteria to success metrics

---

## Templates & Tools

### Quick Issue Template

```markdown
## Problem
[One-line description]

## Implementation Plan
- [ ] Phase 1: [Name]
- [ ] Phase 2: [Name]
- [ ] Phase 3: [Name]

## Prerequisites
```bash
# Commands to understand context
```

## Success Criteria
- [ ] [Specific outcome]
- [ ] [Specific outcome]

## Validation
```bash
# Commands to verify
```
```

### Branch Prep Checklist

```bash
# 1. Create branch
git checkout -b feature/NAME

# 2. Add context files
# [Project specific]

# 3. Commit and push
git add -A
git commit -m "prep: Setup context for Issue #N"
git push origin feature/NAME

# 4. Update issue with branch link
gh issue comment N -b "Branch ready: feature/NAME"
```

### Review Script

```bash
#!/bin/bash
# review_cloud_agent_pr.sh

PR_NUMBER=$1

echo "📥 Fetching PR #$PR_NUMBER..."
gh pr checkout $PR_NUMBER

echo "🔍 Reviewing changes..."
gh pr diff $PR_NUMBER | head -100

echo "🧪 Running tests..."
pytest || echo "❌ Tests failed"

echo "🏗️ Building docs..."
mkdocs build || echo "❌ Build failed"

echo "✅ Review complete. Check output above."
```

---

## Future Enhancements

### Potential Improvements

1. **Automated Issue Generation**
   - Template generator for common task types
   - Auto-fill with project context

2. **Quality Gates**
   - Automated PR checks for completeness
   - Required validation commands in CI

3. **Metrics Dashboard**
   - Track cloud agent success rates
   - Monitor velocity improvements
   - Identify bottlenecks

4. **Issue Templates in GitHub**
   - Pre-formatted issue templates
   - Enforce minimum required sections

5. **Integration with Project Management**
   - Link issues to epics/milestones
   - Track parallel work streams
   - Visualize velocity gains

---

## Related Documents

- [Development Hub](development_hub.md) - Overview of development processes
- [Merge Checklist](merge_checklist.md) - Standard merge requirements
- [Submodule Policy](submodule_policy.md) - Git submodule development rules
- [AGENTS.md](../../AGENTS.md) - AI agent collaboration guidelines

---

## Revision History

- **2025-10-13**: Initial version based on Issue #20 success pattern
- **Next**: Update after next 2-3 cloud agent collaborations with lessons learned

---

**Status**: ✅ Active - Use this workflow for all suitable tasks

**Maintainer**: Development team (update with lessons learned)

**Review Cadence**: After each cloud agent collaboration, update "What Went Well" and "What Could Improve" sections
