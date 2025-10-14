#!/usr/bin/env python3
"""Generate Markdown stubs for ROS 2 packages in the ShadowHound workspace."""

from __future__ import annotations

import argparse
import ast
import textwrap
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Optional, Any

try:
    import yaml
except ImportError as exc:  # pragma: no cover - dependency hint
    raise SystemExit("PyYAML is required. Install with 'pip install pyyaml'.") from exc

try:
    from docstring_parser import parse as parse_docstring
    DOCSTRING_PARSER_AVAILABLE = True
except ImportError:
    DOCSTRING_PARSER_AVAILABLE = False

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
            f"- [[{package_dir.name}_api|API Reference]] (if Python package)",
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


# ============================================================================
# Python API Extraction Functions
# ============================================================================


def find_python_modules(package_dir: Path, package_name: str) -> List[Path]:
    """Find Python modules in a ROS 2 package.
    
    Args:
        package_dir: Root directory of the package
        package_name: Name of the package
        
    Returns:
        List of Python module files (excluding __init__.py and test files)
    """
    python_package_dir = package_dir / package_name
    if not python_package_dir.exists():
        return []
    
    modules: List[Path] = []
    for py_file in python_package_dir.rglob("*.py"):
        # Skip __init__.py and test files
        if py_file.name == "__init__.py" or py_file.name.startswith("test_"):
            continue
        # Skip hidden files
        if py_file.name.startswith("."):
            continue
        # Skip files in directories named 'test*'
        if py_file.parent.name.lower().startswith("test"):
            continue
        modules.append(py_file)
    
    return sorted(modules)


def extract_function_signature(node: ast.FunctionDef) -> str:
    """Extract function signature with type hints.
    
    Args:
        node: AST FunctionDef node
        
    Returns:
        Function signature string
    """
    args_list: List[str] = []
    
    # Handle regular arguments
    for arg in node.args.args:
        arg_str = arg.arg
        if arg.annotation:
            arg_str += f": {ast.unparse(arg.annotation)}"
        args_list.append(arg_str)
    
    # Handle *args
    if node.args.vararg:
        vararg_str = f"*{node.args.vararg.arg}"
        if node.args.vararg.annotation:
            vararg_str += f": {ast.unparse(node.args.vararg.annotation)}"
        args_list.append(vararg_str)
    
    # Handle **kwargs
    if node.args.kwarg:
        kwarg_str = f"**{node.args.kwarg.arg}"
        if node.args.kwarg.annotation:
            kwarg_str += f": {ast.unparse(node.args.kwarg.annotation)}"
        args_list.append(kwarg_str)
    
    # Build signature
    signature = f"{node.name}({', '.join(args_list)})"
    
    # Add return type if present
    if node.returns:
        signature += f" -> {ast.unparse(node.returns)}"
    
    return signature


def parse_class_info(node: ast.ClassDef, source_code: str) -> Dict[str, Any]:
    """Parse class information from AST node.
    
    Args:
        node: AST ClassDef node
        source_code: Original source code for docstring extraction
        
    Returns:
        Dictionary with class information
    """
    info: Dict[str, Any] = {
        "name": node.name,
        "docstring": ast.get_docstring(node) or "",
        "bases": [ast.unparse(base) for base in node.bases],
        "methods": [],
        "lineno": node.lineno,
    }
    
    # Parse methods
    for item in node.body:
        if isinstance(item, ast.FunctionDef):
            # Skip private methods unless they're special methods
            if item.name.startswith("_") and not (
                item.name.startswith("__") and item.name.endswith("__")
            ):
                continue
            
            method_info = {
                "name": item.name,
                "signature": extract_function_signature(item),
                "docstring": ast.get_docstring(item) or "",
                "lineno": item.lineno,
            }
            info["methods"].append(method_info)
    
    return info


def parse_function_info(node: ast.FunctionDef) -> Dict[str, Any]:
    """Parse function information from AST node.
    
    Args:
        node: AST FunctionDef node
        
    Returns:
        Dictionary with function information
    """
    return {
        "name": node.name,
        "signature": extract_function_signature(node),
        "docstring": ast.get_docstring(node) or "",
        "lineno": node.lineno,
    }


