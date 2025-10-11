---
tags: [networking, index]
status: draft
related: []
summary: >
  Networking documentation index for connectivity, telemetry, and remote operations.
---

# Networking Index

## Purpose
Catalog networking guides for remote teleoperation, telemetry streaming, and secure infrastructure.

## Prerequisites
- Access to network configuration credentials.
- Familiarity with VPN, VLAN, and ROS 2 discovery concepts.

## Steps
1. Document each networking environment (lab, field, cloud relay) with diagrams and configs.
2. Use `_assets/` for topology diagrams and link them via relative paths.
3. Verify all IP ranges and credentials are stored in secure vaults, not inline Markdown.

### Featured Guides
- [[networking/webrtc_direct_test|WebRTC Direct Test]]

## Validation
- [ ] Each environment has a validated connection checklist.
- [ ] Sensitive secrets are stored outside of the repo.
- [ ] Converted Markdown renders without Obsidian-only syntax.

## References
- [[index|Vault Index]]
- [[software/README|Software Index]]
- Network monitoring dashboards (link when available)
