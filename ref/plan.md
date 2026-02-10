Here is your **Staging Operations Manual**. Save this entire response in a file named `STAGING_MANUAL.md` in your repository for future reference.

---

# 📘 Staging Environment Operations Manual

**Project:** DentCharts Mobile (Frappe/ERPNext Backend)
**Platform:** Coolify / Docker

---

## 1. Initial Setup (Docker Compose)

Use this "Slim" configuration for your Staging environment in Coolify. It reduces RAM usage and fixes Nginx permission errors.

**File:** `docker-compose.yml`

```yaml
version: '3'
services:
  # API GATEWAY (Nginx) - Exposes API to the internet
  frontend:
    image: 'ghcr.io/ananthcjayan12/frappe-custom-mobclinic:latest' # Replace with specific tag (e.g., :v74) if needed
    restart: unless-stopped
    command:
      - nginx-entrypoint.sh
    environment:
      BACKEND: 'backend:8000'
      FRAPPE_SITE_NAME_HEADER: staging.dentcharts.com
      SOCKETIO: 'websocket:9000'
      UPSTREAM_REAL_IP_ADDRESS: 127.0.0.1
      CLIENT_MAX_BODY_SIZE: 50m
    volumes:
      - 'sites:/home/frappe/frappe-bench/sites'
      - type: tmpfs
        target: /run
        tmpfs: { size: 100m }
      - type: tmpfs
        target: /var/cache/nginx
        tmpfs: { size: 100m }
    depends_on:
      - backend
      - websocket
    ports:
      - '8305:8080' # Exposed Port
    user: "0:0" # Run as root to fix permissions

  # APP SERVER
  backend:
    image: 'ghcr.io/ananthcjayan12/frappe-custom-mobclinic:latest'
    deploy: { restart_policy: { condition: on-failure } }
    volumes:
      - 'sites:/home/frappe/frappe-bench/sites'
    environment:
      DB_HOST: db
      DB_PORT: '3306'
      MYSQL_ROOT_PASSWORD: admin
      MARIADB_ROOT_PASSWORD: admin
      REDIS_CACHE: 'redis-cache:6379'
      REDIS_QUEUE: 'redis-queue:6379'
      SOCKETIO_PORT: '9000'

  # AUTO-MIGRATOR (Runs once per deploy)
  configurator:
    image: 'ghcr.io/ananthcjayan12/frappe-custom-mobclinic:latest'
    deploy: { restart_policy: { condition: none } }
    entrypoint: [ "bash", "-c" ]
    command:
      - |
        echo "⏳ Waiting for services..."
        sleep 10
        if [ -d "sites/staging.dentcharts.com" ]; then
          echo "🚀 Site found! Running 'bench migrate'..."
          bench --site staging.dentcharts.com migrate
        else
          echo "⚠️ Site missing. Run 'new-site' manually."
        fi
    volumes:
      - 'sites:/home/frappe/frappe-bench/sites'
    environment:
      DB_HOST: db
      DB_PORT: '3306'
      REDIS_CACHE: 'redis-cache:6379'
      REDIS_QUEUE: 'redis-queue:6379'

  # WORKER & SCHEDULER
  worker:
    image: 'ghcr.io/ananthcjayan12/frappe-custom-mobclinic:latest'
    deploy: { restart_policy: { condition: on-failure } }
    command: [ "bench", "worker", "--queue", "short,default,long" ]
    volumes:
      - 'sites:/home/frappe/frappe-bench/sites'

  scheduler:
    image: 'ghcr.io/ananthcjayan12/frappe-custom-mobclinic:latest'
    deploy: { restart_policy: { condition: on-failure } }
    command: [ "bench", "schedule" ]
    volumes:
      - 'sites:/home/frappe/frappe-bench/sites'

  websocket:
    image: 'ghcr.io/ananthcjayan12/frappe-custom-mobclinic:latest'
    deploy: { restart_policy: { condition: on-failure } }
    command: [ "node", "/home/frappe/frappe-bench/apps/frappe/socketio.js" ]
    volumes:
      - 'sites:/home/frappe/frappe-bench/sites'

  # DATA STORE
  db:
    image: 'mariadb:10.6'
    deploy: { restart_policy: { condition: on-failure } }
    command:
      - '--character-set-server=utf8mb4'
      - '--collation-server=utf8mb4_unicode_ci'
      - '--skip-character-set-client-handshake'
      - '--skip-innodb-read-only-compressed'
    environment:
      MYSQL_ROOT_PASSWORD: admin
      MARIADB_ROOT_PASSWORD: admin
    volumes:
      - 'db-data:/var/lib/mysql'

  redis-queue:
    image: 'redis:6.2-alpine'
    volumes:
      - 'redis-queue-data:/data'
  redis-cache:
    image: 'redis:6.2-alpine'

volumes:
  db-data:
  redis-queue-data:
  sites:

```

