# Release Guide (Lab 16)

## Goal
Create a versioned image tag and run the platform in “prod-like mode” (image-only).

## Versioning rules (beginner-friendly)
- Use semantic-ish versions: `MAJOR.MINOR.PATCH`
- RC tags: `0.3.0-rc.1`, `0.3.0-rc.2`
- Avoid `latest`

## Build the release image
From `labs/lab-16/`:

```bash
cp .env.example .env
source .env
docker build -f api/Dockerfile.distroless -t dzth/mini-platform-api:${RELEASE_VERSION} api
```

## Run prod-like (image-only)
```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d
docker inspect -f '{{.Config.Image}}' lab16-api
```

## Promote to a new RC
- bump `RELEASE_VERSION` in `.env`
- rebuild the image tag
- rerun prod-like stack
