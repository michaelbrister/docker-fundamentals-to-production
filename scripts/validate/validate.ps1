
# Top-level validation runner (PowerShell)
# Usage examples:
#   .\scripts\validate\validate.ps1 lab-01
#   .\scripts\validate\validate.ps1 labs\lab-01
#   .\scripts\validate\validate.ps1 all
#   .\scripts\validate\validate.ps1

param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Lab = "all",

    [switch]$Help
)

if ($Help -or $Lab -in @("-h","--help","help")) {
    Write-Host "Usage: .\scripts\validate\validate.ps1 <lab-id|all>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\scripts\validate\validate.ps1 lab-01" -ForegroundColor Yellow
    Write-Host "  .\scripts\validate\validate.ps1 labs\lab-01" -ForegroundColor Yellow
    Write-Host "  .\scripts\validate\validate.ps1 all" -ForegroundColor Yellow
    Write-Host "  .\scripts\validate\validate.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Notes:" -ForegroundColor Yellow
    Write-Host "  - 'all' validates every labs\lab-* directory that contains validate.ps1" -ForegroundColor Yellow
    exit 0
}

function Resolve-LabDir {
    param([string]$InputLab)

    if ($InputLab -like "labs*") {
        return $InputLab
    } elseif ($InputLab -like "lab-*") {
        return (Join-Path "labs" $InputLab)
    } else {
        return (Join-Path "labs" $InputLab)
    }
}

function Invoke-OneLab {
    param([string]$InputLab)

    $labDir = Resolve-LabDir -InputLab $InputLab

    if (-not (Test-Path $labDir -PathType Container)) {
        Write-Error "Lab directory not found: $labDir"
        Write-Host "Hint: expected something like labs\lab-01" -ForegroundColor Yellow
        return 2
    }

    $validator = Join-Path $labDir "validate.ps1"
    if (-not (Test-Path $validator -PathType Leaf)) {
        Write-Error "No validate.ps1 found in $labDir"
        Write-Host "Expected: $validator" -ForegroundColor Yellow
        return 2
    }

    Write-Host "Dispatching to lab validator: $validator" -ForegroundColor Cyan
    & $validator
    return $LASTEXITCODE
}

if ($Lab -eq "all") {
    Write-Host "Validating all labs..." -ForegroundColor Cyan

    $labDirs = Get-ChildItem -Path ".\labs" -Directory -Filter "lab-*" | Sort-Object Name

    if (-not $labDirs -or $labDirs.Count -eq 0) {
        Write-Error "No labs found under .\labs (expected directories like labs\lab-01)"
        exit 2
    }

    $failures = 0

    foreach ($d in $labDirs) {
        $labDir = $d.FullName

        Write-Host ""
        Write-Host "=== $($d.Name) ===" -ForegroundColor Cyan

        $validator = Join-Path $labDir "validate.ps1"
        if (-not (Test-Path $validator -PathType Leaf)) {
            Write-Host "SKIP: No validate.ps1 in $labDir" -ForegroundColor DarkYellow
            continue
        }

        $code = Invoke-OneLab -InputLab $labDir
        if ($code -ne 0) {
            Write-Error "Validation failed for $labDir"
            $failures++
        } else {
            Write-Host "Validation passed for: $labDir ✔" -ForegroundColor Green
        }
    }

    Write-Host ""
    if ($failures -ne 0) {
        Write-Error "Validation finished with $failures failure(s)."
        exit 1
    }

    Write-Host "All validations passed ✔" -ForegroundColor Green
    exit 0
}

Write-Host "Running validation for: $Lab" -ForegroundColor Cyan
$exitCode = Invoke-OneLab -InputLab $Lab
if ($exitCode -ne 0) {
    Write-Error "Validation failed for $(Resolve-LabDir -InputLab $Lab)"
    exit $exitCode
}

Write-Host "Validation passed for: $(Resolve-LabDir -InputLab $Lab) ✔" -ForegroundColor Green
exit 0
