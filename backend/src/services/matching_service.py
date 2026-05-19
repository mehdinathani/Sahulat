from typing import List, Dict, Any, Optional
from src.services.firebase_service import firebase_service

class MatchingService:
    def __init__(self):
        self.collection = "providers"

    def find_best_matches(self, service_type: str, limit: int = 3) -> List[Dict[str, Any]]:
        """
        Find providers matching the service type and rank them by rating and distance.
        """
        # Fetch all providers (in a real app, we'd use Firestore indexing/geo-queries)
        # For mock, we fetch all and filter in memory
        providers = firebase_service.query_collection(self.collection, [])
        
        # Filter by service type (case-insensitive)
        matches = [
            p for p in providers 
            if service_type.lower() in p.get("service_type", "").lower() 
            and p.get("availability", False)
        ]
        
        # Sort by rating (desc) and then distance (asc)
        matches.sort(key=lambda x: (-x.get("rating", 0), x.get("distance_km", 999)))
        
        return matches[:limit]

    def get_recommendation_reasoning(self, provider: Dict[str, Any]) -> str:
        """
        Generate a natural language reason for recommending this provider.
        """
        name = provider.get("name")
        rating = provider.get("rating")
        dist = provider.get("distance_km")
        
        reasons = [
            f"{name} is highly rated ({rating}/5.0).",
            f"They are very close to you ({dist} km)."
        ]
        
        return " ".join(reasons)

matching_service = MatchingService()
