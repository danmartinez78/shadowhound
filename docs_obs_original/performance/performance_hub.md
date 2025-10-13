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

- [[performance/performance_analysis_plan|Performance Analysis Plan]] - Comprehensive performance testing strategy

## Key Metrics

### LLM Backend Performance
- Response latency (vLLM vs Ollama vs cloud)
- Token throughput
- Memory usage
- See [[software/llm/llm_hub|LLM Integration Hub]]

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
- [[software/llm/llm_hub|LLM Integration]] - Backend performance tuning
- [[troubleshooting/troubleshooting_hub|Troubleshooting]] - Performance debugging
- [[software/software_hub|Software Hub]] - Software stack optimization

## References
- [[index|Documentation Root]]
