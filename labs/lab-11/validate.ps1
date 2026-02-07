# Lab 11 — Validation Script (PowerShell)
Write-Host "Validating Lab 11 — Debugging & Break/Fix" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }

$projects = @("lab-11-s1","lab-11-s2","lab-11-s3","lab-11-s4")
foreach ($p in $projects) {
  $ids = docker ps -a --filter "label=com.docker.compose.project=$p" --format "{{.ID}}"
  if ($ids) {
    Write-Error "Found leftover containers for project $p. Cleanup must use: docker compose down"
    exit 1
  }
}

if (-not (Test-Path "RUNBOOK.md" -PathType Leaf)) {
  Write-Error "RUNBOOK.md not found in labs/lab-11. Create it from RUNBOOK_TEMPLATE.md."
  exit 1
}

$required = @("Scenario 1","Scenario 2","Scenario 3","Scenario 4")
$content = Get-Content "RUNBOOK.md" -Raw
foreach ($h in $required) {
  if ($content -notmatch [regex]::Escape($h)) {
    Write-Error "RUNBOOK.md missing heading: $h"
    exit 1
  }
}

Write-Host "Lab 11 validation passed ✔" -ForegroundColor Green
exit 0
