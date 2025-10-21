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
    robot_namespace_arg = DeclareLaunchArgument(
        "robot_namespace",
        default_value="tachi",
        description="Robot namespace (e.g., tachi, ghost, motoko). Used in hardware and sim.",
    )

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
    # Robot namespace is now passed as parameter to mission_executor.py
    # DIMOS UnitreeGo2(namespace=robot_namespace) handles topic namespacing automatically
    # No need for topic remappings - DIMOS handles it!
    mission_agent_node = Node(
        package="shadowhound_mission_agent",
        executable="mission_agent",
        name="mission_agent",
        output="screen",
        parameters=[
            {
                "robot_namespace": LaunchConfiguration("robot_namespace"),
                "agent_backend": LaunchConfiguration("agent_backend"),
                "robot_mode": LaunchConfiguration("robot_mode"),
                "use_planning_agent": LaunchConfiguration("use_planning_agent"),
                "openai_model": LaunchConfiguration("openai_model"),
                "openai_base_url": LaunchConfiguration("openai_base_url"),
                "ollama_base_url": LaunchConfiguration("ollama_base_url"),
                "ollama_model": LaunchConfiguration("ollama_model"),
            }
        ],
        emulate_tty=True,
    )

    return LaunchDescription(
        [
            pythonpath_env,
            robot_namespace_arg,
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
