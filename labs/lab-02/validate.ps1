# Lab 02 — Validation Script (PowerShell)
Write-Host "Validating Lab 02 — Images, layers, and lifecycle" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }
try { docker info | Out-Null } catch { Write-Error "Cannot reach Docker daemon. Is Docker Desktop / Engine running?"; exit 1 }

$leftover = docker ps -a --format "{{.ID}} {{.Image}} {{.Status}}" | Where-Object { $_ -match "^(\S+)\s+alpine:3\.20\s+Exited" }
if ($leftover) {
  Write-Error "Found stopped alpine:3.20 container(s) that look like Lab 02 leftovers:"
  $leftover | ForEach-Object { Write-Host $_ }
  Write-Host "Hint: docker rm <id>  (or: docker container prune)" -ForegroundColor Yellow
  exit 1
}

Write-Host "Lab 02 validation passed ✔" -ForegroundColor Green
exit 0
