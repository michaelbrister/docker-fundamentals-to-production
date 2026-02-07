# Lab 15 — Validation Script (PowerShell)
Write-Host "Validating Lab 15 — Observability" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }

$required = @(
  "README.md",
  ".env.example",
  "compose.yaml",
  "compose.secrets.yaml",
  "OBSERVABILITY_NOTES_TEMPLATE.md",
  "hints.md",
  "instructor-notes.md",
  "solutions/solution.md",
  "api/Dockerfile.distroless",
  "api/main.go",
  "db/init.sql",
  "secrets/db_password.txt.example"
)

foreach ($f in $required) {
  if (-not (Test-Path $f -PathType Leaf)) { Write-Error "Missing required file: $f"; exit 1 }
}

if (-not (Test-Path "OBSERVABILITY_NOTES.md" -PathType Leaf)) {
  Write-Error "OBSERVABILITY_NOTES.md not found. Create it from OBSERVABILITY_NOTES_TEMPLATE.md."
  exit 1
}
if (-not (Test-Path ".env" -PathType Leaf)) {
  Write-Error ".env not found. Create it from .env.example."
  exit 1
}
if (-not (Test-Path "secrets/db_password.txt" -PathType Leaf)) {
  Write-Error "secrets/db_password.txt not found. Create it from secrets/db_password.txt.example (DO NOT COMMIT)."
  exit 1
}

$secretValue = (Get-Content "secrets/db_password.txt" -Raw).Trim()
if (-not $secretValue -or $secretValue.Length -lt 12) {
  Write-Error "secrets/db_password.txt must be a unique value (>= 12 chars). Hint: lab15-supersecret-change-me"
  exit 1
}

# Ensure no existing lab-15 containers
$ids = docker ps -a --filter "label=com.docker.compose.project=lab-15" --format "{{.ID}}"
if ($ids) {
  Write-Error "lab-15 containers already exist. Cleanup first with: docker compose -f compose.yaml -f compose.secrets.yaml down"
  exit 1
}

Write-Host "Bringing up lab-15 stack for smoke validation..." -ForegroundColor Cyan
docker compose -f compose.yaml -f compose.secrets.yaml up -d --build | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "docker compose up failed"; exit 1 }

function Cleanup { docker compose -f compose.yaml -f compose.secrets.yaml down | Out-Null }

try {
  Write-Host "Waiting for readiness..." -ForegroundColor Cyan
  $ready = $false
  for ($i=0; $i -lt 40; $i++) {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8081/readyz" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch { }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw "readyz never became ready" }

  Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8081/metrics" -TimeoutSec 5 | Out-Null
  Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8081/notes" -TimeoutSec 5 | Out-Null

  # Generate traffic
  Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8081/notes" -TimeoutSec 5 | Out-Null
  Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8081/notes" -Method Post -Headers @{ "content-type"="application/json" } -Body '{"message":"validator"}' -TimeoutSec 5 | Out-Null
  Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8081/notes" -TimeoutSec 5 | Out-Null

  $m = (Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8081/metrics" -TimeoutSec 5).Content
  if ($m -notmatch "http_requests_total") { throw "metrics missing http_requests_total" }
  if ($m -notmatch "http_request_duration_ms_count") { throw "metrics missing duration count" }
  if ($m -notmatch "db_ping_failures_total") { throw "metrics missing db ping failures" }

  # Simulate DB outage
  docker compose -f compose.yaml -f compose.secrets.yaml stop db | Out-Null

  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8081/readyz" -TimeoutSec 5
    if ($r.StatusCode -ne 503) { throw "expected 503" }
  } catch {
    # if Invoke-WebRequest throws on 503, that's acceptable; ensure it was 503
  }

  # Wait for http_errors_total to increment
  $ok = $false
  for ($i=0; $i -lt 20; $i++) {
    $m2 = (Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8081/metrics" -TimeoutSec 5).Content
    if ($m2 -match "http_errors_total [1-9]") { $ok = $true; break }
    Start-Sleep -Seconds 1
  }
  if (-not $ok) { throw "expected http_errors_total to be > 0 after outage" }

  $logs = docker compose -f compose.yaml -f compose.secrets.yaml logs api 2>$null
  if ($logs -match [regex]::Escape($secretValue)) { throw "Secret value was found in API logs." }
}
catch {
  Cleanup
  Write-Error $_
  exit 1
}

Cleanup
$ids2 = docker ps -a --filter "label=com.docker.compose.project=lab-15" --format "{{.ID}}"
if ($ids2) { Write-Error "lab-15 containers still exist after cleanup."; exit 1 }

Write-Host "Lab 15 validation passed ✔" -ForegroundColor Green
exit 0
