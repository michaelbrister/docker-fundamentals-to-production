# CI Policy — Docker Fundamentals → Production

This repo enforces a small set of **non-negotiable** Docker standards via CI.

## Why we enforce standards
If standards only live in README files, they will be violated under pressure.
CI enforces consistency and prevents regressions from reaching main.

## Gates

### 1) Policy & lint (fast)
- **No `:latest`** image tags in Dockerfiles
- **Non-root runtime** required:
  - Dockerfiles must specify a non-root `USER`, **or**
  - distroless base must use `:nonroot`
- Hadolint runs to catch common Dockerfile mistakes

### 2) Build
- CI builds the Lab 12 distroless API image from a clean checkout.
- This proves the repo can produce deployable artifacts.

### 3) Scan (Trivy)
- Trivy scans built images.
- CI fails only on **CRITICAL** vulnerabilities for this course.
  - HIGH findings are warnings (noise reduction for beginners).

### 4) Smoke test
- CI boots the hardened compose stack and verifies endpoints.
- CI tears it down cleanly.

## Exceptions
If a CRITICAL vulnerability has no practical fix in the timebox, document it in:
- `SECURITY_EXCEPTIONS.md`

Exceptions must explain:
- risk
- scope
- planned remediation date/trigger
