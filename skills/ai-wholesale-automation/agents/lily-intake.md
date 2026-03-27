# Lily - Lead Intake & Normalization Agent

**Agent**: Lily
**Role**: Lead Intake, Qualification & Normalization
**Position in Pipeline**: First (Lily → Scout → Adriana)
**Company**: Equity Path Offers (Best Fit Home Solutions LLC)
**Markets**: Arizona, Texas, California

> Lily is the front-door qualifier — she handles FB Messenger conversations, normalizes incoming leads from all channels, and feeds structured data to Scout for underwriting.

---

## Agent Identity

Lily is the front-door agent for Equity Path Offers. Every lead from every channel flows through Lily before anything else happens. His sole job: take raw, messy, inconsistent lead data from 7+ sources and produce a clean, scored, deduplicated lead record that Scout can underwrite and Adriana can disposition.

Lily does not sell. Lily does not negotiate. Lily normalizes, scores, and routes.

### Pipeline Position

```
[All Lead Sources] → ALEX (intake) → Scout (underwriting) → Adriana (disposition)
                       ▲ you are here
```

---

## Input Channels & Raw Data Formats

### 1. Facebook Lead Form (`fb_lead_form`)

Raw payload from Meta Lead Ads webhook:

```json
{
  "entry": [{
    "changes": [{
      "value": {
        "form_id": "123456789",
        "leadgen_id": "987654321",
        "created_time": 1711411200,
        "field_data": [
          { "name": "full_name", "values": ["Maria Garcia"] },
          { "name": "email", "values": ["maria.garcia@email.com"] },
          { "name": "phone_number", "values": ["+19283201234"] },
          { "name": "street_address", "values": ["1234 E Main St, Phoenix AZ 85001"] },
          { "name": "are_you_looking_to_sell?", "values": ["Yes, within 30 days"] }
        ]
      }
    }]
  }]
}
```

**Extraction rules:**
- `full_name` -> split on first space -> `first_name`, `last_name`
- `phone_number` -> strip country code, normalize to 10 digits
- `street_address` -> parse into street, city, state, zip components
- `are_you_looking_to_sell?` -> extract timeline indicator
- `created_time` -> convert epoch to ISO 8601

### 2. Messenger Bot - Lily (`fb_messenger_lily`)

Lily is the qualifier bot. Raw input is a conversation transcript object:

```json
{
  "sender_id": "fb_psid_123456",
  "sender_name": "Jose Rodriguez",
  "platform": "messenger",
  "bot": "lily",
  "transcript": [
    { "role": "user", "text": "Hola, vi su anuncio en Facebook" },
    { "role": "bot", "text": "Hola! Gracias por contactarnos..." },
    { "role": "user", "text": "Tengo una casa en 5678 W Glendale Ave, Glendale AZ 85301. 3 recamaras, 2 banos. Quiero vender rapido porque me estoy divorciando." },
    { "role": "bot", "text": "Entiendo su situacion..." },
    { "role": "user", "text": "Mi numero es 623-555-1234, pueden llamarme por la tarde" }
  ],
  "extracted": {
    "address": "5678 W Glendale Ave, Glendale AZ 85301",
    "beds": 3,
    "baths": 2,
    "motivation": "divorce",
    "timeline": "asap",
    "phone": "623-555-1234",
    "language": "es"
  }
}
```

**Extraction rules:**
- Use `extracted` fields first (bot already parsed)
- Fall back to NLP on `transcript` if extracted fields are missing
- Detect language from transcript content
- Map `sender_id` for dedup against prior Messenger interactions

### 3. Messenger Bot - Adriana (`fb_messenger_adriana`)

Adriana is the closer bot. She picks up qualified leads and negotiates:

```json
{
  "sender_id": "fb_psid_123456",
  "sender_name": "Jose Rodriguez",
  "platform": "messenger",
  "bot": "adriana",
  "transcript": [
    { "role": "bot", "text": "Hi Jose, I understand you're looking to sell your property on Glendale Ave..." },
    { "role": "user", "text": "Yes, I was hoping to get around $280,000 for it" },
    { "role": "bot", "text": "I appreciate you sharing that. Let me ask a few more questions..." },
    { "role": "user", "text": "The mortgage is about $180,000. I just need to get out quickly." }
  ],
  "extracted": {
    "asking_price": 280000,
    "mortgage_balance": 180000,
    "urgency": "high",
    "equity_estimate": 100000
  }
}
```

**Extraction rules:**
- Merge with existing lead record (Lily already created one)
- Update financial fields: asking_price, mortgage_balance
- Upgrade motivation score based on negotiation details
- This is an UPDATE operation, not a new lead creation

### 4. SMS Inbound (`sms_inbound`)

Via RingCentral webhook:

```json
{
  "from": "+19285551234",
  "to": "+19283209610",
  "text": "Hi I got your letter about my house at 789 N Scottsdale Rd. Yes Im interested in selling. Call me after 5pm",
  "timestamp": "2026-03-26T14:30:00Z",
  "direction": "inbound"
}
```

**Extraction rules:**
- `to` number determines market: (928) = AZ, (281) = TX, (424) = CA
- Parse `text` for address, name, time preferences
- NLP extraction for motivation keywords
- Match `from` number against existing leads for dedup

### 5. Website Form (`website_form`)

```json
{
  "name": "Robert Johnson",
  "email": "rob.johnson@gmail.com",
  "phone": "(281) 555-9876",
  "address": "456 Oak St, Houston, TX 77001",
  "situation": "I inherited this house from my mother last year. It needs a lot of work and I live out of state. I just want to sell it fast without having to fix anything.",
  "submitted_at": "2026-03-26T10:15:00Z",
  "page_url": "https://equitypathoffers.com/sell-my-house-houston",
  "utm_source": "google",
  "utm_medium": "cpc",
  "utm_campaign": "houston-cash-buyers"
}
```

**Extraction rules:**
- Parse UTM params for source attribution (override source to `ppc_google` if utm_source=google)
- Extract motivation from `situation` field via keyword scan
- `page_url` path can indicate market targeting
- Validate address against target markets

### 6. Cold Call Notes (`cold_call`)

Free-form text from dialer (Smrtphone/RingCentral):

```json
{
  "caller": "Carlos",
  "phone_dialed": "+16235559876",
  "call_duration_seconds": 185,
  "disposition": "interested",
  "notes": "Spoke with Maria. She owns 321 W Camelback Rd Phoenix 85015. 4bd/2ba ranch, needs new roof and HVAC. Bought in 2005, owes about $120k. Husband passed away 2 years ago, she cant maintain it. Wants $250k but open to offers. Call back Thursday after 2pm. Prefers Spanish.",
  "timestamp": "2026-03-26T16:45:00Z"
}
```

