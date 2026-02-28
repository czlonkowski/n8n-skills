# Error Handling Patterns

Comprehensive guide to building resilient n8n workflows with error recovery.

---

## Pattern 1: Try-Catch with Fallback

### Basic Structure
```
HTTP Request → [Continues normally on success]
     ↓
   [Error?] → Execute Fallback → Merge → Continue
```

### Implementation in n8n

**Step 1**: Use IF node after HTTP Request
- Condition: `{{$json.error}}`
- True branch: Fallback flow
- False branch: Continue normal

**Step 2**: Fallback branch
- Log the error
- Execute fallback action (use cached data, default value)
- Return formatted result

**Step 3**: Merge branches
- Combine both branches
- Merge node with "Append"
- Continue downstream processing

### Example Code

```javascript
// After HTTP Request - Set node to handle error
{
  "result": "{{$json.data || {default: 'cached_data'}}}"
}

// Or in Code node:
if ($input.first().json.error) {
  return [{
    json: {
      data: {id: 0, name: 'Default'},
      fromCache: true
    }
  }];
} else {
  return [{
    json: $input.first().json
  }];
}
```

---

## Pattern 2: Retry Logic with Exponential Backoff

### Structure
```
Attempt 1: HTTP Request → [Success?] → Continue
             ↓ (Fail)
Attempt 2: Wait 1s → HTTP Request → [Success?] → Continue
             ↓ (Fail)
Attempt 3: Wait 2s → HTTP Request → [Success?] → Continue
             ↓ (Fail)
Attempt 4: Wait 4s → HTTP Request → [Success?] → Continue
             ↓ (Fail)
Max retries reached → Send Alert → Stop
```

### Implementation

**Option 1: Simple Retry (Built-in)**
- HTTP Request node → Settings
- Enable "Retry on Fail"
- Set retries: 3
- Backoff: Exponential

**Option 2: Code-Based Retry**
```javascript
let attempts = 0;
const maxAttempts = 4;
const backoffs = [0, 1000, 2000, 4000];

while (attempts < maxAttempts) {
  try {
    // Make request
    const response = await fetch(url);
    if (response.ok) return response.json();
  } catch (err) {
    attempts++;
    if (attempts < maxAttempts) {
      await sleep(backoffs[attempts]);
    }
  }
}
throw new Error('Max retries exceeded');
```

---

## Pattern 3: Circuit Breaker

### Concept
Stop calling failing service, return fallback immediately.

### Structure
```
Is service in Circuit Breaker state?
├─ Yes → Return cached/default immediately
└─ No → Try request
        ├─ Success → Record success
        └─ Fail → Increment failure count
                 ├─ >3 fails? → Enable Circuit Breaker
                 └─ Retry
```

### Implementation
```javascript
// In Code node - Check circuit state
const circuitState = await getFromDatabase('circuit_breaker_state');

if (circuitState.isOpen && !circuitState.shouldRetry()) {
  return [{json: {cached: true, data: circuitState.lastGoodValue}}];
}

// If can try, attempt request
try {
  const response = await makeRequest();
  await recordSuccess();  // Reset failure count
  return [{json: response}];
} catch (err) {
  const failures = await incrementFailureCount();
  if (failures > 3) {
    await openCircuitBreaker();  // Disable further requests
  }
  throw err;
}
```

---

## Pattern 4: Deadline/Timeout Handling

### Problem
Workflow waits forever for slow service.

### Solution
```
Start Timer → Make Request
    ↓
[Timeout?] ├─ Yes → Cancel request → Return fallback
           └─ No → Wait for response → Continue
```

### Implementation
```javascript
// In Code node
const timeout = 5000;  // 5 seconds
const controller = new AbortController();

const timeoutId = setTimeout(() => {
  controller.abort();
}, timeout);

try {
  const response = await fetch(url, {
    signal: controller.signal
  });
  clearTimeout(timeoutId);
  return [{json: response}];
} catch (err) {
  if (err.name === 'AbortError') {
    return [{json: {timeout: true, cached: true}}];
  }
  throw err;
}
```

---

## Pattern 5: Dead Letter Queue (DLQ)

### Concept
Failed messages go to queue for later retry/investigation.

### Structure
```
Process Message
    ├─ Success → Continue
    ├─ Transient Error → Retry Queue
    └─ Permanent Error → Dead Letter Queue (DLQ)

DLQ → Manual Review → Fix and Reprocess
```

