param(
    [string]$ApiRefPath = "../api-reference.json",
    [string]$CredsPath = "../credentials.json",
    [string]$TargetMethod = "GET",
    [string]$TargetPath = "/account/cloud-gateway/v1/emergency-contact"
)

$ErrorActionPreference = 'Stop'

function Resolve-CredentialsPath {
    param([string]$Path)
    
    # If path exists as-is, use it
    if (Test-Path $Path) { return (Resolve-Path $Path).Path }
    
    # Try relative to script directory
    $scriptDir = Split-Path -Parent $PSCommandPath
    $scriptRelative = Join-Path $scriptDir $Path
    if (Test-Path $scriptRelative) { return (Resolve-Path $scriptRelative).Path }
    
    # Try in parent directory of script location
    $parentDir = Split-Path -Parent $scriptDir
    $parentRelative = Join-Path $parentDir "credentials.json"
    if (Test-Path $parentRelative) { return (Resolve-Path $parentRelative).Path }
    
    # Not found
    return $null
}

function Get-CredentialsJson {
    param([string]$Path)
    $resolvedPath = Resolve-CredentialsPath $Path
    if (!$resolvedPath) { throw "Credentials file not found. Tried: $Path, and local directories. Run setup-credentials.ps1 first." }
    return Get-Content $resolvedPath | ConvertFrom-Json
}

function Resolve-ApiReferencePath {
    param([string]$Path)
    
    # If path exists as-is, use it
    if (Test-Path $Path) { return (Resolve-Path $Path).Path }
    
    # Try relative to script directory
    $scriptDir = Split-Path -Parent $PSCommandPath
    $scriptRelative = Join-Path $scriptDir $Path
    if (Test-Path $scriptRelative) { return (Resolve-Path $scriptRelative).Path }
    
    # Try in parent directory of script location
    $parentDir = Split-Path -Parent $scriptDir
    $parentRelative = Join-Path $parentDir "api-reference.json"
    if (Test-Path $parentRelative) { return (Resolve-Path $parentRelative).Path }
    
    # Not found
    return $null
}

function Get-Endpoint {
    param([string]$ApiPath, [string]$Method, [string]$JsonPath)
    $resolvedPath = Resolve-ApiReferencePath $JsonPath
    if (!$resolvedPath) { throw "API reference file not found. Tried: $JsonPath, and local directories." }
    $data = Get-Content $resolvedPath | ConvertFrom-Json
    $match = $data.endpoints | Where-Object { $_.path -eq $ApiPath -and $_.method -eq $Method } | Select-Object -First 1
    if (-not $match) { throw "Endpoint not found for $Method $ApiPath" }
    return $match
}

function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [int]$MaxAttempts = 4,
        [int]$BaseDelayMs = 500
    )
    for ($i=1; $i -le $MaxAttempts; $i++) {
        try {
            return & $Action
        } catch {
            $status = $_.Exception.Response.StatusCode.value__
            if ($status -in 429,500,502,503,504 -and $i -lt $MaxAttempts) {
                $delay = [int]($BaseDelayMs * [math]::Pow(2, $i-1))
                Start-Sleep -Milliseconds $delay
                continue
            }
            throw
        }
    }
}

function Invoke-MimecastApi {
    param(
        [string]$BaseUrl,
        [string]$Token,
        [string]$Method,
        [string]$Path,
        [hashtable]$Body = @{}
    )
    $uri = "$BaseUrl$Path"
    $json = if ($Body.Count -gt 0) { $Body | ConvertTo-Json -Depth 6 } else { $null }

    Invoke-WithRetry {
        Invoke-RestMethod -Method $Method -Uri $uri -Headers @{ Authorization = "Bearer $Token" } -ContentType 'application/json' -Body $json -ErrorAction Stop
    }
}

function Get-MimecastToken {
    param(
        [string]$BaseUrl,
        [string]$ClientId,
        [string]$ClientSecret
    )
    # If an env token is present, use it
    if ($env:MIMECAST_TOKEN) { return $env:MIMECAST_TOKEN }

    # Placeholder token acquisition flow: update the auth URL and payload to match Mimecast documentation for your tenant.
    # Common pattern: client credentials grant to obtain a bearer token.
    $authUri = "$BaseUrl/oauth/token"  # TODO: verify the correct auth endpoint for Mimecast
    $payload = @{ grant_type = 'client_credentials'; client_id = $ClientId; client_secret = $ClientSecret }

    try {
        $resp = Invoke-RestMethod -Method POST -Uri $authUri -Body $payload -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
        if ($resp.access_token) { return $resp.access_token }
        throw "Token response missing access_token"
    } catch {
        throw "Failed to acquire token. Update Get-MimecastToken with the correct endpoint per Mimecast docs: $($_.Exception.Message)"
    }
}

# MAIN
$creds = Get-CredentialsJson -Path $CredsPath
$endpoint = Get-Endpoint -ApiPath $TargetPath -Method $TargetMethod -JsonPath $ApiRefPath

# TODO: Replace this with your actual token acquisition flow
$token = Get-MimecastToken -BaseUrl $creds.BaseUrl -ClientId $creds.ClientId -ClientSecret $creds.ClientSecret

# Example body (edit per endpoint parameters)
$body = @{}

$response = Invoke-MimecastApi -BaseUrl $creds.BaseUrl -Token $token -Method $endpoint.method -Path $endpoint.path -Body $body
$response | ConvertTo-Json -Depth 6
