"""
PropStream API Client — Scout's Data Source
=============================================
Pulls property details and comparable sales from PropStream API.
Normalizes output to feed directly into comp-analysis-engine.py.

Used by: Scout (underwriting agent)
Markets: Arizona, Texas, California

Usage:
    from propstream_client import analyze_address
    from comp_analysis_engine import run_scout_analysis

    data = analyze_address("123 Main St", "Phoenix", "AZ", "85001")
    result = run_scout_analysis(
        address=data["subject"]["address"],
        beds=data["subject"]["beds"],
        baths=data["subject"]["baths"],
        sqft=data["subject"]["sqft"],
        condition="medium",
        comps=data["comps"],
        state=data["subject"]["state"],
    )
"""

import os
import requests
from typing import Dict, List

PROPSTREAM_API_KEY = os.getenv("PROPSTREAM_API_KEY")
PROPSTREAM_BASE_URL = os.getenv("PROPSTREAM_BASE_URL", "https://api.propstream.example.com")

headers = {
    "Authorization": f"Bearer {PROPSTREAM_API_KEY}",
    "Content-Type": "application/json"
}


def search_property(address: str, city: str = "", state: str = "", zip_code: str = "") -> Dict:
    """Search PropStream for a property by address."""
    payload = {
        "address": address,
        "city": city,
        "state": state,
        "zip": zip_code
    }
    r = requests.post(
        f"{PROPSTREAM_BASE_URL}/property/search",
        json=payload,
        headers=headers,
        timeout=30
    )
    r.raise_for_status()
    return r.json()


def get_comps(
    property_id: str,
    radius_miles: float = 0.5,
    months_back: int = 12
) -> List[Dict]:
    """Pull comparable sales within radius and time window."""
    payload = {
        "property_id": property_id,
        "radius_miles": radius_miles,
        "months_back": months_back,
        "status": "sold"
    }
    r = requests.post(
        f"{PROPSTREAM_BASE_URL}/property/comps",
        json=payload,
        headers=headers,
        timeout=30
    )
    r.raise_for_status()
    return r.json().get("comps", [])


def normalize_subject(raw: Dict) -> Dict:
    """Normalize PropStream property data to Scout's input format."""
    return {
        "property_id": raw.get("id"),
        "address": raw.get("address"),
        "city": raw.get("city"),
        "state": raw.get("state"),
        "zip": raw.get("zip"),
        "beds": raw.get("beds"),
        "baths": raw.get("baths"),
        "sqft": raw.get("living_sqft"),
        "lot_size": raw.get("lot_sqft"),
        "year_built": raw.get("year_built"),
        "property_type": raw.get("property_type"),
        "owner_name": raw.get("owner_name"),
        "estimated_equity": raw.get("estimated_equity"),
    }


def normalize_comp(comp: Dict) -> Dict:
    """Normalize PropStream comp to Scout's comp format."""
    return {
        "address": comp.get("address"),
        "sale_price": comp.get("sale_price"),
        "sold_date": comp.get("sold_date"),
        "beds": comp.get("beds"),
        "baths": comp.get("baths"),
        "sqft": comp.get("living_sqft"),
        "distance_miles": comp.get("distance_miles"),
        "property_type": comp.get("property_type"),
    }


def analyze_address(
    address: str,
    city: str,
    state: str,
    zip_code: str
) -> Dict:
    """
    Full PropStream lookup: search property + pull comps.
    Returns normalized data ready for comp-analysis-engine.
    """
    subject_raw = search_property(address, city, state, zip_code)
    subject = normalize_subject(subject_raw)

    comps_raw = get_comps(subject["property_id"])
    comps = [normalize_comp(c) for c in comps_raw]

    return {
        "subject": subject,
        "comps": comps,
    }


if __name__ == "__main__":
    result = analyze_address("123 Main St", "Phoenix", "AZ", "85001")
    print(result)