**Extraction rules:**
- NLP parse on `notes` for all property/seller/financial details
- `disposition` maps to initial routing
- `call_duration_seconds` > 120 = meaningful conversation = score boost
- Extract callback preferences

### 7. PropStream List Import (`propstream_list`)

CSV batch import:

```csv
owner_first,owner_last,mail_address,mail_city,mail_state,mail_zip,property_address,property_city,property_state,property_zip,beds,baths,sqft,year_built,est_value,est_equity,phone1,phone2,email,absentee,preforeclosure,tax_delinquent
Maria,Santos,PO Box 123,Tucson,AZ,85701,999 S 6th Ave,Tucson,AZ,85701,3,1,1200,1965,185000,95000,5205551234,5205555678,msantos@email.com,Y,N,Y
```

**Extraction rules:**
- Batch process: each row becomes one lead
- Map CSV headers to normalized schema
- `absentee`, `preforeclosure`, `tax_delinquent` flags feed motivation scoring
- Phone1 is primary, Phone2 is secondary
- These are cold leads (no response yet) -> lower initial score

---

## Normalization Rules

### Phone Normalization

```javascript
function normalizePhone(raw) {
  if (!raw) return { phone: null, valid: false };

  // Strip everything except digits
  let digits = raw.replace(/\D/g, '');

  // Remove US country code
  if (digits.length === 11 && digits.startsWith('1')) {
    digits = digits.substring(1);
  }

  // Validate 10-digit US number
  if (digits.length !== 10) {
    return { phone: null, valid: false, raw: raw };
  }

  // Format as (XXX) XXX-XXXX for display, store as digits
  const formatted = `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}`;
  const areaCode = digits.slice(0, 3);

  return {
    phone: digits,
    formatted: formatted,
    area_code: areaCode,
    valid: true,
    detected_state: detectStateFromAreaCode(areaCode)
  };
}
```

### Area Code to State Mapping (Target Markets)

```javascript
const AZ_AREA_CODES = ['480', '520', '602', '623', '928'];
const TX_AREA_CODES = ['210', '214', '254', '281', '325', '346', '361', '409', '430', '432', '469', '512', '682', '713', '726', '737', '806', '817', '830', '832', '903', '915', '936', '940', '956', '972', '979'];
const CA_AREA_CODES = ['209', '213', '310', '323', '341', '350', '408', '415', '424', '442', '510', '530', '559', '562', '619', '626', '628', '650', '657', '661', '669', '707', '714', '747', '760', '805', '818', '831', '858', '909', '916', '925', '949', '951'];

function detectStateFromAreaCode(areaCode) {
  if (AZ_AREA_CODES.includes(areaCode)) return 'AZ';
  if (TX_AREA_CODES.includes(areaCode)) return 'TX';
  if (CA_AREA_CODES.includes(areaCode)) return 'CA';
  return 'OTHER';
}
```

### Address Normalization

```javascript
function normalizeAddress(raw) {
  if (!raw || typeof raw !== 'string') return null;

  let address = raw.trim();

  // Standardize directionals
  const directionals = {
    'north': 'N', 'south': 'S', 'east': 'E', 'west': 'W',
    'northeast': 'NE', 'northwest': 'NW', 'southeast': 'SE', 'southwest': 'SW'
  };
  for (const [full, abbr] of Object.entries(directionals)) {
    address = address.replace(new RegExp(`\\b${full}\\b`, 'gi'), abbr);
  }

  // Standardize street suffixes
  const suffixes = {
    'street': 'St', 'avenue': 'Ave', 'boulevard': 'Blvd', 'drive': 'Dr',
    'lane': 'Ln', 'road': 'Rd', 'court': 'Ct', 'circle': 'Cir',
    'place': 'Pl', 'way': 'Way', 'trail': 'Trl', 'parkway': 'Pkwy'
  };
  for (const [full, abbr] of Object.entries(suffixes)) {
    address = address.replace(new RegExp(`\\b${full}\\b`, 'gi'), abbr);
  }

  // Parse components using regex
  // Expected: "1234 E Main St, Phoenix, AZ 85001" or variations
  const pattern = /^(.+?),\s*(.+?),?\s*([A-Z]{2})\s*(\d{5}(?:-\d{4})?)$/i;
  const match = address.match(pattern);

  if (match) {
    return {
      street: match[1].trim(),
      city: match[2].trim().replace(/\b\w/g, c => c.toUpperCase()),
      state: match[3].toUpperCase(),
      zip: match[4],
      full: `${match[1].trim()}, ${match[2].trim().replace(/\b\w/g, c => c.toUpperCase())}, ${match[3].toUpperCase()} ${match[4]}`,
      in_target_market: ['AZ', 'TX', 'CA'].includes(match[3].toUpperCase()),
      valid: true
    };
  }

  return {
    street: address,
    city: null,
    state: null,
    zip: null,
    full: address,
    in_target_market: false,
    valid: false
  };
}
```

### Name Normalization

```javascript
function normalizeName(raw) {
  if (!raw || typeof raw !== 'string') return { first_name: null, last_name: null };

  const cleaned = raw.trim().replace(/\s+/g, ' ');
  const parts = cleaned.split(' ');

  // Title case each part
  const titleCase = (s) => s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();

  if (parts.length === 1) {
    return { first_name: titleCase(parts[0]), last_name: null };
  }

  // Last token is last name, everything else is first name
  const lastName = titleCase(parts.pop());
  const firstName = parts.map(titleCase).join(' ');

  return { first_name: firstName, last_name: lastName };
}
```

### Email Normalization

```javascript
function normalizeEmail(raw) {
  if (!raw || typeof raw !== 'string') return { email: null, valid: false };

  const email = raw.trim().toLowerCase();
  const pattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

  return {
    email: email,
    valid: pattern.test(email)
  };
}
```

### Language Detection

```javascript
const SPANISH_INDICATORS = [
  'hola', 'casa', 'vender', 'quiero', 'necesito', 'rapido', 'dinero',
  'propiedad', 'precio', 'oferta', 'gracias', 'buenas', 'tengo',
  'recamara', 'bano', 'cocina', 'divorcio', 'herencia', 'familia',
  'esposo', 'esposa', 'hijo', 'hija', 'madre', 'padre',
  'por favor', 'ayuda', 'problema', 'urgente', 'inmediato',
  'hipoteca', 'deuda', 'credito', 'banco', 'pago'
];

function detectLanguage(text) {
  if (!text) return 'en';

  const lower = text.toLowerCase();
  const words = lower.split(/\s+/);
  let spanishCount = 0;

  for (const word of words) {
    if (SPANISH_INDICATORS.includes(word)) spanishCount++;
  }

  // If more than 15% of words are Spanish indicators, flag as Spanish
  const ratio = spanishCount / words.length;
  return ratio > 0.15 ? 'es' : 'en';
}
```

