#!/usr/bin/env bash
set -euo pipefail

# Top-level validation runner
# Usage examples:
#   ./scripts/validate/validate.sh lab-01
#   ./scripts/validate/validate.sh lab-01-getting-started
#   ./scripts/validate/validate.sh labs/lab-01
#   ./scripts/validate/validate.sh labs/lab-01-getting-started

lab_input="${1:-}"

if [[ -z "${lab_input}" ]]; then
  echo "Usage: ./scripts/validate/validate.sh <lab-id>" >&2
  echo "Examples:" >&2
  echo "  ./scripts/validate/validate.sh lab-01" >&2
  echo "  ./scripts/validate/validate.sh labs/lab-01" >&2
  exit 2
fi

# Normalize input into a lab directory under ./labs
# Accept:
# - "lab-01"
# - "lab-01-foo"
# - "labs/lab-01"
# - "labs/lab-01-foo"
case "${lab_input}" in
  labs/*) lab_dir="${lab_input}" ;;
  lab-*)  lab_dir="labs/${lab_input}" ;;
  *)      lab_dir="labs/${lab_input}" ;;
esac

if [[ ! -d "${lab_dir}" ]]; then
  echo "ERROR: Lab directory not found: ${lab_dir}" >&2
  echo "Hint: expected something like labs/lab-01" >&2
  exit 2
fi

validator="${lab_dir}/validate.sh"
if [[ ! -f "${validator}" ]]; then
  echo "ERROR: No validate.sh found in ${lab_dir}" >&2
  echo "Expected: ${validator}" >&2
  exit 2
fi

# Ensure executable bit isn't required (run via bash either way)
echo "Running validator: ${validator}"
bash "${validator}"

echo "✅ Validation passed for: ${lab_dir}"
