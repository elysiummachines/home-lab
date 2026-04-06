# Monitoring and Maintenance

This guide covers ongoing care for your CouchDB instance: checking sizes, monitoring sync activity, compacting databases to reclaim disk space, backing up data, and updating the container. Most of this is optional for a small personal setup, but it gets useful as your vaults grow or as you add users.

## Setting Up Shell Variables for Convenience

Most commands in this guide need admin credentials. Set them once per shell session:

```bash
cd /compose/couchdb
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)
```

Remember to `unset` and `history -c` after you finish working.

## Checking Database Health and Size

### List all databases

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/_all_dbs
```

Returns a JSON array of database names including system databases (`_users`, `_replicator`) and your vault databases.

### Get full info for a specific database

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/sharedvault
```

Returns metadata including `doc_count`, `update_seq`, and `sizes`. Useful fields:

- ***`doc_count`*** is the number of documents currently in the database. For LiveSync, this includes file metadata documents (prefixed `f:`), content chunks (prefixed `h:`), and one config document. A typical small vault might have 30 to 100 docs. A large vault with hundreds of files could have several thousand.
- ***`sizes.file`*** is the on disk size of the database file in bytes, including history and unused space.
- ***`sizes.active`*** is the size actually used by current documents and indexes. The difference between `file` and `active` is reclaimable space.
- ***`sizes.external`*** is the uncompressed JSON size of all docs combined.

### Just the doc count

For quick checks during sync debugging:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/sharedvault | grep -oE '"doc_count":[0-9]+'
```

### On disk size from the host

The Docker volume itself:

```bash
du -sh /compose/couchdb/data
```

This is the total disk consumption of CouchDB across all databases.

## Monitoring Sync Activity

### Active replication tasks

When LiveSync is actively syncing or doing background replication, you can see it in CouchDB's task list:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/_active_tasks
```

Returns an array of currently running tasks. For LiveSync, you might see `database_compaction` or `view_compaction` entries during background compaction, or empty `[]` when idle.

### Database changes feed

To see recent activity on a specific vault:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" "http://localhost:5984/sharedvault/_changes?limit=10&descending=true"
```

Returns the most recent 10 changes (document creations, updates, deletions). Useful for confirming that a specific edit reached the server.

The output looks like:

```json
{"results":[
  {"seq":"123-...","id":"f:abc123...","changes":[{"rev":"3-..."}]},
  {"seq":"122-...","id":"h:def456...","changes":[{"rev":"1-..."}]},
  ...
],"last_seq":"123-..."}
```

The `id` fields are the encrypted document IDs LiveSync uses (`f:` for file metadata, `h:` for content chunks).

## Database Compaction

Over time, CouchDB databases accumulate old document revisions and unused space inside their files. Compaction reclaims that space.

### When to compact

- ***`sizes.file` is significantly larger than `sizes.active`.*** The difference is reclaimable. If `file` is 100 MB and `active` is 30 MB, you can recover 70 MB.
- ***You just deleted many documents.*** Deletions in CouchDB are logical, not physical. The data sticks around in the file until compaction.
- ***Routine maintenance.*** Once a month for active vaults is a reasonable cadence.

### Compact a specific database

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X POST http://localhost:5984/sharedvault/_compact \
  -H "Content-Type: application/json"
```

Expected response:

```json
{"ok":true}
```

The compaction runs in the background. Check progress with `_active_tasks`:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/_active_tasks
```

You will see an entry with `"type":"database_compaction"` while it runs.

### Compact via Fauxton

The web UI also supports compaction:

1. Go to `https://couchdb.yourdomain.com/_utils/`.
2. Click your database in the list.
3. Click **Run Maintenance** then **Compact**.

### LiveSync also has a compact command

The plugin itself has a maintenance command in its settings (Maintenance section, or via the command palette: search for "compact"). It does the same thing but from the client side.

## Backups

### What to back up

The entire CouchDB state lives in `/compose/couchdb/data`. Backing up that directory captures every database, every user, every security document, every document revision. That is everything.

You also want `/compose/couchdb/.env` and `/compose/couchdb/config/local.ini` so you can rebuild the container quickly. Plus your `docker-compose.yaml`.

### Cold backup (recommended for simplicity)

Stop the container, copy the data directory, restart:

```bash
cd /compose/couchdb
docker compose stop
tar czf /backups/couchdb-$(date +%Y%m%d).tar.gz data config .env docker-compose.yaml
docker compose start
```

Cold backups are guaranteed consistent because nothing is writing to the files during the copy. The downside is sync downtime during the backup, usually under a minute for small instances.

### Hot backup with rsync

If you want continuous backups without stopping the container:

```bash
rsync -av --delete /compose/couchdb/data /backups/couchdb-data/
```

CouchDB uses an append only file format, so a hot rsync usually produces a usable backup. There is a small risk of catching the file mid write and getting an inconsistent snapshot. For belt and suspenders, run a `_compact` first and then rsync, since compaction creates a new clean file.

### Backup via CouchDB replication (advanced)

