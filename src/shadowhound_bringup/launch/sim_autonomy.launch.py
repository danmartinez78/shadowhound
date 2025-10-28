#!/usr/bin/env python3
"""
Simulation Autonomy Stack Launch File

This launch file mirrors robot.launch.py but WITHOUT the go2_driver_node.
Isaac Sim replaces the driver by publishing topics directly.

Usage:
    # On Tower: Start Isaac Sim (publishes /robot0/* topics)
    
    # On Laptop: Start autonomy stack
    ros2 launch shadowhound_bringup sim_autonomy.launch.py \
        rviz2:=true \
        nav2:=true \
        slam:=true \
        foxglove:=true

Launched Components:
    - Nav2 (navigation stack)
    - SLAM Toolbox (mapping)
    - Foxglove Bridge (visualization)
    - RViz2 (3D visualization)
    - Robot state publisher (TF transforms)
    - Pointcloud to laserscan converter
    
NOT Launched:
    - go2_driver_node (Isaac Sim publishes topics instead!)
    
Network Requirements:
    - ROS_DOMAIN_ID=0
    - ROS_LOCALHOST_ONLY=0
    - RMW_IMPLEMENTATION=default (FastDDS, to match Isaac Sim)
"""

import os
from typing import List

from ament_index_python.packages import get_package_share_directory
from launch_ros.actions import Node, PushRosNamespace, SetRemap
from launch_ros.parameter_descriptions import ParameterValue
from nav2_common.launch import RewrittenYaml

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, GroupAction, IncludeLaunchDescription
from launch.conditions import IfCondition
from launch.launch_description_sources import (
    FrontendLaunchDescriptionSource,
    PythonLaunchDescriptionSource,
)
from launch.substitutions import (
    Command,
    LaunchConfiguration,
    PathJoinSubstitution,
    TextSubstitution,
)


class SimAutonomyConfig:
    """Configuration for simulation autonomy stack"""

    def __init__(self):
        # Robot namespace from launch argument (defaults to "tachi")
        self.robot_namespace = LaunchConfiguration("robot_namespace")

        # Package paths
        self.shadowhound_dir = get_package_share_directory("shadowhound_bringup")
        self.go2_sdk_dir = get_package_share_directory("go2_robot_sdk")

        # Config file paths
        self.config_paths = self._get_config_paths()

        print("🤖 Simulation Autonomy Stack Configuration:")
        print(f"   Robot namespace: {self.robot_namespace} (from launch arg)")
        print(f"   Nav2 params: {self.config_paths['nav2']}")
        print(f"   SLAM params: {self.config_paths['slam']}")

    def _get_config_paths(self) -> dict:
        """Get all configuration file paths"""
        # Use shadowhound_bringup package's installed config directory
        # This works correctly in both source and install workspaces
        shadowhound_config_dir = os.path.join(self.shadowhound_dir, "config")

        # Prefer simulation-specific nav2 config if available (has robot0/ frames)
        # Falls back to default config if not found
        nav2_sim_config = os.path.join(
            shadowhound_config_dir, "nav2_params_simulation.yaml"
        )
        nav2_default_config = os.path.join(shadowhound_config_dir, "nav2_params.yaml")

        if os.path.exists(nav2_sim_config):
            nav2_config = nav2_sim_config
        elif os.path.exists(nav2_default_config):
            nav2_config = nav2_default_config
        else:
            # Final fallback to go2_robot_sdk
            nav2_config = os.path.join(self.go2_sdk_dir, "config", "nav2_params.yaml")

        # Prefer simulation-specific slam config if available (has robot0/ frames)
        # Falls back to default config if not found
        slam_sim_config = os.path.join(
            shadowhound_config_dir, "mapper_params_simulation.yaml"
        )
        slam_default_config = os.path.join(
            self.go2_sdk_dir, "config", "mapper_params_online_async.yaml"
        )

        if os.path.exists(slam_sim_config):
            slam_config = slam_sim_config
        else:
            # Fallback to go2_robot_sdk
            slam_config = slam_default_config

        return {
            "nav2": nav2_config,
            "slam": slam_config,
            # Prefer our custom RViz tuned for namespaced topics/frames; fallback to SDK config
            "rviz": (
                os.path.join(
                    self.shadowhound_dir, "config", "rviz", "sim_autonomy_robot0.rviz"
                )
                if os.path.exists(
                    os.path.join(
                        self.shadowhound_dir,
                        "config",
                        "rviz",
                        "sim_autonomy_robot0.rviz",
                    )
                )
                else os.path.join(self.go2_sdk_dir, "config", "single_robot_conf.rviz")
            ),
            "urdf": os.path.join(self.go2_sdk_dir, "urdf", "go2.urdf"),
        }


