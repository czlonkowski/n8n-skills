---
name: n8n-webhook-advanced
description: Expert guide for production webhook security, validation, and reliability. Use when building webhook integrations, securing endpoints, rate limiting, request validation, or debugging webhook issues. Covers security best practices, payload validation, and webhook hardening.
---

# n8n Webhook Advanced

Production-hardened webhook implementation and security guide.

---

## Webhook Security Fundamentals

### 1. Webhook Authentication

**Pattern: HMAC Signature Verification**
```
Provider sends: Data + Signature (HMAC-SHA256)
n8n verifies: Calculate HMAC of received data
              Compare with provided signature
              ├─ Match → Authentic ✅
              └─ No match → Reject ❌
```

**Implementation**:
```javascript
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
  const hash = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(hash),
    Buffer.from(signature)
  );
}

// In webhook node:
// 1. Extract signature from header
// 2. Get payload body
// 3. Verify with secret
// 4. If invalid → Return 401 and stop
```

**Provider Examples**:
- GitHub: `X-Hub-Signature-256`
- Stripe: `X-Stripe-Signature`
- Slack: `X-Slack-Request-Timestamp` + `X-Slack-Signature`

### 2. Bearer Token Authentication

```javascript
// Request header: Authorization: Bearer <token>

// Verify in webhook:
const token = $json.headers['authorization']?.split(' ')[1];
if (token !== process.env.WEBHOOK_SECRET) {
  return [{json: {error: "Unauthorized"}, status: 401}];
}
```

### 3. API Key Authentication

```javascript
// Request header: X-API-Key: <key>

const apiKey = $json.headers['x-api-key'];
if (apiKey !== process.env.API_KEY) {
  return [{json: {error: "Forbidden"}, status: 403}];
}
```

---

## Request Validation

### 1. Payload Schema Validation

```javascript
// Define expected schema
const schema = {
  event: {required: true, type: 'string'},
  data: {required: true, type: 'object'},
  timestamp: {required: true, type: 'number'}
};

// Validate
for (const [field, rules] of Object.entries(schema)) {
  if (rules.required && !payload[field]) {
    return [{
      json: {error: `Missing required field: ${field}`},
      status: 400
    }];
  }
  if (payload[field] && typeof payload[field] !== rules.type) {
    return [{
      json: {error: `Invalid type for ${field}`},
      status: 400
    }];
  }
}
```

### 2. Data Sanitization

```javascript
// Remove sensitive data that shouldn't be logged
function sanitize(data) {
  const sensitive = ['password', 'token', 'secret', 'api_key'];

  for (const [key, value] of Object.entries(data)) {
    if (sensitive.some(s => key.includes(s))) {
      data[key] = '***REDACTED***';
    }
  }

  return data;
}
```

### 3. Rate Limiting

**Pattern: Token Bucket**
```javascript
// Track requests per sender
const bucket = {
  [sender]: {
    tokens: 100,        // Current tokens
    lastRefill: now()
  }
};

// Consume token for each request
if (bucket[sender].tokens <= 0) {
  return [{json: {error: "Rate limited"}, status: 429}];
}
bucket[sender].tokens--;

// Refill over time (1 token per second)
const timePassed = (now() - lastRefill) / 1000;
bucket[sender].tokens = Math.min(100, bucket[sender].tokens + timePassed);
bucket[sender].lastRefill = now();
```

### 4. Request Size Limits

```javascript
// Prevent large payload attacks
const maxSize = 1024 * 100;  // 100KB

if (contentLength > maxSize) {
  return [{
    json: {error: "Payload too large"},
    status: 413
  }];
}
```

---

## Webhook Reliability

### 1. Idempotency

**Problem**: Webhook delivered twice → Duplicate processing

**Solution**: Idempotency key
```javascript
// Provider sends unique ID per event: X-Idempotency-Key: abc123
const key = $json.headers['x-idempotency-key'];

// Check if already processed
const existing = await database.findOne('processed', {id: key});
if (existing) {
  return [{json: {processed: true, id: key}}];  // 200 OK
}

// Process new event
await processEvent(data);
await database.insert('processed', {id: key, data});
return [{json: {processed: true, id: key}}];
```

### 2. Deduplication

```javascript
// If same event received multiple times
const eventHash = hash(JSON.stringify(event));

const isDuplicate = await database.findOne('events', {hash: eventHash});
if (isDuplicate) {
  return [{json: {status: "duplicate"}}];
}

// Process event
await processEvent(event);
await database.insert('events', {hash: eventHash, data: event});
```

