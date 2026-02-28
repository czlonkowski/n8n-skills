---
name: n8n-performance-optimization
description: Master techniques for optimizing n8n workflow performance. Use when workflows are slow, need faster execution, scaling to large datasets, reducing costs, or improving user experience. Covers bottleneck detection, optimization strategies, and benchmarking.
---

# n8n Performance Optimization

Techniques for building fast, efficient, and scalable n8n workflows.

---

## Performance Optimization Framework

### Phase 1: Measure (Baseline)
Get actual metrics:
```javascript
// Get 10 successful executions
n8n_list_executions({workflowId, limit: 10})

// Calculate metrics:
avgTime = sum of all / count
slowest = max
fastest = min
```

### Phase 2: Identify Bottlenecks
```javascript
// Find slowest nodes:
nodes_by_time = sort all nodes by execution time
top5_slowest = slowest 5 nodes

// Calculate impact:
% of total = (slowest_node_time / total_time) * 100
```

### Phase 3: Optimize High-Impact Areas
```
Rule: Optimize slowest 20% first
- 80% of performance comes from 20% of nodes
- Focus on high-impact optimizations
- Quick wins before complex changes
```

### Phase 4: Measure Again
Verify improvement: `(old_time - new_time) / old_time * 100` = % improvement

---

## Optimization Patterns

### Pattern 1: Reduce HTTP Requests

**Bottleneck**: HTTP nodes are 60%+ of execution time

**Solutions**:

**1a: Batch API Calls**
```
Before: 100 items → 100 API calls (100 × 1s = 100s)
After:  Batch endpoint with 100 items (1 × 2s = 2s)
Result: 50x faster! ✅
```

**1b: Add Caching**
```
Before: Every execution → HTTP call
After:  Check cache first:
  - Cache hit (90%): 10ms ✅
  - Cache miss (10%): HTTP call
Result: 90% of requests sub-100ms ✅
```

**1c: Parallelize Requests**
```
Before: Request A → Request B → Request C (sequential = 3s)
After:  All 3 in parallel (parallel = 1s)
Result: 3x faster ✅
```

### Pattern 2: Optimize Data Volume

**Bottleneck**: Processing large datasets

**Solutions**:

**2a: Filter Early**
```
Before: Fetch 10,000 → Process all → Filter to 100
After:  Filter query → Fetch only 100
Result: 100x less data to process ✅
```

**2b: Pagination**
```
Before: Load all 10,000 at once (memory spike)
After:  Load 100 at a time (constant memory)
Result: Memory efficient, can process billions ✅
```

**2c: Sampling**
```
Before: Process all 100,000 items
After:  Sample 1,000 (1%) for analysis
Result: 100x faster, still representative ✅
```

### Pattern 3: Optimize Code Logic

**Bottleneck**: Complex Code nodes (>1s)

**Solutions**:

**3a: Better Algorithm**
```javascript
// SLOW: O(n²) = nested loops
const result = [];
for (const item of items) {  // 1000 iterations
  for (const other of items) {  // 1000 iterations each = 1M total
    if (item.id === other.id) result.push(item);
  }
}

// FAST: O(n) = single pass with map
const result = Array.from(
  new Map(items.map(item => [item.id, item])).values()
);
// 1000 iterations vs 1M = 1000x faster ✅
```

**3b: Reduce Processing**
```javascript
// Use built-in functions instead of loops
// Array.filter() is faster than manual loop
// Array.map() is faster than forEach with manual push
```

**3c: Use Simpler Nodes**
```
Code node: 500ms for simple mapping
Set node: 50ms for same result
Result: 10x faster by using right tool ✅
```

### Pattern 4: Optimize Node Selection

**Bottleneck**: Using wrong node type

**Solution**:

Replace heavy nodes with faster alternatives:
```
HTTP Request + Parser → 500ms
REST API node → 100ms (built-in, optimized)

Code node (JavaScript) → 200ms
Set node (simple mapping) → 20ms

Each saves 10-100ms = significant at scale
```

### Pattern 5: Parallel Processing

**Bottleneck**: Sequential processing of items

