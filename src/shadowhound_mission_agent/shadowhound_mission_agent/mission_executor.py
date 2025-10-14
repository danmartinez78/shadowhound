#!/usr/bin/env python3
"""Mission Executor - The Robot's Cognitive Layer (Brain/Personality).

This module contains the robot's intelligence/decision-making logic, separated from
ROS infrastructure. It initializes and coordinates DIMOS components (robot, agent,
skills) to execute natural language missions via LLM reasoning.

Architecture:
    MissionNode (ROS2) → MissionExecutor (this file) → DIMOS Agent → Robot

Key Responsibilities:
    - Initialize DIMOS robot interface (UnitreeGo2)
    - Initialize DIMOS agent (OpenAIAgent/PlanningAgent)
    - Configure LLM backend (OpenAI cloud vs Ollama local)
    - Execute missions through LLM reasoning and tool calling
    - Manage semantic memory and context (RAG)

What This Is NOT:
    - NOT a ROS2 node (pure Python, no rclpy)
    - NOT tied to ROS topics/services
    - CAN be used in scripts, notebooks, tests without ROS

Design Pattern:
    Humble Object - Separates business logic from infrastructure.
    This enables testing without ROS and reuse in multiple contexts.

Future Refactor:
    Will be renamed to RobotAgent in Phase 1 to better reflect its role
    as the robot's intelligence layer. See docs/development/naming_refactor_plan.md

For detailed architecture documentation, see:
    docs/architecture/mission_agent_vs_executor.md
    docs/development/agent_robot_decoupling_analysis.md

Example Usage:
    # In ROS2 Node
    config = MissionExecutorConfig(agent_backend="ollama")
    executor = MissionExecutor(config, logger=node.get_logger())
    executor.initialize()
    response, timing = executor.execute_mission("patrol perimeter")

    # In Jupyter Notebook
    executor = MissionExecutor(MissionExecutorConfig())
    executor.initialize()
    executor.execute_mission("stand up and wave")
"""

import logging
import os
from dataclasses import dataclass
from typing import Any, Dict, Optional

# Import DIMOS components
try:
    from dimos.agents.agent import OpenAIAgent
    from dimos.agents.memory.chroma_impl import LocalSemanticMemory
    from dimos.agents.planning_agent import PlanningAgent
    from dimos.robot.unitree.unitree_go2 import UnitreeGo2
    from dimos.robot.unitree.unitree_ros_control import UnitreeROSControl
    from dimos.robot.unitree.unitree_skills import MyUnitreeSkills

    DIMOS_AVAILABLE = True
except ImportError as e:
    DIMOS_AVAILABLE = False
    IMPORT_ERROR = str(e)


@dataclass
class MissionExecutorConfig:
    """Configuration for MissionExecutor.

    Backend Options:
    - 'openai': Use OpenAI cloud API (requires OPENAI_API_KEY)
    - 'ollama': Use Ollama (self-hosted, can be local or remote)

    Deployment Scenarios:
    - Development: agent_backend='ollama', ollama_base_url='http://<gaming-pc-ip>:11434'
    - Thor Production: agent_backend='ollama', ollama_base_url='http://localhost:11434'
    - Cloud Fallback: agent_backend='openai' (slower but higher quality)
    """

    agent_backend: str = "openai"  # 'openai' or 'ollama'
    use_planning_agent: bool = False  # Use PlanningAgent vs OpenAIAgent
    robot_ip: str = "192.168.1.103"  # Robot IP address
    webrtc_api_topic: str = "webrtc_req"  # ROS topic for WebRTC API commands

    # OpenAI backend settings (cloud)
    openai_model: str = "gpt-4-turbo"  # OpenAI model name
    openai_base_url: str = "https://api.openai.com/v1"  # OpenAI API endpoint

    # Ollama backend settings (self-hosted)
    ollama_base_url: str = "http://localhost:11434"  # Ollama server URL
    ollama_model: str = "llama3.1:70b"  # Ollama model name

    # Token limits (apply to both backends)
    max_output_tokens: int = (
        150  # Max tokens for model output (terse responses for faster inference)
    )
    max_input_tokens: int = 128000  # Max tokens for model input

    # Custom system prompt for function calling enforcement
    system_prompt: str = (
        "You are a quadruped robot controller. "
        "Use the available functions to control the robot. "
        "Be brief in your responses."
    )


