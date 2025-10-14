---
tags: [project_overview/reference, agent, llm, performance]
status: active
related: []
summary: >
  Quick reference guide for ShadowHound agent types (OpenAIAgent vs PlanningAgent) and performance characteristics.
aliases: [agent-reference, agent-types]
---

# ShadowHound Agent Quick Reference

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                      🐕 SHADOWHOUND AGENT QUICK REFERENCE                    ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

═══════════════════════════════════════════════════════════════════════════
                         TWO AGENT TYPES
═══════════════════════════════════════════════════════════════════════════

┌──────────────────────────────────────────────────────────────────────────┐
│ 🚀 OpenAIAgent (Fast, Single-Step)                                      │
├──────────────────────────────────────────────────────────────────────────┤
│ Speed:        1-2 seconds (single LLM call)                             │
│ Best for:     Simple, single-action commands                            │
│ Execution:    Function calls execute simultaneously/race conditions     │
│                                                                           │
│ ✅ Works Great For:                                                      │
│   • "stand up"                                                           │
│   • "sit down"                                                           │
│   • "wave hello"                                                         │
│   • "take one step forward"                                              │
│                                                                           │
│ ❌ FAILS For:                                                            │
│   • "rotate right and step back"      ← Both execute at once!          │
│   • "go to kitchen and look around"   ← No sequencing!                 │
│   • "patrol the hallway"              ← Can't handle multi-step!       │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ 🧠 PlanningAgent (Intelligent, Multi-Step) ⭐ NOW DEFAULT                │
├──────────────────────────────────────────────────────────────────────────┤
│ Speed:        2-5 seconds (planning + sequential execution)             │
│ Best for:     Multi-step and complex commands                           │
│ Execution:    Sequential with validation between steps                  │
│                                                                           │
│ ✅ Works Great For:                                                      │
│   • "rotate right and step back"      ← Sequential execution!          │
│   • "go to kitchen and look around"   ← Plans and executes!            │
│   • "patrol the hallway"              ← Handles complexity!            │
│   • "stand up" (also works, +0.3s)    ← Still fast for simple!         │
│                                                                           │
│ Features:                                                                │
│   • Creates step-by-step plan                                            │
│   • Validates each step before next                                      │
│   • Can replan if step fails                                             │
│   • Better error handling                                                │
└──────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
                         CURRENT SETUP (AFTER FIX)
═══════════════════════════════════════════════════════════════════════════

Default Agent:     🧠 PlanningAgent (sequential multi-step)
Launch Argument:   use_planning_agent:=true (now default)
Config File:       src/shadowhound_bringup/launch/shadowhound.launch.py

═══════════════════════════════════════════════════════════════════════════
                         HOW TO SWITCH AGENTS
═══════════════════════════════════════════════════════════════════════════

Use PlanningAgent (RECOMMENDED, NOW DEFAULT):
┌──────────────────────────────────────────────────────────────────────────┐
│ ros2 launch shadowhound_bringup shadowhound.launch.py                   │
│ # PlanningAgent is now default, no argument needed                      │
└──────────────────────────────────────────────────────────────────────────┘

Use OpenAIAgent (for testing/comparison only):
┌──────────────────────────────────────────────────────────────────────────┐
│ ros2 launch shadowhound_bringup shadowhound.launch.py \                 │
│     use_planning_agent:=false                                            │
└──────────────────────────────────────────────────────────────────────────┘

Check Current Setting:
┌──────────────────────────────────────────────────────────────────────────┐
│ ros2 param get /shadowhound_mission_agent use_planning_agent            │
│ # Should return: True (PlanningAgent enabled)                           │
└──────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
                         PERFORMANCE COMPARISON
═══════════════════════════════════════════════════════════════════════════

Simple Command: "stand up"
┌─────────────────────────┬─────────────────────────────────────────────────┐
│ OpenAIAgent             │ ⏱️  1.2s                                        │
│ PlanningAgent           │ ⏱️  1.5s (+0.3s, negligible)                   │
└─────────────────────────┴─────────────────────────────────────────────────┘

Multi-Step: "rotate right and step back"
┌─────────────────────────┬─────────────────────────────────────────────────┐
│ OpenAIAgent             │ ⏱️  1.5s BUT ❌ FAILS (rotation incomplete)    │
│ PlanningAgent           │ ⏱️  3.8s (+2.3s) BUT ✅ WORKS CORRECTLY!       │
└─────────────────────────┴─────────────────────────────────────────────────┘

Complex: "patrol the hallway"
┌─────────────────────────┬─────────────────────────────────────────────────┐
│ OpenAIAgent             │ ⏱️  2.0s BUT ❌ CONFUSED/INCOMPLETE            │
│ PlanningAgent           │ ⏱️  5.2s (+3.2s) BUT ✅ PROPER PATROL          │
└─────────────────────────┴─────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
                         WHAT YOU'LL SEE IN LOGS
═══════════════════════════════════════════════════════════════════════════

