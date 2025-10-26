#!/usr/bin/env python3
"""
Custom Nav2 node launch - bypasses bringup_launch.py to avoid RewrittenYaml.

This launches Nav2 nodes directly with raw params (no YAML rewriting).
For multi-robot with pre-namespaced TF frames from Isaac Sim.
"""

import os
from launch import LaunchDescription
from launch.actions import GroupAction, DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node, PushRosNamespace
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    namespace = LaunchConfiguration('namespace')
    params_file = LaunchConfiguration('params_file')
    use_sim_time = LaunchConfiguration('use_sim_time')
    autostart = LaunchConfiguration('autostart')
    
    # All Nav2 nodes in a namespace group
    nav2_nodes = GroupAction([
        PushRosNamespace(namespace),
        
        # Controller Server
        Node(
            package='nav2_controller',
            executable='controller_server',
            output='screen',
            parameters=[params_file, {'use_sim_time': use_sim_time}],
            remappings=[('/tf', '/tf'), ('/tf_static', '/tf_static')]
        ),
        
        # Planner Server  
        Node(
            package='nav2_planner',
            executable='planner_server',
            name='planner_server',
            output='screen',
            parameters=[params_file, {'use_sim_time': use_sim_time}],
            remappings=[('/tf', '/tf'), ('/tf_static', '/tf_static')]
        ),
        
        # Behavior Server
        Node(
            package='nav2_behaviors',
            executable='behavior_server',
            name='behavior_server',
            output='screen',
            parameters=[params_file, {'use_sim_time': use_sim_time}],
            remappings=[('/tf', '/tf'), ('/tf_static', '/tf_static')]
        ),
        
        # BT Navigator
        Node(
            package='nav2_bt_navigator',
            executable='bt_navigator',
            name='bt_navigator',
            output='screen',
            parameters=[params_file, {'use_sim_time': use_sim_time}],
            remappings=[('/tf', '/tf'), ('/tf_static', '/tf_static')]
        ),
        
        # Waypoint Follower
        Node(
            package='nav2_waypoint_follower',
            executable='waypoint_follower',
            name='waypoint_follower',
            output='screen',
            parameters=[params_file, {'use_sim_time': use_sim_time}],
            remappings=[('/tf', '/tf'), ('/tf_static', '/tf_static')]
        ),
        
        # Lifecycle Manager
        Node(
            package='nav2_lifecycle_manager',
            executable='lifecycle_manager',
            name='lifecycle_manager_navigation',
            output='screen',
            parameters=[{'use_sim_time': use_sim_time},
                       {'autostart': autostart},
                       {'node_names': ['controller_server',
                                      'planner_server',
                                      'behavior_server',
                                      'bt_navigator',
                                      'waypoint_follower']}],
        ),
    ])
    
    return LaunchDescription([
        DeclareLaunchArgument('namespace', default_value=''),
        DeclareLaunchArgument('params_file', default_value=''),
        DeclareLaunchArgument('use_sim_time', default_value='false'),
        DeclareLaunchArgument('autostart', default_value='true'),
        
        nav2_nodes
    ])
