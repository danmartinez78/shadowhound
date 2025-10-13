#!/usr/bin/env python3
"""Convert standard Markdown links to Obsidian wikilinks.

This script reverses the conversion done by link_convert.py:
- Converts [text](path.md) → [[path|text]]
- Removes .md extensions
- Handles anchors: path.md#heading → path#heading
- Skips external URLs (http://, https://, mailto:)
- Preserves YAML front-matter
"""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path
from typing import Iterable

# Pattern to match standard markdown links: [text](href)
MARKDOWN_LINK_PATTERN = re.compile(r'(!?)\[([^\]]+)\]\(([^)]+)\)')


def is_external_url(href: str) -> bool:
    """Check if href is an external URL that should not be converted."""
    return href.startswith(('http://', 'https://', 'mailto:', 'ftp://'))


def deslugify(slug: str) -> str:
    """Convert slugified anchor back to original (best effort).
    
    This is approximate since slugification loses information.
    We keep it simple: just replace hyphens with spaces and capitalize.
    """
    return slug.replace('-', ' ')


def normalize_href(href: str) -> str:
    """Normalize href by removing URL encoding and normalizing path separators."""
    # Decode URL-encoded spaces
    href = href.replace('%20', ' ')
    # Normalize path separators
    href = href.replace('\\', '/')
    return href.strip()


def calculate_wikilink_path(href: str, current_file_path: Path) -> str:
    """Convert markdown relative path to wikilink path.
    
    Args:
        href: The href from markdown link (e.g., "../development/file.md")
        current_file_path: Path object of current file relative to docs root
    
    Returns:
        Wikilink path (e.g., "development/file" or "../index")
    """
    # Remove .md extension
    if href.endswith('.md'):
        href = href[:-3]
    
    # If href starts with ../, analyze the pattern
    if href.startswith('../'):
        # Count how many ../ are present
        parent_count = 0
        temp_href = href
        while temp_href.startswith('../'):
            parent_count += 1
            temp_href = temp_href[3:]
        
        # If we go up one level and then into a subdirectory (e.g., ../integrations/file)
        # This becomes an absolute path from docs root (e.g., integrations/file)
        if parent_count == 1 and '/' in temp_href:
            return temp_href
        elif parent_count == 1 and '/' not in temp_href:
            # This is a reference to parent directory (e.g., ../index → ../index)
            return href
        else:
            # Multiple levels up - keep as relative
            return href
    
    # If no ../, it's either a same-directory reference or already in correct format
    return href


def convert_markdown_to_wikilink(match: re.Match[str], current_file_path: Path) -> str:
    """Convert a single markdown link match to wikilink format.
    
    Args:
        match: Regex match object for markdown link
        current_file_path: Path object of current file relative to docs root
    
    Returns:
        Wikilink formatted string or original string for images
    """
    is_embed = match.group(1) == '!'
    label = match.group(2).strip()
    href = normalize_href(match.group(3))
    
    # Don't convert image embeds - keep them as standard markdown
    if is_embed:
        return match.group(0)
    
    # Skip external URLs
    if is_external_url(href):
        return match.group(0)
    
    # Split anchor if present
    if '#' in href:
        href_path, anchor = href.split('#', 1)
        # Deslugify anchor (approximate)
        anchor = deslugify(anchor)
    else:
        href_path, anchor = href, ''
    
    # Convert relative markdown path to wikilink path
    wikilink_path = calculate_wikilink_path(href_path, current_file_path)
    
    # Build wikilink: [[path|label]] or [[path#anchor|label]]
    wikilink = f'[[{wikilink_path}'
    if anchor:
        wikilink += f'#{anchor}'
    
    # Always add label for links (preserve the label from markdown)
    # This matches the pattern from docs_obs_original where labels are always present
    wikilink += f'|{label}'
    
    wikilink += ']]'
    
    return wikilink


def convert_text(content: str, current_file_path: Path) -> str:
    """Convert all markdown links in text to wikilinks.
    
    Args:
        content: Markdown text content
        current_file_path: Path object of current file relative to docs root
    
    Returns:
        Text with wikilinks instead of markdown links
    """
    return MARKDOWN_LINK_PATTERN.sub(
        lambda m: convert_markdown_to_wikilink(m, current_file_path),
        content
    )


def convert_file(input_path: Path, output_path: Path, input_root: Path) -> None:
    """Convert a single file from markdown to wikilink format.
    
    Args:
        input_path: Source file path
        output_path: Destination file path
        input_root: Root directory of input tree (for relative path calculation)
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if input_path.suffix.lower() == '.md':
        # Calculate path of current file relative to input root
        rel_path = input_path.relative_to(input_root)
        
        # Read and convert content
        with input_path.open('r', encoding='utf-8') as handle:
            content = handle.read()
        
        converted = convert_text(content, rel_path)
        
        # Write converted content
        with output_path.open('w', encoding='utf-8') as handle:
            handle.write(converted)
    else:
        # Copy non-markdown files as-is
        shutil.copy2(input_path, output_path)


def iter_files(root: Path) -> Iterable[Path]:
    """Iterate over all files in directory tree."""
    for path in root.rglob('*'):
        if path.is_file():
            yield path


def convert_tree(input_dir: Path, output_dir: Path) -> None:
    """Convert entire directory tree from markdown to wikilink format.
    
    Args:
        input_dir: Source directory with markdown files
        output_dir: Destination directory for converted files
    """
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    file_count = 0
    for input_path in iter_files(input_dir):
        rel_path = input_path.relative_to(input_dir)
        output_path = output_dir / rel_path
        convert_file(input_path, output_path, input_dir)
        file_count += 1
    
    print(f'✅ Converted {file_count} files from {input_dir} → {output_dir}')


def main() -> None:
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description='Convert standard Markdown links to Obsidian wikilinks.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Convert docs/ to Obsidian vault
  python tools/obsidian_convert.py docs docs_obs
  
  # Test on a subset
  python tools/obsidian_convert.py docs/software docs_obs_test
"""
    )
    parser.add_argument(
        'input',
        type=Path,
        help='Source directory containing standard Markdown files'
    )
    parser.add_argument(
        'output',
        type=Path,
        help='Destination directory for Obsidian wikilink files'
    )
    args = parser.parse_args()
    
    if not args.input.exists():
        print(f'❌ Error: Input directory {args.input} does not exist')
        return 1
    
    if not args.input.is_dir():
        print(f'❌ Error: Input path {args.input} is not a directory')
        return 1
    
    convert_tree(args.input, args.output)
    return 0


if __name__ == '__main__':
    exit(main())
