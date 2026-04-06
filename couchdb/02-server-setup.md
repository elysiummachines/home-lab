# Server Setup

This guide covers standing up the CouchDB container, wiring up its config, and running the one time cluster initialization. At the end of it you will have a running CouchDB instance ready for vault creation in the next step.

## Step 1: Prepare Directories

```bash
mkdir -p /compose/couchdb && chmod 750 /compose/couchdb && cd /compose/couchdb
mkdir -p data config && chmod 750 data config
```

The `config` folder holds `local.ini` (CouchDB runtime config). The `data` folder holds all CouchDB state (databases, indexes, users). Keep both together so a single folder backup captures the whole setup.

## Step 2: Create the `.env` File

```bash
cat > .env <<'EOF'
COUCHDB_USER=ADMIN_HERE
COUCHDB_PASSWORD=PASS_WORD_HERE
EOF
chmod 600 .env
```

Then generate a strong admin password. Strip `+`, `/`, and `=` to avoid URL encoding issues later when some tools try to build `http://user:pass@host` style URLs:

```bash
openssl rand -base64 24 | tr -d '/+='
```

Copy the output, then edit `.env` and replace `REPLACE_ME` with it:

```bash
nano .env
```

Example of what `.env` should look like when done:

```bash
COUCHDB_USER=Admin
COUCHDB_PASSWORD=SUHUC3ddjSkqPbgqROR4GqQUWvjhZtJa
```

The `COUCHDB_USER` can be any name you want. It does not have to be `admin`. Avoid common names since this is the superuser of your entire CouchDB instance.

## Step 3: Create `config/local.ini`

This file must exist before the first boot of the container. It enables CORS (required for Obsidian mobile to connect) and raises request size limits so LiveSync can upload large chunks.

```bash
nano config/local.ini
```

Paste the following:

```ini
[couchdb]
single_node=true
max_document_size = 50000000

[chttpd]
require_valid_user = true
max_http_request_size = 4294967296
enable_cors = true

[chttpd_auth]
require_valid_user = true
authentication_redirect = /_utils/session.html

[httpd]
WWW-Authenticate = Basic realm="couchdb"
bind_address = 0.0.0.0
enable_cors = true

[cors]
origins = app://obsidian.md,capacitor://localhost,http://localhost
credentials = true
headers = accept, authorization, content-type, origin, referer
methods = GET, PUT, POST, HEAD, DELETE
max_age = 3600
```

### What the important settings do

- ***`require_valid_user = true`*** forces every HTTP request to present valid credentials. Without this, anonymous users could read the welcome page and probe the instance.
- ***`bind_address = 0.0.0.0`*** makes CouchDB listen on all network interfaces inside the container so the Cloudflare Tunnel process can reach it.
- ***`enable_cors = true`*** combined with the `[cors]` block allows Obsidian mobile to make cross origin requests. Without this, mobile clients fail with opaque CORS errors before they can even send credentials.
- ***`app://obsidian.md`*** and ***`capacitor://localhost`*** are the origins the Obsidian mobile app sends in its requests. Missing these means mobile will not connect even if everything else is correct.
- ***`max_http_request_size`*** is raised to 4 GB so LiveSync can push large vaults in a single request without hitting HTTP 413 errors.

## Step 4: Create `docker-compose.yaml`

```bash
nano docker-compose.yaml
```

Paste the following:

```yaml
---
services:
  couchdb:
    image: couchdb:3
    container_name: couchdb
    ports:
      - "5984:5984"
    volumes:
      - /compose/couchdb/data:/opt/couchdb/data
      - /compose/couchdb/config:/opt/couchdb/etc/local.d
    environment:
      - COUCHDB_USER=${COUCHDB_USER}
      - COUCHDB_PASSWORD=${COUCHDB_PASSWORD}
    deploy:
      resources:
        limits:
          memory: 1g
          cpus: "1"
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS -u $${COUCHDB_USER}:$${COUCHDB_PASSWORD} http://localhost:5984/_up || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: 10m
        max-file: "3"
```

### Important notes about the compose file

