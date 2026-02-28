# Advanced Orchestration Guide

Master complex multi-step workflow orchestration.

---

## Pattern: Multi-Stage Pipeline with Validation

### Concept
Each stage validates before proceeding to next stage.

```
Input → Stage 1 → Validate ✓ → Stage 2 → Validate ✓ → Stage 3 → Output
            ↓                        ↓                      ↓
        [Error] → Log & Fail    [Error] → Log & Fail    [Error] → Log & Fail
```

### Example: User Onboarding

```
1. Validate Email
   Input: {email, name}
   Output: Valid email? Yes/No

2. Check Duplicates
   Query: Does user exist?
   Output: Duplicate? Yes/No

3. Create Account
   Action: Create user
   Output: User created? Yes/No

4. Send Welcome
   Action: Send email
   Output: Sent? Yes/No

5. Return Result
   Output: Success or detailed error
```

### Implementation Code

```javascript
// Validation node output format
{
  "isValid": true,
  "stage": "email_validation",
  "data": {...}  // Pass data to next stage
}

// Error handling node
{
  "error": true,
  "stage": "duplicate_check",
  "reason": "User already exists",
  "data": {...}  // Original data for debugging
}
```

---

## Pattern: Parallel Branches with Merge

### Concept
Process multiple independent streams, merge results.

```
Input → [Split Data]
        ├─ Branch A: Get User Details
        ├─ Branch B: Get User Stats
        ├─ Branch C: Get Recent Orders
        └─ [Merge] → Combine All Data → Output
```

### Implementation

**Step 1: Split**
```javascript
// In Code node - prepare data for parallel processing
const branchA = {task: 'getUser', id: userId};
const branchB = {task: 'getStats', id: userId};
const branchC = {task: 'getOrders', id: userId};

return [
  {json: branchA},
  {json: branchB},
  {json: branchC}
];
```

**Step 2: Process in Parallel**
Each branch runs independently (faster!)

**Step 3: Merge**
```javascript
// After all branches complete - merge results
const results = $input.all().map(item => item.json);
const merged = {
  user: results[0],
  stats: results[1],
  orders: results[2]
};

return [{json: merged}];
```

---

## Pattern: Fan-Out / Fan-In

### Concept
Send to multiple destinations, wait for all.

```
Process Complete → [Fan-Out]
                   ├─ Send Slack
                   ├─ Send Email
                   ├─ Save Database
                   └─ [Fan-In: Wait all] → Continue
```

### Implementation

```javascript
// Use Merge node with "Wait for All"
// Or in Code node with Promise.all

const promises = [
  sendToSlack(message),
  sendToEmail(message),
  saveToDatabase(data)
];

const results = await Promise.all(promises);
return [{json: {allSent: true, results}}];
```

---

## Pattern: Conditional Workflow with Multiple Paths

### Decision Tree

```
Input → [Type?]
        ├─ "order" → Process Order → Send Confirmation
        ├─ "refund" → Process Refund → Send Refund Confirmation
        ├─ "support" → Create Ticket → Assign Agent
        └─ "other" → Log & Archive
```

### Implementation

Use nested IF nodes or Switch logic:

```javascript
// In IF node conditions
if ($json.type === 'order') {
  // True branch → Process order
} else if ($json.type === 'refund') {
  // Another branch → Process refund
} else {
  // Default branch
}
```

---

## Pattern: State Machine Workflow

### Concept
Workflow progresses through defined states.

```
States: pending → processing → complete → archived

Each transition:
1. Validate current state
2. Execute action
3. Update state
4. Log transition
```

### Implementation

