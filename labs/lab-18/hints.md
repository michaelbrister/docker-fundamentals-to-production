# Lab 18 — Hints
- Rollback is a **tag swap**, not a rebuild.
- Readiness can be 200 while a route is broken.
- Evidence to collect: `/notes` status, `/version`, metrics (`http_errors_total`).
