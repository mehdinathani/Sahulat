import urllib.request
import json
import urllib.error

BASE = 'https://sahulat-ai-backend-823935698067.us-central1.run.app'
boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
body = []
body.append(f'--{boundary}'.encode())
body.append(b'Content-Disposition: form-data; name="audio"; filename="test.wav"')
body.append(b'Content-Type: audio/wav')
body.append(b'')
body.append(b'RIFF' + b'\0' * 40)
body.append(f'--{boundary}--'.encode())
body.append(b'')
request_body = b'\r\n'.join(body)

req = urllib.request.Request(
    f'{BASE}/api/stt',
    data=request_body,
    headers={
        'Content-Type': f'multipart/form-data; boundary={boundary}',
        'Content-Length': str(len(request_body))
    }
)
try:
    resp = urllib.request.urlopen(req, timeout=30)
    print(json.loads(resp.read().decode()))
except urllib.error.HTTPError as e:
    print(f"HTTP Error {e.code}: {e.read().decode()}")
except Exception as e:
    print(f"Error: {e}")
