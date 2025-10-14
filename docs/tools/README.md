---
tags: [tools, documentation]
status: active
related: [obsidian/README.md]
summary: >
  Documentation and development tools for the ShadowHound project.
---

# Development Tools

This directory contains documentation for tools used in the ShadowHound development workflow.

## Available Tools

### [Obsidian Integration](obsidian/)

Optional graph view visualization of project documentation.

**Purpose**: Visual documentation navigation and exploration  
**Location**: `docs/tools/obsidian/`  
**Quick Start**: `./scripts/generate_obsidian_vault.sh`

**Features**:
- Graph view of documentation structure
- Color-coded directory groups
- Hub-based navigation
- Local graph for focused exploration

**Use Cases**:
- Understanding documentation structure
- Finding related documents
- Exploring new project areas
- Visualizing information architecture

See [obsidian/README.md](obsidian/) for complete documentation.

---

## Future Tools

This section will grow as additional development tools are documented:

- ROS2 autodoc generation
- Documentation linting
- Link checking
- Build and test automation
- _...more to come_

---

## Contributing

When adding a new tool to this directory:

1. Create a subdirectory: `docs/tools/<tool-name>/`
2. Add a README.md explaining the tool
3. Update this file with a summary
4. Follow the standard documentation front-matter format

## Structure

```
docs/tools/
├── README.md           # This file - tool index
└── obsidian/           # Obsidian graph view integration
    ├── README.md       # Overview and quick start
    ├── guide.md        # Complete usage guide
    ├── setup.md        # Manual configuration
    └── persistence.md  # Configuration persistence
```
