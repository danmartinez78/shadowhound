#!/usr/bin/env python3
"""
Multi-robot Nav2 bringup (namespaced nodes/topics, GLOBAL TF)
"""

import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, GroupAction, LogInfo
from launch.conditions import IfCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, TextSubstitution
from launch_ros.actions import Node, Remap
from nav2_common.launch import RewrittenYaml


def generate_launch_description():
    ns = LaunchConfiguration("robot_namespace")
    use_sim_time = LaunchConfiguration("use_sim_time")
    with_nav2 = LaunchConfiguration("nav2")
    pointcloud_topic = LaunchConfiguration("pointcloud_topic")

    bringup_share = get_package_share_directory("shadowhound_bringup")
    go2_share = get_package_share_directory("go2_robot_sdk")

    default_nav2_yaml = os.path.join(bringup_share, "config", "nav2_params_simulation.yaml")
    default_slam_yaml = os.path.join(bringup_share, "config", "mapper_params_simulation.yaml")

    nav2_params_file = LaunchConfiguration("nav2_params_file")
    slam_params_file = LaunchConfiguration("slam_params_file")

    param_rewrites = {
        "amcl.global_frame_id": [ns, TextSubstitution(text="/map")],
        "amcl.odom_frame_id": [ns, TextSubstitution(text="/odom")],
        "amcl.base_frame_id": [ns, TextSubstitution(text="/base_link")],
        "controller_server.odom_frame": [ns, TextSubstitution(text="/odom")],
        "controller_server.robot_base_frame": [ns, TextSubstitution(text="/base_link")],
        "local_costmap.global_frame": [ns, TextSubstitution(text="/odom")],
        "local_costmap.robot_base_frame": [ns, TextSubstitution(text="/base_link")],
        "global_costmap.global_frame": [ns, TextSubstitution(text="/map")],
        "global_costmap.robot_base_frame": [ns, TextSubstitution(text="/base_link")],
        "local_costmap.voxel_layer.observation_sources": TextSubstitution(text="scan"),
        "local_costmap.voxel_layer.scan.topic": TextSubstitution(text="scan"),
    }

    nav2_params = RewrittenYaml(
        source_file=nav2_params_file,
        root_key=None,
        param_rewrites=param_rewrites,
        convert_types=True,
    )

    pcl_to_scan = Node(
        package="pointcloud_to_laserscan",
        executable="pointcloud_to_laserscan_node",
        name="pointcloud_to_laserscan",
        namespace=ns,
        output="screen",
        remappings=[
            ("cloud_in", [TextSubstitution(text="/"), ns, TextSubstitution(text="/"), pointcloud_topic]),
            ("scan", "scan"),
            ("tf", "/tf"),
            ("tf_static", "/tf_static"),
        ],
        parameters=[{
            "target_frame": [ns, TextSubstitution(text="/base_link")],
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
        }],
    )

    nav2_include = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(get_package_share_directory("nav2_bringup"), "launch", "bringup_launch.py")
        ),
        condition=IfCondition(with_nav2),
        launch_arguments={
            "namespace": ns,
            "use_namespace": "true",
            "slam": "True",
            "map": "",
            "params_file": nav2_params,
            "use_sim_time": use_sim_time,
            "autostart": "True",
            "use_composition": "False",
            "use_respawn": "False",
        }.items(),
    )

    nav2_group = GroupAction([Remap("tf", "/tf"), Remap("tf_static", "/tf_static"), nav2_include])

    logs = [LogInfo(msg=["Robot namespace: ", ns])]

    return LaunchDescription([
        DeclareLaunchArgument("robot_namespace", default_value="robot0"),
        DeclareLaunchArgument("use_sim_time", default_value="false"),
        DeclareLaunchArgument("nav2", default_value="True"),
        DeclareLaunchArgument("nav2_params_file", default_value=default_nav2_yaml),
        DeclareLaunchArgument("slam_params_file", default_value=default_slam_yaml),
        DeclareLaunchArgument("pointcloud_topic", default_value="point_cloud2_L1"),
        *logs,
        pcl_to_scan,
        nav2_group,
    ])
