---
name: n8n-ai-agents
description: Master building AI agent workflows with n8n and LangChain. Use when creating intelligent agents, tool definitions, memory systems, multi-step reasoning, or agent error handling. Covers agent architecture, tool integration, and production patterns.
---

# n8n AI Agents

Build intelligent AI agents using n8n and LangChain integration.

---

## AI Agent Architecture in n8n

### What is an AI Agent?

An agent that:
1. **Perceives** - Receives input and context
2. **Reasons** - Decides what to do
3. **Acts** - Calls tools/APIs
4. **Learns** - Updates memory with results
5. **Repeats** - Iterates until goal achieved

### Basic Flow

```
User Input → Agent Prompt → LLM Decision → [Which tool?]
                                ↓
                           Call Tool
                                ↓
                           Tool Result
                                ↓
                    Update Memory / Context
                                ↓
                    [Goal Achieved?]
                    ├─ Yes → Return Result
                    └─ No → Reason Again
```

---

## Core Components

### 1. LangChain Agent Node

**Triggers**: Recognizes when to use LLM for decision-making

**Input**:
```javascript
{
  prompt: "Find the weather for Paris",
  tools: [weatherTool, calculatorTool],
  memory: {...},  // Previous context
  model: "gpt-4"
}
```

**Output**:
```javascript
{
  action: "weather",     // Which tool to call
  action_input: "Paris", // Tool parameters
  thought: "I need to check weather in Paris"
}
```

### 2. Tool Definitions

**Each tool needs**:
```javascript
{
  name: "weather",
  description: "Get weather for a location",
  parameters: {
    location: {
      type: "string",
      description: "City name",
      required: true
    }
  },
  execute: async (params) => {
    // Call external API
    return weatherData;
  }
}
```

### 3. Memory Management

**Types of Memory**:

**Conversation Memory**: Last N messages
```javascript
{
  messages: [
    {role: "user", content: "What's the weather?"},
    {role: "assistant", content: "It's sunny..."},
    {role: "user", content: "And tomorrow?"}
  ]
}
```

**Entity Memory**: Key facts about entities
```javascript
{
  entities: {
    "Paris": {weather: "sunny", temp: 18},
    "London": {weather: "rainy", temp: 12}
  }
}
```

**Summary Memory**: Compressed context
```javascript
{
  summary: "User asking about European weather. " +
           "Interested in Paris (sunny) and London (rainy)."
}
```

---

## Building Agent Workflows

### Pattern 1: Simple Tool-Calling Agent

```
User Input → Agent → [Decide Tool] → Call Tool → Return Result
```

**Implementation**:
```
1. HTTP to get user input
2. LangChain Agent node
3. IF node to route to correct tool
4. Execute tool
5. Return result to user
```

### Pattern 2: Multi-Step Reasoning Agent

```
User Input → Agent → [Reasoning Loop]
                     ├─ Tool 1 → Result
                     ├─ Tool 2 → Result
                     ├─ Tool 3 → Result
                     └─ Synthesize → Final Answer
```

**Implementation**:
```
1. LangChain Agent with max_iterations: 5
2. For each iteration:
   - Agent decides next tool
   - Execute tool
   - Pass result back to agent
3. Agent returns when goal met
```

### Pattern 3: Agent with Memory

```
Initialize Memory → Chat History → Agent → Tool Calls → Update Memory
```

**Implementation**:
```javascript
// Initialize memory from database
const memory = await getConversationMemory(userId);

// Add to agent input
const agentInput = {
  input: userMessage,
  memory,
  ...
};

// After agent responds, save memory
await saveConversationMemory(userId, updatedMemory);
```

### Pattern 4: Agent with Function Calling

```
Agent → [LLM decides] → Call n8n Function
                        ├─ If need math: Calculate
                        ├─ If need data: Query DB
                        └─ If need external: Call API
```

---

## Tool Definition Best Practices

### 1. Clear Names & Descriptions

**Good** ✅
```javascript
{
  name: "search_web",
  description: "Search the internet for current information " +
               "about a topic, returns top 5 results"
}
```

**Bad** ❌
```javascript
{
  name: "tool1",
  description: "Does stuff"
}
```

### 2. Detailed Parameters

**Good** ✅
```javascript
parameters: {
  query: {
    type: "string",
    description: "Search query, be specific (e.g., 'current weather Paris')",
    required: true
  },
  max_results: {
    type: "number",
    description: "Maximum number of results (1-10)",
    required: false,
    default: 5
  }
}
```

