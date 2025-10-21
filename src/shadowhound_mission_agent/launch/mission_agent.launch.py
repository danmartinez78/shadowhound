"""Launch file for ShadowHound Mission Agent."""

import os
from pathlib import Path

from launch_ros.actions import Node

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, SetEnvironmentVariable
from launch.substitutions import LaunchConfiguration


def generate_launch_description():
    """Generate launch description for mission agent."""

    # Get DIMOS path (assuming it's in the workspace)
    workspace_dir = Path(__file__).resolve().parents[3]  # Go up to workspace root
    dimos_path = workspace_dir / "src" / "dimos-unitree"

    # Set PYTHONPATH to include DIMOS
    pythonpath_env = SetEnvironmentVariable(
        "PYTHONPATH", str(dimos_path) + os.pathsep + os.environ.get("PYTHONPATH", "")
    )

    # Declare launch arguments
    agent_backend_arg = DeclareLaunchArgument(
        "agent_backend",
        default_value="openai",
        description="Agent backend: 'openai' (cloud) or 'ollama' (self-hosted)",
    )

    robot_mode_arg = DeclareLaunchArgument(
        "robot_mode",
        default_value="mock",
        description=(
            "Robot mode: 'hardware' (real Unitree Go2), "
            "'simulation' (Isaac Sim with namespace), "
            "'mock' (pure software mock)"
        ),
    )

    use_planning_arg = DeclareLaunchArgument(
        "use_planning_agent",
        default_value="false",
        description="Use planning agent for multi-step missions (true/false)",
    )

    # OpenAI backend arguments
    openai_model_arg = DeclareLaunchArgument(
        "openai_model",
        default_value="gpt-4-turbo",
        description="OpenAI model name (e.g., gpt-4-turbo, gpt-3.5-turbo)",
    )

    openai_base_url_arg = DeclareLaunchArgument(
        "openai_base_url",
        default_value="https://api.openai.com/v1",
        description="OpenAI API base URL",
    )

    # Ollama backend arguments
    ollama_base_url_arg = DeclareLaunchArgument(
        "ollama_base_url",
        default_value="http://localhost:11434",
        description="Ollama server URL (e.g., http://192.168.1.100:11434 for remote)",
    )

    ollama_model_arg = DeclareLaunchArgument(
        "ollama_model",
        default_value="llama3.1:70b",
        description="Ollama model name (e.g., llama3.1:70b, llama3.1:13b, mistral)",
    )

    # Mission agent node
    # Robot mode determines topic remapping and connection type:
    # - 'hardware': Real robot, no remapping, WebRTC connection
    # - 'simulation': Isaac Sim, robot0 namespace remapping, CycloneDDS
    # - 'mock': Pure software mock, no remapping, no external topics
    mission_agent_node = Node(
        package="shadowhound_mission_agent",
        executable="mission_agent",
        name="mission_agent",
        output="screen",
        parameters=[
            {
                "agent_backend": LaunchConfiguration("agent_backend"),
                "robot_mode": LaunchConfiguration("robot_mode"),
                "use_planning_agent": LaunchConfiguration("use_planning_agent"),
                "openai_model": LaunchConfiguration("openai_model"),
                "openai_base_url": LaunchConfiguration("openai_base_url"),
                "ollama_base_url": LaunchConfiguration("ollama_base_url"),
                "ollama_model": LaunchConfiguration("ollama_model"),
            }
        ],
        remappings=[
            # Topic remapping for simulation mode (go2_omniverse uses /robot0/* namespace)
            # For hardware and mock modes, these remappings are harmless (topics don't exist anyway)
            # TODO: Make this conditional based on robot_mode once LaunchCondition supports it
            # Command topics (absolute and relative)
            ("/cmd_vel", "/robot0/cmd_vel"),
            ("cmd_vel", "robot0/cmd_vel"),  # Relative (DIMOS uses relative names)
            ("/cmd_vel_out", "/robot0/cmd_vel"),
            ("cmd_vel_out", "robot0/cmd_vel"),
            # Sensor topics (absolute and relative)
            ("/odom", "/robot0/odom"),
            ("odom", "robot0/odom"),
            ("/imu", "/robot0/imu"),
            ("imu", "robot0/imu"),
            ("/joint_states", "/robot0/joint_states"),
            ("joint_states", "robot0/joint_states"),
            # Camera topics (absolute and relative)
            # CRITICAL FIX: mission_executor.py now uses use_raw=True
            # This means DIMOS subscribes to camera/image_raw (Image type)
            # Sim publishes /robot0/front_cam/rgb (Image type)
            ("/camera/image_raw", "/robot0/front_cam/rgb"),  # Mission agent absolute
            (
                "camera/image_raw",
                "robot0/front_cam/rgb",
            ),  # DIMOS relative (use_raw=True)
            # Robot state topics (DIMOS subscriptions - relative names!)
            ("/go2_states", "/robot0/go2_states"),
            ("go2_states", "robot0/go2_states"),
            # LiDAR/Scan topics (absolute and relative)
            ("/scan", "/robot0/point_cloud2_L1"),
            ("scan", "robot0/point_cloud2_L1"),
            # Navigation topics (absolute and relative)
            ("/local_costmap/costmap", "/robot0/local_costmap/costmap"),
            ("local_costmap/costmap", "robot0/local_costmap/costmap"),
            ("/global_costmap/costmap", "/robot0/global_costmap/costmap"),
            ("global_costmap/costmap", "robot0/global_costmap/costmap"),
            ("/map", "/robot0/map"),
            ("map", "robot0/map"),
        ],
        emulate_tty=True,
    )

    return LaunchDescription(
        [
            pythonpath_env,
            agent_backend_arg,
            robot_mode_arg,
            use_planning_arg,
            openai_model_arg,
            openai_base_url_arg,
            ollama_base_url_arg,
            ollama_model_arg,
            mission_agent_node,
        ]
    )
