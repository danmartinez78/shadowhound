#!/usr/bin/env python3
"""
Robot Data Collection Launch
Launches Go2 SDK + Nav2 teleop with topic remapping to /robot0/* namespace for ODD pipeline.

Components:
  - Go2 driver (WebRTC)
  - Python LiDAR pointcloud processor
  - Nav2 for teleoperation
  - Topic remapping to /robot0/* namespace

Required topics for ODD analysis:
  /robot0/odom                - nav_msgs/Odometry
  /robot0/imu                 - sensor_msgs/Imu
  /robot0/joint_states        - sensor_msgs/JointState
  /robot0/front_cam/rgb       - sensor_msgs/Image
  /robot0/point_cloud2_L1     - sensor_msgs/PointCloud2

Usage:
    ros2 launch robot_data_collection.launch.py robot_ip:=192.168.1.103
    
    # In another terminal, record to /home/daniel/go2_bags
    cd /home/daniel/go2_bags
    ros2 bag record -a -o collection_$(date +%Y%m%d_%H%M%S)
"""

import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.conditions import IfCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    """Generate launch description for data collection with topic remapping."""

    # Declare launch arguments
    robot_ip_arg = DeclareLaunchArgument(
        "robot_ip",
        default_value=os.getenv("ROBOT_IP", "192.168.1.103"),
        description="IP address of the Go2 robot",
    )

    robot_token_arg = DeclareLaunchArgument(
        "robot_token",
        default_value=os.getenv("ROBOT_TOKEN", ""),
        description="Robot authentication token",
    )

    conn_type_arg = DeclareLaunchArgument(
        "conn_type",
        default_value="webrtc",
        description="Connection type: webrtc or cyclonedds",
    )

    with_nav2_arg = DeclareLaunchArgument(
        "nav2",
        default_value="true",
        description="Launch Nav2 for teleoperation",
    )

    # Get launch configurations
    robot_ip = LaunchConfiguration("robot_ip")
    robot_token = LaunchConfiguration("robot_token")
    conn_type = LaunchConfiguration("conn_type")
    with_nav2 = LaunchConfiguration("nav2")

    # Package paths
    package_dir = get_package_share_directory("go2_robot_sdk")
    urdf_file = os.path.join(package_dir, "urdf", "go2.urdf")
    nav2_params = os.path.join(package_dir, "config", "nav2_params.yaml")
    twist_mux_params = os.path.join(package_dir, "config", "twist_mux.yaml")

    # Load URDF
    with open(urdf_file, "r") as f:
        robot_desc = f.read()

    print("=" * 70)
    print("🎯 ROBOT DATA COLLECTION LAUNCH")
    print("=" * 70)
    print("\n📋 Components:")
    print("   ✓ Go2 SDK driver (WebRTC)")
    print("   ✓ Python LiDAR pointcloud processor")
    print("   ✓ Nav2 teleoperation")
    print("\n📋 Topics remapped to /robot0/* namespace:")
    print("   ✓ /robot0/odom              (nav_msgs/Odometry)")
    print("   ✓ /robot0/imu               (sensor_msgs/Imu)")
    print("   ✓ /robot0/joint_states      (sensor_msgs/JointState)")
    print("   ✓ /robot0/front_cam/rgb     (sensor_msgs/Image)")
    print("   ✓ /robot0/point_cloud2_L1   (sensor_msgs/PointCloud2)")
    print("\n💾 Bagfiles saved to: /home/daniel/go2_bags/")
    print("=" * 70 + "\n")

    return LaunchDescription(
        [
            # Arguments
            robot_ip_arg,
            robot_token_arg,
            conn_type_arg,
            with_nav2_arg,
            
            # Robot State Publisher (in robot0 namespace)
            Node(
                package="robot_state_publisher",
                executable="robot_state_publisher",
                name="robot_state_publisher",
                namespace="robot0",
                output="screen",
                parameters=[
                    {
                        "use_sim_time": False,
                        "robot_description": robot_desc,
                    }
                ],
            ),
            
            # Go2 Driver Node (with remapping to /robot0/*)
            Node(
                package="go2_robot_sdk",
                executable="go2_driver_node",
                name="go2_driver_node",
                output="screen",
                parameters=[
                    {
                        "robot_ip": robot_ip,
                        "token": robot_token,
                        "conn_type": conn_type,
                    }
                ],
                remappings=[
                    # Remap native topics to /robot0/* namespace
                    ("/odom", "/robot0/odom"),
                    ("/imu", "/robot0/imu"),
                    ("/joint_states", "/robot0/joint_states"),
                    ("/camera/image_raw", "/robot0/front_cam/rgb"),
                    ("/camera/compressed", "/robot0/front_cam/compressed"),
                    ("/point_cloud2", "/robot0/point_cloud2_L1"),
                    ("/cmd_vel", "/robot0/cmd_vel"),
                    ("/tf", "/tf"),
                    ("/tf_static", "/tf_static"),
                ],
            ),
            
            # Python LiDAR to PointCloud Node (use python version, not cpp)
            Node(
                package="lidar_processor",
                executable="lidar_to_pointcloud",
                name="lidar_to_pointcloud",
                output="screen",
                parameters=[
                    {
                        "robot_ip_lst": [robot_ip],
                        "map_name": "data_collection",
                        "map_save": "false",  # Don't save maps during data collection
                    }
                ],
                remappings=[
                    ("/point_cloud2", "/robot0/point_cloud2_L1"),
                ],
            ),
            
            # PointCloud to LaserScan (for Nav2)
            Node(
                package="pointcloud_to_laserscan",
                executable="pointcloud_to_laserscan_node",
                name="pointcloud_to_laserscan",
                namespace="robot0",
                output="screen",
                remappings=[
                    ("cloud_in", "point_cloud2_L1"),
                    ("scan", "scan"),
                ],
                parameters=[
                    {
                        "target_frame": "robot0/base_link",
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
            ),

            # Twist Multiplexer (for teleop priority)
            Node(
                package="twist_mux",
                executable="twist_mux",
                name="twist_mux",
                namespace="robot0",
                output="screen",
                parameters=[
                    {"use_sim_time": False},
                    twist_mux_params,
                ],
                remappings=[
                    ("/cmd_vel_out", "/robot0/cmd_vel"),
                ],
            ),
            
            # Nav2 for teleoperation
            IncludeLaunchDescription(
                PythonLaunchDescriptionSource(
                    [
                        os.path.join(
                            get_package_share_directory("nav2_bringup"),
                            "launch",
                            "navigation_launch.py",
                        )
                    ]
                ),
                condition=IfCondition(with_nav2),
                launch_arguments={
                    "namespace": "robot0",
                    "params_file": nav2_params,
                    "use_sim_time": "false",
                    "autostart": "true",
                }.items(),
            ),
        ]
    )
