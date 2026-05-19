import httpx
import json

url = "https://sahulat-backend-118267129512.us-central1.run.app/api/chat"
payload = {
    "role": "user",
    "content": "I need an electrician in Gulshan-e-Iqbal"
}

try:
    print(f"Sending request to {url}...")
    response = httpx.post(url, json=payload, timeout=30.0)
    print(f"Status Code: {response.status_code}")
    print("Response JSON:")
    print(json.dumps(response.json(), indent=2))
except Exception as e:
    print(f"Error occurred: {e}")
