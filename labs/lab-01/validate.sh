

#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 01 — Docker fundamentals"

# ----------------------------
# Check: Docker CLI available
# ----------------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI is not available. Install Docker and try again." >&2
  exit 1
fi

# ----------------------------
# Check: Docker daemon reachable
# ----------------------------
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Cannot reach Docker daemon. Is Docker Desktop / Docker Engine running?" >&2
  exit 1
fi

# ----------------------------
# Check: lab01-nginx container is NOT present
# ----------------------------
if docker ps -a --filter "name=lab01-nginx" --format '{{.Names}}' | grep -q '^lab01-nginx$'; then
  echo "ERROR: Container 'lab01-nginx' still exists. You must stop and remove it to pass Lab 01." >&2
  echo "Hint: docker rm -f lab01-nginx" >&2
  exit 1
fi

# ----------------------------
# Optional: Warn if expected images are missing
# ----------------------------
for img in hello-world alpine nginx; do
  if ! docker images --format '{{.Repository}}' | grep -q "^${img}$"; then
    echo "WARNING: Image '${img}' not found locally. This is OK if you removed images during cleanup."
  fi
done

echo "Lab 01 validation passed ✔"