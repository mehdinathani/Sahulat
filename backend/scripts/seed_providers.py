import sys
import os
sys.path.append(os.getcwd())
from src.services.firebase_service import firebase_service
import uuid

def seed_providers():
    providers = [
        {
            "name": "Ali AC Services",
            "service_type": "AC Repair",
            "location": "G-13",
            "rating": 4.8,
            "price_per_hour": 1500,
            "availability": True,
            "distance": 1.2
        },
        {
            "name": "Quick Fix Plumbers",
            "service_type": "Plumber",
            "location": "G-13",
            "rating": 4.5,
            "price_per_hour": 1000,
            "availability": True,
            "distance": 0.5
        },
        {
            "name": "Islamabad Cool Tech",
            "service_type": "AC Repair",
            "location": "G-13",
            "rating": 4.2,
            "price_per_hour": 1200,
            "availability": True,
            "distance": 2.5
        },
        {
            "name": "Expert Handyman",
            "service_type": "AC Repair",
            "location": "G-13",
            "rating": 4.9,
            "price_per_hour": 2000,
            "availability": False,
            "distance": 1.0
        }
    ]

    print("Seeding providers to Firestore...")
    for provider in providers:
        doc_id = str(uuid.uuid4())
        firebase_service.add_document("providers", provider, doc_id)
        print(f"Added {provider['name']} with ID: {doc_id}")

if __name__ == "__main__":
    seed_providers()
