#!/bin/bash
# Test if vLLM is returning proper tool_calls format

curl -X POST http://192.168.10.116:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "mistralai/Mistral-7B-Instruct-v0.3",
    "messages": [
      {"role": "system", "content": "You are a robot controller. You MUST call the provided functions to control the robot. NEVER explain how to use functions - ALWAYS call them directly."},
      {"role": "user", "content": "Move forward 1 meter"}
    ],
    "tools": [{
      "type": "function",
      "function": {
        "name": "Move",
        "description": "Move the robot forward/backward and left/right",
        "parameters": {
          "type": "object",
          "properties": {
            "x": {"type": "number", "description": "Forward velocity (m/s)"},
            "y": {"type": "number", "description": "Left/right velocity (m/s)"},
            "yaw": {"type": "number", "description": "Rotational velocity (rad/s)"},
            "duration": {"type": "number", "description": "Duration in seconds"}
          },
          "required": ["x", "y", "yaw", "duration"]
        }
      }
    }],
    "tool_choice": "auto"
  }' | jq '.'
