Write-Host "Validating Lab 20 — Incident Day (Final Exam)" -ForegroundColor Cyan
try { docker info | Out-Null } catch { Write-Error "Docker daemon not reachable."; exit 1 }

$required = @(
  "README.md",".env.example","compose.yaml","compose.prod.yaml","compose.secrets.yaml",
  "hints.md","instructor-notes.md",
  "INCIDENT_TEMPLATE.md","TIMELINE_TEMPLATE.md","RECOVERY_TEMPLATE.md",
  "db/init.sql",
  "api/Dockerfile.distroless","api/main.go","api/go.mod",
  "secrets/db_password.txt.example",
  "reset.sh","reset.ps1"
)
foreach ($f in $required) { if (-not (Test-Path $f -PathType Leaf)) { Write-Error "Missing required file: $f"; exit 1 } }

foreach ($must in @(".env","break-mode.txt","secrets/db_password.txt","INCIDENT.md","TIMELINE.md","RECOVERY.md")) {
  if (-not (Test-Path $must -PathType Leaf)) { Write-Error "$must missing. Follow README steps."; exit 1 }
}
foreach ($doc in @("INCIDENT.md","TIMELINE.md","RECOVERY.md")) {
  if ((Get-Content $doc -Raw) -match "REPLACE_ME") { Write-Error "$doc still contains REPLACE_ME placeholders."; exit 1 }
}
if ((Get-Content ".env" -Raw) -match "REPLACE_ME") { Write-Error ".env contains REPLACE_ME. Set image refs."; exit 1 }
if ((Get-Content "compose.prod.yaml" -Raw) -match "(?m)^\s*build\s*:") { Write-Error "compose.prod.yaml must not contain build:"; exit 1 }

$mode = (Get-Content "break-mode.txt" -Raw).Trim()
if ($mode -ne "mode-a" -and $mode -ne "mode-b") { Write-Error "break-mode.txt must be mode-a or mode-b"; exit 1 }

$envText = Get-Content ".env" -Raw
$rc = ($envText | Select-String -Pattern "^RC_VERSION=" -AllMatches).Line.Split("=",2)[1].Trim()
$goodRef = ($envText | Select-String -Pattern "^KNOWN_GOOD_IMAGE_REF=" -AllMatches).Line.Split("=",2)[1].Trim()
if (-not $rc) { Write-Error "RC_VERSION missing"; exit 1 }
if ($goodRef -notmatch "^sha256:") { Write-Error "KNOWN_GOOD_IMAGE_REF must look like sha256:..."; exit 1 }

$secretValue = (Get-Content "secrets/db_password.txt" -Raw).Trim()
if (-not $secretValue -or $secretValue.Length -lt 12) { Write-Error "secrets/db_password.txt must be >= 12 chars"; exit 1 }

$builtId = ""
try { $builtId = (docker image inspect "dzth/mini-platform-api:$rc" --format "{{.Id}}") } catch { }
if (-not $builtId) {
  Write-Error "Known-good image dzth/mini-platform-api:$rc not found locally. Build it once (before incident)."
  exit 1
}
if ($builtId.Trim() -ne $goodRef.Trim()) {
  Write-Error "KNOWN_GOOD_IMAGE_REF does not match built image ID. Expected $builtId, got $goodRef"
  exit 1
}

function Cleanup { docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down | Out-Null }

$ids = docker ps -a --filter "label=com.docker.compose.project=lab-20" --format "{{.ID}}"
if ($ids) { Write-Error "lab-20 containers already exist. Cleanup first."; exit 1 }

try {
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d | Out-Null

  $ready = $false
  for ($i=0; $i -lt 50; $i++) {
    try { $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8086/readyz" -TimeoutSec 2; if ($r.StatusCode -eq 200) { $ready = $true; break } } catch { }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw "/readyz never became ready (service not recovered)" }

  $notes = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8086/notes" -TimeoutSec 5
  if ($notes.StatusCode -ne 200) { throw "/notes did not return 200 (service not recovered)" }

  $ver = (Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8086/version" -TimeoutSec 5).Content
  if ($ver -notmatch [regex]::Escape($rc)) { throw "/version did not include RC_VERSION=$rc`n$ver" }

  $prodImageId = (docker inspect -f "{{.Image}}" lab20-api)
  $expectedBare = $goodRef.Replace("sha256:","")
  if ($prodImageId.Trim() -ne $expectedBare.Trim() -and $prodImageId.Trim() -ne $goodRef.Trim()) {
    throw "PROD is not running KNOWN_GOOD_IMAGE_REF. Expected $goodRef, got $prodImageId"
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
$ids2 = docker ps -a --filter "label=com.docker.compose.project=lab-20" --format "{{.ID}}"
if ($ids2) { Write-Error "lab-20 containers still exist after cleanup"; exit 1 }

Write-Host "Lab 20 validation passed ✔" -ForegroundColor Green
exit 0
