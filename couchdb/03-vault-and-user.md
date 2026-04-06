# Vault and User Setup

This guide covers creating a database to hold your Obsidian vault data and creating a restricted user account that can only access that one database. The isolation model lets you share specific vaults with specific people without exposing anything else on your CouchDB instance.

Repeat this entire guide for every vault and user pair you want. Each run creates one isolated vault.

## Conceptual Model

Before running commands, it helps to understand how CouchDB handles access control:

- ***Each vault is a database.*** In CouchDB terms, a "database" is a collection of documents. One Obsidian vault maps to one CouchDB database.
- ***Each user is an account in the `_users` system database.*** Users are stored as documents of `type: "user"` with a hashed password.
- ***Each database has a `_security` document.*** This single document inside the database defines which users can read or write it. Without a `_security` document, any authenticated user can access the database by default. With one, only the users listed in its `members` field can get in.
- ***Admins bypass all security.*** The admin account defined in `.env` (the one you set up in the previous guide) can access every database regardless of `_security` rules. Non admin users are locked down.

The goal of this guide is to create one database, one non admin user, and one `_security` document that binds them together.

## Step 1: Load Admin Credentials

```bash
cd /compose/couchdb
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)
```

Verify the admin creds work:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/
```

Expected response starts with `{"couchdb":"Welcome",...}`. If you get an authentication error, go back to the server setup guide and confirm your admin credentials are correct.

## Step 2: Pick a Database Name and Username

Some planning matters here because CouchDB has naming rules:

### Database name rules

- Lowercase letters, digits, and these symbols only: `_ $ ( ) + -`
- Must start with a lowercase letter
- Cannot start with underscore (those are reserved for system databases)
- Examples that work: `sharedvault`, `alice-notes`, `bob_work_vault`, `project42`
- Examples that fail: `SharedVault`, `_myvault`, `alice.notes`, `user@home`

### Username rules

- Lowercase letters, digits, and these symbols only: `_ - ( )`
- Must start with a letter
- No spaces, no uppercase in the URL path portion
- Examples that work: `alice`, `bob_phone`, `user-01`, `hachimon`
- Examples that fail: `Alice`, `user@example.com`, `john doe`

For this guide we will use `sharedvault` as the database and `guestuser` as the user. Substitute your own names throughout.

## Step 3: Create the Vault Database

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT http://localhost:5984/sharedvault
```

Expected response:

```json
{"ok":true}
```

If you get `{"error":"file_exists","reason":"The database could not be created, the file already exists."}`, the database already exists from a previous run. Either pick a different name or delete the existing one first:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X DELETE http://localhost:5984/sharedvault
```

## Step 4: Pick a User Password

Pick a password that the user will actually type. Long random strings work for API clients but are miserable to punch into a mobile keyboard.

Good options:

- ***Passphrase style:*** four random words joined with dashes, like `anchor-blanket-rocket-pepper`. High entropy, easy to type, easy to read off aloud if needed.
- ***Short mixed string:*** something like `Hachimon-2026` or `VaultKey42!`. Memorable and strong enough for HTTP Basic Auth behind a tunnel.

Avoid characters that break URL embedded auth (`http://user:pass@host`): `+`, `/`, `=`, `@`, `:`, `#`, `?`. You can work around them by using `curl -u user:pass` (header based) instead of the URL form, but picking a clean password up front saves headaches.

Set the variable:

```bash
GUEST_PW='pick-a-memorable-passphrase'
```

## Step 5: Create the User

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT \
  http://localhost:5984/_users/org.couchdb.user:guestuser \
  -H "Content-Type: application/json" \
  -d '{"name":"guestuser","password":"'"$GUEST_PW"'","roles":[],"type":"user"}'
