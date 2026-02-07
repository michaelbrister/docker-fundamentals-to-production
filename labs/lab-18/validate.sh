#!/usr/bin/env bash
set -euo pipefail
echo "Validating Lab 18 — Release & Rollback Discipline"

command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker CLI not found." >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "ERROR: Docker daemon not reachable." >&2; exit 1; }

required=(
  "README.md" ".env.example" "compose.yaml" "compose.prod.yaml" "compose.secrets.yaml"
  "RELEASE.md" "INCIDENT_TEMPLATE.md" "hints.md" "instructor-notes.md"
  "db/init.sql"
  "api-good/Dockerfile.distroless" "api-good/main.go" "api-good/go.mod"
  "api-bad/Dockerfile.distroless" "api-bad/main.go" "api-bad/go.mod"
  "secrets/db_password.txt.example"
)
for f in "${required[@]}"; do [[ -f "$f" ]] || { echo "ERROR: Missing required file: $f" >&2; exit 1; }; done

[[ -f "INCIDENT.md" ]] || { echo "ERROR: INCIDENT.md not found. Create it from INCIDENT_TEMPLATE.md." >&2; exit 1; }
[[ -f ".env" ]] || { echo "ERROR: .env not found. Create it from .env.example." >&2; exit 1; }
[[ -f "secrets/db_password.txt" ]] || { echo "ERROR: secrets/db_password.txt not found. Create it from secrets/db_password.txt.example (DO NOT COMMIT)." >&2; exit 1; }

grep -Eq '^\s*build\s*:' compose.prod.yaml && { echo "ERROR: compose.prod.yaml must not contain build:" >&2; exit 1; }

good="$(grep -E '^GOOD_VERSION=' .env | head -n1 | cut -d= -f2- | tr -d '\r\n' || true)"
bad="$(grep -E '^BAD_VERSION=' .env | head -n1 | cut -d= -f2- | tr -d '\r\n' || true)"
[[ -n "$good" && -n "$bad" && "$good" != "latest" && "$bad" != "latest" ]] || { echo "ERROR: GOOD_VERSION and BAD_VERSION must be set (not latest)" >&2; exit 1; }

secret="$(tr -d '\r\n' < secrets/db_password.txt)"
[[ -n "$secret" && ${#secret} -ge 12 ]] || { echo "ERROR: secrets/db_password.txt must be >= 12 chars" >&2; exit 1; }

if docker ps -a --filter "label=com.docker.compose.project=lab-18" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-18 containers already exist. Cleanup first." >&2
  exit 1
fi

echo "Building GOOD image dzth/mini-platform-api:${good} ..."
docker build -f api-good/Dockerfile.distroless -t "dzth/mini-platform-api:${good}" api-good >/dev/null
echo "Building BAD image dzth/mini-platform-api:${bad} ..."
docker build -f api-bad/Dockerfile.distroless -t "dzth/mini-platform-api:${bad}" api-bad >/dev/null

cleanup(){ docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "Starting BAD release (expected regression)..."
ACTIVE_VERSION="${bad}" docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d

echo "Waiting for /readyz..."
for i in $(seq 1 40); do curl -fsS http://localhost:8083/readyz >/dev/null 2>&1 && break; sleep 2; done
curl -fsS http://localhost:8083/readyz >/dev/null 2>&1 || { echo "ERROR: /readyz not ready on BAD"; docker compose logs api --tail 200 >&2 || true; exit 1; }

notes_500=0
for i in $(seq 1 10); do
  if curl -sS -i http://localhost:8083/notes | head -n1 | grep -q "500"; then notes_500=1; break; fi
  sleep 1
done
[[ "$notes_500" -eq 1 ]] || { echo "ERROR: expected /notes 500 on BAD"; curl -sS -i http://localhost:8083/notes || true; exit 1; }

echo "Rolling back to GOOD release..."
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down >/dev/null
ACTIVE_VERSION="${good}" docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d

for i in $(seq 1 40); do curl -fsS http://localhost:8083/readyz >/dev/null 2>&1 && break; sleep 2; done
curl -fsS http://localhost:8083/readyz >/dev/null 2>&1 || { echo "ERROR: /readyz not ready on GOOD"; exit 1; }

curl -sS -i http://localhost:8083/notes | head -n1 | grep -q "200" || { echo "ERROR: expected /notes 200 after rollback"; curl -sS -i http://localhost:8083/notes || true; exit 1; }

if ! curl -fsS http://localhost:8083/version | grep -q "${good}"; then
  echo "ERROR: Rollback incomplete." >&2
  echo "Expected /version to report the GOOD_VERSION (${good})." >&2
  echo "This usually means ACTIVE_VERSION was not updated to GOOD_VERSION during rollback." >&2
  echo "Fix: re-run rollback using ACTIVE_VERSION=${good} and restart the stack." >&2
  echo "" >&2
  echo "Current /version output:" >&2
  curl -fsS http://localhost:8083/version >&2 || true
  exit 1
fi

if docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api 2>/dev/null | grep -Fq "${secret}"; then
  echo "ERROR: Secret value was found in API logs." >&2
  exit 1
fi

trap - EXIT
cleanup
docker ps -a --filter "label=com.docker.compose.project=lab-18" --format '{{.ID}}' | grep -q . && { echo "ERROR: lab-18 containers still exist after cleanup"; exit 1; }

echo "Lab 18 validation passed ✔"
