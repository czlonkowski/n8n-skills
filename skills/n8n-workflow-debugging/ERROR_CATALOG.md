# n8n Error Catalog

Comprehensive catalog of common n8n errors with solutions.

---

## Error Categories

### 1. Configuration Errors (28% of issues)

#### Error: "Missing required field"
**Cause**: Node missing mandatory field
**Solution**:
```javascript
// 1. Get node info
get_node({nodeType: "nodes-base.slack", detail: "standard"})

// 2. Check which fields are required
// 3. Update node config with required field
n8n_update_partial_workflow({
  operations: [{
    type: "updateNode",
    nodeId: "slack-1",
    properties: {
      credentials: {...}  // Add missing required field
    }
  }]
})

// 4. Validate
validate_workflow({id: "workflow-id"})
```

#### Error: "Invalid field value"
**Cause**: Field value wrong type or format
**Solution**:
- String field with number → Wrap in quotes
- Number field with string → Parse to number
- Array field with object → Wrap in array
- Date field with string → Use ISO format (YYYY-MM-DD)

#### Error: "Missing credential"
**Cause**: Node references non-existent credential
**Solution**:
```
1. Create credential in n8n UI
2. Get credential ID
3. Update node to reference correct credential
4. Validate
```

---

### 2. Authentication Errors (18% of issues)

#### Error: "401 Unauthorized" / "401 Invalid Credentials"
**Cause**: API key, token, or password wrong
**Solution**:
```
1. Verify API key/token in external service
2. Check if token expired
3. Update credential in n8n
4. Test with simple request
5. Validate workflow
```

**Time to Fix**: 2-5 minutes

#### Error: "403 Forbidden" / "Access Denied"
**Cause**: Credential valid but permissions insufficient
**Solution**:
```
1. Check required scope (OAuth)
2. Verify user role in external system
3. Grant necessary permissions
4. Update credential to include new scopes
5. Re-test
```

**Time to Fix**: 5-15 minutes

#### Error: "EAUTH: Authentication failed"
**Cause**: Invalid or expired OAuth token
**Solution**:
```
1. Re-authenticate (refresh token)
2. Update credential
3. Remove and re-add credential if needed
4. Test connection
```

**Time to Fix**: 2-5 minutes

---

### 3. Data Format Errors (12% of issues)

#### Error: "Cannot read property X of undefined"
**Cause**: Expected data structure doesn't exist
**Solution**:
```javascript
// 1. Inspect actual input data
// Add Code node:
console.log("Actual structure:", JSON.stringify($input.first().json, null, 2));

// 2. Compare with expected
// Expected: {user: {name: "John"}}
// Actual: {userData: {firstName: "John"}}

// 3. Fix mapping in previous node or use Code node to transform
return $input.all().map(item => ({
  json: {
    user: {
      name: item.json.userData.firstName
    }
  }
}));
```

**Time to Fix**: 5-10 minutes

#### Error: "expected string, got number"
**Cause**: Type mismatch in node configuration
**Solution**:
- Check field expectation in node info
- Coerce type if needed: String(value), Number(value)
- Use Code node to transform

#### Error: "Invalid JSON"
**Cause**: Malformed JSON in body or expression
**Solution**:
```javascript
// Check syntax:
JSON.parse(yourString)  // Throws error if invalid

// Common issues:
// ❌ {name: "John"}      // Missing quotes around keys
// ✅ {"name": "John"}    // Correct
// ❌ {"name": 'John'}    // Wrong quote type
// ✅ {"name": "John"}    // Correct
```

---

### 4. Expression Errors (2% of issues)

#### Error: "Invalid expression" / "SyntaxError"
**Cause**: Malformed {{}} expression
**Solution**:
```javascript
// Common mistakes:

// ❌ {{$json}}         (missing property)
// ✅ {{$json.name}}    (correct)

// ❌ {{$node.slack.data}}    (wrong format)
// ✅ {{$node.slack.json}}    (correct - use .json)

// ❌ {{"text": "hello"}}     (string in expression)
// ✅ {{"text": "hello"}}     (correct with escaped quotes)
```

#### Error: "Unexpected token"
**Cause**: Expression syntax error
**Solution**:
- Missing closing }}
- Missing quotes around strings
- Invalid operators
- Undefined variables

Test in isolation first:
```javascript
// Test in Code node:
const result = $json.name || "default";  // Valid expression
return [{json: {result}}];
```

---

### 5. External Service Errors (15% of issues)

#### Error: "ETIMEDOUT" / "timeout"
**Cause**: Service taking too long to respond
**Solution**:
```
1. Check if external service is running
2. Check if service is slow (performance issue)
3. Add retry logic (3x with exponential backoff)
4. Increase timeout setting
5. Add circuit breaker for reliability
```

**Time to Fix**: 10-30 minutes

Example Retry Logic:
```javascript
// Add between HTTP Request and Slack
// Condition node to check if error
// If error → Wait (2s) → Retry HTTP Request
// Repeat 3x before failing
```

