"""
Comp Analysis Engine — Scout's Core Valuation Module
=====================================================
Weighted comp scoring, outlier removal, ARV calculation,
rehab estimation, and MAO output for Equity Path Offers.

Used by: Scout (underwriting agent)
Markets: Arizona, Texas, California

Usage:
    from comp_analysis_engine import run_scout_analysis

    result = run_scout_analysis(
        address="123 Main St, Phoenix, AZ",
        beds=3, baths=2, sqft=1450,
        condition="medium",
        comps=[...],
        state="AZ"
    )
"""

from dataclasses import dataclass
from typing import List, Dict, Optional
from datetime import datetime
import math
import statistics


@dataclass
class SubjectProperty:
    address: str
    beds: float
    baths: float
    sqft: int
    year_built: int | None = None
    lot_size: int | None = None
    property_type: str = "SFR"
    condition: str = "average"
    state: str = "AZ"


def days_since(date_str: str, fmt="%Y-%m-%d") -> int:
    sold_date = datetime.strptime(date_str, fmt)
    return (datetime.now() - sold_date).days


def safe_ppsf(price: float, sqft: int) -> float:
    return price / sqft if sqft and sqft > 0 else 0


def comp_score(subject: SubjectProperty, comp: Dict) -> float:
    """Score a comp 0-100 based on similarity to subject property."""
    distance = comp.get("distance_miles", 99)
    sold_days = days_since(comp["sold_date"])
    sqft = comp.get("sqft", 0)
    beds = comp.get("beds", 0)
    baths = comp.get("baths", 0)
    prop_type = comp.get("property_type", "SFR")

    sqft_diff_pct = abs(sqft - subject.sqft) / max(subject.sqft, 1)
    bed_diff = abs(beds - subject.beds)
    bath_diff = abs(baths - subject.baths)
    type_penalty = 0 if prop_type == subject.property_type else 0.25

    score = 100
    score -= min(distance * 35, 35)       # Closer = better (max -35)
    score -= min(sold_days / 10, 25)       # More recent = better (max -25)
    score -= min(sqft_diff_pct * 50, 20)   # Similar size = better (max -20)
    score -= min(bed_diff * 5, 10)         # Same beds = better (max -10)
    score -= min(bath_diff * 5, 10)        # Same baths = better (max -10)
    score -= type_penalty * 100             # Same type = no penalty
    return max(score, 0)


def filter_comps(subject: SubjectProperty, comps: List[Dict]) -> List[Dict]:
    """Filter comps to only similar properties within range."""
    filtered = []
    for c in comps:
        # Same property type
        if c.get("property_type") != subject.property_type:
            continue
        # Within ±20% sqft
        if c.get("sqft", 0) < subject.sqft * 0.8 or c.get("sqft", 0) > subject.sqft * 1.2:
            continue
        # Within 1 mile
        if c.get("distance_miles", 99) > 1.0:
            continue
        # Sold within 12 months
        if days_since(c["sold_date"]) > 365:
            continue

        c["ppsf"] = safe_ppsf(c["sale_price"], c["sqft"])
        c["score"] = comp_score(subject, c)
        filtered.append(c)

    return sorted(filtered, key=lambda x: x["score"], reverse=True)


def remove_ppsf_outliers(comps: List[Dict], z_thresh: float = 1.5) -> List[Dict]:
    """Remove statistical outliers by price per sqft."""
    ppsf_values = [c["ppsf"] for c in comps if c["ppsf"] > 0]
    if len(ppsf_values) < 4:
        return comps

    mean_ppsf = statistics.mean(ppsf_values)
    stdev_ppsf = statistics.stdev(ppsf_values)
    if stdev_ppsf == 0:
        return comps

    cleaned = []
    for c in comps:
        z = abs((c["ppsf"] - mean_ppsf) / stdev_ppsf)
        if z <= z_thresh:
            cleaned.append(c)
    return cleaned


def weighted_arv(subject: SubjectProperty, comps: List[Dict]) -> Dict:
    """Calculate weighted ARV using top comps scored by similarity."""
    if not comps:
        return {"arv": None, "confidence": 0, "used_comps": []}

    top = comps[:6]
    total_weight = sum(c["score"] for c in top) or 1
    weighted_ppsf = sum(c["ppsf"] * c["score"] for c in top) / total_weight
    arv = round(weighted_ppsf * subject.sqft, 0)

    confidence = min(
        100,
        round(
            len(top) * 12 + statistics.mean([c["score"] for c in top]) * 0.35,
            0
        )
    )

    return {
        "arv": arv,
        "weighted_ppsf": round(weighted_ppsf, 2),
        "confidence": confidence,
        "used_comps": top
    }


