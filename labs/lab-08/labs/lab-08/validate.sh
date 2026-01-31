#!/usr/bin/env bash
set -euo pipefail

if docker ps -a --filter "label=com.docker.compose.project=lab-08" --format '{{.ID}}' | grep -q .; then
  echo "ERROR: lab-08 containers still exist"
  exit 1
fi

echo "Lab 08 validation passed"
