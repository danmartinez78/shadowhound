---
tags: [software, skills, dimos, implementation]
status: active
related: [mvp_embodied_ai_platform.md, dimos_integration.md]
summary: >
  Inventory of DIMOS skills: current state, known issues, and candidate skills for future implementation
---

# Skills Inventory

## Purpose
Document the current state of DIMOS skills on ShadowHound, track which skills are functional vs blocked, and maintain a list of candidate skills identified during planning.

**Last Updated**: 2025-10-14  
**Current Status**: Limited skill set due to WebRTC API blocker

---

## Current State

### ⚠️ **Critical Blocker: WebRTC API Issues**

**Problem**: Majority of DIMOS MyUnitreeSkills use the WebRTC API directly and are currently non-functional. This significantly limits available robot behaviors.

**Impact**: Working with a limited set of non-WebRTC skills until:
1. WebRTC API is fixed/debugged, OR
2. Custom Nav2-based skills are implemented as alternatives

### ✅ **Known Working Skills**

*(This section needs to be populated based on actual testing)*

**Skills verified to work on hardware**:
- *TBD - needs hardware validation*

**Skills verified to work in simulation/dev**:
- *TBD - needs testing*

### ❌ **Known Non-Working Skills**

**Blocked by WebRTC API** (from DIMOS MyUnitreeSkills):
- Most navigation skills that use WebRTC directly
- Most manipulation skills
- *Specific list TBD - needs audit of MyUnitreeSkills*

**Other Known Issues**:
- *TBD - document as discovered*

---

## Candidate Skills (Planning Phase)

These skills have been discussed during roadmap planning but have NOT been committed to or validated as necessary for the MVP.

### Navigation Category
- `nav.stop` - Immediately stop all motion
- `nav.rotate` - Rotate by angle (degrees)
- `nav.translate` - Move forward/backward by distance
- `nav.goto` - Navigate to (x, y, yaw) pose
- `nav.follow_path` - Follow waypoint list

### Perception Category
- `perception.snapshot` - Capture camera image
- `perception.scan_lidar` - Get lidar scan data
- `perception.detect_obstacles` - Basic obstacle detection

### Reporting Category
- `report.log` - Log message with timestamp
- `report.speak` - Text-to-speech (if available)
- `report.status` - Report system status

### System Category
- `system.health_check` - Verify all systems operational
- `system.emergency_stop` - Safe emergency shutdown
- `system.battery_status` - Report battery level
- `system.reset` - Reset to safe state

**Note**: This is a brainstorming list, not a commitment. The actual MVP will define a minimal skill set based on mission requirements.

---

## DIMOS Skill Extension Pattern

### 🔍 **Research Needed**

**TODO**: Review DIMOS documentation and existing integration to understand:
1. How to properly extend DIMOS skills
2. Whether SkillRegistry pattern is appropriate or if we should use DIMOS native patterns
3. Best practices for custom skill implementation

**Possible Resources**:
- DIMOS documentation (when available - see Issue #7)
- Existing DIMOS MyUnitreeSkills implementations
- Previous integration work (check git history)

**Decision Needed**: 
- Use DIMOS native skill system, OR
- Implement custom SkillRegistry wrapper, OR
- Hybrid approach

---

## Next Steps

### Immediate Actions
1. **Audit DIMOS MyUnitreeSkills**:
   - List all skills in `src/dimos-unitree/`
   - Identify which use WebRTC API directly
   - Document dependencies and functionality

2. **Test Non-WebRTC Skills**:
   - Identify skills that don't depend on WebRTC
   - Validate functionality on hardware
   - Document working examples

3. **Define MVP Minimal Skill Set**:
   - Based on mission requirements from MVP doc
   - Start with smallest set that enables vision-based missions
   - Expand as needed

### Medium-Term Actions
1. **Resolve WebRTC Blocker**:
   - Debug WebRTC API issues, OR
   - Implement Nav2-based alternatives

2. **Research DIMOS Skill Extension**:
   - Review DIMOS patterns
   - Choose implementation approach
   - Document decision

3. **Implement/Fix Required Skills**:
   - Based on minimal skill set definition
   - Test thoroughly in simulation then hardware

---

## Validation
- [ ] DIMOS MyUnitreeSkills audit complete
- [ ] Non-WebRTC skills tested and documented
- [ ] MVP minimal skill set defined
- [ ] Skill extension pattern researched and decided

## See Also
- **[MVP Roadmap](../project_overview/mvp_embodied_ai_platform.md)** - Mission requirements driving skill needs
- **[DIMOS Integration](dimos_integration.md)** - Framework integration details
- **[Software Hub](software_hub.md)** - Package development overview

## References
- DIMOS MyUnitreeSkills: `src/dimos-unitree/`
- WebRTC API Issue: (link when created)
- DIMOS Documentation Issue: [#7](https://github.com/danmartinez78/dimos-unitree/issues/7)
