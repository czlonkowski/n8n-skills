---
name: n8n-workflow-debugging
description: Expert guide for debugging and diagnosing n8n workflow failures. Use when workflows fail, behave unexpectedly, have intermittent errors, need performance analysis, or require root cause identification. Provides execution analysis, error pattern recognition, and systematic diagnostics.
---

# n8n Workflow Debugging

Master guide for systematically diagnosing and fixing n8n workflow problems.

---

## Overview

Debugging n8n workflows requires a **systematic approach**, not guesswork. This skill teaches how to:

- 🔍 **Analyze Executions** - Compare failed vs successful runs
- 📊 **Identify Patterns** - Recognize error types and trends
- 🎯 **Root Cause Analysis** - Find the actual problem, not symptoms
- ⚡ **Quick Fixes** - Apply evidence-based solutions
- 🛡️ **Prevention** - Build debugging checkpoints into workflows

---

## The Debugging Framework

### Phase 1: Establish Context (2-3 minutes)

**Gather Information**:
```
1. Workflow ID and name
2. Last execution timestamp
3. Execution IDs of failures
4. Recent changes to workflow
5. Connected service status
```

**Use MCP Tools**:
- `mcp__n8n-mcp__n8n_get_execution` - Get detailed execution data
- `mcp__n8n-mcp__n8n_list_executions` - See execution history pattern
- `mcp__n8n-mcp__validate_workflow` - Check current workflow validity

### Phase 2: Execution Analysis (3-5 minutes)

**Compare Failed vs Successful Runs**:
```javascript
// Use execution data to:
1. Identify which node failed
2. What data it received
3. What error it threw
4. Where execution stopped
```

**Look for Patterns**:
- Consistent failure at same node? → Node configuration issue
- Intermittent failures? → External service timeout
- Failure after data change? → Data format issue
- Slow execution? → Node selection or processing

### Phase 3: Configuration Deep Dive (5-10 minutes)

**Examine Problematic Node**:
```
1. Get node info: get_node({nodeType})
2. Review current configuration
3. Check property dependencies
4. Validate against profile
5. Compare with template examples
```

**Key Questions**:
- Are all required fields filled?
- Are field values correct type/format?
- Do dependencies match (e.g., sendBody → contentType)?
- Is authentication valid?

### Phase 4: Root Cause Identification

**Categorize the Error**:

| Category | Signs | Solution |
|----------|-------|----------|
| **Authentication** | 401, 403, "Unauthorized" | Check credentials, tokens, API keys |
| **Data Format** | "Cannot read property", type mismatch | Validate data structure, use Code node |
| **Configuration** | "Missing required field", validation error | Check node config, property dependencies |
| **External Service** | Timeout, connection error, rate limit | Check service status, add retry logic |
| **Expression Syntax** | "Invalid expression", unexpected values | Review {{}} syntax, test in isolation |
| **Logic Error** | Wrong output, missing data | Check conditions, loop iterations |

---

## Guide References

- [EXECUTION_ANALYSIS.md](EXECUTION_ANALYSIS.md) - Deep execution tracing techniques
- [ERROR_CATALOG.md](ERROR_CATALOG.md) - Common errors and solutions
- [PERFORMANCE_ANALYSIS.md](PERFORMANCE_ANALYSIS.md) - Speed and bottleneck detection

---

## Quick Diagnostic Checklist

### For Any Failing Workflow

**Step 1: Isolate the Failure** (1 min)
```
□ Get recent failed execution ID
□ Identify failing node name
□ Check what data it received
□ Note the exact error message
```

**Step 2: Check the Obvious** (2 min)
```
□ Is the node properly configured?
□ Are all required fields filled?
□ Is authentication/API key valid?
□ Are field values correct type?
```

**Step 3: Check Dependencies** (3 min)
```
□ Do upstream nodes produce expected output?
□ Are field dependencies satisfied?
□ Does input data match expectations?
□ Are conditions evaluated correctly?
```

**Step 4: Validate & Compare** (5 min)
```
□ Validate node configuration
□ Compare with working templates
□ Check n8n documentation for node
□ Review expression syntax if used
```

**Step 5: Apply Fix** (varies)
```
□ Based on diagnosis, apply targeted fix
□ Use partial update, validate
□ Test with fresh execution
□ Monitor for recurrence
```

---

## Debugging Patterns

### Pattern 1: Consistent Node Failure

**Signs**: Same node fails every time

**Diagnosis**:
```javascript
// Node is misconfigured
1. get_node({nodeType: "nodes-base.slack"})
2. Review current config
3. Check property dependencies
4. Validate against "ai-friendly" profile
```

**Solution**:
- Fix configuration
- Update node with corrected values
- Validate before testing

### Pattern 2: Intermittent Failures

**Signs**: Node fails sometimes, succeeds other times

**Diagnosis**:
```javascript
// External service issue
1. Get 5-10 executions
2. Compare success/failure patterns
3. Check timing, data volume
4. Note any error messages about timeouts/limits
```

**Solution**:
- Add retry logic (3x with exponential backoff)
- Add circuit breaker
- Check service rate limits
- Add error handling with fallback

