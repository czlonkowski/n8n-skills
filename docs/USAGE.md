# Usage Guide

Learn how to use n8n-skills effectively with Claude.

---

## How Skills Activate

Skills activate **automatically** based on your query content. You don't need to manually invoke them.

### Activation Triggers

Each skill has specific triggers defined in its frontmatter:

```markdown
---
name: n8n Expression Syntax
description: Validate n8n expression syntax and fix common errors. Use when writing n8n expressions, using {{}} syntax, accessing $json/$node variables, or troubleshooting expression errors in workflows.
---
```

When your query matches the description keywords, the skill activates.

---

## Individual Skill Usage

### 1. n8n Expression Syntax

**Activates on**: expression, {{}}  syntax, $json, $node, webhook data access

**Example Queries**:
```
"How do I write n8n expressions?"
"Why is {{$json.email}} showing undefined?"
"Access webhook data in Slack node"
"What's wrong with my $node reference?"
```

**What You'll Learn**:
- Correct {{}} syntax
- Webhook data structure ($json.body.*)
- Node references ($node["Node Name"].json)
- Common mistakes and fixes
- When NOT to use expressions (Code nodes)

**Example Response**:
```
[Skill activates]

n8n expressions must be wrapped in double curly braces:

✅ Correct: {{$json.body.email}}
❌ Wrong: $json.body.email

For webhook data, remember it's under .body:
{{$json.body.name}}  // Webhook form data
{{$json.body.message}}  // Webhook message

In Code nodes, use direct access (no {{}}):
const email = $json.body.email;  // Correct in Code node
```

---

### 2. n8n MCP Tools Expert

**Activates on**: search nodes, validate, find node, MCP tools, template, workflow

**Example Queries**:
```
"Find me a Slack node"
"How do I search for database nodes?"
"Validate this node configuration"
"What's the difference between get_node_info and get_node_essentials?"
"Which MCP tool should I use to create workflows?"
```

**What You'll Learn**:
- Tool selection (which tool for which task)
- nodeType format differences
- Validation profiles (minimal/runtime/ai-friendly/strict)
- Common MCP tool mistakes
- Workflow management tools

**Example Response**:
```
[Skill activates]

To find the Slack node, use search_nodes:

search_nodes({query: "slack"})

This returns:
- nodeType: "nodes-base.slack" (for search/validate tools)
- workflowNodeType: "n8n-nodes-base.slack" (for workflows)

⚠️ Important: Use different formats for different tools!

Next, get node details:
get_node_essentials({nodeType: "nodes-base.slack"})

This returns focused 5KB data vs 100KB+ from get_node_info.
```

---

### 3. n8n Workflow Patterns

**Activates on**: build workflow, webhook, pattern, architecture, workflow structure

**Example Queries**:
```
"Build a webhook to Slack workflow"
"What's the best pattern for API integration?"
"Create a scheduled database workflow"
"Show me webhook processing pattern"
```

**What You'll Learn**:
- 5 proven patterns (webhook, HTTP API, database, AI, scheduled)
- Workflow creation checklist
- Node connection best practices
- Real template examples
- Pattern selection guide

**Example Response**:
```
[Skill activates]

For webhook to Slack, use the Webhook Processing pattern:

Pattern Structure:
Webhook Trigger → [Transform] → Slack Notification

Workflow Checklist:
□ Search for nodes (search_nodes)
□ Get node configurations (get_node_essentials)
□ Create workflow structure
□ Add data mappings (expressions)
□ Validate workflow
□ Test with sample data

Real Example from Template #2947:
Webhook → OpenStreetMap → NWS → Slack
(1,500 views, proven pattern)
```

---

### 4. n8n Validation Expert

**Activates on**: validation, error, fix, debug, validate workflow

**Example Queries**:
```
"Why is my workflow validation failing?"
"Fix this validation error"
"Explain this validation warning"
"What does auto-sanitization do?"
```