---

## 2. Cloning Production to Staging (The Workflow)

Perform these steps whenever you want to refresh Staging with fresh Production data.

### Step A: Backup Production

*Run inside **Production Backend** Terminal (Coolify)*

```bash
# 1. Create full backup
bench --site frontend backup --with-files

# 2. Note the timestamp filename from the output (e.g., 20260205_144922)

```

### Step B: Transfer Files

*Run on **Host Server** Terminal (SSH)*

```bash
# 1. Identify Container IDs
docker ps | grep backend
# Note the ID for Production (PROD_ID) and Staging (STG_ID)

# 2. Pull from Production (Replace TIMESTAMP with actual value)
TIMESTAMP="20260205_144922"
docker cp PROD_ID:/home/frappe/frappe-bench/sites/frontend/private/backups/${TIMESTAMP}-frontend-database.sql.gz ./backup.sql.gz
docker cp PROD_ID:/home/frappe/frappe-bench/sites/frontend/private/backups/${TIMESTAMP}-frontend-files.tar ./public.tar
docker cp PROD_ID:/home/frappe/frappe-bench/sites/frontend/private/backups/${TIMESTAMP}-frontend-private-files.tar ./private.tar

# 3. Push to Staging
docker cp ./backup.sql.gz STG_ID:/home/frappe/frappe-bench/backup.sql.gz
docker cp ./public.tar STG_ID:/home/frappe/frappe-bench/public.tar
docker cp ./private.tar STG_ID:/home/frappe/frappe-bench/private.tar

```

### Step C: Restore & Sanitize

*Run inside **Staging Backend** Terminal (Coolify)*

```bash
# 1. Restore Database & Files
bench --site staging.dentcharts.com restore /home/frappe/frappe-bench/backup.sql.gz \
  --with-public-files /home/frappe/frappe-bench/public.tar \
  --with-private-files /home/frappe/frappe-bench/private.tar \
  --mariadb-root-password admin \
  --db-root-password admin

# 2. Migrate to apply latest code changes
bench --site staging.dentcharts.com migrate

# 3. SAFETY: Disable Emails & Scheduler (Prevents accidental emails to patients)
bench --site staging.dentcharts.com set-config disable_emails 1
bench --site staging.dentcharts.com set-config pause_scheduler 1

# 4. Clear Cache
bench --site staging.dentcharts.com clear-cache

```

---

## 3. Troubleshooting Commands

### If "Page Not Found" or 404

*Run inside Staging Backend Terminal*

```bash
# Set the site as default
bench use staging.dentcharts.com

# Re-generate Nginx config
bench setup add-domain 72.61.174.204 --site staging.dentcharts.com
bench setup nginx
bench restart

```

### If Redis Connection Errors

*Run inside Staging Backend Terminal*

```bash
# Point config to correct containers
bench set-config -g redis_cache "redis://redis-cache:6379"
bench set-config -g redis_queue "redis://redis-queue:6379"
bench set-config -g redis_socketio "redis://redis-queue:6379"

```

### If Site is Broken/Corrupted (The "Nuke" Option)

*Run inside Staging Backend Terminal*

```bash
# DELETE EVERYTHING and start fresh
rm -rf sites/staging.dentcharts.com

bench new-site staging.dentcharts.com --force \
  --mariadb-user-host-login-scope='%' \
  --admin-password=admin \
  --db-root-username=root \
  --db-root-password=admin \
  --db-host=db \
  --install-app erpnext \
  --install-app healthcare \
  --install-app mob_clinic \
  --install-app payments \
  --install-app print_designer \
  --install-app india_compliance

```