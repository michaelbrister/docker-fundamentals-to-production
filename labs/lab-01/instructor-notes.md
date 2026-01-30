# lab-01 instructor notes

# Lab 01 — Instructor Notes

## Intended duration

30–45 minutes for true beginners (faster for experienced IT folks)

## Teaching objectives

Learners should walk away with:

- a correct mental model of **image vs container**
- confidence running containers in three modes:
  - short-lived (`hello-world`)
  - interactive (`alpine`)
  - long-running (`nginx -d`)
- comfort with the core “inspection loop”:
  - `docker ps` → `docker logs` → `docker inspect` → `docker exec`
- cleanup discipline

## Suggested flow

1. **5 minutes**: explain image vs container, ports, and `--rm`
2. **10 minutes**: learners run hello-world + alpine
3. **15 minutes**: run nginx, browse localhost, view logs
4. **10 minutes**: inspect and exec into container
5. **5 minutes**: cleanup + quiz

## Common learner mistakes

- Confusing `localhost` inside containers vs host
- Leaving containers running between labs
- Forgetting port mappings and assuming “it should be reachable”
- Using `docker exec` as a crutch instead of fixing Dockerfiles/Compose later (seed this idea early)

## Coaching notes

- Praise cleanup and repeatability, not “it worked once.”
- Encourage learners to narrate what each command does.
- Ask: “What changed on your machine after you ran that command?”

## Optional extension (if time permits)

- Show `docker port lab01-nginx`
- Show `docker stats` briefly (don’t deep dive yet)
- Show how to change host port: `-p 8081:80`