### Implementation
```javascript
// Determine error type
const error = $input.first().json.error;

if (isTransient(error)) {
  // Put in retry queue
  await database.insert('retry_queue', {
    id: uuid(),
    message: originalMessage,
    retryCount: 0,
    nextRetry: now() + 1000
  });
} else {
  // Put in DLQ for manual handling
  await database.insert('dlq', {
    id: uuid(),
    message: originalMessage,
    error: error,
    timestamp: now()
  });
}

function isTransient(error) {
  return error.includes('timeout') ||
         error.includes('ECONNREFUSED') ||
         error.includes('429');  // Rate limit
}
```

---

## Pattern 6: Graceful Degradation

### Concept
Reduce functionality instead of failing completely.

### Example
```
Goal: Send message via Slack
├─ Try Slack → Success? → Done
├─ Slack failed → Try Email → Success? → Done
├─ Email failed → Try SMS → Success? → Done
└─ SMS failed → Log warning → Continue
```

### Implementation
```javascript
let delivered = false;

// Try in order of preference
const channels = ['slack', 'email', 'sms'];

for (const channel of channels) {
  try {
    await send(channel, message);
    delivered = true;
    break;
  } catch (err) {
    console.log(`${channel} failed: ${err.message}`);
  }
}

if (!delivered) {
  await database.insert('failed_messages', {message});
}

return [{json: {delivered}}];
```

---

## Pattern 7: Bulkhead Pattern

### Concept
Isolate failures - don't let one failing component crash everything.

### Structure
```
Main Workflow
├─ Critical Path (must succeed)
├─ Non-critical: Send Slack (can fail)
├─ Non-critical: Update Analytics (can fail)
└─ Non-critical: Send Webhook (can fail)

If non-critical path fails → Log warning, continue
If critical path fails → Stop workflow
```

### Implementation
```javascript
// Wrap non-critical operations in try-catch
try {
  await sendSlackNotification(message);
} catch (err) {
  // Log but don't stop workflow
  console.error('Slack failed:', err);
}

try {
  await updateAnalytics(data);
} catch (err) {
  console.error('Analytics failed:', err);
}

// Critical operation - let it fail if needed
await saveToDatabase(data);  // No catch - will stop workflow
```

---

## Choosing the Right Pattern

| Scenario | Pattern | Resilience |
|----------|---------|-----------|
| API timeout | Retry + Timeout | ⭐⭐⭐ |
| High failure rate | Circuit Breaker | ⭐⭐⭐⭐ |
| Transient failures | Exponential Backoff | ⭐⭐⭐ |
| Service down | Bulkhead | ⭐⭐ |
| Data loss prevention | Dead Letter Queue | ⭐⭐⭐⭐⭐ |
| Feature graceful fail | Graceful Degradation | ⭐⭐⭐ |
| Single point failure | Fallback | ⭐⭐ |

---

## Best Practices

✅ **Log all errors** - For debugging and monitoring
✅ **Distinguish error types** - Transient vs permanent
✅ **Set reasonable timeouts** - Not too short, not too long
✅ **Monitor failure rates** - Detect patterns
✅ **Test error paths** - Use pinned data with failures
✅ **Document decisions** - Why this pattern for this component
✅ **Avoid infinite loops** - Always have max attempts
✅ **Alert on cascading failures** - Multiple errors = bigger problem

---

## Real-World Example

**Slack Notification Workflow with Error Handling**

```javascript
// 1. Try to send via primary channel
// 2. If fails, retry 2x with backoff
// 3. If still fails, try secondary channel (email)
// 4. If that fails, log to DLQ
// 5. Always log attempt for monitoring

const result = {
  attempted: true,
  delivered: false,
  errors: []
};

// Try Slack with retry
for (let i = 0; i < 3; i++) {
  try {
    await slack.send(message);
    result.delivered = true;
    return [{json: result}];
  } catch (err) {
    result.errors.push(`Slack attempt ${i+1}: ${err}`);
    if (i < 2) await sleep(Math.pow(2, i) * 1000);
  }
}

// Try Email fallback
try {
  await email.send(message);
  result.delivered = true;
  return [{json: result}];
} catch (err) {
  result.errors.push(`Email: ${err}`);
}

// Failed to deliver anywhere
await database.insert('dlq', {message, errors: result.errors});
await logger.warn('Message failed to deliver', result);

return [{json: result}];
```

---

## Monitoring & Alerting

Set up alerts for:
- ⚠️ Retry rate > 10%
- ⚠️ Error rate > 5%
- ⚠️ Circuit breaker opened
- ⚠️ DLQ growing (messages failing)
- ⚠️ Timeout frequency increasing
