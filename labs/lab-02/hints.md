# Lab 02 — Hints

## If you’re confused about images vs containers
- Remember: images are read-only blueprints
- Containers add a temporary writable layer

## If you don’t see containers
- Use:
  - `docker ps -a`
- Containers that exited still exist until removed

## If validation fails
- Remove stopped containers:
  - `docker rm <container-id>`
  - or `docker container prune`
