# n8n Workflow Architectures for Wholesale RE

Detailed workflow patterns with node configurations for wholesale real estate automation.

---

## Current System (v2) — 16 Active Workflows

| ID | Name | Purpose | Status |
|----|------|---------|--------|
| WF01 | Podio Webhook Receiver | Catches Podio events | Active |
| WF02 | Lead Form Processor | Website/form lead intake | Active |
| WF03 | Google Sheets Sync | CRM backup to Sheets | Active |
| WF04 | Email Sequence Engine | Automated email drips | Active |
| WF05 | FB Messenger AI Bot | Lily + Adriana on Messenger | Active |
| WF06 | FB Page Bot | Facebook page automation | Active |
| WF07b | Lead Form v2 | Enhanced lead form processing | Active |
| WF08 | 90-Day Drip Campaign | Multi-channel follow-up | Active |
| WF09 | Deal Pipeline Manager | Pipeline stage automation | Active |
| WF10 | System Health Monitor | Workflow health checks | Active |
| EP-11 | SMS Outreach Engine | RingCentral SMS automation | Active |
| EP-12 | Disposition Blaster | Buyer list notifications | Active |
| EP-13 | Comps & MAO Calculator | PropStream data + MAO calc | Active |
| EP-14 | DocuSign Automation | Contract delivery | Active |
| EP-18 | Telegram Notifications | Team alerts via Telegram | Active |
| EP-19 | Carlos SMS Alert | Hot lead SMS to Carlos | Active |

---

## Architecture 1: Lead Intake Pipeline

### Flow

```
[Lead Source] → Webhook → Parse → Deduplicate → Enrich → Score → Route → Notify
```

### Node Configuration

#### Webhook Trigger
```json
{
  "node": "n8n-nodes-base.webhook",
  "parameters": {
    "httpMethod": "POST",
    "path": "lead-intake",
    "authentication": "headerAuth",
    "options": {
      "responseMode": "responseNode"
    }
  }
}
```

#### Parse & Validate (Code Node)
```javascript
const body = $input.first().json.body;

// Validate required fields
const required = ['name', 'phone', 'address'];
const missing = required.filter(f => !body[f]);
if (missing.length) {
  return [{ json: { error: true, missing, message: `Missing: ${missing.join(', ')}` } }];
}

// Normalize phone
const phone = body.phone.replace(/\D/g, '');
const formattedPhone = phone.length === 10 ? '+1' + phone : '+' + phone;

return [{
  json: {
    name: body.name.trim(),
    phone: formattedPhone,
    email: body.email || '',
    address: body.address.trim(),
    source: body.source || 'website',
    received_at: new Date().toISOString()
  }
}];
```

#### Deduplication (Code Node)
```javascript
// Check if lead exists in last 30 days
const lead = $input.first().json;
const existingLeads = $('Google Sheets').all();

const isDuplicate = existingLeads.some(existing => {
  const existingPhone = existing.json.phone?.replace(/\D/g, '');
  const newPhone = lead.phone.replace(/\D/g, '');
  return existingPhone === newPhone;
});

if (isDuplicate) {
  return [{ json: { ...lead, duplicate: true, action: 'skip' } }];
}

return [{ json: { ...lead, duplicate: false, action: 'process' } }];
```

#### Lead Scoring (Code Node)
```javascript
const lead = $input.first().json;
let score = 0;
const signals = [];

// Source quality scoring
const sourceScores = {
  'facebook_ad': 15,
  'google_ppc': 25,
  'website_form': 20,
  'referral': 30,
  'cold_outreach': 5,
  'driving_for_dollars': 20
};
score += sourceScores[lead.source] || 10;

// Engagement scoring
if (lead.phone) { score += 10; signals.push('has_phone'); }
if (lead.email) { score += 5; signals.push('has_email'); }
if (lead.message?.length > 50) { score += 10; signals.push('detailed_message'); }

// Keyword scoring from message
const urgentWords = /\b(asap|urgent|fast|quick|foreclosure|behind|divorce|inherited|relocat|must sell|need to sell)\b/i;
if (urgentWords.test(lead.message || '')) {
  score += 20;
  signals.push('urgent_keywords');
}

score = Math.min(score, 100);
let grade = score >= 75 ? 'A' : score >= 50 ? 'B' : score >= 25 ? 'C' : 'D';

return [{ json: { ...lead, score, grade, signals } }];
```

