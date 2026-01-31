# Lab 07 — Compose + Stateful Services (Postgres) with Volumes and Healthchecks

## Goal

By the end of this lab you will be able to:

- Run a **stateful** service (Postgres) with Docker Compose
- Persist database data using a **named volume**
- Use **healthchecks** and safe startup sequencing
- Execute one-off operational commands (`psql`) inside the Compose network
- Prove persistence by restarting containers without losing data
- Tear down cleanly (and optionally destroy data)

> **Strict mode:** the Compose stack must be shut down using `docker compose down`.  
> Volumes may remain unless you explicitly remove them with `-v`.

---

## Prerequisites

- Labs 01–06 completed
- Docker installed and running
- Comfort running Compose (`docker compose up/down`)
- (Optional) Lab 06 image built: `dzth/lab06-go:0.1`
  - If you don’t have it, you can still complete this lab with Postgres + tools.

---

## Concepts you need (5–10 minutes)

### Stateful vs stateless

- **Stateless** containers can be destroyed and recreated freely (easy)
- **Stateful** services need persistent storage (harder)

Databases are stateful. If you don’t persist data correctly, you will lose it.

---

### Compose volumes

Compose makes volumes declarative:

- define a named volume once
- attach it to a service
- containers can come and go; data persists

---

### Healthchecks and readiness

A container being “running” doesn’t mean it’s **ready**.

Healthchecks let Compose (and humans) reason about service readiness more safely.

---

## Files for this lab

In `labs/lab-07/`, create these files:

```text
lab-07/
├── README.md
├── compose.yaml
└── db/
    └── init.sql
```

### `db/init.sql`

```sql
CREATE TABLE IF NOT EXISTS notes (
  id SERIAL PRIMARY KEY,
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO notes (message) VALUES ('hello from lab-07');
```

### `compose.yaml`

```yaml
name: lab-07

services:
  db:
    image: postgres:16-alpine
    container_name: lab07-db
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: appdb
    volumes:
      - lab07_db_data:/var/lib/postgresql/data
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 20
    ports:
      - "5432:5432"

  adminer:
    image: adminer:4
    container_name: lab07-adminer
    depends_on:
      db:
        condition: service_healthy
    environment:
      ADMINER_DEFAULT_SERVER: db
    ports:
      - "8081:8080"

volumes:
  lab07_db_data:
```

📌 Notes:

- We mount `init.sql` into `docker-entrypoint-initdb.d/` so Postgres runs it **once** on first init.
- The named volume `lab07_db_data` is the persistence mechanism.
- Adminer is a lightweight UI so learners can “see” the database working.

---

## Tasks

### Task 0 — Inspect the Compose file

Before running anything:

- Identify which service is stateful (db)
- Identify the named volume
- Identify ports exposed to the host

---

### Task 1 — Start the stack

From `labs/lab-07/`:

**bash / zsh**

```bash
docker compose up -d
docker compose ps
```

**PowerShell**

```powershell
docker compose up -d
docker compose ps
```

✅ Expected:

- `db` becomes **healthy**
- `adminer` starts after db is healthy
- `docker compose ps` shows both services

Do not proceed until the `db` service reports **healthy**.

If port `5432` or `8081` is already in use, change the host side of the mapping (left side).

---

### Task 2 — Prove the database was initialized

Use a one-off container inside the Compose network to query Postgres.

**bash / zsh**

```bash
docker compose exec db psql -U app -d appdb -c "select * from notes;"
```

**PowerShell**

```powershell
docker compose exec db psql -U app -d appdb -c "select * from notes;"
```

✅ Expected:

- You see at least one row with message `hello from lab-07`

---

### Task 3 — Add a row, then re-check

Insert more data:

**bash / zsh**

```bash
docker compose exec db psql -U app -d appdb -c "insert into notes (message) values ('another note');"
docker compose exec db psql -U app -d appdb -c "select count(*) from notes;"
```

**PowerShell**

```powershell
docker compose exec db psql -U app -d appdb -c "insert into notes (message) values ('another note');"
docker compose exec db psql -U app -d appdb -c "select count(*) from notes;"
```

✅ Expected:

- The count increases

---

### Task 4 — Restart containers and verify persistence

Restart the stack:

**bash / zsh**

```bash
docker compose restart
docker compose ps
```

**PowerShell**

```powershell
docker compose restart
docker compose ps
```

Now query again:

```bash
docker compose exec db psql -U app -d appdb -c "select count(*) from notes;"
```

✅ Expected:

- The count is the same as before restart (data persisted)

📌 This proves:

- containers are ephemeral
- **volumes** make data persistent

---

### Task 5 — Validate networking via service name

From inside Adminer’s container, verify it can resolve the database hostname `db`.

**bash / zsh**

```bash
docker compose exec adminer sh -lc "getent hosts db || nslookup db || ping -c 1 db"
```

**PowerShell**

```powershell
docker compose exec adminer sh -lc "getent hosts db || nslookup db || ping -c 1 db"
```

✅ Expected:

- You see DNS resolution succeed (one of those commands returns a result)

📌 This is why Compose networking is so useful:

- service names are stable
- you don’t manage IPs manually

---

### Task 6 — Use the Adminer UI (optional but recommended)

Visit:

- `http://localhost:8081`

Login:

- System: `PostgreSQL`
- Server: `db`
- Username: `app`
- Password: `app`
- Database: `appdb`

✅ Expected:

- You can browse the `notes` table and see your rows

---

## Cleanup (STRICT)

Bring the stack down:

Using `docker stop` or leaving containers running is considered a failed cleanup.

**bash / zsh**

```bash
docker compose down
docker compose ps
```

**PowerShell**

```powershell
docker compose down
docker compose ps
```

✅ Expected:

- No running services

### Optional: destroy the data (dangerous on purpose)

If you want a clean slate (this deletes the database volume):

```bash
docker compose down -v
```

---

## Common failure modes (and fixes)

- **Ports already in use**
  - Change host ports in `compose.yaml` (left side of `host:container`)
- **db never becomes healthy**
  - Check logs:
    - `docker compose logs db --tail 50`
  - Wait a bit; first init can take longer
- **Init script runs “only once”**
  - That’s correct: `docker-entrypoint-initdb.d` runs only when the data dir is empty
  - To force re-init: `docker compose down -v` (destructive)
- **Can’t connect from Adminer**
  - Ensure server is `db` (service name), not `localhost`

---

## Validation (what “done” means)

To pass Lab 07:

- You started Postgres with Compose
- You confirmed table creation and inserted data
- You restarted containers and proved data persisted via the volume
- You tore down with `docker compose down`
- No `lab-07` containers are left running or stopped

### Official validation (recommended)

(Validators will be added after Lab 07 is locked in.)

From repo root:

- `./scripts/validate/validate.sh lab-07`
- `.\scripts\validate\validate.ps1 lab-07`

---

## Quick quiz (answer from memory)

1. Why do databases require volumes in Docker?
2. What does `docker compose down` remove, and what does it intentionally keep?
3. Why does the init script run only once?
4. Why are service names better than container IPs?
