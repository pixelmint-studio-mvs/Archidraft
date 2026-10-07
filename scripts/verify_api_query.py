import urllib.request
import json

try:
    req = urllib.request.Request('http://localhost:8787/api/draughtsman/summary')
    req.add_header('Authorization', 'Bearer dummy_token')
    response = urllib.request.urlopen(req)
    print(response.read())
except Exception as e:
    print(e)
