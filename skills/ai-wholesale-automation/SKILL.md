---
name: ai-wholesale-automation
description: Expert guide for AI-powered wholesale and novation real estate automation. Use when building lead pipelines, configuring AI bots for seller outreach, scoring leads, building drip campaigns, setting up SMS/voice/email automation, creating deal disposition workflows, or asking about wholesale/novation deal processes, TCPA compliance, Facebook ads, cash buyer lists, or CRM automation for real estate investors.
---

# AI Wholesale Real Estate Automation

Expert guidance for building and optimizing AI-powered wholesale and novation real estate systems using n8n workflows.

---

## System Architecture Overview

```
                    ┌─────────────────────────────────────┐
                    │         LEAD SOURCES                 │
                    │  Facebook Ads │ Google PPC │ Website  │
                    │  PropStream   │ Driving4$  │ Direct   │
                    └────────────┬──────────────────────────┘
                                 │
                    ┌────────────▼──────────────────────────┐
                    │     INTAKE & SCORING (n8n)            │
                    │  Webhook → Parse → Enrich → Score     │
                    │  → Route by grade (A/B/C/D)           │
                    └────────────┬──────────────────────────┘
                                 │
              ┌──────────────────┼──────────────────────┐
              │                  │                      │
     ┌────────▼───────┐ ┌───────▼────────┐  ┌──────────▼─────┐
     │  HOT (A/B)     │ │  WARM (C)      │  │  COLD (D)      │
     │  AI Qualifier  │ │  90-Day Drip   │  │  Database       │
     │  (Lily Bot)    │ │  SMS+Email     │  │  Quarterly      │
     └────────┬───────┘ └───────┬────────┘  └────────────────┘
              │                 │
     ┌────────▼───────┐        │
     │  QUALIFIED     │        │
     │  AI Closer     │◄───────┘ (upgrades on response)
     │  (Adriana Bot) │
     └────────┬───────┘
              │
     ┌────────▼───────────────────────────────┐
     │  DEAL PIPELINE                          │
     │  Discovery → Anchor → Delivery          │
     │  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
     │  │Wholesale │ │Novation  │ │Creative │ │
     │  │Assign    │ │MLS List  │ │Sub2/Wrap│ │
     │  └──────────┘ └──────────┘ └─────────┘ │
     └────────┬───────────────────────────────┘
              │
     ┌────────▼───────┐
     │  DISPOSITION    │
     │  Buyer Blast    │
     │  → Close        │
     └────────────────┘
```

---

## 1. Lead Scoring Engine

### Rule-Based Scoring (0-100)

Deploy in n8n Code node for instant scoring on intake:

```
PROPERTY SIGNALS (max 60 pts):
  Equity > 40%:           +20
  Pre-foreclosure/NOD:    +25
  Tax delinquent:         +20
  Vacant property:        +15
  Code violations:        +15
  Liens/judgments:        +15
  Absentee owner:         +10
  Ownership 10+ years:    +10
  Inherited/probate:      +20
  Expired MLS listing:    +15

BEHAVIORAL SIGNALS (max 40 pts):
  Responded to outreach:  +10
  Timeline < 30 days:     +15
  Phone number given:     +10
  Verbal interest:        +10
  Multiple responses:     +5
  Speed of response <1hr: +5

GRADE MAPPING:
  A (Hot):     75-100 → Immediate multi-channel contact
  B (Warm):    50-74  → Active nurture, weekly contact
  C (Nurture): 25-49  → Drip campaign, monthly contact
  D (Cold):    0-24   → Database only, quarterly touch
```

### ABCD Qualification Framework

| Letter | Meaning | What to Check |
|--------|---------|---------------|
| **A** - Ability | Can they sell? | Equity position, title clear, decision authority, no legal blocks |
| **B** - Believability | Do they trust you? | Rapport built, credibility established, follow-through shown |
| **C** - Condition | Property state? | Repairs needed, ARV gap, neighborhood, lot size |
| **D** - Desire/Distress | How motivated? | Timeline urgency, pain points, financial pressure, life events |

### n8n Scoring Node Pattern

