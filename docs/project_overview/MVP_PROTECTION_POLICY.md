---
tags: [policy, critical, mvp, governance]
status: active
related: [mvp_embodied_ai_platform.md]
summary: >
  Protection and governance policy for MVP roadmap document
---

# MVP Roadmap Protection Policy

**Created**: 2025-10-14  
**Status**: ACTIVE - ENFORCE STRICTLY  
**Criticality**: HIGH - Source of Truth Document

---

## Purpose

The MVP roadmap (`mvp_embodied_ai_platform.md`) is the **source of truth** for project scope, direction, and priorities. This policy ensures:

1. ✅ AI agents **READ and USE** the roadmap for context
2. ✅ Changes require **explicit user approval**
3. ✅ Scope creep is **prevented**
4. ✅ All documentation **aligns** with the roadmap

---

## Why This Matters

**Historical Context**: Prior to 2025-10-14, project scope became confused and shifted unintentionally:
- Multiple competing visions
- Unclear priorities
- Agents made assumptions without grounding
- Documentation drift and inconsistency

**The Roadmap Fix**: Comprehensive requirements gathering session resulted in clear, approved MVP scope.

**Risk**: Without protection, scope will drift again as agents iterate and make changes.

---

## Policy Rules

### Rule 1: AI Agents MUST Read the Roadmap

**When**: At the start of ANY significant work session

**How**:
```bash
# Agents should read the roadmap for context
cat docs/project_overview/mvp_embodied_ai_platform.md
```

