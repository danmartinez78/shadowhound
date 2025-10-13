---
tags: [deployment, operations, index]
status: active
related: []
summary: >
  Deployment guides, environment strategies, and launch orchestration for ShadowHound system.
aliases: [Deployment Hub, Operations]
---

# Deployment Documentation

Deployment strategies, environment configuration, and operational procedures for the ShadowHound system across development and production environments.

## Overview

This directory contains guides for deploying and operating ShadowHound across multiple machines (laptop, Thor/Jetson, GO2 robot) with different environment configurations.

## Documents

### Environment Strategy
- [Codex Environment Strategy](../deployment/codex_environment_strategy.md) - Environment configuration approach
- [Codex 24.04 Plan](../deployment/codex_24_04_plan.md) - Ubuntu 24.04 deployment planning

### Launch & Orchestration
- [Orchestrated Launch](../deployment/orchestrated_launch.md) - Comprehensive launch system design
- [Orchestrated Launch Summary](../deployment/orchestrated_launch_summary.md) - Quick reference for launch system

### Machine Setup
- [Laptop Setup](../deployment/laptop_setup.md) - Development laptop configuration
- [Laptop Diagnostic](../deployment/laptop_diagnostic.md) - Laptop troubleshooting and validation

### Synchronization
- [Deployment Sync](../deployment/deployment_sync.md) - Syncing code across machines
- [Laptop Sync After Conversion](../deployment/laptop_sync_after_conversion.md) - Post-migration sync procedures

## Deployment Topologies

### Development Mode
- **Laptop**: Development environment, web UI, mission planning
- **Connection**: Direct network to robot or simulation

### Production Mode
- **Laptop**: Web UI and monitoring
- **Thor (Jetson)**: vLLM backend, mission agent, ROS2 bridge
- **GO2 Robot**: Hardware platform
- **Connection**: WiFi mesh network

## Key Concepts

### Environment Variables
Critical configuration managed through `.env` files:
- `AGENT_BACKEND` - cloud vs local LLM
- `GO2_IP` - Robot IP address
- `ROS_DOMAIN_ID` - ROS2 network isolation
- See [Environment Variables Guide](../software/configuration/environment_variables.md)

### Launch Orchestration
The `start.sh` script provides unified deployment:
```bash
./start.sh --dev    # Development mode
./start.sh --prod   # Production mode
```

## Validation
- [ ] Environment variables documented and current
- [ ] Launch procedures tested on all target machines
- [ ] Sync procedures validated for code updates

## See Also
- [Networking Hub](../networking/networking_hub.md) - Network topology and configuration
- [Hardware Hub](../hardware/hardware_hub.md) - Physical device setup
- [Software Hub](../software/software_hub.md) - Software stack and packages
- [Troubleshooting Hub](../troubleshooting/troubleshooting_hub.md) - Deployment diagnostics

## References
- [Documentation Root](../deployment/deployment_hub.md)
- [Project Overview](../project_overview/project_overview_hub.md) - Current status and planning