#### Route by Grade (Switch Node)
```json
{
  "node": "n8n-nodes-base.switch",
  "parameters": {
    "rules": [
      { "output": 0, "conditions": { "string": [{ "value1": "={{$json.grade}}", "operation": "equals", "value2": "A" }] } },
      { "output": 1, "conditions": { "string": [{ "value1": "={{$json.grade}}", "operation": "equals", "value2": "B" }] } },
      { "output": 2, "conditions": { "string": [{ "value1": "={{$json.grade}}", "operation": "equals", "value2": "C" }] } },
      { "output": 3, "conditions": {} }
    ]
  }
}
```

**Output 0 (A-grade)**: → Instant SMS + Email + CRM "Hot" + Carlos SMS Alert
**Output 1 (B-grade)**: → SMS + Email + CRM "Warm" + Assign to Lily
**Output 2 (C-grade)**: → Add to 90-day drip + CRM "Nurture"
**Output 3 (D-grade)**: → CRM "Cold" only

---

## Architecture 2: AI Qualification Bot (WF05)

### Flow

```
FB Webhook → Parse → Dedup → Load State → Build Prompt → Call Groq
  → Parse Response → Extract Data → Score → Route:
      Hot? → SMS Alert to Carlos
      Qualified? → Feed to Pipeline
      All: → Reply to Seller → Update CRM
```

### Critical Implementation Details

1. **Conversation state in staticData**: Persists across executions per sender_id
2. **Two-agent system**: Lily (qualifying) → Adriana (negotiating)
3. **Handoff trigger**: All 6 data points collected + handoff phrase in response
4. **Dynamic scoring**: Recalculated on every message based on collected data
5. **Anti-repetition**: Last 4 AI messages injected into "don't repeat" section
6. **Language auto-detect**: Spanish word frequency → switch system prompt language

### State Machine

```
NEW → qualifying (Lily)
  → All 6 data points? → negotiating (Adriana)
    → intro → anchoring → phone_collected → closing

Each state determines:
  - Which system prompt to use
  - What data to include
  - What triggers advancement
```

---

## Architecture 3: 90-Day Drip Campaign (WF08)

### Flow

```
Schedule (Daily 9 AM) → Query CRM for Due Leads → For Each:
  → Determine Touch Type (by day count)
  → Compliance Check (DNC, hours, frequency)
  → Execute Outreach (SMS/Email/Call)
  → Log Touch to CRM
  → Check for Response → Upgrade if Hot
```

### Touch Schedule

```javascript
const touchSchedule = [
  { day: 0,  channels: ['sms', 'email', 'call'], priority: 'high' },
  { day: 1,  channels: ['sms'],                   priority: 'high' },
  { day: 3,  channels: ['email'],                  priority: 'medium' },
  { day: 7,  channels: ['call', 'sms'],            priority: 'medium' },
  { day: 10, channels: ['sms'],                    priority: 'medium' },
  { day: 14, channels: ['email'],                  priority: 'medium' },
  { day: 21, channels: ['call'],                   priority: 'medium' },
  { day: 30, channels: ['sms'],                    priority: 'low' },
  { day: 45, channels: ['email'],                  priority: 'low' },
  { day: 60, channels: ['call', 'sms'],            priority: 'low' },
  { day: 75, channels: ['email'],                  priority: 'low' },
  { day: 90, channels: ['sms', 'email'],           priority: 'final' }
];
```

---

## Architecture 4: Deal Disposition Engine

### Flow

```
Deal moves to "Under Contract" in CRM
  → Pull deal details
  → Calculate spread & deal sheet
  → Query buyer list (match by criteria)
  → Tier 1 blast (exact match, 24hr exclusive)
  → Tier 2 blast (partial match, 24hr)
  → Tier 3 blast (full list, 48hr)
  → Track buyer responses
  → POF collection → Assignment
```

### Buyer Matching Logic

