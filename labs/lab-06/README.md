# Lab 06 — Build a Production-Grade Go Service Image (Multi-stage + Non-root)

## Goal

By the end of this lab you will be able to:

- Build a Docker image for a real service (Go HTTP API)
- Use a multi-stage Dockerfile to produce a small runtime image
- Run the container as a non-root user
- Validate the container works via /healthz
- Understand basic build caching principles
- Clean up containers safely

> Strict mode: containers from this lab must be removed. Images may remain.

---

## Prerequisites

- Labs 01–05 completed
- Docker installed and running

---

## Tasks

Follow the instructions in order. Do not skip cleanup.

(See full course README for validation standards.)

# Lab 06 — Build a Production-Grade Go Service Image (Multi-stage + Non-root)

## Goal

By the end of this lab you will be able to:

- Build a Docker image for a real service (Go HTTP API)
- Use a **multi-stage Dockerfile** to produce a small runtime image
- Run the container as a **non-root** user
- Validate the container works via `/healthz`
- Understand basic build caching principles
- Clean up containers safely

> **Strict mode:** containers from this lab must be removed. Images may remain unless explicitly instructed.

---

## Prerequisites

- Labs 01–05 completed
- Docker installed and running
- Basic familiarity with Docker Compose (from Lab 05)

---

## Concepts you need (5–10 minutes)

### Multi-stage builds

Multi-stage builds allow you to:

- Compile artifacts in a **builder** image
- Copy only the final binary into a **runtime** image
- Dramatically reduce image size and attack surface

This pattern is extremely common in production.

---

### Non-root containers

By default, containers run as root.
In production, this is risky.

Running as a non-root user:

- Reduces blast radius
- Prevents many container escape scenarios
- Is considered a baseline security practice

---

## Tasks

### Task 0 — Create the service files

In `labs/lab-06/`, ensure the following structure exists:

```text
lab-06/
├── app/
│   ├── go.mod
│   └── main.go
├── Dockerfile
└── .dockerignore
```

#### `app/go.mod`

```go
module example.com/lab06

go 1.22
```

#### `app/main.go`

```go
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok\n"))
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		host, _ := os.Hostname()
		w.WriteHeader(http.StatusOK)
		_, _ = fmt.Fprintf(w, "hello from lab-06 (host=%s)\n", host)
	})

	addr := ":" + port
	log.Printf("listening on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}
```

---

### Task 1 — Write a multi-stage Dockerfile

Create `Dockerfile`:

```dockerfile
# ---- builder ----
FROM golang:1.22-alpine AS builder

WORKDIR /src
RUN apk add --no-cache ca-certificates

# Copy module files first for better caching
COPY app/go.mod ./
RUN go mod download

# Copy source
COPY app/ ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /out/app ./main.go

# ---- runtime ----
FROM alpine:3.20

RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY --from=builder /out/app /app/app
USER app:app

EXPOSE 8080
ENV PORT=8080

ENTRYPOINT ["/app/app"]
```

---

### Task 2 — Build the image

From `labs/lab-06/`:

**bash / zsh**

```bash
docker build -t dzth/lab06-go:0.1 .
```

**PowerShell**

```powershell
docker build -t dzth/lab06-go:0.1 .
```

✅ Expected:

- Build completes successfully
- Image `dzth/lab06-go:0.1` exists

---

### Task 3 — Run and test the container

Run the container:

**bash / zsh**

```bash
docker run -d --name lab06-go -p 8080:8080 dzth/lab06-go:0.1
```

**PowerShell**

```powershell
docker run -d --name lab06-go -p 8080:8080 dzth/lab06-go:0.1
```

Test health endpoint:

**bash / zsh**

```bash
curl http://localhost:8080/healthz
```

**PowerShell**

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/healthz | Select-Object -Expand Content
```

✅ Expected:

- Response: `ok`

---

### Task 4 — Confirm non-root execution

**bash / zsh**

```bash
docker exec -it lab06-go sh -lc "id && ps"
```

**PowerShell**

```powershell
docker exec -it lab06-go sh -lc "id && ps"
```

✅ Expected:

- UID/GID is not `0`
- Application process is running

---

### Task 5 — Review logs

**bash / zsh**

```bash
docker logs lab06-go --tail 20
```

**PowerShell**

```powershell
docker logs lab06-go --tail 20
```

---

## Cleanup (STRICT)

Remove the container:

**bash / zsh**

```bash
docker rm -f lab06-go
docker ps -a
```

**PowerShell**

```powershell
docker rm -f lab06-go
docker ps -a
```

✅ Expected:

- `lab06-go` does not appear in `docker ps -a`

Optional image cleanup:

```bash
docker image rm dzth/lab06-go:0.1
```

---

## Common failure modes (and fixes)

- **Build fails during `go mod download`**
  - Check internet access
- **Container exits immediately**
  - Inspect logs with `docker logs lab06-go`
- **Port 8080 already in use**
  - Use `-p 8081:8080`
- **Binary won’t execute**
  - Ensure `CGO_ENABLED=0` is set

---

## Validation (what “done” means)

To pass Lab 06:

- Image builds successfully
- `/healthz` returns `ok`
- Container runs as non-root
- Container is removed during cleanup

### Official validation

(Validators will be added in a later step.)

---

## Quick quiz

1. Why are multi-stage builds used?
2. What security benefit does running as non-root provide?
3. Why is `go.mod` copied before source code?
4. What does `EXPOSE` do (and not do)?