def extract_module_api(module_path: Path) -> Dict[str, Any]:
    """Extract API information from a Python module.
    
    Args:
        module_path: Path to Python module file
        
    Returns:
        Dictionary with classes and functions
    """
    try:
        with module_path.open("r", encoding="utf-8") as f:
            source_code = f.read()
    except (UnicodeDecodeError, FileNotFoundError) as e:
        return {
            "error": f"Failed to read {module_path.name}: {e}",
            "classes": [],
            "functions": [],
        }
    try:
        tree = ast.parse(source_code)
    except SyntaxError as e:
        return {
            "error": f"Syntax error in {module_path.name}: {e}",
            "classes": [],
            "functions": [],
        }
    
    classes: List[Dict[str, Any]] = []
    functions: List[Dict[str, Any]] = []
    module_docstring = ast.get_docstring(tree)
    
    for node in tree.body:
        if isinstance(node, ast.ClassDef):
            # Skip private classes
            if not node.name.startswith("_"):
                classes.append(parse_class_info(node, source_code))
        elif isinstance(node, ast.FunctionDef):
            # Skip private functions
            if not node.name.startswith("_"):
                functions.append(parse_function_info(node))
    
    return {
        "module_docstring": module_docstring or "",
        "classes": classes,
        "functions": functions,
    }


def format_docstring_section(docstring: str, indent: int = 0) -> List[str]:
    """Format docstring with proper indentation and parse sections if possible.
    
    Args:
        docstring: Raw docstring text
        indent: Number of spaces to indent
        
    Returns:
        List of formatted lines
    """
    if not docstring:
        return []
    
    lines: List[str] = []
    indent_str = " " * indent
    
    if not DOCSTRING_PARSER_AVAILABLE:
        # Fallback: just format the raw docstring
        for line in docstring.split("\n"):
            lines.append(f"{indent_str}{line.strip()}")
        return lines
    
    try:
        parsed = parse_docstring(docstring)
        
        # Short description
        if parsed.short_description:
            lines.append(f"{indent_str}{parsed.short_description}")
            lines.append("")
        
        # Long description
        if parsed.long_description:
            for line in parsed.long_description.split("\n"):
                lines.append(f"{indent_str}{line.strip()}")
            lines.append("")
        
        # Parameters
        if parsed.params:
            lines.append(f"{indent_str}**Parameters:**")
            for param in parsed.params:
                param_line = f"{indent_str}- `{param.arg_name}`"
                if param.type_name:
                    param_line += f" ({param.type_name})"
                if param.description:
                    param_line += f": {param.description}"
                lines.append(param_line)
            lines.append("")
        
        # Returns
        if parsed.returns:
            lines.append(f"{indent_str}**Returns:**")
            return_line = f"{indent_str}- "
            if parsed.returns.type_name:
                return_line += f"{parsed.returns.type_name}"
            if parsed.returns.description:
                if parsed.returns.type_name:
                    return_line += f": {parsed.returns.description}"
                else:
                    return_line += parsed.returns.description
            lines.append(return_line)
            lines.append("")
        
        # Raises
        if parsed.raises:
            lines.append(f"{indent_str}**Raises:**")
            for exc in parsed.raises:
                exc_line = f"{indent_str}- "
                if exc.type_name:
                    exc_line += f"`{exc.type_name}`"
                if exc.description:
                    exc_line += f": {exc.description}"
                lines.append(exc_line)
            lines.append("")
        
        # Examples
        if parsed.examples:
            lines.append(f"{indent_str}**Example:**")
            for example in parsed.examples:
                # Check if example has code snippet
                if example.snippet:
                    lines.append(f"{indent_str}```python")
                    for line in example.snippet.split("\n"):
                        lines.append(f"{indent_str}{line}")
                    lines.append(f"{indent_str}```")
                if example.description:
                    lines.append(f"{indent_str}{example.description}")
            lines.append("")
        
    except Exception:
        # Fallback if parsing fails
        for line in docstring.split("\n"):
            lines.append(f"{indent_str}{line.strip()}")
    
    return lines


