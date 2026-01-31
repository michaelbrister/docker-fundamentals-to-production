#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 08 — App + DB system wiring"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable." >&2
  exit 1
fi

# Strict: no lab-08 containers should exist
if docker ps -a --filter "label=com.docker.compose.project=lab-08" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-08 containers still exist. Cleanup must use: docker compose down" >&2
  exit 1
fi

echo "Lab 08 validation passed ✔"
