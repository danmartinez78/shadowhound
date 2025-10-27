#!/usr/bin/env python3
"""
Multi-robot Simulation Autonomy Launch (global TF, namespaced nodes/topics)
- Each robot runs under its own namespace (robot0, robot1, ...)
- All TF topics are kept GLOBAL (/tf, /tf_static)
- Frame IDs are prefixed with the robot namespace via RewrittenYaml
"""

import os
from typing import List

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, GroupAction, LogInfo
from launch.conditions import IfCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource, FrontendLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, TextSubstitution
from launch_ros.actions import Node, SetRemap
from nav2_common.launch import RewrittenYaml


def _share_dir(pkg: str) -> str:
    return get_package_share_directory(pkg)


def generate_launch_description():
    # --- Launch args ---
    robot_ns = LaunchConfiguration("robot_namespace")
    with_rviz2 = LaunchConfiguration("rviz2")
    with_nav2 = LaunchConfiguration("nav2")
    with_slam = LaunchConfiguration("slam")
    with_foxglove = LaunchConfiguration("foxglove")
    use_sim_time = LaunchConfiguration("use_sim_time")
    pointcloud_topic = LaunchConfiguration("pointcloud_topic")  # per-robot topic name under the namespace

    shadowhound_bringup_dir = _share_dir("shadowhound_bringup")
    go2_sdk_dir = _share_dir("go2_robot_sdk")

    # Default config file paths from installed package share
    default_nav2_yaml = os.path.join(shadowhound_bringup_dir, "config", "nav2_params_simulation.yaml")
    default_slam_yaml = os.path.join(shadowhound_bringup_dir, "config", "mapper_params_simulation.yaml")
    rviz_file = os.path.join(go2_sdk_dir, "config", "single_robot_conf.rviz")

    nav2_params_file = LaunchConfiguration("nav2_params_file")
    slam_params_file = LaunchConfiguration("slam_params_file")

    # RewrittenYaml to inject namespace prefixes into frame IDs at runtime
    # We cover both single-key and double-key costmap node-name styles.
    prefixed_params = RewrittenYaml(
        source_file=nav2_params_file,
        root_key=robot_ns,                    # nav2_bringup expects params rooted at the namespace
        param_rewrites={
            # AMCL
            "amcl.global_frame_id": [robot_ns, TextSubstitution(text="/map")],
            "amcl.odom_frame_id":   [robot_ns, TextSubstitution(text="/odom")],
            "amcl.base_frame_id":   [robot_ns, TextSubstitution(text="/base_link")],
            # BT Nav
            "bt_navigator.global_frame":     [robot_ns, TextSubstitution(text="/map")],
            "bt_navigator.robot_base_frame": [robot_ns, TextSubstitution(text="/base_link")],
            # Controller / Planner / Smoother
            "controller_server.odom_frame":        [robot_ns, TextSubstitution(text="/odom")],
            "controller_server.robot_base_frame":  [robot_ns, TextSubstitution(text="/base_link")],
            "planner_server.global_frame":         [robot_ns, TextSubstitution(text="/map")],
            "planner_server.robot_base_frame":     [robot_ns, TextSubstitution(text="/base_link")],
            "smoother_server.global_frame":        [robot_ns, TextSubstitution(text="/map")],
            "smoother_server.robot_base_frame":    [robot_ns, TextSubstitution(text="/base_link")],
            "behavior_server.global_frame":        [robot_ns, TextSubstitution(text="/map")],
            "behavior_server.robot_base_frame":    [robot_ns, TextSubstitution(text="/base_link")],
            # Costmaps (single-key)
            "local_costmap.global_frame":          [robot_ns, TextSubstitution(text="/odom")],
            "local_costmap.robot_base_frame":      [robot_ns, TextSubstitution(text="/base_link")],
            "global_costmap.global_frame":         [robot_ns, TextSubstitution(text="/map")],
            "global_costmap.robot_base_frame":     [robot_ns, TextSubstitution(text="/base_link")],
            # Costmaps (double-key)
            "local_costmap.local_costmap.global_frame":        [robot_ns, TextSubstitution(text="/odom")],
            "local_costmap.local_costmap.robot_base_frame":    [robot_ns, TextSubstitution(text="/base_link")],
            "global_costmap.global_costmap.global_frame":      [robot_ns, TextSubstitution(text="/map")],
            "global_costmap.global_costmap.robot_base_frame":  [robot_ns, TextSubstitution(text="/base_link")],
        },
        convert_types=True,
    )

    # --- Nodes ---

    # Pointcloud -> Laserscan (namespaced node; subscribes to absolute robot topic; TF global)
    pcl_to_scan = Node(
        package="pointcloud_to_laserscan",
        executable="pointcloud_to_laserscan_node",
        name="pointcloud_to_laserscan",
        namespace=robot_ns,
        output="screen",
        remappings=[
            # "/<ns>/<pointcloud_topic>"
            ("cloud_in", [TextSubstitution(text="/"), robot_ns, TextSubstitution(text="/"), pointcloud_topic]),
            ("scan", "scan"),
            ("tf", "/tf"),
            ("tf_static", "/tf_static"),
        ],
        parameters=[
            {
                "target_frame": [robot_ns, TextSubstitution(text="/base_link")],
                "transform_tolerance": 0.05,
                "min_height": -0.2,
                "max_height": 1.5,
                "angle_min": -3.14159,
                "angle_max": 3.14159,
                "angle_increment": 0.0087,
                "scan_time": 0.1,
                "range_min": 0.1,
                "range_max": 30.0,
                "use_inf": True,
            }
        ],
    )

    # Nav2 bringup (wrapped so TF topics are forced to global)
    nav2_include = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(_share_dir("nav2_bringup"), "launch", "bringup_launch.py")
        ),
        condition=IfCondition(with_nav2),
        launch_arguments={
            "namespace": robot_ns,
            "use_namespace": "true",
            "slam": "False",
            "map": "",
            "params_file": prefixed_params,
            "use_sim_time": use_sim_time,
            "autostart": "True",
            "use_composition": "False",
            "use_respawn": "False",
        }.items(),
    )

    nav2_group = GroupAction([
        SetRemap("tf", "/tf"),
        SetRemap("tf_static", "/tf_static"),
        nav2_include
    ])

    # SLAM Toolbox (kept optional; also TF global)
    slam_node = Node(
        condition=IfCondition(with_slam),
        package="slam_toolbox",
        executable="sync_slam_toolbox_node",
        name="slam_toolbox",
        namespace=robot_ns,
        output="screen",
        parameters=[
            RewrittenYaml(
                source_file=slam_params_file,
                root_key=robot_ns,
                param_rewrites={
                    "slam_toolbox.map_frame":  [robot_ns, TextSubstitution(text="/map")],
                    "slam_toolbox.odom_frame": [robot_ns, TextSubstitution(text="/odom")],
                    "slam_toolbox.base_frame": [robot_ns, TextSubstitution(text="/base_link")],
                },
                convert_types=True,
            ),
            {"use_sim_time": use_sim_time},
        ],
        remappings=[("tf", "/tf"), ("tf_static", "/tf_static")],
    )

    # Foxglove Bridge (optional)
    foxglove_launch = os.path.join(_share_dir("foxglove_bridge"), "launch", "foxglove_bridge_launch.xml")
    foxglove = IncludeLaunchDescription(
        FrontendLaunchDescriptionSource(foxglove_launch),
        condition=IfCondition(with_foxglove),
    )

    # RViz2 (optional)
    rviz = Node(
        condition=IfCondition(with_rviz2),
        package="rviz2",
        executable="rviz2",
        name="rviz2_laptop",
        output="screen",
        arguments=["-d", rviz_file],
    )

    # Logs to confirm which files are used
    log1 = LogInfo(msg=["Using Nav2 params: ", nav2_params_file])
    log2 = LogInfo(msg=["Using SLAM params: ", slam_params_file])
    log3 = LogInfo(msg=["Robot namespace: ", robot_ns])
    log4 = LogInfo(msg=["Pointcloud topic (under ns): ", pointcloud_topic])

    return LaunchDescription([
        # Arguments
        DeclareLaunchArgument("robot_namespace", default_value="robot0",
                              description="Robot namespace (robot0, robot1, ...)"),
        DeclareLaunchArgument("rviz2", default_value="True"),
        DeclareLaunchArgument("nav2", default_value="True"),
        DeclareLaunchArgument("slam", default_value="True"),
        DeclareLaunchArgument("foxglove", default_value="True"),
        DeclareLaunchArgument("use_sim_time", default_value="false"),
        DeclareLaunchArgument("nav2_params_file", default_value=default_nav2_yaml,
                              description="Path to Nav2 params YAML (namespace-agnostic)"),
        DeclareLaunchArgument("slam_params_file", default_value=default_slam_yaml,
                              description="Path to SLAM params YAML (namespace-agnostic)"),
        DeclareLaunchArgument("pointcloud_topic", default_value="point_cloud2_L1",
                              description="Per-robot pointcloud topic name under the namespace"),
        log1, log2, log3, log4,
        # Nodes
        pcl_to_scan,
        nav2_group,
        slam_node,
        foxglove,
        rviz,
    ])
