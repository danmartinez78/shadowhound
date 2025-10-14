---
tags: [project_overview, cleanup, tracking]
status: active
related: [mvp_embodied_ai_platform.md]
summary: >
  Tracking document for project_overview cleanup session (Oct 14, 2025)
---

# Project Overview Cleanup Tracking

**Date**: 2025-10-14  
**Branch**: feature/project-overview-cleanup  
**Purpose**: Track all changes during project_overview directory cleanup to ensure MVP protection

---

## MVP Modification Policy

**CRITICAL**: MVP doc (`mvp_embodied_ai_platform.md`) is SOURCE OF TRUTH per `MVP_PROTECTION_POLICY.md`

**Rules**:
1. ✅ **Additions allowed**: Enhance without changing core content
2. ❌ **Removals forbidden**: Unless explicitly justified and approved
3. ❌ **Modifications forbidden**: Unless explicitly justified and approved
4. ✅ **Clear rationale required**: For any removal/modification at end of cleanup

---

## Changes Made to MVP Doc

### Change 1: Added Testing Infrastructure to Milestone 1
**Type**: ADDITION ONLY  
**Location**: Milestone 1, after existing checklist items  
**Rationale**: Testing infrastructure is essential for MVP but wasn't explicitly documented  
**Content Added**:
```markdown
#### Testing Infrastructure Setup
- [ ] Configure pytest with fixtures and test utilities
- [ ] Implement mock robot interface for unit testing
- [ ] Set up CI pipeline (GitHub Actions):
  - [ ] Run tests on every PR
  - [ ] Code quality checks (black, flake8, mypy)
  - [ ] Test coverage reporting (target: >80%)
- [ ] Document testing patterns and best practices
```
**Existing Content Modified**: NONE  
**Existing Content Removed**: NONE

---

### Change 2: Added Skills Definition Tasks to Milestone 1
**Type**: ADDITION ONLY  
**Location**: Milestone 1, after vision stack items  
**Rationale**: Skills audit needed but shouldn't prescribe specific skills in MVP  
**Content Added**:
```markdown
- [ ] Define minimal skill set needed for MVP missions (see [Skills Inventory](../software/skills_inventory.md))
- [ ] Audit DIMOS MyUnitreeSkills to identify working vs WebRTC-blocked skills
- [ ] Decide on skill implementation approach (DIMOS native vs custom wrapper)
```
**Existing Content Modified**: NONE  
**Existing Content Removed**: NONE

---

### Change 3: Enhanced Success Metrics for Milestone 5
**Type**: ADDITION ONLY (enhanced existing bullet)  
**Location**: Milestone 5, last checklist item  
**Rationale**: More specific metrics make validation clearer  
**Content Before**:
```markdown
- [ ] **Success Metric**: 3 complex missions succeed end-to-end
```
**Content After**:
```markdown
- [ ] **Success Metrics**:
  - 3 complex missions succeed end-to-end
  - >90% mission success rate in controlled environment (20 test runs)
  - <5s average response time for multi-step commands
  - No safety incidents during validation testing
```
**Existing Content Modified**: Changed "Success Metric" (singular) to "Success Metrics" (plural) and expanded bullet  
**Existing Content Removed**: NONE (original metric preserved as first sub-bullet)  
**Justification**: Enhancement only, original success criterion preserved

---

### Change 4: Added Action Items & TODOs Section
**Type**: ADDITION ONLY (new section)  
**Location**: After "Open Questions & Decisions Needed", before "Resources & References"  
**Rationale**: Capture research items without premature commitments  
**Content Added**:
```markdown
## Action Items & TODOs

### Research & Investigation
- [ ] Review DIMOS skill extension patterns and decide implementation approach
- [ ] Determine appropriate task types for cloud agent collaboration (based on experience)
- [ ] Document cloud agent collaboration strategy when patterns are validated

### Documentation
- [ ] Complete skills inventory audit (working vs non-working DIMOS skills)
- [ ] Create testing infrastructure documentation when setup complete
```
**Existing Content Modified**: NONE  
**Existing Content Removed**: NONE

---

## Files Created

### 1. docs/software/skills_inventory.md
**Type**: NEW FILE  
**Purpose**: Document DIMOS skills state (working vs blocked) and candidate skills  
**Rationale**: Keep skill details out of MVP roadmap since we haven't validated minimal set  
**Content**:
- Current state (WebRTC blocker, working vs non-working skills)
- Candidate skills from planning (not commitments)
- Research needed (DIMOS skill extension patterns)
- Next steps (audit, test, define minimal set)

---

### 2. docs/legacy/roadmap_skills_first_oct13.md
**Type**: ARCHIVED FILE (moved from project_overview/)  
**Source**: docs/project_overview/roadmap.md (copied then modified)  
**Purpose**: Preserve skills-first implementation strategy as historical artifact  
**Modifications**:
- Added archive header with status, date, reason, historical value
- Added "ARCHIVED" warning at top
- Added historical context explaining skills-first approach
- Added note about valuable preserved content
- Original content fully preserved below header

---

### 3. docs/project_overview/CLEANUP_TRACKING.md
**Type**: NEW FILE (this document)  
**Purpose**: Track all changes during cleanup to ensure MVP protection  
**Content**: Complete audit trail of all file moves, modifications, and rationale

---

## Files Modified

### 1. docs/project_overview/mvp_embodied_ai_platform.md
**Modifications**: 5 additions (4 planned + 1 from todo.md)  
**Removals**: NONE  
**Core Content Changed**: NONE (only enhancements)

