#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 14 — Secrets & Configuration"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable." >&2
  exit 1
fi

# Required files
required=(
  "README.md"
  ".env.example"
  "compose.yaml"
  "compose.secrets.yaml"
  "SECRETS_NOTES_TEMPLATE.md"
  "hints.md"
  "instructor-notes.md"
  "solutions/solution.md"
  "api/Dockerfile.distroless"
  "api/main.go"
  "db/init.sql"
  "secrets/db_password.txt.example"
)

for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: Missing required file: $f" >&2
    exit 1
  fi
done

# Learner deliverable
if [[ ! -f "SECRETS_NOTES.md" ]]; then
  echo "ERROR: SECRETS_NOTES.md not found. Create it from SECRETS_NOTES_TEMPLATE.md." >&2
  exit 1
fi

# Local secret should exist (runtime requirement)
if [[ ! -f "secrets/db_password.txt" ]]; then
  echo "ERROR: secrets/db_password.txt not found. Create it from secrets/db_password.txt.example (DO NOT COMMIT)." >&2
  exit 1
fi

# Git hygiene checks (best-effort; skip if not a git repo)
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git ls-files --error-unmatch ".env" >/dev/null 2>&1; then
    echo "ERROR: .env is tracked by git. Remove it from git tracking and keep it local-only." >&2
    exit 1
  fi
  if git ls-files --error-unmatch "secrets/db_password.txt" >/dev/null 2>&1; then
    echo "ERROR: secrets/db_password.txt is tracked by git. Do NOT commit secret files." >&2
    exit 1
  fi
fi

# Dockerfile policy: no secret defaults baked in
if grep -Eqi 'DB_PASSWORD|API_KEY|SECRET' "api/Dockerfile.distroless"; then
  echo "ERROR: Dockerfile contains secret-related tokens (DB_PASSWORD/API_KEY/SECRET). Do not bake secrets into images." >&2
  exit 1
fi

# Strict cleanup: no lab-14 containers remain before we start
if docker ps -a --filter "label=com.docker.compose.project=lab-14" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-14 containers already exist. Cleanup first with: docker compose -f compose.yaml -f compose.secrets.yaml down" >&2
  exit 1
fi

# Smoke run (hardened + secrets overlay)
echo "Bringing up lab-14 stack (with secrets overlay) for smoke validation..."
docker compose -f compose.yaml -f compose.secrets.yaml up -d --build

cleanup() {
  docker compose -f compose.yaml -f compose.secrets.yaml down >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Waiting for readiness..."
for i in $(seq 1 40); do
  if curl -fsS http://localhost:8080/readyz >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

curl -fsS http://localhost:8080/healthz >/dev/null
curl -fsS http://localhost:8080/readyz >/dev/null
curl -fsS http://localhost:8080/notes >/dev/null

# Prove secret is not leaked in logs
secret_value="$(tr -d '\r\n' < secrets/db_password.txt)"
if [[ -n "${secret_value}" ]]; then
  if docker compose -f compose.yaml -f compose.secrets.yaml logs api 2>/dev/null | grep -Fq "${secret_value}"; then
    echo "ERROR: Secret value was found in API logs. Secrets must be redacted." >&2
    exit 1
  fi
fi

# Enforce cleanup: after trap runs, no containers should remain (trap will down)
trap - EXIT
cleanup
if docker ps -a --filter "label=com.docker.compose.project=lab-14" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-14 containers still exist after cleanup. Use docker compose down." >&2
  exit 1
fi

echo "Lab 14 validation passed ✔"
