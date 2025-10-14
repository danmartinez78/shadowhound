---
tags: [issue, workaround, llm, function-calling]
status: testing
related: []
summary: >
  System prompt engineering to force LLM function calling without modifying DIMOS
---

# Forcing Function Calling with System Prompts

## Problem

Mistral LLM (via vLLM) returns explanations instead of calling functions:

```
User: "take one small step back"

Expected: Reverse(x=-0.1, y=0.0, yaw=0.0, duration=1.0)

Actual: "To physically move the robot one small step back using the 
provided functions, I would use the `Reverse` function with a small 
backward velocity. Here's an example of how to do this..."
```

**Root Cause:**
- OpenAI API expects `tool_choice="auto"` to enforce function calling
- DIMOS `OpenAIAgent` doesn't set this parameter
- Without it, LLM treats tools as "suggestions" not "requirements"

## Why We Can't Fix It Properly

**Ideal Solution:**
Modify `dimos/agents/agent.py` to add:
```python
response = self.client.chat.completions.create(
    model=self.model_name,
    messages=messages,
    tools=self.skill_library.get_tools(),
    tool_choice="auto",  # ← Add this
    temperature=0.0,     # ← And this for speed
)
```

**Blocker:**
- DIMOS is a git submodule (`src/dimos-unitree/`)
- Project policy: Never edit submodule files directly
- See: `docs/submodule_policy.md`
- Changes must go through upstream DIMOS contribution process

## Workaround: System Prompt Engineering

Instead of modifying DIMOS, we use **aggressive prompt engineering** to force function calling behavior.

### Implementation

**File:** `src/shadowhound_mission_agent/shadowhound_mission_agent/mission_executor.py`

```python
@dataclass
class MissionExecutorConfig:
    # Reduced tokens for faster responses
    max_output_tokens: int = 150  # Was 512
    
    # Aggressive system prompt
    system_prompt: str = (
        "You are a quadruped robot controller. "
        "You MUST call the provided functions to control the robot. "
        "NEVER explain how to use functions - ALWAYS call them directly. "
        "When the user says 'move forward', call Move(). "
        "When the user says 'step back', call Reverse(). "
        "When the user says 'spin left', call SpinLeft(). "
        "When the user says 'spin right', call SpinRight(). "
        "Be extremely brief with any text responses. "
        "Your PRIMARY job is to execute functions, not to chat."
    )

# Pass to agent
agent_kwargs = {
    "system_query": self.config.system_prompt,  # ← Use custom prompt
    "max_output_tokens_per_request": self.config.max_output_tokens,
    # ... other params
}
```

### Prompt Design Principles

1. **Imperative Language:**
   - "You MUST call" not "You can call"
   - "NEVER explain" not "Try not to explain"
   - Creates strong behavioral constraints

2. **Explicit Examples:**
   - Maps user language to function names
   - "move forward" → `Move()`
   - "step back" → `Reverse()`
   - Reduces ambiguity for the LLM

3. **Role Definition:**
   - "You are a robot controller" (not "assistant")
   - "PRIMARY job is to execute functions"
   - Sets expectation hierarchy

4. **Brevity Enforcement:**
   - "Be extremely brief"
   - Reduced max_tokens (512 → 150)
   - Faster inference, less rambling

## Testing

### Before (Default DIMOS Prompt):
```
User: take one small step back
Time: ~30 seconds
Response: [200+ tokens explaining how to use Reverse()]
Result: ❌ No robot motion
```

### After (Custom Prompt):
```
User: take one small step back
Time: ~5-10 seconds (expected)
Response: [Function call to Reverse() + brief confirmation]
Result: ✅ Robot moves backward
```

### Test Commands:
```bash
# On laptop
cd ~/shadowhound
rm -rf build/ install/ log/
./start.sh --prod

# In web UI (http://localhost:8501):
1. "take one small step back"    # Should call Reverse()
2. "move forward 2 meters"        # Should call Move()
3. "spin left 90 degrees"         # Should call SpinLeft()
4. "turn around"                  # Should call SpinLeft(180) or SpinRight(180)
```

## Effectiveness Analysis

