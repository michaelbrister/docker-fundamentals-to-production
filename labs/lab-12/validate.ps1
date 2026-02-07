# Lab 12 — Validation Script (PowerShell)
Write-Host "Validating Lab 12 — Distroless hardening" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }

$ids = docker ps -a --filter "label=com.docker.compose.project=lab-12" --format "{{.ID}}"
if ($ids) {
  Write-Error "lab-12 containers still exist. Cleanup must use: docker compose down"
  exit 1
}

if (-not (Test-Path "HARDENING_NOTES.md" -PathType Leaf)) {
  Write-Error "HARDENING_NOTES.md not found. Create it from HARDENING_TEMPLATE.md."
  exit 1
}

$content = Get-Content "HARDENING_NOTES.md" -Raw
$required = @("What changed","How you verified behavior without shell access","Verification evidence","Prevention / production notes")
foreach ($h in $required) {
  if ($content -notmatch [regex]::Escape($h)) {
    Write-Error "HARDENING_NOTES.md missing heading: $h"
    exit 1
  }
}

Write-Host "Lab 12 validation passed ✔" -ForegroundColor Green
exit 0
