import urllib.request, json, sys
sys.stdout.reconfigure(encoding='utf-8')

BASE = 'https://sahulat-backend-118267129512.us-central1.run.app'

def test(label, payload):
    req = urllib.request.Request(
        f'{BASE}/api/chat',
        data=json.dumps(payload).encode(),
        headers={'Content-Type': 'application/json'}
    )
    try:
        resp = urllib.request.urlopen(req, timeout=60)
        data = json.loads(resp.read().decode())
        print(f'=== {label} (HTTP {resp.status}) ===')
        content = data.get("content", "")
        print(f'Content: {content[:300]}')
        trace = data.get("trace", [])
        print(f'Trace: {[t["step"] for t in trace]}')
        providers = data.get('providers') or []
        print(f'Providers: {len(providers)}')
        for p in providers:
            print(f'  - {p["name"]} | {p["service_type"]} | {p["location"]} | Rating: {p.get("rating")}')
        print(f'Actions: {data.get("suggested_actions", [])}')
        if data.get("booking_id"):
            print(f'Booking ID: {data["booking_id"]}')
        print()
        return data
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f'=== {label} ERROR {e.code} ===')
        print(body[:500])
        print()
        return None

# Test 1: Greeting
test('Greeting', {'role': 'user', 'content': 'hello'})

# Test 2: Plumber in DHA
data = test('Plumber in DHA', {'role': 'user', 'content': 'I need a plumber in DHA Phase 6'})

# Test 3: Electrician (Roman Urdu)
test('Electrician (Roman Urdu)', {'role': 'user', 'content': 'mujhe ek electrician chahiye DHA mein'})

# Test 4: Booking flow (if providers found)
if data and data.get('providers'):
    provider_name = data['providers'][0]['name']
    test('Booking', {'role': 'user', 'content': f'book {provider_name}'})

# Test 5: Conversational
test('Track Booking', {'role': 'user', 'content': 'track my booking'})

print("All tests complete!")
