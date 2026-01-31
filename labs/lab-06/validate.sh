#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 06 — Production-grade image build"

# Check Docker CLI
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi

# Check Docker daemon
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Cannot reach Docker daemon. Is it running?" >&2
  exit 1
fi

# Image must exist
if ! docker image inspect dzth/lab06-go:0.1 >/dev/null 2>&1; then
  echo "ERROR: Image dzth/lab06-go:0.1 not found." >&2
  echo "Hint: docker build -t dzth/lab06-go:0.1 ." >&2
  exit 1
fi

# Container must NOT exist
if docker ps -a --filter "name=lab06-go" --format '{{.Names}}' | grep -q '^lab06-go$'; then
  echo "ERROR: Container 'lab06-go' still exists." >&2
  echo "Hint: docker rm -f lab06-go" >&2
  exit 1
fi

echo "Lab 06 validation passed ✔"
