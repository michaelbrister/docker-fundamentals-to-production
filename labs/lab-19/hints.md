# Lab 19 — Hints

## The main trick
- Build once in dev (compose.dev.yaml includes `build:`)
- Capture immutable image ID via:
  `docker image inspect dzth/mini-platform-api:${RC_VERSION} --format '{{.Id}}'`
- Put that value into `.env` as `PROMOTED_IMAGE_REF=sha256:...`
- Prod-like compose uses `image: ${PROMOTED_IMAGE_REF}` and MUST NOT contain `build:`

## If prod fails to start
Most common causes:
- PROMOTED_IMAGE_REF still set to REPLACE_ME
- you copied a value without the `sha256:` prefix
- you wiped images and need to rebuild in dev again

## Why this matters
Promotion is a release control: it prevents “it worked in dev but prod is different.”
