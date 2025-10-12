# ============================================================================
# ShadowHound Configuration for vLLM on Thor
# ============================================================================
#
# This configuration is optimized for using vLLM running on Thor (Jetson).
#
# NOTE: The agent will AUTO-DETECT that you're using a local LLM (non-OpenAI
# base URL) and automatically use local embeddings. You don't NEED to set
# USE_LOCAL_EMBEDDINGS=true, but you can if you want to be explicit.
#
# ============================================================================

# Agent Configuration - vLLM on Thor
AGENT_BACKEND=openai
OPENAI_BASE_URL=http://192.168.10.116:8000/v1
OPENAI_MODEL=Qwen/Qwen2.5-Coder-7B-Instruct
USE_PLANNING_AGENT=false

# API key (required by DIMOS but not used with vLLM)
OPENAI_API_KEY=sk-dummy-key-for-vllm

# Embeddings (OPTIONAL - auto-detected)
# The agent automatically uses local embeddings when OPENAI_BASE_URL
# is NOT api.openai.com. Uncomment to override:
# USE_LOCAL_EMBEDDINGS=true

# Optional RAG settings
RAG_QUERY_N=3
RAG_SIMILARITY_THRESHOLD=0.4

# Robot configuration
ROBOT_IP=192.168.1.103
CONN_TYPE=webrtc
MOCK_ROBOT=false

# ROS configuration
ROS_DOMAIN_ID=0
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Web interface
ENABLE_WEB_INTERFACE=true
WEB_PORT=8080
WEB_HOST=0.0.0.0

# Logging
LOG_LEVEL=DEBUG
DIMOS_DEBUG=true

# ============================================================================
# Troubleshooting
# ============================================================================
#
# Error: "ValueError: No embedding data received"
#   → Solution: Set USE_LOCAL_EMBEDDINGS=true (vLLM doesn't support embeddings)
#
# Error: "Connection refused"
#   → Verify vLLM running: curl http://192.168.10.116:8000/health
#
# Error: "401 Unauthorized" during vLLM startup
#   → Run: huggingface-cli login
#   → Accept: https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct
#
# ============================================================================

