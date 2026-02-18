# Workflow Management Tools Guide

Complete guide for creating, updating, and managing n8n workflows.

---

## Tool Availability

**Requires n8n API**: All tools in this guide need `N8N_API_URL` and `N8N_API_KEY` configured.

If unavailable, use template examples and validation-only workflows.

---

## n8n_find_workflow (SEARCH BEFORE CREATE!)

**Speed**: 50-200ms

**Use when**: Before creating a new workflow, to prevent duplicates

**Syntax**:
```javascript
n8n_find_workflow({
  name: "Webhook to Slack",     // Required: workflow name to search
  matchMode: "contains",        // Optional: exact, contains (default), fuzzy
  activeOnly: false,            // Optional: only search active workflows
  limit: 10                     // Optional: max results
})
```

**Returns**: Matching workflows with webhook URLs, or null if not found

**Match Modes**:
- `exact` - Exact name match
- `contains` (default) - Name contains query
- `fuzzy` - Typo-tolerant with match scores

**Pattern: Always search before create!**
```javascript
// Step 1: Check if workflow exists
const existing = await n8n_find_workflow({name: "My Webhook"});

// Step 2: Create or update
if (existing) {
  n8n_update_partial_workflow({id: existing.id, operations: [...]});
} else {
  n8n_create_workflow({name: "My Webhook", nodes: [...], connections: {...}});
}
```

---

## n8n_create_workflow

**Speed**: 100-500ms

**Use when**: Creating new workflows from scratch

**Syntax**:
```javascript
n8n_create_workflow({
  name: "Webhook to Slack",  // Required
  nodes: [...],              // Required: array of nodes
  connections: {...},        // Required: connections object
  settings: {...}            // Optional: workflow settings
})
```

**Returns**: Created workflow with ID

**Example**:
```javascript
n8n_create_workflow({
  name: "Webhook to Slack",
  nodes: [
    {
      id: "webhook-1",
      name: "Webhook",
      type: "n8n-nodes-base.webhook",  // Full prefix!
      typeVersion: 2,
      position: [250, 300],
      parameters: {
        path: "slack-notify",
        httpMethod: "POST"
      }
    },
    {
      id: "slack-1",
      name: "Slack",
      type: "n8n-nodes-base.slack",
      typeVersion: 2,
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
      "main": [[{node: "Slack", type: "main", index: 0}]]
    }
  }
})
```

**Notes**:
- Workflows created **inactive** (activate with `activateWorkflow` operation)
- Auto-sanitization runs on creation
- Validate before creating for best results

**New**: Create and activate in one call:
```javascript
n8n_create_workflow({
  name: "Webhook to Slack",
  nodes: [...],
  connections: {...},
  activate: true  // Activates immediately after creation
})
// Returns: workflow with webhookUrls and activation status
```

---

## n8n_update_partial_workflow (MOST USED!)

**Speed**: 50-200ms | **Uses**: 38,287 (most used tool!)

**Use when**: Making incremental changes to workflows

**Common pattern**: 56s average between edits (iterative building!)

### 20 Operation Types

**Node Operations** (6 types):
1. `addNode` - Add new node
2. `removeNode` - Remove node by ID or name
3. `updateNode` - Update node properties (use dot notation)
4. `moveNode` - Change position
5. `enableNode` - Enable disabled node
6. `disableNode` - Disable active node

**Connection Operations** (5 types):
7. `addConnection` - Connect nodes (supports smart params)
8. `removeConnection` - Remove connection (supports ignoreErrors)
9. `rewireConnection` - Change connection target
10. `cleanStaleConnections` - Auto-remove broken connections
11. `replaceConnections` - Replace entire connections object

**Metadata Operations** (4 types):
12. `updateSettings` - Workflow settings
13. `updateName` - Rename workflow
14. `addTag` - Add tag
15. `removeTag` - Remove tag

**Activation Operations** (2 types):
16. `activateWorkflow` - Activate workflow for automatic execution
17. `deactivateWorkflow` - Deactivate workflow

**Internal API Operations** (3 types, requires N8N_USER_EMAIL + N8N_USER_PASSWORD):
18. `setPinData` - Pin test data to a node
19. `clearPinData` - Clear pinned data from node(s)
20. `updateDescription` - Set workflow description

