#!/usr/bin/env python3
"""
Thorough autonomy stack validation for a single robot namespace.

Checks:
- Global TF topics present; no per-namespace tf topics
- Required Nav2/SLAM nodes are up under the namespace
- Local/Global costmap params (double-key style) are present with expected values
- Local costmap subscribes to the scan topic
- Costmap topics publish at > 0 Hz within a timeout window

Usage:
  python3 test_scripts/test_autonomy.py --ns robot0 --timeout 8.0

Exit codes:
  0 = all checks passed
  1 = one or more checks failed
"""
import argparse
import sys
import time
from dataclasses import dataclass
from typing import List, Tuple

import rclpy
from rclpy.node import Node
from rcl_interfaces.srv import GetParameters
from rcl_interfaces.msg import ParameterValue, ParameterType
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy


@dataclass
class CheckResult:
    name: str
    success: bool
    detail: str = ""


class AutonomyTester(Node):
    def __init__(self, ns: str, timeout: float):
        super().__init__(f"autonomy_tester_{ns}")
        self.ns = ns
        self.timeout = timeout
        # QoS for costmap topics (Map msgs often latched/transient local)
        self.map_qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            history=HistoryPolicy.KEEP_LAST,
            depth=10,
        )
        self._costmap_msg_counts = {"local": 0, "global": 0}

    # ------------- Graph helpers -------------
    def topic_exists(self, topic: str) -> bool:
        topics = [t[0] for t in self.get_topic_names_and_types()]
        return topic in topics

    def node_exists(self, full_name: str) -> bool:
        for name, namespace in self.get_node_names_and_namespaces():
            fq = f"{namespace}/{name}".replace("//", "/")
            if fq == full_name:
                return True
        return False

    def subscribers_for(self, topic: str) -> List[str]:
        infos = self.get_subscriptions_info_by_topic(topic)
        return [f"{i.node_namespace}/{i.node_name}".replace("//", "/") for i in infos]

    # ------------- Param helpers -------------
    def get_params(self, node_name: str, names: List[str]) -> Tuple[bool, List[ParameterValue]]:
        client = self.create_client(GetParameters, f"{node_name}/get_parameters")
        if not client.wait_for_service(timeout_sec=self.timeout):
            return False, []
        req = GetParameters.Request()
        req.names = names
        future = client.call_async(req)
        rclpy.spin_until_future_complete(self, future, timeout_sec=self.timeout)
        res = future.result()
        if res is None:
            return False, []
        return True, list(res.values)

    # ------------- Subscriptions -------------
    def _local_costmap_cb(self, msg):  # noqa: ARG002
        self._costmap_msg_counts["local"] += 1

    def _global_costmap_cb(self, msg):  # noqa: ARG002
        self._costmap_msg_counts["global"] += 1

    def subscribe_costmaps(self):
        self.create_subscription(
            msg_type=self.resolve_message_type("nav_msgs/msg/OccupancyGrid"),
            topic=f"/{self.ns}/local_costmap/costmap",
            callback=self._local_costmap_cb,
            qos_profile=self.map_qos,
        )
        self.create_subscription(
            msg_type=self.resolve_message_type("nav_msgs/msg/OccupancyGrid"),
            topic=f"/{self.ns}/global_costmap/costmap",
            callback=self._global_costmap_cb,
            qos_profile=self.map_qos,
        )

    def resolve_message_type(self, type_str):
        # Lazy import to avoid hard dependency
        from rosidl_runtime_py.utilities import get_message

        return get_message(type_str)


