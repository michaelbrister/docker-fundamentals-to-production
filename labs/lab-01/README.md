# Lab 01 — Getting Started: Docker sanity checks + your first containers

## Goal

By the end of this lab you will be able to:

- Verify Docker is installed correctly (client + daemon)
- Explain **image vs container** (and why the difference matters)
- Run containers in **foreground**, **background**, and **interactive** modes
- Inspect containers (logs, ports, metadata)
- Clean up cleanly (strict habit)

> **Strict mode:** you must leave your machine in a clean state at the end (no lingering lab containers).

---

## Prerequisites

- Docker installed and running (Docker Desktop or Docker Engine)
- Internet access to pull images from Docker Hub

### Quick environment check (Doctor)

Run from the repo root:

**bash/zsh**

```bash
./scripts/doctor/doctor.sh
```

**PowerShell**

```powershell
./scripts/doctor/doctor.ps1
```

If Doctor fails, fix that first.

---

## Concepts you need (5 minutes)

### Image vs container (the mental model)

- **Image**: a read-only template (layers) — “the blueprint”
- **Container**: a running instance of an image — “the running process”

A single image can create many containers. Containers have a writable layer; images do not.

### Ports (host vs container)

When you publish ports:

- `-p 8080:80` means **host port 8080** forwards to **container port 80**

If you do not publish a port, the container may still be reachable **from other containers**, but not from your host.

---

## Tasks

### Task 0 — Confirm Docker works

#### Check versions

**bash/zsh**

```bash
docker version
docker compose version
```

**PowerShell**

```powershell
docker version
docker compose version
```

✅ Expected:

- Docker client prints version info
- Server/Engine info is present (daemon reachable)

If you see errors like “Cannot connect to the Docker daemon”, Docker Desktop is not running (or Docker Engine isn’t started).

---

### Task 1 — Pull and run `hello-world`

This verifies the full pull → create → run path.

**bash/zsh**

```bash
docker pull hello-world:latest
docker run --rm hello-world:latest
```

**PowerShell**

```powershell
docker pull hello-world:latest
docker run --rm hello-world:latest
```

✅ Expected:

- Output includes a success message explaining Docker ran correctly

📌 Notes:

- `--rm` automatically deletes the container after it exits (good hygiene)

---

### Task 2 — Run an interactive container (Alpine)

You’ll start a shell **inside** a container.

**bash/zsh**

```bash
docker run --rm -it alpine:3.20 sh
```

**PowerShell**

```powershell
docker run --rm -it alpine:3.20 sh
```

Inside the container, run:

```sh
cat /etc/os-release
echo "hello from inside the container"
ls -la
exit
```

✅ Expected:

- You can run commands
- `exit` returns you to your host shell

📌 Notes:

- `-it` = interactive + pseudo-TTY (most shell sessions need this)

---

### Task 3 — Run a web server in the background (Nginx)

Now you’ll run a long-lived container.

#### Start Nginx

**bash/zsh**

```bash
docker run -d --name lab01-nginx -p 8080:80 nginx:1.27
docker ps
```

**PowerShell**

```powershell
docker run -d --name lab01-nginx -p 8080:80 nginx:1.27
docker ps
```

✅ Expected:

- `docker ps` shows `lab01-nginx` with STATUS `Up`
- The PORTS column shows `0.0.0.0:8080->80/tcp` (or your chosen host port)

✅ Expected:

- `docker ps` shows `lab01-nginx` as running
- Visiting `http://localhost:8080` shows the Nginx welcome page

If `8080` is in use, pick another host port:

- `-p 8081:80` (then visit `http://localhost:8081`)

---

### Task 4 — View logs and inspect container details

#### Logs

**bash/zsh**

```bash
docker logs lab01-nginx --tail 50
```

**PowerShell**

```powershell
docker logs lab01-nginx --tail 50
```

✅ Expected:

- After refreshing the browser a few times, `docker logs` shows HTTP requests such as `GET /`

#### Inspect

**bash/zsh**

```bash
docker inspect lab01-nginx
```

**PowerShell**

```powershell
docker inspect lab01-nginx
```

Find and answer (write down in a notes file if you want):

1. What image is it running?
2. What host port is mapped to container port 80?
3. What is the container’s IP address on the Docker network?

---

### Task 5 — Exec into a running container

Run a command **inside** the running nginx container.

**bash/zsh**

```bash
docker exec -it lab01-nginx sh
```

**PowerShell**

```powershell
docker exec -it lab01-nginx sh
```

Inside the container:

```sh
nginx -v
ls -la /usr/share/nginx/html
exit
```

✅ Expected:

- `nginx -v` prints a version
- You can see the default web content

---

## Cleanup (STRICT)

You must stop and remove the container.

**bash/zsh**

```bash
docker stop lab01-nginx
docker rm lab01-nginx
docker ps
```

**PowerShell**

```powershell
docker stop lab01-nginx
docker rm lab01-nginx
docker ps
```

If cleanup was successful, `docker ps -a` should NOT list `lab01-nginx`.

✅ Expected:

- `lab01-nginx` does not appear in `docker ps`

Optional cleanup (images are okay to keep, but here’s how):

```bash
docker image rm nginx:1.27 hello-world:latest alpine:3.20
```

---

## Common failure modes (and fixes)

- **“Cannot connect to the Docker daemon”**
  - Start Docker Desktop, or start Docker Engine service.
- **Port already in use**
  - Use a different host port: `-p 8081:80`
- **Container name already in use**
  - Remove existing container:
    - `docker rm -f lab01-nginx`
- **On Windows: `localhost` issues**
  - Try `http://127.0.0.1:8080`

---

## Validation (what “done” means)

To pass Lab 01:

- Docker daemon reachable (`docker info` works)
- You successfully ran:
  - `hello-world`
  - an interactive Alpine shell
  - nginx mapped to a host port
- You cleaned up: no `lab01-nginx` container is left running

### Official validation (recommended)

Use the top-level validation runners from the repo root:

- **bash / zsh**

  ```bash
  ./scripts/validate/validate.sh lab-01
  ```

- **PowerShell**
  ```powershell
  .\scripts\validate\validate.ps1 lab-01
  ```

These commands dispatch to the lab-specific validators and enforce strict cleanup rules.

### Direct lab validators (advanced / optional)

You may also run the lab validators directly:

- `./labs/lab-01/validate.sh`
- `.\labs\lab-01\validate.ps1`

---

## Quick quiz (answer from memory)

1. What’s the difference between an image and a container?
2. What does `--rm` do?
3. What does `-p 8080:80` mean?
4. What does `docker exec` allow you to do?
