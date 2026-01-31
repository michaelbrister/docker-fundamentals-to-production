# Lab 03 — Validation Script (PowerShell)
Write-Host "Validating Lab 03 — Volumes, bind mounts, and persistence" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }
try { docker info | Out-Null } catch { Write-Error "Cannot reach Docker daemon. Is Docker Desktop / Engine running?"; exit 1 }

$leftover = docker ps -a --format "{{.ID}} {{.Image}} {{.Status}}" | Where-Object { $_ -match "^(\S+)\s+alpine:3\.20\s+Exited" }
if ($leftover) {
  Write-Error "Found stopped alpine:3.20 container(s). Remove them to pass Lab 03:"
  $leftover | ForEach-Object { Write-Host $_ }
  Write-Host "Hint: docker rm <id>  (or: docker container prune)" -ForegroundColor Yellow
  exit 1
}

try { docker volume inspect lab03_data | Out-Null } catch { Write-Warning "Volume 'lab03_data' not found. OK if removed during optional cleanup." }

Write-Host "Lab 03 validation passed ✔" -ForegroundColor Green
exit 0
