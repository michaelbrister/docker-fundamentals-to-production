#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 12 — Distroless hardening"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable." >&2
  exit 1
fi

# Strict cleanup: no lab-12 containers remain
if docker ps -a --filter "label=com.docker.compose.project=lab-12" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-12 containers still exist. Cleanup must use: docker compose down" >&2
  exit 1
fi

if [[ ! -f "HARDENING_NOTES.md" ]]; then
  echo "ERROR: HARDENING_NOTES.md not found. Create it from HARDENING_TEMPLATE.md." >&2
  exit 1
fi

for heading in "What changed" "How you verified behavior without shell access" "Verification evidence" "Prevention / production notes"; do
  if ! grep -q "$heading" HARDENING_NOTES.md; then
    echo "ERROR: HARDENING_NOTES.md missing heading: $heading" >&2
    exit 1
  fi
done

echo "Lab 12 validation passed ✔"
