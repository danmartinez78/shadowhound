from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration

def generate_launch_description():
    backend = LaunchConfiguration('backend')
    return LaunchDescription([
        DeclareLaunchArgument('backend', default_value='cloud'),
        Node(
            package='shadowhound_mission_agent',
            executable='mission_agent',
            parameters=[{'backend': backend}],
            output='screen',
        )
    ])
