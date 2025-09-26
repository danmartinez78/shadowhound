"""Runtime skill registry and reference skill implementations."""

from __future__ import annotations

import threading
import time
from dataclasses import dataclass, field
from typing import Any, Callable, Dict, Mapping, MutableMapping, Optional, Tuple
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover - used only for type checkers
    from .robot_iface import RobotIface


@dataclass(frozen=True)
class SkillSpec:
    """Metadata describing a skill implementation."""

    name: str
    inputs: Mapping[str, type] = field(default_factory=dict)
    outputs: Optional[Mapping[str, type]] = None
    timeout_s: float = 10.0
    safety: Tuple[str, ...] = field(default_factory=tuple)
    offline_ok: bool = False

    def __post_init__(self) -> None:
        if not self.name or not isinstance(self.name, str):
            raise ValueError("SkillSpec.name must be a non-empty string")
        if self.timeout_s <= 0:
            raise ValueError("SkillSpec.timeout_s must be > 0")
        for key in self.inputs:
            if not isinstance(key, str):
                raise TypeError("SkillSpec.inputs keys must be strings")
        if self.outputs is not None:
            for key in self.outputs:
                if not isinstance(key, str):
                    raise TypeError("SkillSpec.outputs keys must be strings")


_SKILL_REGISTRY: MutableMapping[str, Tuple[SkillSpec, Callable[..., Any]]] = {}


def register_skill(spec: SkillSpec, impl: Callable[..., Any]) -> None:
    """Register ``impl`` for ``spec`` ensuring name uniqueness."""

    if not callable(impl):
        raise TypeError("Skill implementation must be callable")
    if spec.name in _SKILL_REGISTRY:
        raise ValueError(f"Skill '{spec.name}' already registered")
    _SKILL_REGISTRY[spec.name] = (spec, impl)


def call_skill(name: str, /, **kwargs: Any) -> Any:
    """Invoke a registered skill validating arguments and honoring timeouts."""

    try:
        spec, impl = _SKILL_REGISTRY[name]
    except KeyError as exc:
        raise KeyError(f"Unknown skill '{name}'") from exc

    expected_keys = set(spec.inputs.keys())
    provided_keys = set(kwargs.keys())
    missing = expected_keys - provided_keys
    if missing:
        missing_args = ", ".join(sorted(missing))
        raise ValueError(f"Missing arguments for skill '{name}': {missing_args}")

    unexpected = provided_keys - expected_keys
    if unexpected:
        unexpected_args = ", ".join(sorted(unexpected))
        raise ValueError(
            f"Unexpected arguments for skill '{name}': {unexpected_args}"
        )

    for key, expected_type in spec.inputs.items():
        value = kwargs[key]
        if expected_type is not None and not isinstance(value, expected_type):
            raise TypeError(
                f"Argument '{key}' for skill '{name}' must be of type {expected_type}, "
                f"got {type(value)}"
            )

    result: Dict[str, Any] = {}
    error: Dict[str, BaseException] = {}

    def _invoke() -> None:
        try:
            result["value"] = impl(**kwargs)
        except BaseException as exc:  # pragma: no cover - propagate user errors
            error["exc"] = exc

    thread = threading.Thread(target=_invoke, daemon=True)
    thread.start()
    thread.join(timeout=spec.timeout_s)
    if thread.is_alive():
        raise TimeoutError(f"Skill '{name}' timed out after {spec.timeout_s} seconds")
    if error:
        raise error["exc"]
    return result.get("value")


_ROBOT_IFACE: Optional["RobotIface"] = None


def _get_robot_iface() -> "RobotIface":
    global _ROBOT_IFACE
    if _ROBOT_IFACE is not None:
        return _ROBOT_IFACE

    # Lazily import rclpy to avoid mandatory dependency during unit tests.
    import rclpy
    from .robot_iface import RobotIface

    if not rclpy.ok():
        rclpy.init(args=None)
    _ROBOT_IFACE = RobotIface()
    return _ROBOT_IFACE


def _navigation_rotate(*, yaw: float) -> Dict[str, Any]:
    robot = _get_robot_iface()
    angular_speed = 0.6 * (1 if yaw >= 0 else -1)
    remaining = abs(float(yaw))
    step = 0.05
    import rclpy

    while remaining > 0:
        robot.cmd_vel(0.0, 0.0, angular_speed)
        rclpy.spin_once(robot, timeout_sec=step)
        remaining -= abs(angular_speed) * step
    robot.cmd_vel(0.0, 0.0, 0.0)
    return {"status": "completed", "yaw": yaw}


def _report_say(*, text: str) -> Dict[str, Any]:
    import rclpy
    from std_msgs.msg import String

    node = _get_robot_iface()
    publisher = node.create_publisher(String, "/shadowhound/say", 10)
    publisher.publish(String(data=text))
    rclpy.spin_once(node, timeout_sec=0.1)
    return {"status": "spoken", "text": text}


def _perception_snapshot() -> Dict[str, Any]:
    # Placeholder implementation returning a logical URI reference.
    timestamp = int(time.time() * 1000)
    return {"uri": f"package://shadowhound/snapshots/{timestamp}.jpg"}


def _register_builtin_skills() -> None:
    register_skill(
        SkillSpec(
            name="navigation.rotate",
            inputs={"yaw": float},
            outputs={"status": str, "yaw": float},
            timeout_s=10.0,
            safety=("slow_speed",),
            offline_ok=False,
        ),
        _navigation_rotate,
    )
    register_skill(
        SkillSpec(
            name="report.say",
            inputs={"text": str},
            outputs={"status": str, "text": str},
            timeout_s=5.0,
            safety=(),
            offline_ok=True,
        ),
        _report_say,
    )
    register_skill(
        SkillSpec(
            name="perception.snapshot",
            inputs={},
            outputs={"uri": str},
            timeout_s=2.0,
            safety=("no_motion",),
            offline_ok=True,
        ),
        _perception_snapshot,
    )


_register_builtin_skills()


__all__ = ["SkillSpec", "register_skill", "call_skill"]
