# Cloudflare Tunnel

This guide covers exposing your CouchDB instance to the internet via Cloudflare Tunnel so mobile devices and remote machines can reach it. No ports need to be opened on your host firewall and TLS is handled automatically at Cloudflare's edge.

This guide assumes you already have a Cloudflare Tunnel running on your host. If not, the Cloudflare Zero Trust dashboard walks you through creating one in about 5 minutes.

## Why Cloudflare Tunnel

Three reasons this setup uses Cloudflare Tunnel instead of a traditional reverse proxy:

- ***No inbound ports.*** Your host does not need to expose anything to the public internet. The `cloudflared` daemon dials out to Cloudflare and all traffic comes back through that outbound connection.
- ***Free TLS.*** Cloudflare terminates HTTPS at its edge using certificates it manages. You never deal with Let's Encrypt, ACME challenges, or cert renewals.
- ***No DNS juggling.*** Adding a public hostname in the tunnel dashboard automatically creates the DNS record.

The tradeoff is that all your Obsidian sync traffic passes through Cloudflare's network. Because the vault data is already end to end encrypted by the LiveSync plugin before it hits the tunnel, Cloudflare sees only opaque encrypted blobs, not note content.

## Step 1: Open Your Tunnel in Cloudflare Zero Trust

1. Log in to your Cloudflare account.
2. Go to **Zero Trust** (left sidebar, or navigate to `one.dash.cloudflare.com`).
3. Click **Networks** > **Connectors**.
4. Click the tunnel that is running on your CouchDB host.

If you do not have a tunnel running yet, click **Create a tunnel**, pick the `Cloudflared` type, name it, and follow the installer instructions. Come back here once the tunnel shows `HEALTHY` in the dashboard.

## Step 2: Add a Public Hostname

1. Inside your tunnel, click the **Published application routes** tab.
2. Click **Add a Published application routes**.

Fill in the fields:

| Field | Value |
|---|---|
| Subdomain | `couchdb` (or whatever you want) |
| Domain | pick your Cloudflare managed domain from the dropdown |
| Path | leave empty |
| Service Type | `HTTP` |
| URL | `localhost:5984` if cloudflared runs on the same host, or `<node-ip>:5984` otherwise |

### Why HTTP and not HTTPS

Cloudflare terminates TLS at its edge. The traffic from Cloudflare to your `cloudflared` daemon is already encrypted over the tunnel protocol itself. Asking `cloudflared` to then re-encrypt to CouchDB over HTTPS would mean TLS over TLS, and CouchDB does not have a valid cert anyway (it only listens on plain HTTP inside the container).

Pointing `cloudflared` at the plain HTTP port is the correct setup.

## Step 3: Configure Additional Settings

Expand the **Additional application settings** section at the bottom of the hostname config.

### TLS

Leave all defaults. Specifically:

- ***No TLS Verify:*** OFF (not relevant, backend is HTTP)
- ***TLS Timeout:*** default
- ***HTTP2 connection:*** doesn't matter

### HTTP

- ***HTTP Host Header:*** leave blank
- ***Disable Chunked Encoding:*** OFF
- ***Connection:*** keepalive

Do NOT disable chunked encoding. LiveSync uses chunked uploads for large vault pushes and disabling it will cause upload failures for bigger vaults.

### Connection

Defaults are fine. Specifically:

- ***Connect Timeout:*** 30 seconds
- ***No Happy Eyeballs:*** OFF
- ***Keep Alive Connections:*** 100
- ***TCP Keep Alive Interval:*** 30 seconds

### Access

> ***Do NOT enable Cloudflare Access on this hostname.***

Cloudflare Access puts its own authentication layer in front of the service (email OTP, SSO, etc.). CouchDB uses HTTP Basic Auth, which the LiveSync plugin handles natively. Adding Cloudflare Access breaks LiveSync's auth handshake in a way that is hard to diagnose because the sync just silently fails. Leave **Enforce Access JSON Web Token (JWT) validation** set to OFF.

