# Compliance Guide — Wholesale Real Estate Automation

All compliance requirements for SMS, voice, email, and advertising automation.

---

## 1. SMS Compliance (TCPA + 10DLC)

### TCPA Requirements

| Rule | Detail |
|------|--------|
| Consent type | Prior Express Written Consent (PEWC) for marketing messages |
| Consent scope | One-to-one — one brand per consent form |
| Time window | 8am-8pm recipient's local time (some states allow 9pm) |
| Frequency | Max 3 texts per 24-hour period (best practice) |
| Opt-out keywords | Must honor: STOP, CANCEL, UNSUBSCRIBE, END, QUIT |
| Opt-out processing | Within 10 business days (best practice: immediate) |
| Record retention | Keep consent records 4+ years |
| Penalties | $500 per violation, $1,500 per willful violation |

### 10DLC Registration (Mandatory Since Feb 1, 2025)

**Unregistered numbers are BLOCKED by carriers.**

#### Step 1: Brand Registration
- Register business entity with The Campaign Registry (TCR)
- Provide: EIN, legal name, address, website
- One-time vetting fee: $15
- Auth+ vetting: $12.50/brand (mandatory from Aug 2025)
- Processing: minutes to 2 days
- Trust score assigned (determines throughput limits)

#### Step 2: Campaign Registration
- Register each messaging use case
- Define: message samples, opt-in flow, use case description
- Campaign vetting: $30/quarter per campaign
- Processing: 3-7 business days
- Carrier approval required

#### Step 3: Number Association
- Link registered phone numbers to campaign
- Carriers enable messaging throughput
- Test before going live

#### Throughput Limits by Trust Score

| Trust Score | T-Mobile Daily Cap | AT&T Throughput |
|-------------|-------------------|-----------------|
| Low | ~2,000 msgs/day | 1 msg/second |
| Medium | ~10,000 msgs/day | 4 msgs/second |
| High | ~200,000 msgs/day | 75 msgs/second |

### Required Opt-In Disclosure Language

```
"By providing your phone number, you agree to receive text messages
from Equity Path Offers regarding your property inquiry. Message
frequency varies. Message and data rates may apply. Reply STOP to
unsubscribe. Reply HELP for help."
```

### Every First SMS Must Include
- Business name identification
- Opt-out instructions (Reply STOP to opt out)
- No misleading content

### State-Specific Mini-TCPA Laws

| State | Additional Requirement |
|-------|----------------------|
| Florida | Written consent required; enhanced TCPA+ restrictions |
| Oklahoma | Stricter opt-in requirements |
| Washington | Enhanced consent documentation |
| Michigan | Additional texting campaign restrictions |
| Arizona | No state-specific additions beyond federal TCPA |
| Texas | Texas Business & Commerce Code additional protections |
| California | CCPA applies to lead data; enhanced privacy requirements |

---

## 2. AI Voice Call Compliance (TCPA)

### FCC Ruling (Effective Jan 27, 2025)

AI-generated voices are classified as **"artificial or prerecorded voice"** under TCPA.

| Requirement | Detail |
|-------------|--------|
| Consent | Prior Express Written Consent (PEWC) BEFORE any AI call |
| Scope | Consent must name YOUR specific company |
| One-to-one | Cannot use aggregated/shared lead consent |
| Disclosure | Must disclose AI/automated technology at start of call |
| Identity | Must identify yourself and company at call start |
| Hours | 8am-9pm recipient's local time only |
| Opt-out | Must allow opt-out during every call |
| DNC | Must check national + state Do Not Call lists before calling |
| State registration | Register with state telemarketing registries |
| Penalties | $500 per violation, $1,500 per willful violation |

### AI Voice Call Compliance Checklist

```
PRE-CALL:
[ ] Prior Express Written Consent obtained
[ ] Consent names Equity Path Offers specifically
[ ] Consent is one-to-one (not shared/aggregated)
[ ] Number checked against national DNC list
[ ] Number checked against state DNC lists (AZ, TX, CA)
[ ] Calling within allowed hours (8am-9pm local time)
[ ] State telemarketing registration current

DURING CALL:
[ ] Company identified at start
[ ] AI/automated technology disclosed
[ ] Opt-out option provided
[ ] No misleading claims

POST-CALL:
[ ] Call logged with timestamp and duration
[ ] Consent record linked to call
[ ] Opt-out requests processed immediately
[ ] Recording stored per state requirements
```

---

## 3. Facebook Ads Compliance (Housing Special Ad Category)

### Mandatory Requirements

**All real estate ads MUST select Housing Special Ad Category.**
Violations = ad rejection, account suspension, or legal action (per 2022 HUD/Meta settlement).

### Targeting Restrictions

