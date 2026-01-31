#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 09 — Compose builds the API image"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable." >&2
  exit 1
fi

# Image should exist (built)
if ! docker image inspect dzth/lab09-notes-api:0.1 >/dev/null 2>&1; then
  echo "ERROR: Image dzth/lab09-notes-api:0.1 not found. Run: docker compose build" >&2
  exit 1
fi

# Strict cleanup: no lab-09 containers
if docker ps -a --filter "label=com.docker.compose.project=lab-09" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-09 containers still exist. Cleanup must use: docker compose down" >&2
  exit 1
fi

echo "Lab 09 validation passed ✔"
