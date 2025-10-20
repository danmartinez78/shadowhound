"""Launch file for ShadowHound Mission Agent."""

import os
from pathlib import Path
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, SetEnvironmentVariable
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


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

    mock_robot_arg = DeclareLaunchArgument(
        "mock_robot",
        default_value="true",
        description="Use mock robot connection (true/false)",
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
    # TODO: Remove topic remapping once namespace support is added (make robot_namespace configurable)
    # This is a temporary workaround for go2_omniverse sim which uses /robot0/* namespace
    mission_agent_node = Node(
        package="shadowhound_mission_agent",
        executable="mission_agent",
        name="mission_agent",
        output="screen",
        parameters=[
            {
                "agent_backend": LaunchConfiguration("agent_backend"),
                "mock_robot": LaunchConfiguration("mock_robot"),
                "use_planning_agent": LaunchConfiguration("use_planning_agent"),
                "openai_model": LaunchConfiguration("openai_model"),
                "openai_base_url": LaunchConfiguration("openai_base_url"),
                "ollama_base_url": LaunchConfiguration("ollama_base_url"),
                "ollama_model": LaunchConfiguration("ollama_model"),
            }
        ],
        remappings=[
            # Map standard topics to robot0 namespace (go2_omniverse sim)
            ("/cmd_vel", "/robot0/cmd_vel"),
            ("/odom", "/robot0/odom"),
            ("/imu", "/robot0/imu"),
            ("/joint_states", "/robot0/joint_states"),
            ("/camera/image_raw", "/robot0/front_cam/rgb"),
            ("/scan", "/robot0/point_cloud2_L1"),  # Point cloud, not laser scan
        ],
        emulate_tty=True,
    )

    return LaunchDescription(
        [
            pythonpath_env,
            agent_backend_arg,
            mock_robot_arg,
            use_planning_arg,
            openai_model_arg,
            openai_base_url_arg,
            ollama_base_url_arg,
            ollama_model_arg,
            mission_agent_node,
        ]
    )
