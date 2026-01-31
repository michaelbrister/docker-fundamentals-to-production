#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 07 — Compose + stateful services"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable." >&2
  exit 1
fi

# No lab-07 containers should exist
if docker ps -a --filter "label=com.docker.compose.project=lab-07" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-07 containers still exist." >&2
  echo "Hint: docker compose down" >&2
  exit 1
fi

echo "Lab 07 validation passed ✔"