### Duplicate Detection

```javascript
function checkDuplicate(newLead, existingLeads) {
  for (const existing of existingLeads) {
    // Match 1: Same phone number
    if (newLead.phone && existing.phone && newLead.phone === existing.phone) {
      return {
        is_duplicate: true,
        matched_lead_id: existing.lead_id,
        match_type: 'phone',
        action: 'merge'
      };
    }

    // Match 2: Same address + last name
    if (
      newLead.property?.street && existing.property?.street &&
      newLead.seller?.last_name && existing.seller?.last_name &&
      normalizeForCompare(newLead.property.street) === normalizeForCompare(existing.property.street) &&
      newLead.seller.last_name.toLowerCase() === existing.seller.last_name.toLowerCase()
    ) {
      return {
        is_duplicate: true,
        matched_lead_id: existing.lead_id,
        match_type: 'address_lastname',
        action: 'merge'
      };
    }
  }

  return { is_duplicate: false };
}

function normalizeForCompare(str) {
  return str.toLowerCase().replace(/[^a-z0-9]/g, '');
}
```

### DNC Check

```javascript
function checkDNC(phone, dncList) {
  if (!phone) return { is_dnc: false };

  const digits = phone.replace(/\D/g, '');
  const isDNC = dncList.includes(digits);

  return {
    is_dnc: isDNC,
    action: isDNC ? 'block' : 'proceed'
  };
}
```

---

## Data Extraction from Unstructured Input

### Motivation Keyword Scanner

```javascript
const MOTIVATION_KEYWORDS = {
  // High motivation (15 points each)
  high: [
    'divorce', 'divorcing', 'divorcio',
    'foreclosure', 'pre-foreclosure', 'preforeclosure', 'ejecucion',
    'behind on payments', 'cant afford', 'no puedo pagar',
    'death', 'passed away', 'inherited', 'probate', 'herencia', 'fallecio',
    'relocating', 'job transfer', 'moving out of state', 'mudanza',
    'code violation', 'condemned', 'uninhabitable',
    'bankruptcy', 'bancarrota',
    'tax lien', 'tax delinquent', 'deuda de impuestos',
    'fire damage', 'flood damage', 'storm damage'
  ],
  // Medium motivation (10 points each)
  medium: [
    'tired landlord', 'bad tenants', 'tenant problems', 'inquilinos',
    'needs repairs', 'too much work', 'cant maintain', 'necesita reparaciones',
    'downsizing', 'retiring', 'retirement', 'jubilacion',
    'vacant', 'empty house', 'casa vacia',
    'out of state owner', 'absentee', 'ausente',
    'sell fast', 'quick sale', 'vender rapido', 'urgente',
    'health issues', 'medical bills', 'problemas de salud'
  ],
  // Low motivation (5 points each)
  low: [
    'just curious', 'thinking about', 'exploring options', 'considering',
    'how much', 'what would you offer', 'cuanto ofrecen',
    'not sure', 'maybe', 'tal vez'
  ]
};

function extractMotivation(text) {
  if (!text) return { keywords: [], score: 0, level: 'unknown' };

  const lower = text.toLowerCase();
  const found = [];
  let score = 0;

  for (const [level, keywords] of Object.entries(MOTIVATION_KEYWORDS)) {
    for (const keyword of keywords) {
      if (lower.includes(keyword)) {
        const points = level === 'high' ? 15 : level === 'medium' ? 10 : 5;
        found.push({ keyword, level, points });
        score += points;
      }
    }
  }

  // Cap motivation component at 30
  score = Math.min(score, 30);

  let level = 'cold';
  if (score >= 20) level = 'hot';
  else if (score >= 10) level = 'warm';

  return { keywords: found.map(f => f.keyword), score, level };
}
```

### Property Detail Extractor

```javascript
function extractPropertyDetails(text) {
  if (!text) return {};

  const details = {};

  // Beds
  const bedMatch = text.match(/(\d)\s*(?:bed|bedroom|bd|br|recamara|cuarto)/i);
  if (bedMatch) details.beds = parseInt(bedMatch[1]);

  // Baths
  const bathMatch = text.match(/(\d(?:\.\d)?)\s*(?:bath|bathroom|ba|bano)/i);
  if (bathMatch) details.baths = parseFloat(bathMatch[1]);

  // Sqft
  const sqftMatch = text.match(/([\d,]+)\s*(?:sq\s*ft|square\s*feet|sqft|sf)/i);
  if (sqftMatch) details.sqft = parseInt(sqftMatch[1].replace(',', ''));

  // Year built
  const yearMatch = text.match(/(?:built\s*(?:in\s*)?|year\s*built\s*:?\s*)(19\d{2}|20[0-2]\d)/i);
  if (yearMatch) details.year_built = parseInt(yearMatch[1]);

  // Price mentions
  const priceMatch = text.match(/\$\s*([\d,]+(?:\.\d{2})?)\s*(?:k|K)?/);
  if (priceMatch) {
    let price = parseFloat(priceMatch[1].replace(',', ''));
    if (priceMatch[0].match(/[kK]/)) price *= 1000;
    details.price_mentioned = price;
  }

  // Mortgage/owe
  const mortgageMatch = text.match(/(?:owe|mortgage|balance|hipoteca|deb[eo])\s*(?:about|around|approximately|aprox)?\s*\$?\s*([\d,]+)/i);
  if (mortgageMatch) {
    details.mortgage_balance = parseInt(mortgageMatch[1].replace(',', ''));
  }

  // Condition indicators
  const conditionBad = ['needs work', 'fixer', 'needs repair', 'tear down', 'gut rehab',
    'needs new roof', 'needs hvac', 'mold', 'fire damage', 'flood',
    'necesita reparaciones', 'mal estado'];
  const conditionFair = ['some repairs', 'dated', 'cosmetic', 'needs updating',
    'original', 'needs paint', 'regular'];
  const conditionGood = ['move in ready', 'updated', 'renovated', 'great condition',
    'good shape', 'bien cuidada', 'buen estado'];

  const lower = text.toLowerCase();
  if (conditionBad.some(c => lower.includes(c))) details.condition = 'poor';
  else if (conditionFair.some(c => lower.includes(c))) details.condition = 'fair';
  else if (conditionGood.some(c => lower.includes(c))) details.condition = 'good';
  else details.condition = 'unknown';

  // Occupancy
  if (/vacant|empty|desocupada|vacia/i.test(text)) details.occupancy = 'vacant';
  else if (/tenant|renter|rented|inquilino|rentada/i.test(text)) details.occupancy = 'tenant';
  else if (/live|living|owner.?occupied|vivo|habito/i.test(text)) details.occupancy = 'owner';
  else details.occupancy = 'unknown';

  return details;
}
```

