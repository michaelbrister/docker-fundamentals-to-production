#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 15 — Observability"

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
  "compose.secrets.yaml"
  "OBSERVABILITY_NOTES_TEMPLATE.md"
  "hints.md"
  "instructor-notes.md"
  "solutions/solution.md"
  "api/Dockerfile.distroless"
  "api/main.go"
  "db/init.sql"
  "secrets/db_password.txt.example"
)

for f in "${required[@]}"; do
  [[ -f "$f" ]] || { echo "ERROR: Missing required file: $f" >&2; exit 1; }
done

# Learner deliverable
[[ -f "OBSERVABILITY_NOTES.md" ]] || { echo "ERROR: OBSERVABILITY_NOTES.md not found. Create it from OBSERVABILITY_NOTES_TEMPLATE.md." >&2; exit 1; }

# Local-only files
[[ -f ".env" ]] || { echo "ERROR: .env not found. Create it from .env.example." >&2; exit 1; }
[[ -f "secrets/db_password.txt" ]] || { echo "ERROR: secrets/db_password.txt not found. Create it from secrets/db_password.txt.example (DO NOT COMMIT)." >&2; exit 1; }

# Secret must be unique for leak test
secret_value="$(tr -d '\r\n' < secrets/db_password.txt)"
if [[ -z "${secret_value}" || "${#secret_value}" -lt 12 ]]; then
  echo "ERROR: secrets/db_password.txt must be a unique value (>= 12 chars) for this lab." >&2
  echo "Hint: use something like 'lab15-supersecret-change-me'." >&2
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

# Ensure no existing lab-15 containers before start
if docker ps -a --filter "label=com.docker.compose.project=lab-15" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-15 containers already exist. Cleanup first with: docker compose -f compose.yaml -f compose.secrets.yaml down" >&2
  exit 1
fi

echo "Bringing up lab-15 stack for smoke validation..."
docker compose -f compose.yaml -f compose.secrets.yaml up -d --build

cleanup() {
  docker compose -f compose.yaml -f compose.secrets.yaml down >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Waiting for readiness..."
ready_ok=0
for i in $(seq 1 40); do
  if curl -fsS http://localhost:8081/readyz >/dev/null 2>&1; then
    ready_ok=1
    break
  fi
  sleep 2
done
if [[ "${ready_ok}" -ne 1 ]]; then
  echo "ERROR: /readyz did not become ready in time." >&2
  curl -sS -i http://localhost:8081/readyz || true
  docker compose -f compose.yaml -f compose.secrets.yaml logs api --tail 200 >&2 || true
  docker compose -f compose.yaml -f compose.secrets.yaml logs db --tail 200 >&2 || true
  exit 1
fi

# Basic endpoint checks
curl -fsS http://localhost:8081/healthz >/dev/null
curl -fsS http://localhost:8081/readyz >/dev/null
curl -fsS http://localhost:8081/notes >/dev/null
curl -fsS http://localhost:8081/metrics >/dev/null

# Generate traffic
curl -fsS http://localhost:8081/notes >/dev/null
curl -fsS -X POST http://localhost:8081/notes -H 'content-type: application/json' -d '{"message":"validator"}' >/dev/null
curl -fsS http://localhost:8081/notes >/dev/null

metrics_before="$(curl -fsS http://localhost:8081/metrics)"
echo "${metrics_before}" | grep -q "http_requests_total" || { echo "ERROR: metrics missing http_requests_total" >&2; exit 1; }
echo "${metrics_before}" | grep -q "http_request_duration_ms_count" || { echo "ERROR: metrics missing duration count" >&2; exit 1; }
echo "${metrics_before}" | grep -q "db_ping_failures_total" || { echo "ERROR: metrics missing db ping failures" >&2; exit 1; }

# Simulate DB outage and prove signals change
echo "Simulating DB outage..."
docker compose -f compose.yaml -f compose.secrets.yaml stop db >/dev/null

# API should eventually report not ready (avoid race with readiness loop)
ready_503=0
for i in $(seq 1 20); do
  if curl -sS -i http://localhost:8081/readyz | head -n 1 | grep -q "503"; then
    ready_503=1
    break
  fi
  sleep 1
done
if [[ "${ready_503}" -ne 1 ]]; then
  echo "ERROR: expected /readyz 503 during DB outage (timed out)." >&2
  echo "---- /readyz response ----" >&2
  curl -sS -i http://localhost:8081/readyz || true
  echo "---- api logs ----" >&2
  docker compose -f compose.yaml -f compose.secrets.yaml logs api --tail 200 >&2 || true
  echo "---- db logs ----" >&2
  docker compose -f compose.yaml -f compose.secrets.yaml logs db --tail 200 >&2 || true
  exit 1
fi

notes_503=0
for i in $(seq 1 20); do
  if curl -sS -i http://localhost:8081/notes | head -n 1 | grep -q "503"; then
    notes_503=1
    break
  fi
  sleep 1
done
if [[ "${notes_503}" -ne 1 ]]; then
  echo "ERROR: expected /notes 503 during DB outage (timed out)." >&2
  echo "---- /notes response ----" >&2
  curl -sS -i http://localhost:8081/notes || true
  echo "---- api logs ----" >&2
  docker compose -f compose.yaml -f compose.secrets.yaml logs api --tail 200 >&2 || true
  exit 1
fi

# Metrics should include some 5xx and ping failures (eventually)
for i in $(seq 1 20); do
  m="$(curl -fsS http://localhost:8081/metrics)"
  # any 5xx request line OR errors counter > 0
  if echo "${m}" | grep -q 'http_errors_total [1-9]'; then
    break
  fi
  sleep 1
done

m_after="$(curl -fsS http://localhost:8081/metrics)"
echo "${m_after}" | grep -q 'http_errors_total [1-9]' || { echo "ERROR: expected http_errors_total to be > 0 after outage" >&2; echo "${m_after}" >&2; exit 1; }

# Prove secret is not leaked in logs
if docker compose -f compose.yaml -f compose.secrets.yaml logs api 2>/dev/null | grep -Fq "${secret_value}"; then
  echo "ERROR: Secret value was found in API logs. Secrets must be redacted." >&2
  exit 1
fi

# Cleanup and enforce no leftovers
trap - EXIT
cleanup
if docker ps -a --filter "label=com.docker.compose.project=lab-15" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-15 containers still exist after cleanup." >&2
  exit 1
fi

echo "Lab 15 validation passed ✔"
