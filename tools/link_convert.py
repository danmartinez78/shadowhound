#!/usr/bin/env python3
"""Convert Obsidian wikilinks and embeds to standard Markdown links."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path
from typing import Iterable

WIKILINK_PATTERN = re.compile(r"(!?)\[\[([^\]]+)\]\]")


def slugify(value: str) -> str:
    slug = re.sub(r"[^0-9A-Za-z\s-]", "", value)
    slug = slug.strip().lower()
    slug = re.sub(r"[\s]+", "-", slug)
    return slug


def needs_extension(target: str) -> bool:
    basename = Path(target).name
    return "." not in basename


def normalize_target(target: str) -> str:
    target = target.replace("\\", "/")
    return target.strip()


def convert_match(match: re.Match[str]) -> str:
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

    if needs_extension(target_part):
        href = f"{target_part}.md"
    else:
        href = target_part

    if anchor_slug:
        href = f"{href}#{anchor_slug}"

    href = href.replace(" ", "%20")

    if is_embed:
        alt_text = label_part or Path(target_part).name
        return f"![{alt_text}]({href})"

    label = label_part or Path(target_part).name or target_part
    if anchor and not label_part:
        label = f"{label} § {anchor}"
    return f"[{label}]({href})"


def convert_text(content: str) -> str:
    return WIKILINK_PATTERN.sub(convert_match, content)


def convert_file(input_path: Path, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if input_path.suffix.lower() == ".md":
        with input_path.open("r", encoding="utf-8") as handle:
            content = handle.read()
        converted = convert_text(content)
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
        convert_file(input_path, output_path)


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert Obsidian wikilinks to Markdown links.")
    parser.add_argument("input", type=Path, help="Source directory containing Obsidian Markdown.")
    parser.add_argument("output", type=Path, help="Destination directory for converted Markdown.")
    args = parser.parse_args()

    convert_tree(args.input, args.output)
    print(f"Converted {args.input} -> {args.output}")


if __name__ == "__main__":
    main()