```javascript
// Code node: AI Lead Scoring
const items = $input.all();
return items.map(item => {
  const lead = item.json;
  let score = 0;
  const signals = [];

  // Property signals
  if (parseFloat(lead.equity_pct) > 40) { score += 20; signals.push('high_equity'); }
  if (lead.pre_foreclosure) { score += 25; signals.push('pre_foreclosure'); }
  if (lead.tax_delinquent) { score += 20; signals.push('tax_delinquent'); }
  if (lead.vacant) { score += 15; signals.push('vacant'); }
  if (lead.absentee) { score += 10; signals.push('absentee'); }
  if (lead.inherited) { score += 20; signals.push('inherited'); }
  if (lead.expired_listing) { score += 15; signals.push('expired_listing'); }

  // Behavioral signals
  if (lead.responded) { score += 10; signals.push('responded'); }
  if (lead.timeline_days && lead.timeline_days <= 30) { score += 15; signals.push('urgent_timeline'); }
  if (lead.phone_given) { score += 10; signals.push('phone_collected'); }

  // Cap at 100
  score = Math.min(score, 100);

  // Grade
  let grade;
  if (score >= 75) grade = 'A';
  else if (score >= 50) grade = 'B';
  else if (score >= 25) grade = 'C';
  else grade = 'D';

  return { json: { ...lead, score, grade, signals, scored_at: new Date().toISOString() } };
});
```

---

## 2. AI Bot Architecture (Lily & Adriana)

### Two-Agent System

| Agent | Role | Trigger | Goal |
|-------|------|---------|------|
| **Lily** | Qualifier | First contact | Collect 6 data points: name, address, timeline, condition, motivation, price |
| **Adriana** | Closer | After qualification | Get phone number, schedule appointment, verbal agreement |

### Handoff Flow

```
Seller message → Lily qualifies (1 question at a time)
  → All 6 data points collected?
    YES → Score lead → If A/B grade → Adriana takes over
    NO  → Continue qualifying
```

### Key Bot Rules

1. **NEVER reveal they are AI** - always present as team members
2. **One question at a time** - don't overwhelm the seller
3. **Bilingual** - auto-detect English/Spanish, respond in same language
4. **State-matched phone numbers** - give local number based on property state
5. **Anti-repetition** - track last 4 AI messages, don't repeat
6. **DNC detection** - if seller says "stop", "remove", "don't contact" → flag and halt

### Adriana Negotiation States

```
intro → anchoring → phone_collected → closing
  │         │              │             │
  │    Present cash    Got phone      Verbal yes
  │    offer range     number         or appointment
  │         │              │
  │    If price objection: │
  │    pivot to novation   │
  │    (higher retail value)│
  └────────────────────────┘
```

### Adriana Techniques

- **Anchor**: Present cash offer range using comps
- **Feel/Felt/Found**: Handle objections empathetically
- **Novation Pivot**: If seller wants more, explain retail listing option
- **Urgency**: "I have another property to review today, want to secure your spot"
- **Phone Push**: Always push for phone number - "Let me have our senior analyst call you with exact numbers"

See [AI_BOT_PROMPTS.md](AI_BOT_PROMPTS.md) for complete system prompts.

---

## 3. The Rainmaker Method (Novation)

### Phase 1: Discovery
**Goal**: Position as information gatherer, not salesperson

- Let seller talk 80%, you 20%
- Gather: motivation, timeline, financial situation, property condition
- Key questions: Why selling? What have you tried? What's your timeline?
- **AI automation**: Lily bot qualifies, AI scores, auto-pull equity/liens/comps

### Phase 2: Anchor
**Goal**: Set realistic price expectations

- Present comparable sales data showing realistic value
- Use bracket technique: give range, not single number
- Address expectation gap with speed/certainty/convenience value
- **AI automation**: Auto-pull comps (PropStream), generate MAO calculation, AI offer presentation

### Phase 3: Delivery
**Goal**: White glove closing experience

- Professional offer delivery (DocuSign)
- Handle objections with prepared responses
- Coordinate property updates (novation) or assignment (wholesale)
- **AI automation**: DocuSign delivery, status update drips, disposition to buyers

### When to Use Each Exit Strategy

| Strategy | Best For | Profit | Timeline | Buyer Pool |
|----------|----------|--------|----------|------------|
| **Wholesale** | Deep distress, major rehab needed | $5K-$15K | 7-30 days | Cash buyers only |
| **Novation** | Moderate equity, good condition | $15K-$50K+ | 30-90 days | All buyers (FHA/VA/Conv) |
| **Creative (Sub2)** | Low equity, good terms | Varies | 30-60 days | End buyers |

### MAO Calculation

```
WHOLESALE:
  MAO = ARV × 0.70 - Repairs - Wholesale Fee
  Example: $300K × 0.70 - $30K - $10K = $170K

NOVATION:
  Net = Retail Sale Price - Agent Commission - Updates - Seller Payoff - Novation Fee
  Example: $300K - $18K (6%) - $10K - $200K = $72K (split with seller)
```

---

## 4. Multi-Channel Outreach

