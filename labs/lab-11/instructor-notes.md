# Lab 11 — Instructor Notes
**Topic:** Debugging systems, not containers (break/fix)

## Teaching intent
This is the “operator lab.” The main outcome is disciplined reasoning under failure.

## Enforce
- Observe before editing
- One change at a time
- Explain in words before running the next command
- Runbook writing is mandatory

## Scenarios
1) Env mismatch: auth failures in logs
2) Localhost regression: networking mental model under stress
3) Schema missing: init scripts + persistent volume behavior
4) Override leak: environment shape / compose precedence

## Success indicators
Learners can:
- classify failures (config vs networking vs state vs shape)
- explain why the fix works
- describe prevention measures
