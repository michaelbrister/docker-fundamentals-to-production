# Lab 06 — Validation Script (PowerShell)

Write-Host "Validating Lab 06 — Production-grade image build" -ForegroundColor Cyan

# Docker CLI / daemon
try {
    docker version | Out-Null
} catch {
    Write-Error "Docker CLI not available or Docker not running."
    exit 1
}

# Image must exist
try {
    docker image inspect dzth/lab06-go:0.1 | Out-Null
} catch {
    Write-Error "Image dzth/lab06-go:0.1 not found."
    Write-Host "Hint: docker build -t dzth/lab06-go:0.1 ." -ForegroundColor Yellow
    exit 1
}

# Container must NOT exist
$exists = docker ps -a --filter "name=lab06-go" --format "{{.Names}}"
if ($exists) {
    Write-Error "Container 'lab06-go' still exists."
    Write-Host "Hint: docker rm -f lab06-go" -ForegroundColor Yellow
    exit 1
}

Write-Host "Lab 06 validation passed ✔" -ForegroundColor Green
exit 0