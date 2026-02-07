Write-Host "Validating Lab 18 — Release & Rollback Discipline" -ForegroundColor Cyan
try { docker info | Out-Null } catch { Write-Error "Docker daemon not reachable."; exit 1 }

$required = @("README.md",".env.example","compose.yaml","compose.prod.yaml","compose.secrets.yaml","RELEASE.md","INCIDENT_TEMPLATE.md","hints.md","instructor-notes.md","db/init.sql",
"api-good/Dockerfile.distroless","api-good/main.go","api-good/go.mod","api-bad/Dockerfile.distroless","api-bad/main.go","api-bad/go.mod","secrets/db_password.txt.example")
foreach ($f in $required) { if (-not (Test-Path $f -PathType Leaf)) { Write-Error "Missing required file: $f"; exit 1 } }

if (-not (Test-Path "INCIDENT.md" -PathType Leaf)) { Write-Error "INCIDENT.md not found. Create it from template."; exit 1 }
if (-not (Test-Path ".env" -PathType Leaf)) { Write-Error ".env not found. Create it from .env.example."; exit 1 }
if (-not (Test-Path "secrets/db_password.txt" -PathType Leaf)) { Write-Error "secrets/db_password.txt not found."; exit 1 }

if ((Get-Content "compose.prod.yaml" -Raw) -match "(?m)^\s*build\s*:") { Write-Error "compose.prod.yaml must not contain build:"; exit 1 }

$good = (Get-Content ".env" | Where-Object { $_ -match "^GOOD_VERSION=" } | Select-Object -First 1).Split("=",2)[1].Trim()
$bad  = (Get-Content ".env" | Where-Object { $_ -match "^BAD_VERSION=" }  | Select-Object -First 1).Split("=",2)[1].Trim()
if (-not $good -or -not $bad -or $good -eq "latest" -or $bad -eq "latest") { Write-Error "GOOD_VERSION/BAD_VERSION must be set and not latest"; exit 1 }

$secretValue = (Get-Content "secrets/db_password.txt" -Raw).Trim()
if (-not $secretValue -or $secretValue.Length -lt 12) { Write-Error "secrets/db_password.txt must be >= 12 chars"; exit 1 }

$ids = docker ps -a --filter "label=com.docker.compose.project=lab-18" --format "{{.ID}}"
if ($ids) { Write-Error "lab-18 containers already exist. Cleanup first."; exit 1 }

docker build -f api-good/Dockerfile.distroless -t "dzth/mini-platform-api:$good" api-good | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "docker build failed for GOOD"; exit 1 }
docker build -f api-bad/Dockerfile.distroless -t "dzth/mini-platform-api:$bad" api-bad | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "docker build failed for BAD"; exit 1 }

function Cleanup { docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down | Out-Null }

try {
  $env:ACTIVE_VERSION = $bad
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d | Out-Null

  $ready = $false
  for ($i=0; $i -lt 40; $i++) {
    try { $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8083/readyz" -TimeoutSec 2; if ($r.StatusCode -eq 200) { $ready = $true; break } } catch { }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw "readyz never became ready on BAD release" }

  $saw500 = $false
  for ($i=0; $i -lt 10; $i++) {
    try { $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8083/notes" -TimeoutSec 2; if ($r.StatusCode -eq 500) { $saw500 = $true; break } } catch { $saw500 = $true; break }
    Start-Sleep -Seconds 1
  }
  if (-not $saw500) { throw "expected /notes 500 on BAD release" }

  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down | Out-Null

  $env:ACTIVE_VERSION = $good
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d | Out-Null

  $ready = $false
  for ($i=0; $i -lt 40; $i++) {
    try { $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8083/readyz" -TimeoutSec 2; if ($r.StatusCode -eq 200) { $ready = $true; break } } catch { }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw "readyz never became ready on GOOD release" }

  $notes = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8083/notes" -TimeoutSec 5
  if ($notes.StatusCode -ne 200) { throw "expected /notes 200 after rollback" }

  $ver = (Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8083/version" -TimeoutSec 5).Content
  if ($ver -notmatch [regex]::Escape($good)) {
    throw @"
Rollback incomplete.
Expected /version to report the GOOD_VERSION ($good).
This usually means ACTIVE_VERSION was not updated to GOOD_VERSION during rollback.
Fix: re-run rollback using ACTIVE_VERSION=$good and restart the stack.

Current /version output:
$ver
"@
  }

  $logs = docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api 2>$null
  if ($logs -match [regex]::Escape($secretValue)) { throw "Secret value leaked in logs" }
}
catch {
  Cleanup
  Write-Error $_
  exit 1
}

Cleanup
$ids2 = docker ps -a --filter "label=com.docker.compose.project=lab-18" --format "{{.ID}}"
if ($ids2) { Write-Error "lab-18 containers still exist after cleanup"; exit 1 }

Write-Host "Lab 18 validation passed ✔" -ForegroundColor Green
exit 0