class MissionExecutor:
    """Pure Python mission executor using DIMOS framework.

    This class contains the core mission execution logic without ROS dependencies.
    It can be used in ROS nodes, scripts, notebooks, or web applications.

    Example usage:
        # In a ROS node
        config = MissionExecutorConfig(agent_backend="cloud")
        executor = MissionExecutor(config, logger=node.get_logger())
        executor.initialize()
        result = executor.execute_mission("patrol the perimeter")

        # In a script
        executor = MissionExecutor(MissionExecutorConfig())
        executor.initialize()
        result = executor.execute_mission("go to waypoint A")

        # In a notebook
        import logging
        logger = logging.getLogger(__name__)
        executor = MissionExecutor(MissionExecutorConfig(), logger=logger)
        executor.initialize()
    """

    def __init__(
        self, config: MissionExecutorConfig, logger: Optional[logging.Logger] = None
    ):
        """Initialize mission executor.

        Args:
            config: Configuration for the executor
            logger: Optional logger (uses standard logging if not provided)
        """
        self.config = config
        self.logger = logger or logging.getLogger(__name__)

        # DIMOS components (initialized in initialize())
        self.robot: Optional[UnitreeGo2] = None
        self.skills: Optional[MyUnitreeSkills] = None
        self.agent: Optional[OpenAIAgent] = None

        # Initialization state
        self._initialized = False

        # Check DIMOS availability
        if not DIMOS_AVAILABLE:
            raise RuntimeError(f"DIMOS framework not available: {IMPORT_ERROR}")

    def initialize(self) -> None:
        """Initialize robot, skills, and agent.

        This must be called before execute_mission(). Separated from __init__
        to allow for explicit initialization timing (e.g., after ROS node is ready).

        Raises:
            RuntimeError: If initialization fails
        """
        if self._initialized:
            self.logger.warning("MissionExecutor already initialized, skipping")
            return

        self.logger.info("Initializing MissionExecutor...")

        try:
            # 1. Initialize robot interface
            self._init_robot()

            # 2. Initialize skill library
            self._init_skills()

            # 3. Initialize agent
            self._init_agent()

            self._initialized = True
            self.logger.info("MissionExecutor initialization complete")

        except Exception as e:
            self.logger.error(f"Failed to initialize MissionExecutor: {e}")
            raise

    def _init_robot(self) -> None:
        """Initialize DIMOS robot interface."""
        self.logger.info("Initializing robot interface...")

        # Log connection mode for diagnostics
        conn_type = os.getenv("CONN_TYPE", "cyclonedds")
        self.logger.info(f"Connection type: {conn_type}")

        if conn_type == "webrtc":
            self.logger.info(
                "WebRTC mode: High-level API commands (sit, stand, wave) enabled"
            )
        else:
            self.logger.warning(
                "CycloneDDS mode: High-level API commands NOT available"
            )
            self.logger.warning("Set CONN_TYPE=webrtc to enable DIMOS skills")

        # Initialize ROS control bridge
        # Note: This uses ROS topics but doesn't require the caller to be a ROS node
        ros_control = UnitreeROSControl(webrtc_api_topic=self.config.webrtc_api_topic)

        # Initialize robot with ROS provider
        # CONN_TYPE env var controls the underlying communication protocol
        self.robot = UnitreeGo2(
            ros_control=ros_control,
            ip=self.config.robot_ip,
        )

        self.logger.info(f"Robot initialized (ip={self.config.robot_ip})")

    def _init_skills(self) -> None:
        """Initialize DIMOS skill library.

        Skills are needed for function calling with both OpenAIAgent and PlanningAgent.
        Always load skills - the agent will use them if the model supports tools.
        """
        if not self.robot:
            raise RuntimeError("Robot must be initialized before skills")

        self.logger.info("Initializing skill library...")
        self.skills = MyUnitreeSkills(robot=self.robot)
        skill_count = len(self.skills.get())
        self.logger.info(f"Loaded {skill_count} skills for function calling")

    def _init_agent(self) -> None:
        """Initialize DIMOS agent with appropriate backend."""
        if not self.skills:
            raise RuntimeError("Skills must be initialized before agent")

        self.logger.info(
            f"Initializing {self.config.agent_backend} agent "
            f"({'planning' if self.config.use_planning_agent else 'openai'})..."
        )

        # Configure OpenAI client based on backend
        from openai import OpenAI

        if self.config.agent_backend == "ollama":
            # Use Ollama backend (self-hosted LLM)
            self.logger.info(f"Using Ollama backend at {self.config.ollama_base_url}")
            client = OpenAI(
                base_url=f"{self.config.ollama_base_url}/v1",
                api_key="ollama",  # Ollama doesn't validate API keys
            )
            model_name = self.config.ollama_model
            self.logger.info(f"Ollama model: {model_name}")

        elif self.config.agent_backend == "openai":
            # Use OpenAI cloud backend
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                self.logger.warning("OPENAI_API_KEY not set, agent may not function")

            self.logger.info("Using OpenAI cloud backend")
            client = OpenAI(base_url=self.config.openai_base_url, api_key=api_key)
            model_name = self.config.openai_model
            self.logger.info(f"OpenAI model: {model_name}")

        else:
            raise ValueError(
                f"Unknown agent_backend: {self.config.agent_backend}. "
                "Must be 'openai' or 'ollama'"
            )

        # Create DIMOS agent based on type
        if self.config.use_planning_agent:
            # PlanningAgent needs skills parameter, not robot
            self.agent = PlanningAgent(
                dev_name="shadowhound",
                model_name=model_name,
                skills=self.skills,
            )
            self.logger.info("DIMOS PlanningAgent initialized")
        else:
            # Determine embeddings strategy based on backend and configuration
            # Strategy:
            # 1. If USE_LOCAL_EMBEDDINGS explicitly set, honor it
            # 2. If using local LLM (non-OpenAI base URL), default to local embeddings
            # 3. If using OpenAI cloud (api.openai.com), default to OpenAI embeddings

            use_local_env = os.getenv("USE_LOCAL_EMBEDDINGS", "").lower()

            if use_local_env in ("true", "false"):
                # User explicitly set preference
                use_local_embeddings = use_local_env == "true"
                self.logger.info(
                    f"Embeddings: Using explicit setting USE_LOCAL_EMBEDDINGS={use_local_embeddings}"
                )
            else:
                # Auto-detect based on backend
                is_openai_cloud = (
                    self.config.agent_backend == "openai"
                    and "api.openai.com" in self.config.openai_base_url
                )

                if is_openai_cloud:
                    # OpenAI cloud supports embeddings API
                    use_local_embeddings = False
                    self.logger.info(
                        "Embeddings: Auto-detected OpenAI cloud, using OpenAI embeddings API"
                    )
                else:
                    # Local LLM (vLLM, llama.cpp, Ollama) - use local embeddings
                    use_local_embeddings = True
                    self.logger.info(
                        f"Embeddings: Auto-detected local LLM backend "
                        f"({self.config.agent_backend}), using local embeddings"
                    )

            if use_local_embeddings:
                # Use local embeddings (sentence-transformers)
                # Works with: vLLM, llama.cpp, Ollama, or any local LLM
                try:
                    agent_memory = LocalSemanticMemory(
                        collection_name="shadowhound_memory",
                        model_name="sentence-transformers/all-MiniLM-L6-v2",
                    )
                    self.logger.info(
                        "✓ Agent memory: LocalSemanticMemory (sentence-transformers/all-MiniLM-L6-v2)"
                    )
                except ImportError as e:
                    # Missing dependencies for ChromaDB/sentence-transformers
                    self.logger.warning(
                        "⚠ LocalSemanticMemory dependencies not installed"
                    )
                    self.logger.warning(f"  Missing: {str(e)}")
                    self.logger.warning(
                        "  Install with: pip install chromadb langchain-chroma langchain-openai sentence-transformers"
                    )
                    self.logger.warning(
                        "  Continuing without persistent memory (agent will work but no RAG)"
                    )
                    # CRITICAL: Don't pass agent_memory=None with local LLM!
                    # DIMOS will auto-create OpenAISemanticMemory which calls embeddings endpoint
                    # that doesn't exist on vLLM/local LLMs.
                    # Solution: Create a dummy/no-op memory or skip agent_memory parameter entirely.
                    agent_memory = "skip"  # Signal to not pass agent_memory parameter
                except Exception as e:
                    # Handle DIMOS AgentMemoryConnectionError bug or other initialization errors
                    # CRITICAL: Don't call str(e) - DIMOS exception __str__ has a bug (accesses self.message)
                    # Use repr() or type name instead to avoid triggering the bug
                    error_type = type(e).__name__
                    error_args = repr(e.args) if e.args else "no details"
                    self.logger.warning(
                        f"⚠ Failed to initialize LocalSemanticMemory: {error_type} - {error_args}"
                    )
                    self.logger.warning(
                        "  Continuing without persistent memory (agent will work but no RAG)"
                    )
                    agent_memory = "skip"  # Signal to not pass agent_memory parameter
            else:
                # Use OpenAI embeddings API
                # Works with: OpenAI cloud API only
                agent_memory = None  # Let DIMOS use default OpenAISemanticMemory
                self.logger.info(
                    "✓ Agent memory: OpenAISemanticMemory (text-embedding-3-large)"
                )

            # OpenAIAgent with skills for function calling
            # Both OpenAI and Ollama (with tool-capable models) support this
            agent_kwargs = {
                "dev_name": "shadowhound",
                "agent_type": "Mission",
                "model_name": model_name,
                "skills": self.skills,  # Enable function calling
                "openai_client": client,  # Pass custom client for backend flexibility
                "system_query": self.config.system_prompt,  # Custom prompt for function calling
                "max_output_tokens_per_request": self.config.max_output_tokens,
                "max_input_tokens_per_request": self.config.max_input_tokens,
            }

            # Only pass agent_memory if we have a valid one (not "skip")
            # This prevents DIMOS from auto-creating OpenAISemanticMemory for local LLMs
            if agent_memory != "skip":
                agent_kwargs["agent_memory"] = agent_memory

            self.agent = OpenAIAgent(**agent_kwargs)
            self.logger.info(
                f"DIMOS OpenAIAgent initialized with {len(self.skills.get())} skills "
                f"(backend={self.config.agent_backend}, model={model_name})"
            )

    def execute_mission(self, command: str) -> tuple[str, dict]:
        """Execute a mission command.

        Args:
            command: Natural language mission command

        Returns:
            Tuple of (response string, timing dict)
            Timing dict contains: agent_duration, total_duration, overhead_duration

        Raises:
            RuntimeError: If executor not initialized or execution fails
        """
        import time

        if not self._initialized:
            raise RuntimeError(
                "MissionExecutor not initialized. Call initialize() first."
            )

        self.logger.info(f"Executing mission: {command}")
        start_time = time.time()

        try:
            # Execute through DIMOS agent
            agent_start = time.time()
            if self.config.use_planning_agent:
                # PlanningAgent uses process_user_input() for interaction
                # Since we're in web mode (not terminal), we call it directly
                # and then get the response from the observable
                self.agent.process_user_input(command)
                # Get response from the observable stream
                response = ""
                if self.agent.latest_response:
                    if self.agent.latest_response.get("type") == "dialogue":
                        response = self.agent.latest_response.get("content", "")
                    elif self.agent.latest_response.get("type") == "plan":
                        steps = self.agent.latest_response.get("content", [])
                        response = "Plan:\n" + "\n".join(
                            f"{i+1}. {step}" for i, step in enumerate(steps)
                        )
            else:
                # OpenAIAgent uses run_observable_query() which returns an Observable
                response = self.agent.run_observable_query(command).run()

            agent_duration = time.time() - agent_start
            total_duration = time.time() - start_time
            overhead_duration = total_duration - agent_duration

            timing_info = {
                "agent_duration": agent_duration,
                "total_duration": total_duration,
                "overhead_duration": overhead_duration,
                "agent_percentage": (
                    (agent_duration / total_duration * 100) if total_duration > 0 else 0
                ),
            }

            self.logger.info(f"⏱️  Timing breakdown:")
            self.logger.info(
                f"   Agent call: {agent_duration:.2f}s ({timing_info['agent_percentage']:.0f}%)"
            )
            self.logger.info(f"   Overhead:   {overhead_duration:.3f}s")
            self.logger.info(f"   Total:      {total_duration:.2f}s")
            self.logger.info(f"Mission completed: {response[:100]}...")
            return response, timing_info

        except Exception as e:
            self.logger.error(f"Mission execution failed: {e}")
            raise

    def get_robot_status(self) -> Dict[str, Any]:
        """Get current robot status.

        Returns:
            Dictionary with robot status information

        Raises:
            RuntimeError: If robot not initialized
        """
        if not self.robot:
            raise RuntimeError("Robot not initialized")

        # TODO: Implement robot status query
        # This would call robot.get_state() or similar
        return {
            "initialized": self._initialized,
            "robot_ip": self.config.robot_ip,
            "skills_count": len(self.skills.get()) if self.skills else 0,
        }

    def get_available_skills(self) -> list:
        """Get list of available skills.

        Returns:
            List of skill information

        Raises:
            RuntimeError: If skills not initialized
        """
        if not self.skills:
            raise RuntimeError("Skills not initialized")

        return self.skills.get()

    def cleanup(self) -> None:
        """Clean up resources."""
        self.logger.info("Cleaning up MissionExecutor...")

        if self.agent:
            try:
                self.agent.dispose_all()
            except Exception as e:
                self.logger.warning(f"Error disposing agent: {e}")

        # Robot cleanup if needed
        if self.robot:
            try:
                # Add any robot cleanup if needed
                pass
            except Exception as e:
                self.logger.warning(f"Error cleaning up robot: {e}")

        self._initialized = False
        self.logger.info("MissionExecutor cleanup complete")