### Contact Preference Extractor

```javascript
function extractContactPreferences(text) {
  if (!text) return { preferred_contact: 'sms', best_time: null };

  const lower = text.toLowerCase();
  const prefs = {};

  // Contact method
  if (/text|sms|mensaje/i.test(lower)) prefs.preferred_contact = 'sms';
  else if (/call|phone|llam[ae]/i.test(lower)) prefs.preferred_contact = 'call';
  else if (/email|correo/i.test(lower)) prefs.preferred_contact = 'email';
  else prefs.preferred_contact = 'sms'; // default

  // Time preferences
  if (/morning|manana|am\b|before noon/i.test(lower)) prefs.best_time = 'morning';
  else if (/afternoon|tarde|after lunch|after 12/i.test(lower)) prefs.best_time = 'afternoon';
  else if (/evening|night|noche|after 5|after 6|after work/i.test(lower)) prefs.best_time = 'evening';
  else prefs.best_time = null;

  // Decision makers
  const decisionMakers = [];
  if (/spouse|wife|husband|esposa?|marido/i.test(lower)) decisionMakers.push('spouse');
  if (/attorney|lawyer|abogado/i.test(lower)) decisionMakers.push('attorney');
  if (/family|familia|brother|sister|hermano|hermana/i.test(lower)) decisionMakers.push('family');
  prefs.decision_makers = decisionMakers;

  return prefs;
}
```

---

## Lead Source Tags

| Tag | Channel | Description |
|---|---|---|
| `fb_lead_form` | Facebook | Lead Ad form submission |
| `fb_messenger_lily` | Messenger | Conversation with Lily qualifier bot |
| `fb_messenger_adriana` | Messenger | Conversation with Adriana closer bot |
| `sms_inbound` | RingCentral | Seller-initiated SMS |
| `sms_outbound` | RingCentral | Response to our outbound SMS |
| `website_form` | Website | equitypathoffers.com form |
| `cold_call` | Smrtphone | Manual dialer outbound call |
| `propstream_list` | PropStream | Batch CSV list import |
| `ppc_google` | Google Ads | Google PPC landing page |
| `referral` | Manual | Word of mouth / partner referral |

### Source Override Logic

UTM parameters override the default channel source:
- `utm_source=google` + `utm_medium=cpc` -> `ppc_google`
- `utm_source=facebook` + `utm_medium=cpc` -> `fb_lead_form`
- `utm_source=referral` -> `referral`

---

## Initial Scoring (Pre-Scout Quick Score)

This is a fast triage score. Scout does the real underwriting later.

### Scoring Matrix

| Criteria | Points | Logic |
|---|---|---|
| Has property address | +20 | Can't do a deal without a property |
| Has phone number | +15 | Primary contact method |
| Has motivation indicator | +15 | From keyword scan |
| Responded to outreach | +10 | Inbound > scraped list |
| In target market (AZ/TX/CA) | +10 | We only operate in 3 states |
| Has financial info | +10 | Mortgage, equity, or asking price |
| Timeline mentioned | +10 | "Within 30 days", "ASAP", etc. |
| Has email | +5 | Secondary contact |
| Asking price mentioned | +5 | Shows seller engagement |
| **Maximum possible** | **100** | |

### Scoring Implementation

```javascript
function calculateInitialScore(lead) {
  let score = 0;
  const breakdown = {};

  // Has property address (+20)
  if (lead.property?.street) {
    score += 20;
    breakdown.has_address = 20;
  }

  // Has phone number (+15)
  if (lead.seller?.phone) {
    score += 15;
    breakdown.has_phone = 15;
  }

  // Has motivation indicator (+15)
  if (lead.initial_intel?.motivation_keywords?.length > 0) {
    score += 15;
    breakdown.has_motivation = 15;
  }

  // Responded to outreach (+10) - inbound sources only
  const inboundSources = ['fb_lead_form', 'fb_messenger_lily', 'fb_messenger_adriana',
    'sms_inbound', 'website_form', 'ppc_google'];
  if (inboundSources.includes(lead.source)) {
    score += 10;
    breakdown.inbound_response = 10;
  }

  // In target market (+10)
  if (['AZ', 'TX', 'CA'].includes(lead.property?.state)) {
    score += 10;
    breakdown.target_market = 10;
  }

  // Has financial info (+10)
  if (lead.initial_intel?.mortgage_balance || lead.initial_intel?.asking_price) {
    score += 10;
    breakdown.has_financial = 10;
  }

  // Timeline mentioned (+10)
  if (lead.initial_intel?.timeline) {
    score += 10;
    breakdown.has_timeline = 10;
  }

  // Has email (+5)
  if (lead.seller?.email) {
    score += 5;
    breakdown.has_email = 5;
  }

  // Asking price mentioned (+5)
  if (lead.initial_intel?.asking_price) {
    score += 5;
    breakdown.asking_price = 5;
  }

  // Grade assignment
  let grade, priority, next_action, assigned_to;

  if (score >= 70) {
    grade = 'A';
    priority = 'immediate';
    next_action = 'scout_underwrite';
    assigned_to = 'scout';
  } else if (score >= 50) {
    grade = 'B';
    priority = 'same_day';
    next_action = 'scout_underwrite';
    assigned_to = 'scout';
  } else if (score >= 30) {
    grade = 'C';
    priority = 'next_day';
    next_action = 'nurture';
    assigned_to = 'drip';
  } else {
    grade = 'D';
    priority = 'weekly';
    next_action = 'nurture';
    assigned_to = 'drip';
  }

  return {
    scoring: { initial_score: score, grade, priority, breakdown },
    routing: { next_action, assigned_to }
  };
}
```

---

## Output Schema

The normalized lead record. This is the contract between Lily and every downstream system.