**Solution**:
```
Before: Item 1 → Process → Item 2 → Process (1s each = 100s)
After:  All 100 in parallel (1s total)
Result: 100x faster ✅
```

**Implementation**:
```javascript
// In Code node - prepare parallel work
const batch1 = items.slice(0, 50);  // Process in parallel
const batch2 = items.slice(50, 100);

return [
  {json: {batch: batch1}},
  {json: {batch: batch2}}
];

// Merge node merges results after parallel processing
```

---

## Quick Wins (Easy, High Impact)

Implement these first:

| Optimization | Time | Impact | Difficulty |
|---|---|---|---|
| Remove unused nodes | 2 min | 5-10% | ⭐ |
| Filter early | 5 min | 20-50% | ⭐ |
| Replace node type | 5 min | 20-80% | ⭐⭐ |
| Add caching | 15 min | 30-90% | ⭐⭐ |
| Batch requests | 20 min | 50-95% | ⭐⭐ |
| Parallelize | 30 min | 50-90% | ⭐⭐⭐ |
| Optimize code | 45 min | 20-60% | ⭐⭐⭐ |
| Pagination | 60 min | 60-95% | ⭐⭐⭐ |

---

## Benchmarking

### What to Measure

```javascript
// Single execution metrics
executionTime = stopTime - startTime
nodeTime = {node: time_in_ms, ...}
memoryUsage = peak_memory_during_execution

// Aggregate metrics
avgTime = average of 10 runs
p95Time = 95th percentile (for SLA)
p99Time = 99th percentile (worst case)
errorRate = failures / total
```

### Benchmarking Code

```javascript
// Time a section
const start = Date.now();
// ... code to benchmark ...
const elapsed = Date.now() - start;

console.log(`Operation took ${elapsed}ms`);

// Repeat and calculate stats:
const times = [245, 247, 243, 256, 249, ...];
const avg = times.reduce((a,b) => a+b) / times.length;
const sorted = times.sort((a,b) => a-b);
const p95 = sorted[Math.floor(sorted.length * 0.95)];
```

---

## Cost Optimization

### Reduce Execution Costs

n8n charges per execution. Optimize:

```javascript
// Before: 1000 executions/day × $0.01 = $10/day
// After: 100 executions/day × $0.01 = $1/day
// Save: 90% cost reduction ✅

// How to reduce executions:
1. Batch process (1000 items = 1 execution vs 1000)
2. Only trigger when needed (conditions)
3. Cache results (skip re-execution)
4. Scheduled (once/hour vs trigger each)
```

---

## Scaling Workflows

### For Large Datasets

```
Small: <1,000 items → Simple workflow
Medium: 1,000-100,000 → Add pagination/batching
Large: >100,000 → Split into multiple workflows or async processing

Example:
1,000,000 items
├─ Workflow 1: Items 1-100,000
├─ Workflow 2: Items 100,001-200,000
├─ Workflow 3: Items 200,001-300,000
... (scheduled to run in sequence)
└─ Workflow Final: Merge all results
```

---

## Anti-Patterns

❌ **No baseline** - Optimizing blindly
→ **Fix**: Always measure first

❌ **Premature optimization** - Optimizing slow parts
→ **Fix**: Optimize high-impact areas (80/20 rule)

❌ **Ignoring algorithm** - Just throwing more resources
→ **Fix**: Better algorithm beats more CPU

❌ **Caching stale data** - Cached data never refreshes
→ **Fix**: Add cache invalidation

❌ **Over-parallelization** - Parallelizing everything
→ **Fix**: Parallel only for independent operations

---

## Integration

Works with:
- **n8n Workflow Debugging** - Identifies slow nodes
- **n8n Advanced Patterns** - Implements optimized patterns
- **n8n Code JavaScript** - Optimizes code logic

---

## Pro Tips

✅ Always baseline before optimizing
✅ Focus on high-impact areas (80/20)
✅ Test optimization with real data
✅ Monitor performance over time
✅ Document what you optimized and why
✅ Trade-offs: Speed vs Simplicity vs Cost

See [OPTIMIZATION_STRATEGIES.md](OPTIMIZATION_STRATEGIES.md) and [BENCHMARKING_GUIDE.md](BENCHMARKING_GUIDE.md).