### Strengths ✅
- **No DIMOS changes** - respects submodule policy
- **Fast to implement** - just config changes
- **Easy to tune** - adjust prompt text as needed
- **Portable** - works with any OpenAI-compatible backend

### Weaknesses ⚠️
- **Not guaranteed** - LLM can still ignore prompts
- **Model-dependent** - some models respect instructions better than others
- **Needs tuning** - may require iteration for different models
- **Indirect** - prompt engineering vs. API parameter

### When It Works Best:
- Instruction-following models (Mistral, Llama 3.1, GPT-4)
- Clear, unambiguous commands
- Function names that match natural language
- Low temperature settings (if model supports)

### When It Fails:
- Very creative/open-ended queries
- Models trained primarily for chat (not tool use)
- Complex multi-step reasoning tasks
- Ambiguous user commands

## Alternative Approaches (If This Fails)

### Option 1: Client Wrapper
Wrap OpenAI client to inject `tool_choice` before requests reach DIMOS:

```python
class ForcedToolCallingClient(OpenAI):
    def chat_completions_create(self, *args, **kwargs):
        if 'tools' in kwargs and kwargs['tools']:
            kwargs['tool_choice'] = 'auto'
            kwargs['temperature'] = 0.0
        return super().chat_completions_create(*args, **kwargs)

# Pass to agent
client = ForcedToolCallingClient(base_url=...)
agent = OpenAIAgent(openai_client=client, ...)
```

**Pros:** Guarantees tool_choice is set
**Cons:** Fragile, depends on OpenAI client internals

### Option 2: Fork DIMOS
Create temporary fork with tool_choice fix:

```bash
cd src/dimos-unitree
git checkout -b fix/tool-choice-auto
# Make changes
# Use forked version in .gitmodules
```

**Pros:** Proper fix, can PR upstream later
**Cons:** Diverges from upstream, merge conflicts

### Option 3: Upstream Contribution
Submit PR to DIMOS with tool_choice fix:

**Pros:** Benefits everyone, proper solution
**Cons:** Takes time, no guarantee of acceptance

## Success Metrics

Track these to evaluate prompt effectiveness:

```python
# In mission_executor.py or mission_agent.py
metrics = {
    "function_calls": 0,      # Count of actual function executions
    "text_responses": 0,      # Count of pure text responses
    "avg_response_time": 0,   # Seconds per command
    "avg_token_count": 0,     # Tokens in response
    "success_rate": 0,        # Function calls / total commands
}
```

**Target:** >90% success rate (9/10 commands trigger function calls)

## Configuration Options

Users can customize the prompt in their launch files:

```python
# In launch file or config
custom_config = MissionExecutorConfig(
    agent_backend="openai",
    openai_model="mistralai/Mistral-7B-Instruct-v0.3",
    max_output_tokens=100,  # Even terser
    system_prompt=(
        "Robot controller. Call functions. No explanations. "
        "Move=Move(), Back=Reverse(), Left=SpinLeft(), Right=SpinRight()."
    )
)
```

## Status

**Current State:** Implemented, awaiting testing

**Next Steps:**
1. ✅ Commit changes
2. ✅ Push to remote
3. ⏳ Test with real robot
4. ⏳ Measure success rate
5. ⏳ Tune prompt if needed
6. ⏳ Document results

**Expected Outcome:**
- Commands trigger function calls 90%+ of the time
- Response time: 5-10 seconds (down from 30s)
- Robot responds to natural language commands

**Fallback Plan:**
If prompt engineering isn't effective enough, implement client wrapper (Option 1 above).

## Related Issues

- [vllm_tool_calling_configuration](vllm_tool_calling_configuration.md) - vLLM setup for tool calling
- [vllm_mistral_tokenizer_hang](vllm_mistral_tokenizer_hang.md) - Mistral tokenizer fix
- [DIMOS Agent Architecture](../software/agent/dimos_agent_architecture.md) - Why OpenAIAgent is required

## References

- OpenAI Tool Calling Docs: https://platform.openai.com/docs/guides/function-calling
- vLLM Tool Calling: https://docs.vllm.ai/en/stable/features/tool_calling.html
- Mistral Function Calling: https://docs.mistral.ai/capabilities/function_calling/
