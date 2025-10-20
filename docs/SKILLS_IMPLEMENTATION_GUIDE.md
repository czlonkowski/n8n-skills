# 🎯 COMPLETE IMPLEMENTATION GUIDE: n8n-mcp Claude Skills (Path 1)

## Project Overview

**Objective**: Create 5 complementary meta-skills that teach Claude how to use n8n-mcp MCP tools effectively for building n8n workflows.

**Architecture**:
- **n8n-mcp MCP Server**: Provides data access (525 nodes, validation, templates)
- **Claude Skills**: Provides expert guidance on HOW to use MCP tools
- **Together**: Expert workflow builder with progressive disclosure

**Repository Structure**:
```
n8n-mcp-skills/
├── README.md
├── LICENSE
├── skills/
│   ├── n8n-expression-syntax/
│   ├── n8n-mcp-tools-expert/
│   ├── n8n-workflow-patterns/
│   ├── n8n-validation-expert/
│   └── n8n-node-configuration/
├── evaluations/
│   ├── expression-syntax/
│   ├── mcp-tools/
│   ├── workflow-patterns/
│   ├── validation-expert/
│   └── node-configuration/
├── docs/
│   └── DEVELOPMENT.md
└── package.json (for distribution metadata)
```

---

## Implementation Timeline

**Week 1**: Expression Syntax (PoC)
**Week 2**: MCP Tools Expert + Workflow Patterns
**Week 3**: Validation Expert + Node Configuration
**Week 4**: Testing, refinement, documentation
**Week 5-6**: Distribution, plugin packaging

---

# SKILL #1: n8n Expression Syntax (PoC - Week 1)

## Priority: Foundation (Week 1)
**Purpose**: Teach correct n8n expression syntax and common patterns
**File Count**: 4 files
**Total Lines**: ~350 lines
**Complexity**: Simple (good starting point)

## Directory Structure

```
skills/n8n-expression-syntax/
├── SKILL.md                    # 200 lines - main instructions
├── COMMON_MISTAKES.md          # 100 lines - error catalog
├── EXAMPLES.md                 # 50 lines - working examples
└── README.md                   # metadata for GitHub
```

## File: SKILL.md

```markdown
---
name: n8n Expression Syntax
description: Validate n8n expression syntax and fix common errors. Use when writing n8n expressions, using {{}} syntax, accessing $json/$node variables, or troubleshooting expression errors in workflows.
---

# n8n Expression Syntax

## Expression format

All dynamic content in n8n uses double curly braces:

```
{{expression}}
```

## Core variables

**$json** - Current node's output data
```
{{$json.fieldName}}
{{$json['field with spaces']}}
```

**$node** - Other node's output data
```
{{$node["Node Name"].json.fieldName}}
{{$node["HTTP Request"].json.data}}
```

**$now** - Current timestamp
```
{{$now}}
{{$now.toFormat('yyyy-MM-dd')}}
```

**$env** - Environment variables
```
{{$env.API_KEY}}
```

## Common patterns

### Access nested fields
```
✅ {{$json.user.email}}
✅ {{$json.data[0].name}}
✅ {{$json['response']['items']}}
```

### Reference other nodes
```
✅ {{$node["HTTP Request"].json.data}}
✅ {{$node["Webhook"].json.body.user_id}}
```

### Handle spaces in field names
```
❌ {{$json.field name}}
✅ {{$json['field name']}}
```

### Handle spaces in node names
```
❌ {{$node.HTTP Request.json}}
✅ {{$node["HTTP Request"].json}}
```

## Validation rules

1. **Always use {{}}** - Expressions must be wrapped
2. **Use quotes for spaces** - Bracket notation for field/node names with spaces
3. **Match exact node names** - Node references are case-sensitive
4. **No nested {{}}** - Don't double-wrap expressions

## Common mistakes

For complete error catalog, see [COMMON_MISTAKES.md](COMMON_MISTAKES.md)

**Quick fixes:**

| Mistake | Fix |
|---------|-----|
| `$json.field` | `{{$json.field}}` |
| `{{$json.field name}}` | `{{$json['field name']}}` |
| `{{$node.HTTP Request}}` | `{{$node["HTTP Request"]}}` |
| `{{{$json.field}}}` | `{{$json.field}}` |

## Examples

For working examples, see [EXAMPLES.md](EXAMPLES.md)

## When NOT to use expressions

❌ Inside Code node (use JavaScript directly)
❌ In webhook paths (use static text)
❌ In credential fields (use credential system)
```

## File: COMMON_MISTAKES.md

```markdown
# Common n8n Expression Mistakes

## Missing curly braces

**Problem**: Expression not recognized

❌ **Wrong:**
```
$json.email
```

✅ **Correct:**
```
{{$json.email}}
```

**Why it fails**: n8n treats text without {{}} as literal string

---

## Spaces in field names

**Problem**: Syntax error or undefined

❌ **Wrong:**
```
{{$json.first name}}
```

✅ **Correct:**
```
{{$json['first name']}}
```

**Why it fails**: Space breaks dot notation, must use bracket notation

---

## Spaces in node names

**Problem**: Cannot access other node's data

❌ **Wrong:**
```
{{$node.HTTP Request.json.data}}
```

✅ **Correct:**
```
{{$node["HTTP Request"].json.data}}
```

**Why it fails**: Node names are treated as strings, need quotes

---

## Incorrect node reference

**Problem**: Undefined or wrong data

❌ **Wrong:**
```
{{$node["http request"].json.data}}  // lowercase
```

✅ **Correct:**
```
{{$node["HTTP Request"].json.data}}  // exact match
```

**Why it fails**: Node names are case-sensitive

---

## Double wrapping

**Problem**: Literal {{}} in output

❌ **Wrong:**
```
{{{$json.field}}}
```

✅ **Correct:**
```
{{$json.field}}
```

**Why it fails**: Only one set of {{}} needed

---

## Missing quotes on property access

**Problem**: Accessing array/object incorrectly

❌ **Wrong:**
```
{{$json.items.0.name}}
```

✅ **Correct:**
```
{{$json.items[0].name}}
```

**Why it fails**: Array access requires brackets, not dots

---

## Using expressions in Code node

**Problem**: Double evaluation or errors

❌ **Wrong (in Code node):**
```javascript
const email = '{{$json.email}}';  // Don't do this
```

✅ **Correct (in Code node):**
```javascript
const email = $input.item.json.email;  // Use Code node API
```

**Why it fails**: Code node has direct access to data, no {{}} needed
```