### Speed-to-Lead Protocol (Under 5 Minutes)

```
Lead intake webhook fires:
  0-1 min: AI SMS sent (personalized, address-specific)
  1-2 min: AI email sent (cash offer angle)
  2-5 min: AI bot engages if on Messenger
  5-15 min: AI voice call (Retell) if phone available
  Same day: Second SMS if no response
  Day 1: Follow-up email
```

### 90-Day Drip Campaign

```
Day 0:   SMS + Email + Call attempt
Day 1:   Follow-up SMS
Day 3:   Email with market data
Day 7:   Call attempt + SMS
Day 10:  SMS check-in
Day 14:  Email with neighborhood sales
Day 21:  Call attempt
Day 30:  SMS: "Offer still stands"
Day 45:  Email: Value content
Day 60:  Call + SMS
Day 75:  Email: Market update
Day 90:  Final touch: "Still here if you need us"
```

### Channel-Specific Guidelines

**SMS**:
- Always include STOP opt-out
- Max 3 texts per 24 hours
- Personalize with property address and owner name
- 10DLC registration REQUIRED (see [COMPLIANCE.md](COMPLIANCE.md))

**Email**:
- No n8n footer (`appendAttribution: false`)
- Subject line: Include property address
- Keep under 150 words
- One clear CTA

**AI Voice** (Retell/Vapi):
- TCPA Prior Express Written Consent REQUIRED
- Identify as AI at start (FCC requirement)
- Call only 8am-9pm recipient local time
- Log all calls to CRM

See [OUTREACH_SCRIPTS.md](OUTREACH_SCRIPTS.md) for complete templates.

---

## 5. Compliance Requirements

### SMS (10DLC + TCPA)

| Requirement | Status | Action |
|-------------|--------|--------|
| 10DLC Brand Registration | MANDATORY since Feb 2025 | Register through RingCentral/Twilio |
| 10DLC Campaign Registration | MANDATORY | Define use case, message samples |
| Prior Express Written Consent | REQUIRED for marketing SMS | Collect via web form/keyword opt-in |
| STOP/opt-out handling | REQUIRED in first message | Auto-process STOP, CANCEL, END, QUIT |
| Time restrictions | 8am-8pm local time | Check recipient timezone before sending |
| Frequency limits | Max 3/day best practice | Throttle in n8n workflow |
| Record retention | 4+ years | Log all consent with timestamps |

### AI Voice Calls

| Requirement | Details |
|-------------|---------|
| PEWC consent | REQUIRED before ANY AI call |
| Disclosure | Must identify as AI/automated at call start |
| One-to-one consent | Cannot use aggregated lead consent |
| Penalties | $500-$1,500 per violation |
| DNC scrubbing | Check national + state DNC before calling |
| Calling hours | 8am-9pm recipient local time |

### Facebook Ads (Housing Special Ad Category)

| Restriction | Impact |
|-------------|--------|
| Age targeting | BANNED |
| Gender targeting | BANNED |
| ZIP code targeting | BANNED |
| Income targeting | BANNED |
| Minimum radius | 15 miles (US) |
| Lookalike audiences | BANNED (use Special Ad Audiences) |
| Interest targeting | Severely limited |

See [COMPLIANCE.md](COMPLIANCE.md) for full compliance checklist.

---

## 6. n8n Workflow Patterns for Wholesale

### Pattern 1: Lead Intake Pipeline

```
Webhook (FB Form / Website / API)
  → Parse & Validate
  → Deduplicate (check existing leads)
  → Enrich (PropStream/BatchData: equity, liens, condition)
  → AI Score (Code node: 0-100)
  → Route by Grade:
      A/B → Instant multi-channel outreach + CRM "Hot"
      C   → Drip campaign + CRM "Nurture"
      D   → Database only + CRM "Cold"
  → Notify team (SMS/Slack if A-grade)
```

### Pattern 2: AI Qualification Bot

```
FB Messenger/SMS Webhook
  → Parse message (extract sender, text, attachments)
  → Load conversation state (staticData)
  → Determine agent (Lily or Adriana based on state)
  → Build AI prompt with conversation history
  → Call LLM (Groq/OpenAI)
  → Parse response (extract data points, detect handoff)
  → Update conversation state
  → Hot lead detection → SMS alert to acquisitions
  → Send reply via FB API or RingCentral
```

### Pattern 3: Deal Disposition

```
CRM trigger: Deal moves to "Under Contract"
  → Pull deal details (address, ARV, offer, repairs)
  → Generate deal sheet
  → Query buyer list (match: location, price range, property type)
  → Blast matching buyers (email + SMS)
  → Track responses → Update CRM
  → If buyer POF received → Notify acquisitions
```

