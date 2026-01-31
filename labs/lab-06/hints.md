# Lab 06 — Solution (reference)

This solution is a **reference only**.  
If you copied this without understanding _why_ each step exists, revisit the lab.

---

## Build the image

```bash
docker build -t dzth/lab06-go:0.1 .
```

---

## Run the container

```bash
docker run -d --name lab06-go -p 8080:8080 dzth/lab06-go:0.1
```

---

## Verify health

```bash
curl http://localhost:8080/healthz
```

Expected:

```
ok
```

---

## Confirm non-root execution

```bash
docker exec -it lab06-go sh -lc "id"
```

Expected:

- UID/GID is **not** `0`

---

## View logs

```bash
docker logs lab06-go
```

---

## Cleanup (required)

```bash
docker rm -f lab06-go
```

Optional:

```bash
docker image rm dzth/lab06-go:0.1
```

#!/usr/bin/env bash
set -euo pipefail

echo "Validating Lab 06 — Production-grade image build"

# Docker CLI

if ! command -v docker >/dev/null 2>&1; then
echo "ERROR: Docker CLI not found." >&2
exit 1
fi

# Docker daemon

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

# Lab 06 — Validation Script (PowerShell)

Write-Host "Validating Lab 06 — Production-grade image build" -ForegroundColor Cyan

# Docker CLI / daemon

try { docker version | Out-Null } catch {
Write-Error "Docker CLI not available or Docker not running."
exit 1
}

# Image must exist

try {
docker image inspect dzth/lab06-go:0.1 | Out-Null
} catch {
Write-Error "Image dzth/lab06-go:0.1 not found."
Write-Host "Hint: docker build -t dzth/lab06-go:0.1 ." -ForegroundColor Yellow
exit 1
}

# Container must NOT exist

$exists = docker ps -a --filter "name=lab06-go" --format "{{.Names}}"
if ($exists) {
Write-Error "Container 'lab06-go' still exists."
Write-Host "Hint: docker rm -f lab06-go" -ForegroundColor Yellow
exit 1
}

Write-Host "Lab 06 validation passed ✔" -ForegroundColor Green
exit 0
