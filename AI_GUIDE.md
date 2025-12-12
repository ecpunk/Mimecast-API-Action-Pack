# AI Guide for Mimecast API Action Pack

This file is designed for AI assistants to generate working scripts using `api-reference.json`.

## Assumptions
- All requests require authentication via a bearer token in `Authorization: Bearer <token>`.
- Token acquisition can be performed using `ClientId`/`ClientSecret` provided by the user or assumed to be available as `MIMECAST_TOKEN`.
- Use `path` and `method` from `api-reference.json` exactly as provided.
- Include exponential backoff and retries for `429` and `5xx` responses.
- Validate required parameters if present in `parameters`.

## Inputs provided to you
- `api-reference.json` — contains: `id`, `name`, `category`, `method`, `path`, `description`, `parameters`, `url`, `last_updated`.
- `credentials.json` — user-supplied file with `BaseUrl`, `ClientId`, `ClientSecret`.

## Script generation checklist
- Read `credentials.json` for `BaseUrl` (and optionally `ClientId`/`ClientSecret`).
- Obtain or read bearer token (`MIMECAST_TOKEN` env var or token exchange flow).
- Build request to `BaseUrl + path` with `Content-Type: application/json` + `Authorization: Bearer <token>`.
- Respect HTTP method from the endpoint.
- If `parameters` exist, map user inputs to request body or query appropriately.
- Implement retries on `429/5xx` with exponential backoff.
- Log or print response (JSON-encoded).

## Prompt recipes
- PowerShell: "Using `api-reference.json`, create a PowerShell script that calls `POST /api/...` with parameters X, reading `BaseUrl` from `credentials.json` and token from `MIMECAST_TOKEN`. Include retries on 429/5xx."
- Python: "Generate a Python `requests` script that finds the endpoint to list blocked senders in `api-reference.json`, calls it, and prints results. Use bearer token from `MIMECAST_TOKEN` and handle 429/5xx with exponential backoff."
- Validation: "Write a function that checks the required fields from `parameters` for endpoint `<name>` and raises if missing."

## Example skeletons
- PowerShell and Python examples are available in `examples/` and demonstrate loading the JSON, selecting an endpoint, authenticating, and retrying.

## References
- Mimecast Developer Docs: https://developer.services.mimecast.com/
