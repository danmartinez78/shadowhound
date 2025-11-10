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
    - Pointcloud to laserscan converter
    
NOT Launched:
    - go2_driver_node (Isaac Sim publishes topics instead!)
    
Network Requirements:
    - ROS_DOMAIN_ID=0
    - ROS_LOCALHOST_ONLY=0
    - RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
"""

import os
from typing import List

from ament_index_python.packages import get_package_share_directory
from launch_ros.actions import Node

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.conditions import IfCondition
from launch.launch_description_sources import (
    FrontendLaunchDescriptionSource,
    PythonLaunchDescriptionSource,
)
from launch.substitutions import LaunchConfiguration


class SimAutonomyConfig:
    """Configuration for simulation autonomy stack"""

    def __init__(self):
        # Robot namespace from launch argument (defaults to "robot0")
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
        shadowhound_config_dir = os.path.join(self.shadowhound_dir, "config")

        # Prefer namespaced nav2 config (clean unprefixed frames)
        nav2_namespaced_config = os.path.join(
            shadowhound_config_dir, "nav2_params_namespaced.yaml"
        )
        nav2_sim_config = os.path.join(
            shadowhound_config_dir, "nav2_params_simulation.yaml"
        )
        nav2_default_config = os.path.join(shadowhound_config_dir, "nav2_params.yaml")

        if os.path.exists(nav2_namespaced_config):
            nav2_config = nav2_namespaced_config
        elif os.path.exists(nav2_sim_config):
            nav2_config = nav2_sim_config
        elif os.path.exists(nav2_default_config):
            nav2_config = nav2_default_config
        else:
            nav2_config = os.path.join(self.go2_sdk_dir, "config", "nav2_params.yaml")

        # SLAM params
        slam_sim_config = os.path.join(
            shadowhound_config_dir, "mapper_params_simulation.yaml"
        )
        slam_default_config = os.path.join(
            self.go2_sdk_dir, "config", "mapper_params_online_async.yaml"
        )
        slam_config = slam_sim_config if os.path.exists(slam_sim_config) else slam_default_config

        # RViz config
        rviz_sim = os.path.join(
            self.shadowhound_dir, "config", "rviz", "sim_autonomy_robot0.rviz"
        )
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

    Subscribes to: point_cloud2_L1 (namespace-relative from Isaac Sim)
    Publishes to: scan (namespace-relative for Nav2)
    
    All topics are namespace-relative. Node runs under /robotN namespace,
    so point_cloud2_L1 becomes /robotN/point_cloud2_L1 automatically.
    """
    return Node(
        package="pointcloud_to_laserscan",
        executable="pointcloud_to_laserscan_node",
        name="pointcloud_to_laserscan",
        namespace=config.robot_namespace,
        output="screen",
        remappings=[
            ("cloud_in", "point_cloud2_L1"),  # Namespace-relative
            ("scan", "scan"),  # Namespace-relative
        ],
        parameters=[
            {
                "target_frame": "base_link",  # Unprefixed - isolated by namespace
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


def create_navigation_stack(
    config: SimAutonomyConfig,
) -> List:
    """
    Create Nav2 and SLAM stack with fully namespaced architecture.

    Pattern: Namespaced TF topics with unprefixed frames
    - All nodes under /robotN/* namespace
    - TF topics: /robotN/tf and /robotN/tf_static (namespaced)
    - Frame IDs: map, odom, base_link (unprefixed, isolated by namespace)
    - Topics: /robotN/* (scan, cmd_vel, costmaps, etc.)
    
    NO RewrittenYaml needed - params file has unprefixed frames already.
    Nav2's use_namespace=true handles TF topic namespacing automatically.
    """
    use_sim_time = LaunchConfiguration("use_sim_time")
    with_nav2 = LaunchConfiguration("nav2")
    with_slam = LaunchConfiguration("slam")

    ns = config.robot_namespace

    # Nav2 launch with namespace support (no RewrittenYaml!)
    nav2_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            [
                os.path.join(
                    get_package_share_directory("shadowhound_bringup"),
                    "launch",
                    "nav2_nodes.launch.py",
                )
            ]
        ),
        launch_arguments={
            "namespace": ns,  # Set namespace
            "use_namespace": "true",  # Enable namespaced TF topics
            "params_file": config.config_paths["nav2"],
            "use_sim_time": use_sim_time,
            "autostart": "True",
        }.items(),
        condition=IfCondition(with_nav2),
    )

    # SLAM - namespaced (no global TF remapping)
    slam_node = Node(
        condition=IfCondition(with_slam),
        package="slam_toolbox",
        executable="sync_slam_toolbox_node",
        name="slam_toolbox",
        namespace=ns,
        output="screen",
        parameters=[
            config.config_paths["slam"],
            {"use_sim_time": use_sim_time},
        ],
        # NO TF remaps - use namespaced TF
    )

    slam_lifecycle = Node(
        condition=IfCondition(with_slam),
        package="nav2_lifecycle_manager",
        executable="lifecycle_manager",
        name="lifecycle_manager_slam",
        namespace=ns,
        output="screen",
        parameters=[
            {"autostart": True},
            {"bond_timeout": 0.0},
            {"node_names": ["slam_toolbox"]},
        ],
    )

    return [nav2_launch, slam_node, slam_lifecycle]


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
            name="rviz2_laptop",
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
    print("🚀 SIMULATION AUTONOMY STACK - NAMESPACED TF")
    print("=" * 60)
    print("Prerequisites:")
    print("  1. Isaac Sim running on Tower (publishing /robotN/* topics)")
    print("  2. Network ROS2 configured:")
    print("     - ROS_DOMAIN_ID=0")
    print("     - ROS_LOCALHOST_ONLY=0")
    print("     - RMW_IMPLEMENTATION=rmw_cyclonedds_cpp")
    print("\nArchitecture:")
    print("  📡 TF Topics: /robotN/tf and /robotN/tf_static (namespaced)")
    print("  🏷️  Frame IDs: map, odom, base_link (unprefixed)")
    print("  🎯 Isolation: Each robot in separate namespace")
    print("\nLaunching:")
    print("  ✅ Pointcloud to laserscan converter (namespaced)")
    print("  ✅ Nav2 with use_namespace=true (if enabled)")
    print("  ✅ SLAM Toolbox namespaced (if enabled)")
    print("  ✅ Foxglove Bridge (if enabled)")
    print("  ✅ RViz2 (if enabled)")
    print("\nNOT Launching:")
    print("  ❌ go2_driver_node (Isaac Sim replaces this!)")
    print("  ❌ robot_state_publisher (Tower provides TF frames)")
    print("  ❌ RewrittenYaml (removed for simplicity)")
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
