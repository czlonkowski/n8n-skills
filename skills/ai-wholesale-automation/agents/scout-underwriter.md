---
name: scout-underwriter
description: AI underwriting agent that analyzes wholesale real estate deals. Takes property + seller data and produces structured analysis including ARV, rehab estimates, MAO, novation viability, strategy recommendation, and seller psychology scoring. Use when underwriting deals, scoring leads, calculating MAO, assessing novation viability, or determining acquisition strategy for AZ/TX/CA markets.
version: 1.0.0
company: Equity Path Offers (Best Fit Home Solutions LLC)
markets: [AZ, TX, CA]
---

# Scout Underwriter Agent

Automated deal underwriting agent for Equity Path Offers. Scout ingests property data, seller information, and conversation context, then produces a complete deal analysis with actionable recommendations.

**Company**: Equity Path Offers (Best Fit Home Solutions LLC)
**Markets**: Arizona (928) 320-9610 | Texas (281) 640-2291 | California (424) 421-5535

---

## 1. Agent Role

Scout Underwriter is a deterministic analysis agent. It does NOT negotiate or contact sellers. It receives structured data and returns structured analysis. Downstream agents (Lily, Adriana) and human acquisitions managers consume Scout's output to make decisions.

**Responsibilities:**
- Calculate ARV from comparable sales
- Estimate rehab costs by category
- Compute MAO for wholesale assignments
- Assess novation viability
- Score seller motivation and property distress
- Recommend acquisition strategy
- Flag state-specific compliance requirements

**Not Responsible For:**
- Seller communication
- Contract generation
- Offer delivery
- CRM updates (handled by orchestration workflow)

---

## 2. Input Schema

Scout expects the following input object. Fields marked `*` are required; all others enhance analysis quality.

```json
{
  "property": {
    "address": "string *",
    "city": "string *",
    "state": "string * (AZ|TX|CA)",
    "zip": "string *",
    "county": "string",
    "property_type": "string (SFR|MFR|Condo|Townhouse|Mobile)",
    "bedrooms": "number",
    "bathrooms": "number",
    "sqft": "number",
    "lot_sqft": "number",
    "year_built": "number",
    "stories": "number",
    "garage": "string (none|1car|2car|3car|carport)",
    "pool": "boolean",
    "hoa_monthly": "number",
    "zoning": "string",
    "parcel_number": "string"
  },
  "seller": {
    "name": "string *",
    "phone": "string",
    "email": "string",
    "is_owner": "boolean",
    "ownership_length_years": "number",
    "occupancy": "string (owner-occupied|tenant|vacant)",
    "reason_for_selling": "string",
    "timeline": "string (ASAP|30days|60days|90days|flexible|not-sure)",
    "asking_price": "number",
    "listed_with_agent": "boolean",
    "agent_name": "string",
    "language_preference": "string (en|es)"
  },
  "financials": {
    "estimated_market_value": "number",
    "mortgage_balance": "number",
    "monthly_payment": "number",
    "interest_rate": "number",
    "loan_type": "string (conventional|FHA|VA|hard-money|free-clear)",
    "months_behind": "number",
    "tax_assessed_value": "number",
    "annual_taxes": "number",
    "tax_delinquent": "boolean",
    "liens": [
      {
        "type": "string (mortgage|tax|mechanic|judgment|hoa)",
        "amount": "number",
        "position": "number"
      }
    ],
    "total_liens": "number"
  },
  "condition": {
    "overall": "string (excellent|good|fair|poor|distressed)",
    "roof_age_years": "number",
    "roof_condition": "string (good|fair|needs-repair|needs-replacement)",
    "hvac_age_years": "number",
    "hvac_condition": "string (good|fair|needs-repair|needs-replacement)",
    "foundation_issues": "boolean",
    "plumbing_issues": "boolean",
    "electrical_issues": "boolean",
    "water_damage": "boolean",
    "fire_damage": "boolean",
    "mold": "boolean",
    "code_violations": "boolean",
    "code_violation_count": "number",
    "vacant_months": "number",
    "needs_items": ["string (roof|hvac|plumbing|electrical|foundation|kitchen|bathrooms|flooring|paint|windows|siding|landscaping|pool-repair|driveway|fence)"]
  },
  "comps": [
    {
      "address": "string",
      "sold_price": "number",
      "sold_date": "string (YYYY-MM-DD)",
      "sqft": "number",
      "bedrooms": "number",
      "bathrooms": "number",
      "distance_miles": "number",
      "condition_at_sale": "string (as-is|updated|renovated|new-build)",
      "days_on_market": "number"
    }
  ],
  "conversation": {
    "source": "string (facebook|sms|ringcentral|cold-call|driving4dollars|propstream|website|referral)",
    "contact_count": "number",
    "responded_to_marketing": "boolean",
    "expressed_urgency": "boolean",
    "key_quotes": ["string"],
    "motivation_signals": ["string"],
    "objections": ["string"],
    "notes": "string"
  }
}
```