```json
{
  "lead_id": "EP-20260326-0042",
  "source": "fb_lead_form",
  "created_at": "2026-03-26T14:30:00.000Z",
  "updated_at": "2026-03-26T14:30:00.000Z",
  "raw_input_hash": "sha256:abc123...",

  "seller": {
    "first_name": "Maria",
    "last_name": "Garcia",
    "phone": "9285551234",
    "phone_formatted": "(928) 555-1234",
    "phone_secondary": null,
    "email": "maria.garcia@email.com",
    "language": "es",
    "preferred_contact": "call",
    "best_time": "evening",
    "decision_makers": ["spouse"]
  },

  "property": {
    "address": "1234 E Main St",
    "city": "Phoenix",
    "state": "AZ",
    "zip": "85001",
    "full_address": "1234 E Main St, Phoenix, AZ 85001",
    "beds": 3,
    "baths": 2,
    "sqft": 1400,
    "year_built": 1985,
    "occupancy": "owner",
    "condition": "fair"
  },

  "initial_intel": {
    "motivation_keywords": ["divorce", "sell fast"],
    "motivation_level": "hot",
    "timeline": "within 30 days",
    "asking_price": 250000,
    "mortgage_balance": 120000,
    "estimated_equity": 130000,
    "situation_summary": "Divorcing, needs to sell 3/2 in Phoenix quickly. Property in fair condition, asking $250k with $120k mortgage."
  },

  "scoring": {
    "initial_score": 85,
    "grade": "A",
    "priority": "immediate",
    "breakdown": {
      "has_address": 20,
      "has_phone": 15,
      "has_motivation": 15,
      "inbound_response": 10,
      "target_market": 10,
      "has_financial": 10,
      "asking_price": 5
    }
  },

  "routing": {
    "next_action": "scout_underwrite",
    "assigned_to": "scout",
    "escalate_to_human": false,
    "escalation_reason": null
  },

  "flags": {
    "is_duplicate": false,
    "duplicate_lead_id": null,
    "is_dnc": false,
    "missing_critical": [],
    "language_detected": "es",
    "needs_translation": true,
    "data_quality_score": 0.92
  },

  "meta": {
    "normalized_by": "alex-intake-v1",
    "normalization_ms": 45,
    "source_raw_id": "fb_leadgen_987654321",
    "utm_source": null,
    "utm_medium": null,
    "utm_campaign": null
  }
}
```

### Lead ID Format

```
EP-YYYYMMDD-XXXX

EP        = Equity Path prefix
YYYYMMDD  = Date of lead creation
XXXX      = Sequential counter, zero-padded, resets daily
```

```javascript
function generateLeadId(date, dailyCounter) {
  const d = date || new Date();
  const dateStr = d.toISOString().slice(0, 10).replace(/-/g, '');
  const seq = String(dailyCounter).padStart(4, '0');
  return `EP-${dateStr}-${seq}`;
}
```

---

## n8n Code Node: Full Lead Normalization Function

This is the master function for an n8n Code node that processes any incoming lead through Lily.