## File: EXAMPLES.md

```markdown
# n8n Expression Examples

## Example 1: Access webhook data

**Workflow**: Webhook → Code → Slack

**Webhook output:**
```json
{
  "body": {
    "user_id": "12345",
    "email": "user@example.com"
  }
}
```

**In Slack node message field:**
```
New user registered: {{$json.body.email}}
User ID: {{$json.body.user_id}}
```

---

## Example 2: Reference previous node

**Workflow**: HTTP Request → Set → Email

**HTTP Request output:**
```json
{
  "data": {
    "items": [
      {"name": "Product 1", "price": 29.99}
    ]
  }
}
```

**In Set node, use HTTP Request data:**
```
{{$node["HTTP Request"].json.data.items[0].name}}
{{$node["HTTP Request"].json.data.items[0].price}}
```

---

## Example 3: Format timestamp

**Use $now for current time:**
```
{{$now.toFormat('yyyy-MM-dd')}}          // 2025-01-20
{{$now.toFormat('HH:mm:ss')}}            // 14:30:45
{{$now.toFormat('yyyy-MM-dd HH:mm')}}    // 2025-01-20 14:30
```

---

## Example 4: Handle field with spaces

**Data:**
```json
{
  "first name": "John",
  "last name": "Doe"
}
```

**Expression:**
```
Hello {{$json['first name']}} {{$json['last name']}}!
```

**Output:**
```
Hello John Doe!
```

---

## Example 5: Access array elements

**Data:**
```json
{
  "users": [
    {"email": "alice@example.com"},
    {"email": "bob@example.com"}
  ]
}
```

**Expressions:**
```
First user: {{$json.users[0].email}}
Second user: {{$json.users[1].email}}
Count: {{$json.users.length}}
```
```

## Evaluations (3 scenarios)

**File**: `evaluations/expression-syntax/eval-001-missing-braces.json`
```json
{
  "id": "expr-001",
  "skills": ["n8n-expression-syntax"],
  "query": "I'm trying to access an email field in n8n with: $json.email but it's not working. What's wrong?",
  "expected_behavior": [
    "Identifies missing {{ }} brackets around expression",
    "Explains that $json.email without braces is treated as literal text",
    "Provides corrected expression: {{$json.email}}",
    "Uses examples from SKILL.md or COMMON_MISTAKES.md"
  ],
  "baseline_without_skill": {
    "likely_response": "May suggest general debugging, might not know n8n-specific {{ }} syntax",
    "expected_quality": "Low - lacks n8n-specific knowledge"
  },
  "with_skill_expected": {
    "response_quality": "High - precise fix with n8n-specific guidance",
    "uses_skill_content": true,
    "provides_correct_syntax": true
  }
}
```

**File**: `evaluations/expression-syntax/eval-002-space-in-field.json`
```json
{
  "id": "expr-002",
  "skills": ["n8n-expression-syntax"],
  "query": "My workflow has a field called 'first name' and I'm using {{$json.first name}} but getting undefined. Help!",
  "expected_behavior": [
    "Identifies space in field name as the issue",
    "Explains that dot notation breaks with spaces",
    "Provides corrected expression using bracket notation: {{$json['first name']}}",
    "References COMMON_MISTAKES.md section on spaces"
  ],
  "test_variations": [
    "field name with spaces",
    "node name with spaces",
    "nested field with spaces"
  ]
}
```

**File**: `evaluations/expression-syntax/eval-003-node-reference.json`
```json
{
  "id": "expr-003",
  "skills": ["n8n-expression-syntax"],
  "query": "How do I access data from my 'HTTP Request' node in a later node?",
  "expected_behavior": [
    "Provides correct $node syntax with quotes",
    "Shows example: {{$node[\"HTTP Request\"].json.fieldName}}",
    "Explains node name must match exactly (case-sensitive)",
    "Provides multiple examples from EXAMPLES.md if relevant"
  ]
}
```

---

# SKILL #2: n8n MCP Tools Expert (Week 2)

## Priority: 1 (Highest - fixes 20% failure rate)
**Purpose**: Teach how to use n8n-mcp MCP tools effectively
**File Count**: 5 files
**Total Lines**: ~600 lines
**Complexity**: Medium

## Directory Structure

```
skills/n8n-mcp-tools-expert/
├── SKILL.md                    # 350 lines - tool overview
├── SEARCH_GUIDE.md             # 150 lines - search tools
├── VALIDATION_GUIDE.md         # 100 lines - validation tools
└── WORKFLOW_GUIDE.md           # 100 lines - workflow management tools
```

## File: SKILL.md

