---
tags: [hardware, index]
status: draft
related: []
aliases: [Hardware Index]
summary: >
  Hardware documentation index covering sensors, compute, power distribution, and mechanical assemblies.
---

# Hardware Index

## Purpose
Provide a curated map of hardware documentation for the ShadowHound platform.

## Prerequisites
- Access to the hardware inventory and CAD repositories.
- Understanding of the ShadowHound bill of materials.

## Steps
1. Review the component summary to identify missing or outdated docs.
2. Create dedicated sub-pages using the template for detailed teardown or maintenance guides.
3. Link each hardware asset to calibration, firmware, and troubleshooting resources.

### Component Summary
- Chassis & mechanical integration
- Sensor payload (stereo, depth, thermal)
- Compute modules and power distribution
- Communications hardware (radios, LTE, Wi-Fi)

## Validation
- [ ] All critical hardware subsystems have at least one linked document.
- [ ] Media assets are stored under `_assets/` and referenced relatively.
- [ ] Links render correctly after conversion to public outputs.

## See Also
- [Network & Power Topologies](../hardware/network_power_topologies.md) — Comprehensive wiring configurations
- [360° Vision Options](../hardware/omni_vision_exploration.md) — Sensor research and comparison
- [Networking Documentation](../networking/networking_hub.md) — DDS and WebRTC connectivity
- [Troubleshooting Index](../troubleshooting/troubleshooting_hub.md) — Hardware diagnostic procedures

## References
- [Vault Index](../index.md)
- Hardware CAD (link when available)
- Supplier datasheets stored in `_assets/`
