# Lab 13 — CI + Policy Enforcement (GitHub Actions)

## Goal
By the end of this lab you will be able to:
- Add **GitHub Actions CI** to enforce Docker standards automatically
- Fail PRs when Dockerfiles violate policy (e.g., `latest`, root user)
- Build the **distroless** API image in CI (artifact-level enforcement)
- Scan images with **Trivy** and fail on **CRITICAL** vulnerabilities only
- Run a small **smoke test** that proves the containerized system boots and responds
- Understand CI gates: **lint → build → scan → smoke-test**

> **Strict mode:** CI is the standard. If CI fails, the change is not “done.”

---

## What gets added to the repo
This lab adds repo-level files (not just lab files):

```text
.github/workflows/ci.yml
scripts/ci/policy-check.sh
docs/ci-policy.md
SECURITY_EXCEPTIONS.md
```

And this lab folder:

```text
labs/lab-13/
├── README.md
├── hints.md
├── instructor-notes.md
├── validate.sh
├── validate.ps1
└── solutions/
    └── solution.md
```

---

## Prerequisites
- Labs 01–12 completed
- Lab 12 exists in your repo at `labs/lab-12/` (distroless Dockerfile + compose)
- Repo hosted on GitHub (Actions enabled)

---

## CI gates (what your pipeline enforces)

### Gate 1 — Policy & lint (fast)
- Dockerfile linting (Hadolint)
- Custom policy checks:
  - No `:latest`
  - Must run as non-root (or distroless `:nonroot`)

### Gate 2 — Build (artifact creation)
- Build the Lab 12 distroless API image from a clean checkout

### Gate 3 — Scan (security)
- Trivy scans the built image
- Pipeline fails on **CRITICAL only**

### Gate 4 — Smoke test (behavior)
- Bring up the Lab 12 stack (`compose.distroless.yaml`)
- Wait for `/readyz`
- Tear down cleanly

---

## Tasks

### Task 0 — Install the files
Apply the artifact from this lab into your repo root (paths are repo-relative).

### Task 1 — Push a branch and open a PR
- CI should run automatically on PR and on pushes to `main`.

### Task 2 — Trigger a policy failure (intentional)
Make one intentional policy violation and confirm CI fails, then fix it.

Pick ONE:
- Change a Dockerfile base image to `alpine:latest`
- Remove/replace `USER` in a Dockerfile (make it run as root)

✅ Expected:
- The **policy** job fails with a clear message.

Revert and push to see CI pass.

### Task 3 — Trigger a CRITICAL scan failure (optional)
This can be noisy depending on base image timing.
If you hit CRITICAL findings:
- fix by updating base images and rebuilding
- if remediation isn’t practical, document it in `SECURITY_EXCEPTIONS.md` (and discuss why this is a controlled exception)

---

## Validation (local)
From repo root:
- bash: `./scripts/validate/validate.sh lab-13`
- PowerShell: `\scripts\validate\validate.ps1 lab-13`

This checks that required CI files exist and Lab 13 support files exist.

---

## Quick quiz
1) Why is CI enforcement better than “README standards”?
2) What’s the difference between linting and scanning?
3) Why fail on CRITICAL but not HIGH in this course?
4) What does a smoke test protect you from?