```javascript
const deal = $input.first().json;
const buyers = $('Buyer List').all();

const matched = buyers.map(buyer => {
  const b = buyer.json;
  let matchScore = 0;

  // Location match (highest weight)
  if (b.target_zips?.includes(deal.zip_code)) matchScore += 40;
  else if (b.target_cities?.includes(deal.city)) matchScore += 25;
  else if (b.target_states?.includes(deal.state)) matchScore += 10;

  // Price range match
  if (deal.asking_price >= b.min_price && deal.asking_price <= b.max_price) matchScore += 30;

  // Property type match
  if (b.property_types?.includes(deal.property_type)) matchScore += 15;

  // Rehab tolerance
  if (deal.repair_estimate <= b.max_rehab_budget) matchScore += 15;

  return { ...b, matchScore };
}).filter(b => b.matchScore >= 40)
  .sort((a, b) => b.matchScore - a.matchScore);

// Tier assignment
const tier1 = matched.filter(b => b.matchScore >= 70);
const tier2 = matched.filter(b => b.matchScore >= 40 && b.matchScore < 70);

return [{ json: { deal, tier1, tier2, total_matched: matched.length } }];
```

---

## Architecture 5: System Health Monitor (WF10)

### Flow

```
Schedule (Every 15 min)
  → Ping all webhook endpoints
  → Check credential expiration
  → Query execution failure rates
  → If failures > threshold → Alert
  → Daily: Summary report via email/Telegram
```

### Health Check Code

```javascript
const workflows = [
  { id: 'UPbXrYapLZclmAnK', name: 'WF05-FB-Bot', critical: true },
  { id: 'h5H0RdpBzFd1cjoa', name: 'EP-19-SMS-Alert', critical: true },
  // ... all workflows
];

const results = [];
for (const wf of workflows) {
  try {
    const resp = await this.helpers.httpRequest({
      method: 'GET',
      url: `https://n8n.srv1441553.hstgr.cloud/api/v1/workflows/${wf.id}`,
      headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
    });
    results.push({
      name: wf.name,
      active: resp.active,
      status: resp.active ? 'OK' : 'INACTIVE',
      critical: wf.critical
    });
  } catch (e) {
    results.push({ name: wf.name, status: 'ERROR', error: e.message, critical: wf.critical });
  }
}

const failures = results.filter(r => r.status !== 'OK');
const criticalFailures = failures.filter(r => r.critical);

return [{ json: { total: results.length, healthy: results.length - failures.length, failures, criticalFailures, checked_at: new Date().toISOString() } }];
```

---

## Architecture 6: Hot Lead SMS Alert (EP-19)

### Flow

```
Webhook (from WF05 Hot Lead Notification)
  → HTTP Request (RingCentral OAuth2)
  → Respond to Webhook
```

### Configuration

- **Webhook path**: `/webhook/carlos-sms-alert`
- **RingCentral credential**: OAuth2 (`jut9CRzRQx6xAXud`)
- **From number**: `+19283209610` (AZ)
- **Payload**: `{ carlos_phone, message }`

### Hot Lead Triggers

A lead is "hot" when ANY of these conditions are true:
1. `just_qualified === true` (first handoff from Lily → Adriana)
2. `phone_given === true` (seller provided phone number)
3. `adriana_state === 'phone_collected'`
4. `adriana_state === 'closing'`
5. `dynamic_score >= 80`

---

## Upgrade Recommendations (v3)

### New Workflows to Build

| Priority | Workflow | Purpose |
|----------|----------|---------|
| 1 | EP-20 Retell Voice Caller | AI voice calls via Retell API |
| 2 | EP-21 Buyer Disposition Blast | Auto-match and blast buyers |
| 3 | EP-22 Intelligent Drip | Engagement-based follow-up adaptation |
| 4 | EP-23 Comps Auto-Pull | PropStream API integration for auto comps |
| 5 | EP-24 DocuSign Delivery | Auto-generate and send contracts |
| 6 | EP-25 Analytics Dashboard | Real-time KPI tracking and reporting |
| 7 | EP-26 Website Form Handler | equitypathoffers.com form intake |
| 8 | EP-27 Compliance Auditor | Automated DNC/TCPA/10DLC checks |

### Integration Priorities

1. **Retell AI** ($0.07/min) — Add AI voice calling to speed-to-lead
2. **PropStream API** — Auto-pull comps, equity, liens for scoring
3. **DocuSign API** — Automated contract generation and delivery
4. **Website form** — equitypathoffers.com with webhook to n8n
5. **Google Ads** — PPC lead intake webhook
