Write-Host "Validating Lab 19 — Promotion & Provenance" -ForegroundColor Cyan

try { docker info | Out-Null } catch { Write-Error "Docker daemon not reachable."; exit 1 }

$required = @(
  "README.md",".env.example","compose.yaml","compose.dev.yaml","compose.prod.yaml","compose.secrets.yaml",
  "hints.md","instructor-notes.md",
  "PROMOTION_TEMPLATE.md","PROVENANCE_TEMPLATE.md",
  "db/init.sql",
  "api/Dockerfile.distroless","api/main.go","api/go.mod",
  "secrets/db_password.txt.example"
)
foreach ($f in $required) { if (-not (Test-Path $f -PathType Leaf)) { Write-Error "Missing required file: $f"; exit 1 } }

if (-not (Test-Path ".env" -PathType Leaf)) { Write-Error ".env not found. Create it from .env.example."; exit 1 }
if (-not (Test-Path "secrets/db_password.txt" -PathType Leaf)) { Write-Error "secrets/db_password.txt not found."; exit 1 }
if (-not (Test-Path "PROMOTION.md" -PathType Leaf)) { Write-Error "PROMOTION.md not found. Create it from template."; exit 1 }
if (-not (Test-Path "PROVENANCE.md" -PathType Leaf)) { Write-Error "PROVENANCE.md not found. Create it from template."; exit 1 }

if ((Get-Content ".env" -Raw) -match "REPLACE_ME") { Write-Error ".env contains REPLACE_ME. Set PROMOTED_IMAGE_REF after build."; exit 1 }
if ((Get-Content "PROMOTION.md" -Raw) -match "REPLACE_ME" -or (Get-Content "PROVENANCE.md" -Raw) -match "REPLACE_ME") {
  Write-Error "PROMOTION.md/PROVENANCE.md still contains REPLACE_ME placeholders."; exit 1
}
if ((Get-Content "compose.prod.yaml" -Raw) -match "(?m)^\s*build\s*:") { Write-Error "compose.prod.yaml must not contain build:"; exit 1 }

$rc = (Get-Content ".env" | Where-Object { $_ -match "^RC_VERSION=" } | Select-Object -First 1).Split("=",2)[1].Trim()
$promoted = (Get-Content ".env" | Where-Object { $_ -match "^PROMOTED_IMAGE_REF=" } | Select-Object -First 1).Split("=",2)[1].Trim()
if (-not $rc) { Write-Error "RC_VERSION missing"; exit 1 }
if (-not $promoted) { Write-Error "PROMOTED_IMAGE_REF missing"; exit 1 }
if ($promoted -notmatch "^sha256:") { Write-Error "PROMOTED_IMAGE_REF must look like sha256:..."; exit 1 }

$secretValue = (Get-Content "secrets/db_password.txt" -Raw).Trim()
if (-not $secretValue -or $secretValue.Length -lt 12) { Write-Error "secrets/db_password.txt must be >= 12 chars"; exit 1 }

function CleanupAll {
  docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml down | Out-Null
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down | Out-Null
}

$ids = docker ps -a --filter "label=com.docker.compose.project=lab-19" --format "{{.ID}}"
if ($ids) { Write-Error "lab-19 containers already exist. Cleanup first."; exit 1 }

try {
  Write-Host "Building RC image in DEV..." -ForegroundColor Cyan
  docker compose -f compose.yaml -f compose.dev.yaml build | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "docker compose build failed" }

  $builtId = (docker image inspect "dzth/mini-platform-api:$rc" --format "{{.Id}}")
  if (-not $builtId) { throw "Could not inspect built image dzth/mini-platform-api:$rc" }

  if ($builtId.Trim() -ne $promoted.Trim()) {
    throw @"
PROMOTED_IMAGE_REF does not match the built image ID for dzth/mini-platform-api:$rc
Expected: $builtId
Got:      $promoted
Fix: set PROMOTED_IMAGE_REF to:
  docker image inspect dzth/mini-platform-api:$rc --format '{{.Id}}'
"@
  }

  Write-Host "Starting DEV stack..." -ForegroundColor Cyan
  docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml up -d | Out-Null

  $ready = $false
  for ($i=0; $i -lt 40; $i++) {
    try { $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8084/readyz" -TimeoutSec 2; if ($r.StatusCode -eq 200) { $ready = $true; break } } catch { }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw "DEV /readyz never became ready" }

  $verDev = (Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8084/version" -TimeoutSec 5).Content
  if ($verDev -notmatch [regex]::Escape($rc)) { throw "DEV /version did not include RC_VERSION=$rc`n$verDev" }

  $logsDev = docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml logs api 2>$null
  if ($logsDev -match [regex]::Escape($secretValue)) { throw "Secret value leaked in DEV logs" }

  docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml down | Out-Null

  Write-Host "Starting PROD-like stack..." -ForegroundColor Cyan
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d | Out-Null

  $ready = $false
  for ($i=0; $i -lt 40; $i++) {
    try { $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8085/readyz" -TimeoutSec 2; if ($r.StatusCode -eq 200) { $ready = $true; break } } catch { }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw "PROD /readyz never became ready" }

  $verProd = (Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8085/version" -TimeoutSec 5).Content
  if ($verProd -notmatch [regex]::Escape($rc)) { throw "PROD /version did not include RC_VERSION=$rc`n$verProd" }

  $prodImageId = (docker inspect -f "{{.Image}}" lab19-api)
  if (-not $prodImageId) { throw "Could not inspect lab19-api container image id" }

  # docker returns bare sha; accept both forms
  $expectedBare = $promoted.Replace("sha256:","")
  if ($prodImageId.Trim() -ne $expectedBare.Trim() -and $prodImageId.Trim() -ne $promoted.Trim()) {
    throw "PROD container is not running promoted image id. Expected $promoted, got $prodImageId"
  }

  $logsProd = docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api 2>$null
  if ($logsProd -match [regex]::Escape($secretValue)) { throw "Secret value leaked in PROD logs" }
}
catch {
  CleanupAll
  Write-Error $_
  exit 1
}

CleanupAll
$ids2 = docker ps -a --filter "label=com.docker.compose.project=lab-19" --format "{{.ID}}"
if ($ids2) { Write-Error "lab-19 containers still exist after cleanup"; exit 1 }

Write-Host "Lab 19 validation passed ✔" -ForegroundColor Green
exit 0
