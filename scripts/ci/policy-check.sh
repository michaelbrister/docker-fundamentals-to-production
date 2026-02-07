#!/usr/bin/env bash
set -euo pipefail

echo "Running Docker policy checks..."

# Find Dockerfiles in labs (and repo root if any)
mapfile -t dockerfiles < <(find . -type f \( -name 'Dockerfile' -o -name 'Dockerfile.*' \) -print)

if [[ ${#dockerfiles[@]} -eq 0 ]]; then
  echo "No Dockerfiles found. Nothing to check."
  exit 0
fi

fail=0

check_no_latest() {
  local f="$1"
  if grep -Eiq '^\s*FROM\s+[^\s]+:latest\b' "$f"; then
    echo "POLICY FAIL: ':latest' tag is not allowed in $f"
    fail=1
  fi
}

check_non_root() {
  local f="$1"

  # If distroless nonroot is used, accept
  if grep -Eiq '^\s*FROM\s+gcr\.io/distroless/.+:nonroot\b' "$f"; then
    return 0
  fi

  # Otherwise require a USER that is not 0/root
  if ! grep -Eiq '^\s*USER\s+' "$f"; then
    echo "POLICY FAIL: missing USER (must run as non-root) in $f"
    fail=1
    return
  fi

  # Reject obvious root patterns
  if grep -Eiq '^\s*USER\s+(0|root)(:0|:root)?\s*$' "$f"; then
    echo "POLICY FAIL: USER is root in $f"
    fail=1
  fi
}

for f in "${dockerfiles[@]}"; do
  echo "Checking $f"
  check_no_latest "$f"
  check_non_root "$f"
done

if [[ $fail -ne 0 ]]; then
  echo ""
  echo "Docker policy checks FAILED."
  echo "Fix the issues above and re-run."
  exit 1
fi

echo "Docker policy checks passed ✔"
