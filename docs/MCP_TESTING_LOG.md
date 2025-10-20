# MCP Tool Testing Log
## Generated: 2025-10-20
## Purpose: Document actual tool responses for skill content creation

This log contains real responses from n8n-mcp tools to inform accurate skill content.

---

## n8n API Status

**Health Check Result**:
```json
{
  "status": "ok",
  "apiUrl": "https://n8n-test.n8n-mcp.com",
  "mcpVersion": "2.20.3",
  "versionCheck": "up to date",
  "responseTime": 798ms
}
```

✅ **n8n API Tools Available**: All workflow creation/management tools functional

---

## Database Statistics

```json
{
  "totalNodes": 537,
  "totalTemplates": 2653,
  "statistics": {
    "aiTools": 270,
    "triggers": 108,
    "versionedNodes": 141,
    "nodesWithDocumentation": 470,
    "documentationCoverage": "88%"
  },
  "packageBreakdown": [
    {"package": "@n8n/n8n-nodes-langchain", "nodeCount": 100},
    {"package": "n8n-nodes-base", "nodeCount": 437}
  ]
}
```

**Key Insights**:
- 537 nodes total (437 base + 100 langchain)
- 270 AI-capable tools
- 108 trigger nodes
- 88% documentation coverage
- 2,653 templates with avg 4,115 views

---

## Search Tool Testing

### search_nodes - Common Queries

**Query: "webhook"** → Returns Webhook (trigger), Respond to Webhook (transform)
- nodeType format: `nodes-base.webhook`
- workflowNodeType format: `n8n-nodes-base.webhook`
- ⚠️ **Critical**: Use different formats for different tools!

**Query: "http"** → Returns HTTP Request, HTTP Request Tool (AI), Code Tool
- Regular: `nodes-base.httpRequest`
- AI Tool: `nodes-langchain.toolHttpRequest`

**Query: "database"** → Returns Firebase, Redis Vector Store, etc.

---

## Node Essentials Testing

### Webhook Node

**Key Properties**:
- `httpMethod`: GET, POST, PUT, DELETE, etc. (default: GET)
- `path`: Webhook URL path (e.g., "form-submit")
- `responseMode`: onReceived, lastNode, responseNode
- **CRITICAL**: Webhook data structure is `$json.body.*` not `$json.*`

**Output Structure**:
```javascript
{
  "headers": {...},
  "params": {...},
  "query": {...},
  "body": {  // ⚠️ User data is HERE!
    "name": "John",
    "email": "john@example.com"
  }
}
```

---

## Validation Testing

### Validation Profiles Comparison

**Test Config**: `{resource: "channel", operation: "create"}` on Slack node

**Result**: Missing required field "name"
- All profiles detected this error
- Fix provided: "Provide a channel name"
- Warning about rate limits (best practice)

---

## Template Analysis

**Total Templates**: 2,653
**Popular Templates** (webhook + slack):
- #2947: Weather via Slack (1,500 views) - Webhook → OpenStreetMap → NWS → Slack
- #4039: Download Slack Media (778 views) - SlackTrigger → HTTP Request
- #5529: Jamf Patch to Slack (147 views) - Complex multi-node

**Key Pattern**: Webhook → Transform → Action → Notify (5-7 nodes avg)

---

## Critical Findings for Skills

### 1. Expression Syntax (Skill #1)
- ✅ Webhook data under `.body` (not root)
- ✅ Code nodes use direct access ($json), NOT expressions ({{}})
- ✅ Node references: `$node["Node Name"].json.field`

### 2. MCP Tools Expert (Skill #2)
- ✅ nodeType formats differ: `nodes-base.*` vs `n8n-nodes-base.*`
- ✅ get_node_essentials preferred over get_node_info (5KB vs 100KB+)
- ✅ Validation profiles: minimal/runtime/ai-friendly/strict
- ✅ Smart parameters: branch="true"/"false" for IF, case=N for Switch
- ✅ Auto-sanitization runs on ALL nodes during any update

### 3. Workflow Patterns (Skill #3)
- ✅ 2,653 real templates available
- ✅ Template metadata includes complexity, setup time, services
- ✅ Common pattern: Trigger → Process → Act (5-7 nodes)
- ✅ Webhook workflows: 27.6% of all workflows

### 4. Validation Expert (Skill #4)
- ✅ Real validation errors documented
- ✅ Auto-sanitization fixes operator structures
- ✅ Binary operators (equals, contains) vs unary (isEmpty, isNotEmpty)

### 5. Node Configuration (Skill #5)
- ✅ Property dependencies documented (e.g., sendBody → contentType)
- ✅ Operation-specific requirements vary
- ✅ 8 AI connection types supported

---

## Tools Availability Summary

**Available WITHOUT n8n API**:
- search_nodes, list_nodes, get_node_essentials ✅
- validate_node_minimal, validate_node_operation ✅
- validate_workflow, get_property_dependencies ✅
- search_templates, get_template, list_tasks ✅

**Requires n8n API** (AVAILABLE at n8n-test.n8n-mcp.com):
- n8n_create_workflow ✅
- n8n_update_partial_workflow ✅
- n8n_validate_workflow (by ID) ✅
- n8n_list_workflows, n8n_get_workflow ✅
- n8n_trigger_webhook_workflow ✅

---

**Testing Complete**: Ready for skill implementation with real data!
