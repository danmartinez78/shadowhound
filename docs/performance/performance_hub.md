---
tags: [performance, testing, index]
status: active
related: []
summary: >
  Performance analysis, benchmarking, and optimization documentation.
aliases: [Performance Hub]
---

# Performance Documentation

Performance analysis, benchmarking, and system optimization guides for ShadowHound.

## Overview

This directory tracks performance characteristics, bottleneck analysis, and optimization strategies for the ShadowHound system.

## Documents

- [Performance Analysis Plan](../performance/performance_analysis_plan.md) - Comprehensive performance testing strategy

## Key Metrics

### LLM Backend Performance
- Response latency (vLLM vs Ollama vs cloud)
- Token throughput
- Memory usage
- See [LLM Integration Hub](../software/llm/llm_hub.md)

### Robot Control Performance
- Command execution latency
- Skill execution time
- ROS2 topic rates
- WebRTC stream quality

### System Resources
- CPU utilization (laptop, Thor, GO2)
- Memory consumption
- Network bandwidth
- Power consumption

## Validation
- [ ] Baseline performance metrics documented
- [ ] Bottlenecks identified and tracked
- [ ] Optimization efforts measured and validated

## See Also
- [LLM Integration](../software/llm/llm_hub.md) - Backend performance tuning
- [Troubleshooting](../troubleshooting/troubleshooting_hub.md) - Performance debugging
- [Software Hub](../software/software_hub.md) - Software stack optimization

## References
- [Documentation Root](index.md)
