# GitHub Wiki Setup Guide

Quick guide to enable and test the GitHub Wiki synchronization.

## Initial Setup

### 1. Enable GitHub Wiki

1. Go to repository settings: https://github.com/danmartinez78/shadowhound/settings
2. Scroll down to "Features" section
3. Check the "Wikis" checkbox
4. Save settings

### 2. Initialize the Wiki

GitHub needs at least one page to create the wiki repository. You have two options:

**Option A: Create via Web UI**
1. Go to the Wiki tab: https://github.com/danmartinez78/shadowhound/wiki
2. Click "Create the first page"
3. Add any content (e.g., "Initializing wiki...")
4. Click "Save page"

**Option B: Manual Initial Sync**
```bash
# Clone the repository
git clone https://github.com/danmartinez78/shadowhound.git
cd shadowhound

# Run initial sync (requires git credentials with wiki push access)
python3 tools/wiki_sync.py --remote https://github.com/danmartinez78/shadowhound.wiki.git
```

### 3. Verify Setup

After initialization, the wiki should be accessible at:
https://github.com/danmartinez78/shadowhound/wiki

You should see:
- **Home** page (from `docs/index.md`)
- **project** page (from `docs/project.md`)
- **DIMOS-INTEGRATION** page
- **DIMOS-CAPABILITIES** page
- **ARCH-UPDATE-SUMMARY** page
- **Deployment-wiki-sync** page

## Testing CI Workflow

### Test 1: Manual Workflow Trigger

1. Go to Actions tab: https://github.com/danmartinez78/shadowhound/actions
2. Select "Sync Wiki" workflow
3. Click "Run workflow"
4. Select branch `dev` (or the branch with the workflow)
5. Click "Run workflow"
6. Wait for completion (should take ~30 seconds)
7. Check wiki to verify changes

### Test 2: Automatic Trigger on Push

1. Make a change to any file in `docs/`
   ```bash
   cd shadowhound
   echo "\n## New Section" >> docs/project.md
   git add docs/project.md
   git commit -m "Test wiki sync"
   git push origin dev
   ```

2. Go to Actions tab: https://github.com/danmartinez78/shadowhound/actions
3. Verify "Sync Wiki" workflow is running
4. Wait for completion
5. Check wiki to see the change

### Test 3: Link Conversion

1. Add a link to `docs/index.md`:
   ```markdown
   [See Project Details](project.md)
   ```

2. Commit and push to dev:
   ```bash
   git add docs/index.md
   git commit -m "Test wiki link conversion"
   git push origin dev
   ```

3. After workflow completes, check the wiki Home page
4. The link should be converted to wiki format: `[[See Project Details|project]]`
5. Click the link - it should work!

## Troubleshooting

### Wiki Not Found Error

**Symptom**: CI fails with "Failed to clone wiki"

**Solution**: 
- Make sure wiki is enabled in repository settings
- Initialize wiki by creating at least one page (see step 2 above)
- Wait a few minutes after enabling before running CI

### Permission Denied

**Symptom**: CI fails with "permission denied" or "403 Forbidden"

**Solution**:
- Verify `GITHUB_TOKEN` has wiki permissions (it should by default)
- Check that the workflow is running from a branch in the main repository (not a fork)
- For local testing, ensure you have push access to the repository

### Links Not Working in Wiki

**Symptom**: Links in wiki pages don't work or return 404

**Solution**:
- Check that the target file exists in `docs/`
- Verify file naming follows convention (underscores → hyphens)
- Run `python3 tools/link_convert.py docs/` to check mappings
- Links should use wiki format: `[[Text|Page-Name]]`

### Workflow Not Triggering

**Symptom**: Push to dev doesn't trigger wiki sync

**Solution**:
- Verify you're pushing to `dev` branch (not `main` or other branch)
- Ensure changes are in `docs/**` directory
- Check workflow file exists: `.github/workflows/wiki-sync.yml`
- Try manual trigger to verify workflow works

## Verification Checklist

After setup, verify:

- [ ] Wiki is enabled in repository settings
- [ ] Can access wiki at https://github.com/danmartinez78/shadowhound/wiki
- [ ] Home page exists and displays content from `docs/index.md`
- [ ] All doc pages are present (project, DIMOS-INTEGRATION, etc.)
- [ ] Links in wiki pages work correctly
- [ ] CI workflow appears in Actions tab
- [ ] Manual workflow trigger works
- [ ] Automatic trigger on push to dev works
- [ ] Link conversion works (standard MD → wiki format)

## Next Steps

Once wiki is working:

1. **Document in README**: ✅ Already done - wiki link added
2. **Update AGENTS.md**: If it exists, update to reflect wiki CI status
3. **Add to Development Docs**: Consider adding wiki link to developer onboarding
4. **Monitor CI**: Keep an eye on workflow runs for any issues

## Local Development

For local testing without pushing to wiki:

```bash
# Dry run - shows what would be synced
python3 tools/wiki_sync.py --dry-run

# Test link conversion
python3 tools/link_convert.py docs/

# Run tests
python3 tools/test_wiki_sync.py
```

## Additional Resources

- **Wiki Sync Documentation**: `docs/deployment/wiki_sync.md`
- **Tools README**: `tools/README.md`
- **GitHub Wiki Docs**: https://docs.github.com/en/communities/documenting-your-project-with-wikis
- **GitHub Actions Docs**: https://docs.github.com/en/actions

---

**Questions?** Open an issue or check the documentation in `docs/deployment/wiki_sync.md`.
