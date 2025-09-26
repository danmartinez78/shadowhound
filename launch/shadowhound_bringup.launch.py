from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

def generate_launch_description():
    profile = LaunchConfiguration("profile")
    backend = LaunchConfiguration("backend")
    llm_endpoint = LaunchConfiguration("llm_endpoint")

    return LaunchDescription([
        DeclareLaunchArgument("profile", default_value="laptop_webrtc",
                              description="laptop_webrtc or thor_ethernet"),
        DeclareLaunchArgument("backend", default_value="cloud",
                              description="cloud or local"),
        DeclareLaunchArgument("llm_endpoint", default_value="http://127.0.0.1:8000",
                              description="Local LLM/VLM endpoint used when backend=local"),

        # TODO: Include dimos-unitree driver launch as IncludeLaunchDescription here,
        # based on the chosen profile (webrtc vs ethernet).

        Node(
            package="shadowhound_mission_agent",
            executable="mission_agent",
            name="shadowhound_mission_agent",
            output="screen",
            parameters=[
                {"profile": profile},
                {"backend": backend},
                {"llm_endpoint": llm_endpoint},
            ],
        ),
    ])