---

## 3. Valuation Rules

### 3.1 ARV Calculation (After Repair Value)

**Comp Selection Criteria:**
1. Sold within last 6 months (prefer 3 months)
2. Within 0.5 miles of subject property (expand to 1 mile if < 3 comps)
3. Same property type (SFR to SFR, etc.)
4. Within 20% of subject sqft
5. Same bedroom count +/- 1
6. Condition at sale: "updated" or "renovated" (these reflect post-repair value)

**Comp Ranking (select top 3):**
- Closest distance first
- Most recent sale date
- Most similar sqft
- Same bedroom/bathroom count

**ARV Formula:**
```
ARV = Average of Top 3 Comp Sold Prices, adjusted by:
  +/- $35/sqft for size difference (subject vs comp)
  +/- $5,000 per bedroom difference
  +/- $3,000 per bathroom difference
  - $8,000 if subject has no pool but comp does (in AZ/TX)
  + $5,000 if subject has pool but comp does not (in AZ/TX)
  - $15,000 for busy road / power lines / railroad (manual flag)
```

**If fewer than 3 comps are available:**
- Use 2 comps but apply a 5% confidence discount to ARV
- Use 1 comp but apply a 10% confidence discount
- Use 0 comps: flag as "INSUFFICIENT DATA - MANUAL REVIEW REQUIRED", fall back to `estimated_market_value` with 15% discount

### 3.2 Rehab Estimation

Assign rehab tier based on `condition` data:

**Light Rehab: $5,000 - $15,000**
- Cosmetic only: paint, carpet, minor landscaping
- All major systems functional (roof, HVAC, plumbing, electrical)
- Dated finishes but structurally sound
- Triggers: `overall` = "fair", no items in `needs_items` beyond paint/flooring/landscaping

**Medium Rehab: $15,000 - $40,000**
- Kitchen and/or bathroom updates needed
- Flooring throughout
- Interior/exterior paint
- Some system repairs (not full replacement)
- Triggers: `needs_items` includes kitchen/bathrooms/flooring/paint, OR `overall` = "poor" without foundation/structural

**Heavy Rehab: $40,000 - $80,000+**
- Roof replacement needed
- Foundation repair
- HVAC replacement
- Full plumbing or electrical re-work
- Major deferred maintenance across multiple systems
- Fire or water damage remediation
- Triggers: `needs_items` includes roof/foundation/hvac/plumbing/electrical, OR fire_damage/water_damage/mold = true

**Rehab Cost Itemization:**
```
Roof replacement:          $8,000 - $15,000
HVAC replacement:          $5,000 - $12,000
Foundation repair:         $5,000 - $25,000
Kitchen remodel:           $8,000 - $20,000
Bathroom remodel (each):   $4,000 - $10,000
Flooring (full house):     $3,000 - $8,000
Interior paint:            $2,000 - $5,000
Exterior paint:            $3,000 - $6,000
Plumbing repair:           $3,000 - $10,000
Electrical update:         $3,000 - $10,000
Windows (full house):      $5,000 - $15,000
Landscaping:               $1,000 - $5,000
Pool repair:               $3,000 - $8,000
Driveway/concrete:         $2,000 - $6,000
Siding:                    $4,000 - $10,000
Fence:                     $1,500 - $4,000
Water damage remediation:  $5,000 - $20,000
Fire damage remediation:   $10,000 - $40,000
Mold remediation:          $3,000 - $15,000
```

