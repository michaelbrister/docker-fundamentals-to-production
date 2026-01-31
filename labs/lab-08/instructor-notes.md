# Lab 08 — Instructor Notes
**Topic:** Application + database wiring, env-based config, readiness vs running

---

## Teaching intent
Lab 08 is where learners stop thinking “one container” and start thinking “system.”

The core takeaway:
- Apps must be configured by **environment**
- Services talk by **service name**
- Readiness is **dependency truth**, not “it started”

---

## What to emphasize
### 1) Localhost is the trap
Let learners hit the failure with `DB_HOST=localhost`.
That moment is the lesson.

### 2) Readiness vs health
- `/healthz` proves the process is alive
- `/readyz` proves DB + schema are usable

### 3) Schema missing is a different class of failure
They should learn to distinguish:
- network/connectivity issues
- missing schema / initialization issues

### 4) Restarts should be boring
Restarting the API should not lose data.
If learners fear restarts, slow down and reframe the mental model.

---

## Common failure modes
- `go mod tidy` downloads fail (network)
- readiness stays not-ready because db is slow to init
- schema missing because volume already exists and init.sql didn’t run

---

## Things NOT to overteach
Avoid deep dives into:
- ORMs or migrations
- Postgres tuning
- secrets management beyond env vars
- retries/circuit breakers beyond simple readiness checks

---

## Transition
End with:
> “Now that we can run an app + DB as a system, next we will build the API into a real image and run it without go tooling.”