def create_launch_arguments() -> List[DeclareLaunchArgument]:
    """Create launch arguments for optional components"""
    return [
        DeclareLaunchArgument(
            "robot_namespace",
            default_value="robot0",
            description="Robot namespace (e.g., robot0, robot1)",
        ),
        DeclareLaunchArgument(
            "rviz2", default_value="True", description="Launch RViz2 for visualization"
        ),
        DeclareLaunchArgument(
            "nav2", default_value="True", description="Launch Nav2 navigation stack"
        ),
        DeclareLaunchArgument(
            "slam", default_value="True", description="Launch SLAM Toolbox for mapping"
        ),
        DeclareLaunchArgument(
            "foxglove", default_value="True", description="Launch Foxglove Bridge"
        ),
        DeclareLaunchArgument(
            "use_sim_time",
            default_value="false",
            description="Use simulation time (set true if sim provides clock)",
        ),
    ]


def create_robot_state_publisher(config: SimAutonomyConfig) -> None:
    """
    Robot state publisher NOT NEEDED for simulation.

    Isaac Sim on Tower already publishes TF frames (robot0/base_link, robot0/UnitreeL1_link, etc.)
    Launching robot_state_publisher here would create conflicting TF publishers.

    Tower's TF frames will propagate over the network to laptop.

    Returns None to skip this component.
    """
    return None


def create_pointcloud_to_laserscan(config: SimAutonomyConfig) -> Node:
    """
    Convert LiDAR pointcloud to laserscan for Nav2

    Subscribes to: /robot0/point_cloud2_L1 (from Isaac Sim - namespaced)
    Publishes to: /robot0/scan (namespaced, for Nav2)
    """
    return Node(
        package="pointcloud_to_laserscan",
        executable="pointcloud_to_laserscan_node",
        name="pointcloud_to_laserscan",
        namespace=config.robot_namespace,
        output="screen",
        remappings=[
            # Absolute namespaced topic (templated for multi-robot)
            (
                "cloud_in",
                [
                    "/",
                    config.robot_namespace,
                    TextSubstitution(text="/point_cloud2_L1"),
                ],
            ),
            ("scan", "scan"),  # Publishes to /robot0/scan (relative under namespace)
            # Force TF to global
            ("tf", "/tf"),
            ("tf_static", "/tf_static"),
        ],
        parameters=[
            {
                "target_frame": [
                    config.robot_namespace,
                    TextSubstitution(text="/base_link"),
                ],
                "transform_tolerance": 0.05,
                "min_height": -0.2,
                "max_height": 1.5,
                "angle_min": -3.14159,
                "angle_max": 3.14159,
                "angle_increment": 0.0087,  # ~0.5 degrees
                "scan_time": 0.1,
                "range_min": 0.1,
                "range_max": 30.0,
                "use_inf": True,
            }
        ],
    )


