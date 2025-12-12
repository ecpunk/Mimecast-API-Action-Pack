# Mimecast API Action Pack (Human Guide)

This pack provides a curated API reference (`api-reference.json`) and starter scripts so you can quickly call Mimecast APIs from PowerShell or Python.

---

## 🚀 Quick Setup with AI (Copy & Paste)
If you want to set up a new VS Code workspace using this repo, paste this into your AI assistant (Claude, Copilot, etc.):

> I want to create a new VS Code workspace using the GitHub repository https://github.com/ecpunk/Mimecast-API-Action-Pack as the basis. Please:
> 1. Clone the repo
> 2. Create a Python virtual environment (`.venv`)
> 3. Run `setup-credentials.ps1` (or `python -m pip install requests` if on Python)
> 4. Verify the example scripts can find the credentials
> 5. Show me how to test the setup by running one of the example scripts
> 6. Give me next steps to call a real Mimecast API endpoint

---

## Contents
- `api-reference.json` — 257 endpoints with name, category, method, path, description, parameters, url, last_updated.
- `credentials.json.template` — template for API credentials (use `setup-credentials.ps1` to generate).
- `setup-credentials.ps1` — interactive script to create `credentials.json` with your Client ID and Secret.
- `examples/powershell-basic.ps1` — load JSON, select endpoint, call it with retry/backoff.
- `examples/python-basic.py` — same flow in Python `requests`.

## Prerequisites
- A Mimecast API application with `ClientId` and `ClientSecret`.
- Access to Mimecast's API environment and permissions to call the selected endpoints.
- Recommended: VS Code with PowerShell or Python extensions.

Refer to Mimecast's official documentation to set up API credentials:
https://developer.services.mimecast.com/

## Quick start
1) Run `./setup-credentials.ps1` to interactively create `credentials.json` with your Client ID and Secret.
   - Or manually: Copy `credentials.json.template` to `credentials.json` and edit in your credentials.
2) Scripts will acquire a bearer token automatically using `ClientId`/`ClientSecret` (or use `MIMECAST_TOKEN` if set). No manual token handling required.
3) Open `api-reference.json` to find the endpoint you need (or search programmatically).
4) Run one of the example scripts and adjust `TargetMethod`/`TargetPath`.

### Optional: search endpoints with the finder
```bash
python3 tools/find_endpoint.py blocked senders --limit 5
python3 tools/find_endpoint.py quarantine --category "Email Security Onboarding"
```

## VS Code workflow
1) Open this folder in VS Code. Install extensions: PowerShell and/or Python.
2) Configure your environment:
    - Set `MIMECAST_TOKEN` in your shell, or
    - Add a token acquisition step that exchanges `ClientId`/`ClientSecret` for a bearer token.
3) Run `examples/powershell-basic.ps1` or `examples/python-basic.py` and modify:
    - `TargetMethod`, `TargetPath`, and request body according to `api-reference.json`.
4) For resilience, include retry/backoff for 429/5xx responses.

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
If you use an AI assistant, see `AI_GUIDE.md` and `PROMPTS.md` for ready-to-copy prompts and assumptions.

## Notes & best practices
- Use `path` and `method` from `api-reference.json` as source of truth.
- Categories are normalized for readability.
- Descriptions/parameters are best-effort; validate inputs before calling.
- Always include retry/backoff for 429/5xx; Mimecast may throttle.
- Authenticate with a bearer token in the `Authorization` header; obtain it using your `ClientId`/`ClientSecret`.

## Next updates
- Re-run the scraper when Mimecast updates docs (use `api-docs-scraper/run_sections.py`).
- Extend examples if you need multipart uploads or pagination helpers.