```markdown
---
name: n8n MCP Tools Expert
description: Expert guide for using n8n-mcp MCP tools effectively. Use when searching for nodes, validating configurations, accessing templates, managing workflows, or using any n8n-mcp tool. Provides tool selection guidance and parameter formats.
---

# n8n MCP Tools Expert

## Tool categories

The n8n-mcp MCP server provides 40+ tools organized into categories:

1. **Node Discovery** → [SEARCH_GUIDE.md](SEARCH_GUIDE.md)
2. **Configuration Validation** → [VALIDATION_GUIDE.md](VALIDATION_GUIDE.md)
3. **Workflow Management** → [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md)
4. **Template Library** - templates for common patterns
5. **Documentation** - tool and node documentation

## Quick reference

### Most used tools (by frequency)

| Tool | Use When | Success Rate |
|------|----------|--------------|
| `search_nodes` | Finding nodes by keyword | 99.9% |
| `get_node_essentials` | Understanding node operations | 91.7% |
| `n8n_create_workflow` | Creating new workflows | 96.8% |
| `n8n_update_partial_workflow` | Editing workflows | 99.0% |
| `n8n_validate_workflow` | Checking workflow validity | 99.7% |

### Tool selection guide

**Finding the right node:**
```
1. search_nodes(query) - Start here
2. get_node_essentials(nodeType) - Get operation list
3. get_node_documentation(nodeType) - Detailed docs if needed
```

**Validating configuration:**
```
1. validate_node_minimal(nodeType, {}) - Check required fields
2. validate_node_operation(nodeType, config, 'runtime') - Validate config
3. n8n_validate_workflow(workflow) - Validate complete workflow
```

**Managing workflows:**
```
1. n8n_create_workflow(name, nodes, connections) - Create new
2. n8n_update_partial_workflow(id, operations) - Edit existing
3. n8n_validate_workflow(id) - Validate before deploy
```

## Common mistakes

### ❌ Using get_node_info when get_node_essentials is better

**Problem**: get_node_info returns 100KB+ of data (20% failure rate)

**Solution**: Use get_node_essentials instead:
```
❌ get_node_info("nodes-base.slack")  // Returns massive schema
✅ get_node_essentials("nodes-base.slack")  // Returns focused data
```

### ❌ Wrong nodeType format

**Problem**: Tool fails with "node not found"

**Formats**:
- **For search tools**: `"nodes-base.slack"` (with prefix)
- **For n8n tools**: `"n8n-nodes-base.slack"` (full name)

**Solution**:
```javascript
// Search/essentials/validation tools:
search_nodes("slack")  // No prefix needed
get_node_essentials("nodes-base.slack")  // Short prefix

// List templates:
list_node_templates(["n8n-nodes-base.slack"])  // Full prefix
```

### ❌ Not using validation profiles

**Problem**: Getting too many false positives or missing real errors

**Profiles**:
- `minimal` - Only check required fields exist
- `runtime` - Check values and types (recommended)
- `ai-friendly` - Reduce false positives
- `strict` - Maximum validation

**Solution**:
```javascript
// For configuration:
validate_node_operation(nodeType, config, 'runtime')

// For quick check:
validate_node_minimal(nodeType, {})
```

## Tool usage patterns

See detailed guides:
- **Node Discovery**: [SEARCH_GUIDE.md](SEARCH_GUIDE.md)
- **Validation**: [VALIDATION_GUIDE.md](VALIDATION_GUIDE.md)
- **Workflow Management**: [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md)

## Self-help

**Get tool documentation:**
```
tools_documentation()  // List all tools
tools_documentation("search_nodes", "full")  // Specific tool
```

**Health check:**
```
n8n_health_check()  // Verify MCP server connectivity
```
```

## File: SEARCH_GUIDE.md

```markdown
# Node Discovery Tools Guide

## Tool selection

### search_nodes - Start here (99.9% success rate)

**Use when**: You know what you're looking for (keyword, use case, service)

**Example**:
```javascript
search_nodes({
  query: "slack",
  mode: "OR",  // Default: any word matches
  limit: 20
})
```

**Returns**: List of matching nodes with types

**Tips**:
- Use specific keywords: "slack", "http request", "database"
- Common searches: webhook, http, database, email, slack
- mode: "OR" (default) | "AND" (all words) | "FUZZY" (typo-tolerant)

---

### get_node_essentials - Understand operations (91.7% success)

**Use when**: You've found the node and need to see operations

**Example**:
```javascript
get_node_essentials({
  nodeType: "nodes-base.slack",
  includeExamples: true  // Get real template configs
})
```

**Returns**:
- Available operations
- Essential properties only (not full schema)
- Example configurations from templates

**Tips**:
- Use after search_nodes to understand what a node can do
- includeExamples:true provides working configurations
- Much faster than get_node_info (4ms vs 3ms)

---

### get_node_info - Full documentation (80% success)

**Use when**: You need complete schema details

**Warning**:
- Returns 100KB+ data
- 20% failure rate (use sparingly)
- Better alternatives exist for most cases

**Example**:
```javascript
get_node_info({
  nodeType: "nodes-base.httpRequest"
})
```

**When to use**:
- Debugging complex configuration issues
- Need full property schemas
- Exploring advanced features

**Better alternatives**:
1. get_node_essentials - for operations list
2. get_node_documentation - for readable docs
3. search_node_properties - for specific property

---

### list_nodes - Browse all nodes (99.6% success)

**Use when**: Exploring by category or seeing all available

**Example**:
```javascript
list_nodes({
  category: "trigger",
  limit: 200
})
```

**Categories**:
- trigger - Webhook, Schedule, Manual, etc.
- transform - Code, Set, Function, etc.
- output - HTTP Request, Email, Slack, etc.

**Tips**:
- Use limit:200 to see all nodes
- Filter by package: "n8n-nodes-base" or "@n8n/n8n-nodes-langchain"
- Filter by category for focused exploration

---

## Workflow: Finding and configuring a node

```
Step 1: Search for node
  search_nodes({query: "slack"})
  → Returns: nodes-base.slack

Step 2: Get operations
  get_node_essentials({
    nodeType: "nodes-base.slack",
    includeExamples: true
  })
  → Returns: operations list + example configs

Step 3: Validate configuration
  validate_node_operation({
    nodeType: "nodes-base.slack",
    config: {resource: "channel", operation: "create"},
    profile: "runtime"
  })
  → Returns: validation result

Step 4: Use in workflow
  (Configuration is validated and ready)
```

## Common patterns from telemetry

**Pattern**: search → essentials (9,835 occurrences, 18s avg)
```javascript
// Step 1
search_nodes({query: "webhook"})

// Step 2 (after ~18 seconds of reviewing results)
get_node_essentials({nodeType: "nodes-base.webhook"})
```

This is the MOST COMMON discovery pattern. Follow it!
```

## File: VALIDATION_GUIDE.md

