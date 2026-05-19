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

    # Test cases: (language_code, preset, expected_partial_text)
    test_cases = [
        (None, None, "electrician"),
        ("en-US", "electrician", "certified electrician"),
        ("en-US", "ac", "AC repair technician"),
        ("en-US", "plumber", "water leakage"),
        ("en-US", "tutor", "physics home tutor"),
        ("ur-PK", "electrician", "الیکٹریشن"),
        ("ur-PK", "ac", "اے سی سروس"),
        ("ur-PK", "plumber", "پلمبر"),
        ("ur-PK", "tutor", "ہوم ٹیوٹر"),
        ("auto", "electrician", "electrician"),
        ("auto", "ac", "AC"),
        ("auto", "plumber", "leak"),
        ("auto", "tutor", "tutor"),
    ]

    for lang, preset, expected in test_cases:
        with open("dummy.wav", "rb") as f:
            data = {}
            if lang:
                data["language_code"] = lang
            if preset:
                data["preset"] = preset
                
            response = client.post(
                "/api/stt",
                data=data,
                files={"audio": ("test.wav", f, "audio/wav")}
            )

        print(f"[{lang} | {preset}] Status Code: {response.status_code}")
        assert response.status_code == 200, f"Failed for {lang}, {preset}: {response.text}"
        res_json = response.json()
        print(f"  Transcript: {res_json['transcript']}")
        assert expected.lower() in res_json["transcript"].lower(), f"Expected '{expected}' not found in '{res_json['transcript']}'"

    # Cleanup
    if os.path.exists("dummy.wav"):
        os.remove("dummy.wav")
    print("All STT integration tests passed successfully!")

if __name__ == "__main__":
    try:
        test_stt_endpoint()
    except Exception as e:
        print(f"Test failed: {e}")
        sys.exit(1)