| Feature | Status | Detail |
|---------|--------|--------|
| Age targeting | BANNED | Cannot target by age |
| Gender targeting | BANNED | Cannot target by gender |
| ZIP code targeting | BANNED | Cannot use ZIP codes |
| Income targeting | BANNED | Cannot target by income |
| Radius targeting | LIMITED | Minimum 15-mile radius (US) |
| City targeting | ALLOWED | Can target by city name |
| Interest targeting | LIMITED | Many interests removed |
| Lookalike audiences | BANNED | Use Special Ad Audiences instead |

### What Still Works
- Geo-targeting by city and radius (15-mile minimum)
- Special Ad Audiences (Meta's compliant alternative to lookalikes)
- Creative qualification — ad copy filters for motivated sellers
- Broad targeting + strong creative — let Meta's algorithm optimize
- Retargeting website visitors with custom audiences (pixel-based)

### Ad Content Requirements
- No discriminatory content
- No false or misleading claims
- Must clearly identify as advertisement
- Landing page must match ad claims

---

## 4. Email Compliance (CAN-SPAM + State Laws)

### CAN-SPAM Requirements

| Rule | Detail |
|------|--------|
| From line | Must accurately identify sender |
| Subject line | Must reflect message content (no misleading subjects) |
| Physical address | Must include valid physical postal address |
| Opt-out mechanism | Must include clear unsubscribe link |
| Opt-out processing | Within 10 business days |
| No purchased lists | Don't email purchased/rented email lists without consent |
| Header info | Must not use false/misleading header information |

### Best Practices
- Honor unsubscribe requests immediately (don't wait 10 days)
- Don't make unsubscribe difficult (no login required, no multi-step)
- Identify promotional emails clearly
- Track bounces and remove invalid addresses
- Keep email logs with consent records

---

## 5. DNC (Do Not Call) List Management

### Federal DNC
- Access via donotcall.gov
- Must scrub lists within 31 days of campaign
- Re-scrub at least every 31 days
- Maintain internal DNC list of all opt-outs

### State DNC Lists
- Arizona: No state DNC (uses federal only)
- Texas: Texas No Call List (register at texasnocall.com)
- California: No state DNC (uses federal only)

### Internal DNC Management

```javascript
// DNC check in n8n Code node
const dncList = await this.helpers.httpRequest({
  method: 'GET',
  url: 'https://your-api/dnc-list'
});

const phoneClean = phone.replace(/\D/g, '');
const isOnDNC = dncList.some(entry => entry.phone === phoneClean);

if (isOnDNC) {
  return [{ json: { skip: true, reason: 'DNC', phone } }];
}
```

---

## 6. Data Privacy (CCPA — California)

Since Equity Path Offers operates in California, CCPA applies.

| Requirement | Detail |
|-------------|--------|
| Right to know | Sellers can ask what data you have on them |
| Right to delete | Must delete personal data on request |
| Right to opt-out | Must offer opt-out of data sale |
| Notice at collection | Must disclose what data you collect and why |
| Privacy policy | Must have accessible privacy policy |

### Data Retention Best Practices
- Only collect data needed for the transaction
- Delete lead data after 4 years (matches TCPA retention)
- Encrypt sensitive data at rest
- Log all data access for audit trail
- Have a documented data breach response plan

---

## 7. Compliance Automation in n8n

### Automated Compliance Checks

```
Lead enters system:
  → Check DNC (national + state + internal)
  → Verify opt-in consent exists and is documented
  → Check timezone for calling/texting hours
  → Apply frequency limits (max 3 SMS/day)
  → Log all outreach with timestamps

Before any outreach:
  → Re-verify DNC status
  → Check time window (8am-8pm/9pm local)
  → Verify consent still valid
  → Check frequency limits not exceeded
  → Include required disclosures (business name, STOP)

After opt-out received:
  → Immediately add to internal DNC
  → Stop all active drip campaigns
  → Confirm removal to seller
  → Log opt-out with timestamp
  → Retain record for audit (4 years)
```

### n8n Compliance Node Pattern

```javascript
// Compliance gate — runs before every outreach
const lead = $input.first().json;
const now = new Date();

// 1. DNC check
if (lead.on_dnc === true) {
  return [{ json: { blocked: true, reason: 'DNC list' } }];
}

// 2. Time window check (8am-8pm local)
const localHour = getLocalHour(now, lead.timezone);
if (localHour < 8 || localHour >= 20) {
  return [{ json: { blocked: true, reason: 'Outside calling hours', retry_after: nextAllowedTime(lead.timezone) } }];
}

// 3. Frequency check (max 3 SMS/day)
const todayTouches = lead.touches_today || 0;
if (todayTouches >= 3) {
  return [{ json: { blocked: true, reason: 'Daily frequency limit reached' } }];
}

// 4. Consent check
if (!lead.consent_timestamp) {
  return [{ json: { blocked: true, reason: 'No consent on file' } }];
}

// All clear
return [{ json: { ...lead, compliance_cleared: true, checked_at: now.toISOString() } }];
```
