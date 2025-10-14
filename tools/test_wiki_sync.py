#!/usr/bin/env python3
"""
Test suite for wiki sync tools.

Run with: python3 -m pytest tools/test_wiki_sync.py -v
Or simply: python3 tools/test_wiki_sync.py
"""

import sys
from pathlib import Path

# Add tools directory to path
tools_dir = Path(__file__).parent
sys.path.insert(0, str(tools_dir))

from link_convert import path_to_wiki_name, get_file_mappings, convert_internal_links


def test_path_to_wiki_name():
    """Test file path to wiki name conversion."""
    tests = [
        ('project.md', 'project'),
        ('DIMOS_INTEGRATION.md', 'DIMOS-INTEGRATION'),
        ('deployment/wiki_sync.md', 'Deployment-wiki-sync'),
        ('sub/dir/file.md', 'Dir-file'),
        ('TEST_FILE.md', 'TEST-FILE'),
    ]
    
    for input_path, expected in tests:
        result = path_to_wiki_name(Path(input_path))
        assert result == expected, f"Failed: {input_path} -> {result}, expected {expected}"
        print(f"✓ {input_path} -> {result}")


def test_link_conversion():
    """Test markdown link conversion."""
    file_mappings = {
        'project.md': 'project',
        'DIMOS_INTEGRATION.md': 'DIMOS-INTEGRATION',
        'deployment/wiki_sync.md': 'Deployment-wiki-sync',
    }
    
    tests = [
        # Internal links
        ('[Project](project.md)', '[[Project|project]]'),
        ('[DIMOS](DIMOS_INTEGRATION.md)', '[[DIMOS|DIMOS-INTEGRATION]]'),
        
        # External links (should not change)
        ('[Google](https://google.com)', '[Google](https://google.com)'),
        ('[Email](mailto:test@test.com)', '[Email](mailto:test@test.com)'),
        
        # Anchors only (should not change)
        ('[Section](#section)', '[Section](#section)'),
    ]
    
    for input_text, expected in tests:
        result = convert_internal_links(input_text, file_mappings)
        assert result == expected, f"Failed: {input_text} -> {result}, expected {expected}"
        print(f"✓ {input_text} -> {result}")


def test_get_file_mappings():
    """Test file mappings from docs directory."""
    # Use actual docs directory from repo
    repo_root = Path(__file__).parent.parent
    docs_dir = repo_root / 'docs'
    
    if not docs_dir.exists():
        print("⚠ Skipping test_get_file_mappings - docs/ directory not found")
        return
    
    mappings = get_file_mappings(docs_dir)
    
    # Should find at least a few files
    assert len(mappings) > 0, "No files found in docs/"
    print(f"✓ Found {len(mappings)} documentation file mappings")
    
    # Check for expected files
    expected_files = ['project.md', 'DIMOS-INTEGRATION', 'DIMOS-CAPABILITIES']
    for expected in expected_files:
        found = any(expected in str(v) for v in mappings.values())
        if found:
            print(f"✓ Found expected file: {expected}")
        else:
            print(f"⚠ Expected file not found: {expected}")


def run_tests():
    """Run all tests."""
    print("=" * 60)
    print("Wiki Sync Tools - Test Suite")
    print("=" * 60)
    
    tests = [
        ("Path to wiki name conversion", test_path_to_wiki_name),
        ("Link conversion", test_link_conversion),
        ("File mappings", test_get_file_mappings),
    ]
    
    failed = []
    
    for test_name, test_func in tests:
        print(f"\n{test_name}:")
        print("-" * 40)
        try:
            test_func()
            print(f"✅ {test_name} passed")
        except AssertionError as e:
            print(f"❌ {test_name} failed: {e}")
            failed.append(test_name)
        except Exception as e:
            print(f"❌ {test_name} error: {e}")
            failed.append(test_name)
    
    print("\n" + "=" * 60)
    if failed:
        print(f"❌ {len(failed)} test(s) failed:")
        for name in failed:
            print(f"  - {name}")
        return 1
    else:
        print("✅ All tests passed!")
        return 0


if __name__ == '__main__':
    sys.exit(run_tests())
