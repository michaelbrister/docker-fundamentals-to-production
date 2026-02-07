# Lab 12 — Instructor Notes
**Topic:** Security hardening via runtime constraints

## Teaching intent
Learners experience the loss of convenience (no shell) and learn to rely on observability.
This lab is about reducing surface area and privilege—NOT scanning or CVEs yet.

## Enforce
- Distroless runtime for API
- Non-root execution (distroless nonroot)
- Demonstrate `docker exec sh` failure and explain why it's good
- Require HARDENING_NOTES.md

## Watch for
- Learners trying to "install curl" into containers (discourage)
- Confusing build problems with runtime problems
- Over-hardening without understanding (breaking app)

## Transition
Next lab can introduce CI enforcement:
- lint rules (no latest)
- image scanning
- policy checks for non-root and hardening settings