CouchDB can replicate databases to another CouchDB instance as a backup target. This is the most "CouchDB native" approach and gives you a live secondary you can fail over to:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X POST http://localhost:5984/_replicate \
  -H "Content-Type: application/json" \
  -d '{
    "source": "http://USER:PASS@localhost:5984/sharedvault",
    "target": "http://USER:PASS@backup-host:5984/sharedvault",
    "create_target": true
  }'
```

This requires running a second CouchDB instance somewhere. Useful for serious setups, overkill for personal use.

### Restore from cold backup

```bash
cd /compose/couchdb
docker compose down
rm -rf data config
tar xzf /backups/couchdb-YYYYMMDD.tar.gz
docker compose up -d
```

CouchDB picks up exactly where the backup was taken. All vaults, users, and security docs are restored.

## Updating the Container

The `couchdb:3` tag tracks the 3.x major series and gets patch updates over time. To pull the latest:

```bash
cd /compose/couchdb
docker compose pull
docker compose up -d
```

This recreates the container using the newer image. Your data directory is preserved across recreates because it's bind mounted, so nothing is lost.

For peace of mind, run a backup before updating. Patch releases are usually safe but software being software, always have a rollback path.

### Upgrading across major versions

If a `couchdb:4` ever ships, do not just change the tag. Read the upgrade notes from the Apache CouchDB project, take a backup, test the upgrade in a separate stack first, and have a rollback plan. CouchDB's storage format can change between major versions.

## Container Logs

### Tail recent logs

```bash
docker compose logs --tail 100 couchdb
```

### Follow logs in real time

```bash
docker compose logs -f couchdb
```

Useful when debugging connection issues from clients. Each request hits the log with method, path, status code, and timing:

```
[notice] 2026-04-23T14:58:22.608390Z nonode@nohost <0.603.0> 74692b2afa localhost:5984 127.0.0.1 undefined GET /_up 401 ok 15
```

The `401` and `ok` are good signs (auth is working as expected). A `500` would indicate a server error worth investigating.

### Searching logs

```bash
docker compose logs couchdb | grep -i error
docker compose logs couchdb | grep -i unauthorized
```

## Container Health and Resource Usage

### Container status

```bash
docker compose ps
```

Should show `healthy` and `running` once the healthcheck has had a chance to pass.

### Resource consumption

```bash
docker stats couchdb
```

Live view of CPU, memory, and network usage. Useful when investigating slowness.

### From inside the container

```bash
docker exec -it couchdb bash
```

Drops you into a shell inside the container. From there you can poke at config files, run `top`, etc.

## Auditing Access

### List all users

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/_users/_all_docs
```

Returns every user document. Useful for confirming who has accounts and for cleaning up old ones.

### Inspect security on a specific vault

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/sharedvault/_security
```

Returns the `_security` document showing who has access. If `members.names` lists more users than you expect, time to investigate.

### Check who is connected

CouchDB does not maintain explicit "session" state for Basic Auth (each request is independent), so there is no list of "currently connected users". The `_active_tasks` and `_changes` endpoints are the closest you get to seeing what is happening right now.

## Routine Maintenance Schedule

For a small personal setup, this is a reasonable cadence:

| Task | Frequency |
|---|---|
| Check `docker compose ps` is healthy | Whenever you remember |
| Backup the `data` directory | Weekly to a separate disk or remote |
| `_compact` your active vaults | Monthly |
| `docker compose pull && up -d` to update | Quarterly, or when a CVE is announced |
| Audit `_users` and `_security` documents | Whenever you add or remove a person |

For larger or shared setups (multiple users, work data, anything you cannot afford to lose), tighten everything up: daily backups, weekly compaction, near real time backup replication, more aggressive monitoring.

## Common Patterns

### Quickly check if everything is healthy

```bash
docker compose ps
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/_up
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/_all_dbs
du -sh /compose/couchdb/data
```

If all four succeed and look reasonable, you are fine.

### See how big a specific user's vault has grown

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/alicevault | python3 -m json.tool
```

The `python3 -m json.tool` formats the JSON for easier reading. If you do not have python, use `jq` if installed, or just read the raw output.

### Daily backup cron job

Drop this in a script and add to cron:

```bash
#!/bin/bash
set -e
cd /compose/couchdb
TIMESTAMP=$(date +%Y%m%d-%H%M)
docker compose stop
tar czf /backups/couchdb-$TIMESTAMP.tar.gz data config .env docker-compose.yaml
docker compose start
# Keep last 30 backups
ls -1t /backups/couchdb-*.tar.gz | tail -n +31 | xargs -r rm
```

## What You Have Now

- Visibility into database sizes and sync activity
- A repeatable backup process
- Knowledge of how to compact databases when they grow
- The ability to update the container safely
- A maintenance schedule appropriate for your use case

## Next Step

For issues you run into during normal operation, see the **[troubleshooting guide](troubleshooting.md)**. It covers every problem encountered during setup and ongoing operation, with diagnostic commands and fixes for each.