**What You'll Learn**:
- Validation loop workflow
- Error interpretation
- Auto-sanitization system
- False positives handling
- Profile selection

**Example Response**:
```
[Skill activates]

Validation Error: "Required field 'channel' missing"

Fix:
validate_node_operation({
  nodeType: "nodes-base.slack",
  config: {
    resource: "message",
    operation: "post",
    channel: "#general",  // Add this!
    text: "Message"
  },
  profile: "runtime"
})

Auto-sanitization will fix:
✅ Binary operator structures (equals, contains)
✅ Unary operator structures (isEmpty, isNotEmpty)
✅ Missing metadata in IF/Switch nodes

But cannot fix:
❌ Broken connections
❌ Branch count mismatches
```

---

### 5. n8n Node Configuration

**Activates on**: configure node, property, operation, dependencies, AI workflow

**Example Queries**:
```
"How do I configure the HTTP Request node?"
"What properties does the Slack node need?"
"Explain property dependencies"
"Set up AI Agent workflow"
```

**What You'll Learn**:
- Operation-specific requirements
- Property dependencies (sendBody → contentType)
- AI connection types (8 types)
- Common configuration patterns

**Example Response**:
```
[Skill activates]

HTTP Request node property dependencies:

1. Set sendBody = true
   ↓ Reveals: contentType

2. Set contentType = "json"
   ↓ Reveals: specifyBody

3. Set specifyBody = "json"
   ↓ Reveals: jsonBody

This cascade of 32 dependencies ensures you see only relevant properties!

For AI workflows, 8 connection types:
- ai_languageModel (OpenAI, Anthropic)
- ai_tool (HTTP Request Tool, Code Tool)
- ai_memory (Window Buffer Memory)
- ai_outputParser, ai_embedding, ai_vectorStore...
```

---

## Cross-Skill Composition

Skills work **together automatically**. Here's how:

### Example: Complete Workflow Build

**Your Query**:
```
"Build and validate a webhook to Slack workflow with proper data mapping"
```

**What Happens** (all automatic):

**Step 1**: n8n Workflow Patterns activates
```
→ Identifies: Webhook Processing Pattern
→ Provides: Workflow structure
```

**Step 2**: n8n MCP Tools Expert activates
```
→ Searches: search_nodes({query: "webhook"})
→ Searches: search_nodes({query: "slack"})
→ Gets details: get_node_essentials for both
```

**Step 3**: n8n Node Configuration activates
```
→ Guides: Webhook node setup (path, httpMethod)
→ Guides: Slack node setup (resource, operation, channel)
```

**Step 4**: n8n Expression Syntax activates
```
→ Provides: {{$json.body.message}} for data mapping
→ Warns: Webhook data is under .body!
```

**Step 5**: n8n Validation Expert activates
```
→ Validates: Complete workflow structure
→ Checks: Node configurations
→ Reports: Any errors or warnings
```

**Result**: Complete, validated, working workflow!

---

## Common Use Cases

### Use Case 1: Quick Node Search

```
You: "Find email nodes"

[n8n MCP Tools Expert activates]
Claude: Uses search_nodes({query: "email"})
Returns: Gmail, Email Send, IMAP Email, etc.
```

### Use Case 2: Fix Expression Error

```
You: "My {{$json.name}} is showing undefined in webhook workflow"

[n8n Expression Syntax activates]
Claude: Webhook data is under .body!
Fix: {{$json.body.name}}
```

### Use Case 3: Understand Validation Error

```
You: "Validation says 'binary operator cannot have singleValue'"

[n8n Validation Expert activates]
Claude: Binary operators (equals, contains) should NOT have singleValue.
Auto-sanitization will fix this on next update.
```

### Use Case 4: Build AI Workflow