### Intent Parameter (IMPORTANT!)

Always include `intent` for better responses:

```javascript
n8n_update_partial_workflow({
  id: "workflow-id",
  intent: "Add error handling for API failures",  // Describe what you're doing
  operations: [...]
})
```

### Smart Parameters

**IF nodes** - Use semantic branch names:
```javascript
{
  type: "addConnection",
  source: "IF",
  target: "True Handler",
  branch: "true"  // Instead of sourceIndex: 0
}

{
  type: "addConnection",
  source: "IF",
  target: "False Handler",
  branch: "false"  // Instead of sourceIndex: 1
}
```

**Switch nodes** - Use semantic case numbers:
```javascript
{
  type: "addConnection",
  source: "Switch",
  target: "Handler A",
  case: 0
}

{
  type: "addConnection",
  source: "Switch",
  target: "Handler B",
  case: 1
}
```

### AI Connection Types (8 types)

**Full support** for AI workflows:

```javascript
// Language Model
{
  type: "addConnection",
  source: "OpenAI Chat Model",
  target: "AI Agent",
  sourceOutput: "ai_languageModel"
}

// Tool
{
  type: "addConnection",
  source: "HTTP Request Tool",
  target: "AI Agent",
  sourceOutput: "ai_tool"
}

// Memory
{
  type: "addConnection",
  source: "Window Buffer Memory",
  target: "AI Agent",
  sourceOutput: "ai_memory"
}

// All 8 types:
// - ai_languageModel
// - ai_tool
// - ai_memory
// - ai_outputParser
// - ai_embedding
// - ai_vectorStore
// - ai_document
// - ai_textSplitter
```

### Property Removal with undefined

Remove properties by setting them to `undefined`:

```javascript
// Remove a property
{
  type: "updateNode",
  nodeName: "HTTP Request",
  updates: { onError: undefined }
}

// Migrate from deprecated property
{
  type: "updateNode",
  nodeName: "HTTP Request",
  updates: {
    continueOnFail: undefined,  // Remove old
    onError: "continueErrorOutput"  // Add new
  }
}
```

### Activation Operations

```javascript
// Activate workflow
n8n_update_partial_workflow({
  id: "workflow-id",
  intent: "Activate workflow for production",
  operations: [{type: "activateWorkflow"}]
})

// Deactivate workflow
n8n_update_partial_workflow({
  id: "workflow-id",
  intent: "Deactivate workflow for maintenance",
  operations: [{type: "deactivateWorkflow"}]
})
```

### Internal API Operations

**Requires**: N8N_USER_EMAIL + N8N_USER_PASSWORD

```javascript
// Pin test data to a node for debugging
n8n_update_partial_workflow({
  id: "workflow-id",
  intent: "Pin test data for debugging",
  operations: [{
    type: "setPinData",
    nodeName: "HTTP Request",
    data: [{json: {id: 1, name: "Test User", email: "test@example.com"}}]
  }]
})

// Clear pinned data from specific node
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [{type: "clearPinData", nodeName: "HTTP Request"}]
})

// Clear ALL pinned data
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [{type: "clearPinData"}]
})

// Set workflow description
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [{
    type: "updateDescription",
    description: "Processes incoming webhooks and forwards to Slack."
  }]
})
```

**Note**: These operations use the n8n Internal REST API (session-based authentication), not the Public API. They are optional and degrade gracefully if credentials are not configured.

### Example Usage

```javascript
n8n_update_partial_workflow({
  id: "workflow-id",
  intent: "Add transform node after IF condition",
  operations: [
    // Add node
    {
      type: "addNode",
      node: {
        name: "Transform",
        type: "n8n-nodes-base.set",
        position: [400, 300],
        parameters: {}
      }
    },
    // Connect it (smart parameter)
    {
      type: "addConnection",
      source: "IF",
      target: "Transform",
      branch: "true"  // Clear and semantic!
    }
  ]
})
```

### Cleanup & Recovery

**cleanStaleConnections** - Remove broken connections:
```javascript
{type: "cleanStaleConnections"}
```