### 3. Webhook Acknowledgment

```javascript
// Return 200 immediately, process async
setTimeout(async () => {
  try {
    await processEvent(data);
  } catch (err) {
    console.error('Processing failed:', err);
    // Add to retry queue
    await database.insert('failed_webhooks', {data, error: err});
  }
}, 0);

// Return immediately so provider knows we received it
return [{json: {received: true}, status: 200}];
```

### 4. Webhook Retry Handling

```javascript
// Provider might retry on 5xx errors
// Only return 5xx for temporary issues

try {
  // Process webhook
  await processEvent(data);
  return [{json: {success: true}, status: 200}];
} catch (err) {
  if (isTemporary(err)) {
    // Temporary issue → 503 (provider will retry)
    return [{json: {error: err.message}, status: 503}];
  } else {
    // Permanent issue → 400 (provider won't retry)
    return [{json: {error: err.message}, status: 400}];
  }
}
```

---

## Webhook Debugging

### 1. Logging Strategy

```javascript
// Log structured data for debugging
const log = {
  timestamp: new Date().toISOString(),
  webhookId: event.id,
  eventType: event.type,
  sender: $json.headers['x-sender-id'],
  success: true,
  duration: endTime - startTime
};

if (error) {
  log.success = false;
  log.error = error.message;
  log.stack = error.stack;
}

await database.insert('webhook_logs', log);
```

### 2. Webhook Testing

```javascript
// Simulate webhook in test environment
const testPayload = {
  event: "order.created",
  data: {id: "123", amount: 100},
  timestamp: Date.now()
};

const response = await fetch('https://webhook.url', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Signature': calculateSignature(testPayload)
  },
  body: JSON.stringify(testPayload)
});

console.log('Response:', response.status, response.body);
```

### 3. Replay Capability

```javascript
// Store webhooks to enable replaying
await database.insert('webhook_archive', {
  id: uuid(),
  timestamp: now(),
  headers: headers,
  body: body,
  response: response
});

// Replay endpoint:
// POST /admin/replay/{id}
// Takes stored webhook, re-processes it
```

---

## Common Webhook Issues

### Issue 1: Webhook Not Triggered

**Checklist**:
- ✅ Webhook URL is correct
- ✅ Webhook is activated (toggle ON)
- ✅ Event type matches (e.g., "order.created")
- ✅ Provider has permission to call webhook
- ✅ Firewall allows provider IP

### Issue 2: Signature Verification Failing

**Debug**:
```javascript
// Log what we're verifying
console.log('Secret:', secret);
console.log('Payload:', JSON.stringify(payload));
console.log('Provided signature:', providedSignature);
console.log('Calculated signature:', calculatedSignature);
```

**Common mistakes**:
- ❌ Wrong secret (copy-paste error)
- ❌ Payload modified (extra spaces, order change)
- ❌ Wrong algorithm (SHA1 vs SHA256)
- ❌ Wrong encoding (base64 vs hex)

### Issue 3: Duplicate Processing

**Solution**: Idempotency key (see above)

### Issue 4: Timeout on Slow Processing

**Solution**: Return 200 immediately, process async

---

## Security Checklist

- ✅ **Verify signatures** for all webhooks
- ✅ **Validate input** - Check schema and types
- ✅ **Rate limit** - Prevent abuse
- ✅ **Size limit** - Prevent memory attacks
- ✅ **Log everything** - For debugging and audits
- ✅ **Handle errors** - Don't expose internals
- ✅ **Use HTTPS** - Always
- ✅ **Sanitize data** - Don't log secrets
- ✅ **Implement idempotency** - Handle duplicates
- ✅ **Monitor health** - Alert on failures

---

## Production Patterns

### Pattern: Webhook with Queue

```
Webhook → Validate → Enqueue → Return 200
          ↓
       [Async Worker]
       └─ Process from queue
```

### Pattern: Webhook with Circuit Breaker

```
Webhook → Validate → Check Circuit → [Open?]
          ├─ No → Process
          └─ Yes → Return 503 (provider retries)
```

### Pattern: Webhook with Dead Letter Queue

```
Webhook → Process → [Success?]
                    ├─ Yes → Done
                    └─ No → DLQ → Manual Review
```

---

## Integration

Works with:
- **n8n Advanced Patterns** - Error handling, retries
- **n8n Workflow Debugging** - Debug webhook issues
- **n8n Code JavaScript** - Validation logic

---

See [SECURITY_HARDENING.md](SECURITY_HARDENING.md) and [WEBHOOK_TESTING.md](WEBHOOK_TESTING.md).
