---
tags: [project, legacy]
status: draft
related: []
summary: >
  Legacy documentation preserved from earlier phases for review and migration.
---

# GitHub Copilot CLI Setup

## Purpose
Preserve historical context while signaling that this page requires verification against the current workflow.

## Prerequisites
- Review the legacy notes below to understand original assumptions and instructions.
- Cross-check commands and links with the latest tooling before execution.

## Steps
1. Read through the legacy notes captured under **Legacy Notes** and flag outdated guidance.
2. Update or replace the content with validated procedures as time permits.
3. Record verification outcomes in the validation checklist and mark follow-up tasks in the backlog.

### Legacy Notes
GitHub Copilot CLI is now installed and configured on this system.

## Installation Summary

- **Installed**: GitHub CLI (`gh`) version 2.81.0
- **Extension**: `github/gh-copilot` version 1.1.1
- **Authentication**: Logged in as `danmartinez78`
- **Shell**: Bash aliases configured

## Available Commands

### Quick Commands (Aliases)

```bash
# Ask Copilot to suggest a shell command
ghcs "what you want to do"

# Ask Copilot to explain a command
ghce <command>

# Examples:
ghcs "find all large files over 100MB"
ghcs "compress all images in this directory"
ghce "tar -xzf file.tar.gz"
```

### Full Interface

```bash
# Interactive Copilot CLI
gh copilot

# Direct command suggestions
gh copilot suggest "your question"

# Explain a command
gh copilot explain "command to explain"
```

## Usage Examples

### Get Command Suggestions

```bash
$ ghcs "find all python files modified today"
Suggestion: find . -name "*.py" -mtime 0
? Select an option
> Execute command
> Revise command
> Rate response
> Copy command
> Explain command
> Exit
```

### Explain Complex Commands

```bash
$ ghce "tar -xzf archive.tar.gz"
# Copilot explains what each flag does
```

### Git Operations

```bash
ghcs "show me the diff of unstaged changes"
ghcs "commit all changes with a descriptive message"
ghcs "create a new branch from current branch"
```

### ROS2 Operations

```bash
ghcs "list all active ROS2 nodes"
ghcs "echo a ROS2 topic and show the message type"
ghcs "build only the shadowhound_mission_agent package"
```

### File Operations

```bash
ghcs "find all markdown files and count lines"
ghcs "recursively change permissions of all python files"
ghcs "copy all launch files to a backup directory"
```

## Tips

1. **Be Specific**: The more specific your question, the better the suggestion
   - ❌ "find files"
   - ✅ "find all .py files modified in the last week"

2. **Natural Language**: Write like you're asking a person
   - "show me all running docker containers"
   - "what processes are using port 8080"

3. **Review Before Executing**: Always review suggested commands before executing
   - Commands can modify files or system state
   - Verify paths and arguments are correct

4. **Iterate**: If the first suggestion isn't perfect, select "Revise command"

5. **Learn**: Use "Explain command" to understand what complex commands do

## Configuration

Aliases are configured in `~/.bashrc`:

```bash
# View the alias definitions
grep -A 10 "gh copilot alias" ~/.bashrc
```

To reload aliases in current shell:
```bash
source ~/.bashrc
```

## Privacy

- GitHub Copilot CLI sends your queries to GitHub's AI service
- Usage data collection is **enabled** (opted in during setup)
- Commands are processed by AI but are not stored permanently
- See: https://gh.io/gh-copilot-transparency

To opt out of usage data:
```bash
gh copilot config set optout true
```

## Troubleshooting

### Command Not Found

If `ghcs` or `ghce` not found:
```bash
source ~/.bashrc
```

### Authentication Issues

If authentication expires:
```bash
gh auth login
```

### Extension Issues

Reinstall the extension:
```bash
gh extension remove github/gh-copilot
gh extension install github/gh-copilot
```

### Check Version

```bash
gh --version
gh extension list
```

## Resources

- [GitHub CLI Docs](https://cli.github.com/manual/)
- [Copilot CLI Guide](https://docs.github.com/en/copilot/github-copilot-in-the-cli)
- [Copilot Transparency](https://gh.io/gh-copilot-transparency)

---

**Quick Test**: Try `ghcs "list all files in current directory by size"`


## Validation
- [ ] Legacy guidance reviewed for accuracy and converted to the new workflow where applicable.
- [ ] Links updated to use vault-friendly wikilinks or confirmed for external references.
- [ ] Outstanding migration work captured as tasks in the backlog.

## References
- [Knowledge Base Index](../history/history_hub.md)