**Changes**:
1. Testing infrastructure section added to Milestone 1
2. Skills definition tasks added to Milestone 1
3. Success metrics enhanced in Milestone 5
4. Action Items & TODOs section added
5. Video walkthrough added to Documentation TODOs (from old todo.md)

**Verification**: 31 insertions(+), 1 deletion(-) - the 1 deletion is "Metric" → "Metrics" enhancement

---

### 2. docs/architecture/architecture_review_summary.md
**Modifications**: Added system architecture diagram
**Rationale**: Project_overview version had image reference, added to authoritative architecture version
**Change**: Added `![System Architecture](../_assets/system-architecture.png)` with caption

---

## Files Moved (Not Modified)

### To docs/software/agent/
1. `agent_quick_reference.md` → `agent_types_comparison.md`
   - **Rationale**: Technical operational guide belongs in software docs, not project overview
   - **Modification**: Fixed ASCII art formatting (wrapped in code block)

### To docs/development/
2. `quick_reference.md` → `command_reference.md`
   - **Rationale**: Command cheatsheet is development/operations content

### To docs/deployment/
3. `quick_start.md` → `launch_checklist.md`
   - **Rationale**: Launch procedures are deployment operations

### To docs/history/
4. `setup_status.md` → `setup_status_oct04_2025.md`
   - **Rationale**: Point-in-time status (Oct 4) superseded by status_analysis_2025_10.md
5. `status_2025-10-12.md` → `status_2025-10-12.md`
   - **Rationale**: Point-in-time status update, historical value only
6. `todo.md` → `todo_pre_mvp_oct2025.md`
   - **Rationale**: Pre-MVP task list superseded by MVP milestones
   - **Preserved**: Video walkthrough item added to MVP documentation TODOs

---

## Files Removed (Duplicates)

### 1. docs/project_overview/architecture_review_summary.md
**Action**: REMOVED (git rm)  
**Rationale**: Duplicate of docs/architecture/architecture_review_summary.md  
**Issues**: 
- Corrupted YAML front-matter
- 81 lines vs 209 lines in architecture version
- Architecture version is authoritative and more complete
**Preservation**: System architecture image reference migrated to architecture version

---

## Summary Statistics

**Before Cleanup**: 14 files in docs/project_overview/  
**After Cleanup**: 7 files in docs/project_overview/ (50% reduction)

**Files Kept**: 6 + tracking doc  
**Files Moved**: 6 (to appropriate directories)  
**Files Archived**: 2 (legacy/ and history/)  
**Files Removed**: 1 (duplicate)  
**Files Created**: 2 (skills_inventory.md + this tracking doc)

**Total Git Operations**:
- `git mv`: 7 files relocated
- `git rm`: 2 files removed (roadmap.md from project_overview, architecture duplicate)
- New files: 3 (skills_inventory.md, legacy/roadmap, CLEANUP_TRACKING.md)
- Modified: 2 (mvp_embodied_ai_platform.md, architecture/architecture_review_summary.md)

---

---

## Files Pending Review

### ✅ All Files Reviewed and Processed!

**Original 14 files** → **Final 7 files** (50% reduction)

### Files Kept in project_overview/ (6 + tracking doc)
1. ✅ `mvp_embodied_ai_platform.md` - **SOURCE OF TRUTH** roadmap
2. ✅ `MVP_PROTECTION_POLICY.md` - Critical scope protection policy
3. ✅ `ideas_backlog.md` - Future ideas and enhancements
4. ✅ `ideas_integration_summary.md` - Ideas integration planning history
5. ✅ `status_analysis_2025_10.md` - Current state assessment (Oct 13)
6. ✅ `project_overview_hub.md` - Directory index (needs update after cleanup)
7. ✅ `CLEANUP_TRACKING.md` - This tracking document

### Files Moved to Appropriate Directories (7)
1. ✅ `agent_quick_reference.md` → `docs/software/agent/agent_types_comparison.md` (technical reference)
2. ✅ `quick_reference.md` → `docs/development/command_reference.md` (operational commands)
3. ✅ `quick_start.md` → `docs/deployment/launch_checklist.md` (deployment guide)
4. ✅ `setup_status.md` → `docs/history/setup_status_oct04_2025.md` (point-in-time status)
5. ✅ `status_2025-10-12.md` → `docs/history/status_2025-10-12.md` (point-in-time status)
6. ✅ `architecture_review_summary.md` → **REMOVED** (duplicate, authoritative version in docs/architecture/)
7. ✅ `todo.md` → `docs/history/todo_pre_mvp_oct2025.md` (pre-MVP task list)

### Files Archived to legacy/ (1)
1. ✅ `roadmap.md` → `docs/legacy/roadmap_skills_first_oct13.md` (historical approach preserved)

---

## Next Steps

1. Review remaining 7 files (one by one with user)
2. Update `project_overview_hub.md` after all decisions
3. Remove original `roadmap.md` from project_overview/ (already archived)
4. Final review: Verify NO unauthorized MVP changes
5. Commit with clear message documenting changes
6. Create PR to dev

---

## Final Pre-Commit Checklist

Before committing to feature branch:
- [ ] Verify MVP doc has ONLY the 4 documented additions
- [ ] Verify NO removals from MVP doc
- [ ] Verify NO modifications to existing MVP content (except documented enhancement)
- [ ] Verify all changes have clear rationale documented in this file
- [ ] Review diff to confirm additions-only policy

Before merging to dev:
- [ ] Second review of all MVP changes
- [ ] Confirm all modifications justified and approved
- [ ] Update project_overview_hub.md with new structure
- [ ] Test all internal links work correctly
