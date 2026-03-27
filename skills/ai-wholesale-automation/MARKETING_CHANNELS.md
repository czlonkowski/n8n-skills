# Marketing Channel Guide — Wholesale Real Estate

Detailed configuration for Facebook Ads, Google PPC, and AI Voice channels.

---

## 1. Facebook Ads for Motivated Sellers

### Campaign Setup Checklist

```
[ ] Select Housing Special Ad Category (MANDATORY)
[ ] Set up Facebook Pixel on landing page
[ ] Create Custom Audience from website visitors
[ ] Create Special Ad Audience (compliant lookalike alternative)
[ ] Set up conversion tracking (lead form submit)
[ ] Configure Meta Instant Forms (in-app lead capture)
```

### Campaign Structure

```
ACCOUNT: Equity Path Offers
│
├── CAMPAIGN: Motivated Sellers - Arizona
│   ├── Objective: Lead Generation
│   ├── Special Ad Category: Housing
│   ├── Budget: $10-20/day (start), scale to $50+/day
│   │
│   ├── AD SET: Phoenix Metro (15mi radius)
│   │   ├── Targeting: City of Phoenix, 15-mile radius
│   │   ├── Age/Gender: Cannot target (Housing category)
│   │   ├── Placements: Automatic (let Meta optimize)
│   │   ├── Optimization: Lead Generation
│   │   │
│   │   ├── AD 1: Video (property walkthrough)
│   │   │   "Need to sell your house fast? We buy houses
│   │   │    in any condition. Cash offer in 24 hours."
│   │   │
│   │   ├── AD 2: Image (before/after or team photo)
│   │   │   "No repairs. No showings. No fees.
│   │   │    Close in as little as 7 days."
│   │   │
│   │   └── AD 3: Carousel (benefits breakdown)
│   │       Slide 1: "Fair Cash Offer"
│   │       Slide 2: "Close in 7-14 Days"
│   │       Slide 3: "Sell As-Is"
│   │       Slide 4: "Zero Fees"
│   │
│   └── AD SET: Tucson Metro (15mi radius)
│       └── [Same ad structure, different city]
│
├── CAMPAIGN: Motivated Sellers - Texas
│   ├── AD SET: Houston Metro
│   ├── AD SET: Dallas-Fort Worth
│   ├── AD SET: San Antonio
│   └── AD SET: Austin
│
└── CAMPAIGN: Motivated Sellers - California
    ├── AD SET: Los Angeles Metro
    ├── AD SET: San Diego
    └── AD SET: Sacramento
```

### Meta Instant Form Configuration

```
Form Name: "Get Your Cash Offer - [City]"
Form Type: More Volume (lower friction) OR Higher Intent (better quality)

Questions:
1. Full Name (prefilled from FB)
2. Email (prefilled from FB)
3. Phone Number (prefilled from FB)
4. Property Address (custom question, short answer)
5. "When are you looking to sell?" (multiple choice):
   - As soon as possible
   - Within 30 days
   - Within 90 days
   - Just exploring options

Thank You Screen:
  Headline: "We'll be in touch within 24 hours!"
  Description: "Our team is reviewing your property now.
                Expect a call or text shortly."
  CTA: "Call Us Now" → (928) 320-9610 / (281) 640-2291 / (424) 421-5535

Webhook: POST to n8n lead intake endpoint
```

### Ad Copy Frameworks

**Problem-Solution**:
```
Headline: "Sell Your House Fast for Cash"
Text: "Behind on payments? Facing foreclosure? Inherited a property?
We buy houses in ANY condition. No repairs, no fees, close in 7 days.
Get a fair cash offer in 24 hours."
CTA: "Get Offer"
```

**Testimonial**:
```
Headline: "We Helped [Name] Sell in 10 Days"
Text: "[Name] needed to relocate fast. We bought their home for cash,
closed in 10 days, and they didn't spend a dime on repairs or fees.
We can do the same for you."
CTA: "Get Your Offer"
```

