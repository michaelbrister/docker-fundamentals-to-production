#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 11 — Debugging & Break/Fix"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI not found." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable." >&2
  exit 1
fi

# Ensure no scenario containers remain (compose projects lab-11-s1..s4)
for proj in lab-11-s1 lab-11-s2 lab-11-s3 lab-11-s4; do
  if docker ps -a --filter "label=com.docker.compose.project=${proj}" --format '{{.ID}}' | grep -q .; then
    echo "ERROR: Found leftover containers for project ${proj}. Cleanup must use: docker compose down" >&2
    exit 1
  fi
done

# RUNBOOK.md required
if [[ ! -f "RUNBOOK.md" ]]; then
  echo "ERROR: RUNBOOK.md not found in labs/lab-11. Create it from RUNBOOK_TEMPLATE.md." >&2
  exit 1
fi

# Must contain all headings
for heading in "Scenario 1" "Scenario 2" "Scenario 3" "Scenario 4"; do
  if ! grep -q "${heading}" RUNBOOK.md; then
    echo "ERROR: RUNBOOK.md missing heading: ${heading}" >&2
    exit 1
  fi
done

echo "Lab 11 validation passed ✔"
