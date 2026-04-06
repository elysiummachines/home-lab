# Troubleshooting

A reference for problems encountered during setup and ongoing operation. Use `Ctrl+F` to find your symptom. Each entry follows the same format: symptom, cause, fix.

If your issue is not in here, the diagnostic checklist at the bottom walks through general first response steps that catch most problems.

## Quick Reference Index

- [Cannot authenticate to CouchDB](#cannot-authenticate-to-couchdb)
- [Container starts but shows unhealthy in Portainer](#container-starts-but-shows-unhealthy-in-portainer)
- [First boot logs show database errors](#first-boot-logs-show-database-errors)
- [Sync indicator moves but files do not appear cross device](#sync-indicator-moves-but-files-do-not-appear-cross-device)
- [DevTools console shows 404 on _local](#devtools-console-shows-404-on-_local)
- [Console shows rule violation warnings](#console-shows-rule-violation-warnings)
- [Fetch Remote Configuration Failed](#fetch-remote-configuration-failed)
- [Edit on one device does not propagate](#edit-on-one-device-does-not-propagate)
- [Cloudflare Tunnel returns 502 Bad Gateway](#cloudflare-tunnel-returns-502-bad-gateway)
- [Browser prompts Cloudflare Access login instead of CouchDB](#browser-prompts-cloudflare-access-login-instead-of-couchdb)
- [Encryption passphrase lost](#encryption-passphrase-lost)
- [Container port conflicts](#container-port-conflicts)
- [CouchDB only listens on 127.0.0.1](#couchdb-only-listens-on-127001)
- [Mobile fails to connect with CORS errors](#mobile-fails-to-connect-with-cors-errors)
- [Cannot delete a database file_exists error](#cannot-delete-a-database-file_exists-error)
- [LiveSync wizard hangs on test connection](#livesync-wizard-hangs-on-test-connection)
- [Two devices have different vault content](#two-devices-have-different-vault-content)

---

## Cannot authenticate to CouchDB

***Symptom:*** Running `curl -u admin:somepassword http://localhost:5984/` returns:

```json
{"error":"unauthorized","reason":"Name or password is incorrect."}
```

***Cause:*** Using the literal string `admin` as the username when `.env` has a different `COUCHDB_USER` value. CouchDB does not have a default `admin` user. The admin account name is whatever you set in `.env`.

***Fix:*** Pull the username from `.env` first:

```bash
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/
```

---

## Container starts but shows unhealthy in Portainer

***Symptom:*** `docker compose ps` shows `unhealthy` next to `couchdb`, but the database itself is responding to API calls and everything works.

***Cause:*** A common older healthcheck pattern is `curl -f http://localhost:5984/_up` without credentials. Because `local.ini` has `require_valid_user = true`, that endpoint returns `401 Unauthorized` to anonymous requests. The `-f` flag treats any HTTP error as failure, so the healthcheck always fails even though CouchDB is fine.

***Fix:*** Use a healthcheck that authenticates. The compose file in this repo uses:

```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -fsS -u $${COUCHDB_USER}:$${COUCHDB_PASSWORD} http://localhost:5984/_up || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 30s
```

The `$$` doubling escapes Docker Compose variable interpolation so the literal `${COUCHDB_USER}` reaches the shell inside the container, where it expands at runtime against the container's own environment.

After updating, recreate the container:

```bash
docker compose down
docker compose up -d
```

Wait 30 seconds for the `start_period` to elapse, then check `docker compose ps` again.

---

## First boot logs show database errors

***Symptom:*** Logs from `docker compose logs couchdb` on first boot include:

```
[warning] creating missing database: _nodes
[warning] creating missing database: _dbs
[notice] Missing system database _users
[error] Request to create N=3 DB but only 1 node(s)
```

***Cause:*** CouchDB defaults to expecting a 3 node cluster. On a fresh single node install, the system databases (`_users`, `_replicator`, `_global_changes`) do not exist yet and the cluster expects more nodes than are present.

***Fix:*** This is normal first boot noise and disappears after running `_cluster_setup`:

```bash
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)

curl -u "$ADMIN_USER:$ADMIN_PW" -X POST http://localhost:5984/_cluster_setup \
  -H "Content-Type: application/json" \
  -d '{"action":"enable_single_node","bind_address":"0.0.0.0","username":"'"$ADMIN_USER"'","password":"'"$ADMIN_PW"'","port":5984,"singlenode":true}'
```

Expected response: `{"ok":true}`.

After this runs once, the system databases get created and CouchDB stops complaining.

---

## Sync indicator moves but files do not appear cross device

***Symptom:*** The `Sync: ↑3 ↓1` indicator ticks up on both devices, the CouchDB `doc_count` grows, but files created on one device never show up on the other.

***Cause #1 (most common):*** Encryption passphrase mismatch between devices. Each device encrypts data with its own passphrase derived key. The server stores both sets of encrypted blobs side by side, but neither device can decrypt the other's data. Sync mechanics work fine, but the data is invisible across devices because it cannot be read.

***Fix:***

1. On the working device: Settings > Self-hosted LiveSync > find the E2EE Configuration section > reveal the passphrase using the show button or eye icon.
2. Copy the exact value to a password manager.
3. On the broken device: same settings location, paste the passphrase into the field. Do not retype it. Click Apply or Configure E2EE.
4. Run "Replicate now" from the command palette.
5. If still broken, in LiveSync settings find the Maintenance section and run "Rebuild local database from remote". This wipes the local sync state and pulls everything fresh from the server using the corrected passphrase.

***Cause #2:*** Property Encryption (also called Obfuscate Properties) setting differs between devices. Same root issue as the passphrase: the encryption contract does not match.

***Fix:*** Set the same value (both ON or both OFF) on every device. The recommended setting is ON.

***Cause #3:*** Sync Mode is set to event based instead of LiveSync.

***Fix:*** Settings > Self-hosted LiveSync > Sync Settings tab (circular arrows icon) > Sync Mode dropdown > set to LiveSync. The event based options (Sync on Save, Sync on Startup, etc.) are unreliable on mobile because Obsidian does not always fire save events when expected. LiveSync mode uses a persistent WebSocket and propagates changes in roughly one second.

---

## DevTools console shows 404 on _local

***Symptom:*** Opening DevTools (`Ctrl+Shift+I` on desktop) shows:

```
GET https://couchdb.yourdomain.com/sharedvault/_local/4r5eNzn0jGG1PnFcpauzIA%3D%3D 404 (Not Found)
```

***Cause:*** None. This is normal. PouchDB (the library LiveSync is built on) checks for an existing replication checkpoint document. If no checkpoint exists yet (first sync, or after a reset), the server returns 404. The plugin even prints a confirmation right after:

```
The above 404 is totally normal. PouchDB is just checking if a remote checkpoint exists.
```

***Fix:*** Ignore. Not an error.

---

## Console shows rule violation warnings

***Symptom:*** LiveSync console output includes lines like:

```
Rule violation: handleFilenameCaseSensitive is undefined but should be false
Rule violation: usePluginSyncV2 is false but should be true
Rule violation: customChunkSize is 0 but should be 60
```

***Cause:*** Configuration drift between devices. The plugin compares each device's settings against a baseline stored in the shared config document on the server. Mismatches are flagged.

These warnings do not block sync but can cause subtle inconsistencies, particularly around chunk dedup and case sensitive file handling.

***Fix:*** In LiveSync settings, find a "Check and Fix" or "Apply device config" command (often in the Maintenance section, or accessible via command palette). Run it on each device to harmonize settings.

---

## Fetch Remote Configuration Failed

***Symptom:*** A dialog during setup says:

> Could not fetch configuration from remote. If you are new to the Self-hosted LiveSync, this might be expected.

Two buttons: "Skip and proceed" and "Retry (recommended)".

***Cause:*** LiveSync stores a shared config document inside the database so future devices can fetch your preferences automatically. On the very first device against a brand new database, that document does not exist yet.

***Fix:*** Tap **Skip and proceed**. The first device will create the config document, so subsequent devices will not see this dialog. Tapping Retry just fails again for the same reason.

---

## Edit on one device does not propagate

***Symptom:*** You edit a note on one device but the change does not show up on the other within a few seconds.

***Diagnostic checklist:***

1. ***Is Sync Mode set to LiveSync on both devices?*** Settings → Self-hosted LiveSync → Sync Settings tab → Sync Mode dropdown.
2. ***Did the editing device actually save?*** On mobile, Obsidian sometimes does not flush a save while you are still in the editor. Tap away from the note (back arrow, switch to another note) to force save.
3. ***Did the doc_count on CouchDB go up?*** From the host:
   ```bash
   curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/sharedvault | grep -oE '"doc_count":[0-9]+'
   ```
   If it did not increase, the editing device never pushed. If it did increase, the receiving device is the problem.
4. ***Force a manual sync.*** On the receiving device, command palette → "Replicate now".
5. ***Check the LiveSync status tab*** (the 💬 icon at the top of LiveSync settings) for connection state, pending changes, and errors.

If all of those check out and sync still fails, suspect a passphrase mismatch (see [the cross device file invisibility entry](#sync-indicator-moves-but-files-do-not-appear-cross-device)).

---

## Cloudflare Tunnel returns 502 Bad Gateway

***Symptom:*** Hitting `https://couchdb.yourdomain.com/` returns a Cloudflare 502 error page.

***Cause:*** `cloudflared` cannot reach CouchDB on the configured backend URL.

***Fix:*** Diagnose with curl from wherever `cloudflared` runs:

```bash
curl http://<host-ip>:5984/
```

Expected: `{"error":"unauthorized",...}` (a 401, which means CouchDB is reachable and just demanding auth).

If the curl times out or refuses connection:

- ***CouchDB is not running.*** Check `docker compose ps`.
- ***CouchDB is bound only to 127.0.0.1.*** See [the bind address entry](#couchdb-only-listens-on-127001).
- ***A firewall is blocking the port.*** Check `iptables`, `ufw`, or your host firewall.
- ***`cloudflared` is on a different host than CouchDB and cannot route to it.*** Use the actual LAN IP in the tunnel config, not `localhost`.

---

## Browser prompts Cloudflare Access login instead of CouchDB

***Symptom:*** Hitting the tunnel URL in a browser shows a Cloudflare Access login screen (email OTP, SSO redirect, etc.) instead of CouchDB's HTTP Basic Auth popup.

***Cause:*** A Cloudflare Access policy is applied to the tunnel hostname.

***Fix:*** Remove the policy. Cloudflare Access intercepts requests before they reach CouchDB, which breaks LiveSync's auth handshake. Sync fails silently because the plugin cannot tell the difference between "wrong CouchDB password" and "Cloudflare wants me to log in via web SSO".

In the Cloudflare Zero Trust dashboard:

1. Access > Applications.
2. Find the application matching your CouchDB hostname.
3. Either delete the application entirely, or remove the policy that requires authentication.

CouchDB still requires HTTP Basic Auth on every request, and individual vaults are still locked down with `_security` documents, so removing Cloudflare Access does not weaken your security.

---

## Encryption passphrase lost

***Symptom:*** You no longer have the encryption passphrase, and at least one device has the working configuration with synced data.

***Outlook:*** The data on the server is encrypted client side. The passphrase derives the encryption key. Without the passphrase, the encrypted data is permanently unreadable. CouchDB does not store the passphrase and there is no way to recover it from the server side.

***Fix paths in order of preference:***

1. ***If at least one device still has the passphrase configured and sync working:*** reveal the passphrase from that device's LiveSync settings (E2EE section, show button or eye icon). Save it immediately.
2. ***If no device has the working passphrase but one device has the unencrypted vault contents on disk:*** that device's local files are in plaintext. Rebuild the entire setup from scratch using the local vault as the new master.
3. ***If the passphrase is gone and no device has the unencrypted contents:*** the data is unrecoverable. Nuclear reset is the only path forward (see below).

***Nuclear reset:***

```bash
cd /compose/couchdb
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)

curl -u "$ADMIN_USER:$ADMIN_PW" -X DELETE http://localhost:5984/sharedvault
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT http://localhost:5984/sharedvault
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT http://localhost:5984/sharedvault/_security \
  -H "Content-Type: application/json" \
  -d '{"admins":{"names":[],"roles":[]},"members":{"names":["guestuser"],"roles":[]}}'
```

Then on each device, in LiveSync Maintenance, run "Discard local database and start over" and re-run the wizard with a fresh passphrase you save to a password manager this time.

---

## Container port conflicts

***Symptom:*** `docker compose up -d` fails with `bind: address already in use` for port 5984.

***Cause:*** Another process (often another CouchDB instance, a forgotten container, or some unrelated service) is already bound to port 5984 on the host.

***Fix:*** Find what is using the port:

```bash
ss -tlnp | grep 5984
```

If it is another container you forgot about:

```bash
docker ps | grep 5984
docker stop <container-name>
```

If it is a host service, either stop it or change the CouchDB host port mapping in `docker-compose.yaml`:

```yaml
ports:
  - "5985:5984"
```

Then update your tunnel config to point at the new host port.

---

## CouchDB only listens on 127.0.0.1

***Symptom:*** Locally `curl http://localhost:5984/` works from the CouchDB host, but `curl http://<host-ip>:5984/` from another machine on the same LAN fails with connection refused. Cloudflare Tunnel returns 502.

***Cause:*** CouchDB is binding only to the loopback interface inside the container. The `bind_address` setting in `local.ini` is missing or set to `127.0.0.1`.

***Fix:*** Edit `config/local.ini` and confirm:

```ini
[chttpd]
bind_address = 0.0.0.0

[httpd]
bind_address = 0.0.0.0
```

Restart the container:

```bash
docker compose restart couchdb
```

Verify:

```bash
docker exec couchdb ss -tlnp | grep 5984
```

Should show `0.0.0.0:5984` rather than `127.0.0.1:5984`.

---

## Mobile fails to connect with CORS errors

***Symptom:*** During mobile setup, the connection test fails. Console (if accessible) shows CORS related errors. Desktop works fine.

***Cause:*** CORS is not configured in `local.ini`, or the Obsidian mobile origin is not in the allowed origins list.

***Fix:*** Confirm your `local.ini` has the full CORS block:

```ini
[chttpd]
enable_cors = true

[httpd]
enable_cors = true

[cors]
origins = app://obsidian.md,capacitor://localhost,http://localhost
credentials = true
headers = accept, authorization, content-type, origin, referer
methods = GET, PUT, POST, HEAD, DELETE
max_age = 3600
```

If it does, restart the container:

```bash
docker compose restart couchdb
```

Verify the config is loaded inside the container:

```bash
docker exec couchdb cat /opt/couchdb/etc/local.d/local.ini
```

Should show your full config including the `[cors]` section.

---

## Cannot delete a database file_exists error

***Symptom:*** Trying to create a database returns:

```json
{"error":"file_exists","reason":"The database could not be created, the file already exists."}
```

***Cause:*** A database with that name already exists, possibly from a prior attempt.

***Fix:*** Either pick a different name, or delete the existing one first:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X DELETE http://localhost:5984/sharedvault
```

If the delete itself fails with permission errors, confirm you are using admin credentials and not a regular user.

---

## LiveSync wizard hangs on test connection

***Symptom:*** During the Obsidian wizard, the "Test Connection" or "Next" button spins indefinitely without succeeding or failing.

***Diagnostic:*** Most common causes in order of likelihood:

1. ***Typo in the URI.*** Confirm `https://` not `http://`. Confirm spelling. Confirm no trailing slash.
2. ***Typo in username, password, or database name.*** Each is case sensitive.
3. ***Tunnel not actually live.*** Test from outside the LAN with `curl https://couchdb.yourdomain.com/`.
4. ***Mobile device on Wi-Fi that blocks the request.*** Try cellular data instead. Some hotel Wi-Fi and corporate networks block arbitrary HTTPS endpoints.
5. ***Cloudflare Access enabled.*** See [the Access entry above](#browser-prompts-cloudflare-access-login-instead-of-couchdb).

Go through this list one item at a time. The wizard does not give helpful errors, so process of elimination is the only way.

---

## Two devices have different vault content

***Symptom:*** Phone and desktop both have LiveSync running, sync indicators move, but each device shows a different set of files. They appear to be syncing two separate vaults.

***Cause:*** The most likely cause is encryption mismatch between devices: passphrase, Property Encryption setting, or both. Each device encrypts and decrypts its own data, but cannot read the other's. The server stores both sets of encrypted blobs side by side. Each device sees only its own files.

***Fix:*** This is the same problem as the [cross device file invisibility entry](#sync-indicator-moves-but-files-do-not-appear-cross-device). Resolution depends on which device has the data you want to keep.

***If desktop has the canonical data:***

1. On desktop: confirm passphrase and Property Encryption settings.
2. On phone: paste the same passphrase, set the same Property Encryption value.
3. On phone: LiveSync Maintenance → "Discard local database and start over".
4. On phone: re-run the wizard, pick "I am adding a device to an existing synchronisation setup", pick "This Vault is empty" on the reset sync screen.
5. Phone pulls the desktop's content down.

***If phone has the canonical data:*** mirror the above with phone and desktop reversed.

***If both have content you want to keep:*** more complex. Probably easiest to: copy phone's vault folder to desktop manually, do the reset on phone, let phone sync down, manually merge any conflicts in the file system, then save the result.

---

## General Diagnostic Checklist

When something is broken and not in this guide, work through this list before deeper investigation.

### On the host

```bash
# Container running and healthy?
docker compose ps

# Logs reveal anything?
docker compose logs --tail 100 couchdb

# Can you authenticate locally?
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/_up

# Is the database doc count what you expect?
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/sharedvault | grep -oE '"doc_count":[0-9]+'

# Does the security document look right?
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/sharedvault/_security
```

### Through the tunnel

```bash
# Tunnel reachable and CouchDB responding through it?
curl https://couchdb.yourdomain.com/_up
# Expect: {"error":"unauthorized","reason":"Authentication required."}

curl -u guestuser:GUEST_PW https://couchdb.yourdomain.com/sharedvault
# Expect: JSON with db_name, doc_count, etc.
```

### On the client

1. Settings > Self-hosted LiveSync > Sync Settings tab > confirm Sync Mode is **LiveSync**.
2. Settings > Self-hosted LiveSync > confirm passphrase matches across devices.
3. Settings > Self-hosted LiveSync > confirm Property Encryption matches across devices.
4. Open DevTools (desktop only) and watch console while triggering "Replicate now" from command palette.
5. Status tab in LiveSync settings (💬 icon) shows pending changes and errors.

### Common findings

If you make it through the checklist and find:

- ***Server side everything looks fine, only some devices are broken:*** suspect passphrase or encryption settings on the broken devices.
- ***Server side itself is unreachable through the tunnel:*** suspect tunnel config, Cloudflare Access, or `bind_address`.
- ***Server side responds but rejects credentials from clients:*** suspect mistyped username, password, or database name.
- ***Sync moves numbers but no actual file changes appear:*** suspect encryption mismatch.

---

## When to Nuke and Start Over

Sometimes the fastest path forward is a clean reset rather than debugging an inconsistent state.

Consider a nuclear reset when:

- The encryption passphrase is genuinely lost
- Multiple devices have drifted into inconsistent states with different content
- An experimental setting change broke things and you cannot remember what changed
- The data on the server is small or unimportant and a fresh start is cheaper than diagnosis

To reset just the vault data without rebuilding the container:

```bash
cd /compose/couchdb
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)

curl -u "$ADMIN_USER:$ADMIN_PW" -X DELETE http://localhost:5984/sharedvault
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT http://localhost:5984/sharedvault
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT http://localhost:5984/sharedvault/_security \
  -H "Content-Type: application/json" \
  -d '{"admins":{"names":[],"roles":[]},"members":{"names":["guestuser"],"roles":[]}}'
```

To reset the entire CouchDB instance including users:

```bash
docker compose down
rm -rf /compose/couchdb/data
docker compose up -d
```

Then redo the setup from the server setup guide. All users, all databases, all sync state gone. Useful when starting truly clean.

---

## When the Issue Is Not in This Guide

If you have worked through the diagnostic checklist and your issue is not covered here:

1. ***Check the LiveSync plugin's GitHub issues.*** The plugin is actively maintained and many edge cases are documented there.
2. ***Check the Apache CouchDB documentation.*** For server side issues that look like CouchDB bugs rather than LiveSync issues.
3. ***Try a nuclear reset on a single device first.*** Often the cheapest way to confirm the problem is local rather than server side.
4. ***Capture logs.*** Both `docker compose logs couchdb` and the LiveSync DevTools console output. These reveal far more than client side error messages.