
# Top-level validation runner (PowerShell)
# Usage examples:
#   .\scripts\validate\validate.ps1 lab-01
#   .\scripts\validate\validate.ps1 labs\lab-01
#   .\scripts\validate\validate.ps1 lab-01-getting-started

param(
    [Parameter(Mandatory = $true)]
    [string]$Lab
)

Write-Host "Running validation for: $Lab" -ForegroundColor Cyan

# Normalize lab path
if ($Lab -like "labs*") {
    $labDir = $Lab
} elseif ($Lab -like "lab-*") {
    $labDir = Join-Path "labs" $Lab
} else {
    $labDir = Join-Path "labs" $Lab
}

if (-not (Test-Path $labDir -PathType Container)) {
    Write-Error "Lab directory not found: $labDir"
    Write-Host "Hint: expected something like labs\\lab-01" -ForegroundColor Yellow
    exit 2
}

$validator = Join-Path $labDir "validate.ps1"
if (-not (Test-Path $validator -PathType Leaf)) {
    Write-Error "No validate.ps1 found in $labDir"
    Write-Host "Expected: $validator" -ForegroundColor Yellow
    exit 2
}

Write-Host "Dispatching to lab validator: $validator" -ForegroundColor Cyan

# Run the lab-specific validator in a new scope
& $validator
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Error "Validation failed for $labDir"
    exit $exitCode
}

Write-Host "Validation passed for: $labDir ✔" -ForegroundColor Green
exit 0