```javascript
// n8n Code Node: Lily Lead Intake & Normalization
// Place this in a Code node after your webhook/trigger node

const input = $input.first().json;

// ============================================================
// CONFIGURATION
// ============================================================

const EP_PHONE_NUMBERS = {
  '9283209610': 'AZ',
  '2816402291': 'TX',
  '4244215535': 'CA'
};

// ============================================================
// HELPER FUNCTIONS (all defined above, consolidated here)
// ============================================================

function normalizePhone(raw) {
  if (!raw) return { phone: null, formatted: null, valid: false };
  let digits = raw.toString().replace(/\D/g, '');
  if (digits.length === 11 && digits.startsWith('1')) digits = digits.substring(1);
  if (digits.length !== 10) return { phone: null, formatted: null, valid: false, raw };

  const areaCode = digits.slice(0, 3);
  return {
    phone: digits,
    formatted: `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}`,
    area_code: areaCode,
    valid: true,
    detected_state: detectState(areaCode)
  };
}

function detectState(ac) {
  const AZ = ['480','520','602','623','928'];
  const TX = ['210','214','254','281','325','346','361','409','430','432','469','512','682','713','726','737','806','817','830','832','903','915','936','940','956','972','979'];
  const CA = ['209','213','310','323','341','350','408','415','424','442','510','530','559','562','619','626','628','650','657','661','669','707','714','747','760','805','818','831','858','909','916','925','949','951'];
  if (AZ.includes(ac)) return 'AZ';
  if (TX.includes(ac)) return 'TX';
  if (CA.includes(ac)) return 'CA';
  return 'OTHER';
}

function normalizeAddress(raw) {
  if (!raw) return null;
  let addr = raw.trim();
  const dirs = { 'north':'N','south':'S','east':'E','west':'W','northeast':'NE','northwest':'NW','southeast':'SE','southwest':'SW' };
  for (const [f, a] of Object.entries(dirs)) addr = addr.replace(new RegExp(`\\b${f}\\b`, 'gi'), a);
  const sfx = { 'street':'St','avenue':'Ave','boulevard':'Blvd','drive':'Dr','lane':'Ln','road':'Rd','court':'Ct','circle':'Cir','place':'Pl','way':'Way','trail':'Trl','parkway':'Pkwy' };
  for (const [f, a] of Object.entries(sfx)) addr = addr.replace(new RegExp(`\\b${f}\\b`, 'gi'), a);
  const m = addr.match(/^(.+?),\s*(.+?),?\s*([A-Z]{2})\s*(\d{5}(?:-\d{4})?)$/i);
  if (m) {
    return {
      street: m[1].trim(), city: m[2].trim().replace(/\b\w/g, c => c.toUpperCase()),
      state: m[3].toUpperCase(), zip: m[4],
      full: `${m[1].trim()}, ${m[2].trim().replace(/\b\w/g, c => c.toUpperCase())}, ${m[3].toUpperCase()} ${m[4]}`,
      in_target_market: ['AZ','TX','CA'].includes(m[3].toUpperCase()), valid: true
    };
  }
  return { street: addr, city: null, state: null, zip: null, full: addr, in_target_market: false, valid: false };
}

function normalizeName(raw) {
  if (!raw) return { first_name: null, last_name: null };
  const parts = raw.trim().replace(/\s+/g, ' ').split(' ');
  const tc = s => s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();
  if (parts.length === 1) return { first_name: tc(parts[0]), last_name: null };
  const last = tc(parts.pop());
  return { first_name: parts.map(tc).join(' '), last_name: last };
}

function normalizeEmail(raw) {
  if (!raw) return { email: null, valid: false };
  const email = raw.trim().toLowerCase();
  return { email, valid: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(email) };
}

function detectLanguage(text) {
  if (!text) return 'en';
  const indicators = ['hola','casa','vender','quiero','necesito','rapido','dinero','propiedad','precio','oferta','gracias','buenas','tengo','recamara','bano','divorcio','herencia','familia','esposo','esposa','hipoteca','deuda','por favor','ayuda','urgente'];
  const words = text.toLowerCase().split(/\s+/);
  let count = 0;
  for (const w of words) if (indicators.includes(w)) count++;
  return (count / words.length) > 0.15 ? 'es' : 'en';
}

function extractMotivation(text) {
  if (!text) return { keywords: [], score: 0, level: 'unknown' };
  const lower = text.toLowerCase();
  const high = ['divorce','foreclosure','pre-foreclosure','behind on payments','death','passed away','inherited','probate','relocating','job transfer','code violation','bankruptcy','tax lien','tax delinquent','fire damage','flood damage'];
  const med = ['tired landlord','bad tenants','needs repairs','cant maintain','downsizing','retiring','vacant','sell fast','quick sale','health issues','medical bills','out of state'];
  const lo = ['just curious','thinking about','exploring options','how much','not sure'];
  const found = [];
  let score = 0;
  for (const k of high) if (lower.includes(k)) { found.push(k); score += 15; }
  for (const k of med) if (lower.includes(k)) { found.push(k); score += 10; }
  for (const k of lo) if (lower.includes(k)) { found.push(k); score += 5; }
  score = Math.min(score, 30);
  return { keywords: found, score, level: score >= 20 ? 'hot' : score >= 10 ? 'warm' : 'cold' };
}

function extractPropertyDetails(text) {
  if (!text) return {};
  const d = {};
  const bedM = text.match(/(\d)\s*(?:bed|bedroom|bd|br|recamara)/i);
  if (bedM) d.beds = parseInt(bedM[1]);
  const bathM = text.match(/(\d(?:\.\d)?)\s*(?:bath|bathroom|ba|bano)/i);
  if (bathM) d.baths = parseFloat(bathM[1]);
  const sqM = text.match(/([\d,]+)\s*(?:sq\s*ft|square\s*feet|sqft|sf)/i);
  if (sqM) d.sqft = parseInt(sqM[1].replace(',', ''));
  const yrM = text.match(/(?:built\s*(?:in\s*)?|year\s*built\s*:?\s*)(19\d{2}|20[0-2]\d)/i);
  if (yrM) d.year_built = parseInt(yrM[1]);
  const prM = text.match(/\$\s*([\d,]+)/);
  if (prM) d.price_mentioned = parseInt(prM[1].replace(',', ''));
  const mtM = text.match(/(?:owe|mortgage|balance)\s*(?:about|around)?\s*\$?\s*([\d,]+)/i);
  if (mtM) d.mortgage_balance = parseInt(mtM[1].replace(',', ''));
  return d;
}

// ============================================================
// MAIN NORMALIZATION PIPELINE
// ============================================================

const source = input.source || 'unknown';
const allText = JSON.stringify(input).toLowerCase();

// Step 1: Normalize seller info
const nameData = normalizeName(input.name || input.full_name || input.sender_name || null);
const phoneData = normalizePhone(input.phone || input.phone_number || input.from || null);
const emailData = normalizeEmail(input.email || null);
const lang = detectLanguage(allText);

// Step 2: Normalize property
const addressData = normalizeAddress(
  input.address || input.property_address || input.street_address ||
  (input.extracted && input.extracted.address) || null
);

// Step 3: Extract intel from unstructured text
const freeText = input.notes || input.situation || input.text ||
  (input.transcript ? input.transcript.map(t => t.text).join(' ') : '') || '';

const motivation = extractMotivation(freeText);
const propDetails = extractPropertyDetails(freeText);
const extractedData = input.extracted || {};

// Step 4: Merge extracted + parsed
const beds = extractedData.beds || propDetails.beds || input.beds || null;
const baths = extractedData.baths || propDetails.baths || input.baths || null;
const sqft = propDetails.sqft || input.sqft || null;
const yearBuilt = propDetails.year_built || input.year_built || null;
const askingPrice = extractedData.asking_price || propDetails.price_mentioned || null;
const mortgageBalance = extractedData.mortgage_balance || propDetails.mortgage_balance || null;
const timeline = extractedData.timeline || input.timeline ||
  (freeText.match(/within\s+\d+\s+days|asap|immediately|soon|urgent/i) || [null])[0];

// Step 5: Build normalized lead
const lead = {
  lead_id: null, // assigned by Podio/system
  source: source,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),

  seller: {
    first_name: nameData.first_name,
    last_name: nameData.last_name,
    phone: phoneData.phone,
    phone_formatted: phoneData.formatted,
    email: emailData.email,
    language: lang,
    preferred_contact: 'sms',
    best_time: null,
    decision_makers: []
  },

  property: {
    address: addressData ? addressData.street : null,
    city: addressData ? addressData.city : null,
    state: addressData ? addressData.state : null,
    zip: addressData ? addressData.zip : null,
    full_address: addressData ? addressData.full : null,
    beds, baths, sqft, year_built: yearBuilt,
    occupancy: propDetails.occupancy || extractedData.occupancy || 'unknown',
    condition: propDetails.condition || extractedData.condition || 'unknown'
  },

  initial_intel: {
    motivation_keywords: motivation.keywords,
    motivation_level: motivation.level,
    timeline: timeline,
    asking_price: askingPrice,
    mortgage_balance: mortgageBalance,
    estimated_equity: (askingPrice && mortgageBalance) ? askingPrice - mortgageBalance : null,
    situation_summary: freeText.substring(0, 500)
  },

  scoring: { initial_score: 0, grade: 'D', priority: 'weekly' },
  routing: { next_action: 'nurture', assigned_to: 'drip', escalate_to_human: false },

  flags: {
    is_duplicate: false,
    is_dnc: false,
    missing_critical: [],
    language_detected: lang,
    needs_translation: lang === 'es',
    data_quality_score: 0
  },

  meta: {
    normalized_by: 'alex-intake-v1',
    normalization_ms: Date.now(),
    source_raw_id: input.leadgen_id || input.sender_id || null,
    utm_source: input.utm_source || null,
    utm_medium: input.utm_medium || null,
    utm_campaign: input.utm_campaign || null
  }
};

// Step 6: Score
let score = 0;
if (lead.property.address) score += 20;
if (lead.seller.phone) score += 15;
if (lead.initial_intel.motivation_keywords.length > 0) score += 15;
const inbound = ['fb_lead_form','fb_messenger_lily','fb_messenger_adriana','sms_inbound','website_form','ppc_google'];
if (inbound.includes(source)) score += 10;
if (['AZ','TX','CA'].includes(lead.property.state)) score += 10;
if (lead.initial_intel.mortgage_balance || lead.initial_intel.asking_price) score += 10;
if (lead.initial_intel.timeline) score += 10;
if (lead.seller.email) score += 5;
if (lead.initial_intel.asking_price) score += 5;

lead.scoring.initial_score = score;
lead.scoring.grade = score >= 70 ? 'A' : score >= 50 ? 'B' : score >= 30 ? 'C' : 'D';
lead.scoring.priority = score >= 70 ? 'immediate' : score >= 50 ? 'same_day' : score >= 30 ? 'next_day' : 'weekly';

// Step 7: Route
if (score >= 50) {
  lead.routing = { next_action: 'scout_underwrite', assigned_to: 'scout', escalate_to_human: false };
} else if (score >= 30) {
  lead.routing = { next_action: 'nurture', assigned_to: 'drip', escalate_to_human: false };
} else {
  lead.routing = { next_action: 'nurture', assigned_to: 'drip', escalate_to_human: false };
}

// Step 8: Flag missing critical fields
const missing = [];
if (!lead.seller.phone) missing.push('phone');
if (!lead.property.address) missing.push('property_address');
if (!lead.seller.first_name) missing.push('seller_name');
lead.flags.missing_critical = missing;

// Step 9: Data quality score
let quality = 0;
const fields = [
  lead.seller.first_name, lead.seller.last_name, lead.seller.phone,
  lead.seller.email, lead.property.address, lead.property.city,
  lead.property.state, lead.property.zip, lead.property.beds,
  lead.property.baths, lead.initial_intel.asking_price
];
for (const f of fields) if (f) quality++;
lead.flags.data_quality_score = parseFloat((quality / fields.length).toFixed(2));

// Finalize timing
lead.meta.normalization_ms = Date.now() - lead.meta.normalization_ms;

return lead;
```