**rewireConnection** - Change target atomically:
```javascript
{
  type: "rewireConnection",
  source: "Webhook",
  from: "Old Handler",
  to: "New Handler"
}
```

**Best-effort mode** - Apply what works:
```javascript
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [...],
  continueOnError: true  // Don't fail if some operations fail
})
```

**Validate before applying**:
```javascript
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [...],
  validateOnly: true  // Preview without applying
})
```

---

## n8n_deploy_template (QUICK START!)

**Speed**: 200-500ms

**Use when**: Deploying a template directly to n8n instance

```javascript
n8n_deploy_template({
  templateId: 2947,  // Required: from n8n.io
  name: "My Weather to Slack",  // Optional: custom name
  autoFix: true,  // Default: auto-fix common issues
  autoUpgradeVersions: true,  // Default: upgrade node versions
  stripCredentials: true  // Default: remove credential refs
})
```

**Returns**:
- Workflow ID
- Required credentials
- Fixes applied

**Example**:
```javascript
// Deploy a webhook to Slack template
const result = n8n_deploy_template({
  templateId: 2947,
  name: "Production Slack Notifier"
});

// Result includes:
// - id: "new-workflow-id"
// - requiredCredentials: ["slack"]
// - fixesApplied: ["typeVersion upgraded", "expression format fixed"]
```

---

## n8n_workflow_versions (VERSION CONTROL)

**Use when**: Managing workflow history, rollback, cleanup

### List Versions
```javascript
n8n_workflow_versions({
  mode: "list",
  workflowId: "workflow-id",
  limit: 10
})
```

### Get Specific Version
```javascript
n8n_workflow_versions({
  mode: "get",
  versionId: 123
})
```

### Rollback to Previous Version
```javascript
n8n_workflow_versions({
  mode: "rollback",
  workflowId: "workflow-id",
  versionId: 123,  // Optional: specific version
  validateBefore: true  // Default: validate before rollback
})
```

### Delete Versions
```javascript
// Delete specific version
n8n_workflow_versions({
  mode: "delete",
  workflowId: "workflow-id",
  versionId: 123
})

// Delete all versions for workflow
n8n_workflow_versions({
  mode: "delete",
  workflowId: "workflow-id",
  deleteAll: true
})
```

### Prune Old Versions
```javascript
n8n_workflow_versions({
  mode: "prune",
  workflowId: "workflow-id",
  maxVersions: 10  // Keep 10 most recent
})
```

---

## n8n_test_workflow (TRIGGER EXECUTION)

**Use when**: Testing workflow execution

**Auto-detects** trigger type (webhook, form, chat)

```javascript
// Test webhook workflow
n8n_test_workflow({
  workflowId: "workflow-id",
  triggerType: "webhook",  // Optional: auto-detected
  httpMethod: "POST",
  data: {message: "Hello!"},
  waitForResponse: true,
  timeout: 120000
})

// Test chat workflow
n8n_test_workflow({
  workflowId: "workflow-id",
  triggerType: "chat",
  message: "Hello, AI agent!",
  sessionId: "session-123"  // For conversation continuity
})
```

### Assertion Support (NEW)

Automated output validation:
```javascript
n8n_test_workflow({
  id: "workflow-id",
  testMode: "webhook",
  webhookData: {message: "Hello!"},
  expectedOutput: {status: "ok", processed: true},
  assertionMode: "partial"  // "partial" (default) or "exact"
})
// Returns: testResult: "PASS" or "FAIL" with field-level details
```

---

## n8n_validate_workflow (by ID)

**Use when**: Validating workflow stored in n8n

```javascript
n8n_validate_workflow({
  id: "workflow-id",
  options: {
    validateNodes: true,
    validateConnections: true,
    validateExpressions: true,
    profile: "runtime"
  }
})
```

---

## n8n_get_workflow

**Use when**: Retrieving workflow details

**Modes**:
- `full` (default) - Complete workflow JSON
- `details` - Full + execution stats
- `structure` - Nodes + connections only
- `minimal` - ID, name, active, tags
- `summary` (NEW) - Agent-friendly compact overview with webhook URLs, credentials used