```
You: "Create an AI Agent workflow with HTTP Request tool"

[n8n Workflow Patterns + Node Configuration activate]
Claude: AI Agent Workflow Pattern:
1. Connect language model: sourceOutput="ai_languageModel"
2. Connect tool: sourceOutput="ai_tool"
3. Connect memory: sourceOutput="ai_memory"

[Provides complete configuration]
```

---

## Best Practices

### 1. Be Specific

**Good**: "Build a webhook that receives form data and posts to Slack"
**Better**: "Build a webhook to Slack workflow with form validation and error handling"

**Why**: More specific queries activate relevant skills with better context.

### 2. Ask Follow-Up Questions

Skills provide deep knowledge. Don't hesitate to ask:
```
"Explain property dependencies in HTTP Request node"
"Show me more webhook examples"
"What are validation profiles?"
```

### 3. Request Validation

Always ask for validation:
```
"Build this workflow AND validate it"
"Check if this configuration is correct"
```

### 4. Leverage Cross-Skill Knowledge

```
"Build, validate, and explain the expressions in this workflow"
→ Activates: Patterns + Validation + Expression Syntax
```

### 5. Reference Real Templates

```
"Show me template #2947 and explain how it works"
→ Uses n8n-mcp tools to fetch and analyze real templates
```

---

## Skill Limitations

### What Skills CAN Do:
✅ Teach n8n concepts
✅ Guide MCP tool usage
✅ Provide workflow patterns
✅ Interpret validation errors
✅ Explain configurations
✅ Reference real templates

### What Skills CANNOT Do:
❌ Execute workflows (use n8n for that)
❌ Access your n8n instance directly (use n8n-mcp API tools)
❌ Modify running workflows
❌ Debug runtime execution errors (only configuration errors)

---

## Tool Availability

**Always Available** (no n8n API needed):
- search_nodes, list_nodes, get_node_essentials ✅
- validate_node_minimal, validate_node_operation ✅
- validate_workflow, get_property_dependencies ✅
- search_templates, get_template ✅

**Requires n8n API** (N8N_API_URL + N8N_API_KEY):
- n8n_create_workflow ⚠️
- n8n_update_partial_workflow ⚠️
- n8n_validate_workflow (by ID) ⚠️
- n8n_list_workflows, n8n_get_workflow ⚠️
- n8n_trigger_webhook_workflow ⚠️

If API tools unavailable, skills use templates and validation-only workflows.

---

## Troubleshooting

### Skill Not Activating

**Problem**: Skill doesn't activate when expected

**Solution**: Rephrase query to match activation keywords
```
Instead of: "How do I use expressions?"
Try: "How do I write n8n expressions with {{}} syntax?"
```

### Wrong Skill Activates

**Problem**: Different skill than expected activates

**Solution**: This is usually fine! Skills complement each other.
If needed, be more specific:
```
"Using n8n MCP tools, search for webhook node"
```

### Multiple Skills Needed

**Problem**: Need knowledge from multiple skills

**Solution**: Ask a comprehensive question:
```
"Build, configure, and validate a webhook workflow with explanations"
```

All relevant skills will activate automatically.

---

## Advanced Usage

### Request Specific Tool Usage

```
"Use get_node_essentials to show me Slack node configuration"
```

### Ask for Real Examples

```
"Show me real template examples of webhook workflows"
```

### Request Step-by-Step

```
"Step by step: build a webhook to database workflow with validation at each step"
```

### Debug with Skills

```
"My workflow fails validation. Debug it using validation expert knowledge."
```

---

## Next Steps

- **Getting Started**: Try example queries above
- **Deep Dive**: Read individual SKILL.md files in skills/
- **Contribute**: See [DEVELOPMENT.md](DEVELOPMENT.md)

---

## Support

- **Issues**: https://github.com/czlonkowski/n8n-skills/issues
- **Discussions**: https://github.com/czlonkowski/n8n-skills/discussions

---

**Ready to build amazing n8n workflows with Claude? Start asking questions!** 🚀

---

Conceived by Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