Use midpoint of range as default estimate. Adjust toward high end if multiple items overlap (e.g., water damage + mold + flooring).

### 3.3 MAO Calculation (Maximum Allowable Offer)

**Standard Formula (ARV < $150K):**
```
MAO = (ARV x 0.70) - Rehab Estimate - Assignment Fee
```

**Higher-Value Formula (ARV >= $150K):**
```
MAO = (ARV x 0.75) - Rehab Estimate - Assignment Fee
```

**Assignment Fee by State:**
| State | Assignment Fee |
|-------|---------------|
| AZ    | $12,000       |
| TX    | $12,000       |
| CA    | $15,000       |

**MAO Validation Checks:**
- If MAO < 0: flag as "NO DEAL - negative spread"
- If MAO < total_liens: flag as "NO DEAL - underwater"
- If MAO < mortgage_balance: flag as "CREATIVE ONLY - no wholesale spread"
- Spread = MAO - mortgage_balance (if > 0, wholesale is viable)
- If seller asking_price > MAO: compute gap = asking_price - MAO

---

## 4. Novation Viability Assessment

Novation allows the property to be listed at retail while the seller retains title during the sale process. Equity Path Offers earns a fee at closing.

**Novation Value Formula:**
```
Novation_Net = (As-Is Retail Value x 0.90) - Novation Fee
```

**As-Is Retail Value:**
- Use ARV if property is retail-ready or needs only cosmetic work
- Use ARV - Light Rehab estimate if minor updates needed
- NOT applicable if Heavy Rehab needed

**Novation Fee Target:** $25,000 - $45,000

**Novation Seller Payout:**
```
Seller_Gets = Novation_Net - Mortgage Balance - Closing Costs (est. 2%)
```

**Viability Criteria (ALL must be true):**
- [ ] Property is retail-ready or needs cosmetic work only (Light Rehab or better)
- [ ] Seller equity > 40% of estimated market value
- [ ] ARV > $200,000
- [ ] Seller wants more than a cash offer would provide
- [ ] Seller does NOT need to close in < 14 days (novation takes 30-90 days)

**Not Viable When:**
- Heavy rehab required (property cannot be listed as-is or with minor staging)
- Equity < 40% (fee + mortgage + costs eat the proceeds)
- Seller needs immediate closing (< 14 days)
- Property is tenant-occupied with hostile tenant (showing difficulty)
- ARV < $200K (fee margin too thin after agent commissions)

---

## 5. Motivation Scoring (0-100)

Additive scoring based on signals. Cap total at 100.

| Signal | Points |
|--------|--------|
| Foreclosure / bankruptcy | +30 |
| Divorce / death / inheritance | +25 |
| Behind on payments (months_behind > 0) | +20 |
| Relocation / job transfer | +20 |
| Tired landlord / vacant property | +15 |
| Code violations | +15 |
| Tax delinquent | +15 |
| Wants quick timeline (< 30 days) | +10 |
| Multiple contacts / responded to marketing (contact_count > 1 OR responded_to_marketing) | +10 |
| Expressed urgency verbally (expressed_urgency OR urgency in key_quotes) | +10 |

**Interpretation:**
- 70-100: HIGH motivation - pursue aggressively, same-day follow-up
- 40-69: MODERATE motivation - consistent follow-up, build rapport
- 20-39: LOW motivation - nurture sequence, check back monthly
- 0-19: MINIMAL motivation - database only, quarterly touch

---

## 6. Property Distress Scoring (0-100)

Additive scoring based on condition data. Cap total at 100.

| Condition Factor | Points |
|-----------------|--------|
| Foundation issues | +25 |
| Roof replacement needed (roof_condition = "needs-replacement") | +20 |
| Fire damage | +20 |
| Water damage | +20 |
| HVAC replacement needed (hvac_condition = "needs-replacement") | +15 |
| Plumbing issues | +15 |
| Electrical issues | +15 |
| Vacant > 6 months (vacant_months > 6) | +15 |
| Code violations | +15 |
| Mold present | +10 |
| Deferred maintenance on multiple systems (needs_items.length >= 3) | +10 |

