# Lab 15 — Instructor Notes

## Teaching intent
Students can now build and run platforms. The next leap is: **operate with evidence**.
This lab teaches the difference between:
- “it’s broken”
- “it’s broken because X (and here is proof)”

## Key outcomes
Learners must demonstrate they can:
- interpret logs without exec
- read `/metrics` and explain what changed after traffic/failure
- distinguish **health** vs **readiness**
- diagnose DB outage using logs + metrics

## Enforce strictly
- logs must be structured (JSON or key=value) and include core fields
- `/metrics` must change after traffic
- DB outage must flip readiness and increase error metrics
- no secrets appear in logs (search for the actual secret)

## Common traps
- logging passwords
- logging too much (noise) or too little (no signal)
- thinking healthcheck means ready
- forgetting to clean up containers

## Timing
~75–90 minutes.
