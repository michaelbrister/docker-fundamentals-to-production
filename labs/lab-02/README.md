# lab-02

Lab instructions go here.

# Lab 02 — Images, Layers, and the Container Lifecycle

## Goal

By the end of this lab you will be able to:

- Explain what a Docker image **is** (and is not)
- Describe how images are built from **layers**
- Understand why images are **immutable**
- Reason about the container lifecycle (create, start, stop, remove)
- Inspect images and containers using Docker tooling
- Clean up images and containers safely

> **Strict mode:** containers from this lab must be removed. Images may remain unless explicitly instructed otherwise.

---

## Prerequisites

- Lab 01 completed
- Docker installed and running
- Internet access to pull images from Docker Hub

---

## Concepts you need (5–10 minutes)

### Images are immutable

- Docker images are **read-only**
- You cannot “change” an image once built
- Running a container adds a **temporary writable layer** on top of the image

When a container is removed, its writable layer is destroyed.

### Layers and caching

- Images are composed of **layers**
- Each instruction in a Dockerfile creates a new layer
- Docker reuses cached layers when possible

This is why build order matters later when you write Dockerfiles.

### Image vs container (revisited)

- **Image**: blueprint (static)
- **Container**: runtime instance (dynamic, disposable)

---

## Tasks

### Task 0 — Inspect local images

List images on your system.

**bash / zsh**

```bash
docker images
```

**PowerShell**

```powershell
docker images
```

✅ Expected:

- You see images pulled in Lab 01 (e.g. `nginx`, `alpine`, `hello-world`)
- Each image has a REPOSITORY, TAG, IMAGE ID, and SIZE

---

### Task 1 — Pull a specific image version

Pull a pinned version of Alpine Linux.

**bash / zsh**

```bash
docker pull alpine:3.20
```

**PowerShell**

```powershell
docker pull alpine:3.20
```

✅ Expected:

- Docker reports the image is pulled (or already up to date)
- The image now appears in `docker images`

📌 Notes:

- Pinning versions avoids surprises
- You will stop using `:latest` later in the course

---

### Task 2 — Inspect image metadata

Inspect the Alpine image.

**bash / zsh**

```bash
docker inspect alpine:3.20
```

**PowerShell**

```powershell
docker inspect alpine:3.20
```

Find and answer:

1. What architecture is the image built for?
2. What is the default command (`Cmd`)?
3. Is there an exposed port?

You do **not** need to memorize this output — learn how to _find_ information.

---

### Task 3 — View image layers

Examine how the image is built.

**bash / zsh**

```bash
docker history alpine:3.20
```

**PowerShell**

```powershell
docker history alpine:3.20
```

✅ Expected:

- You see one or more layers
- Each layer has a size and command

📌 Notes:

- Some base images are very small (Alpine is a good example)
- Large images later will have many layers

---

### Task 4 — Create, stop, and remove a container

Create a container **without** removing it automatically.

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
echo "temporary data" > /tmp/example.txt
ls /tmp
exit
```

Now list all containers (including stopped ones):

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

### Task 5 — Remove the container and observe data loss

Remove the stopped container.

**bash / zsh**

```bash
docker rm <container-id>
```

**PowerShell**

```powershell
docker rm <container-id>
```

Now run a **new** Alpine container:

```bash
docker run --rm -it alpine:3.20 sh
ls /tmp
exit
```

✅ Expected:

- `/tmp/example.txt` is **gone**

📌 This proves:

- Container data is ephemeral
- Images are unchanged
- Containers are disposable

---

## Cleanup (STRICT)

Ensure no containers from this lab remain.

**bash / zsh**

```bash
docker ps -a
```

**PowerShell**

```powershell
docker ps -a
```

✅ Expected:

- No stopped Alpine containers remain from this lab

Optional (do **not** fail validation if skipped):

```bash
docker image rm alpine:3.20
```

---

## Common failure modes (and fixes)

- **Container ID not found**
  - Run `docker ps -a` and copy the correct ID
- **Confusing image vs container**
  - Remember: deleting a container does **not** delete the image
- **Forgetting to remove containers**
  - Validation will fail if containers remain

---

## Validation (what “done” means)

To pass Lab 02:

- You inspected images and layers
- You created and removed at least one container
- No containers from this lab remain (`docker ps -a` is clean)

### Official validation (recommended)

From the repo root:

- **bash / zsh**

  ```bash
  ./scripts/validate/validate.sh lab-02
  ```

- **PowerShell**
  ```powershell
  .\scripts\validate\validate.ps1 lab-02
  ```

---

## Quick quiz (answer from memory)

1. Why are Docker images considered immutable?
2. What happens to a container’s writable layer when the container is removed?
3. Why is pinning image versions important?
4. What does `docker history` show you?
