# Agent Orchestration Spec — Lily / Scout / Adriana Pipeline

> The complete n8n workflow architecture for the 3-agent wholesale automation system.
> Uses Equity Path Offers' existing bot names: **Lily** (qualifier/intake), **Adriana** (closer/objection handler), and the new **Scout** (underwriting engine).

---

## Agent Name Mapping

| Your Agent | Role | King Khang Equivalent |
|-----------|------|----------------------|
| **Lily** | Lead intake, qualification, initial scoring | AI Alex |
| **Scout** | Underwriting, comps, ARV, MAO, strategy | AI Scout |
| **Adriana** | Objection handling, closing, follow-up sequences | AI Ryan |

---

## Pipeline Overview

```
INBOUND LEAD (any channel)
    │
    ▼
┌─────────────────┐
│   LILY (Intake)  │  Normalize, dedupe, DNC check, initial score
└────────┬────────┘
         │
         ▼
    ┌─────────┐     Score < 25 → Nurture drip (WF08)
    │ ROUTER  │────► Score 25-49 → Queue for human review
    └────┬────┘     Score ≥ 50 → Immediate Scout
         │
         ▼
┌─────────────────────┐
│  SCOUT (Underwrite) │  ARV, rehab, MAO, novation viability, strategy
└────────┬────────────┘
         │
         ▼
    ┌──────────┐    Dead → Archive + reason
    │ STRATEGY │───► Nurture → 90-day drip (WF08)
    │  ROUTER  │    Wholesale → Adriana (cash path)
    └────┬─────┘    Novation → Adriana (novation path)
         │          Creative → Flag for Carlos review
         ▼
┌─────────────────┐
│  RYAN (Closer)  │  Objection handling, talk tracks, follow-up sequences
└────────┬────────┘
         │
         ▼
    ┌──────────┐    Ready → DocuSign trigger + title company notify
    │ OUTCOME  │───► Stalled → Re-engage sequence (Ryan generates)
    │  ROUTER  │    Dead → Archive + nurture drip
    └────┬─────┘    Under Contract → Dispo blast (wholesale) or MLS prep (novation)
         │
         ▼
┌─────────────────┐
│  PODIO UPDATE   │  Update all fields, stage, next action, notes
└─────────────────┘
```

---

## Workflow: WF-LILY — Lead Intake Pipeline

**Trigger:** Webhook (receives from all lead sources)

```
Node 1: Webhook Trigger
  - Path: /lead-intake
  - Auth: API Key header (X-API-Key)
  - Accepts: POST with lead data from any source

Node 2: Source Router (Switch)
  - Routes by $.body.source field:
    - fb_lead_form → Facebook normalizer
    - fb_messenger → Messenger normalizer
    - sms_inbound → SMS normalizer
    - website_form → Website normalizer
    - cold_call → Call notes normalizer
    - propstream_list → PropStream normalizer

Node 3a-f: Source-Specific Normalizers (Code nodes)
  - Each extracts fields into unified schema
  - Phone: strip to 10 digits
  - Address: standardize format
  - Name: proper case
  - Language: detect from content

Node 4: DNC Check (Code node)
  - Check phone against Podio DNC list
  - If DNC → Stop, log, respond with DNC status

Node 5: Duplicate Check (Code node)
  - Query Podio by phone OR (address + last_name)
  - If duplicate → Merge data, update existing record, skip creation

Node 6: Alex AI Scoring (HTTP Request → Groq API)
  - Send normalized lead data to Groq
  - System prompt: Alex intake agent
  - Returns: initial_score, grade, priority, routing

Node 7: Podio Create/Update
  - Create new lead record with all normalized fields
  - Set status: "New Lead"
  - Set grade: from Alex scoring

Node 8: Priority Router (Switch)
  - A-grade (75+) → Trigger Scout immediately
  - B-grade (50-74) → Trigger Scout, lower priority
  - C-grade (25-49) → Queue for human review
  - D-grade (0-24) → Add to nurture drip

Node 9: Scout Trigger (HTTP Request)
  - POST to WF-SCOUT webhook with lead_id + property data
  - Only for A and B grades

Node 10: Notification (conditional)
  - A-grade: SMS to Carlos "[Name] at [Address] — Grade A, motivation [score]. Scout running now."
  - B-grade: Email summary end of day
```

---

## Workflow: WF-SCOUT — Underwriting Pipeline

**Trigger:** Webhook (receives from WF-LILY or manual trigger)

