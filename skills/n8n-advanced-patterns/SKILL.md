---
name: n8n-advanced-patterns
description: Master advanced n8n workflow patterns for error handling, branching, looping, and orchestration. Use when building enterprise workflows, handling failures gracefully, implementing complex logic, or designing multi-step orchestrations.
---

# n8n Advanced Patterns

Master patterns for building enterprise-grade n8n workflows.

---

## Pattern Categories

### 1. Error Handling & Recovery ([ERROR_HANDLING.md](ERROR_HANDLING.md))

**Pattern: Try-Catch with Fallback**
```
HTTP Request → [Error?] → Execute Fallback → Slack
                ↓ (Success)
              Continue Flow
```

**When**: External API might fail, need graceful degradation
**Result**: Workflow completes even if external service fails

**Pattern: Retry Logic with Exponential Backoff**
```
HTTP Request → [Timeout?] → Wait (1s) → Retry
                             → [Still fail?] → Wait (2s) → Retry
                             → [Still fail?] → Wait (4s) → Retry
                             → [Max retries?] → Send Alert
```

**When**: Transient failures (temporary network issues)
**Result**: Self-healing workflow that recovers from temporary failures

---

### 2. Branching & Conditional Logic

**Pattern: IF-THEN-ELSE Branching**
```
Trigger → Validate → [Status?]
                     ├─ "active" → Process
                     ├─ "pending" → Queue
                     └─ "inactive" → Archive
```

**Implementation**:
- Use IF node with conditions
- Separate branches for each case
- Merge branches at end if needed

**Pattern: Switch/Case for Multiple Options**
```
Input → [Type?] → case "email" → Send Email
                  case "slack" → Send Slack
                  case "sms" → Send SMS
                  default → Log Error
```

**When**: Many branches (>3), each with different logic
**Node**: Use IF or merge multiple conditions

---

### 3. Looping Patterns

**Pattern: For Each Loop**
```
Data Array → [For Each Item]
             ├─ Transform Item
             ├─ Send Request
             └─ Collect Results

Result: Array of transformed items
```

**When**: Process list of items individually
**Node**: Loop node with "For each" mode

**Pattern: While Loop (Pagination)**
```
Initialize (page=1) → Get Results → [More pages?]
                                    ├─ Yes → Increment page → Fetch next
                                    └─ No → Continue
```

**When**: Paginated API, fetch all results
**Implementation**:
- Use Code node to track pagination state
- Loop until no more pages
- Aggregate results

**Pattern: Parallel Processing**
```
Data Array → [Split into parallel branches]
           ├─ Branch 1: Process items 1-25
           ├─ Branch 2: Process items 26-50
           ├─ Branch 3: Process items 51-75
           └─ Merge: Combine results

Result: 3x faster than sequential!
```

---

### 4. Orchestration Patterns

**Pattern: Multi-Step Workflow with Checkpoints**
```
Step 1: Validate Input ✓
Step 2: Fetch Dependencies ✓
Step 3: Process Main Logic ✓
Step 4: Save Results ✓
Step 5: Send Notifications ✓

Each step isolated, can fail independently
```

**When**: Complex workflows with many stages
**Benefit**: Can debug/retry individual stages

**Pattern: Fan-Out / Fan-In**
```
Trigger → Distribute to Multiple Services
         ├─ Service A
         ├─ Service B
         ├─ Service C
         └─ Merge Results → Continue

Parallel execution = faster workflow
```

**When**: Need results from multiple sources
**Implementation**: Merge node with parallel branches

**Pattern: State Machine**
```
State: "pending" → [Do X] → "processing"
State: "processing" → [Do Y] → "complete"
State: "complete" → [Do Z] → "archived"

Track state in database, each transition validates
```

**When**: Workflow with explicit state transitions
**Benefit**: Clear workflow progression, easy to debug

---

### 5. Data Transformation Patterns

**Pattern: Normalization**
```
Input (various formats) → Normalize → Standard format → Process

Example:
├─ "John Doe" → {first: "John", last: "Doe"}
├─ "Jane, Smith" → {first: "Jane", last: "Smith"}
└─ "bob (Robert) wilson" → {first: "Robert", last: "Wilson"}
```

**Pattern: Aggregation**
```
Individual Items → Collect in Array → Batch Process

Example:
├─ User 1: {id: 1, action: "login"}
├─ User 2: {id: 2, action: "logout"}
├─ User 3: {id: 3, action: "login"}
→ Batch Insert All
```

**Pattern: Deduplication**
```
Data with Duplicates → {ID → Item mapping} → Remove Dups → Unique Data

Faster than loop comparison!
```

---

## Quick Reference: When to Use Each Pattern

| Need | Pattern | Node |
|------|---------|------|
| Handle failures | Try-Catch | IF + Merge |
| Retry failed requests | Retry Loop | Wait + Condition |
| Process multiple items | For Each | Loop |
| Paginated API | Pagination Loop | Code + Condition |
| Multiple branches | Branching | IF |
| Parallel work | Fan-Out/In | Merge |
| Track progress | State Machine | Database |
| Process lists | Aggregation | Code |

---

## Anti-Patterns to Avoid

❌ **Deep Nesting**: >3 levels of IF statements
→ **Fix**: Use Switch logic or separate workflows

❌ **Synchronous When Async Needed**: Waiting for all 100 items sequentially
→ **Fix**: Use parallel/batch processing

❌ **No Error Handling**: Workflow fails completely on first error
→ **Fix**: Add try-catch patterns

❌ **Hardcoded Values**: API keys, IDs in workflow
→ **Fix**: Use credentials/variables

❌ **Missing Validation**: No checks on input data
→ **Fix**: Add validation at start of workflow

---

## Integration with Other Skills

- **n8n Workflow Patterns** - Identifies pattern type needed
- **n8n Code JavaScript** - Implements complex logic
- **n8n Validation Expert** - Validates each stage
- **n8n Workflow Debugging** - Debugs failing patterns

---

## Pro Tips

✅ Start simple, add complexity incrementally
✅ Test each pattern independently first
✅ Use pinned data to simulate scenarios
✅ Document pattern choice in workflow notes
✅ Compare with templates for proven implementations
✅ Monitor performance of complex patterns
✅ Keep orchestration logic readable and clear

---

See [ERROR_HANDLING.md](ERROR_HANDLING.md) and [ADVANCED_ORCHESTRATION.md](ADVANCED_ORCHESTRATION.md) for detailed implementations.