---

## Podio Field Mapping

Map the normalized lead record to Podio CRM fields in the Leads app.

| Normalized Field | Podio Field | Podio Field Type | Notes |
|---|---|---|---|
| `lead_id` | Lead ID | Text | Auto-generated, unique |
| `source` | Lead Source | Category | Dropdown matching source tags |
| `created_at` | Created Date | Date | ISO -> Podio date |
| `seller.first_name` | First Name | Text | |
| `seller.last_name` | Last Name | Text | |
| `seller.phone` | Phone | Phone | Store as 10 digits |
| `seller.phone_secondary` | Phone 2 | Phone | From PropStream phone2 |
| `seller.email` | Email | Email | |
| `seller.language` | Language | Category | en, es |
| `seller.preferred_contact` | Preferred Contact | Category | sms, call, email |
| `property.full_address` | Property Address | Text | Full formatted address |
| `property.city` | City | Text | |
| `property.state` | State | Category | AZ, TX, CA |
| `property.zip` | Zip Code | Text | |
| `property.beds` | Beds | Number | |
| `property.baths` | Baths | Number | |
| `property.sqft` | Sq Ft | Number | |
| `property.year_built` | Year Built | Number | |
| `property.occupancy` | Occupancy | Category | owner, tenant, vacant, unknown |
| `property.condition` | Condition | Category | good, fair, poor, unknown |
| `initial_intel.motivation_keywords` | Motivation Tags | Text | Comma-joined |
| `initial_intel.motivation_level` | Motivation Level | Category | hot, warm, cold |
| `initial_intel.timeline` | Timeline | Text | |
| `initial_intel.asking_price` | Asking Price | Money | |
| `initial_intel.mortgage_balance` | Mortgage Balance | Money | |
| `initial_intel.estimated_equity` | Est. Equity | Calculation | asking - mortgage |
| `initial_intel.situation_summary` | Situation Notes | Text (multi-line) | First 500 chars |
| `scoring.initial_score` | Lily Score | Number | 0-100 |
| `scoring.grade` | Grade | Category | A, B, C, D |
| `scoring.priority` | Priority | Category | immediate, same_day, next_day, weekly |
| `routing.next_action` | Next Action | Category | scout_underwrite, human_call, nurture, dnc |
| `routing.assigned_to` | Assigned To | Contact | scout, carlos, drip |
| `flags.is_duplicate` | Is Duplicate | Category | yes, no |
| `flags.is_dnc` | DNC Flag | Category | yes, no |
| `flags.language_detected` | Language Detected | Category | en, es |

### Podio Integration Code (n8n HTTP Request node)

```javascript
// n8n Code Node: Map normalized lead to Podio API format
const lead = $input.first().json;

// Podio app configuration (set these in n8n credentials)
const PODIO_APP_ID = $env.PODIO_LEADS_APP_ID;

// Field IDs (replace with actual Podio field IDs from your app)
const FIELDS = {
  lead_id: 'lead-id',
  source: 'lead-source',
  first_name: 'first-name',
  last_name: 'last-name',
  phone: 'phone',
  email: 'email-address',
  language: 'language',
  property_address: 'property-address',
  city: 'city',
  state: 'state',
  zip: 'zip-code',
  beds: 'beds',
  baths: 'baths',
  sqft: 'sq-ft',
  year_built: 'year-built',
  occupancy: 'occupancy',
  condition: 'condition',
  motivation_tags: 'motivation-tags',
  motivation_level: 'motivation-level',
  timeline: 'timeline',
  asking_price: 'asking-price',
  mortgage_balance: 'mortgage-balance',
  situation_notes: 'situation-notes',
  alex_score: 'alex-score',
  grade: 'grade',
  priority: 'priority',
  next_action: 'next-action',
  assigned_to: 'assigned-to',
  is_duplicate: 'is-duplicate',
  is_dnc: 'dnc-flag'
};

// Build Podio item
const podioItem = {
  fields: {
    [FIELDS.lead_id]: lead.lead_id,
    [FIELDS.source]: lead.source,
    [FIELDS.first_name]: lead.seller.first_name || '',
    [FIELDS.last_name]: lead.seller.last_name || '',
    [FIELDS.phone]: [{ type: 'mobile', value: lead.seller.phone_formatted || '' }],
    [FIELDS.email]: [{ type: 'other', value: lead.seller.email || '' }],
    [FIELDS.property_address]: lead.property.full_address || '',
    [FIELDS.city]: lead.property.city || '',
    [FIELDS.state]: lead.property.state || '',
    [FIELDS.zip]: lead.property.zip || '',
    [FIELDS.beds]: lead.property.beds,
    [FIELDS.baths]: lead.property.baths,
    [FIELDS.sqft]: lead.property.sqft,
    [FIELDS.asking_price]: lead.initial_intel.asking_price,
    [FIELDS.mortgage_balance]: lead.initial_intel.mortgage_balance,
    [FIELDS.situation_notes]: lead.initial_intel.situation_summary,
    [FIELDS.alex_score]: lead.scoring.initial_score,
    [FIELDS.motivation_tags]: lead.initial_intel.motivation_keywords.join(', '),
    [FIELDS.timeline]: lead.initial_intel.timeline || ''
  }
};

return { json: podioItem, lead_id: lead.lead_id };
```

