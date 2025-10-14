#!/usr/bin/env python3
"""
Synchronize docs/ directory to GitHub Wiki.

This script:
1. Clones the wiki repository
2. Converts markdown files from docs/ to wiki format
3. Converts links to wiki link format
4. Copies files to wiki repo
5. Commits and pushes changes

Usage:
    python wiki_sync.py --remote <wiki_git_url>
    python wiki_sync.py --remote https://github.com/user/repo.wiki.git
    python wiki_sync.py --dry-run  # Test without pushing
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Import link conversion utilities
from link_convert import convert_file, get_file_mappings, path_to_wiki_name


def run_command(cmd, cwd=None, check=True):
    """Run a shell command and return output."""
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(
        cmd,
        cwd=cwd,
        check=check,
        capture_output=True,
        text=True
    )
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    return result


def clone_wiki(wiki_url, target_dir):
    """Clone the wiki repository."""
    print(f"\nCloning wiki from {wiki_url}...")
    run_command(['git', 'clone', wiki_url, str(target_dir)])


def copy_and_convert_docs(docs_dir, wiki_dir, file_mappings, dry_run=False):
    """
    Copy documentation files to wiki, converting links.
    
    Args:
        docs_dir: Source docs directory
        wiki_dir: Target wiki directory
        file_mappings: Dict mapping file paths to wiki page names
        dry_run: If True, only show what would be done
    """
    docs_path = Path(docs_dir)
    wiki_path = Path(wiki_dir)
    
    print(f"\nCopying and converting docs from {docs_path} to {wiki_path}...")
    
    files_processed = 0
    
    # Process each markdown file
    for md_file in docs_path.rglob('*.md'):
        # Skip special files
        if md_file.name in ('COLCON_IGNORE', 'README.md'):
            print(f"  Skipping {md_file.name}")
            continue
        
        # Get wiki page name
        rel_path = md_file.relative_to(docs_path)
        wiki_name = path_to_wiki_name(rel_path)
        wiki_file = wiki_path / f"{wiki_name}.md"
        
        print(f"  {rel_path} -> {wiki_name}.md")
        
        if not dry_run:
            # Convert links in content
            converted_content = convert_file(md_file, file_mappings)
            
            # Write to wiki directory
            wiki_file.write_text(converted_content, encoding='utf-8')
        
        files_processed += 1
    
    # Handle index.md -> Home.md
    index_file = docs_path / 'index.md'
    if index_file.exists():
        print(f"  Creating Home.md from index.md")
        if not dry_run:
            converted_content = convert_file(index_file, file_mappings)
            home_file = wiki_path / 'Home.md'
            home_file.write_text(converted_content, encoding='utf-8')
        files_processed += 1
    else:
        # Create a default Home.md from project.md if index doesn't exist
        project_file = docs_path / 'project.md'
        if project_file.exists():
            print(f"  Creating Home.md from project.md")
            if not dry_run:
                converted_content = convert_file(project_file, file_mappings)
                home_file = wiki_path / 'Home.md'
                home_file.write_text(converted_content, encoding='utf-8')
            files_processed += 1
    
    print(f"\nProcessed {files_processed} files")
    return files_processed


def copy_assets(docs_dir, wiki_dir, dry_run=False):
    """
    Copy image and asset files to wiki.
    
    Args:
        docs_dir: Source docs directory
        wiki_dir: Target wiki directory
        dry_run: If True, only show what would be done
    """
    docs_path = Path(docs_dir)
    wiki_path = Path(wiki_dir)
    
    # Common image/asset extensions
    asset_extensions = {'.png', '.jpg', '.jpeg', '.gif', '.svg', '.pdf'}
    
    assets_copied = 0
    
    for asset_file in docs_path.rglob('*'):
        if asset_file.suffix.lower() in asset_extensions:
            rel_path = asset_file.relative_to(docs_path)
            target_file = wiki_path / rel_path
            
            print(f"  Copying asset: {rel_path}")
            
            if not dry_run:
                target_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(asset_file, target_file)
            
            assets_copied += 1
    
    if assets_copied > 0:
        print(f"\nCopied {assets_copied} asset files")
    
    return assets_copied


def commit_and_push_changes(wiki_dir, dry_run=False):
    """
    Commit and push changes to wiki repository.
    
    Args:
        wiki_dir: Wiki repository directory
        dry_run: If True, show changes but don't push
    """
    wiki_path = Path(wiki_dir)
    
    print("\nChecking for changes...")
    status_result = run_command(['git', 'status', '--porcelain'], cwd=wiki_path)
    
    if not status_result.stdout.strip():
        print("No changes to commit")
        return False
    
    print("Changes detected:")
    print(status_result.stdout)
    
    if dry_run:
        print("\nDry run - would commit and push these changes")
        return True
    
    # Add all changes
    run_command(['git', 'add', '.'], cwd=wiki_path)
    
    # Commit
    commit_msg = "Sync documentation from docs/ directory"
    run_command(['git', 'commit', '-m', commit_msg], cwd=wiki_path)
    
    # Push
    print("\nPushing changes to wiki...")
    run_command(['git', 'push'], cwd=wiki_path)
    
    print("✅ Wiki sync complete!")
    return True


def main():
    parser = argparse.ArgumentParser(
        description='Sync docs/ directory to GitHub Wiki',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Sync to wiki (requires GITHUB_TOKEN env var for CI)
  python wiki_sync.py --remote https://github.com/user/repo.wiki.git
  
  # Test locally without pushing
  python wiki_sync.py --dry-run
  
  # Use custom docs directory
  python wiki_sync.py --docs ../documentation --remote <url>
        """
    )
    
    parser.add_argument(
        '--remote',
        default='https://github.com/danmartinez78/shadowhound.wiki.git',
        help='Wiki git repository URL (default: shadowhound wiki)'
    )
    parser.add_argument(
        '--docs',
        default='docs',
        help='Documentation directory (default: docs)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be done without actually syncing'
    )
    
    args = parser.parse_args()
    
    # Validate docs directory exists
    docs_dir = Path(args.docs)
    if not docs_dir.exists():
        print(f"Error: Documentation directory '{docs_dir}' does not exist")
        sys.exit(1)
    
    print("=" * 60)
    print("GitHub Wiki Sync")
    print("=" * 60)
    print(f"Docs directory: {docs_dir.absolute()}")
    print(f"Wiki remote: {args.remote}")
    print(f"Mode: {'DRY RUN' if args.dry_run else 'LIVE SYNC'}")
    print("=" * 60)
    
    # Get file mappings for link conversion
    file_mappings = get_file_mappings(docs_dir)
    print(f"\nDiscovered {len(file_mappings)} documentation files")
    
    # Create temp directory for wiki clone
    with tempfile.TemporaryDirectory() as temp_dir:
        wiki_dir = Path(temp_dir) / 'wiki'
        
        if not args.dry_run:
            # Clone wiki repository
            try:
                clone_wiki(args.remote, wiki_dir)
            except subprocess.CalledProcessError as e:
                print(f"\n❌ Failed to clone wiki: {e}")
                print("\nMake sure:")
                print("  1. The wiki exists (enable it in GitHub repo settings)")
                print("  2. You have push access (set GITHUB_TOKEN for CI)")
                sys.exit(1)
        else:
            # Create dummy directory for dry run
            wiki_dir.mkdir(parents=True)
            print(f"\nDry run: Using temporary directory {wiki_dir}")
        
        # Copy and convert documentation
        files_count = copy_and_convert_docs(docs_dir, wiki_dir, file_mappings, args.dry_run)
        
        # Copy assets (images, etc)
        assets_count = copy_assets(docs_dir, wiki_dir, args.dry_run)
        
        if not args.dry_run and (files_count > 0 or assets_count > 0):
            # Commit and push changes
            changes_made = commit_and_push_changes(wiki_dir, args.dry_run)
            
            if changes_made:
                print(f"\n✅ Successfully synced {files_count} files and {assets_count} assets")
            else:
                print("\n✅ No changes needed - wiki is up to date")
        else:
            print(f"\n✅ Dry run complete - would sync {files_count} files and {assets_count} assets")


if __name__ == '__main__':
    main()
