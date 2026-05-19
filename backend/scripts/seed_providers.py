import sys
import os
sys.path.append(os.getcwd())
from src.services.firebase_service import firebase_service
import uuid

def seed_providers():
    providers = [
        # AC Repair providers
        {
            "name": "Ali AC Services",
            "service_type": "AC Repair",
            "location": "G-13",
            "rating": 4.8,
            "price_per_hour": 1500,
            "price_range": "Rs 1,200–1,800",
            "availability": True,
            "distance_km": 1.2
        },
        {
            "name": "Islamabad Cool Tech",
            "service_type": "AC Repair",
            "location": "G-13",
            "rating": 4.2,
            "price_per_hour": 1200,
            "price_range": "Rs 1,000–1,500",
            "availability": True,
            "distance_km": 2.5
        },
        {
            "name": "CoolAir DHA",
            "service_type": "AC Repair",
            "location": "DHA",
            "rating": 4.6,
            "price_per_hour": 1800,
            "price_range": "Rs 1,500–2,200",
            "availability": True,
            "distance_km": 1.0
        },
        # Plumber providers
        {
            "name": "Quick Fix Plumbers",
            "service_type": "Plumber",
            "location": "G-13",
            "rating": 4.5,
            "price_per_hour": 1000,
            "price_range": "Rs 800–1,200",
            "availability": True,
            "distance_km": 0.5
        },
        {
            "name": "DHA Plumbing Experts",
            "service_type": "Plumber",
            "location": "DHA",
            "rating": 4.7,
            "price_per_hour": 1200,
            "price_range": "Rs 1,000–1,500",
            "availability": True,
            "distance_km": 0.8
        },
        {
            "name": "Karachi Pipe Masters",
            "service_type": "Plumber",
            "location": "Gulshan-e-Iqbal",
            "rating": 4.3,
            "price_per_hour": 900,
            "price_range": "Rs 700–1,100",
            "availability": True,
            "distance_km": 1.5
        },
        # Electrician providers
        {
            "name": "BrightSpark Electricians",
            "service_type": "Electrician",
            "location": "DHA",
            "rating": 4.9,
            "price_per_hour": 1400,
            "price_range": "Rs 1,200–1,800",
            "availability": True,
            "distance_km": 0.6
        },
        {
            "name": "PowerLine Electric",
            "service_type": "Electrician",
            "location": "Johar Town",
            "rating": 4.4,
            "price_per_hour": 1100,
            "price_range": "Rs 900–1,300",
            "availability": True,
            "distance_km": 1.8
        },
        {
            "name": "Clifton Wiring Solutions",
            "service_type": "Electrician",
            "location": "Clifton",
            "rating": 4.6,
            "price_per_hour": 1500,
            "price_range": "Rs 1,200–1,800",
            "availability": True,
            "distance_km": 1.0
        },
        # Tutor providers
        {
            "name": "Smart Tutors Academy",
            "service_type": "Tutor",
            "location": "DHA",
            "rating": 4.8,
            "price_per_hour": 2000,
            "price_range": "Rs 1,500–2,500",
            "availability": True,
            "distance_km": 0.9
        },
        {
            "name": "Gulshan Learning Hub",
            "service_type": "Tutor",
            "location": "Gulshan-e-Iqbal",
            "rating": 4.5,
            "price_per_hour": 1500,
            "price_range": "Rs 1,200–1,800",
            "availability": True,
            "distance_km": 2.0
        },
        # Carpenter providers
        {
            "name": "Ustad Furniture Works",
            "service_type": "Carpenter",
            "location": "Johar Town",
            "rating": 4.7,
            "price_per_hour": 1300,
            "price_range": "Rs 1,000–1,600",
            "availability": True,
            "distance_km": 1.3
        },
        {
            "name": "DHA WoodCraft",
            "service_type": "Carpenter",
            "location": "DHA",
            "rating": 4.4,
            "price_per_hour": 1600,
            "price_range": "Rs 1,300–2,000",
            "availability": True,
            "distance_km": 0.7
        },
    ]

    print(f"Seeding {len(providers)} providers to Firestore...")
    for provider in providers:
        doc_id = str(uuid.uuid4())
        firebase_service.add_document("providers", provider, doc_id)
        print(f"  Added {provider['name']} ({provider['service_type']}, {provider['location']}) with ID: {doc_id}")
    print("Seeding complete!")

if __name__ == "__main__":
    seed_providers()