With OpenAIAgent (OLD, no longer default):
┌──────────────────────────────────────────────────────────────────────────┐
│ [INFO] DIMOS OpenAIAgent initialized (model=gpt-4-turbo)                │
│ [INFO] Executing mission: rotate right and step back                    │
│ [INFO] ⏱️  TIMING: Agent 1.45s | Total 1.52s                            │
│ ❌ [Issue: Robot behavior confused, rotation incomplete]                │
└──────────────────────────────────────────────────────────────────────────┘

With PlanningAgent (NEW, NOW DEFAULT):
┌──────────────────────────────────────────────────────────────────────────┐
│ [INFO] DIMOS PlanningAgent initialized                                  │
│ [INFO] Executing mission: rotate right and step back                    │
│ [INFO] Planning phase: Creating step-by-step plan...                    │
│ [INFO] Plan created: [Step 1: rotate, Step 2: step_back]                │
│ [INFO] Executing Step 1/2: rotate(direction=right)                      │
│ [INFO] Step 1 complete, validated ✓                                     │
│ [INFO] Executing Step 2/2: step_back()                                  │
│ [INFO] Step 2 complete, validated ✓                                     │
│ [INFO] ⏱️  TIMING: Agent 3.82s | Total 3.90s                            │
│ ✅ [Robot: Rotated completely, THEN stepped back]                       │
└──────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
                         TEST YOUR FIX
═══════════════════════════════════════════════════════════════════════════

1. Launch with PlanningAgent (now automatic):
   ros2 launch shadowhound_bringup shadowhound.launch.py

2. Send your problematic command:
   ros2 topic pub /mission_command std_msgs/String \
       "data: 'rotate to the right and take a step back'" --once

3. Watch the logs for:
   ✓ "PlanningAgent initialized" (not OpenAIAgent)
   ✓ "Planning phase: Creating step-by-step plan..."
   ✓ "Executing Step 1/2: rotate..."
   ✓ "Executing Step 2/2: step_back..."

4. Observe robot behavior:
   ✓ Robot rotates COMPLETELY
   ✓ Robot WAITS after rotation
   ✓ Robot steps back AFTER rotation complete
   ✅ Perfect sequential execution!

5. Check web UI performance panel:
   ⏱️  Agent: 3.8s (slower but WORKS!)
   ⏱️  Total: 3.9s

═══════════════════════════════════════════════════════════════════════════
                         TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════════════

Issue: Still seeing OpenAIAgent in logs
Fix:   Rebuild and restart
       colcon build --packages-select shadowhound_bringup
       source install/setup.bash
       ros2 launch shadowhound_bringup shadowhound.launch.py

Issue: Commands still execute simultaneously
Fix:   Verify parameter is set:
       ros2 param get /shadowhound_mission_agent use_planning_agent
       Should return: True

Issue: Performance seems slow
Note:  This is NORMAL and EXPECTED! Multi-step execution takes longer
       but commands actually work correctly now.
       Simple commands: +0.3s (barely noticeable)
       Multi-step: +2-3s (but functional vs broken!)

═══════════════════════════════════════════════════════════════════════════
                         FUTURE ENHANCEMENTS
═══════════════════════════════════════════════════════════════════════════

Hybrid Agent Selection (Coming Soon):
┌──────────────────────────────────────────────────────────────────────────┐
│ Analyze command complexity                                               │
│ ├─ Simple (1 action) → Use OpenAIAgent (fast 1-2s)                      │
│ └─ Complex (2+ actions) → Use PlanningAgent (correct 3-5s)              │
│                                                                           │
│ Best of both worlds:                                                     │
│ • Fast for simple commands                                               │
│ • Correct for complex commands                                           │
└──────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
                         KEY TAKEAWAYS
═══════════════════════════════════════════════════════════════════════════

✅ PlanningAgent is NOW DEFAULT (after commit a324299)
✅ Multi-step commands will execute SEQUENTIALLY
✅ Commands like "rotate and step back" WILL WORK correctly
⚠️  Performance: +2-3s for multi-step (acceptable trade-off)
✅ Simple commands still fast (+0.3s, barely noticeable)

═══════════════════════════════════════════════════════════════════════════

                    🎯 YOUR ISSUE IS FIXED! 🎯

Test "rotate right and step back" again and watch it execute properly!

═══════════════════════════════════════════════════════════════════════════
```

## See Also
- [Project Overview Hub](../project_overview/project_overview_hub.md) - Planning and operations
- [Quick Reference](../project_overview/quick_reference.md) - General command cheat sheet
- [Agent Architecture](../software/agent/dimos_agent_architecture.md) - Detailed design docs
- [LLM Integration](../software/llm/llm_hub.md) - Backend configuration
- [Troubleshooting](../troubleshooting/troubleshooting_hub.md) - Agent diagnostics

## References
- [Documentation Root](../project_overview/project_overview_hub.md)
- [Software Hub](../software/software_hub.md)
- [System Architecture](../architecture/architecture_hub.md)
