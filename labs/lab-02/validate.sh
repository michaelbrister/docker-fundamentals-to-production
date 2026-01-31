#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 02 — Images, layers, and lifecycle"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Cannot reach Docker daemon. Is it running?" >&2
  exit 1
fi

# Strict: no stopped alpine:3.20 containers (common leftovers for this lab)
leftover=$(docker ps -a --format '{{.ID}} {{.Image}} {{.Status}}' | awk '$2=="alpine:3.20" && $3=="Exited" {print $1}' || true)
if [[ -n "${leftover}" ]]; then
  echo "ERROR: Found stopped alpine:3.20 container(s) that look like Lab 02 leftovers:" >&2
  echo "${leftover}" >&2
  echo "Hint: docker rm <id>  (or: docker container prune)" >&2
  exit 1
fi

echo "Lab 02 validation passed ✔"
