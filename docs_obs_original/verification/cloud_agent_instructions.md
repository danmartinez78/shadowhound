---
tags: [documentation, issue-20, pipeline-reversal]
status: active
related: []
summary: >
  Context and guidance for cloud agent working on Issue #20 pipeline reversal.
---

# Issue #20: Cloud Agent Context & Instructions

**Branch**: `feature/reverse-doc-pipeline`  
**Issue**: https://github.com/danmartinez78/shadowhound/issues/20  
**Status**: Ready for Phase 2 implementation

## Quick Orientation

You're working on reversing the documentation pipeline. Here's what's already done and what you need to do:

### ✅ Phase 1: COMPLETE (Verification)
- Generated standard markdown from wikilinks
- Verified 100% accuracy, no information loss
- Prepared both formats for your reference

### 🎯 Your Mission: Phases 2-6

Build the reverse pipeline so standard markdown becomes the source format, with Obsidian vault generated locally.

## Current Branch Structure

```
feature/reverse-doc-pipeline/
├── docs/                      # 175 markdown files (FINAL FORMAT)
│   ├── architecture/          # Standard markdown links: [text](path.md)
│   ├── development/
│   ├── software/
│   └── ...                    # This is what docs/ should be at the end
│
├── docs_obs_original/         # 175 wikilink files (REFERENCE)
│   ├── architecture/          # Obsidian wikilinks: [[path/file|text]]
│   ├── development/
│   ├── verification/          # Conversion verification reports
│   │   ├── conversion_verification_summary.md
│   │   ├── conversion_detailed_report.md
│   │   ├── conversion_examples.md
│   │   └── converted_structure.txt
│   └── ...                    # This is what docs/ WAS before
│
├── .gitignore                 # Ignores /docs_obs/ (future generated vault)
└── tools/
    └── link_convert.py        # EXISTING: wikilinks → markdown
```

## What You Need to Understand

### The Conversion Pattern

**Study these files to understand the transformation:**

1. **Compare any file pair:**
   ```bash
   diff docs_obs_original/development/submodule_policy.md \
        docs/development/submodule_policy.md
   ```

2. **Read the conversion logic:**
   ```bash
   cat tools/link_convert.py
   ```

3. **Review verification reports:**
   ```bash
   cat docs_obs_original/verification/conversion_verification_summary.md
   cat docs_obs_original/verification/conversion_examples.md
   ```

### Conversion Examples

**Wikilink → Markdown** (what link_convert.py does):
```markdown
# Original (wikilink)
[[development/dimos_policy|DIMOS Policy]]
[[../index|Home]]
[[file#section|Link Text]]

# Converted (markdown)
[DIMOS Policy](../development/dimos_policy.md)
[Home](../index.md)
[Link Text](../file.md#section)
```

**You need to build the REVERSE:**

