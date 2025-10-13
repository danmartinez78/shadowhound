---
tags: [development, docs]
status: draft
related: []
summary: >
  Pull request checklist for documentation-only changes to ensure consistency, navigation, and link integrity.
---

# PR Checklist: Docs Cleanup

Use this checklist when submitting documentation-only changes.

## Scope
- [ ] This PR contains only documentation edits (no code/build changes)
- [ ] Changes are limited to the directories described in the PR description

## Standards
- [ ] Front-matter present on all Markdown files (tags, status, related, summary)
- [ ] Page structure follows: Purpose, Prerequisites, Steps, Validation, References
- [ ] Obsidian wikilinks used consistently; aliases added when they reduce ambiguity

## Canonical Sources
- [ ] Networking pages align with Hardware Network & Power Topologies
- [ ] No duplicated procedures across directories; links point to canonical guides

## Environment Policy
- [ ] Documentation avoids bespoke `.env.webrtc_test` and `.shadowhound_env`
- [ ] Note: Leave existing `.env*` files in repo root untouched for now (do not modify/move)

## Navigation & Links
- [ ] `mkdocs.yml` updated when new index pages are added
- [ ] `tools/validate_wikilinks.py --docs docs` returns 0 broken links

## Summary
- [ ] PR description lists key files changed and any redirects or deprecations
- [ ] Screenshots/diagrams (if any) added to `docs/_assets/`
