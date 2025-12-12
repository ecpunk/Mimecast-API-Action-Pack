# Mimecast API Action Pack

Curated Mimecast API reference (257 endpoints) with starter scripts for PowerShell and Python.

## Quick Start: Two Steps

### Step 1: Generate New Workspace

Paste this into your AI assistant **inside VS Code**:

```
Create and open a new VS Code workspace.

Workspace details:
- Name: Mimecast-API-Action-Pack
- Location: ~/dev
- Source repository:
  https://github.com/ecpunk/Mimecast-API-Action-Pack

Rules:
- Create ~/dev if it does not exist
- Open the workspace immediately
- Use VS Code's native workspace generation flow
- Stop once the workspace is open
```

### Step 2: Bootstrap the Workspace

Once the workspace is open, paste this into your AI assistant:

```
You are running inside the Mimecast-API-Action-Pack VS Code workspace. Tasks:
1. Create a Python virtual environment named .venv in the workspace root.
2. Activate the virtual environment.
3. Install requests.
4. Create credentials.json by copying credentials.json.template.
5. Verify api-reference.json exists.
6. Stop.

Do NOT:
- Open or generate another workspace
- Explain steps
- Ask questions
- Run example scripts
- Modify git state
```

## What's Included

- **api-reference.json** — 257 endpoints with method, path, description, parameters, and category
- **credentials.json.template** — Template for storing your API credentials
- **setup-credentials.ps1** — Interactive PowerShell script to generate credentials
- **examples/powershell-basic.ps1** — Basic PowerShell endpoint call with retry/backoff
- **examples/python-basic.py** — Basic Python endpoint call with requests library

## Prerequisites

- Mimecast API application credentials (ClientId and ClientSecret)
- VS Code with PowerShell or Python extensions (recommended)

Get API credentials: https://developer.services.mimecast.com/

## Using the API

1. **Find your endpoint** — Search `api-reference.json` for the operation you need
2. **Modify the example script** — Update `TargetMethod` and `TargetPath` to match
3. **Add your request body** — Include any parameters the endpoint requires
4. **Run the script** — Bearer token is acquired automatically from your credentials

### Example: Search endpoints

```bash
python3 tools/find_endpoint.py quarantine --limit 5
python3 tools/find_endpoint.py blocked --category "Email Security"
```

## Loading and Querying the API Reference

**PowerShell**
```powershell
$data = Get-Content ./api-reference.json | ConvertFrom-Json
$endpoint = $data.endpoints | Where-Object { $_.path -eq '/api/email-security/quarantine/v1/list' } | Select-Object -First 1
```

**Python**
```python
import json
with open('api-reference.json') as f:
    data = json.load(f)
endpoint = next((e for e in data['endpoints'] if '/quarantine/' in e['path']), None)
```

## Notes

- Token acquisition is handled automatically in both PowerShell and Python examples
- Include retry/backoff (429/5xx) for production use — Mimecast may throttle
- See `api-reference.json` for the definitive method and path for each endpoint
- Endpoint descriptions and parameters are best-effort; validate before calling

## Keeping It Updated

Re-run the scraper when Mimecast updates their documentation:

```bash
python3 api-docs-scraper/run_sections.py
```

## Need Help?

- Review the example scripts in `examples/`
- Check endpoint details in `api-reference.json`
- Refer to Mimecast's official docs: https://developer.services.mimecast.com/
