# Lab 13 — Solution (reference)

## Expected files
- `.github/workflows/ci.yml`
- `scripts/ci/policy-check.sh`
- `docs/ci-policy.md`
- `SECURITY_EXCEPTIONS.md`

## Expected behavior
- Open a PR: Actions runs automatically
- Policy violation (e.g., `alpine:latest`) fails the policy job
- Fix the Dockerfile and push: CI passes
