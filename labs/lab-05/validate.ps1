# Lab 05 — Validation Script (PowerShell)
Write-Host "Validating Lab 05 — Docker Compose fundamentals" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }
try { docker info | Out-Null } catch { Write-Error "Cannot reach Docker daemon. Is Docker Desktop / Engine running?"; exit 1 }
try { docker compose version | Out-Null } catch { Write-Error "docker compose not available. Install Docker Desktop or Compose plugin."; exit 1 }

$ids = docker ps -a --filter "label=com.docker.compose.project=lab-05" --format "{{.ID}}"
if ($ids) {
  Write-Error "Compose project 'lab-05' still has containers. Run: docker compose down"
  exit 1
}

Write-Host "Lab 05 validation passed ✔" -ForegroundColor Green
exit 0
