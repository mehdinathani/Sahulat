import requests
import json

url = "http://localhost:8080/api/chat"
body = {"role": "user", "content": "I need an electrician in Gulshan-e-Iqbal"}
headers = {"Content-Type": "application/json"}

try:
    response = requests.post(url, json=body, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
except Exception as e:
    print(f"Error: {e}")
