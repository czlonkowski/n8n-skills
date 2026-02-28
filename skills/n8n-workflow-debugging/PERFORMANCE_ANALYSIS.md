# Performance Analysis Guide

Techniques for identifying and fixing workflow performance bottlenecks.

---

## Performance Metrics

### Key Metrics to Track

```javascript
// From execution data:

totalExecutionTime = endTime - startTime;        // Total workflow duration
nodeExecutionTime = node.endTime - node.startTime;  // Per-node duration
percentageOfTotal = (nodeTime / totalTime) * 100;  // Node impact

// Example:
// Total: 45 seconds
// HTTP Request: 30 seconds (67% of total) ← BOTTLENECK
// Slack: 2 seconds
// Code: 3 seconds
```

---

## Identifying Performance Bottlenecks

### Step 1: Get Baseline

```javascript
// Get multiple successful executions
n8n_list_executions({
  workflowId: "123",
  limit: 10
})

// Calculate average execution time:
const times = executions.map(e => e.executedTime);
const avg = times.reduce((a, b) => a + b) / times.length;
const min = Math.min(...times);
const max = Math.max(...times);

console.log(`Avg: ${avg}ms, Min: ${min}ms, Max: ${max}ms`);
// Example: Avg: 15000ms, Min: 10000ms, Max: 25000ms
```

### Step 2: Identify Slowest Nodes

```javascript
// For a single execution:
const nodeTimes = {};
for (const [name, node] of Object.entries(execution.nodes)) {
  nodeTimes[name] = node.executedTime;
}

// Sort by slowest
const slowest = Object.entries(nodeTimes)
  .sort((a, b) => b[1] - a[1])
  .slice(0, 5);

// slowest = [
//   ["HTTP Request", 10000],
//   ["Code Transform", 2000],
//   ["Set Data", 500],
//   ["Webhook", 100],
//   ["Slack", 900]
// ]
```

### Step 3: Analyze Slow Nodes

**Pattern Recognition**:
- **HTTP Request 10s** → External service slow? Add timeout, retry, or use alternative
- **Code 2s** → Complex logic? Optimize or use simpler approach
- **Set 500ms** → Normal for data transformation
- **Custom Node 5s** → Consider if necessary

---

## Performance Optimization Patterns

### Pattern 1: Slow HTTP Request (Network Latency)

**Causes**:
- External API is slow
- Network latency
- Large response size
- Timeout configured too high

**Solutions**:

**Option 1: Reduce Scope**
```javascript
// Instead of fetching all user data
// https://api.example.com/users?page=1&limit=100

// Fetch only needed fields
// https://api.example.com/users?page=1&limit=100&fields=id,name,email
```

**Option 2: Add Caching**
```javascript
// Check Redis or local cache before HTTP request
// If cached → Use cached data (instant)
// If not cached → HTTP request (slow) then cache result
```

**Option 3: Batch Requests**
```javascript
// Instead of 100 individual requests (100 × 1s = 100s)
// Use batch endpoint: 1 request with 100 IDs (1 × 2s = 2s)
// 50x faster!
```

**Option 4: Increase Timeout Strategically**
```javascript
// Don't just increase timeout from 10s → 30s
// That makes failures take longer too
// Better: Reduce requests by caching/batching first
```

### Pattern 2: Complex Code Node

**Causes**:
- Inefficient algorithms
- N² complexity loops
- Unnecessary transformations
- Large object manipulations

**Solutions**:

**Option 1: Optimize Algorithm**
```javascript
// SLOW: N² complexity
const result = [];
for (const item of $input.all()) {
  for (const other of $input.all()) {
    if (item.id === other.id) {
      result.push({...item, ...other});
    }
  }
}

// FAST: O(n) complexity
const map = new Map($input.all().map(item => [item.id, item]));
const result = Array.from(map.values());
```

**Option 2: Stream Processing**
```javascript
// Instead of loading all data in memory:
// Process in chunks and return immediately

// For large datasets: use pagination/batching
// 1000 items × 1 item/ms = 1s (vs 500ms if optimized)
```

**Option 3: Use Simpler Node Type**
```javascript
// Instead of Code node for simple mapping → Use Set node
// Instead of Code node for filtering → Use Filter node
// Built-in nodes are faster than JavaScript execution
```

### Pattern 3: Too Many Nodes

**Cause**: Workflow has 50+ nodes, each adds overhead

**Solution**:
```javascript
// Before: Webhook → 5 nodes → Code → 10 nodes → Slack
// Total: ~50 nodes, 15s execution

// After: Webhook → Code (single node does all transformations) → Slack
// Total: ~3 nodes, 5s execution
// 3x faster!

// Consolidate where it makes sense
// Use Code nodes for complex multi-step logic
```

---

## Optimization Checklist

### Quick Wins (Easy, High Impact)

