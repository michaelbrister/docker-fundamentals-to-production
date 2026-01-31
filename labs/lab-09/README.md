# Lab 09 — Build the API Image and Run It in Compose (Alpine runtime)

## Goal
By the end of this lab you will be able to:
- Build a **deployable image artifact** for the API (not `go run`)
- Use **multi-stage builds** to separate build and runtime concerns
- Run the system with **Compose building images** (`docker compose build`)
- Understand why code changes require a **rebuild**
- Keep the database state persistent via volumes
- Tear down cleanly using `docker compose down`

> **Strict mode:** bring the stack down with `docker compose down`. Stopping containers manually is failed cleanup.

---

## Prerequisites
- Labs 01–08 completed
- Docker installed and running
- Lab 08 completed successfully (you can start the app+db system)

---

## Concepts you need (5–10 minutes)

### You deploy images, not source code
In production, you ship:
- an image (artifact)
- configuration (env vars/secrets)

You do not ship your laptop filesystem.

### Multi-stage builds
A builder image can be large (compilers, tooling). A runtime image should be small and minimal.
We will use:
- `golang:1.22-alpine` as builder
- `alpine:3.20` as runtime (shell available for learning/debugging)

### Compose can build
Compose can build your images from Dockerfiles:
- `docker compose build`
- `docker compose up --build`

---

## Files for this lab

In `labs/lab-09/`, create:

```text
lab-09/
├── README.md
├── compose.yaml
├── db/
│   └── init.sql
└── api/
    ├── Dockerfile
    ├── .dockerignore
    ├── go.mod
    └── main.go
```

You can copy `db/init.sql`, `api/go.mod`, and `api/main.go` from Lab 08.

---

## Step 1 — API Dockerfile (multi-stage, non-root)

Create `api/Dockerfile`:

```dockerfile
# ---- builder ----
FROM golang:1.22-alpine AS builder

WORKDIR /src
RUN apk add --no-cache ca-certificates

# Cache deps
COPY go.mod ./
RUN go mod download

# Copy source
COPY . ./

# Build binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/notes-api .

# ---- runtime ----
FROM alpine:3.20

RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY --from=builder /out/notes-api /app/notes-api
USER app:app

EXPOSE 8080
ENV PORT=8080

ENTRYPOINT ["/app/notes-api"]
```

Create `api/.dockerignore`:

```dockerignore
.git
.DS_Store
**/.idea
**/.vscode
**/*.log
```

---

## Step 2 — Compose topology (build the API image)

Create `compose.yaml`:

```yaml
name: lab-09

services:
  db:
    image: postgres:16-alpine
    container_name: lab09-db
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: appdb
    volumes:
      - lab09_db_data:/var/lib/postgresql/data
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 20
    ports:
      - "5434:5432"

  adminer:
    image: adminer:4
    container_name: lab09-adminer
    depends_on:
      db:
        condition: service_healthy
    environment:
      ADMINER_DEFAULT_SERVER: db
    ports:
      - "8083:8080"

  api:
    build:
      context: ./api
    image: dzth/lab09-notes-api:0.1
    container_name: lab09-api
    environment:
      PORT: "8080"
      DB_HOST: "db"
      DB_PORT: "5432"
      DB_NAME: "appdb"
      DB_USER: "app"
      DB_PASSWORD: "app"
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8080:8080"

volumes:
  lab09_db_data:
```

---

## Tasks

### Task 0 — Build images with Compose
From `labs/lab-09/`:

**bash / zsh**
```bash
docker compose build
docker compose images
```

**PowerShell**
```powershell
docker compose build
docker compose images
```

✅ Expected:
- An image named `dzth/lab09-notes-api:0.1` is built locally

---

### Task 1 — Start the system
```bash
docker compose up -d
docker compose ps
```

✅ Expected:
- `db` becomes healthy
- `api` becomes ready (via `/readyz`)
- `adminer` is available at `http://localhost:8083`

Do not proceed until `db` is healthy.

---

### Task 2 — Verify endpoints
```bash
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
curl -s http://localhost:8080/notes
```

✅ Expected:
- `/healthz` returns `ok`
- `/readyz` returns `ready`
- `/notes` returns JSON

---

### Task 3 — Prove “you deploy images, not source”
1) Edit the API response message (in `api/main.go`) for the `/` route or add a new message.
2) Re-run `/notes` or `/healthz`.

✅ Expected:
- Nothing changes yet (you did not rebuild).

Now rebuild and restart only the API:

```bash
docker compose build api
docker compose up -d --no-deps api
```

Re-test:

```bash
curl -s http://localhost:8080/healthz
```

✅ Expected:
- Now your change is reflected.

📌 Lesson:
- Source changes require an image rebuild to affect running containers.

---

### Task 4 — Restart API and verify DB persistence
Insert a note (same as Lab 08):

```bash
curl -s -X POST http://localhost:8080/notes   -H "Content-Type: application/json"   -d '{"message":"persisted through lab-09"}'
```

Restart API:

```bash
docker compose restart api
```

Query notes again:

```bash
curl -s http://localhost:8080/notes
```

✅ Expected:
- The inserted message is still present (DB volume persisted).

---

## Cleanup (STRICT)
```bash
docker compose down
docker compose ps
```

Optional destructive cleanup:
```bash
docker compose down -v
```

---

## Common failure modes (and fixes)
- **Build fails**:
  - `docker compose logs api` won't help; build errors are in the build output.
  - Re-run: `docker compose build --no-cache api` (only if you must)
- **Ports in use**:
  - Change host ports 8080/8083/5434
- **API never becomes ready**:
  - Check logs: `docker compose logs api --tail 80`
  - Check DB health: `docker compose ps`
- **Code change not reflected**:
  - You forgot to rebuild the image

---

## Validation (recommended)
From repo root:
- bash: `./scripts/validate/validate.sh lab-09`
- PowerShell: `.\scriptsalidatealidate.ps1 lab-09`

---

## Quick quiz (answer from memory)
1) Why do we deploy images instead of source code?
2) What does multi-stage buy us?
3) Why did your code change not show up until rebuild?
4) What does `docker compose down` remove vs keep?
