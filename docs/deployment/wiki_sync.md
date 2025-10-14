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

1. **Strips YAML front-matter** - Removes metadata blocks from the start of files
2. **Converts links to wiki-style** - Transforms both wikilinks and markdown links to GitHub Wiki format
3. **Copies** the converted documentation to the wiki repository
4. **Commits and pushes** changes to the GitHub Wiki

This ensures the wiki is always up-to-date with the latest documentation without manual intervention.

### Architecture

```
┌─────────────┐
│  docs/      │  Source documentation (Obsidian format)
└──────┬──────┘
       │
       ├─ (Conversion via link_convert.py)
       │  • Strip YAML front-matter
       │  • Convert [[wikilinks]] to wiki-style
       │  • Convert [text](path.md) to wiki-style
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

### Link Conversion Details

The `link_convert.py` tool performs the following transformations:

**YAML Front-matter Stripping**:
```markdown
# Input:
---
tags: [project, overview]
status: draft
summary: >
  Multi-line summary
---

# Content

# Output:
# Content
```

**Wikilink Conversion**:
```markdown
[[simple_page]]           → [simple_page](Simple-Page)
[[docs/path/to/page]]     → [page](Page)
[[page|Custom Label]]     → [Custom Label](Page)
[[page#section]]          → [page § section](Page#section)
```

**Markdown Link Conversion**:
```markdown
[Setup](docs/setup.md)              → [Setup](Setup)
[Config](path/to/config.md)         → [Config](Config)
[Guide](architecture/guide.md)      → [Guide](Guide)
```

**Preserved Links**:
```markdown
[External](https://example.com)     → [External](https://example.com)
[Anchor](#section)                  → [Anchor](#section)
![Image](_assets/diagram.png)       → ![Image](_assets/diagram.png)
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

**Cause**: Links in source docs may use incorrect format or reference non-existent pages.

**Solution**:
1. Test locally with `link_convert.py` to verify conversion
2. Check that source links follow supported formats:
   - Wikilinks: `[[page_name]]` or `[[path/to/page]]`
   - Markdown: `[text](path/to/page.md)`
3. Ensure all linked files exist in `docs/`
4. Review the conversion examples in the Architecture section above

### Issue: YAML front-matter visible in wiki

**Cause**: This issue has been fixed. If you still see YAML, the wiki may need to be re-synced.

**Solution**:
1. Push a change to trigger wiki sync workflow
2. Or manually run: `python tools/wiki_sync.py --docs docs --wiki /tmp/wiki_local --remote "$WIKI_REMOTE"`

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
- **Strips YAML front-matter** from markdown files (lines between `---` markers at file start)
- **Converts links to wiki-style format**:
  - Wikilinks `[[page]]` → `[page](Page)`
  - Markdown links `[text](path/to/page.md)` → `[text](Page)`
  - Uses GitHub Wiki naming convention: Title-Case-With-Hyphens
- Preserves external links (http://, https://)
- Preserves anchor links (#section)
- Preserves image paths (especially `_assets/` directory)
- Preserves non-Markdown files

**Usage**:
```bash
python tools/link_convert.py <input_dir> <output_dir>
```

**Examples**:
```markdown
# Input:
---
tags: [test]
status: draft
---

Link to [Setup](docs/setup.md)
Link to [[config_file]]

# Output:
Link to [Setup](Setup)
Link to [config_file](Config-File)
```

## Validation

After a wiki sync, verify:

- [ ] Wiki is accessible at https://github.com/danmartinez78/shadowhound/wiki
- [ ] Home page displays `docs/index.md` content (without YAML front-matter)
- [ ] Internal links work correctly and point to wiki pages (not .md files)
- [ ] Images and diagrams display (from `_assets/` directory)
- [ ] No YAML metadata visible at the top of pages
- [ ] Recent changes are reflected
- [ ] Workflow logs show successful execution

## References

- [GitHub Wiki Documentation](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AGENTS.md](../../AGENTS.md) - Repository documentation guidelines
- [README.md](../../README.md) - Documentation ecosystem overview
