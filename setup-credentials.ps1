# Setup credentials file from template
# Usage: ./setup-credentials.ps1 or ./setup-credentials.ps1 -BaseUrl "URL" -ClientId "ID" -ClientSecret "SECRET"

param(
    [string]$BaseUrl = "https://api.services.mimecast.com",
    [string]$ClientId,
    [string]$ClientSecret,
    [string]$CredsPath = "./credentials.json",
    [string]$TemplatePath = "./credentials.json.template"
)

$ErrorActionPreference = 'Stop'

# Check if template exists
if (!(Test-Path $TemplatePath)) {
    Write-Error "Template not found at: $TemplatePath"
    exit 1
}

# Check if credentials already exist
if (Test-Path $CredsPath) {
    $response = Read-Host "credentials.json already exists. Overwrite? (y/n)"
    if ($response -ne 'y') {
        Write-Host "Skipping credentials setup."
        exit 0
    }
}

# Prompt for missing values
if ([string]::IsNullOrWhiteSpace($ClientId)) {
    $ClientId = Read-Host "Enter your Mimecast Client ID"
}

if ([string]::IsNullOrWhiteSpace($ClientSecret)) {
    $ClientSecret = Read-Host "Enter your Mimecast Client Secret" -AsSecureString
    $ClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($ClientSecret))
}

# Create credentials object
$credentials = @{
    BaseUrl = $BaseUrl
    ClientId = $ClientId
    ClientSecret = $ClientSecret
} | ConvertTo-Json

# Write to file
$credentials | Out-File -Path $CredsPath -Encoding UTF8
Write-Host "✓ Credentials file created at: $CredsPath"
Write-Host "  BaseUrl: $BaseUrl"
Write-Host "  ClientId: $($ClientId.Substring(0, [Math]::Min(4, $ClientId.Length)))***"
