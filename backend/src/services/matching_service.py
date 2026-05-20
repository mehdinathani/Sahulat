from typing import List, Dict, Any, Optional, Tuple
from src.services.firebase_service import firebase_service


# Weights for the composite provider score. Tuned so a 0.5 km closer provider
# outweighs a 0.1-star rating gap, while availability is a hard gate.
_W_RATING = 0.55
_W_DISTANCE = 0.35
_W_PRICE = 0.10
_MAX_DISTANCE_KM = 10.0   # anything beyond this gets distance_score = 0
_MAX_PRICE = 2000.0       # rough ceiling for hourly rate in PKR for normalisation


def _normalize_distance(km: float) -> float:
    """0–1, closer is higher."""
    if km is None or km < 0:
        return 0.0
    if km >= _MAX_DISTANCE_KM:
        return 0.0
    return 1.0 - (km / _MAX_DISTANCE_KM)


def _normalize_price(price: float) -> float:
    """0–1, cheaper is higher. Returns 0.5 if price unknown so it doesn't penalise unfairly."""
    if not price or price <= 0:
        return 0.5
    if price >= _MAX_PRICE:
        return 0.0
    return 1.0 - (price / _MAX_PRICE)


def _score_provider(p: Dict[str, Any]) -> Tuple[float, Dict[str, float]]:
    """Return (composite_score_0_to_1, factor_breakdown)."""
    rating = float(p.get("rating", 0)) / 5.0
    distance_score = _normalize_distance(float(p.get("distance", p.get("distance_km", 999))))
    price_score = _normalize_price(float(p.get("price_per_hour", p.get("price", 0))))

    composite = (
        _W_RATING * rating
        + _W_DISTANCE * distance_score
        + _W_PRICE * price_score
    )
    factors = {
        "rating": round(rating, 3),
        "distance": round(distance_score, 3),
        "price": round(price_score, 3),
        "composite": round(composite, 3),
    }
    return composite, factors


class MatchingService:
    def __init__(self):
        self.collection = "providers"

    def find_best_matches(
        self,
        service_type: str,
        limit: int = 3,
        user_location: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """Find providers matching the service type, ranked by composite score.

        Availability is a hard filter. Within the available pool, providers are
        scored on rating + distance + price and sorted descending.
        If `user_location` is provided, an exact location match gives a small
        boost so neighbourhood relevance breaks ties.
        """
        providers = firebase_service.query_collection(self.collection, [])

        matches = [
            p for p in providers
            if service_type.lower() in p.get("service_type", "").lower()
            and p.get("availability", False)
        ]

        scored: List[Tuple[float, Dict[str, Any]]] = []
        for p in matches:
            score, factors = _score_provider(p)
            if user_location and user_location.lower() in (p.get("location") or "").lower():
                score += 0.05  # small neighbourhood-match boost
                factors["location_match"] = True
            p["_score"] = factors
            scored.append((score, p))

        scored.sort(key=lambda kv: -kv[0])
        return [p for _, p in scored[:limit]]

    def get_recommendation_reasoning(self, provider: Dict[str, Any]) -> str:
        """Plain-English reasoning that cites the actual factors used to rank."""
        name = provider.get("name", "This provider")
        rating = provider.get("rating")
        dist = provider.get("distance", provider.get("distance_km"))
        price = provider.get("price_per_hour", provider.get("price"))
        experience = provider.get("experience")
        location = provider.get("location")

        bits: List[str] = []
        if rating is not None:
            bits.append(f"rated **{rating}/5.0**")
        if dist is not None:
            bits.append(f"only **{dist} km** away")
        if price:
            bits.append(f"Rs. {price}/hr")
        if experience:
            bits.append(f"{experience} experience")
        if location:
            bits.append(f"based in {location}")

        if not bits:
            return f"{name} is the best available match."

        return f"{name} is " + ", ".join(bits) + "."


matching_service = MatchingService()
