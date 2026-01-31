#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 04 — Networking fundamentals"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Cannot reach Docker daemon. Is it running?" >&2
  exit 1
fi

for name in lab04-nginx lab04-nginx-internal; do
  if docker ps -a --filter "name=${name}" --format '{{.Names}}' | grep -q "^${name}$"; then
    echo "ERROR: Container '${name}' still exists. Remove it to pass Lab 04." >&2
    echo "Hint: docker rm -f ${name}" >&2
    exit 1
  fi
done

echo "Lab 04 validation passed ✔"
