# RUNBOOK — Mini-Platform (Lab 16)

## Scope
This runbook covers the Docker Compose mini-platform:
- API (Go, distroless)
- Postgres

## How to start (prod-like)
Commands:
-

## Health checks
How to verify the system is usable:
- `/healthz` means:
- `/readyz` means:
- `/metrics` means:
- log command you use:

## Common failures and what to do
### 1) DB outage / connection refused
Evidence you will check:
- logs:
- metrics:
Actions:
-

### 2) “Ready is 503 after password change”
Evidence:
-
Action:
-

## Secrets handling
Where secrets live:
- What must never be committed:
- How to rotate the DB password safely:
-

## Recovery checklist
- [ ] Services running
- [ ] `/readyz` returns 200
- [ ] Error metrics not climbing
- [ ] No secrets in logs
