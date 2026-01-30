

# Lab 01 — Validation Script (PowerShell)
# This script enforces strict cleanup and basic Docker sanity checks.

Write-Host "Validating Lab 01 — Docker fundamentals" -ForegroundColor Cyan

# ----------------------------
# Check: Docker CLI available
# ----------------------------
try {
    docker version | Out-Null
} catch {
    Write-Error "Docker CLI is not available or Docker is not running."
    exit 1
}

# ----------------------------
# Check: Docker daemon reachable
# ----------------------------
try {
    docker info | Out-Null
} catch {
    Write-Error "Cannot reach Docker daemon. Is Docker Desktop or Docker Engine running?"
    exit 1
}

# ----------------------------
# Check: lab01-nginx container is NOT running
# ----------------------------
$container = docker ps -a --filter "name=lab01-nginx" --format "{{.Names}}"

if ($container) {
    Write-Error "Container 'lab01-nginx' still exists. You must stop and remove it to pass Lab 01."
    Write-Host "Hint: docker rm -f lab01-nginx" -ForegroundColor Yellow
    exit 1
}

# ----------------------------
# Optional: Warn if expected images are missing
# ----------------------------
$expectedImages = @(
    "hello-world",
    "alpine",
    "nginx"
)

foreach ($image in $expectedImages) {
    $found = docker images --format "{{.Repository}}" | Select-String "^$image$"
    if (-not $found) {
        Write-Warning "Image '$image' not found locally. This is OK if you removed images during cleanup."
    }
}

# ----------------------------
# Success
# ----------------------------
Write-Host "Lab 01 validation passed ✔" -ForegroundColor Green
exit 0