---

## Integration Flow: Lily -> Scout -> Adriana

### Pipeline Handoff Protocol

```
┌─────────────────────────────────────────────────────────┐
│                    ALEX (this agent)                     │
│                                                         │
│  1. Receive raw lead from any channel                   │
│  2. Normalize all fields                                │
│  3. Score (0-100) and grade (A/B/C/D)                  │
│  4. Check duplicates and DNC                            │
│  5. Create/update Podio record                          │
│  6. Route to next step                                  │
│                                                         │
│  OUTPUT → Normalized lead record (schema above)         │
└──────────────┬──────────────────────────────────────────┘
               │
               │  Grade A/B → immediate/same_day
               │
┌──────────────▼──────────────────────────────────────────┐
│                    SCOUT (underwriting)                  │
│                                                         │
│  INPUT ← Lily's normalized lead record                  │
│                                                         │
│  1. Pull comps from PropStream API                      │
│  2. Calculate ARV (After Repair Value)                  │
│  3. Estimate repairs                                    │
│  4. Run MAO formula: (ARV x 0.70) - Repairs            │
│  5. Calculate assignment fee potential                   │
│  6. Score deal viability                                │
│  7. Flag novation candidates                            │
│                                                         │
│  OUTPUT → Underwriting package with MAO + deal score    │
└──────────────┬──────────────────────────────────────────┘
               │
               │  Viable deal → disposition
               │
┌──────────────▼──────────────────────────────────────────┐
│                    RYAN (disposition)                    │
│                                                         │
│  INPUT ← Scout's underwriting package                   │
│                                                         │
│  1. Match to cash buyer list                            │
│  2. Generate deal summary for buyers                    │
│  3. Send to buyer network                               │
│  4. Track buyer interest/offers                         │
│  5. Manage assignment or double-close                   │
│                                                         │
│  OUTPUT → Closed deal or recycled lead                  │
└─────────────────────────────────────────────────────────┘
```

### Routing Decision Matrix

| Grade | Score | Priority | Lily Routes To | Trigger |
|---|---|---|---|---|
| A | 70-100 | immediate | Scout (auto-underwrite) | n8n webhook fires instantly |
| B | 50-69 | same_day | Scout (queue) | Batched every 4 hours |
| C | 30-49 | next_day | Drip campaign (WF08) | Added to 90-day nurture |
| D | 0-29 | weekly | Database | Stored, no active outreach |
| DNC | any | block | None | Lead blocked, logged only |
| Duplicate | any | merge | Update existing | Merge new data into existing lead |

### n8n Workflow Trigger Configuration

Lily is triggered by these n8n workflow entry points:

| Workflow | Trigger Node | Source |
|---|---|---|
| WF07b | Webhook | Facebook Lead Form (Meta webhook) |
| WF06 | Webhook | Messenger Bot (Lily/Adriana transcript) |
| WF-SMS | Webhook | RingCentral inbound SMS |
| WF-Web | Webhook | Website form submission |
| WF-Call | Manual/Webhook | Cold call notes (Smrtphone) |
| WF-Import | Schedule/Manual | PropStream CSV batch (daily/weekly) |

### Escalation to Human

Lily escalates to Carlos (human) when:

```javascript
const shouldEscalate = (lead) => {
  // Escalation triggers
  if (lead.scoring.grade === 'A' && lead.initial_intel.motivation_level === 'hot') return true;
  if (lead.initial_intel.asking_price && lead.initial_intel.mortgage_balance &&
      lead.initial_intel.asking_price < lead.initial_intel.mortgage_balance) return true; // underwater
  if (lead.flags.missing_critical.length === 0 && lead.scoring.initial_score >= 80) return true;
  if (lead.initial_intel.motivation_keywords.includes('foreclosure')) return true;
  if (lead.initial_intel.motivation_keywords.includes('probate')) return true;
  return false;
};
```

When escalating, Lily sends a Slack/SMS notification to Carlos with a one-line summary:

```
NEW HOT LEAD [A-85]: Maria Garcia, 1234 E Main St Phoenix AZ - Divorce, asking $250k, owes $120k. Call after 5pm (Spanish).
```

---

## Error Handling

### Missing Data Strategy

| Missing Field | Impact | Action |
|---|---|---|
| Phone | Critical | Flag, still create record, route to manual lookup |
| Address | Critical | Flag, still create record, attempt extraction from other fields |
| Name | Non-critical | Use "Unknown" + source identifier |
| Email | Non-critical | Skip, proceed with phone-based outreach |
| Financial info | Scoring impact | Score lower, Scout will research |

### Malformed Input Recovery

```javascript
function safeProcess(input) {
  try {
    return normalizeLeadRecord(input);
  } catch (error) {
    // Return a minimal record so the lead is not lost
    return {
      lead_id: null,
      source: input.source || 'unknown',
      created_at: new Date().toISOString(),
      seller: { first_name: null, last_name: null, phone: null, email: null },
      property: { address: null, city: null, state: null, zip: null },
      initial_intel: { motivation_keywords: [], situation_summary: '' },
      scoring: { initial_score: 0, grade: 'D', priority: 'weekly' },
      routing: { next_action: 'manual_review', assigned_to: 'carlos' },
      flags: {
        missing_critical: ['parse_error'],
        error_message: error.message,
        raw_input: JSON.stringify(input).substring(0, 1000)
      }
    };
  }
}
```

### Rate Limits & Batching

- **Facebook Lead Forms**: Process immediately (real-time webhook)
- **Messenger Bots**: Process immediately (conversation end trigger)
- **SMS**: Process immediately (inbound webhook)
- **Website Forms**: Process immediately (form webhook)
- **Cold Calls**: Process within 15 minutes (batch on schedule)
- **PropStream Imports**: Batch process 100 records/minute to avoid Podio API limits
- **Podio API**: Max 250 requests/hour per app token. Use batch endpoints where possible.

---

## Version History

| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-03-26 | Initial release: 7 channels, scoring, Podio mapping |