def estimate_rehab(condition: str, sqft: int) -> Dict:
    """Estimate rehab cost based on condition and sqft."""
    ranges = {
        "light": (15, 25),       # Cosmetic: paint, carpet, cleaning
        "average": (20, 35),     # Dated but functional
        "medium": (30, 50),      # Kitchen/bath updates, flooring, some systems
        "heavy": (45, 80),       # Major: roof, foundation, HVAC, full gut
    }
    low_psf, high_psf = ranges.get(condition.lower(), (20, 35))
    return {
        "rehab_level": condition.lower(),
        "rehab_low": round(low_psf * sqft, 0),
        "rehab_high": round(high_psf * sqft, 0),
        "rehab_mid": round(((low_psf + high_psf) / 2) * sqft, 0),
    }


# ─── MAO Calculations ───────────────────────────────────────────

def calculate_wholesale_mao(
    arv: float,
    rehab: float,
    state: str = "AZ",
    custom_fee: Optional[float] = None
) -> Dict:
    """
    Wholesale MAO = (ARV × ratio) - Repairs - Assignment Fee
    Ratio: 0.70 for ARV < $150K, 0.75 for ARV >= $150K
    Fees: $12K for AZ/TX, $15K for CA
    """
    ratio = 0.75 if arv >= 150000 else 0.70
    fees = {"AZ": 12000, "TX": 12000, "CA": 15000}
    fee = custom_fee or fees.get(state, 12000)

    mao = round((arv * ratio) - rehab - fee, 0)

    return {
        "mao": mao,
        "ratio_used": ratio,
        "assignment_fee": fee,
        "offer_range_low": round(mao * 0.95, 0),
        "offer_range_high": round(mao * 1.05, 0),
    }


def calculate_novation_mao(
    as_is_retail: float,
    mortgage_balance: float = 0,
    novation_fee: float = 30000,
) -> Dict:
    """
    Novation MAO = As-Is Retail Value × 90% - Novation Fee
    Rich Wonders method: uses AS-IS RETAIL, not ARV after repairs.
    The 10% covers: ~6% commissions + ~2% closing + ~2% concessions
    """
    max_seller_net = round(as_is_retail * 0.90, 0)
    seller_net_offer = round(max_seller_net - novation_fee, 0)
    seller_walks_with = round(seller_net_offer - mortgage_balance, 0)

    viable = (
        novation_fee >= 25000
        and seller_walks_with > 0
        and seller_net_offer > mortgage_balance
    )

    return {
        "as_is_retail": as_is_retail,
        "max_seller_net_after_costs": max_seller_net,
        "novation_fee": novation_fee,
        "seller_net_offer": seller_net_offer,
        "seller_walks_with": seller_walks_with,
        "mortgage_balance": mortgage_balance,
        "viable": viable,
        "viability_reason": (
            "Viable — spread supports ${}K fee".format(int(novation_fee / 1000))
            if viable
            else "Not viable — "
            + (
                "fee too low"
                if novation_fee < 25000
                else "seller underwater"
                if seller_walks_with <= 0
                else "mortgage exceeds net"
            )
        ),
    }


def calculate_equity_pct(arv: float, mortgage: float) -> float:
    """Equity % = (ARV - Mortgage) / ARV × 100"""
    if arv <= 0:
        return 0
    return round((arv - mortgage) / arv * 100, 1)


# ─── Strategy Recommendation ────────────────────────────────────

def recommend_strategy(
    arv: float,
    rehab_mid: float,
    wholesale_mao: float,
    novation_result: Dict,
    motivation_score: int = 50,
    condition: str = "average",
    timeline_days: int = 30,
    equity_pct: float = 50,
) -> Dict:
    """Recommend best exit strategy based on all factors."""

    strategies = []

    # Wholesale viability
    if wholesale_mao > 0:
        strategies.append({
            "strategy": "wholesale",
            "profit": wholesale_mao * 0.05,  # rough assignment fee proxy
            "timeline": "7-14 days",
            "fit_score": 0
        })

    # Novation viability
    if novation_result["viable"]:
        strategies.append({
            "strategy": "novation",
            "profit": novation_result["novation_fee"],
            "timeline": "30-60 days",
            "fit_score": 0
        })

    # Score each strategy
    for s in strategies:
        score = 0
        if s["strategy"] == "wholesale":
            if condition in ("heavy", "medium"):
                score += 30
            if timeline_days <= 14:
                score += 25
            if equity_pct < 30:
                score += 15
            if motivation_score >= 70:
                score += 20

        elif s["strategy"] == "novation":
            if condition in ("light", "average"):
                score += 30
            if arv >= 200000:
                score += 20
            if equity_pct >= 40:
                score += 25
            if s["profit"] >= 30000:
                score += 15
            if timeline_days >= 30:
                score += 10

        s["fit_score"] = min(score, 100)

    if not strategies:
        return {
            "best_exit": "nurture" if motivation_score >= 30 else "dead",
            "reason": "No viable exit — spread too thin or no equity",
            "strategies": [],
        }

    strategies.sort(key=lambda x: x["fit_score"], reverse=True)

    return {
        "best_exit": strategies[0]["strategy"],
        "reason": f"{strategies[0]['strategy'].title()} scores highest ({strategies[0]['fit_score']}/100) — "
                  f"est. profit ${int(strategies[0]['profit']):,}",
        "strategies": strategies,
    }