```
Node 1: Webhook Trigger
  - Path: /scout-underwrite
  - Auth: API Key header
  - Receives: lead_id, property data, seller data

Node 2: PropStream Data Pull (HTTP Request)
  - Pull property details, ownership, equity estimate
  - Pull comparable sales (3-5 comps, 6mo, 0.5mi radius)
  - Pull tax status, lien info if available

Node 3: Comp Analysis (Code node)
  - Filter comps: similar sqft (±20%), similar beds/baths, sold within 6mo
  - Calculate: average sold price, median, price per sqft
  - Identify: highest comp, lowest comp, most similar comp
  - Output: suggested ARV range

Node 4: Scout AI Analysis (HTTP Request → Groq API)
  - Send: property data + comp data + seller data
  - System prompt: Scout underwriter agent
  - Returns: full Scout JSON output
    - ARV, rehab estimate, MAO
    - Novation viability + range
    - Motivation score, distress score
    - Strategy recommendation
    - Missing data flags

Node 5: Podio Update
  - Update lead record with Scout analysis:
    - ARV field
    - Rehab estimate field
    - MAO field
    - Novation viable (Y/N)
    - Novation range
    - Strategy: wholesale/novation/creative/nurture/dead
    - Confidence score
    - Missing data notes

Node 6: Strategy Router (Switch)
  - strategy == "dead" → Archive node
  - strategy == "nurture" → Add to WF08 drip
  - strategy == "wholesale" → Trigger Adriana (cash path)
  - strategy == "novation" → Trigger Adriana (novation path)
  - strategy == "creative" → Notify Carlos for manual review
  - confidence < 60 → Flag for human review regardless

Node 7: Ryan Trigger (HTTP Request)
  - POST to WF-ADRIANA webhook with:
    - lead_id, scout_analysis, conversation_history, strategy

Node 8: Hot Lead Alert (conditional)
  - If motivation >= 80 AND strategy in [wholesale, novation]:
    - SMS to Carlos: "🔥 HOT: [Name] at [Address]. [Strategy]. MAO $[X]. Call NOW."
    - Include top objection prediction from Scout
```

---

## Workflow: WF-ADRIANA — Closer Pipeline

**Trigger:** Webhook (receives from WF-SCOUT or conversation events)

```
Node 1: Webhook Trigger
  - Path: /ryan-closer
  - Auth: API Key header
  - Receives: lead_id, scout_analysis, conversation_transcript, trigger_type

Node 2: Context Builder (Code node)
  - Assemble full context:
    - Scout analysis (ARV, MAO, strategy, psychology)
    - Conversation history from Podio
    - Prior offers made
    - Objection history
    - Follow-up history

Node 3: Ryan AI Analysis (HTTP Request → Groq API)
  - Send: full context package
  - System prompt: Ryan closer agent (state-specific version)
  - Returns: full Ryan JSON output
    - Seller stage
    - True objections
    - Commitment score
    - Talk track
    - Follow-up sequence

Node 4: Podio Update
  - Update lead record with Ryan analysis:
    - Seller stage field
    - Commitment score
    - Last objection
    - Next action
    - Follow-up scheduled date

Node 5: Action Router (Switch)
  - next_action == "call_now" → Hot alert SMS to Carlos with talk track
  - next_action == "send_offer" → Trigger DocuSign prep
  - next_action == "book_callback" → Create calendar event + reminder
  - next_action == "nurture" → Add to drip with Ryan's custom sequence
  - next_action == "disqualify" → Archive + reason

Node 6: Follow-Up Scheduler (Code node)
  - Parse Ryan's follow_up_sequence array
  - For each touch:
    - Calculate send_at timestamp (delay_hours from now)
    - Create scheduled message in queue
    - sms → RingCentral API
    - email → Gmail API
    - call → Create Podio task for Carlos

Node 7: Talk Track Delivery
  - If Carlos is about to call:
    - Format Ryan's talk_track as clean SMS/Slack message
    - Include: opening, empathy line, core question, price reframe, close
    - Send to Carlos 2 minutes before scheduled callback
```

---

## Workflow: WF-DISPO — Disposition Pipeline

**Trigger:** Podio status change to "Under Contract"

