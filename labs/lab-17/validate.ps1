Write-Host "Validating Lab 17 — Supply Chain (SBOM + Vulnerability Policy)" -ForegroundColor Cyan

function Need-Cmd($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Error "'$name' not found. Install it for this lab."
    exit 1
  }
}

Need-Cmd docker
Need-Cmd syft
Need-Cmd grype

try { docker info | Out-Null } catch { Write-Error "Docker daemon not reachable."; exit 1 }

$required = @(
  "README.md",
  ".env.example",
  "hints.md",
  "instructor-notes.md",
  "SBOM_TEMPLATE.md",
  "SECURITY_NOTES_TEMPLATE.md",
  "api/Dockerfile.distroless",
  "api/main.go",
  "api/go.mod",
  "secrets/db_password.txt.example",
  "ci/github-actions-workflow.yml"
)

foreach ($f in $required) {
  if (-not (Test-Path $f -PathType Leaf)) { Write-Error "Missing required file: $f"; exit 1 }
}

if (-not (Test-Path "SBOM.md" -PathType Leaf)) { Write-Error "SBOM.md not found. Create it from SBOM_TEMPLATE.md."; exit 1 }
if (-not (Test-Path "SECURITY_NOTES.md" -PathType Leaf)) { Write-Error "SECURITY_NOTES.md not found. Create it from SECURITY_NOTES_TEMPLATE.md."; exit 1 }
if (-not (Test-Path ".env" -PathType Leaf)) { Write-Error ".env not found. Create it from .env.example."; exit 1 }
if (-not (Test-Path "secrets/db_password.txt" -PathType Leaf)) { Write-Error "secrets/db_password.txt not found. Create it from secrets/db_password.txt.example."; exit 1 }

$releaseLine = (Get-Content ".env" | Where-Object { $_ -match "^RELEASE_VERSION=" } | Select-Object -First 1)
if (-not $releaseLine) { Write-Error "RELEASE_VERSION missing from .env"; exit 1 }
$releaseVersion = $releaseLine.Split("=",2)[1].Trim()
if (-not $releaseVersion -or $releaseVersion -eq "latest") { Write-Error "RELEASE_VERSION must be set and not 'latest'"; exit 1 }

$secretValue = (Get-Content "secrets/db_password.txt" -Raw).Trim()
if (-not $secretValue -or $secretValue.Length -lt 12) { Write-Error "secrets/db_password.txt must be >= 12 chars"; exit 1 }

Write-Host "Building image dzth/mini-platform-api:$releaseVersion ..." -ForegroundColor Cyan
docker build -f api/Dockerfile.distroless -t "dzth/mini-platform-api:$releaseVersion" api | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "docker build failed"; exit 1 }

Write-Host "Generating SBOM -> sbom.json ..." -ForegroundColor Cyan
syft "dzth/mini-platform-api:$releaseVersion" -o "spdx-json=sbom.json" | Out-Null
if (-not (Test-Path "sbom.json" -PathType Leaf)) { Write-Error "sbom.json was not created"; exit 1 }
if ((Get-Item "sbom.json").Length -lt 10) { Write-Error "sbom.json is empty"; exit 1 }

Write-Host "Scanning image (fail on CRITICAL)..." -ForegroundColor Cyan
grype "dzth/mini-platform-api:$releaseVersion" --fail-on critical
if ($LASTEXITCODE -ne 0) {
  Write-Error "Grype reported CRITICAL vulnerabilities (policy violation)."
  exit 1
}

Write-Host "Lab 17 validation passed ✔" -ForegroundColor Green
exit 0
