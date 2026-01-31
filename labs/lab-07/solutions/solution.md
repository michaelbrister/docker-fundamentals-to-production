# Lab 07 — Solution (reference)

This is a reference only.

---

## Start the stack
```bash
docker compose up -d
docker compose ps
```

---

## Verify initialization
```bash
docker compose exec db psql -U app -d appdb -c "select * from notes;"
```

---

## Insert data
```bash
docker compose exec db psql -U app -d appdb -c "insert into notes (message) values ('another note');"
docker compose exec db psql -U app -d appdb -c "select count(*) from notes;"
```

---

## Restart and verify persistence
```bash
docker compose restart
docker compose exec db psql -U app -d appdb -c "select count(*) from notes;"
```

---

## Cleanup
```bash
docker compose down
```

Optional destructive cleanup:
```bash
docker compose down -v
```
