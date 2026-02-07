# Lab 13 — Instructor Notes
**Topic:** CI as enforcement: standards become non-negotiable

## Teaching intent
Learners must understand:
- standards without enforcement are not standards
- CI gates protect the team from regressions
- policy checks are fast feedback
- scans and smoke tests are “artifact and behavior” proof

## Enforce
- One intentional CI failure + fix (required)
- Explain each gate’s purpose in plain English

## Watch for
- learners “fixing” CI by weakening rules
- confusion between lint vs scan vs test
- assuming scan output is deterministic forever (it changes with time)

## Transition
Next: optional advanced track
- SBOM
- signing (cosign)
- digest pinning
- provenance/SLSA concepts
