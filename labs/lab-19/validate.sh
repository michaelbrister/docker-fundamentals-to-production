#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 19 — Promotion & Provenance"

command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker CLI not found." >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "ERROR: Docker daemon not reachable." >&2; exit 1; }

required=(
  "README.md" ".env.example" "compose.yaml" "compose.dev.yaml" "compose.prod.yaml" "compose.secrets.yaml"
  "hints.md" "instructor-notes.md"
  "PROMOTION_TEMPLATE.md" "PROVENANCE_TEMPLATE.md"
  "db/init.sql"
  "api/Dockerfile.distroless" "api/main.go" "api/go.mod"
  "secrets/db_password.txt.example"
)

for f in "${required[@]}"; do [[ -f "$f" ]] || { echo "ERROR: Missing required file: $f" >&2; exit 1; }; done

# Learner deliverables
[[ -f ".env" ]] || { echo "ERROR: .env not found. Create it from .env.example." >&2; exit 1; }
[[ -f "secrets/db_password.txt" ]] || { echo "ERROR: secrets/db_password.txt not found. Create it from example (DO NOT COMMIT)." >&2; exit 1; }
[[ -f "PROMOTION.md" ]] || { echo "ERROR: PROMOTION.md not found. Create it from PROMOTION_TEMPLATE.md." >&2; exit 1; }
[[ -f "PROVENANCE.md" ]] || { echo "ERROR: PROVENANCE.md not found. Create it from PROVENANCE_TEMPLATE.md." >&2; exit 1; }

if grep -q "REPLACE_ME" .env; then
  echo "ERROR: .env contains REPLACE_ME. Set PROMOTED_IMAGE_REF after building the RC." >&2
  exit 1
fi
if grep -q "REPLACE_ME" PROMOTION.md || grep -q "REPLACE_ME" PROVENANCE.md; then
  echo "ERROR: PROMOTION.md/PROVENANCE.md still contains REPLACE_ME placeholders." >&2
  exit 1
fi

# ensure prod compose has no build context
if grep -Eq '^\s*build\s*:' compose.prod.yaml; then
  echo "ERROR: compose.prod.yaml must NOT contain 'build:'. Prod-like must run from image reference only." >&2
  exit 1
fi

rc="$(grep -E '^RC_VERSION=' .env | head -n 1 | cut -d= -f2- | tr -d '\r\n' || true)"
promoted="$(grep -E '^PROMOTED_IMAGE_REF=' .env | head -n 1 | cut -d= -f2- | tr -d '\r\n' || true)"
[[ -n "${rc}" ]] || { echo "ERROR: RC_VERSION missing in .env" >&2; exit 1; }
[[ -n "${promoted}" ]] || { echo "ERROR: PROMOTED_IMAGE_REF missing in .env" >&2; exit 1; }
[[ "${promoted}" == sha256:* ]] || { echo "ERROR: PROMOTED_IMAGE_REF must look like sha256:... (image ID)" >&2; exit 1; }

secret="$(tr -d '\r\n' < secrets/db_password.txt)"
[[ -n "$secret" && ${#secret} -ge 12 ]] || { echo "ERROR: secrets/db_password.txt must be >= 12 chars" >&2; exit 1; }

cleanup_all() {
  docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml down >/dev/null 2>&1 || true
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down >/dev/null 2>&1 || true
}
trap cleanup_all EXIT

# Guard: no existing containers
if docker ps -a --filter "label=com.docker.compose.project=lab-19" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-19 containers already exist. Cleanup first." >&2
  exit 1
fi

echo "Building RC image in DEV..."
docker compose -f compose.yaml -f compose.dev.yaml build >/dev/null

# Verify the built image ID matches PROMOTED_IMAGE_REF
built_id="$(docker image inspect "dzth/mini-platform-api:${rc}" --format '{{.Id}}' 2>/dev/null || true)"
[[ -n "${built_id}" ]] || { echo "ERROR: Could not inspect dzth/mini-platform-api:${rc}. Did the build succeed?" >&2; exit 1; }

if [[ "${built_id}" != "${promoted}" ]]; then
  echo "ERROR: PROMOTED_IMAGE_REF does not match the built image ID for dzth/mini-platform-api:${rc}" >&2
  echo "Expected: ${built_id}" >&2
  echo "Got:      ${promoted}" >&2
  echo "Fix: set PROMOTED_IMAGE_REF in .env to the output of:" >&2
  echo "  docker image inspect dzth/mini-platform-api:${rc} --format '{{.Id}}'" >&2
  exit 1
fi

echo "Starting DEV stack (RC tag)..."
docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml up -d

echo "Waiting for DEV /readyz..."
for i in $(seq 1 40); do curl -fsS http://localhost:8084/readyz >/dev/null 2>&1 && break; sleep 2; done
curl -fsS http://localhost:8084/readyz >/dev/null 2>&1 || { echo "ERROR: DEV /readyz not ready"; docker compose -f compose.yaml -f compose.dev.yaml logs api --tail 200 >&2 || true; exit 1; }

curl -fsS http://localhost:8084/version | grep -q "${rc}" || { echo "ERROR: DEV /version did not include RC_VERSION=${rc}" >&2; curl -fsS http://localhost:8084/version || true; exit 1; }

# Ensure secret is not leaked in logs
if docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml logs api 2>/dev/null | grep -Fq "${secret}"; then
  echo "ERROR: Secret value was found in DEV API logs. Secrets must be redacted." >&2
  exit 1
fi

echo "Stopping DEV..."
docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml down >/dev/null

echo "Starting PROD-like stack (immutable image ref)..."
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d

echo "Waiting for PROD /readyz..."
for i in $(seq 1 40); do curl -fsS http://localhost:8085/readyz >/dev/null 2>&1 && break; sleep 2; done
curl -fsS http://localhost:8085/readyz >/dev/null 2>&1 || { echo "ERROR: PROD /readyz not ready"; docker compose -f compose.yaml -f compose.prod.yaml logs api --tail 200 >&2 || true; exit 1; }

curl -fsS http://localhost:8085/version | grep -q "${rc}" || { echo "ERROR: PROD /version did not include RC_VERSION=${rc}" >&2; curl -fsS http://localhost:8085/version || true; exit 1; }

# Verify prod container image ID equals promoted
prod_image_id="$(docker inspect -f '{{.Image}}' lab19-api 2>/dev/null || true)"
[[ -n "${prod_image_id}" ]] || { echo "ERROR: Could not inspect prod container lab19-api" >&2; exit 1; }
if [[ "${prod_image_id}" != "${promoted#sha256:}" && "${prod_image_id}" != "${promoted}" ]]; then
  # docker inspect .Image usually returns bare sha without prefix; tolerate both
  echo "ERROR: PROD container is not running the promoted image ID." >&2
  echo "Expected: ${promoted}" >&2
  echo "Got:      ${prod_image_id}" >&2
  exit 1
fi

# Ensure secret not leaked
if docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api 2>/dev/null | grep -Fq "${secret}"; then
  echo "ERROR: Secret value was found in PROD API logs. Secrets must be redacted." >&2
  exit 1
fi

trap - EXIT
cleanup_all
if docker ps -a --filter "label=com.docker.compose.project=lab-19" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-19 containers still exist after cleanup." >&2
  exit 1
fi

echo "Lab 19 validation passed ✔"
