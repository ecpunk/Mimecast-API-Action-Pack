# AI Guide for Mimecast API Action Pack
This file is designed for AI assistants to generate working scripts using `api-reference.json`.

## Critical Behaviors
- **Response Status**: Check `meta.status` in the response body for the actual result. HTTP 200 does NOT mean the function succeeded — function-level failures appear in `code` and `message` fields.
- **Authentication**: All requests require `Authorization: Bearer <token>`. Token acquisition must be handled by the generated script using `ClientId`/`ClientSecret` from `credentials.json`, or read from `MIMECAST_TOKEN` env var.
- **Token Expiry**: Access tokens expire after 30 minutes. On 401 `token_expired`, refresh the token and retry.
- **Rate Limiting**: On 429 responses, read the `X-RateLimit-Reset` header (milliseconds) and wait that duration before retrying. Do not immediately retry.
- **Pagination**: Some endpoints return paginated results. Check `meta.pagination.next`/`previous` tokens in responses. To request the next page, include `pageToken` in the request body's `meta.pagination` object with the token value.
- **Endpoint paths/methods**: Use `path` and `method` from `api-reference.json` exactly as provided.
- **Retry strategy**: Include exponential backoff and retries for `429` and `5xx` responses.
- **Required parameters**: Validate required parameters from `parameters` field before making requests.
- **Regional URLs**: By default use `BaseUrl` from `credentials.json`. If the user specifies UK/US compliance, use `uk-api.services.mimecast.com` or `us-api.services.mimecast.com` instead.
- **Delegate Access**: If accessing another account, include `accountCode` in the `meta` object of the request body.
- **Content-Length**: Some endpoints have maximum content-length restrictions. Check `api-reference.json` for endpoint-specific limits.

## Inputs Provided
- `api-reference.json` — contains: `id`, `name`, `category`, `method`, `path`, `description`, `parameters`, `url`, `last_updated`.
- `credentials.json` — user-supplied file with `BaseUrl`, `ClientId`, `ClientSecret`.

## Script Generation Checklist
- Read `credentials.json` for `BaseUrl`, `ClientId`, and `ClientSecret`.
- Obtain bearer token via token exchange flow using credentials, or read `MIMECAST_TOKEN` env var.
- Build request to `BaseUrl + path` with `Content-Type: application/json` + `Authorization: Bearer <token>`.
- Respect HTTP method from the endpoint.
- If `parameters` exist, map user inputs to request body appropriately.
- Implement retries on `429/5xx` with exponential backoff and rate limit header respect.
- Check `meta.status` in response for actual success/failure, not HTTP status.
- Handle pagination by extracting `pageToken` from `meta.pagination.next` for subsequent requests.
- Log or print response (JSON-encoded).

## Prompt Examples
- PowerShell: "Using `api-reference.json`, create a PowerShell script that calls `POST /api/...` with parameters X, reading `BaseUrl` from `credentials.json` and token from `MIMECAST_TOKEN`. Include retries on 429/5xx with rate limit header respect."
- Python: "Generate a Python `requests` script that finds the endpoint to list blocked senders in `api-reference.json`, calls it, and prints results. Use bearer token from `MIMECAST_TOKEN`, handle pagination, and implement exponential backoff on 429/5xx."
- Validation: "Write a function that checks the required fields from `parameters` for endpoint `<name>` and raises if missing."

## Example Skeletons
PowerShell and Python examples are available in `examples/` and demonstrate:
- Loading `api-reference.json` and `credentials.json`
- Selecting an endpoint
- Token acquisition and refresh on expiry
- Building and executing requests
- Handling 429 rate limiting with header-based wait times
- Parsing `meta.status` for actual function result

## References
- Mimecast Developer Docs: https://developer.services.mimecast.com/
- API Response Codes and Function Failures: Check Mimecast docs for detailed failure code meanings