Your CouchDB is still protected: every request requires HTTP Basic Auth with a valid CouchDB user, and individual vaults are locked down with `_security` documents as covered in the previous guide.

## Step 4: Save and Wait for DNS Propagation

Click **Save hostname**. Cloudflare will automatically create a DNS record pointing your subdomain at the tunnel. This usually takes 10 to 30 seconds to propagate.

## Step 5: Verify the Tunnel Is Working

From any machine outside your local network (including your phone on cellular data), run or open:

### Test 1: Welcome endpoint should require auth

```bash
curl https://couchdb.yourdomain.com/
```

Expected response:

```json
{"error":"unauthorized","reason":"Authentication required."}
```

This looks like an error but it is actually success. It means the request reached CouchDB and CouchDB enforced authentication. A 502 Bad Gateway or timeout would mean the tunnel is not reaching CouchDB.

### Test 2: Authenticated request returns data

```bash
curl -u guestuser:yourPasswordHere https://couchdb.yourdomain.com/sharedvault
```

Expected response:

```json
{"db_name":"sharedvault","doc_count":0,"update_seq":"...","sizes":{...},...}
```

That confirms the tunnel works, CouchDB accepts credentials through the tunnel, and the guest user has access to their vault.

### Test 3: Browser check

Open `https://couchdb.yourdomain.com/` in a web browser. You should see a Basic Auth popup asking for a username and password. Cancel it (nothing more to test here), the popup itself is proof that the tunnel is correctly forwarding to CouchDB.

## Step 6: (Optional) Lock Down Fauxton Access

Fauxton is CouchDB's built in web admin interface at `/_utils/`. It is extremely useful but gives full admin access once logged in. You probably do not want it exposed to the entire internet.

Three options in order of paranoia:

### Option A: Do nothing

Fauxton requires the admin password to log in. A strong admin password and a non guessable tunnel URL are already a decent defense. This is the default and fine for most home setups.

### Option B: Cloudflare WAF rule to restrict by IP

1. Cloudflare dashboard → your domain → **Security** → **WAF** → **Custom rules**.
2. Click **Create rule**.
3. Name it something like `Restrict Fauxton to home IP`.
4. Expression:
   ```
   (http.host eq "couchdb.yourdomain.com" and http.request.uri.path contains "/_utils") and not ip.src eq YOUR.HOME.IP.HERE
   ```
5. Action: **Block**.
6. Deploy.

Now `/_utils/` (Fauxton) is blocked from every IP except your home address, while the rest of the tunnel (which LiveSync uses for sync) stays open to everyone with valid credentials.

### Option C: Use Fauxton only from LAN

Skip the tunnel for Fauxton entirely. Access it at `http://<host-ip>:5984/_utils/` directly over your local network. This requires no Cloudflare config, but means Fauxton is unusable when you are away from home.

## Step 7: Save the Public URL

Write down (or save in a password manager) the Cloudflare URL you just created. You will enter this in the Obsidian LiveSync plugin on every device:

```
https://couchdb.yourdomain.com
```

Note: no trailing slash. LiveSync's URI field expects the bare protocol and hostname.

## What You Have Now

- A public HTTPS URL that reaches your CouchDB instance
- Automatic TLS certificates managed by Cloudflare
- No inbound ports opened on your host
- HTTP Basic Auth enforced at the CouchDB layer
- Per vault access control enforced by `_security` documents
- (Optionally) Fauxton locked down to your home IP

## Common Failure Modes

If the tests in Step 5 do not work, jump to the troubleshooting guide. The usual suspects are:

- Tunnel shows UNHEALTHY in Cloudflare dashboard (check `cloudflared` logs on host)
- Service URL points to `localhost:5984` but `cloudflared` runs on a different host (use the real IP instead)
- CouchDB bound only to `127.0.0.1` inside the container (check `bind_address` in `local.ini`)
- Cloudflare Access accidentally enabled on the hostname (disable it)

## Next Step

Proceed to **[05 - Mobile Setup](05-mobile-setup.md)** to install the Self-hosted LiveSync plugin on your phone and connect it to your new CouchDB backend.