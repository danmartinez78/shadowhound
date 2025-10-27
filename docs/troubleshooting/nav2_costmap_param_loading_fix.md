# Nav2 Costmap Parameter Loading Fix

**Date**: October 27, 2025  
**Issue**: Costmap nodes loading default unprefixed frame IDs (`odom`, `base_link`) instead of robot0-prefixed IDs  
**Root Cause**: Nav2 versions differ on YAML parameter key structure  

## Problem Diagnosis

**Symptoms**:
```
[controller_server]: Could not transform from base_link to odom
ros2 param get /robot0/local_costmap/local_costmap global_frame
  → String value is: odom  (❌ should be robot0/odom)
```

**TF Tree Status**: ✅ Correct
```bash
ros2 run tf2_ros tf2_echo robot0/odom robot0/base_link
# Works! Transform available at ~38 Hz from Isaac Sim
```

**Conclusion**: TF tree is fine. Parameters aren't loading into costmap nodes.

## Root Cause: YAML Key Structure Mismatch

Nav2 releases differ on whether costmap nodes read parameters at:
- **Single-key**: `local_costmap.ros__parameters`
- **Double-key**: `local_costmap.local_costmap.ros__parameters`

Our YAML only had the double-key variant. If your Nav2 build expects single-key, parameters default to unprefixed `odom` and `base_link`.

## Solution: Include Both Variants

Added redundant parameter blocks at both key levels:

```yaml
# Single-key variant (some Nav2 builds)
local_costmap:
  ros__parameters:
    global_frame: robot0/odom
    robot_base_frame: robot0/base_link
    # ... all other params

# Double-key variant (other Nav2 builds)  
local_costmap:
  local_costmap:
    ros__parameters:
      global_frame: robot0/odom
      robot_base_frame: robot0/base_link
      # ... all other params
```

Same approach for `global_costmap`.

## Testing Approaches

### Quick Test (Live Parameter Setting)
While `test_autonomy.sh` is running:
```bash
./scripts/fix_costmap_params_live.sh
```
This sets frame IDs live without restarting. If controller warnings stop, we've confirmed the issue.

### Permanent Fix (Restart with Updated YAML)
```bash
# Kill test_autonomy.sh
git pull  # Get commit 0d295d1
colcon build --packages-select shadowhound_bringup
./test_autonomy.sh  # Restart with updated YAML
./scripts/verify_nav2_params.sh  # Verify all parameters loaded
```

## Verification

Check that frame IDs loaded correctly:
```bash
ros2 param get /robot0/local_costmap/local_costmap global_frame
# Should show: robot0/odom (not 'odom')

ros2 param get /robot0/local_costmap/local_costmap robot_base_frame  
# Should show: robot0/base_link (not 'base_link')

ros2 param get /robot0/controller_server robot_base_frame
# Should show: robot0/base_link

ros2 param get /robot0/controller_server odom_frame
# Should show: robot0/odom
```

## Related Commits

- `65d5d00`: ChatGPT's namespace alignment (robot0 everywhere)
- `14bd34d`: Added controller_server frame IDs (robot_base_frame, odom_frame)
- `3d52420`: Created verify_nav2_params.sh script
- `0d295d1`: **THIS FIX** - Added single-key costmap params for compatibility
- `7176131`: Created fix_costmap_params_live.sh for quick testing

## Historical Context

This was the 16th configuration attempt to fix Nav2 TF frame issues. Previous attempts focused on:
- Namespace configuration (`use_namespace` true/false)
- Frame ID format (relative vs absolute)
- Launch file structure (GroupAction, PushRosNamespace)

The breakthrough came from ChatGPT identifying:
1. Namespace mismatch between components (Phase 1 fix)
2. Missing controller_server frame params (Phase 2 fix)
3. **YAML key structure mismatch** (Phase 3 fix - THIS)

## Key Lessons

1. **Check what parameters are ACTUALLY loaded**: `ros2 param get` is critical
2. **Nav2 versions differ**: Always include both single-key and double-key param structures
3. **TF being correct ≠ parameters loaded**: Separate issues
4. **Live parameter setting confirms root cause**: Fast way to test before restarting

## Future Improvements

Consider using `robot0/map` as global frame instead of `robot0/odom` for:
- `global_costmap.global_frame`
- `AMCL.global_frame_id`

This follows canonical ROS2 frame chain: `map → odom → base_link`
