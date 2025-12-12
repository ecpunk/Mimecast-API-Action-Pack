# Mimecast API Action Pack

This bundle gives humans and AI a ready-to-use reference plus starter scripts to call Mimecast APIs.

## Contents
- `api-reference.json` — 257 endpoints with name, category, method, path, description, parameters, url, last_updated.
- `credentials.json.template` — fill in `ClientId` and `ClientSecret`, save as `credentials.json`.
- `examples/powershell-basic.ps1` — load JSON, select endpoint, call it with retry/backoff.
- `examples/python-basic.py` — same flow in Python `requests`.

## Quick start
1) Copy `credentials.json.template` to `credentials.json` and set `ClientId` / `ClientSecret`.
2) Open `api-reference.json` to find the endpoint you need (or search programmatically).
3) Run one of the example scripts and adjust `target_method`/`target_path`.

## Loading the JSON
**PowerShell**
```powershell
$data = Get-Content ./api-reference.json | ConvertFrom-Json
$endpoint = $data.endpoints | Where-Object { $_.path -eq '/api/account/cloud-gateway/v1/emergency-contact' -and $_.method -eq 'GET' } | Select-Object -First 1
```

**Python**
```python
import json
with open('api-reference.json') as f:
    data = json.load(f)
endpoint = next(e for e in data['endpoints'] if e['path']=='/api/account/cloud-gateway/v1/emergency-contact' and e['method']=='GET')
```

## Asking AI for a script
Provide the JSON and a clear intent. Example prompts:
1) “Using `api-reference.json`, generate a PowerShell script that calls `POST /api/account/cloud-gateway/v1/emergency-contact` with these parameters: ... Include headers, auth using `credentials.json`, and basic retry on 429.”
2) “From `api-reference.json`, find the endpoint to list blocked senders. Generate a Python `requests` script to call it, logging the request/response.”
3) “Given this payload and `api-reference.json`, produce a PowerShell function that validates required fields from the parameters list before calling the endpoint.”

## Lessons learned (for AI + humans)
- Paths in the docs URLs are reliable; use the `path` and `method` from the JSON as the source of truth.
- Categories are normalized; do not attempt to infer from URL fragments.
- Descriptions/parameters are best-effort from the docs DOM; handle missing/optional fields defensively.
- Include retry/backoff for 429/5xx; Mimecast may throttle.
- Default auth flow: client ID/secret to get a token, then bearer token in `Authorization` header.
- Keep user-agent simple; avoid noisy headers.

## Next updates
- Re-run the scraper when Mimecast updates docs (use `api-docs-scraper/run_sections.py`).
- Extend examples if you need multipart uploads or pagination helpers.