```

Expected response:

```json
{"ok":true,"id":"org.couchdb.user:guestuser","rev":"1-..."}
```

### Why the document ID is `org.couchdb.user:guestuser`

CouchDB stores all users as documents inside the built in `_users` database. The document ID follows a strict convention: `org.couchdb.user:<username>`. This prefix is required. If you try to create a user document without it, CouchDB rejects the request.

### What the JSON body means

- `"name"`: the username. Must match the end of the document ID.
- `"password"`: plaintext on input. CouchDB automatically hashes and salts it on write, so the actual stored document contains `password_scheme`, `iterations`, `derived_key`, and `salt` fields. The plaintext is discarded immediately.
- `"roles"`: an array of role names. We leave it empty for simple per user access.
- `"type"`: must be `"user"`.

## Step 6: Lock the Database to Only This User

This is the critical step for isolation. Without it, any authenticated user on your CouchDB instance can read any database.

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT http://localhost:5984/sharedvault/_security \
  -H "Content-Type: application/json" \
  -d '{"admins":{"names":[],"roles":[]},"members":{"names":["guestuser"],"roles":[]}}'
```

Expected response:

```json
{"ok":true}
```

### What the `_security` document means

- `"admins"`: users and roles that can administrate this specific database (modify its `_security` doc, add indexes, etc.). We leave it empty because the global admin defined in `.env` already has full access to everything.
- `"members"`: users and roles that can read and write documents in this database. We put `guestuser` here.

Once this document exists, any request to `/sharedvault` from a user not listed in `members` (or `admins`) will be rejected with `401 Unauthorized`.

## Step 7: Verify Isolation

This step matters. If isolation is broken, your entire per user access model is broken. Run both of these checks.

### Check 1: The user can read their own vault

```bash
curl -u "guestuser:$GUEST_PW" http://localhost:5984/sharedvault
```

Expected: JSON response with `db_name`, `doc_count`, `sizes`, and other database metadata.

If this returns `{"error":"unauthorized","reason":"Name or password is incorrect."}`, the user account is not set up correctly. Go back to Step 5.

### Check 2: The user cannot access system databases

```bash
curl -u "guestuser:$GUEST_PW" http://localhost:5984/_users/_all_docs
```

Expected: `{"error":"unauthorized","reason":"You are not a server admin."}`

This is the result you want. It proves that the user is authenticated (not rejected for wrong credentials) but is blocked from reading the system `_users` database. That means they also cannot enumerate other users, discover other database names, or probe for anything outside what you granted them.

### Check 3: If you have another vault, verify the user cannot touch it

Create a second database temporarily:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT http://localhost:5984/secretvault
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT http://localhost:5984/secretvault/_security \
  -H "Content-Type: application/json" \
  -d '{"admins":{"names":[],"roles":[]},"members":{"names":["someone-else"],"roles":[]}}'
```

Now try to read it as `guestuser`:

```bash
curl -u "guestuser:$GUEST_PW" http://localhost:5984/secretvault
```

Expected: `{"error":"unauthorized","reason":"You are not authorized to access this db."}`

Clean up the test database:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X DELETE http://localhost:5984/secretvault
```

If all three checks pass, isolation is working correctly.

## Step 8: Clean Up Shell History

Your variables still hold sensitive data:

```bash
unset ADMIN_USER ADMIN_PW GUEST_PW
history -c
```

Or selectively delete lines with passwords:

```bash
history | grep -E 'GUEST_PW|ADMIN_PW'
history -d <line-number>
```

## What You Have Now

- A new database called `sharedvault` (or whatever you named it)
- A non admin user called `guestuser` (or whatever you named them)
- A `_security` document that restricts the database to only that user
- Verified isolation: the user cannot read system databases, cannot read other databases, and can only access the one vault you assigned

The database is still empty. Data starts flowing in once you connect your first Obsidian device in a later step.

## Credentials to Save

Write these down somewhere safe (password manager, paper in a drawer, whatever works):

- CouchDB URL: (you will add the Cloudflare Tunnel hostname in the next guide)
- Database name: `sharedvault`
- Username: `guestuser`
- Password: the `$GUEST_PW` value from Step 4

You will need all four when setting up each Obsidian device.

## Next Step

Proceed to **[04 - Cloudflare Tunnel](04-cloudflare-tunnel.md)** to expose CouchDB to the internet securely so your mobile and remote devices can reach it.