### 3) Rollback (tag switch only — strict)

Rollback MUST include **all three steps** below:

1. Stop the currently running (bad) release
2. Update `ACTIVE_VERSION` to the known-good tag
3. Restart the stack

If `ACTIVE_VERSION` is not changed, the rollback is **incomplete** even if the service appears healthy.

```bash
# Stop the bad release
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down

# Roll back by switching ONLY the image tag (no rebuilds)
source .env
ACTIVE_VERSION=${GOOD_VERSION} docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d

# Verify recovery
curl -i http://localhost:8083/notes
curl -s http://localhost:8083/version
```

⚠️ **Common failure mode (intentional learning moment)**  
Rolling back containers without updating `ACTIVE_VERSION` may restore functionality,
but leaves release metadata incorrect.  
Production rollbacks must restore **both behavior and version signaling**.
