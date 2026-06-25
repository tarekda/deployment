## Radius Pro – Deployment (all repos)

This is the **single deployment folder** for the whole stack:

- `xnet-backend-radius-pro` (API + backups)
- `xnet-frontend-radius-pro` (UI)
- `radius-docker-image` (FreeRADIUS)
- Redis + RabbitMQ (containers)
- **MySQL on the VM host** (not containerized)

### Environment

1. Copy `env.example` → `.env` and set secrets + URLs.
2. Backend loads **all** vars from `.env` via `env_file`; compose adds service wiring (Redis/RabbitMQ hostnames, cron defaults).
3. Frontend **`VITE_API_URL`** is a **build arg** — set the public API URL before `docker compose up --build` (rebuild required after changes).

### Host MySQL setup (one-time, on the VM)

1. Install MySQL 8.0 on the VM and ensure it is running.

2. Allow Docker containers to connect (MySQL must not listen on `127.0.0.1` only):

```ini
# /etc/mysql/mysql.conf.d/mysqld.cnf (or equivalent)
[mysqld]
bind-address = 0.0.0.0
log_bin_trust_function_creators = 1
```

```bash
sudo systemctl restart mysql
```

3. Create the database and user:

```sql
CREATE DATABASE IF NOT EXISTS radius CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'radius'@'%' IDENTIFIED BY 'your_strong_password';
GRANT ALL PRIVILEGES ON radius.* TO 'radius'@'%';
FLUSH PRIVILEGES;
```

4. Load schema (from the VM, paths relative to `deployment/`):

```bash
mysql -u radius -p radius < ../radius-docker-image/mysql/init/01-schema.sql
mysql -u radius -p radius < ../radius-docker-image/mysql/init/02-radius_procedures.sql
# optional test seed (dev only):
# mysql -u radius -p radius < ../radius-docker-image/mysql/init/03-seed.sql
```

FreeRADIUS runs idempotent schema patches on every container start (`bootstrap_schema.sh`).

### Quick start (Windows / PowerShell)

From `C:\xnet-project\deployment\`:

```powershell
Copy-Item .\env.example .\.env -Force
notepad .\.env
.\up.ps1
```

**Linux VM:**

```bash
cp env.example .env
nano .env
docker compose --env-file .env up --build -d
```

Set in `.env` at minimum: `DB_PASSWORD`, `SQL_PASSWORD`, `JWT_SECRET`, `REFRESH_TOKEN_SECRET`, and `VITE_API_URL` (public backend URL if users access the UI remotely).

Stop:

```powershell
.\down.ps1
```

### Best practice for deploying to a new client

- **One `.env` per client** (never commit it). Commit `env.example` only.
- **Host MySQL**: dedicated `radius` user, strong password, firewall blocks port 3306 from the internet.
- **Rebuild frontend** after changing `VITE_API_URL`.
- **Backups**: store off-node (S3/Blob) and test restores.
- **Pin versions**: deploy tagged images/releases; avoid `latest`.
- **Observability**: enable logs/metrics stack if required (Grafana/Loki/Prometheus).
