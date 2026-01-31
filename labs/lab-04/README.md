# lab-04

Lab instructions go here.

# Lab 04 — Container Networking Fundamentals

## Goal

By the end of this lab you will be able to:

- Explain how Docker networking works at a basic level
- Understand the default **bridge network**
- Distinguish between **container ports** and **host ports**
- Discover how containers communicate with each other
- Inspect Docker networks and container connectivity
- Reason about why Docker Compose networking exists

> **Strict mode:** containers created in this lab must be removed before validation.

---

## Prerequisites

- Labs 01–03 completed
- Docker installed and running
- Basic comfort running containers

---

## Concepts you need (5–10 minutes)

### Containers do not share your host network

- Containers run in an isolated network namespace
- `localhost` **inside a container** is not your host
- Port publishing explicitly exposes container ports to the host

This isolation is intentional and critical for security and predictability.

---

### The default bridge network

- Docker automatically creates a bridge network
- Containers attached to the same bridge can communicate by IP
- By default, containers are **not** reachable from the host unless ports are published

Later, you’ll learn how Docker Compose improves on this model.

---

## Tasks

### Task 0 — Inspect Docker networks

List existing Docker networks.

**bash / zsh**

```bash
docker network ls
```

**PowerShell**

```powershell
docker network ls
```

✅ Expected:

- You see a network named `bridge`
- Other networks may exist (this is normal)

---

### Task 1 — Run a container without published ports

Start an nginx container **without** publishing any ports.

**bash / zsh**

```bash
docker run -d --name lab04-nginx-internal nginx:1.27
docker ps
```

**PowerShell**

```powershell
docker run -d --name lab04-nginx-internal nginx:1.27
docker ps
```

Attempt to access nginx from your host:

- `http://localhost`
- `http://localhost:80`

❌ Expected:

- The site is **not reachable**

📌 This proves:

- Containers are isolated by default
- Exposing ports is an explicit decision

---

### Task 2 — Inspect the container network settings

Inspect the container.

**bash / zsh**

```bash
docker inspect lab04-nginx-internal
```

**PowerShell**

```powershell
docker inspect lab04-nginx-internal
```

Find:

1. The container’s IP address
2. The network name it is attached to

You don’t need to memorize this — learn how to find it.

---

### Task 3 — Publish a container port

Stop and remove the previous container.

**bash / zsh**

```bash
docker rm -f lab04-nginx-internal
```

**PowerShell**

```powershell
docker rm -f lab04-nginx-internal
```

Run nginx again, this time publishing a port.

**bash / zsh**

```bash
docker run -d --name lab04-nginx -p 8080:80 nginx:1.27
docker ps
```

**PowerShell**

```powershell
docker run -d --name lab04-nginx -p 8080:80 nginx:1.27
docker ps
```

Visit:

- `http://localhost:8080`

✅ Expected:

- Nginx welcome page loads
- `docker ps` shows `0.0.0.0:8080->80/tcp`

---

### Task 4 — Container-to-container communication

Run a second container on the same bridge network.

**bash / zsh**

```bash
docker run --rm -it alpine:3.20 sh
```

**PowerShell**

```powershell
docker run --rm -it alpine:3.20 sh
```

Inside the Alpine container, attempt to reach nginx:

```sh
apk add --no-cache curl
curl http://<nginx-container-ip>
exit
```

✅ Expected:

- You receive the nginx HTML response

📌 This proves:

- Containers on the same network can communicate directly
- Host port publishing is not required for container-to-container traffic

---

### Task 5 — Inspect the bridge network

Inspect the bridge network.

**bash / zsh**

```bash
docker network inspect bridge
```

**PowerShell**

```powershell
docker network inspect bridge
```

Find:

1. Which containers are attached
2. Their IP addresses

📌 Observation:

- Networking details are handled by Docker
- Manual IP management does not scale

This sets the stage for Docker Compose.

---

## Cleanup (STRICT)

Remove all containers from this lab.

**bash / zsh**

```bash
docker rm -f lab04-nginx
docker ps -a
```

**PowerShell**

```powershell
docker rm -f lab04-nginx
docker ps -a
```

✅ Expected:

- No `lab04-*` containers remain

---

## Common failure modes (and fixes)

- **Confusing `localhost`**
  - Remember: `localhost` inside a container ≠ host
- **Port already in use**
  - Use a different host port: `-p 8081:80`
- **Curl not found**
  - Install it inside Alpine: `apk add --no-cache curl`

---

## Validation (what “done” means)

To pass Lab 04:

- You inspected Docker networks
- You ran containers with and without published ports
- You verified container-to-container communication
- All lab containers were removed

### Official validation (recommended)

From the repo root:

- **bash / zsh**

  ```bash
  ./scripts/validate/validate.sh lab-04
  ```

- **PowerShell**
  ```powershell
  .\scripts\validate\validate.ps1 lab-04
  ```

---

## Quick quiz (answer from memory)

1. Why can’t you access a container by default from the host?
2. What does `-p 8080:80` actually do?
3. Why can containers talk to each other without published ports?
4. What problem does Docker Compose networking solve?
