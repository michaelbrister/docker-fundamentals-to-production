# Lab 17 — Supply Chain: SBOM + Vulnerability Policy (Syft + Grype)

## Goal
Build **supply-chain awareness** into your release workflow:

- Generate an **SBOM** (Software Bill of Materials) for a versioned image
- Scan the image for vulnerabilities
- Enforce a **risk-based policy** (fail on **CRITICAL** only)
- Document your decisions like a real team would

This lab is opinionated on purpose: **security without drama**.

---

## What you will deliver (strict)
Create these learner artifacts:

- `SBOM.md` (from template)
- `SECURITY_NOTES.md` (from template)
- `.env` (from `.env.example`)
- `secrets/db_password.txt` (from example — used only for “no secret leaks” expectations)

Validators fail if these are missing.

---

## Tools used
- **Syft** — generates SBOMs
- **Grype** — scans images for vulnerabilities

### Install (macOS)
```bash
brew install syft grype
```

### Install (Windows)
Using winget (preferred):
```powershell
winget install Anchore.Syft
winget install Anchore.Grype
```

Or Chocolatey:
```powershell
choco install syft grype -y
```

### Install (Linux)
Use the official install scripts (copy/paste from the vendors) **or** your distro package manager if available.
Validate install with:
```bash
syft version
grype version
```

---

## Lab structure
```text
lab-17/
├── README.md
├── .env.example
├── hints.md
├── instructor-notes.md
├── validate.sh
├── validate.ps1
├── SBOM_TEMPLATE.md
├── SECURITY_NOTES_TEMPLATE.md
├── SBOM.md                 # you create this
├── SECURITY_NOTES.md        # you create this
├── sbom.json                # you generate this (SBOM artifact)
├── ci/
│   └── github-actions-workflow.yml
├── api/
│   ├── main.go
│   ├── Dockerfile.distroless
│   └── go.mod
└── secrets/
    ├── db_password.txt.example
    └── db_password.txt       # you create this (DO NOT COMMIT)
```

> Note: This lab focuses on **image artifacts**, so we don’t run the full DB stack here.

---

## Step 0 — Create required local-only files

```bash
cp .env.example .env
cp secrets/db_password.txt.example secrets/db_password.txt
cp SBOM_TEMPLATE.md SBOM.md
cp SECURITY_NOTES_TEMPLATE.md SECURITY_NOTES.md
```

Edit `secrets/db_password.txt` to a unique value (>= 12 chars). Do not commit it.

---

## Step 1 — Build a versioned release image
Set a version in `.env`:

```dotenv
RELEASE_VERSION=0.4.0-rc.1
```

Build:
```bash
source .env
docker build -f api/Dockerfile.distroless -t dzth/mini-platform-api:${RELEASE_VERSION} api
```

---

## Step 2 — Generate an SBOM (required)
Generate an SBOM in **SPDX JSON** format:

```bash
source .env
syft dzth/mini-platform-api:${RELEASE_VERSION} -o spdx-json=sbom.json
```

Quick sanity checks:
```bash
test -s sbom.json
head -n 20 sbom.json
```

Now fill in `SBOM.md` (short, direct answers).

---

## Step 3 — Scan the image (policy: fail CRITICAL only)
Run a scan that fails only on CRITICAL vulnerabilities:

```bash
source .env
grype dzth/mini-platform-api:${RELEASE_VERSION} --fail-on critical
```

If it fails, don’t panic:
- capture the finding(s)
- note likely cause (base image, dependency)
- propose mitigation (upgrade base, bump dependency, reduce packages)

Now fill in `SECURITY_NOTES.md`.

---

## Step 4 — CI template (copy to repo root later)
This lab includes a GitHub Actions workflow template at:

- `ci/github-actions-workflow.yml`

When you’re ready, you’ll copy it into the repo root:

```bash
mkdir -p ../../.github/workflows
cp ci/github-actions-workflow.yml ../../.github/workflows/lab-17-supply-chain.yml
```

(We keep it as a template so labs stay self-contained.)

---

## Validation
From repo root:

```bash
./scripts/validate/validate.sh lab-17
```

On Windows:
```powershell
.\scripts\validate\validate.ps1 lab-17
```

---

## Cleanup
Nothing is left running, but you can remove the image if you want:

```bash
source .env
docker image rm dzth/mini-platform-api:${RELEASE_VERSION}
```
