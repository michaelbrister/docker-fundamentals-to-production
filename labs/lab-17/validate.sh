#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 17 — Supply Chain (SBOM + Vulnerability Policy)"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' not found. Install it for this lab." >&2; exit 1; }
}

need_cmd docker
need_cmd syft
need_cmd grype

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable." >&2
  exit 1
fi

required=(
  "README.md"
  ".env.example"
  "hints.md"
  "instructor-notes.md"
  "SBOM_TEMPLATE.md"
  "SECURITY_NOTES_TEMPLATE.md"
  "api/Dockerfile.distroless"
  "api/main.go"
  "api/go.mod"
  "secrets/db_password.txt.example"
  "ci/github-actions-workflow.yml"
)

for f in "${required[@]}"; do
  [[ -f "$f" ]] || { echo "ERROR: Missing required file: $f" >&2; exit 1; }
done

# Learner deliverables
[[ -f "SBOM.md" ]] || { echo "ERROR: SBOM.md not found. Create it from SBOM_TEMPLATE.md." >&2; exit 1; }
[[ -f "SECURITY_NOTES.md" ]] || { echo "ERROR: SECURITY_NOTES.md not found. Create it from SECURITY_NOTES_TEMPLATE.md." >&2; exit 1; }

# Local-only files
[[ -f ".env" ]] || { echo "ERROR: .env not found. Create it from .env.example." >&2; exit 1; }
[[ -f "secrets/db_password.txt" ]] || { echo "ERROR: secrets/db_password.txt not found. Create it from secrets/db_password.txt.example (DO NOT COMMIT)." >&2; exit 1; }

release_version="$(grep -E '^RELEASE_VERSION=' .env | head -n 1 | cut -d= -f2- | tr -d '\r\n' || true)"
if [[ -z "${release_version}" || "${release_version}" == "latest" ]]; then
  echo "ERROR: RELEASE_VERSION must be set and must not be 'latest'." >&2
  exit 1
fi

secret_value="$(tr -d '\r\n' < secrets/db_password.txt)"
if [[ -z "${secret_value}" || "${#secret_value}" -lt 12 ]]; then
  echo "ERROR: secrets/db_password.txt must be a unique value (>= 12 chars) for this lab." >&2
  exit 1
fi

# Build image (artifact mindset)
echo "Building image dzth/mini-platform-api:${release_version} ..."
docker build -f api/Dockerfile.distroless -t "dzth/mini-platform-api:${release_version}" api >/dev/null

# Generate SBOM (require sbom.json exists after generation)
echo "Generating SBOM (spdx-json) -> sbom.json ..."
syft "dzth/mini-platform-api:${release_version}" -o spdx-json=sbom.json >/dev/null
[[ -s "sbom.json" ]] || { echo "ERROR: sbom.json was not created or is empty." >&2; exit 1; }

# Scan image — fail CRITICAL only
echo "Scanning image with policy: fail-on CRITICAL ..."
set +e
grype "dzth/mini-platform-api:${release_version}" --fail-on critical
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "ERROR: Grype reported CRITICAL vulnerabilities (policy violation)." >&2
  echo "Action: document findings in SECURITY_NOTES.md and mitigate (upgrade base/deps), then re-run." >&2
  exit 1
fi

# Basic sanity: templates should mention policy
grep -qi "CRITICAL" SECURITY_NOTES_TEMPLATE.md || { echo "ERROR: SECURITY_NOTES_TEMPLATE.md should mention CRITICAL policy." >&2; exit 1; }

echo "Lab 17 validation passed ✔"
