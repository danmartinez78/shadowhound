---
name: GitHub Wiki Synchronization Setup
about: Set up automated GitHub Wiki synchronization from docs/ directory
title: 'Set Up GitHub Wiki Synchronization'
labels: ['documentation', 'infrastructure', 'cloud-agent']
assignees: ''
---

## Overview

**Type**: Infrastructure + Documentation  
**Effort**: ~2-3 hours  
**Risk**: Low  
**Priority**: Medium

Enable automated synchronization of the `docs/` directory to the GitHub Wiki, making documentation accessible through multiple surfaces (GitHub Pages, Wiki, Obsidian).

## Context

We have standard Markdown documentation in `docs/` and existing tooling (`tools/wiki_sync.py`) but no active wiki synchronization. The wiki provides an additional surface for users to discover and read documentation.

**Current State**:
- ✅ `tools/wiki_sync.py` exists (converts standard MD → wiki links)
- ✅ `tools/link_convert.py` exists (link conversion utility)
- ✅ Agent instructions mention wiki sync (AGENTS.md)
- ❌ No CI automation set up
- ❌ GitHub Wiki not populated
- ❌ No documentation on wiki sync process

**Goal**: Automatic wiki updates on every push to `dev` that changes `docs/`

## Tasks

### Phase 1: Local Testing (30 min)
- [ ] Test `tools/wiki_sync.py` locally to verify it works
- [ ] Check if GitHub Wiki is enabled for shadowhound repo
- [ ] If wiki doesn't exist, enable it in repo settings
- [ ] Run initial sync: `python tools/wiki_sync.py --remote https://github.com/danmartinez78/shadowhound.wiki.git`
- [ ] Verify wiki content appears correctly
- [ ] Test link conversion (standard MD links → wiki links)
- [ ] Verify Home page is created from `docs/index.md`

### Phase 2: CI Workflow Setup (45 min)
- [ ] Create `.github/workflows/wiki-sync.yml`
- [ ] Configure to trigger on:
  - Push to `dev` branch
  - Changes to `docs/**` paths only
  - Manual workflow dispatch (for testing)
- [ ] Set up GitHub token permissions for wiki push
- [ ] Add status badge to README.md (optional but nice)

### Phase 3: Documentation (30 min)
- [ ] Create `docs/deployment/wiki_sync.md` explaining:
  - What the wiki is and why we use it
  - How synchronization works
  - How to test locally
  - CI workflow details
  - Troubleshooting common issues
- [ ] Update AGENTS.md to reflect actual CI status (not just "CI handles it")
- [ ] Add wiki link to main README.md

### Phase 4: Validation (15 min)
- [ ] Make a test change to `docs/` and push to dev
- [ ] Verify CI workflow runs successfully
- [ ] Verify wiki updates with the change
- [ ] Check that links work in wiki interface
- [ ] Verify images/assets are accessible
- [ ] Test navigation in wiki

## Acceptance Criteria

**Must Have**:
- [x] GitHub Wiki exists and is accessible
- [x] Initial sync populates wiki with all current docs/
- [x] CI workflow runs on docs/ changes
- [x] Links convert correctly (relative MD links → wiki links)
- [x] Home page exists (from docs/index.md)
- [x] Documentation explains wiki sync process
- [x] No broken links in wiki

**Should Have**:
- [x] Images/assets are copied and accessible
- [x] Manual workflow dispatch works (for testing)
- [x] CI workflow logs are clear and helpful

**Nice to Have**:
- [ ] Status badge in README
- [ ] Wiki appears in repo "About" section

## Example CI Workflow

```yaml
name: Sync Wiki

on:
  push:
    branches:
      - dev
    paths:
      - 'docs/**'
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Sync to Wiki
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          python tools/wiki_sync.py \
            --remote https://x-access-token:${GITHUB_TOKEN}@github.com/danmartinez78/shadowhound.wiki.git
```

## Files to Create/Modify

**New Files**:
- `.github/workflows/wiki-sync.yml` - CI automation
- `docs/deployment/wiki_sync.md` - Documentation

**Modified Files**:
- `AGENTS.md` - Update wiki sync status
- `README.md` - Add wiki link (optional)

## Testing Instructions

**Local Testing**:
```bash
# Test wiki sync locally
python tools/wiki_sync.py --remote https://github.com/danmartinez78/shadowhound.wiki.git

# Check the generated wiki/ directory
ls -la wiki/

# Verify links are converted
grep -r "\[.*\](" wiki/ | head -5
```

**CI Testing**:
1. Make a trivial change to a doc in `docs/`
2. Commit and push to dev
3. Check GitHub Actions tab for workflow run
4. Visit wiki and verify change appears

## Notes for Cloud Agent

**Critical**:
- DO test locally before setting up CI
- DO check if wiki already exists before enabling
- DO verify GitHub token has wiki push permissions
- DON'T push to main branch (work in feature branch)
- DON'T break existing docs/ content

**Tips**:
- Start simple: get local sync working first
- The wiki is a separate git repo at `shadowhound.wiki`
- Wiki uses wikilink format, not standard MD links
- `tools/link_convert.py` handles conversion
- Test with a subset of docs before full sync

**If Issues Arise**:
- Check `tools/wiki_sync.py` logs for errors
- Verify GitHub Wiki is enabled in repo settings
- Check CI workflow permissions (needs `contents: write`)
- Look for broken links in conversion

## Success Metrics

- ✅ Wiki is live and accessible
- ✅ CI runs successfully on first test
- ✅ Zero broken links in wiki
- ✅ Documentation is clear and complete
- ✅ Future docs/ updates automatically sync

## References

- Existing tool: `tools/wiki_sync.py`
- Link converter: `tools/link_convert.py`
- Agent instructions: `AGENTS.md` (line 156)
- GitHub Wiki docs: https://docs.github.com/en/communities/documenting-your-project-with-wikis
