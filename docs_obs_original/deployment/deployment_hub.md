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
- [[deployment/codex_environment_strategy|Codex Environment Strategy]] - Environment configuration approach
- [[deployment/codex_24_04_plan|Codex 24.04 Plan]] - Ubuntu 24.04 deployment planning

### Launch & Orchestration
- [[deployment/orchestrated_launch|Orchestrated Launch]] - Comprehensive launch system design
- [[deployment/orchestrated_launch_summary|Orchestrated Launch Summary]] - Quick reference for launch system

### Machine Setup
- [[deployment/laptop_setup|Laptop Setup]] - Development laptop configuration
- [[deployment/laptop_diagnostic|Laptop Diagnostic]] - Laptop troubleshooting and validation

### Synchronization
- [[deployment/deployment_sync|Deployment Sync]] - Syncing code across machines
- [[deployment/laptop_sync_after_conversion|Laptop Sync After Conversion]] - Post-migration sync procedures

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
- See [[software/configuration/environment_variables|Environment Variables Guide]]

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
- [[networking/networking_hub|Networking Hub]] - Network topology and configuration
- [[hardware/hardware_hub|Hardware Hub]] - Physical device setup
- [[software/software_hub|Software Hub]] - Software stack and packages
- [[troubleshooting/troubleshooting_hub|Troubleshooting Hub]] - Deployment diagnostics

## References
- [[deployment/deployment_hub|Documentation Root]]
- [[project_overview/project_overview_hub|Project Overview]] - Current status and planning