### Pattern 4: Automated Follow-Up

```
Schedule: Daily 9 AM
  → Query CRM for leads due for follow-up
  → For each lead:
      → Calculate days since last contact
      → Determine touch type (SMS/email/call)
      → Execute outreach
      → Log touch to CRM
      → If response detected → Upgrade priority
```

### Pattern 5: System Monitor

```
Schedule: Every 15 minutes
  → Health check all webhook endpoints
  → Verify credential validity (OAuth tokens)
  → Check execution failure rate
  → If failures > threshold → Alert via SMS/Slack
  → Daily summary report
```

See [WORKFLOW_ARCHITECTURES.md](WORKFLOW_ARCHITECTURES.md) for detailed node configurations.

---

## 7. Cash Buyer List

### Building the List

| Source | Method | Quality |
|--------|--------|---------|
| PropStream Quick List | Filter recent cash purchases, 3+ properties owned | High |
| County records | Search transactions with no mortgage recorded | High |
| REI meetups | Network at local investor groups | High |
| Auction attendees | People at foreclosure auctions have cash | Very High |
| Facebook RE groups | Post deals, collect buyer criteria | Medium |
| Title companies | Ask for referrals to active buyers | High |
| Hard money lenders | They know active buyers | High |

### Buyer Segmentation

Track for each buyer:
- Property type preference (SFR, multi, commercial)
- Geographic focus (zip codes)
- Price range (budget per deal)
- Rehab tolerance (turnkey vs. gut rehab)
- Buying frequency and speed of close
- Deals closed with you, reliability score

### Disposition Workflow

```
New deal under contract
  → Match criteria against buyer database
  → Tier 1: Exact match buyers (get first look, 24hrs)
  → Tier 2: Partial match (get blast at 24hrs)
  → Tier 3: Full list (48hrs if no Tier 1/2 commitment)
  → Track: opens, clicks, responses, POF submissions
```

---

## 8. CRM Pipeline Stages

### Acquisitions Pipeline

```
1. New Lead          → Auto-assign, AI score, speed-to-lead triggered
2. Contacted         → First conversation logged
3. Appointment Set   → Calendar invite, reminder sequence
4. Appointment Done  → Property info captured, comps pulled
5. Offer Made        → DocuSign sent
6. Negotiating       → Follow-up sequence (3-7-14-30 day touches)
7. Under Contract    → Title search initiated, disposition started
8. In Closing        → TC coordinating, buyer assigned
9. Closed Won        → Commission tracked, review request sent
10. Dead/Nurture     → 90-day drip, re-engagement sequence
```

### Dispositions Pipeline

```
1. New Deal          → Deal sheet created, buyer blast
2. Buyer Interest    → POF requested
3. Under Contract    → Assignment/double-close initiated
4. In Closing        → Title company coordinating
5. Closed            → Profit recorded
```

### Podio + n8n Integration Pattern

```
n8n → HTTP Request node → Podio Webform POST
  Body: {
    "field_1": leadName,      // Text field
    "field_2": propertyAddr,  // Text field
    "field_3": phoneNumber,   // Phone field
    "field_4": score,         // Number field
    "field_5": grade,         // Category field
    "field_6": source         // Text field
  }
  No CSRF needed for webform endpoint
```

---

## 9. Marketing Channels

### Facebook Ads (Motivated Sellers)

**Setup**:
1. Select Housing Special Ad Category (MANDATORY)
2. Target by city (15-mile minimum radius)
3. Use broad targeting + strong creative (let algorithm optimize)
4. Start with $10-20/day, scale what converts

**Best performing formats**: Video (403% more inquiries) > Lead Forms > Carousel

**Cost benchmarks**:
- CPL: $5-$65 (varies by market tier)
- CPC: ~$1.17 average
- Conversion rate: ~10.67%

**Winning angles**:
- Speed: "Close in 7 days"
- As-is: "No repairs, no cleaning"
- Cash: "Fair cash offer in 24 hours"
- No fees: "Zero commissions or closing costs"
- Problem-solving: "Behind on payments? We can help"

### Google PPC

**High-intent keywords**: "sell my house fast [city]" ($30-36 CPC), "we buy houses [city]" ($15-25 CPC)

**Recommended budget**: $1,500-$3,000/month minimum

**Landing page musts**: Sub-2s load, 4 fields max, single CTA, mobile-first, local imagery

### AI Voice (Retell AI Recommended)

- $0.07/min flat rate
- Best latency for natural conversation
- Branded caller ID boosts answer rates
- TCPA compliance: PEWC required for ALL AI calls

