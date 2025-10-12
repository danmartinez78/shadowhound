---
tags: [project, legacy]
status: draft
related: []
summary: >
  Legacy documentation preserved from earlier phases for review and migration.
---

# Variable Naming Conventions

## Purpose
Preserve historical context while signaling that this page requires verification against the current workflow.

## Prerequisites
- Review the legacy notes below to understand original assumptions and instructions.
- Cross-check commands and links with the latest tooling before execution.

## Steps
1. Read through the legacy notes captured under **Legacy Notes** and flag outdated guidance.
2. Update or replace the content with validated procedures as time permits.
3. Record verification outcomes in the validation checklist and mark follow-up tasks in the backlog.

### Legacy Notes
## Robot IP Address Variable

### History and Convention Conflict

**Date Discovered**: October 6, 2025

**Issue**: The DIMOS library (`dimos-unitree`) originally used `GO2_IP` as its convention for the robot IP address, which conflicts with the upstream `go2_ros2_sdk` convention of using `ROBOT_IP`.

### Root Cause

1. **go2_ros2_sdk** (upstream dependency): Uses `ROBOT_IP` as the primary environment variable
   - Location: `go2_robot_sdk/go2_robot_sdk/presentation/go2_driver_node.py`
   - Pattern: `os.getenv('ROBOT_IP', os.getenv('GO2_IP', ''))`
   - The SDK checks `ROBOT_IP` first, then falls back to `GO2_IP` for backward compatibility

2. **dimos-unitree** (our fork): Originally adopted `GO2_IP` as its convention
   - This created a naming conflict with the upstream SDK
   - Led to confusing behavior where scripts checked one variable but used another

3. **shadowhound** (our application): Initially followed DIMOS convention (`GO2_IP`)
   - This propagated the conflict throughout our codebase
   - Resulted in misleading warnings (e.g., "ROBOT_IP not set" when using `GO2_IP`)

### Resolution (October 6, 2025)

**Decision**: Standardize on `ROBOT_IP` throughout the shadowhound codebase to align with the upstream `go2_ros2_sdk` convention.

**Rationale**:
- `ROBOT_IP` is the primary convention in the upstream SDK
- Aligns with ROS2 ecosystem standards
- Reduces confusion and maintenance burden
- SDK already has backward compatibility fallback for `GO2_IP`

**Implementation**: Commit `8a6e47e` on `feature/dimos-integration` branch
- Updated 12 files across the shadowhound workspace
- Replaced all `GO2_IP` references with `ROBOT_IP`
- External `dimos-unitree` SDK maintains backward compatibility

### Current State

✅ **shadowhound workspace**: Uses `ROBOT_IP` exclusively
✅ **go2_ros2_sdk**: Uses `ROBOT_IP` as primary, `GO2_IP` as fallback
⚠️ **dimos-unitree**: May still reference `GO2_IP` in some places (has fallback logic)

### Future Considerations

**If this bites us later, check:**

1. **Environment Variable Priority**:
   ```python
   # SDK checks in this order:
   robot_ip = os.getenv('ROBOT_IP', os.getenv('GO2_IP', ''))
   ```
   - If both are set, `ROBOT_IP` takes precedence
   - If only `GO2_IP` is set, SDK will still work (fallback)

2. **DIMOS Updates**: If updating `dimos-unitree` dependency:
   - Check if they've standardized on a different convention
   - Verify our `ROBOT_IP` usage still works
   - Look for any new environment variables related to robot connection

3. **Documentation**: If seeing confusing behavior:
   - Check if old docs/scripts are using `GO2_IP`
   - Verify `.env` files use `ROBOT_IP`
   - Confirm `start.sh` exports `ROBOT_IP` correctly

4. **Testing**: When testing robot connection:
   ```bash
   # Check what's actually being used:
   echo "ROBOT_IP: $ROBOT_IP"
   echo "GO2_IP: $GO2_IP"  # Should be unset in shadowhound
   
   # Verify SDK sees it:
   ros2 param get /go2_driver robot_ip
   ```

5. **External Scripts**: If integrating third-party tools:
   - They may expect `GO2_IP` (older convention)
   - Add translation layer if needed:
     ```bash
     export GO2_IP=${ROBOT_IP}  # For backward compat
     ```

### Related Files

**Key locations where ROBOT_IP is used:**

1. **Environment Files**:
   - `.env.development`
   - `.env.production`
   - `.env.example`
   - `.env.webrtc_test`

2. **Startup Scripts**:
   - `start.sh` (5 locations)
   - `source_shadowhound.sh`

3. **Launch Files**:
   - `launch/go2_sdk/robot_minimal.launch.py`
   - `launch/go2_sdk/robot_python_lidar.launch.py`
   - `launch/shadowhound_full.launch.py`

4. **Test Scripts**:
   - `test_topic_visibility.sh`
   - `scripts/test_webrtc_direct.sh`
   - `scripts/setup_webrtc_test.sh`

5. **External SDK** (maintains fallback):
   - `src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk/go2_robot_sdk/presentation/go2_driver_node.py`
   - `src/dimos-unitree/dimos/robot/unitree/external/go2_ros2_sdk/go2_robot_sdk/launch/webrtc_web.launch.py`

### Lessons Learned

1. **Convention Alignment**: When using external libraries, prefer their conventions over inventing our own
2. **Upstream First**: Check upstream conventions before forking/extending
3. **Document Conflicts**: When conflicts arise, document them immediately (like this!)
4. **Graceful Migration**: Use fallback patterns during transitions (SDK's approach is good)
5. **Systematic Updates**: Update all references at once to avoid partial migration states

### Additional Notes

- The SDK's backward compatibility pattern is good practice:
  ```python
  value = os.getenv('NEW_NAME', os.getenv('OLD_NAME', 'default'))
  ```
- Consider this pattern if we need to rename variables in the future
- This conflict was subtle because both variables work - just confusing warnings

---

**Last Updated**: October 6, 2025  
**Status**: ✅ Resolved - Standardized on ROBOT_IP  
**Risk Level**: 🟡 Low (documented, backward compat exists)  
**Action Required**: None - just be aware when updating dependencies


## Validation
- [ ] Legacy guidance reviewed for accuracy and converted to the new workflow where applicable.
- [ ] Links updated to use vault-friendly wikilinks or confirmed for external references.
- [ ] Outstanding migration work captured as tasks in the backlog.

## References
- [Knowledge Base Index](index.md)
