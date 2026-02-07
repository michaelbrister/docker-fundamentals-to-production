#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 16 — Capstone Release Candidate"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable." >&2
  exit 1
fi

required=(
  "README.md"
  ".env.example"
  "compose.yaml"
  "compose.dev.yaml"
  "compose.prod.yaml"
  "compose.secrets.yaml"
  "RELEASE.md"
  "RUNBOOK_TEMPLATE.md"
  "INCIDENT_TEMPLATE.md"
  "hints.md"
  "instructor-notes.md"
  "api/Dockerfile.distroless"
  "api/main.go"
  "db/init.sql"
  "secrets/db_password.txt.example"
)

for f in "${required[@]}"; do
  [[ -f "$f" ]] || { echo "ERROR: Missing required file: $f" >&2; exit 1; }
done

# Learner deliverables
[[ -f "RUNBOOK.md" ]] || { echo "ERROR: RUNBOOK.md not found. Create it from RUNBOOK_TEMPLATE.md." >&2; exit 1; }
[[ -f "INCIDENT.md" ]] || { echo "ERROR: INCIDENT.md not found. Create it from INCIDENT_TEMPLATE.md." >&2; exit 1; }

# Local-only files
[[ -f ".env" ]] || { echo "ERROR: .env not found. Create it from .env.example." >&2; exit 1; }
[[ -f "secrets/db_password.txt" ]] || { echo "ERROR: secrets/db_password.txt not found. Create it from secrets/db_password.txt.example (DO NOT COMMIT)." >&2; exit 1; }

# Ensure prod compose has no build context
if grep -Eq '^\s*build\s*:' compose.prod.yaml; then
  echo "ERROR: compose.prod.yaml must NOT contain 'build:'. Prod mode must run from images." >&2
  exit 1
fi

# Release version required
release_version="$(grep -E '^RELEASE_VERSION=' .env | head -n 1 | cut -d= -f2- | tr -d '\r\n' || true)"
if [[ -z "${release_version}" ]]; then
  echo "ERROR: RELEASE_VERSION is missing from .env" >&2
  exit 1
fi
if [[ "${release_version}" == "latest" ]]; then
  echo "ERROR: RELEASE_VERSION must not be 'latest'." >&2
  exit 1
fi

# Secret must be unique for leak test
secret_value="$(tr -d '\r\n' < secrets/db_password.txt)"
if [[ -z "${secret_value}" || "${#secret_value}" -lt 12 ]]; then
  echo "ERROR: secrets/db_password.txt must be a unique value (>= 12 chars) for this lab." >&2
  exit 1
fi

# Best-effort git hygiene
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git ls-files --error-unmatch ".env" >/dev/null 2>&1; then
    echo "ERROR: .env is tracked by git. Keep it local-only." >&2
    exit 1
  fi
  if git ls-files --error-unmatch "secrets/db_password.txt" >/dev/null 2>&1; then
    echo "ERROR: secrets/db_password.txt is tracked by git. Do NOT commit secret files." >&2
    exit 1
  fi
fi

# Ensure no existing lab-16 containers before start
if docker ps -a --filter "label=com.docker.compose.project=lab-16" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-16 containers already exist. Cleanup first with: docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down" >&2
  exit 1
fi

# Build release image (RC mindset)
echo "Building release image dzth/mini-platform-api:${release_version} ..."
docker build -f api/Dockerfile.distroless -t "dzth/mini-platform-api:${release_version}" api >/dev/null

echo "Bringing up lab-16 prod-like stack for smoke validation (image-only)..."
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d

