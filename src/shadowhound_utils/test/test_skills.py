import time
from typing import Dict

import pathlib
import sys

import pytest

sys.path.append(str(pathlib.Path(__file__).resolve().parents[3] / "src"))

import shadowhound_utils.shadowhound_utils.skills as skills


@pytest.fixture(autouse=True)
def isolate_registry():
    snapshot = dict(skills._SKILL_REGISTRY)
    try:
        yield
    finally:
        skills._SKILL_REGISTRY.clear()
        skills._SKILL_REGISTRY.update(snapshot)


def test_register_duplicate_skill_raises():
    spec = skills.SkillSpec(name="demo.skill", inputs={}, timeout_s=0.1)
    skills.register_skill(spec, lambda: None)
    with pytest.raises(ValueError):
        skills.register_skill(spec, lambda: None)


def test_missing_argument_detection():
    spec = skills.SkillSpec(name="demo.required", inputs={"value": int}, timeout_s=0.1)
    skills.register_skill(spec, lambda value: value)
    with pytest.raises(ValueError):
        skills.call_skill("demo.required")


def test_type_validation():
    spec = skills.SkillSpec(name="demo.types", inputs={"value": int}, timeout_s=0.1)
    skills.register_skill(spec, lambda value: value)
    with pytest.raises(TypeError):
        skills.call_skill("demo.types", value="nope")


def test_timeout_behavior():
    spec = skills.SkillSpec(name="demo.timeout", inputs={}, timeout_s=0.05)

    def slow_skill():
        time.sleep(0.2)

    skills.register_skill(spec, slow_skill)
    with pytest.raises(TimeoutError):
        skills.call_skill("demo.timeout")


def test_successful_call_returns_value():
    spec = skills.SkillSpec(name="demo.success", inputs={"value": int}, timeout_s=0.5)

    def impl(value: int) -> Dict[str, int]:
        return {"value": value}

    skills.register_skill(spec, impl)
    assert skills.call_skill("demo.success", value=7) == {"value": 7}
