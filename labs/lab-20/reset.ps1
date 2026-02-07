param(
  [Parameter(Mandatory=$true)][ValidateSet("mode-a","mode-b")] [string]$Mode
)

if (-not (Test-Path ".env" -PathType Leaf)) {
  Write-Error ".env not found. Create it from .env.example first."
  exit 1
}

$envText = Get-Content ".env" -Raw
$goodRef = ($envText | Select-String -Pattern "^KNOWN_GOOD_IMAGE_REF=" -AllMatches).Line.Split("=",2)[1].Trim()
$promoted = ($envText | Select-String -Pattern "^PROMOTED_IMAGE_REF=" -AllMatches).Line.Split("=",2)[1].Trim()

if (-not $goodRef -or -not $promoted -or $goodRef -eq "REPLACE_ME" -or $promoted -eq "REPLACE_ME") {
  Write-Error "Set KNOWN_GOOD_IMAGE_REF and PROMOTED_IMAGE_REF in .env before starting the incident."
  exit 1
}

# Restore stable baseline first
$envText = ($envText -replace "(?m)^DB_HOST=.*$","DB_HOST=db")
$envText = ($envText -replace "(?m)^PROMOTED_IMAGE_REF=.*$","PROMOTED_IMAGE_REF=$goodRef")

if ($Mode -eq "mode-a") {
  $envText = ($envText -replace "(?m)^DB_HOST=.*$","DB_HOST=db-broken")
  Set-Content -Path "break-mode.txt" -Value "mode-a" -NoNewline
  Write-Host "Incident started: mode-a (misconfiguration: DB_HOST wrong)" -ForegroundColor Yellow
} else {
  $envText = ($envText -replace "(?m)^PROMOTED_IMAGE_REF=.*$","PROMOTED_IMAGE_REF=sha256:0000000000000000000000000000000000000000000000000000000000000000")
  Set-Content -Path "break-mode.txt" -Value "mode-b" -NoNewline
  Write-Host "Incident started: mode-b (bad promotion: PROMOTED_IMAGE_REF wrong)" -ForegroundColor Yellow
}

Set-Content -Path ".env" -Value $envText -NoNewline
Write-Host "NOTE: Do NOT rebuild images during the incident. Fix by updating .env and restarting the stack." -ForegroundColor Cyan
