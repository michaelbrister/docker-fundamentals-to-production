# Lab 13 — Validation Script (PowerShell)

Write-Host "Validating Lab 13 — CI + policy enforcement files" -ForegroundColor Cyan

$required = @(
  ".github/workflows/ci.yml",
  "scripts/ci/policy-check.sh",
  "docs/ci-policy.md",
  "SECURITY_EXCEPTIONS.md",
  "labs/lab-13/README.md",
  "labs/lab-13/hints.md",
  "labs/lab-13/instructor-notes.md",
  "labs/lab-13/solutions/solution.md"
)

foreach ($f in $required) {
  if (-not (Test-Path $f -PathType Leaf)) {
    Write-Error "Missing required file: $f"
    exit 1
  }
}

Write-Host "Lab 13 validation passed ✔" -ForegroundColor Green
exit 0