**Urgency/Scarcity**:
```
Headline: "We're Buying [X] More Houses in [City] This Month"
Text: "Our team is actively purchasing properties in [City/Area].
If you've been thinking about selling, now is the time.
Cash offers. Fast close. Zero hassle."
CTA: "Claim Your Offer"
```

### Cost Benchmarks to Track

| Metric | Target | Action if Over |
|--------|--------|----------------|
| CPL | < $30 (Tier 2/3 markets) | Test new creative, tighten geo |
| CPC | < $2.00 | Review ad relevance score |
| CTR | > 1.5% | Test new headlines/images |
| Form completion rate | > 30% | Reduce form fields |
| Lead-to-contact rate | > 40% | Improve speed-to-lead |

---

## 2. Google PPC for Motivated Sellers

### Campaign Structure

```
CAMPAIGN: Motivated Sellers [City]
├── Ad Group: "Sell Fast"
│   ├── sell my house fast [city]
│   ├── sell house quickly [city]
│   └── fast home sale [city]
│
├── Ad Group: "Cash Buyers"
│   ├── cash home buyers [city]
│   ├── we buy houses cash [city]
│   └── cash for my house [city]
│
├── Ad Group: "As-Is"
│   ├── sell house as is [city]
│   ├── sell damaged house [city]
│   └── sell fixer upper [city]
│
└── Ad Group: "Distress"
    ├── stop foreclosure [city]
    ├── sell inherited house [city]
    └── behind on mortgage [city]
```

### Negative Keywords (Must-Have)

```
-jobs -rent -rental -zillow -redfin -agent -realtor
-license -salary -career -apartment -lease -mortgage rates
-home depot -calculator -free -DIY -how to become
-price -worth -value -estimate -zestimate
```

### Ad Copy Template

```
Headline 1: Sell Your House Fast in [City]
Headline 2: Cash Offer in 24 Hours
Headline 3: No Repairs, No Fees
Description 1: We buy houses in any condition. Close in 7-14 days.
               No agent fees, no closing costs. Get your free cash offer today.
Description 2: Local cash home buyers serving [City/Area].
               Fair offers, fast closings, zero hassle. Call now.
```

### Landing Page Requirements

1. **Load time**: Under 2 seconds (every 1s delay = 7% conversion drop)
2. **Form fields**: Max 4 (name, phone, email, address)
3. **Single CTA**: "Get Your Cash Offer Now"
4. **Trust signals**: Google reviews, BBB badge, "X houses bought" counter
5. **Local imagery**: Photos of the city/area (15-30% conversion boost)
6. **Mobile-first**: 60%+ of traffic is mobile
7. **Match ad copy**: Keywords from ad should appear in headline
8. **Phone number**: Click-to-call prominently displayed

### Budget & Bidding

| Market | Monthly Budget | Target CPA |
|--------|---------------|------------|
| Phoenix AZ | $1,500-2,000 | $80-$120 |
| Houston TX | $2,000-3,000 | $100-$150 |
| Los Angeles CA | $3,000-5,000 | $120-$170 |

- Start with Manual CPC, switch to Target CPA after 30+ conversions
- Geo-bid adjustments: +20% in ZIP codes with higher distress
- Schedule ads: Higher bids during 10am-2pm (peak search times)
- Device: Mobile-first, desktop secondary

---

## 3. AI Voice Calling (Retell AI)

### Why Retell AI for Wholesale RE

- **$0.07/min flat rate** (cheapest major platform)
- **Best latency** for natural conversation
- **Branded caller ID** boosts answer rates 20-30%
- **Custom LLM support** (use Groq for speed)
- **Appointment scheduling** built-in
- **HIPAA included** (no extra cost)

### Setup Checklist

