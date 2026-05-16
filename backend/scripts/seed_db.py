import sys
import os
import json

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

def seed():
    providers = [
        {
            "name": "Arshad Electrics",
            "service_type": "electrician",
            "rating": 4.8,
            "price_per_hour": 500,
            "distance": 1.2,
            "availability": True,
            "location": "Gulshan-e-Iqbal, Karachi",
            "experience": "10 years"
        },
        {
            "name": "Imran Wireman",
            "service_type": "electrician",
            "rating": 4.5,
            "price_per_hour": 400,
            "distance": 2.5,
            "availability": True,
            "location": "Johar, Karachi",
            "experience": "5 years"
        },
        {
            "name": "Sajid Plumber",
            "service_type": "plumber",
            "rating": 4.9,
            "price_per_hour": 600,
            "distance": 0.8,
            "availability": True,
            "location": "DHA, Karachi",
            "experience": "15 years"
        },
        {
            "name": "Kashif AC Services",
            "service_type": "ac_repair",
            "rating": 4.7,
            "price_per_hour": 1200,
            "distance": 3.0,
            "availability": True,
            "location": "North Nazimabad, Karachi",
            "experience": "8 years"
        }
    ]

    db_content = {
        "providers": {str(i): p for i, p in enumerate(providers)}
    }

    with open("mock_db.json", "w") as f:
        json.dump(db_content, f, indent=2)
    
    print("Successfully seeded mock_db.json with providers.")

if __name__ == "__main__":
    seed()
