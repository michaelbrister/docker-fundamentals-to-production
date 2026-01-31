# Lab 09 — Instructor Notes
**Topic:** From source-in-container to image artifact; Compose builds

---

## Teaching intent
This lab teaches the biggest workflow shift in the course:
> In real deployments, you ship images, not source code.

Learners should feel the difference between:
- running from source (Lab 08)
- running a built image artifact (Lab 09)

---

## Reinforce
- Build vs run are separate phases
- Multi-stage reduces runtime size and attack surface
- Non-root runtime is baseline
- Code changes require rebuild + recreate

---

## Common failure modes
- Expecting live code reload without bind mounts
- Confusing compose logs with build output
- Init.sql not rerunning because volume already exists

---

## Transition
Next lab introduces dev vs prod shapes using overrides:
- dev: bind mounts + fast iterate
- prod-like: built images + no mounts
