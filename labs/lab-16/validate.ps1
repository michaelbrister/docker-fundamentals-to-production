# Lab 16 — Validation Script (PowerShell)
Write-Host "Validating Lab 16 — Capstone Release Candidate" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }

$required = @(
  "README.md",
  ".env.example",
  "compose.yaml",
  "compose.dev.yaml",
  "compose.prod.yaml",
  "compose.secrets.yaml",
  "RELEASE.md",
  "RUNBOOK_TEMPLATE.md",
  "INCIDENT_TEMPLATE.md",
  "hints.md",
  "instructor-notes.md",
  "api/Dockerfile.distroless",
  "api/main.go",
  "db/init.sql",
  "secrets/db_password.txt.example"
)

foreach ($f in $required) {
  if (-not (Test-Path $f -PathType Leaf)) { Write-Error "Missing required file: $f"; exit 1 }
}

if (-not (Test-Path "RUNBOOK.md" -PathType Leaf)) { Write-Error "RUNBOOK.md not found. Create it from RUNBOOK_TEMPLATE.md."; exit 1 }
if (-not (Test-Path "INCIDENT.md" -PathType Leaf)) { Write-Error "INCIDENT.md not found. Create it from INCIDENT_TEMPLATE.md."; exit 1 }
if (-not (Test-Path ".env" -PathType Leaf)) { Write-Error ".env not found. Create it from .env.example."; exit 1 }
if (-not (Test-Path "secrets/db_password.txt" -PathType Leaf)) { Write-Error "secrets/db_password.txt not found. Create it from secrets/db_password.txt.example."; exit 1 }

# compose.prod.yaml must not contain build:
if ((Get-Content "compose.prod.yaml" -Raw) -match "(?m)^\s*build\s*:") { Write-Error "compose.prod.yaml must NOT contain build:"; exit 1 }

$releaseLine = (Get-Content ".env" | Where-Object { $_ -match "^RELEASE_VERSION=" } | Select-Object -First 1)
if (-not $releaseLine) { Write-Error "RELEASE_VERSION is missing from .env"; exit 1 }
$releaseVersion = $releaseLine.Split("=",2)[1].Trim()
if (-not $releaseVersion -or $releaseVersion -eq "latest") { Write-Error "RELEASE_VERSION must be set and not 'latest'"; exit 1 }

$secretValue = (Get-Content "secrets/db_password.txt" -Raw).Trim()
if (-not $secretValue -or $secretValue.Length -lt 12) { Write-Error "secrets/db_password.txt must be >= 12 chars"; exit 1 }

# Ensure no existing lab-16 containers
$ids = docker ps -a --filter "label=com.docker.compose.project=lab-16" --format "{{.ID}}"
if ($ids) { Write-Error "lab-16 containers already exist. Cleanup first."; exit 1 }

Write-Host "Building release image dzth/mini-platform-api:$releaseVersion ..." -ForegroundColor Cyan
docker build -f api/Dockerfile.distroless -t "dzth/mini-platform-api:$releaseVersion" api | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "docker build failed"; exit 1 }

Write-Host "Bringing up prod-like stack..." -ForegroundColor Cyan
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "docker compose up failed"; exit 1 }

function Cleanup { docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down | Out-Null }

try {
  $img = docker inspect -f "{{.Config.Image}}" lab16-api 2>$null
  if ($img -ne "dzth/mini-platform-api:$releaseVersion") { throw "api container is not using expected image tag ($img)" }

  $ro = docker inspect -f "{{.HostConfig.ReadonlyRootfs}}" lab16-api
  if ($ro -ne "true") { throw "api must run with read-only rootfs in prod" }

  # Wait for readiness
  $ready = $false
  for ($i=0; $i -lt 50; $i++) {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8082/readyz" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch { }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw "readyz never became ready" }

  $v = (Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8082/version" -TimeoutSec 5).Content
  if ($v -notmatch [regex]::Escape($releaseVersion)) { throw "/version missing release_version" }

  # DB outage drill (poll for 503)
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml stop db | Out-Null
  $saw503 = $false
  for ($i=0; $i -lt 25; $i++) {
    try {
      $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8082/readyz" -TimeoutSec 2
      if ($r.StatusCode -eq 503) { $saw503 = $true; break }
    } catch {
      # 503 often throws; accept that as "saw 503"
      $saw503 = $true
      break
    }
    Start-Sleep -Seconds 1
  }
  if (-not $saw503) { throw "expected /readyz 503 during outage" }

  # Leak check
  $logs = docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api 2>$null
  if ($logs -match [regex]::Escape($secretValue)) { throw "Secret value was found in API logs." }
}
catch {
  Cleanup
  Write-Error $_
  exit 1
}

Cleanup
$ids2 = docker ps -a --filter "label=com.docker.compose.project=lab-16" --format "{{.ID}}"
if ($ids2) { Write-Error "lab-16 containers still exist after cleanup."; exit 1 }

Write-Host "Lab 16 validation passed ✔" -ForegroundColor Green
exit 0
