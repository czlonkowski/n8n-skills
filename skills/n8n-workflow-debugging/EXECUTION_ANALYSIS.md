# Execution Analysis Guide

Deep techniques for tracing workflow executions and understanding failures.

---

## Getting Execution Data

### Step 1: List Recent Executions

```javascript
// Get last 10 executions
n8n_list_executions({
  workflowId: "123",
  limit: 10
})

// Returns: Array of execution summaries with:
// - id: Execution ID
// - status: "success" | "error" | "waiting"
// - startedAt: Timestamp
// - stoppedAt: Timestamp
// - error: Error message if failed
```

### Step 2: Get Detailed Execution Data

```javascript
// Get complete execution with all node data
n8n_get_execution({
  workflowId: "123",
  executionId: "abc123"
})

// Returns: Full execution tree with:
// - All nodes executed
// - Input/output for each node
// - Error details
// - Execution path taken
// - Performance metrics
```

---

## Analyzing Execution Flow

### Understanding Execution Data Structure

```javascript
{
  "id": "exec123",
  "status": "error",
  "startedAt": "2024-02-28T10:00:00Z",
  "stoppedAt": "2024-02-28T10:00:15Z",
  "executionTime": 15000,  // milliseconds

  "nodes": {
    "Webhook": {
      "status": "success",
      "input": { "body": {...}, "query": {...} },
      "output": [...],
      "executedTime": 2000
    },

    "HTTP Request": {
      "status": "error",
      "input": [...],
      "output": null,
      "error": "timeout",
      "executedTime": 13000
    }
  }
}
```

---

## Comparison Analysis

### Comparing Failed vs Successful Executions

**Process**:
1. Get 1 successful execution
2. Get 1 failed execution with same trigger
3. Compare node outputs step by step

**Example**:

```javascript
// Successful: GET /webhook?id=123 → HTTP Request → Slack
// Failed: GET /webhook?id=456 → HTTP Request → ERROR

// Step 1: Check webhook node output
// Successful: {body: {id: "123"}, query: {id: "123"}}
// Failed: {body: {id: "456"}, query: {id: "456"}}

// Step 2: Check HTTP Request input
// Successful: URL = "https://api.example.com/user/123"
// Failed: URL = "https://api.example.com/user/456"
// → Different IDs, so maybe ID 456 doesn't exist?

// Step 3: Check HTTP Request output/error
// Successful: {status: 200, data: {...}}
// Failed: {status: 404, error: "Not found"}
// → ROOT CAUSE: ID 456 doesn't exist in external system
```

---

## Performance Analysis

### Identifying Slow Nodes

```javascript
// From execution data, extract timing per node:
const timings = {};
for (const [nodeName, nodeData] of Object.entries(nodes)) {
  timings[nodeName] = nodeData.executedTime;
}

// Sort by slowest first
const slowest = Object.entries(timings)
  .sort((a, b) => b[1] - a[1])
  .slice(0, 5);

// slowest = [
//   ["HTTP Request", 8000],
//   ["Code node", 2000],
//   ["Set data", 500],
// ]
```

**Interpretation**:
- HTTP Request: 8s → Network/API issue? Add timeout handling
- Code node: 2s → Logic complexity? Optimize or use simpler approach
- Set data: 500ms → Normal for data transformation

---

## Data Flow Tracing

### Following Data Through Nodes

**Example Workflow**: Webhook → Parse → Filter → Slack

```javascript
// 1. Webhook output
webhook.output = {
  body: {
    name: "John",
    email: "john@example.com",
    status: "active"
  }
}

// 2. Parse node output (transforms data)
parse.output = {
  user: {
    name: "John",
    email: "john@example.com"
  },
  status: "active"
}

// 3. Filter node (conditions)
filter.output = [
  {
    user: {name: "John", email: "john@example.com"},
    status: "active"
  }
  // Only active users pass filter
]

// 4. Slack node (sends message)
slack.output = {
  ts: "1234567890.123456",  // Message timestamp = success
  channel: "C123456"
}
```