```markdown
# Configuration Validation Tools Guide

## Validation philosophy

**Validate early, validate often** - 15,107 validation loops observed in telemetry

## Tool selection

### validate_node_minimal - Quick check (97.4% success)

**Use when**: Checking what fields are required

**Example**:
```javascript
validate_node_minimal({
  nodeType: "nodes-base.slack",
  config: {}  // Empty to see all required fields
})
```

**Returns**:
- List of required fields
- No validation of values

**When to use**: Planning configuration, seeing requirements

---

### validate_node_operation - Full validation (varies)

**Use when**: Validating actual configuration

**Example**:
```javascript
validate_node_operation({
  nodeType: "nodes-base.slack",
  config: {
    resource: "channel",
    operation: "create",
    channel: "general"
  },
  profile: "runtime"  // Recommended
})
```

**Profiles**:
- `minimal` - Required fields only
- `runtime` - Values + types (recommended)
- `ai-friendly` - Fewer false positives
- `strict` - Maximum validation

**Returns**:
- errors: Critical issues (must fix)
- warnings: Suggestions (optional)
- suggestions: Improvements

**Validation loop pattern** (from telemetry):
```
1. Configure node
2. validate_node_operation (23s thinking)
3. Fix errors
4. validate_node_operation again (58s fixing)
5. Repeat until valid
```

---

### validate_workflow - Structure validation (95.5% success)

**Use when**: Checking workflow before execution

**Example**:
```javascript
validate_workflow({
  workflow: {
    nodes: [...],
    connections: {...}
  },
  options: {
    validateNodes: true,
    validateConnections: true,
    validateExpressions: true,
    profile: "runtime"
  }
})
```

**Checks**:
- Node configurations
- Connection validity
- Expression syntax
- Workflow structure

---

### n8n_validate_workflow - Complete validation (99.7% success)

**Use when**: Final validation before deployment

**Example**:
```javascript
n8n_validate_workflow({
  id: "workflow-id",
  options: {
    profile: "runtime"
  }
})
```

**Returns**: Comprehensive validation report

**When to use**: After building complete workflow, before executing

---

## Validation workflow (from telemetry)

**Most common pattern** (7,841 occurrences):
```
n8n_update_partial_workflow (make changes)
  ↓ ~23 seconds
n8n_validate_workflow (check)
  ↓ ~58 seconds
n8n_update_partial_workflow (fix errors)
  ↓
(repeat until valid)
```

**Best practice**:
1. Make changes
2. **Validate immediately**
3. Fix errors
4. **Validate again**
5. Only proceed when validation passes

## Handling validation errors

**Error types**:
1. **Required field missing** → Add the field
2. **Invalid value** → Check allowed values in essentials
3. **Type mismatch** → Convert to correct type
4. **False positive** → Check n8n Validation Expert skill

**When you get errors**:
1. Read error message carefully
2. Check if it's a known false positive
3. Fix real errors
4. Validate again
5. Iterate until clean
```

## File: WORKFLOW_GUIDE.md

```markdown
# Workflow Management Tools Guide

## Creation vs Editing

### n8n_create_workflow - New workflows (96.8% success)

**Use when**: Starting from scratch

**Example**:
```javascript
n8n_create_workflow({
  name: "Webhook to Slack",
  nodes: [
    {
      id: "webhook-1",
      name: "Webhook",
      type: "n8n-nodes-base.webhook",
      typeVersion: 1,
      position: [250, 300],
      parameters: {path: "test-webhook"}
    },
    {
      id: "slack-1",
      name: "Slack",
      type: "n8n-nodes-base.slack",
      typeVersion: 1,
      position: [450, 300],
      parameters: {
        resource: "message",
        operation: "post",
        channel: "#general",
        text: "={{$json.body.message}}"
      }
    }
  ],
  connections: {
    "Webhook": {
      "main": [[{"node": "Slack", "type": "main", "index": 0}]]
    }
  }
})
```

**Returns**: Created workflow with ID

**Tips**:
- Always include: id, name, type, typeVersion, position, parameters
- Start workflows inactive (settings.active: false)
- Validate after creation

---

### n8n_update_partial_workflow - Edit existing (99.0% success)

**Use when**: Modifying workflows (MOST COMMON - 38,287 uses)

**Example**:
```javascript
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [
    {
      type: "addNode",
      node: {
        id: "code-1",
        name: "Code",
        type: "n8n-nodes-base.code",
        typeVersion: 1,
        position: [350, 300],
        parameters: {mode: "runOnceForAllItems", code: "..."}
      }
    },
    {
      type: "addConnection",
      connection: {
        sourceNode: "Webhook",
        sourceOutput: "main",
        sourceOutputIndex: 0,
        targetNode: "Code",
        targetInput: "main",
        targetInputIndex: 0
      }
    }
  ]
})
```

**Operation types**:
- addNode, removeNode, updateNode
- addConnection, removeConnection
- updateSettings, updateName
- enableNode, disableNode

**Pattern from telemetry** (31,464 occurrences):
```
update_partial → update_partial → update_partial...
Avg 56 seconds between edits (thinking time)
```

This shows workflow building is ITERATIVE, not one-shot!

---

## Workflow retrieval

### n8n_get_workflow - Full workflow (99.9% success)

**Use when**: Reviewing complete workflow

**Example**:
```javascript
n8n_get_workflow({id: "workflow-id"})
```

**Returns**: Complete workflow JSON

---

### n8n_get_workflow_structure - Just structure (99.9% success)

**Use when**: Checking nodes and connections only

**Example**:
```javascript
n8n_get_workflow_structure({id: "workflow-id"})
```

**Returns**: Nodes + connections (no parameter details)

---

### n8n_list_workflows - Browse workflows (100% success)

**Use when**: Finding existing workflows

**Example**:
```javascript
n8n_list_workflows({
  active: true,
  limit: 100
})
```

---

## Workflow lifecycle

```
1. CREATE
   n8n_create_workflow() → Returns workflow ID

2. VALIDATE
   n8n_validate_workflow(id) → Check for errors

3. EDIT (if needed)
   n8n_update_partial_workflow(id, operations)

