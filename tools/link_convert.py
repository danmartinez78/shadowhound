#!/usr/bin/env python3
"""Convert Obsidian wikilinks and embeds to wiki-style links and strip YAML front-matter."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path
from typing import Iterable

WIKILINK_PATTERN = re.compile(r"(!?)\[\[([^\]]+)\]\]")
YAML_FRONTMATTER_PATTERN = re.compile(r"\A---\s*\n.*?\n---\s*\n", re.DOTALL)
MARKDOWN_LINK_PATTERN = re.compile(r"(!?)\[([^\]]+)\]\(([^\)]+)\)")


def slugify(value: str) -> str:
    """Convert text to URL-friendly slug (lowercase, hyphens)."""
    slug = re.sub(r"[^0-9A-Za-z\s-]", "", value)
    slug = slug.strip().lower()
    slug = re.sub(r"[\s]+", "-", slug)
    return slug


def wiki_slugify(path: str) -> str:
    """Convert file path to GitHub Wiki page name.
    
    GitHub Wiki expects page names like "Page-Name" (title case with hyphens).
    Example: "docs/path/to/my_page.md" -> "My-Page"
    """
    # Get the filename without extension
    filename = Path(path).stem
    
    # Replace underscores with spaces
    filename = filename.replace("_", " ")
    
    # Title case each word
    words = filename.split()
    titled_words = [word.capitalize() for word in words]
    
    # Join with hyphens
    return "-".join(titled_words)


def needs_extension(target: str) -> bool:
    basename = Path(target).name
    return "." not in basename


def normalize_target(target: str) -> str:
    target = target.replace("\\", "/")
    return target.strip()


def convert_match(match: re.Match[str], current_file_depth: int = 0) -> str:
    """Convert wikilink to wiki-style link (for GitHub Wiki).
    
    Wiki links should be just the page name without path or extension.
    Example: [[path/to/page]] -> [Page](Page)
    """
    is_embed = match.group(1) == "!"
    raw = match.group(2)
    if "|" in raw:
        target_part, label_part = raw.split("|", 1)
    else:
        target_part, label_part = raw, ""
    target_part = normalize_target(target_part)
    label_part = label_part.strip()

    if "#" in target_part:
        target_part, anchor = target_part.split("#", 1)
        anchor_slug = slugify(anchor)
    else:
        anchor = ""
        anchor_slug = ""

    if not target_part:
        return match.group(0)

    # For wiki-style links, convert the path to a wiki page name
    wiki_page_name = wiki_slugify(target_part)
    
    if anchor_slug:
        href = f"{wiki_page_name}#{anchor_slug}"
    else:
        href = wiki_page_name

    if is_embed:
        # For embeds (images), keep them as relative paths with extension
        # Images in wiki should reference _assets/ directory
        alt_text = label_part or Path(target_part).name
        if needs_extension(target_part):
            image_href = f"{target_part}.md"
        else:
            image_href = target_part
        return f"![{alt_text}]({image_href})"

    label = label_part or Path(target_part).stem or target_part
    if anchor and not label_part:
        label = f"{label} § {anchor}"
    return f"[{label}]({href})"


def convert_markdown_link(match: re.Match[str]) -> str:
    """Convert standard markdown link to wiki-style link (for GitHub Wiki).
    
    Converts [Label](path/to/file.md) to [Label](File)
    For images, keeps the path as-is since they need to reference _assets/
    """
    is_embed = match.group(1) == "!"
    label = match.group(2)
    href = match.group(3)
    
    # Skip external links (http://, https://, mailto:, etc.)
    if "://" in href or href.startswith("mailto:"):
        return match.group(0)
    
    # Skip anchor-only links
    if href.startswith("#"):
        return match.group(0)
    
    # For images/embeds, keep path as-is (especially for _assets/)
    if is_embed:
        return match.group(0)
    
    # For internal links to .md files, convert to wiki-style
    if href.endswith(".md"):
        # Remove the .md extension and any path
        wiki_page_name = wiki_slugify(href[:-3])  # Remove .md
        return f"[{label}]({wiki_page_name})"
    
    # Skip links that look like they're already wiki-style (no path, no extension)
    # These are typically results of wikilink conversion
    if "/" not in href and "." not in href:
        return match.group(0)
    
    # For other internal links with paths but no .md extension, convert to wiki-style
    if "/" in href and not "." in Path(href).name:  # Has path but no extension
        wiki_page_name = wiki_slugify(href)
        return f"[{label}]({wiki_page_name})"
    
    # Keep other links as-is (images, external files, etc.)
    return match.group(0)


def strip_yaml_frontmatter(content: str) -> str:
    """Remove YAML front-matter from the beginning of a markdown file.
    
    YAML front-matter is delimited by --- at the start and end.
    Example:
        ---
        tags: [test]
        status: draft
        ---
        
        # Content
        
    Returns just the content without the front-matter.
    """
    return YAML_FRONTMATTER_PATTERN.sub("", content, count=1)


def convert_text(content: str, current_file_depth: int = 0) -> str:
    """Convert wikilinks to wiki-style links and strip YAML front-matter."""
    # First strip YAML front-matter
    content = strip_yaml_frontmatter(content)
    # Then convert wikilinks
    content = WIKILINK_PATTERN.sub(lambda m: convert_match(m, current_file_depth), content)
    # Also convert standard markdown links to wiki-style
    content = MARKDOWN_LINK_PATTERN.sub(convert_markdown_link, content)
    return content


def convert_file(input_path: Path, output_path: Path, input_root: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if input_path.suffix.lower() == ".md":
        # Calculate depth of current file relative to input root
        rel_path = input_path.relative_to(input_root)
        current_file_depth = len(rel_path.parent.parts)
        
        with input_path.open("r", encoding="utf-8") as handle:
            content = handle.read()
        converted = convert_text(content, current_file_depth)
        with output_path.open("w", encoding="utf-8") as handle:
            handle.write(converted)
    else:
        shutil.copy2(input_path, output_path)


def iter_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if path.is_file():
            yield path


def convert_tree(input_dir: Path, output_dir: Path) -> None:
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for input_path in iter_files(input_dir):
        rel_path = input_path.relative_to(input_dir)
        output_path = output_dir / rel_path
        convert_file(input_path, output_path, input_dir)


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert Obsidian wikilinks to Markdown links.")
    parser.add_argument("input", type=Path, help="Source directory containing Obsidian Markdown.")
    parser.add_argument("output", type=Path, help="Destination directory for converted Markdown.")
    args = parser.parse_args()

    convert_tree(args.input, args.output)
    print(f"Converted {args.input} -> {args.output}")


if __name__ == "__main__":
    main()
