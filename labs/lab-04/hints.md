# Lab 04 — Hints

## If localhost doesn’t work
- Containers are isolated
- Ports must be published

## If curl isn’t available
- Install it inside Alpine:
  - `apk add --no-cache curl`

## If containers can’t communicate
- Ensure they are on the same network
