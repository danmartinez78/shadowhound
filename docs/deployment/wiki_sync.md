---
tags: [deployment, documentation, automation]
status: complete
related: []
summary: >
  How GitHub Wiki synchronization works in the ShadowHound project.
---

# GitHub Wiki Synchronization

## Purpose

This document explains how the ShadowHound documentation is automatically synchronized from the `/docs` directory to the GitHub Wiki, enabling multiple surfaces for documentation access while maintaining a single source of truth.

## Prerequisites

- Understanding of GitHub Actions workflows
- Basic knowledge of Git and GitHub Wiki
- Python 3.11+ for local testing

## How Wiki Sync Works

### Overview

ShadowHound maintains documentation as standard Markdown files in the `/docs` directory. When changes are pushed to the `dev` or `main` branches, a GitHub Actions workflow automatically:

1. **Converts** Obsidian wikilinks to standard Markdown links
2. **Copies** the converted documentation to the wiki repository
3. **Commits and pushes** changes to the GitHub Wiki

This ensures the wiki is always up-to-date with the latest documentation without manual intervention.

### Architecture

```
┌─────────────┐
│  docs/      │  Source documentation (Obsidian format)
└──────┬──────┘
       │
       ├─ (Conversion via link_convert.py)
       ↓
┌─────────────┐
│  wiki/      │  Temporary local wiki repo
└──────┬──────┘
       │
       ├─ (Push via git)
       ↓
┌─────────────┐
│ GitHub Wiki │  Published wiki (user-facing)
└─────────────┘
```

### Trigger Conditions

The wiki sync workflow (`wiki-sync.yml`) runs when:
- A push is made to the `dev` branch
- Changes are made to files in the `docs/**` path

The main documentation workflow (`docs.yml`) also syncs the wiki when:
- A push is made to the `main` branch
- Changes are made to documentation files

## Testing Locally

### Test Link Conversion

Convert wikilinks to standard Markdown format:

```bash
# From repository root
python tools/link_convert.py docs /tmp/wiki_test

# Verify output
ls /tmp/wiki_test/
cat /tmp/wiki_test/index.md  # Should be renamed to Home.md in wiki
```

### Test Full Wiki Sync

To test the complete sync process locally:

```bash
# Set the wiki remote URL
export WIKI_REMOTE="https://github.com/danmartinez78/shadowhound.wiki.git"

# Run the sync (this will NOT push unless you have write access)
python tools/wiki_sync.py --docs docs --wiki /tmp/wiki_local --remote "$WIKI_REMOTE"

# Check the local wiki repository
ls /tmp/wiki_local/
git -C /tmp/wiki_local log -1
```

**Note**: Local testing will clone the wiki but won't push changes unless you have write permissions and explicitly configure authentication.

## CI Workflow Operations

### Workflow File: `.github/workflows/wiki-sync.yml`

The workflow performs these steps:

1. **Checkout**: Clones the main repository with full history
2. **Setup Python**: Installs Python 3.11
3. **Configure Git**: Sets up bot user credentials for commits
4. **Sync Wiki**: Runs `tools/wiki_sync.py` with the wiki remote URL

### Authentication

The workflow uses `GITHUB_TOKEN` secret which is automatically provided by GitHub Actions. This token has permissions to:
- Read the main repository
- Clone and push to the wiki repository

### Workflow Logs

To view workflow execution:

1. Go to [Actions tab](https://github.com/danmartinez78/shadowhound/actions)
2. Click on "Sync Wiki" workflow
3. Select a specific run to view logs

## Troubleshooting Common Issues

### Issue: Wiki sync workflow fails with "permission denied"

**Cause**: The `GITHUB_TOKEN` doesn't have wiki write permissions.

**Solution**: 
1. Ensure the Wiki feature is enabled in repository settings
2. Check workflow permissions in `.github/workflows/wiki-sync.yml`
3. Verify `permissions: contents: write` is set

### Issue: Links broken in wiki after sync

**Cause**: Wikilink conversion may have issues with complex paths.

**Solution**:
1. Test locally with `link_convert.py` to verify conversion
2. Check if source links use proper relative paths
3. Ensure all linked files exist in `docs/`

### Issue: Images not showing in wiki

**Cause**: Image paths may not be correct after conversion.

**Solution**:
1. Ensure images are in `docs/_assets/` directory
2. Use relative paths: `![image](_assets/image.png)`
3. Test conversion locally to verify image paths

### Issue: Home page not created

**Cause**: The `docs/index.md` file may be missing or not copied.

**Solution**:
1. Verify `docs/index.md` exists
2. Check that `wiki_sync.py` copies `index.md` to `Home.md`
3. Look at line 66-67 in `tools/wiki_sync.py`:
```python
if home_src.exists() and not home_dest.exists():
    shutil.copy2(home_src, home_dest)
```

### Issue: Workflow not triggering

**Cause**: Changes may not be in the `docs/**` path.

**Solution**:
1. Verify changes are in files under `docs/` directory
2. Check workflow trigger in `.github/workflows/wiki-sync.yml`:
```yaml
on:
  push:
    branches: [dev]
    paths:
      - 'docs/**'
```

## Key Tools

### `tools/wiki_sync.py`

Main synchronization script that:
- Clones or initializes the wiki repository
- Converts documentation using `link_convert.py`
- Stages converted files in the wiki repository
- Commits and pushes changes

**Usage**:
```bash
python tools/wiki_sync.py --docs <source> --wiki <local_path> --remote <url>
```

**Parameters**:
- `--docs`: Source documentation directory (default: `docs`)
- `--wiki`: Local wiki repository path (default: `wiki`)
- `--remote`: Git remote URL for the wiki (required)

### `tools/link_convert.py`

Link conversion utility that:
- Converts Obsidian wikilinks (`[[target]]`) to Markdown links (`[target](target.md)`)
- Handles embeds and images
- Preserves assets and non-Markdown files
- Adjusts relative paths based on file depth

**Usage**:
```bash
python tools/link_convert.py <input_dir> <output_dir>
```

## Validation

After a wiki sync, verify:

- [ ] Wiki is accessible at https://github.com/danmartinez78/shadowhound/wiki
- [ ] Home page displays `docs/index.md` content
- [ ] Internal links work correctly
- [ ] Images and diagrams display
- [ ] Recent changes are reflected
- [ ] Workflow logs show successful execution

## References

- [GitHub Wiki Documentation](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AGENTS.md](../../AGENTS.md) - Repository documentation guidelines
- [README.md](../../README.md) - Documentation ecosystem overview