**Bad** ❌
```javascript
parameters: {
  q: {type: "string"}
}
```

### 3. Consistent Return Format

**All tools return**:
```javascript
{
  success: true,           // Was tool call successful?
  data: {...},            // The actual result
  error: null,            // Or error message if failed
  metadata: {
    duration: 250,        // How long it took
    source: "api"         // Where data came from
  }
}
```

---

## Common Agent Patterns

### Autonomous Research Agent

```
Query → Search Web → Read Articles → Synthesize → Research Report
         ↓            ↓               ↓
      Tool A        Tool B          Tool C
```

### Customer Support Agent

```
Question → Lookup Docs → FAQ Search → Generate Answer → Escalate if needed
           ↓             ↓            ↓
        Tool A         Tool B       Tool C
```

### Data Analysis Agent

```
Query → Load Data → Transform → Visualize → Explain
        ↓           ↓           ↓           ↓
     Tool A      Tool B       Tool C      Tool D
```

### Autonomous Email Agent

```
Email Input → [Decision Tree]
              ├─ Spam? → Delete
              ├─ Support? → Auto-reply + Create ticket
              ├─ Sales? → Flag for followup
              └─ Other → Archive
```

---

## Error Handling in Agents

### Pattern: Tool Failure Recovery

```
Agent → Call Tool → [Error?]
          ↓           ├─ Yes → Retry with different params
          ↓           ├─ Still fail → Try alternative tool
          └─ Success ─ Retry or ask for clarification
```

### Pattern: Invalid Reasoning

```
Agent decides → [Valid decision?]
         ├─ Yes → Execute
         └─ No → Ask agent to reconsider with constraints
```

### Pattern: Stuck Agent

```
Agent Iteration 1 → Iteration 2 → Iteration 3 → Iteration 4 → Iteration 5
                    [Same action repeated?]

                    Yes → Stop and return "Unable to solve"
                    No → Continue
```

---

## Prompt Engineering for Agents

### System Prompt Structure

```javascript
const systemPrompt = `
You are a helpful assistant. You have access to these tools:
${tools.map(t => `- ${t.name}: ${t.description}`).join('\n')}

When responding:
1. Always think step-by-step
2. Use tools to gather information
3. Provide clear, actionable answers
4. If you don't know, say so

Current time: ${new Date().toISOString()}
User context: ${userContext}
`;
```

### Few-Shot Examples

```javascript
const examples = [
  {
    input: "What's the weather in Paris?",
    thought: "User asking for weather information",
    action: "weather",
    action_input: "Paris"
  },
  {
    input: "Compare prices of flights to London",
    thought: "User needs to compare flight prices",
    action: "flight_search",
    action_input: {destination: "London", compare: true}
  }
];
```

---

## Production Patterns

### Pattern: Agent with Request Validation

```
Request → Validate Format → Validate Content → Agent → Response
            ↓                  ↓
        Check schema      Check constraints
```

### Pattern: Agent with Rate Limiting

```
Request → Check Rate Limit → [Exceeded?]
          ├─ No → Execute Agent
          └─ Yes → Return 429 error
```

### Pattern: Agent with Logging

```
Request → Log Input → Agent → Log Decision → Execute Tool → Log Result → Response
```

### Pattern: Agent with Caching

```
Request → Check Cache → [Hit?]
          ├─ Yes → Return cached response
          └─ No → Execute Agent → Cache Result → Return
```

---

## Monitoring Agent Performance

Track:
- ✅ Successful requests / total
- 🔄 Average iterations to solve
- ⏱️ Time per request
- 🎯 Tool usage frequency
- ❌ Error rate by tool
- 📊 Token usage (cost)

Alert on:
- ⚠️ Error rate > 5%
- ⚠️ Average iterations > 10
- ⚠️ Iteration limit reached
- ⚠️ Tool failure

---

## Integration

Works with:
- **n8n Advanced Patterns** - Agent orchestration
- **n8n Workflow Debugging** - Debug agent decisions
- **n8n Code JavaScript** - Custom agent logic
- **n8n Performance Optimization** - Scale agents

---

See [LANGCHAIN_INTEGRATION.md](LANGCHAIN_INTEGRATION.md) and [AGENT_EXAMPLES.md](AGENT_EXAMPLES.md).