- ***`image: couchdb:3`*** pulls the official Apache image. The `:3` tag tracks the 3.x major series and receives patch updates on container recreation.
- ***The healthcheck passes credentials with `-u`***, which is required because `local.ini` has `require_valid_user = true`. Without authentication, even the `/_up` endpoint returns `401 Unauthorized`, which `curl -f` treats as a failure and marks the container unhealthy. A plain `curl http://localhost:5984/_up` without credentials will always fail on a secured CouchDB.
- ***The `$${...}` double dollar syntax*** escapes Docker Compose variable interpolation. A single `${VAR}` would get expanded by Compose when it parses the file, baking the plaintext password into the container config. Doubling the dollar sign leaves the literal `${VAR}` in the healthcheck string so the shell inside the container expands it at runtime using the container's own environment variables.
- ***`CMD-SHELL`*** is used instead of `CMD` because the command contains shell features (variable expansion and the `|| exit 1` fallback). `CMD` would try to exec the first token directly without running a shell.
- ***`start_period: 30s`*** gives CouchDB enough time to fully initialize on first boot before the healthcheck starts counting failures. The first boot takes longer than subsequent ones because system databases are being created.
- ***`/opt/couchdb/etc/local.d`*** is where CouchDB reads user supplied config files, so mounting `config/` there is how `local.ini` gets picked up.
- ***Resource limits*** of 1 GB RAM and 1 CPU are plenty for personal use. Raise them if you end up with many users or very large vaults.

## Step 5: Start the Container

```bash
docker compose up -d
docker compose logs -f
```

Wait until you see a line like:

```
Apache CouchDB has started on http://any:5984/
```

Then press `Ctrl+C` to exit the log stream. The container keeps running in the background.

## Step 6: Expected First Boot Noise

You will see some alarming looking errors in the log. These are all normal on a fresh install and disappear after the cluster setup in the next step:

```
[warning] creating missing database: _nodes
[warning] creating missing database: _dbs
[notice] Missing system database _users
[error] Request to create N=3 DB but only 1 node(s)
```

CouchDB expects to be part of a 3 node cluster by default. Since we are running single node, it complains until we explicitly tell it to run in single node mode (next step).

## Step 7: Verify CouchDB is Responding

Pull the admin credentials out of `.env` into shell variables for convenience:

```bash
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)
```

Test the welcome endpoint:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/
```

Expected response:

```json
{"couchdb":"Welcome","version":"3.x.x","git_sha":"...","uuid":"...","features":[...],"vendor":{"name":"The Apache Software Foundation"}}
```

If you get `{"error":"unauthorized","reason":"Name or password is incorrect."}`, double check that you are using the username from `.env` and not the string `admin`. See the troubleshooting doc for more.

## Step 8: Initialize the Single Node Cluster

This is a one time operation that creates the internal system databases (`_users`, `_replicator`, `_global_changes`) and tells CouchDB to stop complaining about missing cluster nodes.

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X POST http://localhost:5984/_cluster_setup \
  -H "Content-Type: application/json" \
  -d '{"action":"enable_single_node","bind_address":"0.0.0.0","username":"'"$ADMIN_USER"'","password":"'"$ADMIN_PW"'","port":5984,"singlenode":true}'
```

Expected response:

```json
{"ok":true}
```

## Step 9: Verify System Databases

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/_all_dbs
```

Expected response:

```json
["_replicator","_users"]
```

Good. CouchDB is now fully initialized and ready to host vault databases.

## Step 10: (Optional) Access Fauxton Admin UI

CouchDB ships with a built in web admin interface called Fauxton. You can reach it on the host or over LAN at:

```
http://<host-ip>:5984/_utils/ or https://name.domain/_utils/
```

Log in with your `$ADMIN_USER` and `$ADMIN_PW`. Fauxton is useful for:

- Browsing databases and documents visually
- Inspecting `_security` documents
- Manually creating or deleting users
- Viewing replication status

You do not need Fauxton for anything in this guide since we do everything via `curl`, but it is a nice fallback when you want to poke at the database without typing commands.

## Clean Up Shell History

Your password variables are currently sitting in shell memory and in your bash history. Clear them:

```bash
unset ADMIN_USER ADMIN_PW
history -c
```

Or at minimum, selectively delete any lines containing `ADMIN_PW=` or passwords:

```bash
history | grep -E 'ADMIN_PW|COUCHDB_PASSWORD'
history -d <line-number>
```

## What You Have Now

- A running CouchDB container on port 5984
- Admin credentials stored in `.env`
- CORS configured for Obsidian mobile
- Single node cluster initialized
- System databases (`_users`, `_replicator`) created
- No vaults or regular users yet. That is the next step.

## Next Step

Proceed to **[03 - Vault and User Setup](03-vault-and-user.md)** to create your first vault database and a restricted user account that can only access it.