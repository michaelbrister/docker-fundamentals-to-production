# Lab 09 — Validation Script (PowerShell)

Write-Host "Validating Lab 09 — Compose builds the API image" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }

try { docker image inspect dzth/lab09-notes-api:0.1 | Out-Null } catch {
  Write-Error "Image dzth/lab09-notes-api:0.1 not found. Run: docker compose build"
  exit 1
}

$ids = docker ps -a --filter "label=com.docker.compose.project=lab-09" --format "{{.ID}}"
if ($ids) {
  Write-Error "lab-09 containers still exist. Cleanup must use: docker compose down"
  exit 1
}

Write-Host "Lab 09 validation passed ✔" -ForegroundColor Green
exit 0
