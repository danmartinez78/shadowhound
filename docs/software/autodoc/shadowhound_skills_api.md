---
tags: [software, autodoc]
status: draft
related: []
summary: >
  Auto-generated reference for shadowhound_skills_api.
---

# shadowhound_skills API Reference

Auto-generated Python API documentation.

## Module: `shadowhound_skills.skill_test_node`

### Functions

#### `main()`

*No documentation available.*

---

## Module: `shadowhound_skills.vision`

Vision skills for ShadowHound using DIMOS Qwen VLM.

These skills leverage DIMOS's existing vision infrastructure:
- Qwen VLM for scene understanding and object detection
- Simple, synchronous API for easy testing and integration
- Structured output for agent consumption


### Class: `SkillResult`

Result from skill execution.


### Class: `VisionSkillBase`

Base class for vision skills.


#### Methods

##### `__init__(self, image_dir: Optional[Path], require_dimos: bool)`

Initialize vision skill.

**Parameters:**
- `image_dir`: Directory to save captured images (default: /tmp/shadowhound/images)
- `require_dimos`: Whether this skill requires DIMOS vision APIs


### Class: `SnapshotSkill`

**Inherits:** `VisionSkillBase`

Capture and save current camera frame. Does not require DIMOS.


#### Methods

##### `__init__(self, image_dir: Optional[Path])`

*No documentation available.*

##### `execute(self, image: np.ndarray, **kwargs) -> SkillResult`

Capture current frame and save with metadata.

**Parameters:**
- `image`: Current camera frame (numpy array or PIL Image)
- `**kwargs`: Optional metadata (pose, timestamp, etc.)

**Returns:**
- SkillResult with image path and metadata


### Class: `DescribeSceneSkill`

**Inherits:** `VisionSkillBase`

Use VLM to describe what's in the image. Requires DIMOS.


#### Methods

##### `__init__(self, image_dir: Optional[Path])`

*No documentation available.*

##### `execute(self, image: np.ndarray, query: Optional[str], save_image: bool, **kwargs) -> SkillResult`

Get VLM description of the scene.

**Parameters:**
- `image`: Current camera frame
- `query`: Custom query (default: "Describe what you see in detail")
- `save_image`: Whether to save the image
- `**kwargs`: Additional parameters

**Returns:**
- SkillResult with VLM description


### Class: `LocateObjectSkill`

**Inherits:** `VisionSkillBase`

Find specific object and return bounding box. Requires DIMOS.


#### Methods

##### `__init__(self, image_dir: Optional[Path])`

*No documentation available.*

##### `execute(self, image: np.ndarray, object_name: str, save_image: bool, **kwargs) -> SkillResult`

Locate specific object in the scene.

**Parameters:**
- `image`: Current camera frame
- `object_name`: Name of object to locate (e.g., "person", "chair")
- `save_image`: Whether to save the image
- `**kwargs`: Additional parameters

**Returns:**
- SkillResult with bounding box if found


### Class: `DetectObjectsSkill`

**Inherits:** `VisionSkillBase`

Detect all prominent objects in the scene. Requires DIMOS.


#### Methods

##### `__init__(self, image_dir: Optional[Path])`

*No documentation available.*

##### `execute(self, image: np.ndarray, save_image: bool, **kwargs) -> SkillResult`

Detect all prominent objects in the scene.

**Parameters:**
- `image`: Current camera frame
- `save_image`: Whether to save the image
- `**kwargs`: Additional parameters

**Returns:**
- SkillResult with list of detected objects


### Functions

#### `get_skill(name: str) -> Optional[VisionSkillBase]`

Get skill by name.


#### `list_skills() -> list`

List all available skills.


---

## References

- [[shadowhound_skills|Package Overview]]
- [[_index|Return to Autodoc Index]]
