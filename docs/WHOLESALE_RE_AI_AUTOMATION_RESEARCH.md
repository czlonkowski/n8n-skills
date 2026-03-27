# Wholesale Real Estate AI Automation Research Report

**Compiled:** March 2026
**Purpose:** Best practices for AI-powered wholesale real estate automation
**For:** Claude Code skill development

---

## Table of Contents

1. [AI Lead Scoring for Real Estate](#1-ai-lead-scoring-for-real-estate)
2. [Facebook Ads for Wholesale Real Estate](#2-facebook-ads-for-wholesale-real-estate)
3. [Google PPC for Wholesale Real Estate](#3-google-ppc-for-wholesale-real-estate)
4. [AI Voice Calling for Real Estate](#4-ai-voice-calling-for-real-estate)
5. [Novation Deal Process (Rainmaker Method)](#5-novation-deal-process-rainmaker-method)
6. [SMS Compliance](#6-sms-compliance)
7. [Cash Buyer List Building](#7-cash-buyer-list-building)
8. [CRM Automation for Wholesalers](#8-crm-automation-for-wholesalers)
9. [n8n Workflow Patterns for Real Estate](#9-n8n-workflow-patterns-for-real-estate)
10. [Seller Outreach Scripts](#10-seller-outreach-scripts)

---

## 1. AI Lead Scoring for Real Estate

### Core Data Points That Matter Most

#### Tier 1: High-Weight Signals (Strongest Predictors)
| Signal | Why It Matters | Data Source |
|--------|---------------|-------------|
| **Equity %** | Higher equity = more negotiation flexibility, ability to sell below market | PropStream, county records |
| **Pre-foreclosure / NOD** | Imminent distress, time pressure | Public filings, PropStream |
| **Tax delinquency** | Financial stress, motivation to liquidate | County tax records |
| **Code violations** | Property burden, potential fines escalating | Municipal records |
| **Liens / judgments** | Legal/financial pressure to sell | Court records, title searches |
| **Vacant property** | No occupant = less emotional attachment, faster close | USPS vacancy data, utility records |

#### Tier 2: Medium-Weight Signals
| Signal | Why It Matters | Data Source |
|--------|---------------|-------------|
| **Absentee ownership** | Out-of-state = tired landlord, management burden | County records, PropStream |
| **Ownership duration (10+ years)** | Tired owners, deferred maintenance likely | County records |
| **Inherited / probate** | Often want quick liquidation, emotional burden | Court records |
| **Divorce filing** | Forced sale situation, timeline pressure | Court records |
| **Failed listing (expired MLS)** | Already tried retail, more open to investor offer | MLS data |
| **Property condition** | Deferred maintenance = lower ARV gap, more motivated | Visual inspection, satellite imagery |

#### Tier 3: Behavioral & Life-Event Signals
| Signal | Why It Matters | Data Source |
|--------|---------------|-------------|
| **Job relocation** | Timeline pressure, dual housing costs | LinkedIn changes, employer data |
| **Retirement** | Downsizing motivation | Age/demographic data |
| **Late-night browsing patterns** | Urgency/stress indicator | Web analytics (for inbound leads) |
| **Repeated engagement with ads** | Active consideration phase | Facebook/Google pixel data |
| **Response speed to outreach** | Faster response = higher motivation | CRM tracking |

### Scoring Models

#### Rule-Based Scoring (Recommended Starting Point)
```
LEAD SCORE = SUM of weighted signals (0-100 scale)

Equity > 40%:           +20 points
Pre-foreclosure:        +25 points
Tax delinquent:         +20 points
Vacant:                 +15 points
Absentee owner:         +10 points
Code violations:        +15 points
Liens/judgments:        +15 points
Ownership 10+ years:    +10 points
Inherited/probate:      +20 points
Expired listing:        +15 points
Responded to outreach:  +10 points
Timeline < 30 days:     +15 points

GRADE:
A (Hot):    75-100 — Immediate follow-up, multiple touches
B (Warm):   50-74  — Active nurture, weekly contact
C (Nurture): 25-49 — Drip campaign, monthly contact
D (Cold):   0-24   — Database only, quarterly touch
```

#### ML-Based Scoring Platforms
- **Leadflow Smart Score**: Analyzes dozens of signals (equity, absentee, tax delinquency, pre-foreclosure)
- **Offrs Seller Score**: 250+ data points per property (ownership duration, mortgage status, market trends)
- **BatchRank (BatchLeads)**: 800+ data points with ML algorithms
- **DataFlik**: 1,800+ individual signals including behavioral patterns
- **REsimpli**: Built-in lead scoring with automated grading

### ABCD Qualification Framework
- **A = Ability**: Can they sell? (equity, title clear, authority)
- **B = Believability**: Do they believe you can help? (rapport, credibility)
- **C = Condition**: What shape is the property in? (repairs needed, ARV gap)
- **D = Desire/Distress**: How motivated are they? (timeline, pain points)

Sources:
- [AI for Wholesaling Real Estate - RealEstateSkills](https://www.realestateskills.com/blog/ai-for-wholesaling-real-estate-guide)
- [Real Estate Lead Scoring - REsimpli](https://resimpli.com/blog/real-estate-lead-scoring/)
- [AI Lead Scoring for Real Estate - Reform](https://www.reform.app/blog/ai-lead-scoring-for-real-estate-how-it-works)
- [AI In Real Estate - BatchLeads](https://batchleads.io/blog/ai-in-real-estate-find-motivated-seller-leads-faster-with-batchleads)
- [AI Seller Lead Scoring - Fello](https://fello.ai/academy/why-73-of-top-producing-brokerages-are-investing-in-ai-seller-lead-scoring-now)

---

## 2. Facebook Ads for Wholesale Real Estate

### Housing Special Ad Category Compliance (Mandatory)

#### What You MUST Do
- Select **"Housing"** in Special Ad Category for ALL real estate ads
- This is required under the 2022 HUD/Meta settlement
- Violations can result in ad rejection, account suspension, or legal action

#### Targeting Restrictions Under Special Ad Category
| Feature | Restricted? | Details |
|---------|------------|---------|
| Age targeting | YES | Cannot target by age |
| Gender targeting | YES | Cannot target by gender |
| ZIP code targeting | YES | Banned entirely |
| Income targeting | YES | Cannot target by income |
| Radius targeting | LIMITED | Minimum 15-mile radius in US |
| City targeting | ALLOWED | Can target by city name |
| Interest targeting | LIMITED | Many interests removed |
| Lookalike audiences | BANNED | Replaced by "Special Ad Audiences" |

#### What Still Works
- **Geo-targeting by radius** (minimum 15 miles) and city
- **Special Ad Audiences** (Meta's compliant alternative to lookalikes)
- **Creative qualification** — use ad content itself to filter for motivated sellers
- **Broad targeting + strong creative** — let Meta's algorithm find the right people

### Best Performing Ad Types

1. **Video ads**: Properties with video receive 403% more inquiries
2. **Lead form ads (Meta Instant Forms)**: Lower friction, higher conversion
3. **Carousel ads**: Show multiple properties or before/after scenarios
4. **Testimonial/social proof ads**: Seller success stories

### Ad Copy That Converts for "We Buy Houses"

**Effective angles:**
- Speed/convenience: "Close in as little as 7 days"
- No repairs needed: "Sell as-is, no cleaning or fixing required"
- Cash offer: "Get a fair cash offer in 24 hours"
- No fees: "No agent commissions, no closing costs"
- Problem-solving: "Behind on payments? Facing foreclosure? We can help"

### Cost Benchmarks (2025-2026)

| Metric | Average | Range |
|--------|---------|-------|
| **CPC** | $1.17 | $0.50 - $3.00 |
| **CPL (general)** | $16.61 | $5 - $40 |
| **CPL (motivated sellers)** | $25-$60 | Market dependent |
| **Conversion rate** | 10.67% | 5% - 15% |
| **CPA** | $16.92 | Varies by market |

**Market tier breakdown:**
- Tier 1 (NYC, LA, Miami): $35-$65 CPL
- Tier 2 (Austin, Denver, Nashville): $20-$45 CPL
- Tier 3 (Rural, small metro): $8-$20 CPL

### Targeting Strategy for Motivated Sellers

1. **Start broad** with city-level geo targeting (15-mile minimum radius)
2. **Let creative qualify** — messaging should speak directly to distressed situations
3. **Use Meta's algorithm** — broad targeting with good creative outperforms manual targeting
4. **Retarget website visitors** with custom audiences (pixel-based)
5. **Special Ad Audiences** based on your existing customer list
6. **Start with $10-$20/day** to gather data, scale what works

### CPC Trend Alert
Real Estate CPC on Facebook **rose 33%** from January 2025 to January 2026, while global benchmarks declined 25%.

Sources:
- [Meta Housing Ads 2026 Geo-Targeting Guide](https://mediastrobe.medium.com/meta-housing-ads-2026-the-complete-guide-to-geo-targeting-under-special-ad-category-restrictions-c008de7252ca)
- [Facebook Ads for Real Estate - FetchFunnel](https://www.fetchfunnel.com/facebook-ads-for-real-estate/)
- [Facebook Ads CPC Benchmarks - SuperAds](https://www.superads.ai/facebook-ads-costs/cpc-cost-per-click/real-estate)
- [Facebook Ads for Real Estate - Koro](https://getkoro.app/blog/facebook-ads-for-real-estate)
- [Facebook Ads for Motivated Sellers - REIKit](https://www.reikit.com/wholesaling-houses/marketing/guide-to-facebook-ads-for-motivated-seller-leads)
- [Facebook Ad Metrics 2025 - ContempoThemes](https://contempothemes.com/facebook-ad-metrics-for-real-estate-2025/)

---

## 3. Google PPC for Wholesale Real Estate

### Keywords That Convert

#### High-Intent Seller Keywords (Most Expensive, Highest Quality)
| Keyword | Avg CPC | Intent Level |
|---------|---------|-------------|
| "sell my house fast [city]" | $30-$36+ | Extremely high |
| "we buy houses [city]" | $15-$25 | Very high |
| "cash home buyers [city]" | $10-$20 | Very high |
| "sell house as is [city]" | $8-$15 | High |
| "sell inherited house [city]" | $5-$12 | High |
| "stop foreclosure [city]" | $8-$15 | Very high (distress) |
| "sell house fast for cash" | $20-$30 | Very high |
| "home buyers near me" | $5-$10 | Medium-high |

#### Negative Keywords (Must-Have to Protect Budget)
```
-jobs, -rent, -rental, -Zillow, -Redfin, -agent, -realtor,
-license, -salary, -career, -apartment, -lease, -mortgage rates,
-home depot, -calculator, -free, -DIY, -how to become
```

### Cost Benchmarks (2025-2026)

| Metric | Value |
|--------|-------|
| Average CPC (general RE) | $2.53 |
| CPC for "sell my house fast" | $30-$36+ |
| Average CTR | 8.43% |
| Average conversion rate | 3.28% |
| Cost per lead (seller) | $65-$170 |
| Cost per lead (optimized) | ~$100 |
| Recommended monthly budget | $1,500-$3,000 minimum |
| Budget per 1.5M population | $3,000/month |

### Landing Page Best Practices

1. **Speed**: Every 1-second delay reduces conversions by 7%
2. **Local imagery**: Improves conversion rates by 15-30%
3. **Single CTA**: One clear action — "Get Your Cash Offer"
4. **Minimal form fields**: Name, address, phone, email (4 fields max)
5. **Social proof**: Testimonials, review badges, "X houses bought" counter
6. **Mobile-first**: 60%+ of traffic is mobile
7. **Match ad to landing page**: Keyword in headline, consistent messaging
8. **Trust signals**: BBB badge, Google reviews, before/after photos

### Campaign Structure

```
Campaign: Motivated Sellers [City]
├── Ad Group: "Sell Fast" keywords
│   ├── sell my house fast [city]
│   ├── sell house quickly [city]
│   └── fast home sale [city]
├── Ad Group: "Cash Buyers" keywords
│   ├── cash home buyers [city]
│   ├── we buy houses cash [city]
│   └── cash for my house [city]
├── Ad Group: "As-Is" keywords
│   ├── sell house as is [city]
│   ├── sell damaged house [city]
│   └── sell fixer upper [city]
└── Ad Group: "Distress" keywords
    ├── stop foreclosure [city]
    ├── sell inherited house [city]
    └── behind on mortgage [city]
```

### Optimization Tips
- **A/B test** landing pages and ad copy continuously
- **Use retargeting** — most visitors don't convert on first visit
- **Dayparting**: Test showing ads during business hours vs. evenings
- **Geo-bid adjustments**: Bid higher in zip codes with more distressed properties
- **Call extensions**: Many motivated sellers prefer to call directly

Sources:
- [PPC Real Estate 101 - Placester](https://placester.com/real-estate-marketing-academy/ppc-guide)
- [PPC for Real Estate Investors - Promodo](https://www.promodo.com/blog/the-ultimate-ppc-guide-for-real-estate-investors)
- [Real Estate PPC Benchmarks 2025](https://contempothemes.com/real-estate-ppc-benchmarks-budget-insights-for-2025/)
- [Real Estate PPC ROI Case Study - DMR Media](https://www.dmrmedia.org/blog/real-estate-pay-per-click-advertising)
- [Google Ads for House Flippers - LeadFarmers](https://www.leadfarmersppc.com/post/google-ads-strategy-for-house-flippers-how-to-generate-high-quality-leads)
- [PPC Management for Wholesalers - Webrageous](https://www.webrageous.com/wholesaling-and-distressed-real-estate-leads-sub2-google-ads.htm)

---

## 4. AI Voice Calling for Real Estate

### Platform Comparison (2026)

| Feature | Retell AI | Vapi | Bland AI |
|---------|-----------|------|----------|
| **Pricing** | $0.07/min flat | $0.13-$0.31/min (modular) | $0.09/min + $0.015/failed attempt |
| **Phone numbers** | $2/month | Varies | ~$15/month |
| **Best for** | Appointments, multi-step calls | Custom logic, developer-first | High-volume outbound campaigns |
| **Scale** | Good | Good | 20,000+ calls/hour |
| **Latency** | Best in class | Good | Good |
| **HIPAA** | Included | $1,000/month add-on | Included |
| **Custom LLM** | Yes | Yes (open-source SDK) | Yes |
| **SIP trunking** | Yes | Yes | Yes |
| **Branded caller ID** | Yes | No | Limited |
| **Real estate fit** | Excellent (appointment-driven) | Good (customizable) | Good (outbound campaigns) |

### Recommendation for Wholesale RE
1. **Retell AI** for inbound/appointment scheduling — best latency, cheapest per minute, branded calls boost answer rates
2. **Bland AI** for outbound cold calling at scale — batch calling, 20K+/hour capacity
3. **Vapi** for custom-built conversational agents — most flexible if you have dev resources

### TCPA Compliance Requirements (Critical)

#### FCC Ruling (Effective 2024-2025)
- AI-generated voices are classified as **"artificial or prerecorded voice"** under TCPA
- ALL AI marketing calls require **Prior Express Written Consent (PEWC)**
- Consent must be from **one identified seller at a time** (no lead aggregation consent)
- Effective January 27, 2025

#### Penalties
- **$500 per violation** (per call)
- **$1,500 per willful violation** (trebled damages)
- Class action lawsuits are common

#### Compliance Checklist
- [ ] Obtain Prior Express Written Consent BEFORE any AI call
- [ ] Consent must name YOUR specific company
- [ ] One-to-one consent only (no shared/aggregated consent)
- [ ] Maintain consent records with timestamps
- [ ] Honor Do Not Call (DNC) lists — national and state
- [ ] Allow opt-out during every call
- [ ] Identify yourself and company at the start of each call
- [ ] Call only during allowed hours (8am-9pm recipient's local time)
- [ ] Disclose that the call uses AI/automated technology
- [ ] Register with state-specific telemarketing registries

### AI Call Script Framework for Motivated Sellers

```
OPENING (First 10 seconds - Critical):
"Hi [Name], this is [Agent/AI Name] with [Company].
I'm reaching out because I noticed you might be considering
selling your property at [Address]. Do you have a quick moment?"

QUALIFICATION (TARP Framework):
T - Timeline: "Is there a specific timeline you're working with?"
A - Authority: "Are you the owner / decision maker on the property?"
R - Reason: "What's prompting you to consider selling?"
P - Price: "Do you have a price in mind?"

CONDITION CHECK:
"How would you describe the current condition of the property?"
"Are there any repairs needed?"
"Is anyone currently living there?"

CLOSE TO APPOINTMENT:
"Based on what you've shared, we may be able to help.
Could we schedule a quick 15-minute call with our acquisitions
team to discuss a fair cash offer?"
```

Sources:
- [Bland AI vs VAPI vs Retell Comparison 2026](https://www.whitespacesolutions.ai/content/bland-ai-vs-vapi-vs-retell-comparison)
- [AI Voice and TCPA: The 2026 Compliance Paradox](https://biglysales.com/ai-outbound-calling-tcpa-compliance/)
- [Retell AI vs Vapi Comparison](https://www.retellai.com/comparisons/retell-vs-vapi)
- [Retell AI vs Bland AI Comparison](https://www.retellai.com/comparisons/retell-vs-bland)
- [Voice AI Platform Pricing Comparison 2025](https://www.retellai.com/resources/voice-ai-platform-pricing-comparison-2025)
- [Vapi AI Alternatives 2026 - Lindy](https://www.lindy.ai/blog/vapi-ai-alternatives)

---

## 5. Novation Deal Process (Rainmaker Method)

### What is a Novation Deal?

Unlike wholesale (assign contract to cash buyer), novation lets you:
- Update/improve the property
- List it on MLS for retail buyers
- Earn a **novation release fee** from the seller at closing
- Access broader buyer pool (FHA, VA, conventional buyers)
- Higher profit margins than traditional wholesale

### Rich Wonders' Rainmaker Method — 3 Phases

#### Phase 1: Discovery
**Goal:** Position yourself as a "glorified information gatherer"

- Build rapport with the seller — you're NOT pitching yet
- Gather property condition, motivation, timeline, financial situation
- Understand the seller's real pain points
- Let the seller talk 80%, you talk 20%
- Key questions: Why selling? What have you tried? What's your timeline? What would you do with the money?

**AI Automation Opportunities:**
- AI bot (Lily) qualifies inbound leads on FB Messenger
- AI scoring determines if lead fits novation criteria
- Automated data pull: equity check, liens, comps, condition estimates
- n8n workflow triggers CRM entry and assigns lead score
- Auto-schedule discovery call based on lead score

#### Phase 2: Anchor
**Goal:** Set realistic expectations for the cash offer

- Present comparable data showing realistic value
- Anchor the seller's expectations to a number that works
- Use the "bracket" technique — give a range, not a single number
- Address the gap between their expectation and reality
- Explain the value of speed, certainty, and convenience

**AI Automation Opportunities:**
- Automated comps pull (PropStream API integration)
- AI-generated offer presentation with ARV, repair estimates
- Automated MAO (Maximum Allowable Offer) calculation
- n8n workflow generates offer document
- AI follow-up sequences if seller doesn't respond

#### Phase 3: Delivery
**Goal:** "White glove" experience for high closing percentage

- Present the offer professionally
- Handle objections with prepared responses
- Manage the contract signing process (DocuSign)
- Coordinate property updates/improvements
- List on MLS and manage buyer showings
- Close the deal and collect novation fee

**AI Automation Opportunities:**
- Automated DocuSign delivery via n8n workflow
- AI-powered drip campaign during escrow
- Automated status updates to seller
- AI disposition to buyer list simultaneously
- Post-close review request automation

### Novation vs. Wholesale Comparison

| Factor | Wholesale | Novation |
|--------|-----------|----------|
| Buyer pool | Cash buyers only | All buyers (FHA, VA, conventional, cash) |
| Profit margin | $5K-$15K typical | $15K-$50K+ typical |
| Time to close | 7-30 days | 30-90 days |
| Property updates | None | Light updates to increase value |
| Seller relationship | Transactional | Collaborative ("white glove") |
| Complexity | Lower | Higher |
| MLS listing | No | Yes |
| Best for | High-equity distressed | Moderate equity, good condition |

### When to Use Novation vs. Wholesale
- **Novation**: Property needs light updates, seller has equity but isn't deeply distressed, property would attract retail buyers
- **Wholesale**: Deep distress, needs major rehab, seller needs immediate relief, time-sensitive

Sources:
- [Novation King - Rainmaker Novation 4.0](https://www.novationking.com)
- [Cracking the Code on Novations - Bateman Collective](https://www.batemancollective.com/podcast/cracking-the-code-on-novations-with-rich-wonders)
- [Novation vs Wholesaling - DealMachine](https://www.dealmachine.com/blog/novation-vs-wholesaling-real-estate)
- [Rich Wonders Leads2Deals Podcast](https://shows.acast.com/leads2deals/episodes/rich-wonders-the-novation-king)

---

## 6. SMS Compliance

### TCPA Foundation Rules

| Requirement | Details |
|------------|---------|
| **Consent type** | Prior Express Written Consent (PEWC) for marketing |
| **Consent scope** | One-to-one — one brand per consent (no sharing across affiliates) |
| **Time restrictions** | 8am - 8pm (some states 9pm) recipient's local time |
| **Frequency limits** | Max 3 texts per 24-hour period (best practice) |
| **Opt-out mechanism** | Must honor STOP, CANCEL, UNSUBSCRIBE, END, QUIT |
| **Opt-out timing** | Must process within 10 business days (best practice: immediate) |
| **Record retention** | Keep consent records for 4+ years |
| **Penalties** | $500-$1,500 per unsolicited message |

### 10DLC Registration (Mandatory as of Feb 1, 2025)

#### What is 10DLC?
A2P (Application-to-Person) 10DLC allows businesses to send SMS from standard 10-digit local numbers, but requires registration with The Campaign Registry (TCR).

#### Registration Process
```
Step 1: Brand Registration
├── Register your business entity with TCR
├── Provide EIN, legal name, address, website
├── One-time vetting fee: $15
├── Auth+ vetting: $12.50 per brand (mandatory from Aug 2025)
├── Processing time: Minutes to 2 days
└── Trust Score assigned (determines throughput)

Step 2: Campaign Registration
├── Register each messaging use case
├── Define message samples, opt-in flow, use case
├── Campaign vetting: $30/quarter per campaign
├── Processing time: 3-7 business days
└── Carrier approval required

Step 3: Number Association
├── Link registered phone numbers to campaign
├── Carriers enable messaging throughput
└── Unregistered numbers are BLOCKED
```

#### Throughput Limits by Trust Score
| Trust Score | T-Mobile Daily Cap | AT&T Throughput |
|------------|-------------------|-----------------|
| Low | ~2,000 msgs/day | 1 msg/second |
| Medium | ~10,000 msgs/day | 4 msgs/second |
| High | ~200,000 msgs/day | 75 msgs/second |

### Opt-In Requirements

#### What Constitutes Valid Consent
1. **Web form opt-in**: Checkbox (unchecked by default) with clear disclosure
2. **Keyword opt-in**: User texts keyword (e.g., "SELL") to your number
3. **Paper form opt-in**: Physical signature with SMS disclosure
4. **Verbal opt-in**: Recorded verbal consent (weakest form)

#### Required Disclosure Language
```
"By providing your phone number, you agree to receive text messages
from [Company Name] regarding your property inquiry. Message frequency
varies. Message and data rates may apply. Reply STOP to unsubscribe.
Reply HELP for help."
```

#### Every SMS Must Include
- Business identification (first message in conversation)
- Opt-out instructions (at minimum in first message)
- No misleading content

### State-Specific "Mini-TCPA" Laws

| State | Additional Requirement |
|-------|----------------------|
| **Florida** | Written consent required; TCPA+ restrictions |
| **Oklahoma** | Stricter opt-in requirements |
| **Washington** | Enhanced consent documentation |
| **Michigan** | Additional texting campaign restrictions |

### Real Estate Investor SMS Best Practices

1. **Use Lead Sherpa or similar compliant platform** for skip-traced SMS
2. **Never cold text** without prior opt-in consent
3. **Register 10DLC** through your SMS provider (RingCentral, Twilio, etc.)
4. **Keep message logs** with timestamps, consent records, opt-outs
5. **Segment lists** — different campaigns for different property types
6. **Personalize messages** — include property address, owner name
7. **Include opt-out** in first message and periodically thereafter
8. **Monitor DNC lists** — scrub against national and state DNC monthly

Sources:
- [SMS Compliance 2025 Checklist - TextMyMainNumber](https://www.textmymainnumber.com/blog/sms-compliance-in-2025-your-tcpa-text-message-compliance-checklist)
- [10DLC 2025 Registration - CallHub](https://callhub.io/blog/compliance/10dlc-2025-registration-callhub/)
- [SMS for Real Estate Compliance - EZ Texting](https://www.eztexting.com/real-estate)
- [TCPA Compliance for SMS - BatchDialer](https://batchdialer.com/blog/understanding-and-adhering-to-tcpa-compliance-for-telemarketing)
- [10DLC Registration Guide 2025 - TextMyMainNumber](https://www.textmymainnumber.com/blog/10dlc-registration-complete-2025-guide)
- [SMS Compliance Real Estate - TextDrip](https://textdrip.com/blog/sms-compliance-real-estate-agent)
- [SMS Compliance Guide A2P 10DLC - Lead Sherpa](https://leadsherpa.freshdesk.com/support/solutions/articles/44002323978-sms-compliance-guide-a2p-10dlc)

---

## 7. Cash Buyer List Building

### Strategy Overview

**Core principle:** Always have more buyers than deals. This ensures no deal falls through and protects your reputation among sellers.

### PropStream Methods

#### Using PropStream's Cash Buyer Lead List
1. **Quick List**: Pre-built "Cash Buyers" lead list shows all recent cash purchases in your area
2. **Filter by criteria**:
   - Number of properties owned (serious investors own 3+)
   - Equity percentage / LTV ratio
   - Purchase date (recent = active buyer)
   - Property type (SFR, multi-family, etc.)
   - Purchase price range (matches your deal sizes)
3. **List Automator**: Automatically sends new matching cash buyer leads to your inbox
4. **Skip Trace**: Get phone/email for identified buyers directly in PropStream

#### PropStream Pricing (2026)
| Plan | Price | Features |
|------|-------|----------|
| Essentials | $99/month | Basic searches, 50 free leads |
| Pro | $199/month | Advanced filters, skip tracing credits |
| Elite | $699/month | Full feature access, team support |
| Free trial | 7 days | All plans include trial |

### Additional Cash Buyer Sources

| Source | Method | Quality |
|--------|--------|---------|
| **County records** | Search recent cash transactions (no mortgage recorded) | High |
| **REI meetups** | Network at local real estate investor groups | High |
| **Facebook groups** | RE investor groups, post deals, collect buyer criteria | Medium |
| **Craigslist/Marketplace** | Look for "we buy houses" ads — those are your buyers | Medium |
| **Title companies** | Ask for referrals to active cash buyers | High |
| **Auction attendees** | People at foreclosure auctions have cash | Very high |
| **Hard money lenders** | They know who's actively buying | High |
| **Wholesaler networks** | JV with other wholesalers, share buyer lists | Medium |
| **BiggerPockets** | Network in forums, marketplace | Medium |
| **Public records** | LLC purchases = investor purchases | High |

### Buyer List Management Best Practices

1. **Segment by criteria**:
   - Property type preference (SFR, duplex, commercial)
   - Geographic focus (zip codes, neighborhoods)
   - Price range (budget per deal)
   - Rehab tolerance (turnkey vs. gut rehab)
   - Buying frequency (monthly, quarterly)
   - Speed of close (7 days, 14 days, 30 days)

2. **Track buyer performance**:
   - Deals closed with you
   - Response time to deal alerts
   - Reliability (pulled out of deals?)
   - Proof of funds verified?

3. **Keep list warm**:
   - Send deal alerts regularly (even ones they won't buy)
   - Monthly market update emails
   - Quarterly check-in calls
   - Invite to REI meetups/events

4. **Automate with n8n**:
   - New deal → auto-blast to matching buyers
   - Buyer response → CRM update → follow-up sequence
   - Buyer closes deal → tag as "active," increase priority

Sources:
- [How to Find Cash Buyers - PropStream](https://www.propstream.com/real-estate-investor-blog/how-to-find-cash-buyers-for-wholesaling-real-estate)
- [Build a Cash Buyers List - PropStream Video](https://www.propstream.com/how-to-build-a-cash-buyers-list)
- [Cash Buyers Using PropStream Lead List](https://www.propstream.com/news/how-to-find-cash-buyers-using-propstreams-quick-list)
- [PropStream 2026 Review](https://realestaterankiq.com/propstream-2026-review-still-worth-it-for-wholesalers-my-honest-take/)
- [Finding Cash Buyers - CrushingREI](https://crushingrei.com/find-cash-buyers-for-wholesaling/)

---

## 8. CRM Automation for Wholesalers

### Platform Comparison

| Feature | Podio | REsimpli | GoHighLevel | InvestorFuse |
|---------|-------|----------|-------------|-------------|
| **Price** | Free-$24/month + add-ons | $99-$299/month | $97-$297/month | $147/month |
| **Built for RE investors** | No (generic) | Yes | No (generic) | Yes |
| **Setup effort** | Very high (DIY) | Low (pre-built) | Medium | Low |
| **Skip tracing** | Add-on | Built-in | Add-on | Limited |
| **Drip campaigns** | Manual/Zapier | Built-in (email, SMS, RVM) | Built-in | Built-in |
| **AI features** | None | AI lead grading, AI agents | AI conversation bots | Limited |
| **Phone/dialer** | Add-on | Built-in | Built-in | Add-on |
| **Pipeline stages** | Custom | Pre-built for investors | Custom Kanban | Pre-built |
| **Direct mail** | No | Built-in | No | No |
| **List stacking** | No | Built-in | No | No |
| **KPI tracking** | Manual | Built-in dashboards | Built-in | Limited |
| **Customization** | Extremely high | Medium | High | Medium |

### Recommended Pipeline Stages

```
ACQUISITIONS PIPELINE:
1. New Lead          → Auto-assign, AI score, first touch triggered
2. Contacted         → First conversation logged
3. Appointment Set   → Calendar invite sent, reminder sequence active
4. Appointment Done  → Property info captured, comps pulled
5. Offer Made        → Offer document sent (DocuSign)
6. Negotiating       → Follow-up sequence active (3-7-14-30 day touches)
7. Under Contract    → TC notified, title search initiated
8. In Closing        → Disposition to buyers or MLS listing (novation)
9. Closed Won        → Commission tracked, review request sent
10. Dead/Nurture     → 90-day drip campaign, re-engagement sequence

DISPOSITIONS PIPELINE:
1. New Deal          → Deal sheet created, blast to buyers
2. Buyer Interest    → POF requested
3. Under Contract    → Assignment/double-close initiated
4. In Closing        → Title company coordinating
5. Closed            → Profit recorded
```

### Automated Follow-Up Sequences

#### The 90-Day Drip Campaign
```
Day 0:   Initial contact (call + SMS + email)
Day 1:   Follow-up SMS: "Just following up on the property at [Address]"
Day 3:   Email with market data/comps
Day 7:   Phone call attempt
Day 10:  SMS: "Any update on your plans for [Address]?"
Day 14:  Email: Neighborhood activity / recent sales
Day 21:  Phone call attempt
Day 30:  SMS: "Still interested in a cash offer for [Address]?"
Day 45:  Email: Value-add content (moving tips, etc.)
Day 60:  Phone call + SMS: "Checking in on [Address]"
Day 75:  Email: Market update for their area
Day 90:  Final touch: "Our offer still stands for [Address]"
```

#### Speed-to-Lead Response
- **Under 5 minutes**: Call + SMS immediately when lead comes in
- **First hour**: If no answer, send email with offer to help
- **Same day**: Second call attempt, different time of day
- **Day 2**: Third call attempt + SMS

### Why Podio Still Has a Place

Despite alternatives, Podio's advantages:
- **Extreme customization** — build exactly what you need
- **Low base cost** — free tier + paid add-ons
- **GlobiFlow/Podio Flows** — built-in automation (basic)
- **Ecosystem** — PodioCreativeAgency, PodioPreBuilt offer investor-ready setups
- **API access** — integrates well with n8n for custom automation

### Recommendation
- **Starting out**: GoHighLevel ($97/month) for most complete automation at lowest price
- **Scaling**: REsimpli ($99-$299/month) for purpose-built investor features
- **Custom/Technical**: Podio + n8n for maximum flexibility and control

Sources:
- [CRM for Real Estate Investors - NetPartners](https://netpartners.marketing/crm-for-real-estate-investors/)
- [REsimpli vs InvestorFuse](https://resimpli.com/blog/resimpli-vs-investorfuse/)
- [Ditch Podio for REsimpli](https://resimpli.com/blog/ditch-podio-and-zapier-resimpli-the-all-in-one-crm-for-real-estate-investors/)
- [Podio CRM for Wholesalers](https://podiocrms.com/)
- [9 Best CRMs for Wholesalers - SPOTIO](https://spotio.com/blog/wholesale-crm/)

---

## 9. n8n Workflow Patterns for Real Estate

### Core Workflow Architectures

#### Pattern 1: Webhook Lead Intake
```
[Facebook Lead Form / Website Form / Google Ads]
    ↓ Webhook trigger
[n8n Workflow]
    ├── Parse lead data
    ├── AI lead scoring (OpenAI node)
    ├── Enrich data (PropStream/BatchData API)
    ├── Create CRM record (Podio/HubSpot/Airtable)
    ├── Send notification (Slack/SMS)
    └── Trigger speed-to-lead sequence
```

#### Pattern 2: Multi-Channel Outreach Engine
```
[CRM: New lead enters pipeline]
    ↓ Trigger (Podio webhook / schedule)
[n8n Workflow]
    ├── Channel 1: SMS via RingCentral/Twilio
    ├── Channel 2: Email via Gmail/SendGrid
    ├── Channel 3: AI Voice Call via Retell/Vapi
    ├── Channel 4: Ringless Voicemail
    └── Log all touches back to CRM
```

#### Pattern 3: 90-Day Drip Campaign
```
[Schedule trigger: Daily at 9 AM]
    ↓
[n8n Workflow]
    ├── Query CRM for leads due for touch
    ├── Determine touch type by day count
    │   ├── Day 0-3: SMS + Call
    │   ├── Day 7-14: Email + SMS
    │   ├── Day 21-30: Call + Email
    │   ├── Day 45-60: Email content
    │   └── Day 75-90: Final touches
    ├── Execute appropriate channel
    ├── Update CRM with touch record
    └── Alert team for hot responses
```

#### Pattern 4: AI Lead Qualification Bot
```
[Facebook Messenger / SMS inbound]
    ↓ Webhook
[n8n Workflow]
    ├── AI Agent (Groq/OpenAI) processes message
    ├── Extract: motivation, timeline, property address
    ├── Score lead based on responses
    ├── If HOT → Route to acquisitions team immediately
    ├── If WARM → Schedule callback, add to nurture
    └── If COLD → Add to long-term drip
```

#### Pattern 5: Deal Disposition Engine
```
[CRM: Deal moves to "Under Contract"]
    ↓ Trigger
[n8n Workflow]
    ├── Pull deal details from CRM
    ├── Generate deal sheet (property details, ARV, offer)
    ├── Query buyer list (match by criteria)
    ├── Blast matching buyers (email + SMS)
    ├── Track buyer responses
    ├── Update CRM with buyer interest
    └── Notify acquisitions manager
```

### Existing n8n Templates for Real Estate

| Template | Description | Key Nodes |
|----------|-------------|-----------|
| [#3666](https://n8n.io/workflows/3666) | BatchData skip tracing + CRM integration | BatchData, HTTP, Airtable |
| [#6630](https://n8n.io/workflows/6630) | Llama AI + VAPI calls + Gmail campaigns | OpenAI, VAPI, Gmail |
| [#3665](https://n8n.io/workflows/3665) | Automated property lead generation | BatchData, HTTP, CRM |
| [#9256](https://n8n.io/workflows/9256) | Open house follow-ups (HubSpot + Twilio) | HubSpot, Twilio, SignSnap |
| [#5428](https://n8n.io/workflows/5428) | OpenAI lead qualification + Gmail + Airtable | OpenAI, Gmail, Airtable |
| [#4368](https://n8n.io/workflows/4368) | End-to-end AI RE agent (web, data, voice) | Multiple AI + data nodes |

### Integration Points

| System | n8n Integration | Use Case |
|--------|----------------|----------|
| **Podio** | HTTP Request (API) | CRM read/write, pipeline updates |
| **Google Sheets** | Google Sheets node | Backup data, reporting, simple CRM |
| **RingCentral** | HTTP Request (API) | SMS sending, call logging |
| **Twilio** | Twilio node | SMS, voice calls |
| **Gmail** | Gmail node (OAuth) | Email sequences |
| **DocuSign** | HTTP Request (API) | Contract delivery |
| **PropStream** | HTTP Request (API) | Property data, comps, skip trace |
| **Facebook** | Facebook node / Webhook | Lead form intake, Messenger bot |
| **Slack** | Slack node | Team notifications |
| **OpenAI/Groq** | OpenAI node | AI agent, lead scoring, content |
| **Retell AI** | HTTP Request (API) | AI voice calls |
| **Airtable** | Airtable node | Lightweight CRM alternative |

### n8n Best Practices for RE Workflows

1. **Error handling**: Always add error branches — leads are money
2. **Webhook security**: Use header authentication or HMAC signatures
3. **Rate limiting**: Respect API limits (RingCentral, PropStream)
4. **Idempotency**: Prevent duplicate lead entries with dedup checks
5. **Logging**: Log every touch to CRM for compliance and follow-up
6. **Credential security**: Use n8n credential store, never hardcode keys
7. **Testing**: Use test webhooks before going live
8. **Monitoring**: Set up health check workflows to alert on failures

Sources:
- [Real Estate Lead Gen with BatchData - n8n Template](https://n8n.io/workflows/3666-real-estate-lead-generation-with-batchdata-skip-tracing-and-crm-integration/)
- [AI Real Estate Marketing - n8n Template](https://n8n.io/workflows/6630-automate-real-estate-marketing-with-llama-ai-vapi-calls-and-gmail-campaigns/)
- [AI Real Estate Agent End-to-End - n8n Template](https://n8n.io/workflows/4368-ai-real-estate-agent-end-to-end-ops-automation-web-data-voice/)
- [Qualify RE Leads with OpenAI - n8n Template](https://n8n.io/workflows/5428-qualify-real-estate-leads-automatically-with-openai-gmail-and-airtable-crm/)
- [n8n Workflows for Real Estate - n8nLab](https://n8nlab.io/blog/n8n-workflows-real-estate-agency)
- [n8n CRM Workflow Automation](https://n8n.io/supercharge-your-crm/)

---

## 10. Seller Outreach Scripts

### Cold Calling Script (Motivated Sellers)

#### Opening (The First 10 Seconds)
```
"Hi, is this [First Name]?

Hey [First Name], my name is [Your Name] with [Company Name].
I'm calling about a property I believe you own at [Address].
Did I catch you at a good time?"
```

#### If Yes — Discovery Questions (TARP Framework)
```
T - TIMELINE:
"Are you currently looking to sell, or just exploring options?"
"Is there a specific timeline you're working with?"
"How soon would you ideally like this handled?"

A - AUTHORITY:
"Are you the sole owner of the property?"
"Is there anyone else involved in the decision to sell?"

R - REASON/MOTIVATION:
"What's prompting you to consider selling?"
"If you don't mind me asking, what would you do with the money?"
"Have you tried selling before? What happened?"

P - PRICE:
"Do you have a price in mind?"
"What do you feel the property is worth?"
"Would you be open to a fair cash offer?"
```

#### Condition Assessment
```
"How would you describe the condition of the property?"
"Does it need any major repairs — roof, HVAC, foundation?"
"Is anyone currently living in the property?"
"When was the last time you were at the property?"
```

#### Closing to Appointment
```
"Based on what you've shared, I think we might be able to help.
Here's what I'd like to do — I'd love to take a quick look
at the property and put together a fair cash offer for you.
Would [Day] at [Time] work for a quick visit?"
```

#### Common Objections & Responses
```
"I'm not interested right now."
→ "Totally understand. Many of the sellers we work with felt
   the same way initially. Would it be okay if I followed up
   in a few weeks? Things change."

"I need to talk to my [spouse/partner/family]."
→ "Of course! Would it help if we scheduled a time when
   both of you could be on the call?"

"I want full market value."
→ "I completely understand wanting top dollar. What we offer
   is speed and certainty — no repairs, no showings, no agent
   fees. Would it help to see what a cash offer would look like
   alongside your other options?"

"How did you get my number?"
→ "Great question — your property showed up in our research
   as one that might be a fit for what we do. We help homeowners
   sell quickly for cash. If this isn't a fit, I completely
   understand and I'll take you off our list."
```

### SMS Templates

#### Initial Outreach (Requires Prior Consent)
```
"Hi [Name], this is [Your Name] with [Company]. We're
interested in making a cash offer on your property at
[Address]. Would you be open to a quick conversation?
Reply STOP to opt out."
```

#### Follow-Up After No Response (Day 3)
```
"Hi [Name], just following up on the property at [Address].
We're still interested in making you a fair cash offer.
Any interest? Reply STOP to opt out."
```

#### Post-Voicemail SMS
```
"Hi [Name], I just tried calling about your property
at [Address]. We buy houses for cash and can close quickly.
Give me a call back when you get a chance! -[Your Name]
[Phone]. Reply STOP to opt out."
```

#### Re-Engagement (Day 30+)
```
"Hi [Name], checking back in on [Address]. Our cash offer
still stands if you're interested. No pressure — just want
you to know the option is there. -[Your Name].
Reply STOP to opt out."
```

### Email Templates

#### Initial Email
```
Subject: Cash Offer for [Address]

Hi [Name],

My name is [Your Name] with [Company Name]. I'm reaching out
because we're actively buying properties in [City/Area], and
your property at [Address] caught our attention.

We buy houses in any condition, and we can close in as little
as 7-14 days. Here's what makes us different:

• No repairs needed — sell as-is
• No agent commissions or closing costs
• Cash offer within 24 hours
• Close on YOUR timeline

If you've been thinking about selling — or even just curious
what your property might be worth — I'd love to have a quick
conversation.

Would you be open to a 10-minute call this week?

Best,
[Your Name]
[Company Name]
[Phone Number]
```

#### Follow-Up Email (Day 7)
```
Subject: Re: Cash Offer for [Address]

Hi [Name],

I wanted to follow up on my previous email about your
property at [Address].

I recently helped a homeowner in [nearby area] sell their
property in just [X] days with zero hassle. They were able
to [specific outcome — move closer to family, avoid
foreclosure, etc.].

If you're facing a similar situation, I'd love to help.
No obligation — just a conversation.

Best,
[Your Name]
```

### Spanish-Language Outreach (Mexican Spanish)

#### Cold Call Opening
```
"¿Hola, hablo con [Nombre]?

Hola [Nombre], mi nombre es [Tu Nombre] de [Compañía].
Le llamo porque tenemos interés en su propiedad en [Dirección].
¿Tiene un momentito para platicar?"
```

#### SMS (Spanish)
```
"Hola [Nombre], soy [Tu Nombre] de [Compañía]. Estamos
interesados en hacerle una oferta en efectivo por su propiedad
en [Dirección]. ¿Le gustaría platicar? Responda STOP para
dejar de recibir mensajes."
```

### Key Statistics
- Personal connections drive **82% of real estate transactions** (NAR)
- Hybrid approach (call + SMS) increases contact rate by **up to 40%**
- Speed-to-lead under 5 minutes increases conversion by **21x**
- Average cold call conversion to appointment: **2-5%**
- Best times to cold call: **10am-12pm** and **4pm-6pm** local time

Sources:
- [Wholesale RE Cold Calling Script 2026 - RealEstateSkills](https://www.realestateskills.com/blog/wholesaling-cold-calling-script)
- [Cold Calling Tips for Wholesalers - REsimpli](https://resimpli.com/blog/cold-calling-script-and-tips-for-real-estate-wholesalers/)
- [Cold Calling Script Samples - RealEstateBees](https://realestatebees.com/cold-calling-script-for-real-estate-wholesalers/)
- [Cold Texting Templates - SimpleTexting](https://simpletexting.com/real-estate-text-message-marketing/scripts-templates/cold-texting/)
- [Cold Calling Scripts - Carrot](https://carrot.com/blog/guide-to-cold-calling-motivated-sellers/)
- [Real Estate Cold Calling Scripts - Pipedrive](https://www.pipedrive.com/en/blog/real-estate-cold-calling)

---

## Summary: Key Takeaways for AI Automation

### Highest-Impact Automation Opportunities

1. **AI Lead Scoring** — Rule-based scoring (equity + distress signals + motivation) deployed via n8n with PropStream/BatchData data enrichment
2. **Speed-to-Lead** — Webhook-triggered instant response (SMS + email + AI call) within 5 minutes of lead intake
3. **AI Qualifier Bots** — Lily/Adriana on FB Messenger + SMS using Groq llama-3.3-70b for 24/7 lead qualification
4. **90-Day Drip Campaigns** — n8n-orchestrated multi-channel (SMS, email, call) automated follow-up
5. **Deal Disposition** — Auto-blast matching cash buyers when deal goes under contract
6. **AI Voice Calling** — Retell AI for appointments, Bland AI for outbound at scale (TCPA compliance critical)
7. **Novation Automation** — AI comps/MAO calculation, automated offer generation, DocuSign delivery

### Compliance Non-Negotiables

- **10DLC registration** mandatory for all SMS (blocked without it)
- **TCPA PEWC** required for AI voice calls AND marketing SMS
- **Facebook Special Ad Category** required for all housing ads
- **One-to-one consent** — no shared/aggregated lead consent
- **Record everything** — consent timestamps, opt-outs, all communications

### Recommended Tech Stack Integration

```
Lead Sources:        Facebook Ads → n8n → CRM
                     Google PPC → n8n → CRM
                     PropStream lists → n8n → CRM

AI Processing:       Groq (llama-3.3-70b) for chat/SMS bots
                     OpenAI for lead scoring/analysis
                     Retell AI for voice appointments
                     Bland AI for outbound calling campaigns

Automation:          n8n (workflow orchestration)
                     RingCentral (SMS/calls)
                     Gmail (email sequences)
                     DocuSign (contracts)

CRM:                 Podio (customized) + Google Sheets (backup)
                     OR REsimpli (all-in-one alternative)

Data:                PropStream (lists, comps, skip trace)
                     BatchData (enrichment, skip trace)
```

---

*Research compiled from 40+ sources across industry publications, platform documentation, and practitioner guides. All data points current as of March 2026.*
