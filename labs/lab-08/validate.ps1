# Lab 08 — Validation Script (PowerShell)

Write-Host "Validating Lab 08 — App + DB system wiring" -ForegroundColor Cyan

try { docker version | Out-Null } catch {
  Write-Error "Docker CLI not available or Docker not running."
  exit 1
}

$ids = docker ps -a --filter "label=com.docker.compose.project=lab-08" --format "{{.ID}}"
if ($ids) {
  Write-Error "lab-08 containers still exist. Cleanup must use: docker compose down"
  exit 1
}

Write-Host "Lab 08 validation passed ✔" -ForegroundColor Green
exit 0
