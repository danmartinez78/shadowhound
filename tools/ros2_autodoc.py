#!/usr/bin/env python3
"""Generate Markdown stubs for ROS 2 packages in the ShadowHound workspace."""

from __future__ import annotations

import argparse
import textwrap
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, Iterable, List, Sequence

try:
    import yaml
except ImportError as exc:  # pragma: no cover - dependency hint
    raise SystemExit("PyYAML is required. Install with 'pip install pyyaml'.") from exc

FRONT_MATTER_TEMPLATE = textwrap.dedent(
    """
    ---
    tags: [software, autodoc]
    status: draft
    related: []
    summary: >
      Auto-generated reference for {package}.
    ---
    """
).strip()

REQUIRED_SECTIONS = ["Purpose", "Prerequisites", "Steps", "Validation", "References"]

PACKAGE_XML_TAGS = (
    "depend",
    "build_depend",
    "exec_depend",
    "test_depend",
    "build_export_depend",
    "exec_export_depend",
    "doc_depend",
)


def find_ros_packages(src_dir: Path) -> List[Path]:
    packages: List[Path] = []
    for package_xml in src_dir.rglob("package.xml"):
        packages.append(package_xml.parent)
    return packages


def parse_package_xml(package_xml: Path) -> Dict[str, object]:
    tree = ET.parse(package_xml)
    root = tree.getroot()

    name = root.findtext("name", "unknown_package").strip()
    description = root.findtext("description", "").strip() or "No description provided."

    maintainers = [
        "{} <{}>".format(m.text.strip(), m.attrib.get("email", ""))
        for m in root.findall("maintainer")
        if m.text
    ]
    maintainers = [m.replace(" <>", "").strip() for m in maintainers if m.strip()]

    dependencies: List[str] = []
    for tag in PACKAGE_XML_TAGS:
        dependencies.extend([d.text.strip() for d in root.findall(tag) if d.text])
    dependencies = sorted(set(dependencies))

    licenses = [l.text.strip() for l in root.findall("license") if l.text]

    return {
        "name": name,
        "description": description,
        "maintainers": maintainers,
        "dependencies": dependencies,
        "licenses": licenses,
    }


def discover_files(package_dir: Path, patterns: Sequence[str]) -> List[Path]:
    matches: List[Path] = []
    for pattern in patterns:
        matches.extend(package_dir.rglob(pattern))
    return sorted(matches)


def flatten_yaml(data: object, prefix: str = "") -> List[str]:
    results: List[str] = []
    if isinstance(data, dict):
        for key, value in data.items():
            new_prefix = f"{prefix}.{key}" if prefix else str(key)
            if isinstance(value, dict):
                results.extend(flatten_yaml(value, new_prefix))
            else:
                results.append(new_prefix)
    elif isinstance(data, list):
        for index, value in enumerate(data):
            new_prefix = f"{prefix}[{index}]" if prefix else f"[{index}]"
            if isinstance(value, (dict, list)):
                results.extend(flatten_yaml(value, new_prefix))
            else:
                results.append(f"{new_prefix} = {value}")
    return results


def extract_parameters(yaml_paths: Iterable[Path]) -> Dict[str, List[str]]:
    parameters: Dict[str, List[str]] = {}
    for path in yaml_paths:
        try:
            with path.open("r", encoding="utf-8") as handle:
                data = yaml.safe_load(handle) or {}
        except Exception as exc:  # pragma: no cover - defensive logging
            parameters[path.name] = [f"Failed to parse: {exc}"]
            continue

        flattened = flatten_yaml(data)
        parameters[path.name] = flattened if flattened else ["(No parameters discovered)"]
    return parameters


def build_markdown(package_dir: Path, meta: Dict[str, object], repo_root: Path) -> str:
    rel_package_path = package_dir.relative_to(repo_root)
    launch_files = discover_files(package_dir, ("*.launch.py", "*.launch.xml"))
    yaml_files = discover_files(package_dir, ("*.yaml", "*.yml"))
    parameters = extract_parameters(yaml_files)

    lines: List[str] = [FRONT_MATTER_TEMPLATE.format(package=meta["name"]), ""]
    lines.append(f"# {meta['name']} Package")
    lines.append("")

    sections: Dict[str, List[str]] = {
        "Purpose": [meta["description"]],
        "Prerequisites": ["- ROS 2 workspace configured per [[../ros2_setup|ROS 2 Workstation Setup]]."],
        "Steps": [],
        "Validation": [
            "- [ ] `colcon build --packages-select {}` succeeds.".format(meta["name"]),
            "- [ ] Unit tests pass for this package.",
            "- [ ] Generated launch files load without runtime errors.",
        ],
        "References": [
            f"- Source directory: `{rel_package_path}`",
            "- [[_index|Return to Autodoc Index]]",
        ],
    }

    steps_lines: List[str] = ["1. Review package metadata below."]
    steps_lines.append("2. Update this doc with manual context as the implementation evolves.")
    steps_lines.append("3. Validate launch files and parameter sets using the ROS 2 tooling described here.")

    sections["Steps"].extend(steps_lines)

    lines.append("## Package Metadata")
    lines.append("")
    lines.append("| Field | Details |")
    lines.append("|-------|---------|")
    lines.append(f"| Path | `{rel_package_path}` |")
    lines.append(f"| Maintainers | {', '.join(meta['maintainers']) if meta['maintainers'] else 'TBD'} |")
    lines.append(f"| Licenses | {', '.join(meta['licenses']) if meta['licenses'] else 'TBD'} |")
    lines.append(f"| Dependencies | {', '.join(meta['dependencies']) if meta['dependencies'] else 'None'} |")
    lines.append("")

    lines.append("### Launch Files")
    if launch_files:
        lines.extend([f"- `{path.relative_to(repo_root)}`" for path in launch_files])
    else:
        lines.append("- None discovered")
    lines.append("")

    lines.append("### Parameter Files")
    if yaml_files:
        for yaml_path in yaml_files:
            rel = yaml_path.relative_to(repo_root)
            lines.append(f"- `{rel}`")
            for entry in parameters.get(yaml_path.name, []):
                lines.append(f"  - {entry}")
    else:
        lines.append("- None discovered")
    lines.append("")

    for section in REQUIRED_SECTIONS:
        lines.append(f"## {section}")
        lines.append("")
        for entry in sections.get(section, []):
            lines.append(entry)
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def write_markdown(output_dir: Path, package_name: str, content: str) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{package_name}.md"
    with output_path.open("w", encoding="utf-8") as handle:
        handle.write(content)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate ROS 2 autodoc stubs.")
    parser.add_argument("--src", default="src", type=Path, help="Source directory containing ROS 2 packages.")
    parser.add_argument(
        "--output",
        default=Path("docs/software/autodoc"),
        type=Path,
        help="Destination directory for generated Markdown files.",
    )
    args = parser.parse_args()

    repo_root = Path.cwd()
    src_dir: Path = (repo_root / args.src).resolve()
    output_dir: Path = (repo_root / args.output).resolve()

    if not src_dir.exists():
        raise SystemExit(f"Source directory {src_dir} does not exist")

    packages = find_ros_packages(src_dir)
    if not packages:
        print("No package.xml files discovered under", src_dir)
        return

    for package_dir in packages:
        meta = parse_package_xml(package_dir / "package.xml")
        markdown = build_markdown(package_dir, meta, repo_root)
        write_markdown(output_dir, package_dir.name, markdown)
        print(f"Generated autodoc for {meta['name']} -> {output_dir / (package_dir.name + '.md')}")


if __name__ == "__main__":
    main()
