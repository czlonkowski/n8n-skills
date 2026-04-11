# Lesson: Intelligence Brief Workflow Fix (2026-02-15)

## What Went Wrong (Hilary's Approach)
Multiple failed attempts to fix a news briefing workflow via API. Key mistakes:

### 1. Merge Node Misuse
**Wrong:** Used Merge v3 `combineAll` with 5+ async inputs (RSS feeds + sequential agent chain)
**Problem:** `combineAll` does a cross-product and doesn't handle async timing. Agents feeding into different Merge inputs at different times = 0 output.

### 2. Wait Nodes Break Activation
**Wrong:** Used Wait v1.1 nodes between agents for sequential execution
**Problem:** Wait nodes require internal webhooks to resume. These webhooks fail to register properly, which **prevents the entire workflow from activating** — including the schedule trigger. This is why triggers never fired.
**Log signature:** `No webhook path could be found for node "Wait: After Edmonton"`

### 3. Schedule Trigger Timezone
**Wrong:** Assumed `triggerAtHour` was UTC
**Reality:** n8n uses the system timezone (`America/Edmonton` / MST) when `GENERIC_TIMEZONE` env var is not set. Hour 21 = 9 PM MST, not 2 PM.

### 4. API PUT Gotchas
- PUT body must contain ONLY: `name`, `nodes`, `connections`, `settings`
- Any extra keys (`versionId`, `active`, `sharedWithProjects`, etc.) → 400 error
- `curl -d` can mangle JSON with special chars — use Python `urllib` instead
- PUT doesn't change `active` state — use `/activate` and `/deactivate` endpoints
- After PUT, must deactivate→reactivate to re-register triggers

## What Murphy/Opus Fixed (Correct Architecture)

### Two Parallel Pipelines, No Merge
```
Trigger (6 AM)
├── Pipeline 1: RSS Feeds (parallel)
│   ├── Al Jazeera ──┐
│   ├── BBC ─────────┤
│   ├── CBC ─────────┼── Aggregate → Code (Format) → Telegram
│   ├── Guardian ────┤
│   ├── NYT ─────────┤
│   └── TechCrunch ──┘
│
└── Pipeline 2: Research Agents (parallel)
    ├── Edmonton Agent ──┐
    ├── Alberta Agent ───┼── Each sends directly to Telegram
    ├── Canada Agent ────┤
    └── AI Agent ────────┘
```

### Key Design Decisions
1. **No Merge nodes at all** — Each agent sends its own Telegram message directly
2. **No Wait nodes** — Agents run in parallel, not sequentially
3. **No sequential chaining** — All 4 agents + all 6 RSS feeds fire simultaneously from the trigger
4. **Aggregate node** for RSS only — collects all RSS items into one array, then Code node formats
5. **Two separate Telegram sends** — RSS headlines go to one message, each agent sends its own intel message
6. **Agent output is `$json.output`** — The langchain agent node puts its response in `.output`, not `.text`

### n8n Patterns Learned
- **Parallel fan-out:** Connect trigger to multiple nodes directly (n8n runs them concurrently)
- **Aggregate + Code:** Better than Merge for combining multiple inputs of same type
- **Direct-to-output:** For AI agents, just pipe `$json.output` straight to Telegram — no need to collect/merge
- **`message_thread_id` as number:** Telegram topic ID should be number `2216`, not string `"2216"`
- **`continueOnFail: true`** on RSS nodes — prevents one broken feed from killing the whole workflow