**Debugging**: If Filter produces empty array → message never sent to Slack
- Check filter condition
- Check input data to filter

---

## Error Message Interpretation

### Common Error Patterns

| Error | Likely Cause | Quick Check |
|-------|-------------|------------|
| `timeout` | Node took too long | Check external service, increase timeout |
| `401 Unauthorized` | Auth failed | Verify credentials/token |
| `Cannot read property X` | Data format wrong | Check node input structure |
| `Missing required field` | Config incomplete | Get node info, check properties |
| `ECONNREFUSED` | Service unreachable | Check service/firewall |
| `SyntaxError` | Code/expression invalid | Review syntax, test in isolation |

### Detailed Error Analysis

```javascript
// Error object from execution:
{
  "name": "NodeOperationError",
  "message": "Could not send message",
  "description": "Invalid auth token",
  "context": {
    "nodeType": "nodes-base.slack",
    "operation": "postMessage"
  }
}

// Interpretation:
// - Node: Slack
// - Operation: Send message
// - Problem: Invalid auth token
// - Solution: Update Slack credentials
```

---

## Execution Patterns

### Pattern Recognition

**Pattern 1: Always Fails at Same Node**
```
Exec 1: Webhook ✓ → HTTP ✗
Exec 2: Webhook ✓ → HTTP ✗
Exec 3: Webhook ✓ → HTTP ✗

→ HTTP Request node misconfigured
```

**Pattern 2: Intermittent at External Node**
```
Exec 1: ... → Slack ✓
Exec 2: ... → Slack ✓
Exec 3: ... → Slack ✗ (timeout)
Exec 4: ... → Slack ✓

→ Slack API timeout, add retry logic
```

**Pattern 3: Failure on Specific Data**
```
ID 1-100: Success
ID 101-200: Success
ID 201: Error (does not exist)
ID 202: Success

→ Data validation issue, not node config
```

---

## Using Code Nodes for Inspection

### Debugging Data in Execution

```javascript
// Add temporary Code node to inspect data:

// INPUT: received data
console.log("Input data:", JSON.stringify($input.all(), null, 2));

// INSPECTION: check structure
const data = $input.first().json;
console.log("Keys:", Object.keys(data));
console.log("Type:", typeof data);

// FILTERING: find problematic items
const problems = $input.all()
  .filter(item => !item.json.id)
  .map(item => item.json);
console.log("Missing ID:", problems);

// TRANSFORMATION: fix structure
return $input.all().map(item => ({
  json: {
    ...item.json,
    timestamp: new Date().toISOString()
  }
}));
```

Then check console output in execution logs.

---

## Debugging Checklist per Node Type

### HTTP Request Node

```
□ URL is correct and complete
□ Method matches API (GET/POST/etc)
□ Authentication is set (Basic/Bearer/etc)
□ Headers are correct
□ Body format matches API (JSON/Form/etc)
□ Timeout is reasonable (10-30s)
□ Response is parseable
```

### Database Node

```
□ Connection is active
□ Table/collection exists
□ Query syntax is correct
□ Input values are properly escaped
□ Output format expected
□ Permissions allow operation
```

### Slack/Email Nodes

```
□ Credentials are valid
□ Channel/email exists and accessible
□ Message format correct
□ Permissions include sending
□ Not rate limited
```

### Code Node

```
□ Syntax is valid JavaScript
□ Input structure correct
□ Return format: [{json: {...}}]
□ No undefined references
□ Error handling for edge cases
```

---

## Success Metrics

**Good Execution Trace**:
- ✅ All nodes show status
- ✅ No missing output fields
- ✅ Timing reasonable (<30s)
- ✅ Error clearly identifies failing node
- ✅ Data flow makes sense

**Poor Execution Trace**:
- ❌ Missing node outputs
- ❌ No error message
- ❌ Execution time abnormally high
- ❌ Data structure doesn't match expectations
