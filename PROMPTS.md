# Prompt Gallery (Copy/Paste)

Use these with Copilot Chat (or your AI assistant) inside VS Code after opening this repo.

## Find and call an endpoint (PowerShell)
"""
Using `api-reference.json`, find the endpoint that lists [describe resource]. Generate a PowerShell script that:
- Reads `BaseUrl`, `ClientId`, `ClientSecret` from `credentials.json`
- Obtains a bearer token automatically
- Calls the endpoint with retries on 429/5xx
- Prints the results as JSON
"""

## Bulk action with filtering (Python)
"""
From `api-reference.json`, identify the endpoint that retrieves [items]. Generate a Python script that:
- Authenticates using client credentials from `credentials.json`
- Paginates if needed
- Filters for records where [condition]
- Outputs CSV with fields A,B,C
"""

## Validate inputs against parameters
"""
Given `api-reference.json` and endpoint `<name>` / `<method> <path>`, write a function that validates a payload against the endpoint's `parameters`, raising if required fields are missing.
"""

## Transform and enrich
"""
Create a PowerShell script that calls `<METHOD> <PATH>`, deduplicates results by `<key>`, and outputs top 10 domains. Include retries and basic logging.
"""
