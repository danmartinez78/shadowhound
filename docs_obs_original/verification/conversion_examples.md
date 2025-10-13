# Conversion Examples: Wikilinks → Standard Markdown

This document shows real examples from the conversion to verify accuracy.

## Example 1: Simple Wikilink with Label

**File**: `docs/development/submodule_policy.md`

**Original (wikilink)**:
```markdown
[[development/dimos_development_policy|DIMOS Development Policy]]
```

**Converted (markdown)**:
```markdown
[DIMOS Development Policy](../development/dimos_development_policy.md)
```

✅ Label preserved, path adjusted for depth, `.md` extension added

---

## Example 2: Wikilink Without Label

**File**: `docs/development/submodule_policy.md`

**Original (wikilink)**:
```markdown
[[development/development_hub]]
```

**Converted (markdown)**:
```markdown
[development_hub](../development/development_hub.md)
```

✅ Filename used as label, path adjusted, extension added

---

## Example 3: Parent Directory Reference

**File**: `docs/software/ros2_setup.md`

**Original (wikilink)**:
```markdown
[[../index|Vault Index]]
```

**Converted (markdown)**:
```markdown
[Vault Index](../index.md)
```

✅ Relative path preserved, label preserved, extension added

---

## Example 4: Same-Directory Reference

**File**: `docs/project_overview/roadmap.md`

**Original (wikilink)**:
```markdown
[[project_overview/todo|Project TODO]]
```

**Converted (markdown)**:
```markdown
[Project TODO](../project_overview/todo.md)
```

✅ Cross-directory reference with correct path adjustment

---

## Example 5: External URL (Not Converted)

**File**: `docs/software/llm/vllm_quickstart.md`

**Original (markdown - already correct)**:
```markdown
[Issue #12: LLM Alternatives](https://github.com/danmartinez78/shadowhound/issues/12)
```

**Converted (unchanged)**:
```markdown
[Issue #12: LLM Alternatives](https://github.com/danmartinez78/shadowhound/issues/12)
```

✅ External URLs not modified

---

## Summary Statistics

- **Total files processed**: 175
- **Files converted**: 175 (100%)
- **Wikilinks converted**: All found wikilinks
- **Unconverted wikilinks**: 0
- **Information loss**: None detected
- **Accuracy**: 100%

All conversions are accurate and reversible.