```javascript
// Define states and transitions
const states = {
  pending: {canTransitionTo: ['processing']},
  processing: {canTransitionTo: ['complete', 'failed']},
  complete: {canTransitionTo: ['archived']},
  failed: {canTransitionTo: ['processing']},  // Retry
  archived: {canTransitionTo: []}  // End state
};

// Transition function
async function transitionState(recordId, from, to) {
  // Validate transition is allowed
  if (!states[from].canTransitionTo.includes(to)) {
    throw new Error(`Cannot transition from ${from} to ${to}`);
  }

  // Update state
  await database.update('records', recordId, {state: to});

  // Log transition
  await database.insert('audit_log', {
    recordId,
    from,
    to,
    timestamp: new Date()
  });

  return {success: true, newState: to};
}
```

---

## Pattern: Idempotent Operations

### Problem
What if workflow executes twice? Prevents duplicate actions.

### Solution
Use unique identifier to detect if already processed.

```javascript
// Check if already processed
const idempotencyKey = md5(userId + timestamp + actionType);
const exists = await database.findOne('processed', {key: idempotencyKey});

if (exists) {
  // Already processed - return cached result
  return [{json: {idempotent: true, result: exists.result}}];
}

// Not processed yet - execute action
const result = await processAction();

// Save as processed
await database.insert('processed', {key: idempotencyKey, result});

return [{json: {idempotent: false, result}}];
```

---

## Pattern: Async Job Processing

### Concept
Long-running tasks don't block workflow. Track async job completion.

```
Request → Create Job (return immediately) → Job Runs Async
          JobID returned to caller

Caller polls: Get Job Status → [Complete?] → Return Result
```

### Implementation

```javascript
// Step 1: Create async job
const jobId = uuid();
await database.insert('jobs', {
  id: jobId,
  status: 'pending',
  data: inputData,
  createdAt: now()
});

// Return immediately with job ID
return [{
  json: {
    jobId,
    message: 'Processing started',
    statusUrl: `/jobs/${jobId}`
  }
}];

// Separate workflow: Job Worker
// Polls jobs table, executes, updates status
async function processJob(jobId) {
  const job = await database.findOne('jobs', {id: jobId});

  try {
    const result = await executeJob(job.data);
    await database.update('jobs', jobId, {
      status: 'complete',
      result,
      completedAt: now()
    });
  } catch (err) {
    await database.update('jobs', jobId, {
      status: 'failed',
      error: err.message
    });
  }
}
```

---

## Pattern: Retry with Exponential Backoff (Orchestration)

### Concept
Built into orchestration - each stage can have retry logic.

```
Stage → Attempt 1 → [Success?] → Continue
           ↓ (Fail)
        Wait 1s → Attempt 2 → [Success?] → Continue
           ↓ (Fail)
        Wait 2s → Attempt 3 → [Success?] → Continue
           ↓ (Fail)
        Max retries → Fail stage
```

### Implementation

```javascript
async function executeWithRetry(fn, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxRetries) throw err;

      const delay = Math.pow(2, attempt - 1) * 1000;  // 1s, 2s, 4s
      await sleep(delay);
    }
  }
}

// Usage in workflow
const result = await executeWithRetry(async () => {
  return await httpRequest({
    url: 'https://api.example.com/process',
    method: 'POST',
    body: data
  });
}, 3);
```

---

## Testing Complex Orchestrations

### Pinned Data Strategy

Create pinned data for each scenario:

```javascript
// Scenario 1: Happy path
{
  type: 'order',
  status: 'pending',
  amount: 100,
  success: true
}

// Scenario 2: Error path
{
  type: 'refund',
  status: 'processing',
  amount: 50,
  error: 'payment_api_down'
}

// Scenario 3: Timeout path
{
  type: 'support',
  status: 'pending',
  timeout: true
}
```

Then test each branch independently.

---

## Monitoring Orchestration Health

Track:
- ⏱️ Average stage execution time
- ❌ Error rate per stage
- 🔄 Retry frequency
- 📊 Success rate by path
- 🔌 Critical stage failures

Alert on:
- Any single stage > 50% error rate
- Average execution time increasing
- Critical path failing repeatedly