4. VALIDATE AGAIN
   n8n_validate_workflow(id)

5. ACTIVATE (when ready)
   n8n_update_partial_workflow(id, [{
     type: "updateSettings",
     settings: {active: true}
   }])

6. MONITOR
   n8n_list_executions({workflowId: id})
   n8n_get_execution({id: execution_id})
```

## Common patterns from telemetry

**Pattern 1**: Edit → Validate (7,841 occurrences)
```
n8n_update_partial_workflow
  ↓ 23s
n8n_validate_workflow
```

**Pattern 2**: Validate → Fix (7,266 occurrences)
```
n8n_validate_workflow
  ↓ 58s
n8n_update_partial_workflow (fix errors)
```

**Pattern 3**: Create → Edit (3,906 occurrences)
```
n8n_create_workflow
  ↓ 113s
n8n_update_partial_workflow (refinements)
```

Follow these natural patterns!
```

## Evaluations (3+ scenarios)

**File**: `evaluations/mcp-tools/eval-001-tool-selection.json`
```json
{
  "id": "mcp-001",
  "skills": ["n8n-mcp-tools-expert"],
  "query": "I need to find a node that can send messages to Slack. Which MCP tool should I use and how?",
  "expected_behavior": [
    "Recommends search_nodes as the starting tool",
    "Provides correct syntax: search_nodes({query: 'slack'})",
    "Suggests following up with get_node_essentials",
    "References SEARCH_GUIDE.md for tool selection"
  ]
}
```

**File**: `evaluations/mcp-tools/eval-002-validation-workflow.json`
```json
{
  "id": "mcp-002",
  "skills": ["n8n-mcp-tools-expert"],
  "query": "I've created a workflow and want to make sure it's valid before deploying. Walk me through the validation process.",
  "expected_behavior": [
    "Recommends n8n_validate_workflow tool",
    "Explains validation profiles (runtime recommended)",
    "Shows complete validation workflow from VALIDATION_GUIDE.md",
    "Mentions validation loop pattern: validate → fix → validate again"
  ]
}
```

**File**: `evaluations/mcp-tools/eval-003-node-type-format.json`
```json
{
  "id": "mcp-003",
  "skills": ["n8n-mcp-tools-expert"],
  "query": "I'm getting 'node not found' errors when calling get_node_essentials. I'm using 'slack' as the nodeType. What's wrong?",
  "expected_behavior": [
    "Identifies incorrect nodeType format",
    "Explains need for 'nodes-base.' prefix",
    "Provides correct format: 'nodes-base.slack'",
    "References nodeType format section from SKILL.md"
  ]
}
```

---

# SKILL #3: n8n Workflow Patterns (Week 2-3)

## Priority: 2 (High - addresses 813 webhook searches)
**Purpose**: Teach proven workflow architectural patterns
**File Count**: 7 files
**Total Lines**: ~800 lines
**Complexity**: Medium-High

## Directory Structure

```
skills/n8n-workflow-patterns/
├── SKILL.md                    # 400 lines - overview + checklist
├── patterns/
│   ├── webhook_processing.md  # 100 lines
│   ├── http_api_integration.md # 100 lines
│   ├── database_operations.md  # 80 lines
│   ├── ai_agent_workflow.md    # 80 lines
│   └── scheduled_tasks.md      # 80 lines
└── scripts/
    └── validate_structure.py   # 100 lines (optional)
```

## File: SKILL.md

