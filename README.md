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
- **api-reference.json** — 257 Mimecast endpoints with method, path, description, and parameters
- **credentials.json.template** — Template for your API credentials
- **examples/** — Starter scripts for PowerShell and Python

## Prerequisites
- Mimecast API application credentials (ClientId and ClientSecret)
- VS Code with PowerShell or Python extensions (recommended)

Get API credentials: https://developer.services.mimecast.com/

## How to Use
Ask your AI assistant what you can do with the endpoints. It has access to `api-reference.json` and can:
- Find endpoints matching your use case
- Write and run scripts to call them
- Handle authentication and error handling automatically

Example prompts:
- "What can I do with quarantine endpoints?"
- "Show me how to list blocked senders"
- "Can I retrieve audit logs? Show me how"

## Notes
- Token acquisition is handled automatically
- Mimecast may throttle requests (429/5xx) — AI will handle retries
- Endpoint descriptions are best-effort; validate against Mimecast's official docs
- Refer to Mimecast's official API docs: https://developer.services.mimecast.com/