### Pattern 3: Data Format Mismatch

**Signs**: "Cannot read property X", unexpected type errors

**Diagnosis**:
```javascript
// Data structure doesn't match expectations
1. Use Code node to inspect: console.log(JSON.stringify(input))
2. Compare with expected structure
3. Check upstream nodes' output format
4. Validate mapping expressions
```

**Solution**:
- Use Code node to transform data
- Use Set node with proper mapping
- Update expressions to handle actual structure
- Add validation Code node early in workflow

### Pattern 4: Authentication Issues

**Signs**: 401, 403, "Unauthorized", "Invalid credentials"

**Diagnosis**:
```javascript
// Auth problem
1. Check if credential is still valid
2. Verify API key/token hasn't expired
3. Check scope/permissions
4. Test credential manually if possible
```

**Solution**:
- Refresh API key or token
- Update credentials in n8n
- Verify scope includes required permissions
- Check service documentation for auth format

### Pattern 5: Performance Degradation

**Signs**: Workflow runs slower than before

**Diagnosis**:
```javascript
// Performance issue
1. Get recent executions
2. Compare execution time trend
3. Identify which node(s) are slow
4. Check data volume at each stage
```

**Solution**:
- Replace slow node with faster alternative
- Add filters to reduce data volume early
- Use batch processing for large datasets
- Optimize expressions or Code logic

---

## Error Pattern Recognition

### Top 5 Error Categories (Cover 62% of Issues)

**1. Missing/Invalid Required Field** (28%)
```
Error: "Missing required field: X"
Solution: Check node config, fill required fields
Time to fix: <2 min
```

**2. Authentication/Credential** (18%)
```
Error: "401 Unauthorized", "Invalid token", "Access denied"
Solution: Update credentials, check permissions
Time to fix: 2-5 min
```

**3. Data Type/Format** (12%)
```
Error: "Cannot read property", "expected X got Y"
Solution: Transform data with Code node, validate structure
Time to fix: 5-10 min
```

**4. Expression Syntax** (2%)
```
Error: "Invalid expression", "SyntaxError"
Solution: Review {{}} syntax, test in isolation
Time to fix: 2-5 min
```

**5. External Service** (2%)
```
Error: "timeout", "connection refused", "ECONNRESET"
Solution: Add retry logic, check service status
Time to fix: 5-15 min
```

---

## When to Escalate

**Stop Debugging and Ask for Help If**:
- You've spent >30 minutes without progress
- External service is down (not your code)
- Need vendor support for API issue
- Workflow design needs architectural changes
- Multiple systems need reconfiguration

**In These Cases**:
1. Document what you've tried
2. Save execution IDs and errors
3. Prepare workflow export
4. Consult n8n documentation or community

---

## Debugging Tools from MCP

### Essential Tools

**Execution Analysis**:
- `mcp__n8n-mcp__n8n_get_execution` - Single execution details
- `mcp__n8n-mcp__n8n_list_executions` - Execution history
- `mcp__n8n-mcp__validate_workflow` - Full workflow validation

**Node Investigation**:
- `mcp__n8n-mcp__get_node` - Node configuration help
- `mcp__n8n-mcp__validate_node` - Node config validation
- `mcp__n8n-mcp__search_nodes` - Find alternative nodes

**Workflow Management**:
- `mcp__n8n-mcp__n8n_update_partial_workflow` - Apply fixes
- `mcp__n8n-mcp__n8n_autofix_workflow` - Auto-fix common issues

---

## Integration with Other Skills

**Use Together With**:
- **n8n Validation Expert** - For validation errors
- **n8n Node Configuration** - For config issues
- **n8n Code JavaScript/Python** - For Code node debugging
- **n8n Workflow Patterns** - For architectural issues
- **n8n MCP Tools Expert** - For tool usage issues

---

## Pro Tips

✅ **Always Have Pinned Data** - For test executions without live data
✅ **Add Validation Checkpoints** - After 3-5 nodes
✅ **Use Code Nodes for Inspection** - console.log is your friend
✅ **Compare with Templates** - Similar workflows already work
✅ **Document Your Fixes** - Build internal knowledge base
✅ **Monitor Executions** - Catch issues early
✅ **Keep Error Logs** - Pattern analysis over time

---

## Common Success Patterns

**Fast Fixes (<2 min)**:
- Missing required field
- Wrong field value
- Simple expression typo

**Medium Fixes (5-15 min)**:
- Data format mismatch
- Auth credential issue
- Expression complexity

**Complex Fixes (15-60 min)**:
- External service integration
- Performance optimization
- Architectural redesign

---

## Conclusion

Effective debugging is **systematic investigation**, not random fixes. Follow the framework:
1. **Context** - Understand the situation
2. **Analysis** - Find patterns
3. **Deep Dive** - Examine configuration
4. **Root Cause** - Identify actual problem
5. **Fix & Validate** - Apply solution safely

Most issues fall into predictable categories with known solutions. When in doubt, check the error catalog and follow the checklist.

**Happy debugging!** 🔍
