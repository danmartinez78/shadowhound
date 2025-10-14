#!/usr/bin/env python3
"""Tests for link_convert.py wiki-style conversion and YAML stripping."""

import tempfile
from pathlib import Path

from link_convert import (
    strip_yaml_frontmatter,
    wiki_slugify,
    convert_text,
    convert_tree,
)


def test_strip_yaml_frontmatter():
    """Test YAML front-matter stripping."""
    # Test with YAML front-matter
    content = """---
tags: [test, example]
status: draft
summary: >
  Multi-line summary
  goes here
---

# Content

This is the actual content."""
    result = strip_yaml_frontmatter(content)
    assert not result.startswith("---")
    assert "# Content" in result
    assert "tags:" not in result
    assert "status:" not in result

    # Test without YAML front-matter
    content_no_yaml = """# Title

Content without YAML."""
    result = strip_yaml_frontmatter(content_no_yaml)
    assert result == content_no_yaml

    # Test with YAML in middle of document (should not be stripped)
    content_yaml_middle = """# Title

---
This is not YAML front-matter
---

Content."""
    result = strip_yaml_frontmatter(content_yaml_middle)
    assert "---" in result  # Middle YAML should be preserved


def test_wiki_slugify():
    """Test wiki page name conversion."""
    # Simple filename
    assert wiki_slugify("simple_file") == "Simple-File"
    
    # Filename with path
    assert wiki_slugify("docs/path/to/page") == "Page"
    
    # Filename with underscores
    assert wiki_slugify("my_test_file") == "My-Test-File"
    
    # Already capitalized
    assert wiki_slugify("MyFile") == "Myfile"  # Note: capitalizes each word
    
    # Multiple words
    assert wiki_slugify("project_overview_hub") == "Project-Overview-Hub"


def test_convert_wikilinks():
    """Test wikilink to wiki-style conversion."""
    # Simple wikilink
    content = "Link to [[page]]"
    result = convert_text(content)
    assert result == "Link to [page](Page)"
    
    # Wikilink with underscore
    content = "Link to [[my_page]]"
    result = convert_text(content)
    assert result == "Link to [my_page](My-Page)"
    
    # Wikilink with path
    content = "Link to [[docs/path/to/page]]"
    result = convert_text(content)
    assert result == "Link to [page](Page)"
    
    # Wikilink with label
    content = "Link to [[page|Custom Label]]"
    result = convert_text(content)
    assert result == "Link to [Custom Label](Page)"
    
    # Wikilink with anchor
    content = "Link to [[page#section]]"
    result = convert_text(content)
    assert "page § section" in result
    assert "#section" in result


def test_convert_markdown_links():
    """Test markdown link to wiki-style conversion."""
    # Standard markdown link
    content = "[Setup Guide](docs/setup.md)"
    result = convert_text(content)
    assert result == "[Setup Guide](Setup)"
    
    # Link with path
    content = "[Architecture](architecture/system_design.md)"
    result = convert_text(content)
    assert result == "[Architecture](System-Design)"
    
    # Link without extension but with path
    content = "[Config](path/to/config)"
    result = convert_text(content)
    assert result == "[Config](Config)"
    
    # Link without path or extension (already wiki-style - preserve as-is)
    content = "[Config](config)"
    result = convert_text(content)
    assert result == "[Config](config)"  # Preserved
    
    # External link (should be preserved)
    content = "[Google](https://google.com)"
    result = convert_text(content)
    assert result == "[Google](https://google.com)"
    
    # Anchor link (should be preserved)
    content = "[Section](#section)"
    result = convert_text(content)
    assert result == "[Section](#section)"
    
    # Image link (should be preserved)
    content = "![diagram](_assets/diagram.png)"
    result = convert_text(content)
    assert result == "![diagram](_assets/diagram.png)"


def test_convert_embeds():
    """Test image embed conversion."""
    # Simple embed
    content = "Image: ![[diagram.png]]"
    result = convert_text(content)
    assert "![diagram.png](diagram.png)" in result
    
    # Embed with label
    content = "Image: ![[photo.jpg|My Photo]]"
    result = convert_text(content)
    assert "![My Photo](photo.jpg)" in result


def test_combined_conversion():
    """Test complete conversion with YAML, wikilinks, and markdown links."""
    content = """---
tags: [test]
status: active
---

# Test Document

Wikilink: [[simple_page]]
Markdown link: [Guide](docs/guide.md)
External: [GitHub](https://github.com)
Image: ![photo](_assets/photo.png)

Content."""
    
    result = convert_text(content)
    
    # YAML should be stripped
    assert "tags:" not in result
    assert "---" not in result
    
    # Wikilink should be converted
    assert "[simple_page](Simple-Page)" in result
    
    # Markdown link should be converted
    assert "[Guide](Guide)" in result
    
    # External link should be preserved
    assert "[GitHub](https://github.com)" in result
    
    # Image should be preserved
    assert "![photo](_assets/photo.png)" in result
    
    # Content should be present
    assert "# Test Document" in result
    assert "Content." in result


def test_convert_tree():
    """Test converting a directory tree."""
    with tempfile.TemporaryDirectory() as tmp_in, tempfile.TemporaryDirectory() as tmp_out:
        input_dir = Path(tmp_in)
        output_dir = Path(tmp_out)
        
        # Create test files
        test_file = input_dir / "test.md"
        test_file.write_text("""---
tags: [test]
---

# Test

Link to [[other_page]].
""")
        
        subdir = input_dir / "subdir"
        subdir.mkdir()
        subfile = subdir / "subfile.md"
        subfile.write_text("""# Subfile

Link to [Main](../test.md).
""")
        
        # Convert tree
        convert_tree(input_dir, output_dir)
        
        # Check output
        out_test = output_dir / "test.md"
        assert out_test.exists()
        content = out_test.read_text()
        assert "tags:" not in content
        assert "[other_page](Other-Page)" in content
        
        out_sub = output_dir / "subdir" / "subfile.md"
        assert out_sub.exists()
        sub_content = out_sub.read_text()
        assert "[Main](Test)" in sub_content


def run_all_tests():
    """Run all tests."""
    tests = [
        test_strip_yaml_frontmatter,
        test_wiki_slugify,
        test_convert_wikilinks,
        test_convert_markdown_links,
        test_convert_embeds,
        test_combined_conversion,
        test_convert_tree,
    ]
    
    for test in tests:
        try:
            test()
            print(f"✓ {test.__name__}")
        except AssertionError as e:
            print(f"✗ {test.__name__}: {e}")
            raise
    
    print(f"\n✅ All {len(tests)} tests passed!")


if __name__ == "__main__":
    run_all_tests()