def create_navigation_stack(
    config: SimAutonomyConfig,
) -> List:
    """
    Create Nav2 and SLAM stack with proper multi-robot namespacing.

    Pattern: Global TF with namespaced frames (ChatGPT's recommended approach)
    - All nodes under /robot0/* namespace
    - TF topics: GLOBAL /tf and /tf_static (forced via GroupAction + SetRemap)
    - Frame IDs: robot0/odom, robot0/base_link (injected via RewrittenYaml)
    - Topics: /robot0/* (scan, cmd_vel, costmaps, etc.)

    Isaac Sim publishes to global /tf with namespaced frames.
    All Nav2 and SLAM nodes remap to global /tf via SetRemap actions.

    Works for multiple robots by changing robot_namespace launch arg.
    """
    use_sim_time = LaunchConfiguration("use_sim_time")
    with_nav2 = LaunchConfiguration("nav2")
    with_slam = LaunchConfiguration("slam")

    ns = config.robot_namespace

    # Rewrite Nav2 params to inject namespaced frame IDs and ensure relative scan topics
    # IMPORTANT: root_key=None below to avoid double-rooting params under <ns>.<ns>.*
    frame_remaps = {
        # AMCL (cover flattened and explicit ros__parameters)
        "amcl.global_frame_id": [ns, TextSubstitution(text="/map")],
        "amcl.ros__parameters.global_frame_id": [ns, TextSubstitution(text="/map")],
        "amcl.odom_frame_id": [ns, TextSubstitution(text="/odom")],
        "amcl.ros__parameters.odom_frame_id": [ns, TextSubstitution(text="/odom")],
        "amcl.base_frame_id": [ns, TextSubstitution(text="/base_link")],
        "amcl.ros__parameters.base_frame_id": [ns, TextSubstitution(text="/base_link")],
        # Keep scan relative so it resolves to /<ns>/scan automatically
        "amcl.scan_topic": TextSubstitution(text="scan"),
        "amcl.ros__parameters.scan_topic": TextSubstitution(text="scan"),
        # BT Navigator
        "bt_navigator.global_frame": [ns, TextSubstitution(text="/map")],
        "bt_navigator.ros__parameters.global_frame": [
            ns,
            TextSubstitution(text="/map"),
        ],
        "bt_navigator.robot_base_frame": [ns, TextSubstitution(text="/base_link")],
        "bt_navigator.ros__parameters.robot_base_frame": [
            ns,
            TextSubstitution(text="/base_link"),
        ],
        # Controller Server
        "controller_server.odom_frame": [ns, TextSubstitution(text="/odom")],
        "controller_server.ros__parameters.odom_frame": [
            ns,
            TextSubstitution(text="/odom"),
        ],
        "controller_server.robot_base_frame": [ns, TextSubstitution(text="/base_link")],
        "controller_server.ros__parameters.robot_base_frame": [
            ns,
            TextSubstitution(text="/base_link"),
        ],
        # Planner Server
        "planner_server.global_frame": [ns, TextSubstitution(text="/map")],
        "planner_server.ros__parameters.global_frame": [
            ns,
            TextSubstitution(text="/map"),
        ],
        "planner_server.robot_base_frame": [ns, TextSubstitution(text="/base_link")],
        "planner_server.ros__parameters.robot_base_frame": [
            ns,
            TextSubstitution(text="/base_link"),
        ],
        # Local Costmap (single-key)
        "local_costmap.global_frame": [ns, TextSubstitution(text="/odom")],
        "local_costmap.ros__parameters.global_frame": [
            ns,
            TextSubstitution(text="/odom"),
        ],
        "local_costmap.robot_base_frame": [ns, TextSubstitution(text="/base_link")],
        "local_costmap.ros__parameters.robot_base_frame": [
            ns,
            TextSubstitution(text="/base_link"),
        ],
        # Ensure plugins list present (single-key)
        "local_costmap.plugins": [
            TextSubstitution(text="obstacle_layer"),
            TextSubstitution(text="inflation_layer"),
        ],
        "local_costmap.ros__parameters.plugins": [
            TextSubstitution(text="obstacle_layer"),
            TextSubstitution(text="inflation_layer"),
        ],
        # Local Costmap - obstacle layer scan
        "local_costmap.obstacle_layer.observation_sources": TextSubstitution(
            text="scan"
        ),
        "local_costmap.ros__parameters.obstacle_layer.observation_sources": TextSubstitution(
            text="scan"
        ),
        # Keep scan relative so it resolves to /<ns>/scan automatically
        "local_costmap.obstacle_layer.scan.topic": TextSubstitution(text="scan"),
        "local_costmap.ros__parameters.obstacle_layer.scan.topic": TextSubstitution(
            text="scan"
        ),
        # Local Costmap (double-key)
        "local_costmap.local_costmap.global_frame": [
            ns,
            TextSubstitution(text="/odom"),
        ],
        "local_costmap.local_costmap.ros__parameters.global_frame": [
            ns,
            TextSubstitution(text="/odom"),
        ],
        "local_costmap.local_costmap.robot_base_frame": [
            ns,
            TextSubstitution(text="/base_link"),
        ],
        "local_costmap.local_costmap.ros__parameters.robot_base_frame": [
            ns,
            TextSubstitution(text="/base_link"),
        ],
        # Ensure plugins list present (double-key)
        "local_costmap.local_costmap.plugins": [
            TextSubstitution(text="obstacle_layer"),
            TextSubstitution(text="inflation_layer"),
        ],
        "local_costmap.local_costmap.ros__parameters.plugins": [
            TextSubstitution(text="obstacle_layer"),
            TextSubstitution(text="inflation_layer"),
        ],
        # Double-key obstacle layer scan
        "local_costmap.local_costmap.obstacle_layer.observation_sources": TextSubstitution(
            text="scan"
        ),
        "local_costmap.local_costmap.ros__parameters.obstacle_layer.observation_sources": TextSubstitution(
            text="scan"
        ),
        "local_costmap.local_costmap.obstacle_layer.scan.topic": TextSubstitution(
            text="scan"
        ),
        "local_costmap.local_costmap.ros__parameters.obstacle_layer.scan.topic": TextSubstitution(
            text="scan"
        ),
        # Global Costmap (single-key)
        "global_costmap.global_frame": [ns, TextSubstitution(text="/map")],
        "global_costmap.ros__parameters.global_frame": [
            ns,
            TextSubstitution(text="/map"),
        ],
        "global_costmap.robot_base_frame": [ns, TextSubstitution(text="/base_link")],
        "global_costmap.ros__parameters.robot_base_frame": [
            ns,
            TextSubstitution(text="/base_link"),
        ],
        # Ensure plugins list present (single-key)
        "global_costmap.plugins": [
            TextSubstitution(text="obstacle_layer"),
            TextSubstitution(text="inflation_layer"),
        ],
        "global_costmap.ros__parameters.plugins": [
            TextSubstitution(text="obstacle_layer"),
            TextSubstitution(text="inflation_layer"),
        ],
        # Global Costmap - obstacle layer scan
        "global_costmap.obstacle_layer.observation_sources": TextSubstitution(
            text="scan"
        ),
        "global_costmap.ros__parameters.obstacle_layer.observation_sources": TextSubstitution(
            text="scan"
        ),
        # Keep scan relative so it resolves to /<ns>/scan automatically
        "global_costmap.obstacle_layer.scan.topic": TextSubstitution(text="scan"),
        "global_costmap.ros__parameters.obstacle_layer.scan.topic": TextSubstitution(
            text="scan"
        ),
        # Global Costmap (double-key)
        "global_costmap.global_costmap.global_frame": [
            ns,
            TextSubstitution(text="/map"),
        ],
        "global_costmap.global_costmap.ros__parameters.global_frame": [
            ns,
            TextSubstitution(text="/map"),
        ],
        "global_costmap.global_costmap.robot_base_frame": [
            ns,
            TextSubstitution(text="/base_link"),
        ],
        "global_costmap.global_costmap.ros__parameters.robot_base_frame": [
            ns,
            TextSubstitution(text="/base_link"),
        ],
        # Ensure plugins list present (double-key)
        "global_costmap.global_costmap.plugins": [
            TextSubstitution(text="obstacle_layer"),
            TextSubstitution(text="inflation_layer"),
        ],
        "global_costmap.global_costmap.ros__parameters.plugins": [
            TextSubstitution(text="obstacle_layer"),
            TextSubstitution(text="inflation_layer"),
        ],
        # Double-key obstacle layer scan
        "global_costmap.global_costmap.obstacle_layer.observation_sources": TextSubstitution(
            text="scan"
        ),
        "global_costmap.global_costmap.ros__parameters.obstacle_layer.observation_sources": TextSubstitution(
            text="scan"
        ),
        "global_costmap.global_costmap.obstacle_layer.scan.topic": TextSubstitution(
            text="scan"
        ),
        "global_costmap.global_costmap.ros__parameters.obstacle_layer.scan.topic": TextSubstitution(
            text="scan"
        ),
    }

    params = RewrittenYaml(
        source_file=config.config_paths["nav2"],
        # CRITICAL: Let bringup namespacing handle the root; avoid double-rooting
        root_key=None,
        param_rewrites=frame_remaps,
        convert_types=True,
    )

    # Nav2 launch
    nav2_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            [
                os.path.join(
                    get_package_share_directory("nav2_bringup"),
                    "launch",
                    "bringup_launch.py",
                )
            ]
        ),
        launch_arguments={
            # We'll apply namespacing ourselves with PushRosNamespace to ensure remaps propagate
            "namespace": "",
            "use_namespace": "false",
            # Let this launch file manage SLAM explicitly; avoid double-launching SLAM Toolbox
            # Setting slam to False prevents nav2_bringup from launching its own slam_toolbox
            "slam": "False",
            "map": "",
            "params_file": params,  # Use rewritten params with frame IDs
            "use_sim_time": use_sim_time,
            "autostart": "True",
            "use_composition": "False",
            "use_respawn": "False",
        }.items(),
    )

    # Nav2 launch wrapped in GroupAction with TF remapping
    # GroupAction with SetRemap forces all child nodes to use global TF
    nav2_group = GroupAction(
        actions=[
            # Apply namespace here so SetRemap applies to all child nodes created by bringup
            PushRosNamespace(ns),
            # Force TF topics to global for every child node inside bringup
            SetRemap("tf", "/tf"),
            SetRemap("tf_static", "/tf_static"),
            nav2_launch,
        ],
        condition=IfCondition(with_nav2),
    )

    # SLAM - with global TF remapping
    slam_node = Node(
        condition=IfCondition(with_slam),
        package="slam_toolbox",
        executable="sync_slam_toolbox_node",
        name="slam_toolbox",
        namespace=ns,  # /robotX/*
        output="screen",
        parameters=[
            config.config_paths["slam"],
            {"use_sim_time": use_sim_time},
        ],
        # Keep TF global
        remappings=[
            ("tf", "/tf"),
            ("tf_static", "/tf_static"),
        ],
    )

    return [nav2_group, slam_node]