```markdown
---
name: n8n Workflow Patterns
description: Build n8n workflows using proven architectural patterns. Use when creating workflows, connecting nodes, designing automation, or when user describes a workflow goal like webhooks, APIs, databases, or scheduled tasks.
---

# n8n Workflow Patterns

## Workflow creation checklist

Copy this and track your progress:

```
Workflow Progress:
- [ ] Step 1: Identify pattern type
- [ ] Step 2: Search for required nodes
- [ ] Step 3: Configure node operations
- [ ] Step 4: Connect nodes properly
- [ ] Step 5: Add expressions for data mapping
- [ ] Step 6: Validate workflow structure
- [ ] Step 7: Test with sample data
```

## Pattern library

Based on 31,917 real workflows, these are the most common patterns:

### 1. Webhook Processing (27.6% of workflows)

**Use when**: Receiving external events and taking action

**Pattern**: Trigger → Process → Act

**See**: [patterns/webhook_processing.md](patterns/webhook_processing.md)

**Example use cases**:
- Form submissions → Database
- Payment notifications → Send receipt
- GitHub webhooks → Slack notifications

---

### 2. HTTP API Integration (755 searches)

**Use when**: Fetching or sending data to APIs

**Pattern**: Trigger → Fetch/Send → Transform → Store/Notify

**See**: [patterns/http_api_integration.md](patterns/http_api_integration.md)

**Example use cases**:
- Fetch weather data → Store in database
- Send customer data → CRM system
- API polling → Process updates

---

### 3. Database Operations (745 searches)

**Use when**: Reading or writing to databases

**Pattern**: Trigger → Query/Insert → Process → Respond

**See**: [patterns/database_operations.md](patterns/database_operations.md)

**Example use cases**:
- Schedule → Query database → Email report
- Webhook → Insert record → Confirm
- API → Update database → Notify

---

### 4. AI Agent Workflows (67 searches, growing)

**Use when**: Using AI to process or generate content

**Pattern**: Trigger → Prepare → AI Process → Act on result

**See**: [patterns/ai_agent_workflow.md](patterns/ai_agent_workflow.md)

**Example use cases**:
- Email → AI categorize → Route to team
- Customer message → AI respond → Send
- Document → AI extract → Store data

---

### 5. Scheduled Tasks (67 searches)

**Use when**: Running workflows on a schedule

**Pattern**: Schedule → Fetch → Process → Store/Notify

**See**: [patterns/scheduled_tasks.md](patterns/scheduled_tasks.md)

**Example use cases**:
- Daily reports
- Hourly data syncs
- Weekly cleanup tasks

---

## Node connection best practices

### Connection types

**main** - Default data flow (most common)
```javascript
connections: {
  "Webhook": {
    "main": [[{
      "node": "Slack",
      "type": "main",
      "index": 0
    }]]
  }
}
```

**error** - Error handling flow
```javascript
"HTTP Request": {
  "error": [[{
    "node": "Error Handler",
    "type": "main",
    "index": 0
  }]]
}
```

### Connection structure

**Single connection**:
```javascript
"Node1": {
  "main": [[{"node": "Node2", "type": "main", "index": 0}]]
}
```

**Multiple connections (branching)**:
```javascript
"IF": {
  "main": [
    [{"node": "True Branch", "type": "main", "index": 0}],  // Output 0
    [{"node": "False Branch", "type": "main", "index": 0}]  // Output 1
  ]
}
```

### Common mistakes

❌ **Forgetting to connect nodes**
```javascript
// No connections object = nodes won't execute
```

❌ **Wrong node names**
```javascript
connections: {
  "webhook": {...}  // Lowercase - won't match "Webhook" node
}
```

✅ **Correct**:
```javascript
connections: {
  "Webhook": {  // Exact match with node name
    "main": [[{"node": "Slack", "type": "main", "index": 0}]]
  }
}
```

## Data flow principles

### 1. Trigger starts the flow

Every workflow needs exactly one active trigger node:
- Webhook
- Schedule
- Manual
- Chat Trigger
- etc.

### 2. Data flows through connections

Each node receives:
- `$json` - Output from connected node
- `$node["Name"]` - Output from any previous node

### 3. Transform data between nodes

Use Code, Set, or Function nodes to:
- Reshape data
- Calculate values
- Filter/map arrays

### 4. End with action or response

Common ending nodes:
- HTTP Request (send to API)
- Email/Slack (notify)
- Database (store)
- Respond to Webhook (return data)

## Pattern selection guide

Ask yourself:

1. **How is the workflow triggered?**
   - Webhook → Webhook Processing
   - Time → Scheduled Tasks
   - Manual → Any pattern

2. **What's the main operation?**
   - API call → HTTP API Integration
   - Database → Database Operations
   - AI processing → AI Agent Workflow

3. **How complex is the logic?**
   - Simple (3-6 nodes) → Use basic pattern
   - Medium (7-15 nodes) → Combine patterns
   - Complex (15+ nodes) → Break into sub-workflows

## Workflow building process

**Step 1: Choose pattern**

Use pattern guides to understand structure

**Step 2: Search for nodes**

Use n8n MCP Tools Expert skill to find nodes:
```javascript
search_nodes({query: "webhook"})
search_nodes({query: "slack"})
```

**Step 3: Configure nodes**

Use n8n Node Configuration skill for operation-aware setup

**Step 4: Connect nodes**

Follow connection patterns from pattern guides

**Step 5: Add data mapping**

Use n8n Expression Syntax skill for {{}} expressions

**Step 6: Validate**

Use n8n Validation Expert skill to check workflow

**Step 7: Test**

Create workflow and test with sample data

## Next steps

Choose a pattern that matches your use case and follow the detailed guide!
```

## File: patterns/webhook_processing.md

```markdown
# Webhook Processing Pattern

## Overview

**Frequency**: 813 searches (most popular!)
**Workflows**: ~8,805 (27.6% of all workflows)
**Complexity**: Simple (5-6 nodes average)

## Pattern structure

```
Webhook Trigger
  ↓
[Optional: Transform data]
  ↓
Action (API, Database, Notification)
  ↓
[Optional: Respond to webhook]
```

## Complete example: Form submission to Slack

### Node 1: Webhook Trigger

```javascript
{
  "id": "webhook-1",
  "name": "Webhook",
  "type": "n8n-nodes-base.webhook",
  "typeVersion": 1,
  "position": [250, 300],
  "parameters": {
    "path": "form-submit",
    "httpMethod": "POST",
    "responseMode": "onReceived"
  }
}
```

**Webhook receives**:
```json
{
  "body": {
    "name": "John Doe",
    "email": "john@example.com",
    "message": "Hello!"
  }
}
```

### Node 2: Slack Notification

```javascript
{
  "id": "slack-1",
  "name": "Slack",
  "type": "n8n-nodes-base.slack",
  "typeVersion": 1,
  "position": [450, 300],
  "parameters": {
    "resource": "message",
    "operation": "post",
    "channel": "#forms",
    "text": "New form submission!\n\nName: {{$json.body.name}}\nEmail: {{$json.body.email}}\nMessage: {{$json.body.message}}"
  }
}
```

### Connections

```javascript
{
  "Webhook": {
    "main": [[{
      "node": "Slack",
      "type": "main",
      "index": 0
    }]]
  }
}
```

## Variations

### With data transformation

Add Code node between Webhook and Action:

```javascript
{
  "id": "code-1",
  "name": "Transform",
  "type": "n8n-nodes-base.code",
  "typeVersion": 1,
  "position": [350, 300],
  "parameters": {
    "mode": "runOnceForAllItems",
    "jsCode": "return items.map(item => ({\n  json: {\n    formData: item.json.body,\n    timestamp: new Date().toISOString(),\n    source: 'website'\n  }\n}));"
  }
}
```

### With webhook response

Change webhook to respond after processing:

```javascript
// Webhook node
"parameters": {
  "path": "form-submit",
  "responseMode": "lastNode"  // Respond with last node output
}

// Add Respond to Webhook node at end
{
  "id": "respond-1",
  "name": "Respond",
  "type": "n8n-nodes-base.respondToWebhook",
  "position": [650, 300],
  "parameters": {
    "responseBody": "={{JSON.stringify({success: true, message: 'Form received'})}}",
    "options": {
      "responseCode": 200
    }
  }
}
```

## Common webhook use cases

1. **Form submissions** → Store in database + Notify
2. **Payment notifications** (Stripe, PayPal) → Update order + Send receipt
3. **GitHub events** → Slack notifications
4. **Zapier/Make alternatives** → Process external triggers
5. **Chat platforms** (Telegram, WhatsApp) → AI agent responses

## Testing webhooks

1. Create workflow with webhook node
2. Note the webhook URL from node
3. Use Postman/curl to send test data:

```bash
curl -X POST https://n8n.example.com/webhook/form-submit \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "message": "Test message"
  }'
