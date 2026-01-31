# Lab 07 — Validation Script (PowerShell)

Write-Host "Validating Lab 07 — Compose + stateful services" -ForegroundColor Cyan

try { docker version | Out-Null } catch {
  Write-Error "Docker CLI not available or Docker not running."
  exit 1
}

$ids = docker ps -a --filter "label=com.docker.compose.project=lab-07" --format "{{.ID}}"
if ($ids) {
  Write-Error "lab-07 containers still exist."
  Write-Host "Hint: docker compose down" -ForegroundColor Yellow
  exit 1
}

Write-Host "Lab 07 validation passed ✔" -ForegroundColor Green
exit 0
