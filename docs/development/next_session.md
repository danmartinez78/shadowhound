---
tags: [development, planning]
status: active
related:
  - devlog.md
  - ../project_overview/mvp_embodied_ai_platform.md
summary: >
  Next steps for Oct 15 evening session - documentation cleanup continuation.
---

# Next Session: Oct 15, 2025 Evening

## Session Goal
Continue documentation cleanup - complete interactive tasks (project_overview and development dirs).

---

## Context: Where We Left Off (Oct 14 Late Evening)

### Completed Today
- ✅ Established three-tier documentation structure (history/development/legacy)
- ✅ Created history_hub.md explaining pattern (devlog→synthesis→history)
- ✅ Migrated project_history_oct_2025.md to docs/history/ (CLOSED)
- ✅ Updated MVP roadmap with WebRTC blocker details
- ✅ Committed and pushed 12 commits to origin/dev
- ✅ Created cloud agent issues (#22, #23) for mechanical tasks

### Cloud Agent Tasks (Delegated)
- **Issue #22**: Obsidian docs → `docs/tools/obsidian/`
- **Issue #23**: src/ docs → `docs/software/packages/`

Both follow same pattern: consolidate under `docs/`, root README acts as quick reference linking to detailed docs.

### Documentation Pattern Established
```
docs/
├── history/          # Synthesized narratives (closed periods)
├── development/      # Active tracking (devlog ongoing)
├── legacy/          # Raw artifacts (reference only)
├── project_overview/ # Current goals (MVP source of truth)
├── software/        # Software/package docs (after #23)
└── tools/           # Tool documentation (after #22)
```

---

## Next Session Tasks (Interactive - VSCode)

### Priority 1: Clean up docs/project_overview/
**Why Interactive**: Requires judgment on what conflicts with MVP roadmap (source of truth).

**Steps**:
1. List all files: `ls -la docs/project_overview/`
2. For each file:
   - Does it conflict with MVP roadmap?
   - Is it outdated/superseded?
   - Does it duplicate MVP content?
3. Decision per file:
   - **Keep & Align**: Update to align with MVP, remove conflicts
   - **Archive**: Move to `docs/legacy/project_planning/` if historical value
   - **Delete**: Only if truly redundant with no historical value (rare)
4. Update cross-references
5. Commit: `docs(project-overview): align with MVP roadmap`

**Expected Duration**: 30-45 minutes

**Decision Framework**:
- MVP roadmap = source of truth
- Err towards moving to legacy vs deletion
- If in doubt, ask rather than delete

---

### Priority 2: Organize docs/development/
**Why Interactive**: Requires design decisions on subdirectory structure.

**Steps**:
1. List all files: `ls -la docs/development/`
2. Review current files:
   - `devlog.md` (active, stays at root)
   - `recent_work.md` (active, stays at root)
   - Others? (need to check)
3. Identify if subdirs needed:
   - Patterns? (testing/, workflows/, processes/?)
   - Or keep flat for now?
4. Execute reorganization if needed
5. Create `docs/development/README.md` explaining structure
6. Commit: `docs(development): organize development tracking`

**Expected Duration**: 45-60 minutes

**Guiding Principles**:
- Keep active tracking docs at root (devlog, recent_work)
- Group related docs in subdirs if pattern emerges
- Don't over-engineer structure for few files

---

## Priority 3: Verify dimos-unitree Submodule
**Quick Check**: Submodule currently at +3b0122e

**Steps**:
1. Check submodule status: `git submodule status`
2. Check what changed: `cd src/dimos-unitree && git log -1 --oneline`
3. Decision:
   - If intentional (DIMOS docs PR merge): Document in devlog
   - If unintentional: Revert to committed version
   - If unsure: Check with DIMOS maintainer tomorrow

**Expected Duration**: 5-10 minutes

---

## After Interactive Tasks

### Check Cloud Agent Progress
- Review PRs from issues #22 and #23
- Merge if quality looks good
- Request changes if needed

### Update Devlog
After completing tasks above, add entry to `docs/development/devlog.md`:

```markdown
## 2025-10-15 (Tuesday)

### [Evening]: Documentation Cleanup - Interactive Tasks
**Type**: Documentation  
**Status**: ✅ Complete  
**Impact**: Project overview aligned with MVP, development dir organized

**Activities**:
- Cleaned up docs/project_overview/ (X files kept, Y archived)
- Organized docs/development/ structure
- Verified dimos-unitree submodule status

**Commits**: 
- `abc123` - docs(project-overview): align with MVP roadmap
- `def456` - docs(development): organize development tracking

**Files Modified**:
- List key files

**Decisions**:
- Key decisions made during cleanup

**Notes**: Additional context
```

---

## Future Work (Not Tonight)

### Legacy Mining (Task 5)
- Review 41 docs in `docs/legacy/`
- Extract any missed information
- Iterative process, do in batches
- **Do this LAST** after structure is stable

### Package Documentation
- Wait for #23 to complete
- Then review package docs under `docs/software/packages/`
- Ensure consistency and completeness

---

## Quick Commands Reference

```bash
# List files in directory
ls -la docs/project_overview/
ls -la docs/development/

# Check git status
git status

# Submodule status
git submodule status
cd src/dimos-unitree && git log -1 --oneline && cd ../..

# Stage and commit
git add -A
git commit -m "docs(scope): description"

# Push when ready
git push origin dev

# Add devlog entry (helper script)
./scripts/add-devlog-entry.sh
```

---

## Success Criteria for Tonight

- [ ] docs/project_overview/ aligned with MVP (no conflicts)
- [ ] docs/development/ organized logically
- [ ] dimos-unitree submodule status verified/resolved
- [ ] Devlog updated with session activities
- [ ] All changes committed and pushed

---

## Notes

- Remember: Err towards moving to legacy vs deletion
- MVP roadmap is source of truth: `docs/project_overview/mvp_embodied_ai_platform.md`
- Cloud agents handle mechanical tasks (Obsidian, src/ docs)
- We handle judgment calls (what conflicts with MVP?)

---

**Last Updated**: 2025-10-14 23:XX
**Next Session**: 2025-10-15 Evening
