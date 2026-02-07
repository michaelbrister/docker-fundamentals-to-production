# Lab 20 — Instructor Notes

## What this lab tests
- Evidence-first diagnosis
- Safe recovery without rebuilding
- Correct artifact promotion discipline (image ref)
- Clear written incident communication

## Break modes
Mode A (misconfiguration):
- DB_HOST is wrong → app cannot reach DB → /readyz stays 503 or app fails

Mode B (bad promotion):
- PROMOTED_IMAGE_REF is wrong → prod cannot start or runs wrong artifact

## Strict grading (recommended)
Pass requires:
- system healthy (`/readyz` 200, `/notes` 200)
- container uses KNOWN_GOOD_IMAGE_REF
- all 3 documents complete and specific (no vague language)
- no secrets leaked in logs
- cleanup leaves no lab-20 containers running

## Reset cadence
For instructor-led sessions:
- have learners do mode-a first
- then re-run with mode-b