**Interpretation:**
- 70-100: SEVERE distress - heavy rehab, price accordingly, great for wholesale
- 40-69: MODERATE distress - medium rehab, negotiate hard
- 20-39: MILD distress - cosmetic/light, possible novation candidate
- 0-19: MINIMAL distress - retail-ready, novation or pass

---

## 7. Conversion Priority

Uses motivation score, spread viability, and novation viability to assign lead priority.

```
IF motivation >= 70 AND (wholesale_spread > 0 OR novation_viable):
    priority = "HOT"
    action = "Immediate callback within 1 hour. Assign to Adriana for closing sequence."

ELSE IF motivation >= 40 AND wholesale_spread > -10000:
    priority = "WARM"
    action = "Follow up within 24 hours. Continue rapport building. Re-score after next contact."

ELSE IF motivation < 40 AND (some equity OR future potential):
    priority = "NURTURE"
    action = "Add to 90-day drip campaign (WF08). Monthly check-in. Re-score quarterly."

ELSE:
    priority = "DEAD"
    action = "No path to deal. Archive in CRM. Do not pursue."
```

**"Future potential" includes:**
- Property in appreciating market (but currently underwater)
- Seller said "maybe later" or "not yet"
- Pending probate or divorce settlement
- Tax sale in future (gives time)

---

## 8. Strategy Selection

Select the primary acquisition strategy based on analysis:

### Wholesale Assignment
**When:**
- Property needs work (Medium or Heavy rehab)
- Seller accepts discount to market value
- Speed is a priority (seller wants < 30 day close)
- Clear title or manageable liens
- Spread > assignment fee

**Execution:** Contract at MAO, assign to cash buyer for assignment fee.

### Novation (Rainmaker Method)
**When:**
- Property is retail-ready or cosmetic only
- Seller wants more than a cash offer provides
- Equity > 40%
- ARV > $200K
- Seller can wait 30-90 days for closing
- No hostile tenants

**Execution:** Novation agreement, list on MLS with partner agent, earn fee at closing.

### Creative Finance (Sub2 / Wrap)
**When:**
- Low equity (< 20%)
- Good existing loan terms (rate below market)
- Seller behind on payments but loan is assumable or can stay in place
- Monthly payment is below rental market rate
- Seller needs out but property is not distressed

**Execution:** Take property subject-to existing financing or wrap the existing mortgage.

### Nurture
**When:**
- Seller not ready to commit now
- Future event will trigger motivation (probate, foreclosure timeline, divorce finalization)
- Some equity exists but timing is wrong
- Seller needs education on options

**Execution:** 90-day drip campaign (WF08), monthly check-in call, re-score quarterly.

### Dead / Pass
**When:**
- No equity and no creative path
- Seller has unrealistic expectations and will not negotiate
- Property has fatal flaws (environmental, zoning, legal)
- Liens exceed any viable offer
- Seller is not the actual owner and cannot convey title

**Execution:** Archive in CRM. Do not pursue. Note reason for future reference.

---

## 9. State-Specific Notes

### Arizona (AZ)
- **Assignment Fee:** $12,000
- **Phone:** (928) 320-9610
- **Closing Timeline:** Typically 14-21 days cash, 30-45 days financed
- **Title Company:** Escrow-based closings (no attorney required)
- **Disclosure:** Seller Property Disclosure Statement (SPDS) required
- **Wholesaling:** Legal with proper assignment language in contract. Must have equitable interest before marketing.
- **Property Tax:** ~0.6% of assessed value. Tax lien state (liens sold at auction after delinquency).
- **HOA:** Common in metro Phoenix. Verify HOA status and any super-lien priority.
- **Foreclosure:** Non-judicial (trustee sale). 90-day process after Notice of Default.
- **Water Rights:** Verify in rural areas. Some properties have no assured water supply.

