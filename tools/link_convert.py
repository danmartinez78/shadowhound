#!/usr/bin/env python3
"""
Convert standard Markdown links to GitHub Wiki link format.

GitHub Wiki uses a special link format where:
- Standard: [Link Text](path/to/file.md)
- Wiki: [[Link Text|File-Name]]

This script converts standard markdown links to wiki format.
"""

import re
from pathlib import Path
from typing import Dict, Tuple


def convert_internal_links(content: str, file_mappings: Dict[str, str]) -> str:
    """
    Convert internal markdown links to wiki format.
    
    Args:
        content: Markdown content with standard links
        file_mappings: Dict mapping file paths to wiki page names
        
    Returns:
        Content with wiki-formatted links
    """
    
    def replace_link(match):
        """Replace a single markdown link with wiki format."""
        link_text = match.group(1)
        link_path = match.group(2)
        
        # Skip external links (http/https)
        if link_path.startswith(('http://', 'https://', 'mailto:')):
            return match.group(0)
        
        # Skip anchors without file paths
        if link_path.startswith('#'):
            return match.group(0)
        
        # Remove anchor from path
        link_path_clean = link_path.split('#')[0]
        
        # Get anchor if present
        anchor = ''
        if '#' in link_path:
            anchor = link_path.split('#')[1]
        
        # Find wiki page name
        wiki_page = None
        for file_path, page_name in file_mappings.items():
            if file_path.endswith(link_path_clean) or link_path_clean.endswith(file_path):
                wiki_page = page_name
                break
        
        if wiki_page:
            # Use wiki link format
            if anchor:
                return f"[[{link_text}|{wiki_page}#{anchor}]]"
            else:
                return f"[[{link_text}|{wiki_page}]]"
        else:
            # Keep original if we can't find mapping
            return match.group(0)
    
    # Match markdown links: [text](path)
    pattern = r'\[([^\]]+)\]\(([^)]+)\)'
    return re.sub(pattern, replace_link, content)


def path_to_wiki_name(file_path: Path) -> str:
    """
    Convert a file path to a wiki page name.
    
    Examples:
        project.md -> project
        DIMOS_INTEGRATION.md -> DIMOS-INTEGRATION
        deployment/wiki_sync.md -> Deployment-wiki-sync
    """
    # Remove .md extension
    name = file_path.stem
    
    # Replace underscores with hyphens (wiki convention)
    name = name.replace('_', '-')
    
    # For nested paths (has subdirectory), include parent directory
    if len(file_path.parts) > 1:  # Has parent directory
        parent = file_path.parts[-2]  # Get immediate parent
        name = f"{parent.title()}-{name}"
    
    return name


def get_file_mappings(docs_dir: Path) -> Dict[str, str]:
    """
    Create a mapping of file paths to wiki page names.
    
    Args:
        docs_dir: Path to docs directory
        
    Returns:
        Dict mapping relative file paths to wiki page names
    """
    mappings = {}
    
    for md_file in docs_dir.rglob('*.md'):
        # Skip COLCON_IGNORE and other non-doc files
        if md_file.name in ('COLCON_IGNORE', 'README.md'):
            continue
        
        rel_path = md_file.relative_to(docs_dir)
        wiki_name = path_to_wiki_name(rel_path)
        
        # Store both relative path forms for matching
        mappings[str(rel_path)] = wiki_name
        mappings[rel_path.name] = wiki_name
    
    return mappings


def convert_file(file_path: Path, file_mappings: Dict[str, str]) -> str:
    """
    Convert a single markdown file's links to wiki format.
    
    Args:
        file_path: Path to markdown file
        file_mappings: Dict mapping file paths to wiki page names
        
    Returns:
        Converted content
    """
    content = file_path.read_text(encoding='utf-8')
    return convert_internal_links(content, file_mappings)


if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python link_convert.py <docs_dir>")
        print("Example: python link_convert.py docs/")
        sys.exit(1)
    
    docs_dir = Path(sys.argv[1])
    if not docs_dir.exists():
        print(f"Error: Directory {docs_dir} does not exist")
        sys.exit(1)
    
    # Get all file mappings
    mappings = get_file_mappings(docs_dir)
    print(f"Found {len(mappings)} documentation files")
    print("\nFile mappings:")
    for path, wiki_name in sorted(mappings.items()):
        if '/' in path or '\\' in path:  # Only show full paths
            print(f"  {path} -> {wiki_name}")
    
    # Test conversion on a file if provided
    if len(sys.argv) >= 3:
        test_file = Path(sys.argv[2])
        if test_file.exists():
            print(f"\nConverting {test_file}...")
            converted = convert_file(test_file, mappings)
            print("\nConverted content:")
            print(converted[:500])  # Show first 500 chars