See [MARKETING_CHANNELS.md](MARKETING_CHANNELS.md) for detailed campaign structures.

---

## 10. Upgrade Roadmap

### Current System (v2) → Upgraded System (v3)

| Area | Current (v2) | Upgrade (v3) |
|------|-------------|-------------|
| Lead Scoring | 6-dimension rubric in Groq prompt | Dedicated scoring Code node with 12+ weighted signals |
| Bot Intelligence | Single Groq prompt per agent | Multi-model: fast model for routing, strong model for negotiation |
| Outreach | SMS via RingCentral + Email via Gmail | + AI Voice (Retell), + Ringless Voicemail, + Direct Mail triggers |
| Follow-up | WF08 basic drip | Intelligent drip: adapt channel/frequency based on engagement |
| Disposition | Manual | Auto-blast matching buyers on contract |
| Compliance | Basic webhook auth | 10DLC registered, TCPA consent tracking, DNC auto-scrub |
| Monitoring | WF10 basic health | Real-time alerts, execution analytics, cost tracking |
| CRM | Podio + Google Sheets | Podio with full pipeline stages, automated status updates |
| Website | None | equitypathoffers.com with form → webhook → instant response |
| Analytics | Daily email report | Real-time dashboard: CPL, conversion rates, pipeline value |

### Priority Implementation Order

1. **10DLC Registration** - Unregistered SMS gets blocked
2. **Website with intake form** - Capture inbound leads 24/7
3. **AI Voice (Retell)** - Add phone channel to speed-to-lead
4. **Buyer list + disposition workflow** - Monetize deals faster
5. **Enhanced scoring** - Better lead routing = higher conversion
6. **Intelligent drip** - Engagement-based follow-up
7. **Analytics dashboard** - Track ROI per channel
8. **Novation automation** - DocuSign + MLS workflow

---

## Quick Reference

### Key Formulas

```
MAO (Wholesale) = ARV × 0.70 - Repairs - Your Fee
MAO (Novation)  = Retail Price - Commission - Updates - Payoff - Your Fee
CPL Target       = Monthly Budget ÷ Number of Leads
Cost Per Deal    = Total Marketing Spend ÷ Deals Closed
ROI              = (Revenue - Total Cost) ÷ Total Cost × 100
```

### Key Metrics to Track

| Metric | Target |
|--------|--------|
| Speed-to-lead | < 5 minutes |
| Lead-to-contact rate | > 40% |
| Contact-to-appointment | > 15% |
| Appointment-to-offer | > 60% |
| Offer-to-contract | > 20% |
| Contract-to-close | > 80% |
| Cost per lead (FB) | < $30 |
| Cost per deal | < $2,000 |

### Reference Files

- [AI_BOT_PROMPTS.md](AI_BOT_PROMPTS.md) - Complete Lily & Adriana system prompts
- [OUTREACH_SCRIPTS.md](OUTREACH_SCRIPTS.md) - SMS, email, cold call, Spanish templates
- [COMPLIANCE.md](COMPLIANCE.md) - TCPA, 10DLC, Housing Ads, DNC requirements
- [WORKFLOW_ARCHITECTURES.md](WORKFLOW_ARCHITECTURES.md) - Detailed n8n workflow patterns
- [MARKETING_CHANNELS.md](MARKETING_CHANNELS.md) - Facebook, Google, Voice channel guides
- [CASH_BUYER_PLAYBOOK.md](CASH_BUYER_PLAYBOOK.md) - Cash buyer list building, VIP tiers, dispo templates, POF verification

### Agent System (v3 Architecture)

- [agents/scout-underwriter.md](agents/scout-underwriter.md) - Scout: ARV, rehab, MAO, novation viability, strategy engine
- [agents/adriana-closer.md](agents/adriana-closer.md) - Adriana v2: objection specialist, commitment tracking, follow-up sequencing
- [agents/lily-intake.md](agents/lily-intake.md) - Lily v2: lead normalization, dedup, DNC, initial scoring from all channels
- [agents/comp-analysis-engine.py](agents/comp-analysis-engine.py) - Python comp scoring engine (weighted PPSF, outlier removal, ARV calc)
- [agents/orchestration-spec.md](agents/orchestration-spec.md) - Full Lily → Scout → Adriana pipeline with n8n workflow specs + Podio schema

### Novation Call Assistant

- [equitypath-novation-assistant/](equitypath-novation-assistant/) - Complete Rainmaker 3-call system (Discovery → Anchor → Deliver) with live coaching, objection handlers, deal calculator, Podio templates, follow-up texts
