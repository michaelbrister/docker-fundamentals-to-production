# Lab 14 — Validation Script (PowerShell)
Write-Host "Validating Lab 14 — Secrets & Configuration" -ForegroundColor Cyan

try { docker version | Out-Null } catch { Write-Error "Docker CLI not available or Docker not running."; exit 1 }

$required = @(
  "README.md",
  ".env.example",
  "compose.yaml",
  "compose.secrets.yaml",
  "SECRETS_NOTES_TEMPLATE.md",
  "hints.md",
  "instructor-notes.md",
  "solutions/solution.md",
  "api/Dockerfile.distroless",
  "api/main.go",
  "db/init.sql",
  "secrets/db_password.txt.example"
)

foreach ($f in $required) {
  if (-not (Test-Path $f -PathType Leaf)) {
    Write-Error "Missing required file: $f"
    exit 1
  }
}

if (-not (Test-Path "SECRETS_NOTES.md" -PathType Leaf)) {
  Write-Error "SECRETS_NOTES.md not found. Create it from SECRETS_NOTES_TEMPLATE.md."
  exit 1
}

if (-not (Test-Path "secrets/db_password.txt" -PathType Leaf)) {
  Write-Error "secrets/db_password.txt not found. Create it from secrets/db_password.txt.example (DO NOT COMMIT)."
  exit 1
}

# Best-effort git hygiene
try {
  git rev-parse --is-inside-work-tree | Out-Null
  $trackedEnv = git ls-files --error-unmatch ".env" 2>$null
  if ($LASTEXITCODE -eq 0) { Write-Error ".env is tracked by git. Keep it local-only."; exit 1 }

  $trackedSecret = git ls-files --error-unmatch "secrets/db_password.txt" 2>$null
  if ($LASTEXITCODE -eq 0) { Write-Error "secrets/db_password.txt is tracked by git. Do NOT commit secret files."; exit 1 }
} catch {
  # not a git repo; ignore
}

# Dockerfile policy (no secret tokens)
$dockerfile = Get-Content "api/Dockerfile.distroless" -Raw
if ($dockerfile -match "DB_PASSWORD|API_KEY|SECRET") {
  Write-Error "Dockerfile contains secret-related tokens (DB_PASSWORD/API_KEY/SECRET). Do not bake secrets into images."
  exit 1
}

# Ensure no existing lab-14 containers
$ids = docker ps -a --filter "label=com.docker.compose.project=lab-14" --format "{{.ID}}"
if ($ids) {
  Write-Error "lab-14 containers already exist. Cleanup first with: docker compose -f compose.yaml -f compose.secrets.yaml down"
  exit 1
}

Write-Host "Bringing up lab-14 stack (with secrets overlay) for smoke validation..." -ForegroundColor Cyan
docker compose -f compose.yaml -f compose.secrets.yaml up -d --build | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "docker compose up failed"; exit 1 }

function Cleanup {
  docker compose -f compose.yaml -f compose.secrets.yaml down | Out-Null
}
try {
  Write-Host "Waiting for readiness..." -ForegroundColor Cyan
  $ready = $false
  for ($i=0; $i -lt 40; $i++) {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8080/readyz" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch { }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw "readyz never became ready" }

  Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8080/healthz" -TimeoutSec 5 | Out-Null
  Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8080/readyz" -TimeoutSec 5 | Out-Null
  Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8080/notes" -TimeoutSec 5 | Out-Null

  $secretValue = (Get-Content "secrets/db_password.txt" -Raw).Trim()
  if ($secretValue) {
    $logs = docker compose -f compose.yaml -f compose.secrets.yaml logs api 2>$null
    if ($logs -match [regex]::Escape($secretValue)) {
      throw "Secret value was found in API logs. Secrets must be redacted."
    }
  }
}
catch {
  Cleanup
  Write-Error $_
  exit 1
}

Cleanup

$ids2 = docker ps -a --filter "label=com.docker.compose.project=lab-14" --format "{{.ID}}"
if ($ids2) {
  Write-Error "lab-14 containers still exist after cleanup. Use docker compose down."
  exit 1
}

Write-Host "Lab 14 validation passed ✔" -ForegroundColor Green
exit 0