```

4. Check workflow execution in n8n

## Best practices

✅ **Validate webhook data** - Check required fields exist
✅ **Handle errors** - Add error handling for failed actions
✅ **Respond quickly** - If response needed, process async if possible
✅ **Log events** - Store webhook data for debugging
✅ **Secure webhooks** - Use authentication when possible

## Checklist for webhook workflows

```
- [ ] Webhook path is unique and descriptive
- [ ] HTTP method matches sender (usually POST)
- [ ] Response mode set correctly (onReceived vs lastNode)
- [ ] Data validation included (check required fields)
- [ ] Error handling configured
- [ ] Tested with sample payload
- [ ] Webhook URL documented for sender
```
```

## File: patterns/http_api_integration.md

```markdown
# HTTP API Integration Pattern

## Overview

**Frequency**: 755 searches
**Complexity**: Simple to Medium (5-10 nodes)

## Pattern structure

```
Trigger (Webhook, Schedule, Manual)
  ↓
HTTP Request (Fetch data)
  ↓
[Optional: Transform/Filter]
  ↓
Action (Store, Process, Notify)
```

## Complete example: Fetch weather and send email

### Node 1: Schedule Trigger

```javascript
{
  "id": "schedule-1",
  "name": "Schedule",
  "type": "n8n-nodes-base.scheduleTrigger",
  "typeVersion": 1,
  "position": [250, 300],
  "parameters": {
    "rule": {
      "interval": [{
        "field": "cronExpression",
        "expression": "0 8 * * *"  // Daily at 8 AM
      }]
    }
  }
}
```

### Node 2: HTTP Request (Fetch Weather)

```javascript
{
  "id": "http-1",
  "name": "Get Weather",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.1,
  "position": [450, 300],
  "parameters": {
    "method": "GET",
    "url": "https://api.openweathermap.org/data/2.5/weather",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "openWeatherMapApi",
    "sendQuery": true,
    "queryParameters": {
      "parameters": [
        {"name": "q", "value": "London"},
        {"name": "units", "value": "metric"}
      ]
    }
  }
}
```

**HTTP Request returns**:
```json
{
  "main": {
    "temp": 15.5,
    "feels_like": 14.2
  },
  "weather": [{
    "description": "partly cloudy"
  }]
}
```

### Node 3: Email Notification

```javascript
{
  "id": "email-1",
  "name": "Send Email",
  "type": "n8n-nodes-base.emailSend",
  "typeVersion": 2,
  "position": [650, 300],
  "parameters": {
    "fromEmail": "weather@example.com",
    "toEmail": "user@example.com",
    "subject": "Daily Weather Report",
    "text": "Today's weather in London:\n\nTemperature: {{$json.main.temp}}°C\nFeels like: {{$json.main.feels_like}}°C\nConditions: {{$json.weather[0].description}}"
  }
}
```

## Best practices

✅ **Handle rate limits** - Add delays between requests
✅ **Parse responses** - Use Code node if needed
✅ **Error handling** - Check for API errors
✅ **Secure credentials** - Use n8n credential system
✅ **Timeout settings** - Set appropriate timeouts

## Checklist for API workflows

```
- [ ] API endpoint URL correct
- [ ] HTTP method correct (GET/POST/PUT/DELETE)
- [ ] Authentication configured
- [ ] Required headers included
- [ ] Query/body parameters set correctly
- [ ] Response parsing configured
- [ ] Error handling added
- [ ] Tested with actual API
```
```

## Evaluations (3+ scenarios)

**File**: `evaluations/workflow-patterns/eval-001-webhook-pattern.json`
```json
{
  "id": "pattern-001",
  "skills": ["n8n-workflow-patterns", "n8n-mcp-tools-expert"],
  "query": "I want to build a workflow that posts to Slack whenever someone submits a form on my website. How should I structure this?",
  "expected_behavior": [
    "Identifies webhook processing pattern as correct choice",
    "References patterns/webhook_processing.md",
    "Provides workflow creation checklist",
    "Suggests: Webhook → Slack structure",
    "Mentions using search_nodes to find webhook and slack nodes",
    "Recommends validation after building"
  ]
}
```

---

# SKILL #4: n8n Validation Expert (Week 3)

[Similar detailed structure with SKILL.md, ERROR_CATALOG.md, FALSE_POSITIVES.md, evaluation scenarios]

