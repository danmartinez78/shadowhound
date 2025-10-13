---
tags: [hardware, index]
status: draft
related: [hardware/network_power_topologies, hardware/omni_vision_exploration, hardware/omni_vision_sensor_setup]
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
- [[hardware/network_power_topologies|Network & Power Topologies]] — Comprehensive wiring configurations
- [[hardware/omni_vision_exploration|360° Vision Options]] — Sensor research and comparison
- [[networking/networking_hub|Networking Documentation]] — DDS and WebRTC connectivity
- [[troubleshooting/troubleshooting_hub|Troubleshooting Index]] — Hardware diagnostic procedures

## References
- [[../index|Vault Index]]
- Hardware CAD (link when available)
- Supplier datasheets stored in `_assets/`
