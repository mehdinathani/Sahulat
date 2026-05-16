import sys
import os
sys.path.append(os.getcwd())
from fastapi.testclient import TestClient
from main import app
import json

client = TestClient(app)

def test_chat_endpoint():
    print("Testing /api/chat endpoint...")
    response = client.post(
        "/api/chat",
        json={
            "role": "user",
            "content": "Mujhe G-13 mein AC repair wala chahiye kal subah"
        }
    )
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

if __name__ == "__main__":
    try:
        test_chat_endpoint()
    except Exception as e:
        print(f"Test failed: {e}")
