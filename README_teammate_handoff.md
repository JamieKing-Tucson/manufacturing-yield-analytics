# Manufacturing Yield Analytics Platform — Teammate Handoff

This repo contains the **infrastructure-as-code** for the manufacturing yield analytics stack (Docker Compose).
A separate **data snapshot** zip provides an identical starting dataset (MinIO + Iceberg catalog + Grafana state).

## What you will receive
1) **GitHub repo link** (this code)
2) **`data_snapshot_bundle.zip`** (data + dashboards snapshot)

> Do **not** commit the snapshot zip or tarballs to Git.

---

## Prerequisites
- Windows 10/11
- Docker Desktop installed and running
- Git installed

---

## 1) Clone the repo
```bat
git clone https://github.com/JamieKing-Tucson/manufacturing-yield-analytics.git
cd manufacturing-yield-analytics\site-a
```

---

## 2) Create your local `.env`
If the repo includes `.env.example`:

```bat
copy .env.example .env
```

Edit `.env` if needed for your machine.

---

## 3) Create Docker volumes (first-time only)
Bring the stack up once to create the named volumes, then stop it:

```bat
docker compose -f merged.yml -f docker-compose.phase3.yml -f docker-compose.connect.yml up -d
docker compose -f merged.yml -f docker-compose.phase3.yml -f docker-compose.connect.yml down
```

---

## 4) Restore the data snapshot

### 4.1 Place files
- Put `data_snapshot_bundle.zip` in: `manufacturing-yield-analytics\site-a\`
- Extract it so you have:
  - `site-a\backups\minio-data.tar.gz`
  - `site-a\backups\iceberg-catalog.tar.gz`
  - `site-a\backups\grafana-data.tar.gz`

### 4.2 Run the restore script
From `manufacturing-yield-analytics\site-a\`:

```bat
restore_snapshot.cmd
```

This restores into the default volumes:
- `site-a_minio-data`
- `site-a_iceberg_rest_db`
- `site-a_grafana-data`

If your compose project prefix is different, you can pass a prefix, e.g.:
```bat
restore_snapshot.cmd myprefix
```

---

## 5) Start the platform
```bat
docker compose -f merged.yml -f docker-compose.phase3.yml -f docker-compose.connect.yml up -d
```

---

## 6) Verify
- Grafana: http://localhost:3000
- Expect dashboards and data to already be populated.

Quick container check:
```bat
docker ps
```

---

## Common issues

### “Volume not found”
Run the Step 3 “up then down” once to create volumes, then re-run `restore_snapshot.cmd`.

### “No data in dashboards”
Confirm the snapshot tarballs exist in `backups\` and were restored to the correct volume prefix.

### Port conflicts
If ports like `3000` are already used, stop the conflicting service or adjust compose ports.

---

## Safety notes (important)
- Do **not** run `docker system prune` or delete volumes unless you intend to wipe data.
- Do **not** commit `.env` files or snapshot artifacts to Git.