```
Node 1: Podio Trigger
  - On status change to "Under Contract"
  - Pull full deal record

Node 2: Exit Strategy Router (Switch)
  - Wholesale → Disposition blast
  - Novation → MLS prep sequence

Node 3a: Wholesale Disposition
  - Pull cash buyer list from Podio/Google Sheets
  - Filter by: market, property type, price range, buyer preferences
  - Generate deal summary email with:
    - Property details, photos
    - ARV, rehab estimate
    - Contract price, assignment fee
    - Inspection period, closing date
  - Send blast via Gmail to matched buyers
  - Track opens/responses

Node 3b: Novation MLS Prep
  - Notify listing agent (market-specific)
  - Generate MLS listing draft with property details
  - Create task: "Get photos from seller (48hr)"
  - Create task: "Get room measurements"
  - Create task: "Schedule contractor walkthrough"
  - Set 7-day reminder: "Confirm MLS listing live"

Node 4: Title Company Notification
  - Send contract package to title company
  - Include: PSA, assignment/novation addendum, seller contact
  - Create Podio task: "Confirm title received package"

Node 5: Closing Timeline Tracker
  - Set calendar events:
    - Inspection deadline
    - Title search expected
    - Closing date
  - Set reminders at: 7 days, 3 days, 1 day before closing
```

---

## Podio Field Schema

### Lead Record (App: "Acquisitions Pipeline")

```
═══════════════════════════════════════
CONTACT FIELDS
═══════════════════════════════════════
lead_id              Text         Auto-generated: EP-YYYYMMDD-XXXX
first_name           Text         Required
last_name            Text         Required
phone                Phone        Required, validated 10-digit
email                Email        Optional
language             Category     en | es
preferred_contact    Category     sms | call | email
lead_source          Category     fb_lead_form | fb_messenger_lily | fb_messenger_adriana | sms_inbound | website_form | cold_call | propstream_list | referral | ppc_google
created_date         Date         Auto-set on creation
last_contact_date    Date         Updated on each touch

═══════════════════════════════════════
PROPERTY FIELDS
═══════════════════════════════════════
property_address     Text         Full street address
city                 Text
state                Category     AZ | TX | CA
zip                  Text
beds                 Number
baths                Number
sqft                 Number
year_built           Number
lot_size             Text
occupancy            Category     owner_occupied | tenant | vacant | unknown
condition            Category     good | fair | poor | unknown
condition_notes      Text (multi) Free-form condition details
hoa                  Category     yes | no | unknown
hoa_amount           Money        Monthly HOA if applicable

═══════════════════════════════════════
FINANCIAL FIELDS
═══════════════════════════════════════
asking_price         Money        Seller's stated price
asking_price_basis   Text         How they arrived at the number
mortgage_balance     Money        Outstanding mortgage
liens_taxes          Money        Outstanding liens/back taxes
equity_estimate_pct  Number       Calculated: (ARV - mortgage) / ARV × 100

═══════════════════════════════════════
SCOUT ANALYSIS FIELDS
═══════════════════════════════════════
arv_low              Money        Scout's ARV range low
arv_high             Money        Scout's ARV range high
arv_suggested        Money        Scout's recommended ARV
rehab_level          Category     light | medium | heavy
rehab_estimate_low   Money
rehab_estimate_high  Money
rehab_suggested      Money
mao_cash             Money        Max Allowable Offer (wholesale)
novation_viable      Category     yes | no | maybe
novation_range_low   Money        Seller net range (novation)
novation_range_high  Money
scout_confidence     Number       0-100
scout_missing_data   Text (multi) What data Scout still needs
comps_used           Text (multi) Comp addresses + prices

═══════════════════════════════════════
SCORING FIELDS
═══════════════════════════════════════
motivation_score     Number       0-100 (from Scout)
distress_score       Number       0-100 (from Scout)
commitment_score     Number       0-100 (from Ryan)
initial_score        Number       0-100 (from Alex)
lead_grade           Category     A | B | C | D
conversion_priority  Category     hot | warm | nurture | dead

═══════════════════════════════════════
PIPELINE FIELDS
═══════════════════════════════════════
status               Category     new_lead | contacted | qualified | offer_made |
                                  negotiating | under_contract | closed | dead | nurture
exit_strategy        Category     wholesale | novation | creative | sub2 | wrap | none
seller_stage         Category     discovery | qualified | negotiating | stalled | ready
next_action          Category     scout_underwrite | call_now | send_offer |
                                  book_callback | nurture_sequence | disqualify | human_review
next_action_date     Date         When the next action should happen
assigned_to          Category     alex | scout | ryan | carlos | drip

═══════════════════════════════════════
SELLER PSYCHOLOGY (Ryan)
═══════════════════════════════════════
magic_problem        Text (multi) The core pain/motivation
objections_history   Text (multi) All objections raised, timestamped
last_objection       Text         Most recent objection category
recommended_tone     Category     direct | empathetic | urgent | consultative
talk_track_current   Text (multi) Ryan's latest talk track for Carlos

═══════════════════════════════════════
DEAL FIELDS (post-contract)
═══════════════════════════════════════
contract_price       Money        Agreed purchase price
assignment_fee       Money        Your wholesale fee
novation_fee         Money        Your novation fee
title_company        Text
closing_date         Date
inspection_deadline  Date
documents_status     Category     not_sent | sent | partially_signed | fully_signed
disposition_status   Category     not_started | blast_sent | buyer_interested |
                                  buyer_under_contract | closed

═══════════════════════════════════════
COMMUNICATION LOG
═══════════════════════════════════════
call_1_date          Date         Discovery call
call_1_notes         Text (multi) Podio-ready notes from template
call_2_date          Date         Anchor call
call_2_notes         Text (multi)
call_3_date          Date         Deliver call
call_3_notes         Text (multi)
follow_up_count      Number       Total touches
last_follow_up_type  Category     sms | call | email
drip_stage           Category     day_7 | day_14 | day_30 | day_60 | day_90 | completed

═══════════════════════════════════════
FLAGS
═══════════════════════════════════════
is_dnc               Category     yes | no
is_duplicate         Category     yes | no
needs_human_review   Category     yes | no
spanish_speaker      Category     yes | no
has_attorney         Category     yes | no
multiple_decision_makers Category  yes | no
```

