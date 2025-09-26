from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, GroupAction, SetEnvironmentVariable, OpaqueFunction
from launch.substitutions import LaunchConfiguration, PythonExpression
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.actions import IncludeLaunchDescription
from launch.substitutions import PathJoinSubstitution

def include_dimos_driver(context, *args, **kwargs):
    profile = LaunchConfiguration("profile").perform(context)
    # Map profile -> comm_mode expected by the dimos-unitree bringup (adjust to actual arg names)
    comm_mode = "webrtc" if profile == "laptop_webrtc" else "ethernet"

    # Best-guess: dimos-unitree has a bringup launch under its share/launch folder.
    # If the actual filename differs, change 'bringup.launch.py' here.
    dimos_launch = PathJoinSubstitution([
        FindPackageShare('dimos_unitree'), 'launch', 'bringup.launch.py'
    ])

    return [IncludeLaunchDescription(
        PythonLaunchDescriptionSource(dimos_launch),
        launch_arguments={
            # Common patterns; rename keys to match dimos-unitree's expected args.
            'comm_mode': comm_mode,
            'enable_camera': 'true',
            'use_sim_time': 'false',
        }.items()
    )]

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

        # Ensure RMW is consistent (optional; override in shell or profiles)
        SetEnvironmentVariable("ROS_DOMAIN_ID", "7"),

        # Include the dimos-unitree driver using the selected profile
        OpaqueFunction(function=include_dimos_driver),

        # ShadowHound mission agent
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
