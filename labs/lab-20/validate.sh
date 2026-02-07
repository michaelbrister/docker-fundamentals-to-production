#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 20 — Incident Day (Final Exam)"

command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker CLI not found." >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "ERROR: Docker daemon not reachable." >&2; exit 1; }

required=(
  "README.md" ".env.example" "compose.yaml" "compose.prod.yaml" "compose.secrets.yaml"
  "hints.md" "instructor-notes.md"
  "INCIDENT_TEMPLATE.md" "TIMELINE_TEMPLATE.md" "RECOVERY_TEMPLATE.md"
  "db/init.sql"
  "api/Dockerfile.distroless" "api/main.go" "api/go.mod"
  "secrets/db_password.txt.example"
  "reset.sh" "reset.ps1"
)
for f in "${required[@]}"; do [[ -f "$f" ]] || { echo "ERROR: Missing required file: $f" >&2; exit 1; }; done

# Learner artifacts
[[ -f ".env" ]] || { echo "ERROR: .env not found. Create it from .env.example." >&2; exit 1; }
[[ -f "break-mode.txt" ]] || { echo "ERROR: break-mode.txt missing. Start the incident using reset.sh/reset.ps1." >&2; exit 1; }
[[ -f "secrets/db_password.txt" ]] || { echo "ERROR: secrets/db_password.txt not found. Create it from example (DO NOT COMMIT)." >&2; exit 1; }
[[ -f "INCIDENT.md" ]] || { echo "ERROR: INCIDENT.md missing. Create from template." >&2; exit 1; }
[[ -f "TIMELINE.md" ]] || { echo "ERROR: TIMELINE.md missing. Create from template." >&2; exit 1; }
[[ -f "RECOVERY.md" ]] || { echo "ERROR: RECOVERY.md missing. Create from template." >&2; exit 1; }

for doc in INCIDENT.md TIMELINE.md RECOVERY.md; do
  if grep -q "REPLACE_ME" "$doc"; then
    echo "ERROR: $doc still contains REPLACE_ME placeholders." >&2
    exit 1
  fi
done

if grep -q "REPLACE_ME" .env; then
  echo "ERROR: .env contains REPLACE_ME. You must set KNOWN_GOOD_IMAGE_REF and PROMOTED_IMAGE_REF." >&2
  exit 1
fi

# Enforce prod compose is image-only
if grep -Eq '^\s*build\s*:' compose.prod.yaml; then
  echo "ERROR: compose.prod.yaml must NOT contain 'build:' (prod-like image-only mode)." >&2
  exit 1
fi

mode="$(tr -d '\r\n' < break-mode.txt)"
if [[ "${mode}" != "mode-a" && "${mode}" != "mode-b" ]]; then
  echo "ERROR: break-mode.txt must be 'mode-a' or 'mode-b'." >&2
  exit 1
fi

rc="$(grep -E '^RC_VERSION=' .env | head -n1 | cut -d= -f2- | tr -d '\r\n')"
good_ref="$(grep -E '^KNOWN_GOOD_IMAGE_REF=' .env | head -n1 | cut -d= -f2- | tr -d '\r\n')"
promoted="$(grep -E '^PROMOTED_IMAGE_REF=' .env | head -n1 | cut -d= -f2- | tr -d '\r\n')"

[[ -n "${rc}" ]] || { echo "ERROR: RC_VERSION missing in .env" >&2; exit 1; }
[[ "${good_ref}" == sha256:* ]] || { echo "ERROR: KNOWN_GOOD_IMAGE_REF must look like sha256:..." >&2; exit 1; }
[[ "${promoted}" == sha256:* ]] || { echo "ERROR: PROMOTED_IMAGE_REF must look like sha256:..." >&2; exit 1; }

secret="$(tr -d '\r\n' < secrets/db_password.txt)"
[[ -n "$secret" && ${#secret} -ge 12 ]] || { echo "ERROR: secrets/db_password.txt must be >= 12 chars" >&2; exit 1; }

# Image must exist locally and match good_ref (no rebuild needed here, but artifact must be present)
built_id="$(docker image inspect "dzth/mini-platform-api:${rc}" --format '{{.Id}}' 2>/dev/null || true)"
if [[ -z "${built_id}" ]]; then
  echo "ERROR: Known-good image dzth/mini-platform-api:${rc} not found locally." >&2
  echo "Action: build it once (allowed before incident):" >&2
  echo "  docker build -f api/Dockerfile.distroless -t dzth/mini-platform-api:${rc} api" >&2
  exit 1
fi
if [[ "${built_id}" != "${good_ref}" ]]; then
  echo "ERROR: KNOWN_GOOD_IMAGE_REF does not match the built image ID for dzth/mini-platform-api:${rc}" >&2
  echo "Expected: ${built_id}" >&2
  echo "Got:      ${good_ref}" >&2
  echo "Fix: set KNOWN_GOOD_IMAGE_REF to docker image inspect output." >&2
  exit 1
fi

if docker ps -a --filter "label=com.docker.compose.project=lab-20" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-20 containers already exist. Cleanup first." >&2
  exit 1
fi

cleanup(){ docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "Bringing up lab-20 prod-like stack for verification..."
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d

echo "Waiting for readiness..."
for i in $(seq 1 50); do
  if curl -fsS http://localhost:8086/readyz >/dev/null 2>&1; then break; fi
  sleep 2
done
curl -fsS http://localhost:8086/readyz >/dev/null 2>&1 || { echo "ERROR: /readyz not ready (service not recovered)" >&2; docker compose logs api --tail 200 >&2 || true; exit 1; }

curl -sS -i http://localhost:8086/notes | head -n1 | grep -q "200" || { echo "ERROR: /notes did not return 200 (service not recovered)" >&2; curl -sS -i http://localhost:8086/notes || true; exit 1; }

curl -fsS http://localhost:8086/version | grep -q "${rc}" || { echo "ERROR: /version did not include RC_VERSION=${rc}" >&2; curl -fsS http://localhost:8086/version || true; exit 1; }

# Provenance: prod must run the known-good artifact
prod_image_id="$(docker inspect -f '{{.Image}}' lab20-api 2>/dev/null || true)"
[[ -n "${prod_image_id}" ]] || { echo "ERROR: Could not inspect lab20-api image id" >&2; exit 1; }
if [[ "${prod_image_id}" != "${good_ref#sha256:}" && "${prod_image_id}" != "${good_ref}" ]]; then
  echo "ERROR: PROD is not running the known-good artifact." >&2
  echo "Expected KNOWN_GOOD_IMAGE_REF: ${good_ref}" >&2
  echo "Got container image id:        ${prod_image_id}" >&2
  exit 1
fi

# Secrets must not leak in logs
if docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api 2>/dev/null | grep -Fq "${secret}"; then
  echo "ERROR: Secret value was found in API logs. Secrets must be redacted." >&2
  exit 1
fi

trap - EXIT
cleanup
docker ps -a --filter "label=com.docker.compose.project=lab-20" --format '{{.ID}}' | grep -q . && { echo "ERROR: lab-20 containers still exist after cleanup" >&2; exit 1; }

echo "Lab 20 validation passed ✔"
