#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 03 — Volumes, bind mounts, and persistence"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Cannot reach Docker daemon. Is it running?" >&2
  exit 1
fi

# Strict: no stopped alpine:3.20 containers (common leftovers)
leftover=$(docker ps -a --format '{{.ID}} {{.Image}} {{.Status}}' | awk '$2=="alpine:3.20" && $3=="Exited" {print $1}' || true)
if [[ -n "${leftover}" ]]; then
  echo "ERROR: Found stopped alpine:3.20 container(s). Remove them to pass Lab 03." >&2
  echo "${leftover}" >&2
  echo "Hint: docker rm <id>  (or: docker container prune)" >&2
  exit 1
fi

# Soft: volume exists (may have been removed during optional cleanup)
if ! docker volume inspect lab03_data >/dev/null 2>&1; then
  echo "WARNING: Volume 'lab03_data' not found. OK if you removed it during optional cleanup."
fi

echo "Lab 03 validation passed ✔"
