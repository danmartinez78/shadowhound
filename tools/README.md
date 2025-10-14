# Wiki Synchronization Tools

Tools for automatically synchronizing the `docs/` directory to GitHub Wiki.

## Scripts

### `link_convert.py`
Converts standard Markdown links to GitHub Wiki link format.

**Usage:**
```bash
# Display file mappings
python3 link_convert.py docs/

# Test conversion on a specific file
python3 link_convert.py docs/ docs/project.md
```

**Example conversions:**
- `[text](project.md)` → `[[text|project]]`
- `[text](DIMOS_INTEGRATION.md)` → `[[text|DIMOS-INTEGRATION]]`
- `[text](deployment/wiki_sync.md)` → `[[text|Deployment-wiki-sync]]`

### `wiki_sync.py`
Main sync script that clones wiki, converts docs, and pushes changes.

**Usage:**
```bash
# Dry run (recommended first)
python3 wiki_sync.py --dry-run

# Actual sync (requires git credentials)
python3 wiki_sync.py --remote https://github.com/user/repo.wiki.git

# Use default remote (shadowhound)
python3 wiki_sync.py
```

**Features:**
- Clones wiki repository
- Converts all markdown files with proper link format
- Creates `Home.md` from `docs/index.md`
- Copies image assets
- Commits and pushes changes

## CI Integration

The `.github/workflows/wiki-sync.yml` workflow automatically runs `wiki_sync.py` when:
- Changes are pushed to `dev` branch
- Files in `docs/**` are modified

Authentication is handled automatically via `GITHUB_TOKEN`.

## Testing

### Run Dry Run
```bash
cd /path/to/shadowhound
python3 tools/wiki_sync.py --dry-run
```

Expected output:
```
============================================================
GitHub Wiki Sync
============================================================
...
✅ Dry run complete - would sync 7 files and 0 assets
```

### Test Link Conversion
```bash
python3 tools/link_convert.py docs/
```

Should show file mappings like:
```
Found 7 documentation files

File mappings:
  deployment/wiki_sync.md -> Deployment-wiki-sync
  ...
```

## File Naming Convention

| Source File | Wiki Page |
|-------------|-----------|
| `docs/project.md` | `project.md` |
| `docs/DIMOS_INTEGRATION.md` | `DIMOS-INTEGRATION.md` |
| `docs/deployment/wiki_sync.md` | `Deployment-wiki-sync.md` |
| `docs/index.md` | `Home.md` |

Rules:
- Underscores → Hyphens
- Nested files prefixed with parent directory name (titlecased)
- `index.md` always becomes `Home.md`

## Requirements

- Python 3.7+
- Git
- Write access to wiki repository (for actual sync)

## Documentation

See `docs/deployment/wiki_sync.md` for detailed documentation including:
- How the sync works
- Troubleshooting
- Best practices
- Architecture details
