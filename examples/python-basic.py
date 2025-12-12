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


def main():
    creds = load_credentials(CREDS_PATH)
    endpoint = load_endpoint(TARGET_PATH, TARGET_METHOD, API_REF_PATH)

    # TODO: Replace with your token acquisition flow
    token = os.getenv("MIMECAST_TOKEN")
    if not token:
        raise SystemExit("Set MIMECAST_TOKEN env var with a valid bearer token")

    body = {}
    result = call_mimecast(creds["BaseUrl"], token, endpoint["method"], endpoint["path"], body)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
