# lab-03

Lab instructions go here.

# Lab 03 — Volumes, Bind Mounts, and Data Persistence

## Goal

By the end of this lab you will be able to:

- Explain why container filesystems are **ephemeral**
- Understand the difference between **named volumes** and **bind mounts**
- Persist data safely outside of containers
- Reason about when to use volumes vs bind mounts
- Inspect and manage Docker volumes
- Clean up containers without losing data

> **Strict mode:** containers must be removed. Volumes may remain unless explicitly instructed.

---

## Prerequisites

- Labs 01 and 02 completed
- Docker installed and running
- Basic comfort with running containers

---

## Concepts you need (5–10 minutes)

### Containers are ephemeral by default

- Containers have a writable layer that exists **only for the life of the container**
- When a container is removed, its writable layer is destroyed
- This is a feature, not a bug

If you need data to survive container removal, you must store it **outside** the container filesystem.

---

### Docker volumes

- Docker-managed storage
- Lives outside the container lifecycle
- Ideal for databases and persistent application data
- Portable and OS-agnostic

Think of volumes as “managed disks” for containers.

---

### Bind mounts

- Map a host directory directly into a container
- Very common for local development
- Tightly coupled to host filesystem layout and permissions

Bind mounts are powerful, but easier to misuse.

---

## Tasks

### Task 0 — Observe ephemeral container storage

Run an Alpine container and create a file.

**bash / zsh**

```bash
docker run -it alpine:3.20 sh
```

**PowerShell**

```powershell
docker run -it alpine:3.20 sh
```

Inside the container:

```sh
echo "hello ephemeral world" > /tmp/demo.txt
ls /tmp
exit
```

List stopped containers:

**bash / zsh**

```bash
docker ps -a
```

**PowerShell**

```powershell
docker ps -a
```

✅ Expected:

- You see a stopped Alpine container
- STATUS shows `Exited`

---

### Task 1 — Remove the container and confirm data loss

Remove the stopped container:

**bash / zsh**

```bash
docker rm <container-id>
```

**PowerShell**

```powershell
docker rm <container-id>
```

Start a new container:

```bash
docker run --rm -it alpine:3.20 sh
ls /tmp
exit
```

✅ Expected:

- `/tmp/demo.txt` does **not** exist

📌 This reinforces:

- container filesystems are disposable
- data must live elsewhere

---

### Task 2 — Create and use a named volume

Create a Docker volume:

**bash / zsh**

```bash
docker volume create lab03_data
```

**PowerShell**

```powershell
docker volume create lab03_data
```

Inspect volumes:

```bash
docker volume ls
```

Run a container using the volume:

```bash
docker run -it -v lab03_data:/data alpine:3.20 sh
```

Inside the container:

```sh
echo "persistent data" > /data/example.txt
ls /data
exit
```

Remove the container:

```bash
docker rm <container-id>
```

Run a new container with the same volume:

```bash
docker run --rm -it -v lab03_data:/data alpine:3.20 sh
ls /data
exit
```

✅ Expected:

- `example.txt` still exists

---

### Task 3 — Inspect a Docker volume

Inspect the volume metadata:

**bash / zsh**

```bash
docker volume inspect lab03_data
```

**PowerShell**

```powershell
docker volume inspect lab03_data
```

Find:

1. The volume driver
2. The mount point on the host (for learning purposes only)

📌 Note:

- You usually **do not** interact with volume mount points directly

---

### Task 4 — Use a bind mount

Create a directory on your host:

```bash
mkdir -p lab03-bind
```

Run a container with a bind mount:

**bash / zsh**

```bash
docker run -it -v "$(pwd)/lab03-bind:/data" alpine:3.20 sh
```

**PowerShell**

```powershell
docker run -it -v "${PWD}\lab03-bind:/data" alpine:3.20 sh
```

Inside the container:

```sh
echo "hello from bind mount" > /data/host-file.txt
exit
```

On your host, list files:

```bash
ls lab03-bind
```

✅ Expected:

- `host-file.txt` exists on the host filesystem

---

### Task 5 — Compare volumes vs bind mounts

Answer (mentally or in notes):

- Which approach is better for databases?
- Which is better for local source code?
- What risks come with bind mounts?

There is no single right answer — context matters.

---

## Cleanup (STRICT)

Remove any stopped containers:

**bash / zsh**

```bash
docker ps -a
```

**PowerShell**

```powershell
docker ps -a
```

Optional cleanup (do **not** fail validation if skipped):

```bash
docker volume rm lab03_data
rm -rf lab03-bind
```

---

## Common failure modes (and fixes)

- **Permission denied with bind mounts**
  - Ensure the host directory exists
  - Check filesystem permissions
- **Volume not persisting**
  - Confirm the same volume name is reused
- **Confusing bind mounts with volumes**
  - Remember: volumes are Docker-managed, bind mounts are host-managed

---

## Validation (what “done” means)

To pass Lab 03:

- You demonstrated ephemeral container storage
- You created and reused a Docker volume
- You used a bind mount successfully
- No containers from this lab remain

### Official validation (recommended)

From the repo root:

- **bash / zsh**

  ```bash
  ./scripts/validate/validate.sh lab-03
  ```

- **PowerShell**
  ```powershell
  .\scripts\validate\validate.ps1 lab-03
  ```

---

## Quick quiz (answer from memory)

1. Why is container storage ephemeral by default?
2. When should you prefer a Docker volume over a bind mount?
3. Why are bind mounts common in development but risky in production?
4. What happens to volume data when a container is removed?
