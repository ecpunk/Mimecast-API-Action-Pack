param(
    [string]$ApiRefPath = "../api-reference.json",
    [string]$CredsPath = "../credentials.json",
    [string]$OutputPath = "AcctInfo.debug.json",
    [string]$NotesPath = "../endpoint-notes.json"
)

$ErrorActionPreference = 'Stop'

function Resolve-CredentialsPath {
    param([string]$Path)
    if (Test-Path $Path) { return (Resolve-Path $Path).Path }
    $scriptDir = Split-Path -Parent $PSCommandPath
    $scriptRelative = Join-Path $scriptDir $Path
    if (Test-Path $scriptRelative) { return (Resolve-Path $scriptRelative).Path }
    $parentDir = Split-Path -Parent $scriptDir
    $parentRelative = Join-Path $parentDir "credentials.json"
    if (Test-Path $parentRelative) { return (Resolve-Path $parentRelative).Path }
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
    if (Test-Path $Path) { return (Resolve-Path $Path).Path }
    $scriptDir = Split-Path -Parent $PSCommandPath
    $scriptRelative = Join-Path $scriptDir $Path
    if (Test-Path $scriptRelative) { return (Resolve-Path $scriptRelative).Path }
    $parentDir = Split-Path -Parent $scriptDir
    $parentRelative = Join-Path $parentDir "api-reference.json"
    if (Test-Path $parentRelative) { return (Resolve-Path $parentRelative).Path }
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

function Get-ErrorDetail {
    param($ErrorRecord)
    try {
        $resp = $ErrorRecord.Exception.Response
        if ($resp -and $resp.GetResponseStream) {
            $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $body = $reader.ReadToEnd()
            if ($body) { return $body }
        }
    } catch { }
    return $ErrorRecord.Exception.Message
}

function Get-StatusCode {
    param($ErrorRecord)
    try { return $ErrorRecord.Exception.Response?.StatusCode?.value__ } catch { return $null }
}

function Get-ErrorCodeFromBody {
    param([string]$Body)
    if (-not $Body) { return $null }
    try {
        $obj = $Body | ConvertFrom-Json -ErrorAction Stop
        # Mimecast error shape often: { "fail": [ { "code": "app_forbidden", "message": "..." } ] }
        if ($obj.fail -and $obj.fail.Count -gt 0 -and $obj.fail[0].code) {
            return [string]$obj.fail[0].code
        }
    } catch { }
    return $null
}

function Resolve-NotesPath {
    param([string]$Path)
    if (Test-Path $Path) { return (Resolve-Path $Path).Path }
    $scriptDir = Split-Path -Parent $PSCommandPath
    $scriptRelative = Join-Path $scriptDir $Path
    if (Test-Path $scriptRelative) { return (Resolve-Path $scriptRelative).Path }
    $parentDir = Split-Path -Parent $scriptDir
    $parentRelative = Join-Path $parentDir "endpoint-notes.json"
    if (Test-Path $parentRelative) { return (Resolve-Path $parentRelative).Path }
    return $null
}

function Get-EndpointNotesMap {
    param([string]$Path)
    $resolved = Resolve-NotesPath $Path
    if (-not $resolved) { return @{} }
    try {
        $notesJson = Get-Content $resolved | ConvertFrom-Json
        $map = @{}
        foreach ($n in $notesJson.notes) {
            $key = "{0} {1}" -f $n.method, $n.path
            $map[$key] = $n.note
        }
        return $map
    } catch {
        return @{}
    }
}

function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [int]$MaxAttempts = 4,
        [int]$BaseDelayMs = 500
    )
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            return & $Action
        } catch {
            $status = $_.Exception.Response?.StatusCode?.value__
            if ($status -and ($status -in 429, 500, 502, 503, 504) -and $i -lt $MaxAttempts) {
                $delay = [int]($BaseDelayMs * [math]::Pow(2, $i - 1))
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
        if ($Method -eq 'GET' -and -not $json) {
            Invoke-RestMethod -Method $Method -Uri $uri -Headers @{ Authorization = "Bearer $Token" } -ErrorAction Stop
        } else {
            Invoke-RestMethod -Method $Method -Uri $uri -Headers @{ Authorization = "Bearer $Token" } -ContentType 'application/json' -Body $json -ErrorAction Stop
        }
    }
}