cleanup() {
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Verify container uses the expected image tag
img="$(docker inspect -f '{{.Config.Image}}' lab16-api 2>/dev/null || true)"
if [[ "${img}" != "dzth/mini-platform-api:${release_version}" ]]; then
  echo "ERROR: api container is not running the expected image tag." >&2
  echo "Expected: dzth/mini-platform-api:${release_version}" >&2
  echo "Actual:   ${img}" >&2
  exit 1
fi

# Verify runtime hardening flags (prod)
ro="$(docker inspect -f '{{.HostConfig.ReadonlyRootfs}}' lab16-api)"
if [[ "${ro}" != "true" ]]; then
  echo "ERROR: api container must run with read-only rootfs in prod." >&2
  exit 1
fi

# no-new-privileges
nnp="$(docker inspect -f '{{json .HostConfig.SecurityOpt}}' lab16-api)"
echo "${nnp}" | grep -q "no-new-privileges" || { echo "ERROR: api container must set no-new-privileges:true in prod." >&2; exit 1; }

# cap drop ALL
caps="$(docker inspect -f '{{json .HostConfig.CapDrop}}' lab16-api)"
echo "${caps}" | grep -q "ALL" || { echo "ERROR: api container must drop ALL capabilities in prod." >&2; exit 1; }

echo "Waiting for readiness..."
ready_ok=0
for i in $(seq 1 50); do
  if curl -fsS http://localhost:8082/readyz >/dev/null 2>&1; then
    ready_ok=1
    break
  fi
  sleep 2
done
if [[ "${ready_ok}" -ne 1 ]]; then
  echo "ERROR: /readyz did not become ready in time." >&2
  curl -sS -i http://localhost:8082/readyz || true
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api --tail 200 >&2 || true
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs db --tail 200 >&2 || true
  exit 1
fi

# Endpoints
curl -fsS http://localhost:8082/healthz >/dev/null
curl -fsS http://localhost:8082/readyz >/dev/null
curl -fsS http://localhost:8082/notes >/dev/null
curl -fsS http://localhost:8082/metrics >/dev/null
curl -fsS http://localhost:8082/version | grep -q "${release_version}" || { echo "ERROR: /version did not include release_version=${release_version}" >&2; exit 1; }

# Generate traffic
curl -fsS http://localhost:8082/notes >/dev/null
curl -fsS -X POST http://localhost:8082/notes -H 'content-type: application/json' -d '{"message":"validator"}' >/dev/null
curl -fsS http://localhost:8082/notes >/dev/null

m_before="$(curl -fsS http://localhost:8082/metrics)"
echo "${m_before}" | grep -q "http_requests_total" || { echo "ERROR: metrics missing http_requests_total" >&2; exit 1; }
echo "${m_before}" | grep -q "http_request_duration_ms_count" || { echo "ERROR: metrics missing duration count" >&2; exit 1; }

# Simulate DB outage and prove signals change (poll to avoid race)
echo "Simulating DB outage..."
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml stop db >/dev/null

ready_503=0
for i in $(seq 1 25); do
  if curl -sS -i http://localhost:8082/readyz | head -n 1 | grep -q "503"; then
    ready_503=1
    break
  fi
  sleep 1
done
if [[ "${ready_503}" -ne 1 ]]; then
  echo "ERROR: expected /readyz 503 during DB outage (timed out)." >&2
  curl -sS -i http://localhost:8082/readyz || true
  docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api --tail 200 >&2 || true
  exit 1
fi

# Hit /notes to produce 5xx signals
for i in $(seq 1 5); do
  curl -sS -i http://localhost:8082/notes >/dev/null 2>&1 || true
  sleep 1
done

# Metrics should include some 5xx (eventually)
for i in $(seq 1 25); do
  m="$(curl -fsS http://localhost:8082/metrics)"
  if echo "${m}" | grep -q 'http_errors_total [1-9]'; then
    break
  fi
  sleep 1
done

m_after="$(curl -fsS http://localhost:8082/metrics)"
echo "${m_after}" | grep -q 'http_errors_total [1-9]' || { echo "ERROR: expected http_errors_total to be > 0 after outage" >&2; echo "${m_after}" >&2; exit 1; }

# Prove secret is not leaked in logs
if docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api 2>/dev/null | grep -Fq "${secret_value}"; then
  echo "ERROR: Secret value was found in API logs. Secrets must be redacted." >&2
  exit 1
fi

# Cleanup and enforce no leftovers
trap - EXIT
cleanup
if docker ps -a --filter "label=com.docker.compose.project=lab-16" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-16 containers still exist after cleanup." >&2
  exit 1
fi

echo "Lab 16 validation passed ✔"