### Texas (TX)
- **Assignment Fee:** $12,000
- **Phone:** (281) 640-2291
- **Closing Timeline:** Typically 14-21 days cash, 30-45 days financed
- **Title Company:** Title company closings (no attorney required for residential)
- **Disclosure:** Seller's Disclosure Notice required (Section 5.008 Property Code)
- **Wholesaling:** Legal. TX Property Code does not restrict assignments. Must have equitable interest.
- **Property Tax:** ~1.6-2.2% of assessed value (no state income tax, higher property tax). Homestead exemption significant.
- **Homestead Protection:** TX Constitution protects homestead from most creditors. Cannot force sale for unsecured debt.
- **Foreclosure:** Non-judicial. Accelerated timeline: ~27 days after notice. Sales on first Tuesday of month.
- **Community Property:** TX is community property state. Both spouses must sign.
- **MUD/PID:** Check for Municipal Utility District or Public Improvement District assessments.

### California (CA)
- **Assignment Fee:** $15,000
- **Phone:** (424) 421-5535
- **Closing Timeline:** Typically 21-30 days cash, 45-60 days financed
- **Title Company:** Escrow company closings
- **Disclosure:** Transfer Disclosure Statement (TDS) required. Natural Hazard Disclosure (NHD) required.
- **Wholesaling:** Legal but scrutinized. AB 1616 (effective 2025) requires disclosure of assignment intent. Must provide written notice that you intend to assign the contract.
- **Property Tax:** ~1.0-1.25% of assessed value (Prop 13 basis). Supplemental tax bills at transfer.
- **Prop 13:** Reassessment at transfer to current market value. Major cost increase for buyer if long-held property.
- **Rent Control:** Some cities have rent control ordinances. Check if tenant-occupied.
- **Foreclosure:** Non-judicial. 110+ day process. Notice of Default recorded, then 90 days to Notice of Trustee Sale, then 21 days to sale.
- **Fire Zones:** Verify wildfire risk zone. Insurance availability is a major issue (2024-2026 market).
- **Earthquake:** Seismic hazard disclosure required. Some properties in liquefaction zones.

---

## 10. Output Schema

Scout returns the following JSON:

```json
{
  "analysis_id": "string (UUID)",
  "timestamp": "string (ISO 8601)",
  "version": "1.0.0",

  "property_summary": {
    "address": "string",
    "city": "string",
    "state": "string",
    "zip": "string",
    "property_type": "string",
    "beds_baths_sqft": "string (e.g., '3/2/1,450')",
    "year_built": "number",
    "occupancy": "string"
  },

  "seller_summary": {
    "name": "string",
    "motivation_keywords": ["string"],
    "timeline": "string",
    "asking_price": "number",
    "language": "string"
  },

  "valuation": {
    "arv": "number",
    "arv_confidence": "string (high|medium|low|insufficient)",
    "comps_used": "number",
    "comp_details": [
      {
        "address": "string",
        "sold_price": "number",
        "sold_date": "string",
        "distance_miles": "number",
        "adjustment": "number",
        "adjusted_price": "number"
      }
    ],
    "as_is_value": "number",
    "rehab_tier": "string (light|medium|heavy)",
    "rehab_estimate": "number",
    "rehab_itemization": [
      {
        "item": "string",
        "estimated_cost": "number"
      }
    ]
  },

  "wholesale_analysis": {
    "mao": "number",
    "multiplier_used": "number (0.70 or 0.75)",
    "assignment_fee": "number",
    "spread": "number (mao - mortgage_balance)",
    "spread_viable": "boolean",
    "gap_to_asking": "number (asking_price - mao, 0 if mao >= asking)",
    "flags": ["string"]
  },

  "novation_analysis": {
    "viable": "boolean",
    "novation_net": "number",
    "novation_fee": "number",
    "seller_payout": "number",
    "seller_payout_vs_cash": "number (novation seller_payout - mao)",
    "viability_checklist": {
      "retail_ready": "boolean",
      "equity_above_40pct": "boolean",
      "arv_above_200k": "boolean",
      "seller_wants_more": "boolean",
      "timeline_allows": "boolean"
    },
    "flags": ["string"]
  },

  "creative_analysis": {
    "sub2_viable": "boolean",
    "wrap_viable": "boolean",
    "existing_rate": "number",
    "existing_payment": "number",
    "market_rent_estimate": "number",
    "cashflow_if_wrap": "number",
    "flags": ["string"]
  },

  "scores": {
    "motivation_score": "number (0-100)",
    "motivation_breakdown": [
      { "signal": "string", "points": "number" }
    ],
    "distress_score": "number (0-100)",
    "distress_breakdown": [
      { "factor": "string", "points": "number" }
    ]
  },

  "recommendation": {
    "priority": "string (HOT|WARM|NURTURE|DEAD)",
    "strategy": "string (wholesale|novation|creative|nurture|dead)",
    "strategy_rationale": "string",
    "next_action": "string",
    "follow_up_date": "string (YYYY-MM-DD)",
    "assigned_to": "string (adriana|lily|drip-campaign|archive)"
  },

  "state_notes": ["string"],

  "warnings": ["string"],

  "raw_input_hash": "string (SHA-256 of input for audit trail)"
}
```