**What to extract**:
- MVP definition and success criteria
- Current system state (what's working, gaps)
- Capability areas (vision, voice, nav, compute, personality)
- Development milestones
- Known constraints and risks

**Integration Points**:
- GitHub Copilot: Reference in `.github/copilot-instructions.md`
- Agentic systems: Include in system prompt/context
- Manual development: Read before starting new feature work

### Rule 2: Changes Require Explicit User Approval

**Protected Sections** (HIGHEST scrutiny):
- Executive Summary
- MVP Definition (Core Capabilities)
- Success Criteria
- Development Milestones
- Architecture Overview

**When Changes Are Proposed**:
1. ❌ **DO NOT** make changes automatically
2. ✅ **DO** explain the proposed change clearly
3. ✅ **DO** explain WHY the change is needed
4. ✅ **DO** highlight what will be different
5. ✅ **WAIT** for explicit user approval before editing

**Example Approval Flow**:
```
Agent: "I notice the roadmap doesn't mention [feature X]. Should I add it?"
User: "Yes, add it to Future Work section" ✅
Agent: [Makes change]

--- OR ---

Agent: "User asked about [feature X]. This would change Milestone 2."
Agent: "Proposed change: Add [details]. This affects scope because [reason]."
Agent: "Should I proceed?"
User: "No, that's scope creep" ❌
Agent: [Does NOT make change]
```

**Exception**: Typo fixes, formatting improvements, and factual corrections (e.g., sensor specs) can be made but should be noted.

### Rule 3: Prevent Scope Creep

**Warning Signs** (agents should flag these):
- User request that changes core capabilities
- Feature additions to MVP milestones
- New requirements not in original roadmap
- Timeline pressure leading to shortcuts
- "Just one more thing" syndrome

**Agent Response**:
```
⚠️  SCOPE ALERT: This request would add [X] to MVP scope.
Current MVP: [list 5 core capabilities]
Proposed addition: [describe]
Impact: [timeline/complexity/risk]
Recommendation: Add to Future Work instead?
```

**User Can Override**: But only with explicit acknowledgment of scope change.

### Rule 4: Documentation Alignment

**Requirement**: All active documentation must align with MVP roadmap.

**Documents to Audit** (Priority Order):
1. **CRITICAL** (align first):
   - `README.md` - Project overview
   - `.github/copilot-instructions.md` - Agent instructions
   - `docs/project_overview/roadmap.md` - High-level roadmap
   - `docs/development/recent_work.md` - Current focus
   
2. **HIGH** (align soon):
   - `docs/architecture/mission_agent_vs_executor.md` - Architecture
   - `docs/development/where_we_are_oct13.md` - Status snapshot
   - Package README files in `src/shadowhound_*/`

3. **MEDIUM** (align when touched):
   - `docs/history/project_history_oct_2025.md` - Historical context
   - Other architecture docs
   - Troubleshooting guides

**Alignment Checklist**:
- [ ] Does document refer to "household assistant" instead of "embodied AI platform"?
- [ ] Does document mention VLA as MVP instead of post-MVP?
- [ ] Does document contradict capability definitions?
- [ ] Does document have outdated milestones or priorities?
- [ ] Does document reference deprecated approaches?

---

## Implementation

### For GitHub Copilot

**Action**: Update `.github/copilot-instructions.md` to reference MVP roadmap.

**Add to Agent Instructions**:
```markdown
## CRITICAL: MVP Roadmap Source of Truth

**BEFORE starting significant work**, read the MVP roadmap:
- Location: `docs/project_overview/mvp_embodied_ai_platform.md`
- Purpose: Defines scope, priorities, success criteria
- Protection Policy: `docs/project_overview/MVP_PROTECTION_POLICY.md`

**WHEN proposing changes** to MVP roadmap:
1. Explain proposed change clearly
2. Explain WHY it's needed
3. Highlight impact on scope/milestones
4. WAIT for explicit user approval

**WHEN detecting scope creep**:
- Flag with ⚠️  SCOPE ALERT
- Recommend Future Work instead of MVP
- Let user make final decision
```

### For Codex and Other Agents

**Action**: Include MVP roadmap in system prompt or context.

**Prompt Template**:
```
You are working on ShadowHound, an embodied AI robot platform.

CRITICAL CONTEXT: The MVP roadmap defines project scope and priorities.
- Read: docs/project_overview/mvp_embodied_ai_platform.md
- Policy: docs/project_overview/MVP_PROTECTION_POLICY.md

BEFORE making changes to the roadmap:
1. Propose the change with clear rationale
2. Explain impact on scope/milestones  
3. Wait for explicit user approval

WHEN user requests seem to expand scope:
- Flag as potential scope creep
- Reference current MVP scope
- Suggest Future Work section instead
```

### For Human Developers

**Action**: Add pre-work checklist to development workflow.

**Before Starting New Work**:
- [ ] Read MVP roadmap (or relevant section)
- [ ] Confirm work aligns with current milestone
- [ ] Check if feature is in MVP scope or Future Work
- [ ] Update devlog when work is significant

---

## Alignment Plan

### Phase 1: Critical Documents (Do Now)

**Task**: Audit and align top-priority documents

**Files**:
1. `README.md` - Update project description, goals, MVP reference
2. `.github/copilot-instructions.md` - Add MVP roadmap reference and protection rules
3. `docs/project_overview/roadmap.md` - Ensure consistency with MVP roadmap
4. `docs/development/recent_work.md` - Update to reflect current MVP focus

**Success Criteria**: 
- All 4 files reference MVP roadmap as source of truth
- No contradictions with MVP scope/milestones
- Agents instructed to use and protect roadmap

### Phase 2: Architecture Documents (Next)

**Task**: Ensure architecture docs align with MVP roadmap

**Files**:
1. `docs/architecture/mission_agent_vs_executor.md`
2. `docs/development/where_we_are_oct13.md`
3. Package README files (if they exist)

**Success Criteria**:
- Architecture descriptions match MVP four-layer stack
- Status documents reflect current MVP state
- No references to deprecated approaches

### Phase 3: Historical & Reference (Ongoing)

**Task**: Update as documents are touched

**Files**:
- `docs/history/project_history_oct_2025.md`
- Other docs in `docs/`

**Success Criteria**:
- Historical context preserved but marked as historical
- Forward-looking content aligns with MVP

---

## Approval Process

### For Roadmap Changes

1. **Agent Proposes**:
   ```
   Proposed Change: [describe]
   Reason: [why needed]
   Impact: [scope/timeline/risk]
   Section: [which part of roadmap]
   ```

2. **User Reviews**:
   - ✅ Approve: "Yes, make that change"
   - ❌ Reject: "No, that's scope creep"
   - 🤔 Defer: "Add to Future Work instead"
   - 📝 Revise: "Change it to [revised version]"

3. **Agent Executes**:
   - If approved: Make change, commit with detailed message
   - If rejected: Do NOT make change, note in conversation
   - If deferred: Add to Future Work section
   - If revised: Make revised change

4. **Agent Documents**:
   - Update devlog if significant
   - Reference approval in commit message
   - Note in conversation for context

---

## Maintenance

### Regular Audits

**Frequency**: After each milestone completion

**Process**:
1. Review MVP roadmap for accuracy
2. Check aligned documents for drift
3. Update roadmap if reality changed (with approval)
4. Re-align documents if needed

### Version Control

**Commits to Roadmap**:
- Require detailed commit messages
- Reference user approval in message
- Tag major scope changes: `[SCOPE CHANGE]`

**Example Commit Messages**:
```bash
# Good - shows approval and reason
git commit -m "docs(mvp): add sensor upgrade section

User requested: Document RealSense and 360° camera options
Approved: Add to Future Work (not MVP scope)
Refs: User feedback on hardware evolution"

# Good - shows scope protection
git commit -m "docs(mvp): clarify VLA is post-MVP priority

User feedback: VLA complexity/risk too high for MVP
Approved: Move to Future Work, tackle last
Refs: Scope protection discussion"

# Bad - no context or approval
git commit -m "docs(mvp): add new feature"
```

---

## Emergency Override

**When**: Critical discovery that invalidates part of roadmap

**Examples**:
- Hardware limitation discovered (e.g., Thor cannot run LLM+VLM)
- Major blocker found (e.g., Go2 SDK missing critical feature)
- Safety issue identified (e.g., VLA risk too high)

**Process**:
1. 🚨 Flag as CRITICAL to user immediately
2. Explain what was discovered and why it matters
3. Propose roadmap changes to address
4. Wait for user decision
5. Update roadmap AND all aligned docs

---

## Success Metrics

**How to Know This Policy Works**:

✅ **Agents reference roadmap** before starting work  
✅ **Scope creep attempts** are flagged and discussed  
✅ **Roadmap changes** have approval trail in commits  
✅ **Documentation drift** is caught and corrected  
✅ **Project direction** remains clear and stable  

❌ **Warning Signs** (policy failing):
- Agents making roadmap changes without proposal
- Scope expanding without user awareness
- Documents contradicting each other
- User confused about project direction
- Features added without milestone assignment

---

## Quick Reference

### Agent Checklist

**Starting Work**:
- [ ] Read MVP roadmap for context
- [ ] Confirm alignment with current milestone
- [ ] Check scope (MVP vs Future Work)

**Proposing Roadmap Change**:
- [ ] Explain change clearly
- [ ] Explain WHY needed
- [ ] Show impact on scope/milestones
- [ ] Wait for approval

**Detecting Scope Creep**:
- [ ] Flag with ⚠️  SCOPE ALERT
- [ ] Reference current MVP scope
- [ ] Suggest Future Work alternative
- [ ] Let user decide

---

**Last Updated**: 2025-10-14  
**Owner**: Project Lead (User)  
**Enforcement**: ALL AI agents + human developers  
**Violations**: Result in wasted work and scope confusion - PREVENT!
