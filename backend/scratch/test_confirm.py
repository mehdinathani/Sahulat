import urllib.request
import json

url = "https://sahulat-backend-118267129512.us-central1.run.app/api/booking/confirm"
payload = {
    "provider_id": "Islamabad Cool Tech",
    "request_id": None
}

req = urllib.request.Request(
    url,
    data=json.dumps(payload).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST'
)

try:
    print(f"Sending booking confirm POST to {url}...")
    with urllib.request.urlopen(req) as response:
        status_code = response.getcode()
        body = response.read().decode('utf-8')
        print(f"Status Code: {status_code}")
        print(f"Response: {body}")
except urllib.error.HTTPError as e:
    print(f"HTTP Error {e.code}: {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")