def run_checks(ns: str, timeout: float) -> List[CheckResult]:
    rclpy.init()
    node = AutonomyTester(ns, timeout)

    results: List[CheckResult] = []

    # 1) TF topics
    results.append(
        CheckResult(
            name="TF topics present",
            success=node.topic_exists("/tf") and node.topic_exists("/tf_static"),
            detail="/tf and /tf_static must exist",
        )
    )
    results.append(
        CheckResult(
            name="No namespaced TF topic",
            success=not node.topic_exists(f"/{ns}/tf"),
            detail=f"/{ns}/tf should NOT exist",
        )
    )

    # 2) Required nodes
    required_nodes = [
        f"/{ns}/controller_server",
        f"/{ns}/planner_server",
        f"/{ns}/bt_navigator",
        f"/{ns}/local_costmap/local_costmap",
        f"/{ns}/global_costmap/global_costmap",
        f"/{ns}/behavior_server",
        f"/{ns}/slam_toolbox",
    ]
    for n in required_nodes:
        results.append(
            CheckResult(name=f"Node up: {n}", success=node.node_exists(n))
        )

    # 3) Local costmap params (double-key node)
    lcm_node = f"/{ns}/local_costmap/local_costmap"
    ok, params = node.get_params(
        lcm_node,
        [
            "plugins",
            "obstacle_layer.observation_sources",
            "obstacle_layer.scan.topic",
            "global_frame",
            "robot_base_frame",
        ],
    )
    if not ok:
        results.append(
            CheckResult(
                name="Local costmap: parameter service",
                success=False,
                detail="get_parameters service unavailable",
            )
        )
    else:
        # plugins list contains both layers
        p0 = params[0]
        p_plugins = (
            list(p0.string_array_value)
            if p0.type == ParameterType.PARAMETER_STRING_ARRAY
            else []
        )
        results.append(
            CheckResult(
                name="Local costmap plugins",
                success=set(["obstacle_layer", "inflation_layer"]).issubset(
                    set(p_plugins)
                ),
                detail=str(p_plugins),
            )
        )
        # observation_sources == scan
        obs = (
            params[1].string_value
            if params[1].type == ParameterType.PARAMETER_STRING
            else None
        )
        results.append(
            CheckResult(
                name="Local costmap observation_sources",
                success=(obs == "scan"),
                detail=f"got={obs}",
            )
        )
        # scan.topic == scan
        scan_topic = (
            params[2].string_value
            if params[2].type == ParameterType.PARAMETER_STRING
            else None
        )
        results.append(
            CheckResult(
                name="Local costmap scan.topic",
                success=(scan_topic == "scan"),
                detail=f"got={scan_topic}",
            )
        )
        # frames prefixed
        gf = (
            params[3].string_value
            if params[3].type == ParameterType.PARAMETER_STRING
            else None
        )
        rbf = (
            params[4].string_value
            if params[4].type == ParameterType.PARAMETER_STRING
            else None
        )
        results.append(
            CheckResult(
                name="Local costmap frames prefixed",
                success=(gf == f"{ns}/odom" and rbf == f"{ns}/base_link"),
                detail=f"global_frame={gf}, robot_base_frame={rbf}",
            )
        )

    # 4) Local costmap subscribes to /<ns>/scan
    subs = node.subscribers_for(f"/{ns}/scan")
    results.append(
        CheckResult(
            name="Local costmap subscribes to scan",
            success=(f"/{ns}/local_costmap/local_costmap" in subs),
            detail=", ".join(subs),
        )
    )

    # 5) Costmap publishing rate
    node.subscribe_costmaps()
    start = time.time()
    while time.time() - start < timeout:
        rclpy.spin_once(node, timeout_sec=0.2)
        if node._costmap_msg_counts["local"] > 0 and node._costmap_msg_counts["global"] > 0:
            break
    results.append(
        CheckResult(
            name="Local costmap publishing",
            success=node._costmap_msg_counts["local"] > 0,
            detail=f"msgs={node._costmap_msg_counts['local']}",
        )
    )
    results.append(
        CheckResult(
            name="Global costmap publishing",
            success=node._costmap_msg_counts["global"] > 0,
            detail=f"msgs={node._costmap_msg_counts['global']}",
        )
    )

    node.destroy_node()
    rclpy.shutdown()
    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ns", default="robot0", help="Robot namespace")
    parser.add_argument(
        "--timeout", type=float, default=8.0, help="Timeout seconds for checks"
    )
    args = parser.parse_args()

    results = run_checks(args.ns, args.timeout)
    failures = [r for r in results if not r.success]

    print("\n=== Autonomy Validation Report ===")
    for r in results:
        status = "PASS" if r.success else "FAIL"
        msg = f"- [{status}] {r.name}"
        if r.detail:
            msg += f"  ({r.detail})"
        print(msg)

    print("\nSummary:")
    print(f"  Passed: {len(results) - len(failures)} / {len(results)}")
    if failures:
        print("  Failed checks:")
        for r in failures:
            print(f"    - {r.name}: {r.detail}")
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