- [ ] **Reduce HTTP requests** - Cache, batch, or parallelize
- [ ] **Optimize Code logic** - Use better algorithms, remove loops
- [ ] **Consolidate nodes** - Combine multiple simple nodes into one
- [ ] **Remove unnecessary nodes** - Only what's needed
- [ ] **Filter early** - Remove unwanted data before processing

### Medium Effort (Moderate Impact)

- [ ] **Add parallel processing** - Run independent nodes simultaneously
- [ ] **Implement caching** - Cache external API responses
- [ ] **Use pagination** - Process large datasets in batches
- [ ] **Optimize expressions** - Avoid complex {{}} syntax
- [ ] **Replace slow nodes** - Use faster alternative nodes

### Complex Solutions (Requires Architecture Change)

- [ ] **Move to scheduled workflow** - If real-time not required
- [ ] **Split into multiple workflows** - Process in stages
- [ ] **Use database for state** - Instead of in-memory
- [ ] **Implement queuing** - Process async with background jobs
- [ ] **Use native functions** - Instead of Code nodes where possible

---

## Performance Targets

### Acceptable Execution Times

| Workflow Type | Target | Max |
|---|---|---|
| Webhook processing | 1-5s | 10s |
| Report generation | 5-30s | 60s |
| Batch processing | 30-300s | unlimited |
| Real-time sync | 1-2s | 5s |
| Database operations | 2-10s | 30s |

### Red Flags

- ⚠️ **>30s for webhook** - User waiting, requests timeout
- ⚠️ **>100s for anything** - Likely architectural issue
- ⚠️ **Increasing over time** - Possible memory leak or data growth
- ⚠️ **>50% on single node** - Major bottleneck, needs optimization

---

## Performance Monitoring

### Setting Up Monitoring

**Step 1: Baseline Execution Times**
```javascript
// Record execution times for 10-20 runs
runs = [10500, 11200, 10800, 15000, 10600, ...]
avg = 11500ms (11.5 seconds)
```

**Step 2: Set Alerts**
- If avg > 15s → Investigate
- If max > 30s → Immediate action
- If trending up → Likely issue

**Step 3: Monitor by Node**
- Track slowest 3-5 nodes
- Alert if any node >50% of total
- Track over time for trends

---

## Real-World Example

### Scenario: Slack Report Workflow Slow

**Initial Performance**:
- Execution time: 35 seconds
- User complaint: "Report takes forever"

**Analysis**:
```javascript
// Slowest nodes:
1. "Get Users" (HTTP) - 15s (43%)
2. "Transform Data" (Code) - 12s (34%)
3. "Generate Report" (Code) - 6s (17%)
4. "Send Slack" - 2s (6%)

Total: 35s
```

**Optimization**:

1. **"Get Users" optimized** (15s → 2s)
   - Was: Individual API call per user (100 users = 100 requests)
   - Now: Single batch endpoint with all IDs
   - Impact: 13s saved

2. **"Transform Data" optimized** (12s → 1s)
   - Was: Double nested loop with object creation
   - Now: Single map operation
   - Impact: 11s saved

3. **"Generate Report" unchanged** (6s)
   - Already optimal, but kept for clarity

**Result**:
- Before: 35 seconds
- After: 11 seconds
- Improvement: 3.2x faster ✅

---

## Tools for Performance Analysis

### MCP Tools

```javascript
// Get execution with timing
n8n_get_execution({
  workflowId: "123",
  executionId: "abc"
})
// Returns: Full execution tree with node timing

// Validate for performance issues
validate_workflow({id: "123"})
// Identifies obvious inefficiencies
```

### Browser DevTools (for HTTP Request nodes)

- Open n8n UI → Workflow → Open in browser DevTools
- Network tab shows HTTP timing
- Can identify slow endpoints

### Code Node Inspection

```javascript
// Time a section of code:
const start = Date.now();

// ... your code ...
const userLists = await complexTransformation(data);

const elapsed = Date.now() - start;
console.log(`Transformation took ${elapsed}ms`);
```

---

## Common Misconceptions

❌ **"Just increase timeout"** → Doesn't fix slow nodes, masks problems
❌ **"Add more nodes for clarity"** → Slower execution, not faster
❌ **"Complex Code is always better"** → Simple fast > Complex slow
❌ **"Caching solves everything"** → Works for repeated requests, not first-time
❌ **"Parallelism always helps"** → Only if truly independent operations

---

## Optimization ROI

| Optimization | Effort | Impact | ROI |
|---|---|---|---|
| Remove unnecessary node | 5 min | 5-10% | Excellent |
| Optimize Code logic | 30 min | 20-40% | Excellent |
| Add caching | 45 min | 30-80% | Great |
| Batch API requests | 60 min | 50-90% | Great |
| Redesign workflow | 3+ hours | 70%+ | Good |

---

## Pro Tips

✅ Profile before optimizing - Data-driven decisions
✅ Optimize expensive operations first - Biggest impact
✅ Test after optimization - Ensure correct results
✅ Document changes - Track what worked
✅ Monitor over time - Catch degradation early
✅ User perspective - 1-2s feels fast, >5s feels slow
