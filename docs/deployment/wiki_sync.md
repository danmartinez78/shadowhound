# Wiki Synchronization

This document explains how the GitHub Wiki synchronization system works for ShadowHound documentation.

## Overview

The ShadowHound documentation in the `docs/` directory is automatically synchronized to the [GitHub Wiki](https://github.com/danmartinez78/shadowhound/wiki) whenever changes are pushed to the `dev` branch.

### Key Features

- **Automatic sync**: CI workflow runs on every push to `dev` that modifies `docs/**`
- **Link conversion**: Standard Markdown links are automatically converted to wiki link format
- **Home page**: `docs/index.md` becomes the wiki Home page
- **Asset support**: Images and other assets are copied to the wiki

## How It Works

### 1. Link Conversion (`tools/link_convert.py`)

GitHub Wiki uses a special link format. The link converter handles this automatically:

**Standard Markdown** (in docs/):
```markdown
[See the project docs](project.md)
[Check DIMOS integration](DIMOS_INTEGRATION.md)
```

**Wiki Format** (converted):
```markdown
[[See the project docs|project]]
[[Check DIMOS integration|DIMOS-INTEGRATION]]
```

### 2. Wiki Sync (`tools/wiki_sync.py`)

The main sync script:
1. Clones the wiki repository (https://github.com/danmartinez78/shadowhound.wiki.git)
2. Converts all markdown files using link converter
3. Copies files with wiki-appropriate names
4. Creates `Home.md` from `docs/index.md`
5. Commits and pushes changes

### 3. CI Workflow (`.github/workflows/wiki-sync.yml`)

Triggered on:
- Push to `dev` branch
- Changes to `docs/**` files
- Manual workflow dispatch

The workflow:
- Checks out the repository
- Sets up Python 3.11
- Runs `wiki_sync.py` with authentication
- Reports success/failure

## Testing Locally

### Dry Run (Recommended First)

Test without actually pushing to wiki:

```bash
cd /path/to/shadowhound
python3 tools/wiki_sync.py --dry-run
```

This shows what would be synced without making changes.

### Test Link Conversion

Check how links will be converted:

```bash
python3 tools/link_convert.py docs/
```

This displays file mappings and can test conversion on specific files:

```bash
python3 tools/link_convert.py docs/ docs/project.md
```

### Full Local Sync

**⚠️ Warning**: This will actually push to the wiki!

```bash
# Make sure you have push access to the wiki
python3 tools/wiki_sync.py --remote https://github.com/danmartinez78/shadowhound.wiki.git
```

You'll need:
- Git configured with your credentials
- Push access to the shadowhound repository

## Workflow Details

### File Naming Convention

Files are converted to wiki page names following this pattern:

| File Path | Wiki Page Name |
|-----------|---------------|
| `docs/project.md` | `project.md` |
| `docs/DIMOS_INTEGRATION.md` | `DIMOS-INTEGRATION.md` |
| `docs/deployment/wiki_sync.md` | `Deployment-Wiki-Sync.md` |
| `docs/index.md` | `Home.md` |

Rules:
- Underscores (`_`) → Hyphens (`-`)
- Nested files include parent directory name
- `index.md` always becomes `Home.md`

### Authentication in CI

The workflow uses `secrets.GITHUB_TOKEN` which is automatically provided by GitHub Actions. This token has:
- Read access to the repository
- Write access to the wiki

No additional secrets configuration is needed!

### Supported File Types

**Markdown files** (`.md`):
- Converted and synced with link conversion
- Becomes wiki pages

**Asset files**:
- `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.pdf`
- Copied as-is to wiki
- Relative paths preserved

**Ignored files**:
- `COLCON_IGNORE`
- `README.md` (in docs/)

## Troubleshooting

### Wiki Not Enabled

**Problem**: CI fails with "Failed to clone wiki"

**Solution**:
1. Go to repository Settings
2. Enable "Wikis" feature
3. Create initial wiki page (GitHub will initialize the wiki repo)
4. Re-run the workflow

### Link Conversion Issues

**Problem**: Links in wiki point to wrong pages

**Solution**:
1. Check file naming matches convention (underscores → hyphens)
2. Test locally: `python3 tools/link_convert.py docs/ docs/yourfile.md`
3. Verify file mappings in dry-run output

### CI Workflow Not Triggering

**Problem**: Push to dev doesn't trigger sync

**Solution**:
1. Check that files in `docs/**` were modified
2. Verify you're pushing to `dev` branch (not `main`)
3. Check workflow file is in `.github/workflows/wiki-sync.yml`

### Authentication Failures

**Problem**: "Permission denied" or "403 Forbidden"

**Solution**:
1. Verify wiki is enabled in repository settings
2. Check that `GITHUB_TOKEN` has wiki permissions
3. For local testing, ensure git credentials are configured

## Manual Workflow Trigger

You can manually trigger the sync without pushing to dev:

1. Go to repository → Actions
2. Select "Sync Wiki" workflow
3. Click "Run workflow"
4. Choose branch and run

This is useful for:
- Testing the workflow
- Re-syncing after manual wiki edits
- Initial wiki population

## Making Changes

### Adding New Documentation

1. Add markdown file to `docs/` directory
2. Use standard markdown links: `[text](path/to/file.md)`
3. Commit and push to `dev` branch
4. CI automatically syncs to wiki

### Updating Existing Docs

1. Edit files in `docs/` directory
2. Don't worry about wiki link format - it's automatic
3. Commit and push to `dev`
4. CI syncs changes within minutes

### Adding Images

1. Place images in `docs/` or subdirectories
2. Reference with relative paths: `![alt text](image.png)`
3. Images will be copied to wiki automatically

## Best Practices

### ✅ Do's

- **Write in standard markdown**: Use normal `[text](file.md)` links
- **Use relative paths**: For images and links within docs
- **Test locally**: Run dry-run before pushing major changes
- **Keep docs organized**: Use subdirectories for different topics
- **Update index.md**: Keep the home page current

### ❌ Don'ts

- **Don't edit wiki directly**: Changes will be overwritten on next sync
- **Don't use absolute paths**: For internal links
- **Don't use special characters**: In filenames (stick to alphanumeric, hyphens, underscores)
- **Don't commit generated files**: Wiki pages are generated, not source

## Architecture

### Components

```
docs/               → Source documentation
tools/
  ├── link_convert.py   → Link format converter
  └── wiki_sync.py      → Main sync script
.github/workflows/
  └── wiki-sync.yml     → CI workflow
```

### Workflow Diagram

```
Push to dev (docs/*)
        ↓
    CI Triggered
        ↓
    Checkout repo
        ↓
    Setup Python
        ↓
  Run wiki_sync.py
        ↓
  Clone wiki repo
        ↓
Convert & copy files
        ↓
 Commit & push wiki
        ↓
      Done ✅
```

## Future Enhancements

Potential improvements:
- [ ] Incremental sync (only changed files)
- [ ] Wiki → docs reverse sync (for wiki-first edits)
- [ ] Automatic table of contents generation
- [ ] Markdown linting before sync
- [ ] Wiki page analytics integration
- [ ] Support for custom link mapping rules

## Related Documentation

- [GitHub Wiki Documentation](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Python Markdown Processing](https://python-markdown.github.io/)

---

**Questions?** Open an issue or check the [main documentation](../project.md).
