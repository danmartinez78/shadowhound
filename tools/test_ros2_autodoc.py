#!/usr/bin/env python3
"""Tests for ros2_autodoc.py API extraction functionality."""

import ast
import tempfile
from pathlib import Path

# Import functions to test
from ros2_autodoc import (
    extract_function_signature,
    parse_class_info,
    parse_function_info,
    extract_module_api,
    format_docstring_section,
)


def test_extract_function_signature():
    """Test function signature extraction."""
    code = """
def test_func(x: int, y: str, *args, **kwargs) -> bool:
    pass
"""
    tree = ast.parse(code)
    func_node = tree.body[0]
    signature = extract_function_signature(func_node)
    assert "test_func" in signature
    assert "x: int" in signature
    assert "y: str" in signature
    assert "*args" in signature
    assert "**kwargs" in signature
    assert "-> bool" in signature


def test_parse_class_info():
    """Test class information extraction."""
    code = '''
class TestClass:
    """Test class docstring."""
    
    def public_method(self, param: str) -> None:
        """Public method."""
        pass
    
    def _private_method(self):
        """Private method - should be skipped."""
        pass
    
    def __init__(self):
        """Constructor - should be included."""
        pass
'''
    tree = ast.parse(code)
    class_node = tree.body[0]
    info = parse_class_info(class_node, code)
    
    assert info["name"] == "TestClass"
    assert info["docstring"] == "Test class docstring."
    assert len(info["methods"]) == 2  # public_method and __init__, not _private_method
    assert any(m["name"] == "public_method" for m in info["methods"])
    assert any(m["name"] == "__init__" for m in info["methods"])
    assert not any(m["name"] == "_private_method" for m in info["methods"])


def test_parse_function_info():
    """Test function information extraction."""
    code = '''
def my_function(x: int) -> str:
    """Function docstring."""
    return str(x)
'''
    tree = ast.parse(code)
    func_node = tree.body[0]
    info = parse_function_info(func_node)
    
    assert info["name"] == "my_function"
    assert "x: int" in info["signature"]
    assert "-> str" in info["signature"]
    assert info["docstring"] == "Function docstring."


def test_extract_module_api():
    """Test full module API extraction."""
    code = '''
"""Module docstring."""

class PublicClass:
    """Public class."""
    
    def method(self) -> None:
        """Method."""
        pass

class _PrivateClass:
    """Private class - should be skipped."""
    pass

def public_function() -> None:
    """Public function."""
    pass

def _private_function():
    """Private function - should be skipped."""
    pass
'''
    
    # Create a temporary file
    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
        f.write(code)
        temp_path = Path(f.name)
    
    try:
        api_info = extract_module_api(temp_path)
        
        assert api_info["module_docstring"] == "Module docstring."
        assert len(api_info["classes"]) == 1  # Only PublicClass
        assert len(api_info["functions"]) == 1  # Only public_function
        assert api_info["classes"][0]["name"] == "PublicClass"
        assert api_info["functions"][0]["name"] == "public_function"
    finally:
        temp_path.unlink()


def test_format_docstring_section():
    """Test docstring formatting."""
    docstring = """
    Short description.
    
    Args:
        param1: Description of param1
        param2: Description of param2
    
    Returns:
        Description of return value
    """
    
    lines = format_docstring_section(docstring)
    formatted = "\n".join(lines)
    
    assert "Short description" in formatted
    # Will vary based on docstring_parser availability, but should not crash
    assert len(lines) > 0


def test_api_extraction_error_handling():
    """Test that API extraction handles invalid Python gracefully."""
    # Create a temporary file with invalid Python
    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
        f.write("invalid python syntax @@@ {{{")
        temp_path = Path(f.name)
    
    try:
        api_info = extract_module_api(temp_path)
        
        # Should return error dict, not crash
        assert "error" in api_info
        assert api_info["classes"] == []
        assert api_info["functions"] == []
    finally:
        temp_path.unlink()


if __name__ == "__main__":
    # Run all tests
    test_extract_function_signature()
    test_parse_class_info()
    test_parse_function_info()
    test_extract_module_api()
    test_format_docstring_section()
    test_api_extraction_error_handling()
    
    print("✅ All tests passed!")
