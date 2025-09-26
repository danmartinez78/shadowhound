"""ShadowHound utility package exports."""

from importlib import import_module
from typing import Any

__all__ = ["RobotIface"]


def __getattr__(name: str) -> Any:
    if name == "RobotIface":
        return import_module(".robot_iface", __name__).RobotIface
    raise AttributeError(name)
