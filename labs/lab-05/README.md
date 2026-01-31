# Lab 05 — Docker Compose Fundamentals

## Goal

By the end of this lab you will be able to:

- Explain **why Docker Compose exists**
- Understand the structure of a `compose.yaml` file
- Run multi-container applications with `docker compose`
- Use service names for container-to-container communication
- Start, stop, and tear down applications cleanly
- Reason about how Compose simplifies networking and lifecycle management

> **Strict mode:** all Compose applications must be shut down and removed using `docker compose down`.

---

## Prerequisites

- Labs 01–04 completed
- Docker installed and running
- Basic understanding of containers, volumes, and networking

---

## Concepts you need (5–10 minutes)

### Why Docker Compose exists

Running multiple containers with `docker run` quickly becomes painful:

- manual port mappings
- manual networks
- ordering issues
- cleanup complexity

Docker Compose solves this by letting you define an **application** as code.

---

### What Docker Compose is (and is not)

- **Is:** a tool for defining and running multi-container apps
- **Is not:** Kubernetes, a production scheduler, or magic

Compose is ideal for:

- local development
- CI pipelines
- single-host environments
- learning and experimentation

---

### Core Compose concepts

- **Services:** long-running containers
- **Networks:** automatically created and shared
- **Volumes:** first-class, declarative storage
- **Lifecycle:** start/stop everything together

---

## Tasks

### Task 0 — Inspect the Compose file

Open `compose.yaml` in this lab directory.

You should see:

- two services (`web`, `app`)
- one network
- one volume

You do not need to understand everything yet — focus on structure.

---

### Task 1 — Start the application with Compose

From the `lab-05` directory:

**bash / zsh**

```bash
docker compose up -d
```

**PowerShell**

```powershell
docker compose up -d
```

List running services:

```bash
docker compose ps
```

✅ Expected:

- Both `web` and `app` services are running
- STATUS shows `running` or `Up`

---

### Task 2 — Access the application from the host

Open a browser and visit:

- `http://localhost:8080`

✅ Expected:

- You see a response served through the `web` service
- Traffic is forwarded internally to the `app` service

📌 Observation:

- Only **one** port is exposed to the host
- Internal service-to-service traffic uses the Docker network

---

### Task 3 — Service name–based networking

Exec into the `web` container:

**bash / zsh**

```bash
docker compose exec web sh
```

**PowerShell**

```powershell
docker compose exec web sh
```

Inside the container, run:

```sh
apk add --no-cache curl
curl http://app:3000
exit
```

✅ Expected:

- You receive a response from the `app` service

📌 This proves:

- Service names act as DNS hostnames
- You do **not** need container IPs

---

### Task 4 — Inspect Compose-managed resources

List networks:

```bash
docker network ls
```

Inspect the Compose network (name will include `lab-05`):

```bash
docker network inspect <compose-network-name>
```

List volumes:

```bash
docker volume ls
```

📌 Observation:

- Compose creates and manages resources automatically
- Resource names are predictable and namespaced

---

### Task 5 — Stop vs remove the application

Stop services without removing resources:

```bash
docker compose stop
docker compose ps
```

Start them again:

```bash
docker compose start
```

Now tear everything down completely:

```bash
docker compose down
```

✅ Expected:

- All containers are removed
- The Compose network is removed
- Volumes remain unless `-v` is used

---

## Cleanup (STRICT)

Ensure the application is fully removed.

**bash / zsh**

```bash
docker compose ps
docker ps -a
```

**PowerShell**

```powershell
docker compose ps
docker ps -a
```

✅ Expected:

- No running Compose services
- No `lab-05` containers remain

Optional (advanced):

```bash
docker compose down -v
```

---

## Common failure modes (and fixes)

- **Port already in use**
  - Change the host port in `compose.yaml`
- **Service cannot reach another service**
  - Use service names, not `localhost`
- **Forgetting `down`**
  - Stopped containers still consume resources

---

## Validation (what “done” means)

To pass Lab 05:

- You started a multi-container app with Compose
- You accessed the app via the host
- You verified service-to-service communication
- You shut down the app cleanly with `docker compose down`

### Official validation (recommended)

From the repo root:

- **bash / zsh**

  ```bash
  ./scripts/validate/validate.sh lab-05
  ```

- **PowerShell**
  ```powershell
  .\scripts\validate\validate.ps1 lab-05
  ```

---

## Quick quiz (answer from memory)

1. What problem does Docker Compose solve?
2. Why can services reach each other by name?
3. What’s the difference between `stop` and `down`?
4. When would you use `docker compose down -v`?
