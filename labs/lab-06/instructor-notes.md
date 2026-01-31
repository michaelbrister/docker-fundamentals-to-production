# lab-06 instructor notes

# Lab 06 — Instructor Notes

**Topic:** Multi-stage builds, non-root containers, production image shape

---

## Teaching intent

Lab 06 is the **pivot point** of the course.

This is where learners move from:

> “I can run containers”

to:

> “I can build production-ready container images.”

Do not rush this lab. The goal is not speed — it is **mental model correctness**.

---

## Core concepts to reinforce

### 1. Multi-stage builds are about _outcomes_, not syntax

Learners may fixate on Dockerfile syntax. Redirect them to _why_:

- Smaller images
- Fewer dependencies in runtime
- Reduced attack surface
- Faster pulls and deploys

**Coaching prompt:**

> “What tools exist in the runtime image after the build finishes?”

---

### 2. Builder vs runtime separation

Emphasize the separation of concerns:

- **Builder stage**
  - Compilers
  - Package managers
  - Build-time dependencies
- **Runtime stage**
  - The application binary only
  - Minimal OS surface

If a learner installs build tools in the runtime image, pause and correct it.

---

### 3. Non-root execution is a baseline, not an optimization

Learners often think non-root is “extra credit.” Correct this early.

Key points:

- Root inside a container is still root
- Many real-world container breakouts start with root processes
- Non-root should be the default mental model

**Coaching prompt:**

> “What could an attacker do if this process ran as root?”

---

### 4. Build cache ordering matters (introduce gently)

This is the _first_ time learners encounter build cache behavior.

Focus only on:

- Copying `go.mod` before source
- Why that speeds up rebuilds

Do **not** dive into advanced caching yet — that comes later.

---

## Common learner failure modes

### Build fails at `go mod download`

- Usually network-related
- Learners may think their code is broken — reassure them

### Container exits immediately

- Learners often forget to check logs
- Reinforce `docker logs` as a primary diagnostic tool

### Confusion around `EXPOSE`

- Learners assume it publishes ports
- Clarify:
  - `EXPOSE` is documentation / metadata
  - `-p` actually publishes ports

---

## Things NOT to overteach in this lab

Avoid deep dives into:

- Distroless images
- Scratch images
- Advanced security hardening
- Kubernetes build patterns

Those topics are intentionally deferred to later labs.

---

## Expected time & pacing

- **Self-paced:** 45–75 minutes
- **Instructor-led:** ~60 minutes with discussion

If learners finish very quickly, ask them to:

- Compare image sizes (`docker images`)
- Remove the builder stage and observe the impact
- Reflect on what changed

---

## Success indicators

A learner has truly “passed” Lab 06 when they can:

- Explain _why_ the image is smaller
- Explain _why_ non-root matters
- Debug a failed container using logs
- Predict what would happen if the builder stage were removed

---

## Transition to next lab

End Lab 06 by framing what’s next:

> “Now that you can build a real image, the next question is:
> how do we run **multiple services with state**?”

This sets up **Lab 07 — Compose + stateful services** cleanly.