#### Error: "ECONNREFUSED" / "Connection refused"
**Cause**: Service not running or firewall blocking
**Solution**:
```
1. Check if service is running
2. Check firewall rules
3. Check port is correct
4. Check network connectivity
5. Check if domain/IP is correct
```

**Time to Fix**: 5-30 minutes

#### Error: "404 Not Found"
**Cause**: Resource doesn't exist at endpoint
**Solution**:
```
1. Verify URL is correct
2. Verify resource ID exists
3. Check endpoint path
4. Test endpoint manually
5. Check API documentation
```

**Time to Fix**: 2-5 minutes

#### Error: "429 Too Many Requests"
**Cause**: Rate limited by external service
**Solution**:
```
1. Add delay between requests (Wait node)
2. Implement batch processing
3. Check rate limits in API docs
4. Request higher limits if possible
5. Add exponential backoff
```

**Time to Fix**: 10-30 minutes

---

### 6. Node-Specific Errors

#### Webhook Node
```
Error: "Webhook failed"
→ Check webhook is activated
→ Verify URL is correct
→ Check request format matches

Error: "Invalid body format"
→ Expected JSON? Make sure Content-Type: application/json
→ Check JSON is valid
```

#### HTTP Request Node
```
Error: "Invalid response"
→ Check response type (JSON/HTML/Text)
→ Check response parser settings
→ Test with curl first

Error: "SSL certificate problem"
→ Check if API uses valid HTTPS
→ May need to disable cert verification (not recommended)
```

#### Database Node
```
Error: "Table not found"
→ Verify table name spelling
→ Check database connection
→ Verify schema if using

Error: "Connection timeout"
→ Check database is accessible
→ Check firewall rules
→ Check connection string
```

#### Slack Node
```
Error: "Channel not found"
→ Verify channel ID is correct
→ Check bot has access to channel
→ Channel name ≠ Channel ID (use ID)

Error: "You can't delete this message"
→ Only can delete messages bot sent
→ Check message ID is correct
```

#### Email Node
```
Error: "Invalid email address"
→ Verify email format: user@domain.com
→ Check for extra spaces

Error: "SMTP error"
→ Verify SMTP server address
→ Check credentials
→ Check port (usually 587 or 465)
```

---

### 7. Workflow Structure Errors

#### Error: "Invalid connections"
**Cause**: Node connections are invalid
**Solution**:
```javascript
validate_workflow({id: "workflow-id"})
// Will identify invalid connections
// Redraw connections using n8n UI
// Re-validate
```

#### Error: "Circular reference"
**Cause**: Nodes create infinite loop
**Solution**:
- Cannot have node A → B → A
- Use Loop node instead for iteration
- Redesign workflow to avoid circles

#### Error: "Unreachable node"
**Cause**: Node never gets executed
**Solution**:
- Check if condition nodes prevent execution
- Check if all branches lead to node
- Add explicit connections if needed
- Test with pinned data

---

### 8. False Positives (Issues That Aren't Real)

#### "Warning: Variable not used"
**Cause**: Set node creates variable but doesn't use it
**Reality**: Harmless, variable is available downstream
**Action**: Ignore unless actually unused

#### "Credential may not be accessible"
**Cause**: Validation can't access credential
**Reality**: Usually false positive, still works
**Action**: Test execution to verify

#### "Complex type not verified"
**Cause**: Can't validate complex types like objects
**Reality**: Validation limitation, not error
**Action**: Verify manually or test execution

---

## Quick Fix Decision Tree

```
Workflow failed?
├── Error message clear?
│   ├── Yes → Look up error in catalog above
│   └── No → Get execution details with n8n_get_execution
│
├── At which node?
│   ├── Webhook/HTTP → Check URL, auth, format
│   ├── Database → Check connection, table, query
│   ├── Slack/Email → Check credentials, format
│   ├── Code → Check syntax, return format
│   └── Other → Check config, required fields
│
├── Check obvious first (2 min)
│   ├── Credentials valid?
│   ├── Required fields filled?
│   ├── Field values correct type?
│   └── Service running?
│
├── Still failing?
│   ├── Compare with successful execution
│   ├── Check data flow through nodes
│   ├── Inspect with Code node + console
│   └── Check templates for similar workflow
│
└── Not fixed in 30 min?
    ├── Document what you've tried
    ├── Save execution IDs and errors
    ├── Check n8n community or docs
    └── Consider architectural redesign
```

---

## Success Rate by Error Type

| Error Type | Detection Rate | Fix Rate | Avg Time |
|-----------|---|---|---|
| Configuration | 95% | 99% | 2 min |
| Authentication | 90% | 95% | 3 min |
| Data Format | 80% | 90% | 7 min |
| External Service | 70% | 80% | 15 min |
| Expression | 85% | 92% | 4 min |
| Logic | 60% | 75% | 20 min |

---

## Prevention Tips

✅ **Always validate after changes**
✅ **Add pinned data for testing**
✅ **Add validation nodes every 3-5 nodes**
✅ **Use Code nodes to inspect data**
✅ **Compare with working templates**
✅ **Test with real data before production**
✅ **Add error handling paths**
✅ **Document what you fix**
