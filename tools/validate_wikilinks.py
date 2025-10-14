#!/usr/bin/env python3
"""Validate wikilinks in documentation files."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterator


WIKILINK_PATTERN = re.compile(r"\[\[([^\]]+)\]\]")


class WikilinkValidator:
    """Validator for wikilinks in Markdown documentation."""

    def __init__(self, docs_root: Path):
        """Initialize validator with documentation root directory."""
        self.docs_root = docs_root
        self.errors: list[str] = []

    def extract_target(self, wikilink: str) -> str:
        """
        Extract the target file path from a wikilink.
        
        Handles formats:
        - [[target]] → target
        - [[target|label]] → target
        - [[target#anchor]] → target
        - [[target#anchor|label]] → target
        """
        # Remove label if present
        if "|" in wikilink:
            target, _ = wikilink.split("|", 1)
        else:
            target = wikilink
        
        # Remove anchor if present
        if "#" in target:
            target, _ = target.split("#", 1)
        
        return target.strip()

    def validate_target(self, target: str, source_file: Path) -> bool:
        """Check if a target file exists, considering relative paths from source file."""
        if not target:
            return False
        
        # Normalize path separators
        target = target.replace("\\", "/")
        
        # If target starts with ../ or ./, it's a relative path from the source file
        if target.startswith("../") or target.startswith("./"):
            # Resolve relative to the source file's directory
            source_dir = source_file.parent
            target_path = (source_dir / target).resolve()
            
            # Check if it exists with .md extension
            if target_path.with_suffix(".md").exists():
                return True
            
            # Check if it exists as-is
            if target_path.exists():
                return True
            
            # Try adding .md to the path
            target_path_md = target_path.parent / (target_path.name + ".md")
            if target_path_md.exists():
                return True
        else:
            # Absolute path from docs root
            # Try with .md extension
            target_path = self.docs_root / f"{target}.md"
            if target_path.exists():
                return True
            
            # Try without adding extension (target might already have one)
            target_path = self.docs_root / target
            if target_path.exists():
                return True
            
            # For targets in the same directory as source, check relative to source
            # This handles cases like [[scripts]] when in software/ directory
            source_dir = source_file.parent
            local_target = source_dir / f"{target}.md"
            if local_target.exists():
                return True
        
        return False

    def find_wikilinks(self, file_path: Path) -> Iterator[tuple[int, str]]:
        """Find all wikilinks in a file, yielding (line_number, wikilink_content)."""
        try:
            with file_path.open("r", encoding="utf-8") as f:
                for line_num, line in enumerate(f, start=1):
                    for match in WIKILINK_PATTERN.finditer(line):
                        yield line_num, match.group(1)
        except Exception as e:
            self.errors.append(f"Error reading {file_path}: {e}")

    def validate_file(self, file_path: Path) -> list[str]:
        """Validate all wikilinks in a file, return list of error messages."""
        file_errors = []
        relative_path = file_path.relative_to(self.docs_root)
        
        for line_num, wikilink in self.find_wikilinks(file_path):
            target = self.extract_target(wikilink)
            
            if not self.validate_target(target, file_path):
                error_msg = f"{relative_path}:{line_num}: Broken wikilink [[{wikilink}]] -> target '{target}' not found"
                file_errors.append(error_msg)
        
        return file_errors

    def validate_all(self) -> int:
        """
        Validate all markdown files in the docs directory.
        
        Returns:
            Number of broken wikilinks found
        """
        print(f"Validating wikilinks in {self.docs_root}")
        print("-" * 60)
        
        broken_count = 0
        file_count = 0
        
        for md_file in sorted(self.docs_root.rglob("*.md")):
            file_count += 1
            file_errors = self.validate_file(md_file)
            
            if file_errors:
                for error in file_errors:
                    print(f"❌ {error}")
                    broken_count += 1
        
        print("-" * 60)
        print(f"Scanned {file_count} markdown files")
        
        if broken_count > 0:
            print(f"❌ Found {broken_count} broken wikilink(s)")
            return broken_count
        else:
            print("✅ All wikilinks are valid!")
            return 0


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Validate wikilinks in documentation files"
    )
    parser.add_argument(
        "--docs",
        type=Path,
        default=Path("docs"),
        help="Path to documentation directory (default: docs)",
    )
    args = parser.parse_args()

    if not args.docs.exists():
        print(f"❌ Error: Documentation directory '{args.docs}' not found")
        return 1

    validator = WikilinkValidator(args.docs)
    broken_count = validator.validate_all()
    
    # Exit with error code if broken links found
    return 1 if broken_count > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
