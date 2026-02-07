## v0.5 – Production Readiness (supply chain + rollback)

This release extends the course from “can operate” to **production-ready DevOps discipline**:

- Supply chain security (SBOMs + vulnerability policy)
- Immutable artifacts and release provenance
- Safe rollback discipline (no rebuilds under pressure)
- Incident documentation and runbooks
- Validation-first enforcement of release correctness

Labs 19–20 complete the program by introducing artifact promotion discipline and a
no-hints incident simulation, bringing the course to full production and on-call readiness.

This release represents a **stable, end-to-end learning path** from Docker fundamentals
through production-grade workflows, including debugging, security hardening, and CI
policy enforcement. All labs included in this release validate cleanly via automated
scripts on macOS, Linux, and CI runners.

Future releases may add optional extensions (Kubernetes, registries, signing/attestations), but the core 01–20 program is complete.

# Docker Fundamentals → Production

> A hands-on Docker training program: Zero → Production.

**Last updated:** 2026-02-07

This repository is a **complete, hands-on Docker training program** designed to take learners from
**little/no container experience** to **production-grade Docker proficiency**.

By the end of the program, learners can:

- Build efficient, minimal Docker images using best practices
- Run and operate containers safely in local and team environments
- Design and operate multi-service platforms using Docker Compose
- Debug containerized applications and platform failures
- Apply security hardening and supply-chain hygiene to container workflows
- Integrate Docker into CI-friendly, validation-first pipelines

The program emphasizes:

- reproducible, hands-on labs
- safe failure and recovery
- opinionated best practices
- validation-first, CI-friendly workflows
- security and production realism over toy examples

---

## Who this is for

- IT professionals transitioning into DevOps
- Developers new to containers
- DevOps / Platform engineers standardizing container workflows
- Teams adopting Docker as a local development and integration platform

---

## Course Navigation

Use this table to understand the progression of the course and how each lab builds toward production readiness.

| Lab | Title                       | Primary Focus                             | Est. Time  | Outcome                                |
| --: | --------------------------- | ----------------------------------------- | ---------- | -------------------------------------- |
|  01 | Getting Started             | Docker CLI, images vs containers          | 30–45 min  | Run and inspect containers confidently |
|  02 | Container Lifecycle         | Start/stop, logs, exec, cleanup           | 30–45 min  | Control running containers safely      |
|  03 | Images & Tags               | Registries, pulling, tagging              | 45 min     | Reason about image provenance          |
|  04 | Dockerfiles                 | Custom image builds                       | 45–60 min  | Build reproducible images              |
|  05 | Volumes & State             | Persistence fundamentals                  | 45–60 min  | Preserve and reason about state        |
|  06 | Production Images           | Multi-stage builds, non-root              | 60 min     | Produce secure runtime images          |
|  07 | Health & Readiness          | Healthchecks, dependencies                | 45–60 min  | Distinguish running vs usable          |
|  08 | App + DB System             | Multi-service Compose wiring              | 60–75 min  | Operate a real local platform          |
|  09 | Build Artifacts             | Compose builds images                     | 60–75 min  | Ship images, not source code           |
|  10 | Dev vs Prod                 | Overrides, env files                      | 60 min     | Run the same system in multiple envs   |
|  11 | Debugging & Break/Fix       | Failure diagnosis                         | 75–90 min  | Debug systems methodically             |
|  12 | Security Hardening          | Distroless, RO FS, least privilege        | 60–75 min  | Harden container runtimes              |
|  13 | CI & Policy (optional)      | Build, scan, enforce                      | 60–90 min  | Integrate Docker into CI safely        |
|  14 | Secrets & Configuration     | Runtime secrets, config vs secrets        | 60–75 min  | Inject secrets safely at runtime       |
|  15 | Observability               | Logs, metrics, health signals             | 75–90 min  | Diagnose systems with evidence         |
|  16 | Capstone: Release Candidate | Image-only prod mode + runbook + incident | 90–120 min | Ship + operate with gates              |
|  17 | Supply Chain Security       | SBOMs, vuln scanning, CI policy           | 60–90 min  | Trust and defend release artifacts     |
|  18 | Release & Rollback          | Immutable tags, rollback discipline       | 60–90 min  | Recover safely without rebuilding      |
|  19 | Promotion & Provenance      | Build once → promote many                 | 60–90 min  | Prevent rebuild drift across envs      |
|  20 | Incident Day (Final Exam)   | Diagnosis, recovery, postmortem           | 90–120 min | Operate and recover under pressure     |

---

## Validation & CI philosophy

This course is **validation-first**.

Every lab includes its own validator, and the repository provides top-level runners to
validate a single lab or the entire course:

```bash
./scripts/validate/validate.sh        # validate all labs
./scripts/validate/validate.sh lab-08 # validate a single lab
```

On Windows:

```powershell
.\scripts\validate\validate.ps1
```

Validation enforces:

- required learner artifacts (files you must create)
- correct runtime behavior (services up, endpoints responding)
- strict cleanup (no leftover containers)

### CI enforcement (Lab 13)

Starting in **Lab 13** (and expanded in Lab 14), these standards are enforced automatically via GitHub Actions:

- Dockerfile policy (no `:latest`, non-root runtime)
- Image build reproducibility
- Vulnerability scanning (fail on **CRITICAL** only)
- Smoke tests to prove the system boots correctly

If CI fails, the change is not considered complete.

## How the program is structured

### Track A — Foundations

Core Docker concepts and mental models:

- images vs containers
- registries and tags
- container lifecycle
- filesystems, volumes, and networking
- Docker Compose fundamentals

### Track B — Building real services

Hands-on image builds and service design:

- multi-stage builds (Go, Python, Node)
- non-root containers and runtime hardening
- health checks and dependency wiring
- environment configuration and secrets
- Docker Compose platforms and profiles
- secrets and runtime configuration using Docker Compose

### Track C — Operations, Security, and CI

Operating Docker like a production system:

- debugging and break/fix scenarios
- logging, metrics, and observability
- security hardening, secrets handling, and least privilege
- image linting, scanning, and CI policy enforcement
- local CI pipelines and quality gates
- supply chain security (SBOMs, vulnerability policy)
- immutable releases and rollback discipline
- incident reporting and recovery workflows
- promotion and provenance (build once → promote many)
- incident response, recovery, and postmortems

---

## Fast start

1. Verify Docker:

```bash
docker version
docker compose version
```

2. Run environment checks:

```bash
./scripts/doctor/doctor.sh
```

3. Start with Lab 01:

```text
labs/lab-01
```

---

## What “proficient” means here

A proficient learner can:

- Explain and reason about Docker images, layers, and containers
- Build minimal, secure images using multi-stage builds
- Use Docker Compose as a first-class local platform tool
- Debug container, networking, and volume issues confidently
- Apply security best practices (non-root, least privilege, scanning)
- Integrate Docker workflows into CI pipelines without surprises

---

## Reference documents

- `COURSE_GUIDE.md`
- `docs/glossary.md`
- `docs/rubrics-and-evaluation.md`