**Markdown → Wikilink** (what you'll create):
```markdown
# Input (markdown)
[DIMOS Policy](../development/dimos_policy.md)
[Home](../index.md)
[Link Text](../file.md#section)

# Output (wikilink)
[[development/dimos_policy|DIMOS Policy]]
[[../index|Home]]
[[file#section|Link Text]]
```

## Your Implementation Tasks

### Phase 2: Create Reverse Converter (NEW TOOL)

**File to create**: `tools/obsidian_convert.py`

**What it should do:**
1. Convert `[text](path.md)` → `[[path|text]]`
2. Remove `.md` extensions
3. Handle anchors: `path.md#heading` → `path#heading`
4. Skip external URLs (http://, https://)
5. Calculate paths relative to docs root
6. Preserve YAML front-matter

**Test it:**
```bash
python tools/obsidian_convert.py docs docs_obs
# Compare output to docs_obs_original to verify accuracy
```

### Phase 3: Create Vault Generator Script

**File to create**: `scripts/generate_obsidian_vault.sh`

```bash
#!/bin/bash
set -e

echo "🔄 Generating Obsidian vault from standard Markdown..."

# Clean old vault
rm -rf docs_obs

# Convert docs → vault
python tools/obsidian_convert.py docs docs_obs

# Copy Obsidian config
cp -r docs_obs_original/.obsidian docs_obs/.obsidian

echo "✅ Vault generated at docs_obs/"
echo "Open docs_obs in Obsidian to view graph"
```

### Phase 4: Update CI Pipeline

**Files to modify:**
1. `.github/workflows/docs.yml` - Remove `link_convert.py` step
2. `mkdocs.yml` - Change `docs_dir: docs_web` → `docs_dir: docs`

### Phase 5: Update Documentation

**Files to update** (This is where you update the instructions):

1. **AGENTS.md** - Change from:
   - ❌ "Prefer Obsidian-style wikilinks during authoring"
   - ✅ "Use standard markdown links `[text](path.md)` for authoring"
   - ✅ "Generate Obsidian vault locally: `./scripts/generate_obsidian_vault.sh`"

2. **.github/copilot-instructions.md** - Same changes as AGENTS.md in documentation section

3. **docs/obsidian_graph_guide.md** - Update to reference `docs_obs/` location

4. **Add new file**: `docs/development/obsidian_vault_generation.md`
   - How to generate vault locally
   - When to regenerate (after doc edits, on pull)
   - Optional: git hook setup

### Phase 6: Testing & Validation

**Checklist:**
- [ ] `tools/obsidian_convert.py` converts all 175 files
- [ ] Generated vault matches `docs_obs_original` structure
- [ ] Graph view works in Obsidian (open `docs_obs/`)
- [ ] All wikilinks work in generated vault
- [ ] CI pipeline builds successfully
- [ ] GitHub Pages deploys correctly
- [ ] Markdown links work on GitHub.com
- [ ] Instructions updated (AGENTS.md, copilot-instructions.md)

## Critical Success Criteria

### End State Verification

After your work, the branch should have:

```
feature/reverse-doc-pipeline/
├── docs/                      # ✅ Standard markdown (source of truth)
├── docs_obs/                  # ✅ Generated (gitignored, created by script)
├── docs_obs_original/         # ⚠️  Can be deleted after verification
├── tools/
│   ├── link_convert.py        # ✅ Keep (for legacy/reference)
│   └── obsidian_convert.py    # ✅ NEW - your creation
├── scripts/
│   └── generate_obsidian_vault.sh  # ✅ NEW - your creation
└── .github/workflows/docs.yml # ✅ Updated (no more conversion step)
```

### Validation Commands

```bash
# Generate vault
./scripts/generate_obsidian_vault.sh

# Verify it matches original
diff -r docs_obs_original docs_obs | grep -v ".obsidian" | head -50

# Should show only minor differences (both are wikilinks)
# Major content differences = BUG in your converter

# Validate markdown links in docs/
python tools/validate_markdown_links.py --docs docs

# Validate wikilinks in generated vault
python tools/validate_wikilinks.py --docs docs_obs
```

## Common Pitfalls to Avoid

1. **Path calculation**: Account for file depth from docs root
2. **Extension handling**: Remove `.md` from markdown links
3. **Anchor slugification**: Markdown uses slugified anchors, wikilinks don't
4. **External URLs**: Don't convert these!
5. **Label extraction**: `[Custom Text](path)` → `[[path|Custom Text]]`

## Files That Need Front-Matter

All your new files should have YAML front-matter:
```yaml
---
tags: [category, topic]
status: active
related: [related/file]
summary: >
  One-line description.
---
```

Use `snake_case_filenames.md` for all new files.

## Need Help?

1. **Review existing converter**: `tools/link_convert.py`
2. **Check verification reports**: `docs_obs_original/verification/`
3. **Compare file pairs**: See differences between formats
4. **Test incrementally**: Convert one file, verify, then scale

## Final Checklist Before PR

- [ ] All tools created and tested
- [ ] All scripts executable (`chmod +x`)
- [ ] CI pipeline updated and passing
- [ ] Instructions updated (AGENTS.md, copilot-instructions.md)
- [ ] Generated vault works in Obsidian
- [ ] All tests pass
- [ ] No information lost in round-trip conversion

---

**Good luck!** 🚀 The verification shows this is completely feasible. You have both formats to study. The pattern is clear. You've got this!

**Questions?** Check the GitHub issue #20 for more details and discussion.