---

## 11. n8n Code Node Implementation

The following JavaScript runs inside an n8n Code node. It calls a language model (Groq or Claude) with the Scout system prompt and input data, then parses the structured JSON response.

### 11.1 System Prompt Builder

```javascript
// n8n Code Node: Scout Underwriter - System Prompt
// Place this in a Code node that feeds into an HTTP Request or AI node

const SCOUT_SYSTEM_PROMPT = `You are Scout, an AI underwriting agent for Equity Path Offers (Best Fit Home Solutions LLC).

Your job is to analyze wholesale real estate deals and return ONLY a valid JSON object matching the output schema. No markdown, no explanation, no commentary outside the JSON.

## Rules

### ARV Calculation
- Use top 3 comps: sold within 6 months, within 0.5 miles, same property type, within 20% sqft, +/-1 bedroom.
- Rank by: closest distance, most recent, most similar sqft.
- Adjust: +/- $35/sqft size diff, +/- $5K/bedroom, +/- $3K/bathroom, pool adjustments in AZ/TX.
- Confidence: 3+ comps = high, 2 = medium (5% discount), 1 = low (10% discount), 0 = insufficient (use market value - 15%).

### Rehab Estimation
- Light ($5K-$15K): cosmetic only (paint, carpet, landscaping). All systems functional.
- Medium ($15K-$40K): kitchen/bath updates, flooring, paint, some system repairs.
- Heavy ($40K-$80K+): roof/foundation/HVAC/plumbing/electrical, fire/water damage.
- Use midpoint of item ranges. Adjust high when multiple overlapping items.

### MAO
- ARV < $150K: MAO = (ARV * 0.70) - Repairs - Assignment Fee
- ARV >= $150K: MAO = (ARV * 0.75) - Repairs - Assignment Fee
- Assignment fees: AZ $12K, TX $12K, CA $15K

### Novation
- Novation_Net = As-Is Retail Value * 0.90 - Fee ($25K-$45K target)
- Viable when: retail-ready/cosmetic, equity > 40%, ARV > $200K, seller wants more than cash, timeline > 14 days.

### Motivation Score (0-100, cap at 100)
- Foreclosure/bankruptcy: +30
- Divorce/death/inheritance: +25
- Behind on payments: +20
- Relocation/job transfer: +20
- Tired landlord/vacant: +15
- Code violations: +15
- Tax delinquent: +15
- Quick timeline (<30 days): +10
- Multiple contacts/responded to marketing: +10
- Expressed urgency: +10

### Distress Score (0-100, cap at 100)
- Foundation issues: +25
- Roof replacement: +20
- Fire damage: +20
- Water damage: +20
- HVAC replacement: +15
- Plumbing issues: +15
- Electrical issues: +15
- Vacant > 6 months: +15
- Code violations: +15
- Mold: +10
- Deferred maintenance (3+ systems): +10

### Priority
- HOT: motivation >= 70 AND (spread viable OR novation viable)
- WARM: motivation >= 40 AND some spread potential
- NURTURE: motivation < 40 OR no current spread but future potential
- DEAD: no motivation, no equity, no path

