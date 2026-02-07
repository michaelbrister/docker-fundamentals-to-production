# Lab 19 — Instructor Notes

## Intent
Teach promotion and provenance:
- build the RC once (dev)
- record immutable image ID as evidence
- run prod-like from the promoted ref without rebuilding

## Strict behaviors to enforce
Fail if:
- prod compose contains `build:`
- PROMOTED_IMAGE_REF is missing/placeholder
- dev and prod run different image IDs
- learner did not fill PROMOTION.md / PROVENANCE.md

## Discussion prompts
- How would you store provenance in CI? (artifact registry, build metadata, signed attestations)
- Why are tags alone insufficient?
- What is the operational risk of rebuilding under pressure?
