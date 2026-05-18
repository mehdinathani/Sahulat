import sys
import os
import json
from fastapi.testclient import TestClient

# Add src to path
sys.path.append(os.getcwd())

from main import app

client = TestClient(app)

def test_stt_endpoint():
    print("Testing /api/stt endpoint...")
    # Create a dummy audio file for testing
    with open("dummy.wav", "wb") as f:
        f.write(b"RIFF" + b"\0" * 40) # Barely a WAV header

    with open("dummy.wav", "rb") as f:
        response = client.post(
            "/api/stt",
            files={"audio": ("test.wav", f, "audio/wav")}
        )

    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    else:
        print(f"Error: {response.text}")

    # Cleanup
    if os.path.exists("dummy.wav"):
        os.remove("dummy.wav")

if __name__ == "__main__":
    try:
        test_stt_endpoint()
    except Exception as e:
        print(f"Test failed: {e}")