def create_visualization_nodes(config: SimAutonomyConfig) -> List:
    """Create visualization nodes (Foxglove, RViz2)"""
    with_rviz2 = LaunchConfiguration("rviz2")
    with_foxglove = LaunchConfiguration("foxglove")

    nodes = []

    # Foxglove Bridge
    foxglove_launch = os.path.join(
        get_package_share_directory("foxglove_bridge"),
        "launch",
        "foxglove_bridge_launch.xml",
    )

    nodes.append(
        IncludeLaunchDescription(
            FrontendLaunchDescriptionSource(foxglove_launch),
            condition=IfCondition(with_foxglove),
        )
    )

    # RViz2
    nodes.append(
        Node(
            package="rviz2",
            executable="rviz2",
            name="rviz2_laptop",  # Unique name to avoid conflict with Tower's RViz
            output="screen",
            arguments=["-d", config.config_paths["rviz"]],
            condition=IfCondition(with_rviz2),
        )
    )

    return nodes


def generate_launch_description():
    """
    Generate launch description for simulation autonomy stack.

    This mirrors robot.launch.py but WITHOUT go2_driver_node.
    Isaac Sim replaces the driver by publishing standard ROS2 topics.
    """

    # Initialize configuration
    config = SimAutonomyConfig()

    # Create all components
    launch_args = create_launch_arguments()
    robot_state_pub = create_robot_state_publisher(config)
    pointcloud_converter = create_pointcloud_to_laserscan(config)
    nav_stack = create_navigation_stack(config)
    viz_nodes = create_visualization_nodes(config)

    print("\n" + "=" * 60)
    print("🚀 SIMULATION AUTONOMY STACK")
    print("=" * 60)
    print("Prerequisites:")
    print("  1. Isaac Sim running on Tower (publishing /robot0/* topics)")
    print("  2. Network ROS2 configured:")
    print("     - ROS_DOMAIN_ID=0")
    print("     - ROS_LOCALHOST_ONLY=0")
    print("     - RMW_IMPLEMENTATION=rmw_cyclonedds_cpp")
    print("\nLaunching:")
    print("  ✅ Pointcloud to laserscan converter")
    print("  ✅ Nav2 (if enabled)")
    print("  ✅ SLAM Toolbox (if enabled)")
    print("  ✅ Foxglove Bridge (if enabled)")
    print("  ✅ RViz2 (if enabled)")
    print("\nNOT Launching:")
    print("  ❌ go2_driver_node (Isaac Sim replaces this!)")
    print("  ❌ robot_state_publisher (Tower provides TF frames)")
    print("=" * 60 + "\n")

    # Combine all elements (filter out None values)
    launch_entities = (
        launch_args
        + ([robot_state_pub] if robot_state_pub is not None else [])
        + [pointcloud_converter]
        + nav_stack
        + viz_nodes
    )

    return LaunchDescription(launch_entities)
