---
tags: [development, documentation, proposal]
status: proposed
related: []
summary: >
  Proposal to reverse the documentation pipeline: author in standard Markdown, generate Obsidian vault for visualization.
---

# Documentation Pipeline Reversal Proposal

## Current State (As of 2025-10-12)

### Current Pipeline: Wikilinks → Markdown
```
Author:    docs/ (wikilinks)              ← Edit in VS Code/Obsidian
           ↓ CI: tools/link_convert.py
Output:    docs_web/ (standard markdown)  ← GitHub Pages
           wiki/ (standard markdown)       ← GitHub Wiki
```

**Authoring format:** Obsidian wikilinks `[` `[path/to/file]]` (double brackets)

**Pros:**
- ✅ Obsidian works natively (no local conversion)
- ✅ Graph view works perfectly
- ✅ Clean wikilink syntax
- ✅ 172 files already converted

**Cons:**
- ❌ GitHub repo browsing shows broken wikilinks
- ❌ Source files not "universal" markdown
- ❌ Primary authoring is in VS Code, not Obsidian

## Proposed State: Markdown → Obsidian Vault

### Proposed Pipeline: Markdown → Wikilinks
```
Author:    docs/ (standard markdown)      ← Edit in VS Code, commit this
           ↓ Local: tools/obsidian_convert.py
Vault:     .obsidian_vault/ (wikilinks)   ← Generated, gitignored
           ↓ No CI conversion needed
Output:    docs/ published directly       ← Already standard markdown
```

**Authoring format:** Standard markdown `[text](path/to/file.md)`

## Benefits of Reversal

### 1. Universal Source Format
- ✅ Works on GitHub.com, GitLab, any markdown viewer
- ✅ No broken links when browsing repository
- ✅ Standard markdown = portable, future-proof

### 2. Author-Workflow Alignment
- ✅ Primary authoring in VS Code (current workflow)
- ✅ Obsidian becomes a **visualization tool**, not authoring tool
- ✅ Git diffs show actual markdown changes

### 3. Simplified Publishing
- ✅ No CI conversion needed (docs/ already standard)
- ✅ Faster builds (skip conversion step)
- ✅ One less failure point in pipeline

### 4. Collaboration Friendly
- ✅ Contributors don't need Obsidian
- ✅ Standard markdown is familiar to everyone
- ✅ Works with any markdown linter/formatter

## Implementation Plan

### Phase 1: Build Reverse Converter (1-2 hours)
Create `tools/obsidian_convert.py`:
- Convert `[text](path.md)` → `[` `[path|text]]` (double brackets)
- Convert `![alt](image.png)` → `![` `[image.png]]` (exclaim + double brackets)
- Preserve anchors: `#heading` → `#heading`
- Handle relative paths correctly

### Phase 2: Convert Existing Files (2-3 hours)
```bash
# Bulk convert 172 files
python tools/reverse_convert.py docs docs_temp
mv docs docs_obsidian_backup
mv docs_temp docs
```

Test conversion:
- Run link validation
- Verify GitHub rendering
- Check CI pipeline still works

### Phase 3: Setup Local Workflow (30 mins)
Create `scripts/generate_obsidian_vault.sh`:
```bash
#!/bin/bash
# Generate Obsidian vault from standard markdown
python tools/obsidian_convert.py docs .obsidian_vault
echo "✅ Obsidian vault generated at .obsidian_vault/"
echo "Open .obsidian_vault in Obsidian to view graph"
```

Add to `.gitignore`:
```
/.obsidian_vault/
```

Update `.obsidian/` symlink to point to `.obsidian_vault/.obsidian/`

### Phase 4: Documentation & Workflow (1 hour)
Update `AGENTS.md`:
```markdown
## Authoring Markdown
- Use **standard markdown links**: `[text](path/to/file.md)`
- To view in Obsidian: Run `./scripts/generate_obsidian_vault.sh`
- Graph view available in `.obsidian_vault/` (gitignored)
```

Update `docs/README.md`:
- Remove wikilink warnings
- Add instructions for Obsidian visualization

### Phase 5: Update CI Pipeline (30 mins)
Simplify `.github/workflows/docs.yml`:
```yaml
# Remove this step (no longer needed):
# - name: Convert docs for MkDocs
#   run: python tools/link_convert.py docs docs_web

# Update this step:
- name: Build MkDocs site
  run: mkdocs build --strict
  # mkdocs.yml already points to docs/ (change docs_dir: docs)
```

Update `mkdocs.yml`:
```yaml
docs_dir: docs  # Changed from docs_web
```

## Migration Checklist

- [ ] Create `tools/obsidian_convert.py` (markdown → wikilinks)
- [ ] Test converter on sample files
- [ ] Backup current `docs/` to `docs_obsidian_backup/`
- [ ] Run bulk conversion: `tools/reverse_convert.py`
- [ ] Validate all links work on GitHub
- [ ] Update `.gitignore` to exclude `.obsidian_vault/`
- [ ] Create `scripts/generate_obsidian_vault.sh`
- [ ] Update `AGENTS.md` authoring guidelines
- [ ] Update `docs/README.md` documentation
- [ ] Simplify CI pipeline (remove conversion step)
- [ ] Update `mkdocs.yml` to use `docs/` directly
- [ ] Test full CI pipeline on test branch
- [ ] Verify GitHub Pages still builds correctly
- [ ] Verify GitHub Wiki sync still works
- [ ] Generate Obsidian vault and verify graph view
- [ ] Document new workflow for team
- [ ] Merge to main

## Rollback Plan

If issues arise:
```bash
# Restore original wikilinks
mv docs docs_markdown_backup
mv docs_obsidian_backup docs
git checkout main -- .github/workflows/docs.yml mkdocs.yml
```

## Estimated Effort

- **Development:** 4-6 hours
- **Testing:** 2-3 hours
- **Documentation:** 1-2 hours
- **Total:** ~1 day of focused work

## Success Criteria

- ✅ All links work on GitHub.com repo browsing
- ✅ GitHub Pages builds successfully
- ✅ GitHub Wiki syncs correctly
- ✅ Running `./scripts/generate_obsidian_vault.sh` creates working Obsidian vault
- ✅ Graph view shows all connections correctly
- ✅ CI pipeline simpler (one less step)
- ✅ Team can author without Obsidian installed

## Open Questions

1. **Front-matter handling:** Keep YAML as-is or convert to Obsidian format?
2. **Image paths:** Keep relative or convert to Obsidian embeds?
3. **Frequency:** Regenerate vault on every commit (hook) or manually?
4. **Obsidian config:** Commit `.obsidian_vault/.obsidian/` settings or let users configure?

## References

- Current converter: `tools/link_convert.py`
- Wikilink validator: `tools/validate_wikilinks.py`
- CI pipeline: `.github/workflows/docs.yml`
- Authoring guide: `AGENTS.md`

## Next Steps

1. Create feature branch: `git checkout -b feature/reverse-doc-pipeline`
2. Implement `tools/obsidian_convert.py`
3. Test on subset of files
4. Proceed with migration checklist

---

**Status:** Proposed (2025-10-12)  
**Branch:** Feature branch to be created  
**Blocked by:** None  
**Depends on:** Current docs/wiki-and-cleanup merge