```javascript
// Full workflow
n8n_get_workflow({id: "workflow-id"})

// Just structure
n8n_get_workflow({id: "workflow-id", mode: "structure"})

// Minimal metadata
n8n_get_workflow({id: "workflow-id", mode: "minimal"})
```

---

## n8n_executions (EXECUTION MANAGEMENT)

**Use when**: Managing workflow executions

### Get Execution Details
```javascript
n8n_executions({
  action: "get",
  id: "execution-id",
  mode: "summary"  // preview, summary, filtered, full, error
})

// Error mode for debugging
n8n_executions({
  action: "get",
  id: "execution-id",
  mode: "error",
  includeStackTrace: true
})
```

### List Executions
```javascript
n8n_executions({
  action: "list",
  workflowId: "workflow-id",
  status: "error",  // success, error, waiting
  limit: 100
})
```

### Delete Execution
```javascript
n8n_executions({
  action: "delete",
  id: "execution-id"
})
```

---

## Workflow Lifecycle

**Standard pattern**:
```
0. SEARCH (prevent duplicates)
   n8n_find_workflow({name: "..."})
   → Check if exists already

1. CREATE
   n8n_create_workflow({...})
   → Returns workflow ID

2. VALIDATE
   n8n_validate_workflow({id})
   → Check for errors

3. EDIT (iterative! 56s avg between edits)
   n8n_update_partial_workflow({id, intent: "...", operations: [...]})
   → Make changes

4. VALIDATE AGAIN
   n8n_validate_workflow({id})
   → Verify changes

5. ACTIVATE
   n8n_update_partial_workflow({
     id,
     intent: "Activate workflow",
     operations: [{type: "activateWorkflow"}]
   })
   → Workflow now runs on triggers!

6. MONITOR
   n8n_executions({action: "list", workflowId: id})
   n8n_executions({action: "get", id: execution_id})
```

---

## Common Patterns from Telemetry

### Pattern 1: Edit → Validate (7,841 occurrences)
```javascript
n8n_update_partial_workflow({...})
// ↓ 23s (thinking about what to validate)
n8n_validate_workflow({id})
```

### Pattern 2: Validate → Fix (7,266 occurrences)
```javascript
n8n_validate_workflow({id})
// ↓ 58s (fixing errors)
n8n_update_partial_workflow({...})
```

### Pattern 3: Iterative Building (31,464 occurrences)
```javascript
update → update → update → ... (56s avg between edits)
```

**This shows**: Workflows are built **iteratively**, not in one shot!

---

## Best Practices

### Do

- Build workflows **iteratively** (avg 56s between edits)
- Include **intent** parameter for better responses
- Use **smart parameters** (branch, case) for clarity
- Validate **after** significant changes
- Use **atomic mode** (default) for critical updates
- Specify **sourceOutput** for AI connections
- Clean stale connections after node renames/deletions
- Use `n8n_deploy_template` for quick starts
- Activate workflows via API when ready

### Don't

- Try to build workflows in one shot
- Skip the intent parameter
- Use sourceIndex when branch/case available
- Skip validation before activation
- Forget to test workflows after creation
- Ignore auto-sanitization behavior

---

## Summary

**Most Important**:
1. **n8n_update_partial_workflow** is most-used tool (38,287 uses)
2. Include **intent** parameter for better responses
3. Workflows built **iteratively** (56s avg between edits)
4. Use **smart parameters** (branch="true", case=0) for clarity
5. **AI connections** supported (8 types with sourceOutput)
6. **Workflow activation** supported via API (`activateWorkflow` operation)
7. **Auto-sanitization** runs on all operations
8. Use **n8n_deploy_template** for quick starts

**New Tools**:
- `n8n_find_workflow` - Search before create (NEW!)
- `n8n_list_credentials` - Discover credential IDs (NEW!)
- `n8n_sync_installed_nodes` - Sync with n8n instance (NEW!)
- `n8n_deploy_template` - Deploy templates directly
- `n8n_workflow_versions` - Version control & rollback
- `n8n_test_workflow` - Trigger execution with assertions
- `n8n_executions` - Manage executions

**Related**:
- [SEARCH_GUIDE.md](SEARCH_GUIDE.md) - Find nodes to add
- [VALIDATION_GUIDE.md](VALIDATION_GUIDE.md) - Validate workflows