### Strategy
- Wholesale: needs work, seller accepts discount, speed priority, spread > fee
- Novation: retail-ready, seller wants more, equity > 40%, ARV > $200K, can wait 30-90 days
- Creative (Sub2/Wrap): low equity, good loan terms, below-market rate, payment < market rent
- Nurture: not ready now, future event pending
- Dead: no path to deal

### State Notes
- AZ: escrow closings, SPDS required, tax lien state, 90-day foreclosure, check water rights rural
- TX: title company closings, both spouses must sign (community property), first-Tuesday foreclosure sales, check MUD/PID
- CA: AB 1616 assignment disclosure required, Prop 13 reassessment at transfer, fire zone/insurance check, NHD required, $15K assignment fee

Return ONLY the JSON object. No other text.`;

return [{ json: { system_prompt: SCOUT_SYSTEM_PROMPT } }];
```

### 11.2 Full Scout Execution Node

```javascript
// n8n Code Node: Scout Underwriter - Execute Analysis
// Inputs: property data from previous nodes (webhook, form, CRM pull)
// Output: structured analysis JSON
//
// Wire this into an HTTP Request node pointing to Groq or Claude API.
// Or use the n8n AI Agent node with the system prompt above.

const crypto = require('crypto');

// Gather input from previous nodes
const inputData = $input.first().json;

// Build the analysis request
const analysisRequest = {
  property: inputData.property || {},
  seller: inputData.seller || {},
  financials: inputData.financials || {},
  condition: inputData.condition || {},
  comps: inputData.comps || [],
  conversation: inputData.conversation || {}
};

// Generate input hash for audit trail
const inputHash = crypto
  .createHash('sha256')
  .update(JSON.stringify(analysisRequest))
  .digest('hex');

// Build the user prompt
const userPrompt = `Analyze this deal and return the Scout Underwriter JSON output.

INPUT DATA:
${JSON.stringify(analysisRequest, null, 2)}

INPUT HASH: ${inputHash}

Return ONLY the JSON object matching the Scout output schema.`;

// Prepare for HTTP Request node (Groq API)
const groqPayload = {
  model: 'llama-3.3-70b-versatile',
  messages: [
    {
      role: 'system',
      content: $('Scout System Prompt').first().json.system_prompt
    },
    {
      role: 'user',
      content: userPrompt
    }
  ],
  temperature: 0.1,
  max_tokens: 4000,
  response_format: { type: 'json_object' }
};

// Alternative: Claude API payload
const claudePayload = {
  model: 'claude-sonnet-4-20250514',
  max_tokens: 4000,
  system: $('Scout System Prompt').first().json.system_prompt,
  messages: [
    {
      role: 'user',
      content: userPrompt
    }
  ]
};

return [{
  json: {
    groq_payload: groqPayload,
    claude_payload: claudePayload,
    input_hash: inputHash,
    raw_input: analysisRequest
  }
}];
```

### 11.3 Response Parser Node

```javascript
// n8n Code Node: Scout Underwriter - Parse Response
// Takes the LLM response and validates/enriches the output

const response = $input.first().json;

// Extract the JSON from the LLM response
let analysis;
try {
  // Handle Groq response format
  if (response.choices && response.choices[0]) {
    analysis = JSON.parse(response.choices[0].message.content);
  }
  // Handle Claude response format
  else if (response.content && response.content[0]) {
    analysis = JSON.parse(response.content[0].text);
  }
  // Handle direct JSON
  else if (response.analysis_id) {
    analysis = response;
  }
  else {
    throw new Error('Unrecognized response format');
  }
} catch (e) {
  return [{
    json: {
      error: true,
      message: `Failed to parse Scout response: ${e.message}`,
      raw_response: JSON.stringify(response).substring(0, 500),
      recommendation: {
        priority: 'WARM',
        strategy: 'nurture',
        next_action: 'Manual review required - Scout parse failed',
        assigned_to: 'lily'
      }
    }
  }];
}

// Validate required fields
const requiredFields = [
  'valuation.arv',
  'wholesale_analysis.mao',
  'scores.motivation_score',
  'scores.distress_score',
  'recommendation.priority',
  'recommendation.strategy'
];

const warnings = analysis.warnings || [];

for (const field of requiredFields) {
  const parts = field.split('.');
  let val = analysis;
  for (const part of parts) {
    val = val?.[part];
  }
  if (val === undefined || val === null) {
    warnings.push(`Missing required field: ${field}`);
  }
}

analysis.warnings = warnings;

// Add metadata
analysis.meta = {
  processed_at: new Date().toISOString(),
  processor: 'scout-underwriter-v1.0.0',
  company: 'Equity Path Offers',
  input_hash: $('Scout Execute').first().json.input_hash
};

// Route based on priority
const routing = {
  HOT: { queue: 'immediate', assignee: 'adriana', sla_minutes: 60 },
  WARM: { queue: 'standard', assignee: 'lily', sla_minutes: 1440 },
  NURTURE: { queue: 'drip', assignee: 'wf08-drip', sla_minutes: null },
  DEAD: { queue: 'archive', assignee: null, sla_minutes: null }
};

const priority = analysis.recommendation?.priority || 'WARM';
analysis.routing = routing[priority] || routing.WARM;

return [{ json: analysis }];
```