function Get-MimecastToken {
    param(
        [string]$BaseUrl,
        [string]$ClientId,
        [string]$ClientSecret
    )
    if ($env:MIMECAST_TOKEN) { return $env:MIMECAST_TOKEN }
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

$accountEndpoints = @(
    @{ Name = 'Identity WhoAmI'; Method = 'GET'; Path = '/identity/whoami'; Body = @{} },
    @{ Name = 'Account Profile'; Method = 'POST'; Path = '/api/account/get-account'; Body = @{} },
    @{ Name = 'Dashboard Notifications'; Method = 'POST'; Path = '/api/account/get-dashboard-notifications'; Body = @{} },
    @{ Name = 'Support Info'; Method = 'POST'; Path = '/api/account/get-support-info'; Body = @{} },
    @{ Name = 'Emergency Contact'; Method = 'GET'; Path = '/account/cloud-gateway/v1/emergency-contact'; Body = @{} },
    @{ Name = 'Provisioning Packages'; Method = 'POST'; Path = '/api/provisioning/get-packages'; Body = @{} }
)

$creds = Get-CredentialsJson -Path $CredsPath
$token = Get-MimecastToken -BaseUrl $creds.BaseUrl -ClientId $creds.ClientId -ClientSecret $creds.ClientSecret

$successCount = 0
$failCount = 0
$failedEndpoints = @()
$results = @()
$notesMap = Get-EndpointNotesMap -Path $NotesPath

Write-Host "=== Mimecast Account Information ===" -ForegroundColor Cyan
Write-Host "Querying $($accountEndpoints.Count) endpoints...`n"

foreach ($item in $accountEndpoints) {
    try {
        $endpoint = Get-Endpoint -ApiPath $item.Path -Method $item.Method -JsonPath $ApiRefPath
        Write-Host "`n--- $($item.Name) [$($endpoint.method) $($endpoint.path)] ---" -ForegroundColor Green
        $key = "{0} {1}" -f $endpoint.method, $endpoint.path
        if ($notesMap.ContainsKey($key)) {
            Write-Host "[INFO] Note: $($notesMap[$key])" -ForegroundColor Yellow
        }
        $bodyToSend = $item.Body
        $response = Invoke-MimecastApi -BaseUrl $creds.BaseUrl -Token $token -Method $endpoint.method -Path $endpoint.path -Body $bodyToSend
        $results += @{ Name = $item.Name; Method = $endpoint.method; Path = $endpoint.path; Status = 'success'; Note = $notesMap[$key]; Response = $response }
        $successCount++
    } catch {
        $detail = Get-ErrorDetail $_
        $status = Get-StatusCode $_
        $failCount++
        $failedEndpoints += @{ Name = $item.Name; Status = $status; Detail = $detail }
        $key = "{0} {1}" -f $endpoint.method, $endpoint.path
        $results += @{ Name = $item.Name; Method = $endpoint.method; Path = $endpoint.path; Status = 'error'; Note = $notesMap[$key]; HttpStatus = $status; Error = $detail }
        
        switch ($status) {
            403 {
                $msg = if ($item.Name -eq 'Identity WhoAmI') {
                    '403 Forbidden - This endpoint appears restricted to partner accounts. It may not be available for your tenant.'
                $errCode = Get-ErrorCodeFromBody $detail
                } else {
                    '403 Forbidden - Your API app lacks permission for this endpoint. Contact your Mimecast admin.'
                }
                Write-Host "`n[WARN] $($item.Name): $msg`nResponse: $detail" -ForegroundColor Yellow
                    403 {
            401 { Write-Host "`n[ERROR] $($item.Name): 401 Unauthorized - Token invalid or expired. Check MIMECAST_TOKEN or credentials.json.`nResponse: $detail" -ForegroundColor Red }
            404 { Write-Host "`n[WARN] $($item.Name): 404 Not Found - Endpoint may not exist in your tenant/region. Verify path in api-reference.json.`nResponse: $detail" -ForegroundColor Yellow }
            default { Write-Host "`n[ERROR] $($item.Name): HTTP $status - $detail" -ForegroundColor Red }
                            if ($errCode -eq 'app_forbidden') {
                                '403 Forbidden (app_forbidden) - Your API app lacks scope for this endpoint. Contact your Mimecast admin.'
                            } else {
                                '403 Forbidden - Your API app lacks permission for this endpoint. Contact your Mimecast admin.'
                            }
        continue
    }
}

Write-Host "`n`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Successful: $successCount / $($accountEndpoints.Count)" -ForegroundColor Green
Write-Host "Failed: $failCount / $($accountEndpoints.Count)" -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Red' })

if ($failedEndpoints.Count -gt 0) {
    Write-Host "`nFailed Endpoints:" -ForegroundColor Yellow
    foreach ($failed in $failedEndpoints) {
        Write-Host "  - $($failed.Name) (HTTP $($failed.Status))" -ForegroundColor Yellow
    }
}

# Write debug output to file (overwrite each run)
$scriptDir = Split-Path -Parent $PSCommandPath
$outFull = if ([System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath } else { Join-Path $scriptDir $OutputPath }
$debugPayload = @{ 
    timestamp = (Get-Date).ToString('o');
    baseUrl = $creds.BaseUrl;
    total = $accountEndpoints.Count;
    success = $successCount;
    failed = $failCount;
    endpoints = $results
}
$jsonOut = $debugPayload | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($outFull, $jsonOut, [System.Text.Encoding]::UTF8)
Write-Host "`nWrote debug output to: $outFull" -ForegroundColor Cyan