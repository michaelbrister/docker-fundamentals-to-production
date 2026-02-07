#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 13 — CI + policy enforcement files"

required=(
  ".github/workflows/ci.yml"
  "scripts/ci/policy-check.sh"
  "docs/ci-policy.md"
  "SECURITY_EXCEPTIONS.md"
  "labs/lab-13/README.md"
  "labs/lab-13/hints.md"
  "labs/lab-13/instructor-notes.md"
  "labs/lab-13/solutions/solution.md"
)

for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing required file: $f" >&2
    exit 1
  fi
done

echo "Lab 13 validation passed ✔"
