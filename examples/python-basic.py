import json
import os
import time
import requests

API_REF_PATH = "../api-reference.json"
CREDS_PATH = "../credentials.json"
TARGET_METHOD = "GET"
TARGET_PATH = "/api/account/cloud-gateway/v1/emergency-contact"


def load_credentials(path: str) -> dict:
    with open(path) as f:
        return json.load(f)


def load_endpoint(api_path: str, method: str, json_path: str) -> dict:
    with open(json_path) as f:
        data = json.load(f)
    for ep in data.get("endpoints", []):
        if ep.get("path") == api_path and ep.get("method") == method:
            return ep
    raise SystemExit(f"Endpoint not found for {method} {api_path}")


def invoke_with_retry(fn, max_attempts=4, base_delay=0.5):
    for attempt in range(1, max_attempts + 1):
        try:
            return fn()
        except requests.HTTPError as exc:
            status = exc.response.status_code
            if status in {429, 500, 502, 503, 504} and attempt < max_attempts:
                delay = base_delay * (2 ** (attempt - 1))
                time.sleep(delay)
                continue
            raise


def call_mimecast(base_url: str, token: str, method: str, path: str, body: dict | None = None):
    url = f"{base_url}{path}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    def do_call():
        resp = requests.request(method, url, headers=headers, json=body)
        resp.raise_for_status()
        return resp.json()
    return invoke_with_retry(do_call)


def get_mimecast_token(base_url: str, client_id: str, client_secret: str) -> str:
    # If env var is set, prefer it
    token = os.getenv("MIMECAST_TOKEN")
    if token:
        return token

    # Placeholder client credentials flow — update auth URL/payload to match Mimecast documentation for your tenant.
    auth_url = f"{base_url}/oauth/token"  # TODO: verify the correct Mimecast auth endpoint
    payload = {
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
    }
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    resp = requests.post(auth_url, data=payload, headers=headers)
    resp.raise_for_status()
    data = resp.json()
    if "access_token" not in data:
        raise RuntimeError("Token response missing access_token — update get_mimecast_token per Mimecast docs")
    return data["access_token"]


def main():
    creds = load_credentials(CREDS_PATH)
    endpoint = load_endpoint(TARGET_PATH, TARGET_METHOD, API_REF_PATH)

    token = get_mimecast_token(creds["BaseUrl"], creds["ClientId"], creds["ClientSecret"]) 

    body = {}
    result = call_mimecast(creds["BaseUrl"], token, endpoint["method"], endpoint["path"], body)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