---

## State Phone Number Routing

```javascript
// n8n Code node: Get state phone number
const statePhones = {
  'AZ': '(928) 320-9610',
  'TX': '(281) 640-2291',
  'CA': '(424) 421-5535'
};

const state = $json.property?.state || $json.state || 'AZ';
const phone = statePhones[state] || statePhones['AZ'];

return { ...items[0].json, ep_phone: phone };
```

---

## API Endpoints Summary

| Workflow | Webhook Path | Method | Auth |
|----------|-------------|--------|------|
| WF-LILY | `/lead-intake` | POST | X-API-Key |
| WF-SCOUT | `/scout-underwrite` | POST | X-API-Key |
| WF-ADRIANA | `/ryan-closer` | POST | X-API-Key |
| WF-DISPO | Podio trigger | — | — |

---

## Environment Variables

```
GROQ_API_KEY=gsk_...
PROPSTREAM_API_KEY=...  (if API available, otherwise manual)
PODIO_CLIENT_ID=...
PODIO_CLIENT_SECRET=...
RINGCENTRAL_JWT=...
GMAIL_OAUTH_TOKEN=...
DOCUSIGN_API_KEY=...
N8N_API_KEY=...
EP_WEBHOOK_API_KEY=ep_ba46f2c670c8b842148656dc18007321
```

---

## Migration Path from Current System

### Phase 1: Alex (Week 1)
- Build WF-LILY intake webhook
- Connect existing FB Lead Form (WF07b) output → Alex
- Connect Lily/Adriana bot output → Alex
- Test: leads normalize correctly into Podio

### Phase 2: Scout (Week 2)
- Build WF-SCOUT underwriting webhook
- Create Groq prompt from scout-underwriter.md
- Connect Alex output → Scout
- Test: accurate ARV/MAO on 10 known deals

### Phase 3: Ryan (Week 3)
- Build WF-ADRIANA closer webhook
- Create Groq prompt from ryan-closer.md
- Connect Scout output → Ryan
- Test: objection handling on 10 real conversations

### Phase 4: Integration (Week 4)
- Wire full pipeline: Alex → Scout → Ryan → Podio
- Add hot lead SMS alerts
- Add follow-up scheduling
- Build "deal desk" view in Podio

### Phase 5: Dispo (Week 5)
- Build WF-DISPO for post-contract automation
- Cash buyer blast for wholesale
- MLS prep sequence for novation
- Title company notification

### Keep Running
- WF05 (AI Bot) → Feeds into Alex
- WF06 (FB Messenger) → Feeds into Alex
- WF07b (Lead Form) → Feeds into Alex
- WF08 (90-Day Drip) → Ryan generates custom sequences
- WF10 (Health Monitor) → Add agent health checks
- EP-19 (Hot Lead Alert) → Replace with Scout/Ryan alerts
