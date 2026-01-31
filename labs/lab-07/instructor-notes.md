# lab-07 instructor notes

# Lab 07 — Instructor Notes

**Topic:** Compose + stateful services, volumes, persistence, readiness

---

## Teaching intent

Lab 07 is where learners confront the **hard truth of containers**:

> Containers are disposable.  
> **Data is not.**

This lab exists to permanently break the instinct that containers should be treated like long‑lived pets.  
If learners walk away believing “Compose makes databases safe,” the lab failed.

The correct takeaway is:

> **Volumes are the reason this works.**

---

## Core concepts to reinforce

### 1. Stateful vs stateless is the real divide

Make this explicit.

- Stateless services:
  - Can be destroyed and recreated freely
  - No persistent data
- Stateful services:
  - Require durable storage
  - Must survive container restarts

Databases are the canonical stateful service. This lab is the first time learners _feel_ that difference.

**Coaching prompt:**

> “What would happen if this container died in production right now?”

---

### 2. Volumes live outside container lifecycle

Learners often assume volumes are “attached” to containers.

Correct mental model:

- Containers come and go
- Volumes persist independently
- `docker compose down` removes containers, **not data**
- `docker compose down -v` is intentionally destructive

Let learners be slightly uncomfortable with `-v`. That discomfort is educational.

---

### 3. Restarting containers should be boring

The restart task is the emotional center of the lab.

If restarting containers causes fear or hesitation, that’s a sign of a bad design.
This lab proves:

- Containers are ephemeral
- Persistence is explicit and deliberate

**Coaching prompt:**

> “If this restart lost data, what would that say about the system design?”

---

### 4. Init scripts are not configuration management

The `docker-entrypoint-initdb.d` behavior is subtle but important.

Reinforce:

- Init scripts run **once**
- Only when the data directory is empty
- They are not re-applied on restart

This prevents a very common beginner mistake:

> “Why didn’t my schema change when I restarted the container?”

---

### 5. Health ≠ running

A container being “Up” does not mean it is ready.

Healthchecks introduce the idea of:

- readiness vs liveness
- waiting for dependencies safely

Do not go deep into orchestration theory yet — just anchor the distinction.

---

### 6. Service names are infrastructure contracts

When Adminer connects to `db`, reinforce that:

- This is not a convenience
- It is a stable internal contract
- IPs are irrelevant and unstable

This mental model carries directly into Kubernetes Services later.

---

## Why Adminer is included

Adminer is intentionally chosen because it:

- Provides visual confirmation for beginners
- Reinforces internal Compose networking
- Avoids teaching SQL deeply (not the goal here)

This lab is about **state**, not SQL proficiency.

---

## Common learner failure modes

### “The init script didn’t run again”

Correct response:

- That’s expected
- Init scripts only run on first initialization
- Destroying the volume is the only way to re-run them

### “Restarting feels scary”

Good. That instinct is being retrained.
Guide learners toward confidence through verification.

### “Why not just use `docker stop`?”

Reinforce lifecycle discipline:

- `docker compose down` is the correct unit of cleanup
- Partial cleanup leads to confusion and drift

---

## Things NOT to overteach in this lab

Avoid deep dives into:

- Postgres tuning or performance
- SQL schema design
- Secrets management
- Backups, replication, HA
- Kubernetes StatefulSets

Those topics belong later. This lab is about **first principles**.

---

## Expected pacing

- **Self‑paced:** 45–75 minutes
- **Instructor‑led:** ~60 minutes with discussion

If learners finish early:

- Have them compare container restarts vs volume deletion
- Ask them to predict outcomes _before_ running commands

---

## Success indicators

A learner has truly passed Lab 07 when they can explain:

- Why data survived a restart
- Why data disappears when the volume is removed
- Why Compose manages containers, not state
- Why healthchecks matter even locally

If they can do the steps but cannot explain those points, slow them down.

---

## Transition to next lab

End Lab 07 by asking:

> “Now that we can safely run a real database, how do we connect **our own application** to it?”

This cleanly sets up **Lab 08 — Application + database together**, where the course begins to resemble a real platform.