**Note**: Full implementation follows same pattern as above skills with:
- SKILL.md (validation loop workflow)
- ERROR_CATALOG.md (known errors from telemetry)
- FALSE_POSITIVES.md (Issues #304, #306, #338)
- 3+ evaluations

---

# SKILL #5: n8n Node Configuration (Week 3)

[Similar detailed structure with SKILL.md, DEPENDENCIES.md, evaluations]

**Note**: Full implementation follows same pattern with:
- SKILL.md (operation-aware configuration process)
- DEPENDENCIES.md (property dependency rules)
- OPERATION_PATTERNS.md (common configurations)
- 3+ evaluations

---

# Testing Strategy

## Evaluation-Driven Development Process

For EACH skill:

1. **Create 3+ evaluations FIRST**
2. **Establish baseline** (test without skill)
3. **Write minimal SKILL.md** (under 500 lines)
4. **Test against evaluations**
5. **Iterate until 100% pass**
6. **Add reference files as needed**

## Cross-Skill Integration Testing

Test skills working together:

```json
{
  "id": "integration-001",
  "skills": [
    "n8n-mcp-tools-expert",
    "n8n-workflow-patterns",
    "n8n-node-configuration",
    "n8n-expression-syntax",
    "n8n-validation-expert"
  ],
  "query": "Build a complete webhook to Slack workflow, validate it, and explain what you did.",
  "expected_behavior": [
    "Uses n8n-workflow-patterns to identify webhook pattern",
    "Uses n8n-mcp-tools-expert to search for nodes",
    "Uses n8n-node-configuration for Slack setup",
    "Uses n8n-expression-syntax for data mapping",
    "Uses n8n-validation-expert to validate result",
    "All 5 skills compose automatically",
    "Produces working, validated workflow"
  ]
}
```

---

# Distribution Strategy

## Claude Code Plugin Structure

```
n8n-mcp-skills-plugin/
├── plugin.json
├── skills/
│   └── [all 5 skills]
└── README.md
```

**plugin.json**:
```json
{
  "name": "n8n-mcp-skills",
  "version": "1.0.0",
  "description": "Expert skills for building n8n workflows with n8n-mcp",
  "skills": [
    "skills/n8n-expression-syntax",
    "skills/n8n-mcp-tools-expert",
    "skills/n8n-workflow-patterns",
    "skills/n8n-validation-expert",
    "skills/n8n-node-configuration"
  ],
  "requires": {
    "mcp_servers": ["n8n-mcp"]
  }
}
```

## GitHub Repository

```
n8n-mcp-skills/
├── README.md
├── LICENSE (MIT)
├── skills/ [all skills]
├── evaluations/ [all evaluations]
├── docs/
│   ├── INSTALLATION.md
│   ├── USAGE.md
│   └── DEVELOPMENT.md
└── .github/
    └── workflows/
        └── test-skills.yml
```

---

# README.md (for repository)

```markdown
# n8n-mcp Claude Skills

Expert Claude Skills for building n8n workflows using the n8n-mcp MCP server.

## What are these skills?

5 complementary skills that teach Claude how to:
- ✅ Write correct n8n expressions
- ✅ Use n8n-mcp MCP tools effectively
- ✅ Build workflows using proven patterns
- ✅ Interpret and fix validation errors
- ✅ Configure nodes with operation-aware guidance

## Skills included

1. **n8n Expression Syntax** - Correct {{}} syntax and common patterns
2. **n8n MCP Tools Expert** - How to use n8n-mcp tools (fixes 20% failure rate)
3. **n8n Workflow Patterns** - 5 proven patterns from 31,917 real workflows
4. **n8n Validation Expert** - Error interpretation and validation loops
5. **n8n Node Configuration** - Operation-aware configuration guidance

## Installation

### Claude Code

1. Download this repository
2. Copy `skills/` directory to your Claude Code skills folder
3. Reload Claude Code

### Claude.ai

1. Download and zip each skill folder individually
2. Upload via Settings > Capabilities > Skills

### API

See [docs/INSTALLATION.md](docs/INSTALLATION.md)

## Usage

Once installed, skills activate automatically when relevant:

- "How do I write n8n expressions?" → Expression Syntax skill
- "Find me a Slack node" → MCP Tools Expert skill
- "Build a webhook workflow" → Workflow Patterns skill
- "Why is validation failing?" → Validation Expert skill

## Requirements

- n8n-mcp MCP server installed and configured
- Claude Code, Claude.ai, or Claude API access

## Data-driven design

These skills are based on analysis of:
- 447,557 real MCP tool usage events
- 31,917 workflows created
- 19,113 validation errors
- 15,107 validation feedback loops

## License

MIT License - see LICENSE file

## Credits

Conceived by Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

Part of the n8n-mcp project.
```

---

# COMPLETE IMPLEMENTATION CHECKLIST

## Week 1: Expression Syntax (PoC)
- [ ] Create `skills/n8n-expression-syntax/` directory
- [ ] Write SKILL.md (200 lines)
- [ ] Write COMMON_MISTAKES.md (100 lines)
- [ ] Write EXAMPLES.md (50 lines)
- [ ] Create 3 evaluations
- [ ] Test evaluations without skill (baseline)
- [ ] Test evaluations with skill
- [ ] Iterate until 100% pass
- [ ] Document findings

## Week 2: MCP Tools + Workflow Patterns
- [ ] Create `skills/n8n-mcp-tools-expert/` directory
- [ ] Write SKILL.md (350 lines)
- [ ] Write SEARCH_GUIDE.md (150 lines)
- [ ] Write VALIDATION_GUIDE.md (100 lines)
- [ ] Write WORKFLOW_GUIDE.md (100 lines)
- [ ] Create 3+ evaluations
- [ ] Test and iterate

- [ ] Create `skills/n8n-workflow-patterns/` directory
- [ ] Write SKILL.md with checklist (400 lines)
- [ ] Write webhook_processing.md
- [ ] Write http_api_integration.md
- [ ] Write database_operations.md
- [ ] Write ai_agent_workflow.md
- [ ] Write scheduled_tasks.md
- [ ] Create 3+ evaluations
- [ ] Test composition with MCP Tools skill

## Week 3: Validation + Configuration
- [ ] Create `skills/n8n-validation-expert/`
- [ ] Write SKILL.md with validation loop
- [ ] Write ERROR_CATALOG.md (known errors)
- [ ] Write FALSE_POSITIVES.md (Issues #304, #338)
- [ ] Create 3+ evaluations
- [ ] Test with all previous skills

- [ ] Create `skills/n8n-node-configuration/`
- [ ] Write SKILL.md
- [ ] Write DEPENDENCIES.md
- [ ] Write OPERATION_PATTERNS.md
- [ ] Create 3+ evaluations

## Week 4: Integration & Testing
- [ ] Create cross-skill integration tests
- [ ] Test all 5 skills working together
- [ ] Test with Haiku, Sonnet, Opus
- [ ] Gather feedback
- [ ] Iterate based on real usage
- [ ] Performance optimization

## Week 5-6: Distribution
- [ ] Create plugin.json
- [ ] Package as Claude Code plugin
- [ ] Create GitHub repository
- [ ] Write comprehensive README
- [ ] Write INSTALLATION.md
- [ ] Write USAGE.md
- [ ] Write DEVELOPMENT.md
- [ ] Create demo video
- [ ] Announce to community

---

**This implementation guide is complete and ready to feed into Claude Code for autonomous execution.**

Conceived by Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
