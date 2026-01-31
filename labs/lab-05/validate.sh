#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 05 — Docker Compose fundamentals"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Cannot reach Docker daemon. Is it running?" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker compose not available. Install Docker Desktop or Compose plugin." >&2
  exit 1
fi

# Strict: no compose containers remain for project "lab-05"
if docker ps -a --filter "label=com.docker.compose.project=lab-05" --format '{{.ID}}' | grep -q '.'; then
  echo "ERROR: Compose project 'lab-05' still has containers. Run: docker compose down" >&2
  exit 1
fi

echo "Lab 05 validation passed ✔"