# ─── Main Entry Point ───────────────────────────────────────────

def run_scout_analysis(
    address: str,
    beds: float,
    baths: float,
    sqft: int,
    condition: str,
    comps: List[Dict],
    state: str = "AZ",
    year_built: int = None,
    mortgage_balance: float = 0,
    asking_price: float = 0,
    motivation_score: int = 50,
    timeline_days: int = 30,
    novation_fee: float = 30000,
) -> Dict:
    """
    Full Scout analysis pipeline.
    Returns complete underwriting output.
    """
    # Build subject
    subject = SubjectProperty(
        address=address,
        beds=beds,
        baths=baths,
        sqft=sqft,
        year_built=year_built,
        property_type="SFR",
        condition=condition,
        state=state,
    )

    # Filter and clean comps
    filtered = filter_comps(subject, comps)
    cleaned = remove_ppsf_outliers(filtered)

    # ARV
    arv_result = weighted_arv(subject, cleaned)
    arv = arv_result["arv"] or 0

    # Rehab
    rehab = estimate_rehab(condition, sqft)

    # Equity
    equity_pct = calculate_equity_pct(arv, mortgage_balance)

    # Wholesale MAO
    wholesale = calculate_wholesale_mao(arv, rehab["rehab_mid"], state)

    # Novation (use ARV as proxy for as-is retail for now)
    # In practice, as-is retail might be ARV * condition_discount
    condition_discount = {
        "light": 0.97,
        "average": 0.92,
        "medium": 0.85,
        "heavy": 0.70,
    }
    as_is_retail = round(arv * condition_discount.get(condition, 0.92), 0)
    novation = calculate_novation_mao(as_is_retail, mortgage_balance, novation_fee)

    # Strategy
    strategy = recommend_strategy(
        arv=arv,
        rehab_mid=rehab["rehab_mid"],
        wholesale_mao=wholesale["mao"],
        novation_result=novation,
        motivation_score=motivation_score,
        condition=condition,
        timeline_days=timeline_days,
        equity_pct=equity_pct,
    )

    return {
        "subject": {
            "address": address,
            "beds": beds,
            "baths": baths,
            "sqft": sqft,
            "condition": condition,
            "state": state,
        },
        "valuation": {
            "arv": arv,
            "arv_low": round(arv * 0.95, 0) if arv else None,
            "arv_high": round(arv * 1.05, 0) if arv else None,
            "weighted_ppsf": arv_result["weighted_ppsf"],
            "confidence": arv_result["confidence"],
        },
        "rehab": rehab,
        "equity": {
            "equity_pct": equity_pct,
            "mortgage_balance": mortgage_balance,
        },
        "wholesale": wholesale,
        "novation": novation,
        "strategy": strategy,
        "comps_used": [
            {
                "address": c["address"],
                "sale_price": c["sale_price"],
                "ppsf": round(c["ppsf"], 2),
                "score": round(c["score"], 2),
            }
            for c in arv_result.get("used_comps", [])
        ],
    }


# ─── Example ────────────────────────────────────────────────────

if __name__ == "__main__":
    result = run_scout_analysis(
        address="123 Main St, Phoenix, AZ",
        beds=3,
        baths=2,
        sqft=1450,
        condition="medium",
        state="AZ",
        mortgage_balance=180000,
        motivation_score=65,
        timeline_days=30,
        novation_fee=30000,
        comps=[
            {"address": "111 A St", "beds": 3, "baths": 2, "sqft": 1420,
             "sale_price": 345000, "sold_date": "2026-02-15",
             "distance_miles": 0.22, "property_type": "SFR"},
            {"address": "222 B St", "beds": 3, "baths": 2, "sqft": 1500,
             "sale_price": 352000, "sold_date": "2026-01-10",
             "distance_miles": 0.35, "property_type": "SFR"},
            {"address": "333 C St", "beds": 4, "baths": 2, "sqft": 1600,
             "sale_price": 360000, "sold_date": "2025-12-05",
             "distance_miles": 0.41, "property_type": "SFR"},
            {"address": "444 D St", "beds": 3, "baths": 2, "sqft": 1380,
             "sale_price": 339000, "sold_date": "2026-03-01",
             "distance_miles": 0.18, "property_type": "SFR"},
        ],
    )

    import json
    print(json.dumps(result, indent=2))