def build_api_markdown(
    package_name: str, modules: List[Path], package_dir: Path, repo_root: Path
) -> str:
    """Build API reference markdown for a package.
    
    Args:
        package_name: Name of the package
        modules: List of Python module files
        package_dir: Package directory path
        repo_root: Repository root path
        
    Returns:
        Markdown content for API reference
    """
    lines: List[str] = [
        FRONT_MATTER_TEMPLATE.format(package=f"{package_name}_api"),
        "",
        f"# {package_name} API Reference",
        "",
        "Auto-generated Python API documentation.",
        "",
    ]
    
    if not modules:
        lines.append("No public Python modules found in this package.")
        return "\n".join(lines).rstrip() + "\n"
    
    # Process each module
    for module_path in modules:
        rel_path = module_path.relative_to(package_dir)
        module_name = str(rel_path).replace("/", ".").replace(".py", "")
        
        lines.append(f"## Module: `{module_name}`")
        lines.append("")
        
        # Extract API
        api_info = extract_module_api(module_path)
        
        if "error" in api_info:
            lines.append(f"*{api_info['error']}*")
            lines.append("")
            continue
        
        # Module docstring
        if api_info.get("module_docstring"):
            lines.extend(format_docstring_section(api_info["module_docstring"]))
            lines.append("")
        
        # Classes
        if api_info["classes"]:
            for class_info in api_info["classes"]:
                lines.append(f"### Class: `{class_info['name']}`")
                lines.append("")
                
                # Inheritance
                if class_info["bases"]:
                    lines.append(f"**Inherits:** {', '.join(f'`{b}`' for b in class_info['bases'])}")
                    lines.append("")
                
                # Class docstring
                if class_info["docstring"]:
                    lines.extend(format_docstring_section(class_info["docstring"]))
                    lines.append("")
                
                # Methods
                if class_info["methods"]:
                    lines.append("#### Methods")
                    lines.append("")
                    
                    for method in class_info["methods"]:
                        lines.append(f"##### `{method['signature']}`")
                        lines.append("")
                        
                        if method["docstring"]:
                            lines.extend(format_docstring_section(method["docstring"]))
                        else:
                            lines.append("*No documentation available.*")
                        lines.append("")
        
        # Module-level functions
        if api_info["functions"]:
            lines.append("### Functions")
            lines.append("")
            
            for func_info in api_info["functions"]:
                lines.append(f"#### `{func_info['signature']}`")
                lines.append("")
                
                if func_info["docstring"]:
                    lines.extend(format_docstring_section(func_info["docstring"]))
                else:
                    lines.append("*No documentation available.*")
                lines.append("")
        
        lines.append("---")
        lines.append("")
    
    # Add references
    lines.append("## References")
    lines.append("")
    lines.append(f"- [[{package_name}|Package Overview]]")
    lines.append("- [[_index|Return to Autodoc Index]]")
    lines.append("")
    
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate ROS 2 autodoc stubs.")
    parser.add_argument("--src", default="src", type=Path, help="Source directory containing ROS 2 packages.")
    parser.add_argument(
        "--output",
        default=Path("docs/software/autodoc"),
        type=Path,
        help="Destination directory for generated Markdown files.",
    )
    parser.add_argument(
        "--api",
        action="store_true",
        help="Generate API reference documentation from Python docstrings.",
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
        
        # Generate package stub
        markdown = build_markdown(package_dir, meta, repo_root)
        write_markdown(output_dir, package_dir.name, markdown)
        print(f"Generated autodoc for {meta['name']} -> {output_dir / (package_dir.name + '.md')}")
        
        # Generate API reference if requested
        if args.api:
            modules = find_python_modules(package_dir, meta["name"])
            if modules:
                api_markdown = build_api_markdown(meta["name"], modules, package_dir, repo_root)
                write_markdown(output_dir, f"{package_dir.name}_api", api_markdown)
                print(f"Generated API docs for {meta['name']} -> {output_dir / (package_dir.name + '_api.md')}")
            else:
                print(f"No Python modules found for {meta['name']}")


if __name__ == "__main__":
    main()
