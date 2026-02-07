#!/usr/bin/env bash
set -euo pipefail

# Top-level validation runner
# Usage examples:
#   ./scripts/validate/validate.sh lab-01
#   ./scripts/validate/validate.sh lab-01-getting-started
#   ./scripts/validate/validate.sh labs/lab-01
#   ./scripts/validate/validate.sh labs/lab-01-getting-started

lab_input="${1:-all}"

if [[ "${lab_input}" == "-h" || "${lab_input}" == "--help" ]]; then
  echo "Usage: ./scripts/validate/validate.sh <lab-id|all>" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  ./scripts/validate/validate.sh lab-01" >&2
  echo "  ./scripts/validate/validate.sh labs/lab-01" >&2
  echo "  ./scripts/validate/validate.sh all" >&2
  echo "" >&2
  echo "Notes:" >&2
  echo "  - 'all' validates every labs/lab-* directory that contains validate.sh" >&2
  exit 0
fi

run_one() {
  local input="$1"
  local lab_dir validator

  # Sanitize input (handle leading "./" and possible CRLF)
  input="${input//$'\r'/}"
  input="${input#./}"

  # Normalize input into a lab directory under ./labs
  case "${input}" in
    labs/*)   lab_dir="${input}" ;;
    lab-*)    lab_dir="labs/${input}" ;;
    *)        lab_dir="labs/${input}" ;;
  esac

  if [[ ! -d "${lab_dir}" ]]; then
    echo "ERROR: Lab directory not found: ${lab_dir}" >&2
    echo "Hint: expected something like labs/lab-01" >&2
    return 2
  fi

  validator="${lab_dir}/validate.sh"
  if [[ ! -f "${validator}" ]]; then
    echo "ERROR: No validate.sh found in ${lab_dir}" >&2
    echo "Expected: ${validator}" >&2
    return 2
  fi

  echo "Running validator: ${validator}"
  (
    cd "${lab_dir}"
    bash "./validate.sh"
  )
  echo "✅ Validation passed for: ${lab_dir}"
}

if [[ "${lab_input}" == "all" ]]; then
  # Validate every lab folder that has a validate.sh
  labs_to_run=$(find ./labs -maxdepth 1 -type d -name "lab-*" | sort)

  if [[ -z "${labs_to_run}" ]]; then
    echo "ERROR: No labs found under ./labs (expected directories like labs/lab-01)" >&2
    exit 2
  fi

  failures=0
  echo "Validating all labs..."
  while IFS= read -r d; do
    if [[ -f "${d}/validate.sh" ]]; then
      echo ""
      echo "=== ${d} ==="
      if ! run_one "${d}"; then
        echo "❌ Validation failed for: ${d}" >&2
        failures=$((failures + 1))
      fi
    else
      echo ""
      echo "=== ${d} ==="
      echo "SKIP: No validate.sh in ${d}"
    fi
  done <<< "${labs_to_run}"

  echo ""
  if [[ ${failures} -ne 0 ]]; then
    echo "❌ Validation finished with ${failures} failure(s)." >&2
    exit 1
  fi

  echo "✅ All validations passed."
  exit 0
fi


# Single lab mode
run_one "${lab_input}"
