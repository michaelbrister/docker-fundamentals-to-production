# Lab 04 — Validation Script (PowerShell)
Write-Host "Validating Lab 04 — Networking fundamentals" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }
try { docker info | Out-Null } catch { Write-Error "Cannot reach Docker daemon. Is Docker Desktop / Engine running?"; exit 1 }

$names = @("lab04-nginx","lab04-nginx-internal")
foreach ($n in $names) {
  $exists = docker ps -a --filter "name=$n" --format "{{.Names}}"
  if ($exists) {
    Write-Error "Container '$n' still exists. Remove it to pass Lab 04."
    Write-Host "Hint: docker rm -f $n" -ForegroundColor Yellow
    exit 1
  }
}

Write-Host "Lab 04 validation passed ✔" -ForegroundColor Green
exit 0
