# Contributing — Docker Fundamentals → Production

Thanks for contributing. This repo is a **training course** with strict conventions so labs stay reproducible and maintainable.

## What counts as a “good change”

A good change is:

- easy for a beginner to follow
- reproducible on macOS, Windows, and Linux
- validated by scripts (no “trust me” steps)
- consistent with existing lab structure and tone

If it breaks validation, it’s not done.

---

## Repo structure (conventions)

### Labs live here

- `labs/lab-01`, `labs/lab-02`, … (one folder per lab)
- lab folders should be **kebab-case** only (e.g., `lab-11`, not `Lab11`)

### Each lab should include

Required:

- `README.md` (learner instructions)
- `validate.sh` and `validate.ps1` (lab validator)
- `hints.md` (small hints first; do not give full answers)
- `solutions/solution.md` (full walkthrough)
- `instructor-notes.md` (teaching intent, traps, timing)
  Optional (if useful):
- `checkpoints/` (intermediate “known good” states)
- `scripts/` (lab-specific helpers)

### Top-level scripts

- `scripts/validate/validate.sh` — validate one lab or all labs (default)
- `scripts/validate/validate.ps1` — same behavior for Windows
- lab validators are **dispatched** by the top-level runners

---

## How to add a new lab (the contract)

### 1) Create the folder

Example for Lab 14:

```bash
mkdir -p labs/lab-14/solutions
touch labs/lab-14/README.md
touch labs/lab-14/hints.md
touch labs/lab-14/instructor-notes.md
touch labs/lab-14/validate.sh
touch labs/lab-14/validate.ps1
touch labs/lab-14/solutions/solution.md
```

### 2) Write the learner README (tone + strictness)

Your `README.md` must:

- state the lab goal up front
- include prerequisites
- include step-by-step commands (bash + PowerShell where appropriate)
- define “done” clearly (what to verify)
- include strict cleanup steps (`docker compose down`)

Avoid hand-wavy steps like “make sure it works.”
Always tell learners _how_ to prove it works.

### 3) Write validators (must be strict)

Validators must:

- be runnable from the lab folder
- fail with a clear error message
- check required deliverables (files the learner must create)
- check strict cleanup (no leftover containers/resources)

Conventions:

- Use `set -euo pipefail` for bash
- Exit codes:
  - `0` = pass
  - non-zero = fail

### 4) Add solutions + instructor notes

- `hints.md` should be short, progressive hints
- `solutions/solution.md` can be detailed and “show the working”
- `instructor-notes.md` should capture:
  - teaching intent
  - common traps
  - time expectations
  - what to enforce strictly

### 5) Update root README navigation table

Add the lab row:

- title
- primary focus
- estimated time
- outcome

### 6) Run validation (required)

From repo root:

```bash
./scripts/validate/validate.sh
```

On Windows:

```powershell
.\scripts\validate\validate.ps1
```

Your PR must be green.

---

## Docker & Compose conventions

### Compose is first-class

- Prefer `docker compose` (v2) syntax
- Keep compose files small and readable
- Use service names for networking (`db`, not `localhost`)
- Avoid bind mounts in prod-like compose files

### Image naming

Use stable, explicit tags:

- ✅ `dzth/lab12-notes-api:distroless-0.1`
- ❌ `myimage:latest`

### No secrets in git

- Do not commit API keys, tokens, or credentials
- Use sample placeholders and `.env.example` patterns when needed

---

## CI policy (Lab 13)

CI enforces:

- no `:latest` in Dockerfiles
- non-root runtime required
- Trivy fails on **CRITICAL** vulnerabilities only
- smoke test boots the hardened compose stack

If you need an exception, document it in `SECURITY_EXCEPTIONS.md`.

---

## Style guide (keep it consistent)

### Writing style

- short paragraphs
- lots of command blocks
- verification steps (“expected output”)
- beginner-safe wording

### Naming

- use `lab-XX` folder names
- use `validate.sh` / `validate.ps1` consistently
- use `solutions/solution.md` (not multiple solution files)

---

## Submitting changes

1. Create a branch:

```bash
git checkout -b feature/lab-14
```

2. Commit with a clear message:

```bash
git commit -am "Add Lab 14: secrets and config"
```

3. Push and open a PR.

---

## Code of conduct

Be kind. This repo is designed for beginners.
