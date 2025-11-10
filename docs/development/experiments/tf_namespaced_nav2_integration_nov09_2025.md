---
tags: [navigation, tf, multi-robot]
status: draft
related: []
summary: >
  Experiment to switch from global TF topics with namespaced frames to fully namespaced TF topics per robot and simplify Nav2 configs.
---

# Namespaced TF Nav2 Integration (Nov 09 2025)

## Context
Current simulation autonomy stack uses global `/tf` and `/tf_static` topics with frame IDs prefixed (e.g. `robot0/base_link`). We applied complex `RewrittenYaml` frame rewrites to inject namespaced frames into Nav2 while keeping TF global. Persistent issue: local costmap failing to register `observation_sources` consistently; rewrites clobber plugin sections in `sim_autonomy.launch.py`.

## Hypothesis
Eliminating global TF and instead launching each robot's Nav2 stack under its own ROS namespace (including TF topics) will:
- Remove need for frame ID prefix rewrites (`base_link`, `odom`, `map` become local to namespace)
- Simplify Nav2 param files (no double-key duplication nor RewrittenYaml surgery)
- Prevent parameter collision or plugin list corruption causing missing `local_costmap` sensor source
- Improve clarity for multi-robot isolation (each robot's TF tree self-contained under `/robotN/tf`).

## Proposed Changes
1. New Nav2 param file `nav2_params_namespaced.yaml` with frames unprefixed (`map`, `odom`, `base_link`), costmaps using standard example structure from Nav2 docs.
2. `sim_autonomy.launch.py` updates:
   - Set `namespace:=<robot_namespace>` and `use_namespace:=true` in nav2 bringup include.
   - Remove `RewrittenYaml` frame rewrites; pass param file directly.
   - Drop `PushRosNamespace` and explicit TF global remaps so `tf` topics become namespaced automatically.
   - Keep scan topic relative (`scan`) so resolves to `/<ns>/scan`.
3. Pointcloud to laserscan node: remove remaps forcing `tf` global.
4. Adjust SLAM & AMCL (future) to accept local frames and namespaced TF; for SLAM node we keep namespace and do not remap `tf`.
5. Provide issue text for Isaac Sim fork requesting per-robot TF topic publication; until upstream supports, Nav2 will maintain its own namespaced TF while sim still publishes global—short-term we may ignore sim TF or bridge.

## Risks / Mitigations
| Risk | Mitigation |
|------|------------|
| Some tools (RViz default config) expect global `/tf` | Update RViz config to use robot-specific fixed frame and subscribe to namespaced `/robotN/tf` automatically. |
| Isaac Sim publishes global TF; double trees conflict | Optionally ignore sim TF by filtering frames or disable robot_state_publisher if redundant. |
| Multi-robot inter-operation needing shared global frame | Provide a future TF aggregator converting namespaced trees to global for cross-robot planning if required. |
| AMCL / SLAM assumptions about frame IDs | Frames unchanged (map/odom/base_link) so internal logic unaffected; only topic namespace changes. |

## Success Criteria
- `ros2 param get /robot0/local_costmap local_costmap.obstacle_layer.observation_sources` returns `scan` (or voxel layer equivalent) without manual rewrites.
- Local costmap node transitions to `active` without warnings about missing observation sources.
- `/robot0/local_costmap/costmap` publishes and reflects laser obstacles.
- TF topics appear as `/robot0/tf` and `/robot0/tf_static`; no transforms from Nav2 stack appear on global `/tf`.

## Experiment Steps
1. Implement new param file and launch refactor.
2. Build & launch simulation autonomy stack with Isaac Sim (keeping laser scan source under namespace).
3. Observe costmap logs; collect before/after diff (copy key log lines).
4. Validate RViz visualization (namespaced costmaps + TF tree).
5. Document outcome.

## Metrics to Capture
- Time from launch to costmap activation.
- Presence/absence of warning lines containing `observation_sources`.
- Count of topics under `/robot0/*` vs global.
- TF tree PDF size (optional with `tf2_tools view_frames`).

## Results (Pending)
(To be filled after execution)

## Conclusion (Pending)
(To be filled after execution)

## Follow-Up
- If successful: deprecate previous simulation parameter files (`nav2_params_simulation.yaml`) or retain with note.
- If unsuccessful: revert launch changes and consider alternative (keep global TF but generate clean params without rewrites).