### 11.4 n8n Workflow Wiring

```
[Webhook/Form Trigger]
        |
        v
[Enrich Property Data] -- (PropStream API, county records)
        |
        v
[Pull Comps] -- (PropStream or MLS API)
        |
        v
[Scout System Prompt] -- (Code Node 11.1)
        |
        v
[Scout Execute] -- (Code Node 11.2)
        |
        v
[HTTP Request: Groq API] -- (POST https://api.groq.com/openai/v1/chat/completions)
        |                     Headers: Authorization: Bearer {{$env.GROQ_API_KEY}}
        v                     Body: {{ $json.groq_payload }}
[Scout Parse Response] -- (Code Node 11.3)
        |
        v
[Switch: Priority]
   |         |          |         |
   HOT      WARM     NURTURE    DEAD
   |         |          |         |
   v         v          v         v
[Slack    [Podio     [WF08      [Podio
 Alert]    Update]    Drip]      Archive]
   |         |
   v         v
[Adriana  [Lily
 Queue]    Queue]
```

---

## 12. Usage Examples

### Example: High-Motivation Wholesale Deal

**Input highlights:**
- Phoenix AZ, 3/2 SFR, 1,450 sqft, built 1985
- Seller in pre-foreclosure, 3 months behind, wants out in 2 weeks
- Roof needs replacement, HVAC is 20 years old, cosmetic throughout
- 3 comps average $285K (renovated)
- Mortgage balance: $120K

**Expected output highlights:**
- ARV: ~$280K (adjusted)
- Rehab: ~$45K (heavy: roof + HVAC + cosmetic)
- MAO: ($280K x 0.75) - $45K - $12K = $153K
- Spread: $153K - $120K = $33K
- Motivation: 30 (foreclosure) + 20 (behind) + 10 (quick timeline) + 10 (urgency) = 70
- Distress: 20 (roof) + 15 (HVAC) + 10 (deferred) = 45
- Priority: HOT
- Strategy: Wholesale

### Example: Novation Candidate

**Input highlights:**
- Scottsdale AZ, 4/3 SFR, 2,800 sqft, built 2005
- Seller relocating, wants top dollar, flexible timeline (60-90 days)
- Property in good condition, needs paint and carpet only
- ARV: $450K, mortgage balance: $180K
- Seller asking $380K

**Expected output highlights:**
- ARV: $450K
- Rehab: $8K (light: paint + carpet)
- As-Is Retail: ~$440K
- Novation_Net: $440K x 0.90 = $396K
- Novation Fee: $35K (target)
- Seller Gets: $396K - $35K - $180K - $8K closing = $173K
- Equity: 60% (above 40% threshold)
- Novation viable: YES
- MAO (wholesale): ($450K x 0.75) - $8K - $12K = $317.5K
- Seller gets more via novation ($173K vs ~$197K cash but at $380K ask, novation gets closer)
- Priority: HOT
- Strategy: Novation

---

Conceived by Romuald Czlonkowski - www.aiadvisors.pl/en
