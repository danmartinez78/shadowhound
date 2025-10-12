---
tags: [development, docs]
status: draft
related: [project_overview/status_2025-10-12]
summary: >
  Checklist and order of operations to review each docs directory for consistency and navigation.
---

# Per-Directory Review Plan

## Purpose
Define the order and checks to validate documentation consistency after the reorg.

## Order
1. `networking/`
2. `troubleshooting/`
3. `development/`
4. `software/llm/`
5. `project_overview/`
6. `performance/`
7. `policies/`
8. `issues/`

## Checks
- Index/README present with short purpose and links
- No obvious duplicates; redirects used when needed
- Wikilinks resolve within vault
- References to scripts match paths under `scripts/`
- Outbound references to DIMOS/go2 SDK are accurate

## Validation
- [ ] Networking index links to both DDS and WebRTC tests
- [ ] Troubleshooting links back to Networking where appropriate
- [ ] Development contains handoff/status guides
- [ ] LLM docs unchanged functionally after move
- [ ] Project overview reflects current branch and status