```
[ ] Create Retell AI account
[ ] Register phone number (or port existing)
[ ] Brand caller ID with "Equity Path Offers"
[ ] Build AI agent with TARP framework script
[ ] Configure webhook for call outcomes → n8n
[ ] Set up CRM integration (log all calls)
[ ] TCPA compliance: consent verification before calling
[ ] Test with team members before live deployment
```

### AI Call Script (Retell Agent Configuration)

```
Agent Name: "Adriana - Acquisitions"
Voice: Female, professional, warm
Language: English (with Spanish fallback)
Max Duration: 5 minutes

Opening:
"Hi [Name], this is Adriana with Equity Path Offers.
I'm reaching out because I noticed your property at [Address]
and I wanted to see if you'd be interested in a cash offer.
Do you have a quick moment?"

Qualification (TARP):
- Timeline → Authority → Reason → Price → Condition

If Interested:
"Great! I'd love to schedule a quick 15-minute call with our
senior analyst who can give you exact numbers. What day and
time works best for you this week?"

If Not Interested:
"Totally understand! If anything changes, we're always here.
Have a great day, [Name]."

Webhook on call end → n8n workflow:
POST { caller_id, duration, outcome, transcript, appointment_time }
```

### Integration with n8n

```
Retell AI Call Ends
  → Webhook to n8n
  → Parse: outcome, transcript, appointment
  → If appointment set:
      → Create Google Calendar event
      → Send confirmation SMS
      → Update CRM to "Appointment Set"
  → If interested but no appointment:
      → Add to warm list
      → Schedule follow-up call in 48 hours
  → If not interested:
      → Log to CRM
      → Add to long-term nurture (90-day drip)
  → All calls:
      → Log transcript to CRM
      → Update call count and last contact date
```

### Cost Comparison

| Platform | Per Minute | Phone/Month | Best For |
|----------|-----------|-------------|----------|
| Retell AI | $0.07 | $2 | Inbound/appointment scheduling |
| Bland AI | $0.09 | ~$15 | High-volume outbound (20K+/hr) |
| Vapi | $0.13-$0.31 | Varies | Custom/developer-first agents |

---

## 4. Channel Attribution & Tracking

### UTM Parameters for Each Channel

```
Facebook Ads:
?utm_source=facebook&utm_medium=paid&utm_campaign=motivated_sellers_az&utm_content=video_ad_1

Google PPC:
?utm_source=google&utm_medium=cpc&utm_campaign=sell_fast_phoenix&utm_content=headline_v2

Direct Mail:
?utm_source=directmail&utm_medium=postcard&utm_campaign=absentee_owner_batch_3

Website Organic:
?utm_source=google&utm_medium=organic
```

### n8n Attribution Tracking Code

```javascript
// In lead intake webhook handler
const source = $input.first().json;
const utm = {
  source: source.utm_source || source.referrer || 'direct',
  medium: source.utm_medium || 'unknown',
  campaign: source.utm_campaign || '',
  content: source.utm_content || ''
};

// Track cost per channel
const channelCosts = {
  'facebook_paid': { daily_budget: 20, monthly: 600 },
  'google_cpc': { daily_budget: 50, monthly: 1500 },
  'retell_voice': { per_call_avg: 0.35, monthly_est: 200 },
  'ringcentral_sms': { per_msg: 0.01, monthly_est: 50 }
};

return [{ json: { ...source, attribution: utm, channel_cost: channelCosts[`${utm.source}_${utm.medium}`] } }];
```

### Monthly Reporting Metrics

| Metric | Formula | Target |
|--------|---------|--------|
| CPL by channel | Channel spend / Leads from channel | < $30 (FB), < $120 (Google) |
| Cost per deal | Total marketing / Deals closed | < $2,000 |
| Marketing ROI | (Revenue - Marketing Cost) / Marketing Cost | > 500% |
| Lead velocity | New leads this month vs. last month | Growing |
| Channel mix | % of deals from each source | Diversified (no >60% from one) |
