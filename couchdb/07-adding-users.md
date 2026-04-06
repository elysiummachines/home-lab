# Adding More Users and Vaults

This guide covers creating additional isolated vaults on the same CouchDB instance. Each vault gets its own database and its own user, with CouchDB's `_security` documents enforcing that no user can access anyone else's vault.

Use this when you want to share specific vaults with specific people, give yourself a separate vault for work or personal notes, or run a small CouchDB for friends and family without exposing everyone's notes to everyone else.

## How Isolation Works

A quick refresher on the isolation model from the vault setup guide:

- ***Each user is a document*** in the system `_users` database, with a hashed password.
- ***Each vault is its own database*** at the root of the CouchDB instance.
- ***Each database has a `_security` document*** that lists which users can read or write it.
- ***Admin accounts bypass `_security`*** and can access everything. The non admin user accounts you create here can only access what their `_security` documents grant.

The result: even if Alice's password is leaked, the attacker can only read Alice's vault, not Bob's, not yours, and not the system databases.

## Planning Before You Start

Before creating users, decide:

- ***How many vaults do you need?*** One per person is the simplest model. One person can also have multiple vaults if they want a `work` and a `personal` separation.
- ***Will the new user share the encryption passphrase with anyone?*** If two people both edit the same vault, they need the same passphrase. If each user has their own private vault, each picks their own passphrase.
- ***What naming convention do you want?*** Pick something consistent. Examples below.

### Naming patterns that work well

| Use case | Database name | Username |
|---|---|---|
| Personal vaults per person | `alicevault` | `alice` |
| Multiple vaults per person | `alice-work`, `alice-personal` | `alice` |
| Shared vault for a team | `teamvault` | `teamuser` (or one user per member with both as members) |
| Project specific vaults | `project42` | `project42-user` |

Database names have rules: lowercase letters, digits, and `_ $ ( ) + -` only. Must start with a lowercase letter. Cannot start with underscore.

Usernames have rules: lowercase letters, digits, and `_ - ( )` only. Must start with a letter.

## Step 1: Load Admin Credentials

```bash
cd /compose/couchdb
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)
```

## Step 2: Set the New User and Database Variables

Pick names for the new user and vault, and a password for the user:

```bash
NEW_USER='alice'
NEW_DB='alicevault'
NEW_PW='alice-passphrase-here'
```

For the password, the same advice from the original vault setup applies. Pick something the user can actually type, avoid `+ / = @ : # ?` for cleaner URL handling, and use a passphrase style if possible:

```bash
NEW_PW='harbor-cement-mango-ranger'
```

## Step 3: Create the Database

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT "http://localhost:5984/$NEW_DB"
```

Expected:

```json
{"ok":true}
```

If you get `{"error":"file_exists"}`, the database already exists. Either pick a different name or delete the existing one with `curl -X DELETE`.

## Step 4: Create the User

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT \
  "http://localhost:5984/_users/org.couchdb.user:$NEW_USER" \
  -H "Content-Type: application/json" \
  -d '{"name":"'"$NEW_USER"'","password":"'"$NEW_PW"'","roles":[],"type":"user"}'
```

Expected:

```json
{"ok":true,"id":"org.couchdb.user:alice","rev":"1-..."}
```

If you get `{"error":"conflict"}`, the username is already taken. Pick a different one.

## Step 5: Lock the Database to This User

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT "http://localhost:5984/$NEW_DB/_security" \
  -H "Content-Type: application/json" \
  -d '{"admins":{"names":[],"roles":[]},"members":{"names":["'"$NEW_USER"'"],"roles":[]}}'
```

Expected:

```json
{"ok":true}
```

## Step 6: Verify Isolation

Same checks as the original vault setup. Run all three.

### Check 1: User can read their own vault

```bash
curl -u "$NEW_USER:$NEW_PW" "http://localhost:5984/$NEW_DB"
```

Expected: JSON with `db_name`, `doc_count`, `sizes`, etc.

### Check 2: User cannot access system databases

```bash
curl -u "$NEW_USER:$NEW_PW" http://localhost:5984/_users/_all_docs
```

Expected: `{"error":"unauthorized","reason":"You are not a server admin."}`

### Check 3: User cannot access other vaults

Replace `sharedvault` with the name of any other vault that exists on your instance:

```bash
curl -u "$NEW_USER:$NEW_PW" http://localhost:5984/sharedvault
```

Expected: `{"error":"unauthorized","reason":"You are not authorized to access this db."}`

If all three checks pass, isolation is working.

## Step 7: Clean Up Shell History

```bash
unset ADMIN_USER ADMIN_PW NEW_USER NEW_PW NEW_DB
history -c
```

## Step 8: Hand Credentials to the User

The new user needs five things to set up Obsidian on their devices:

| Item | Example value |
|---|---|
| CouchDB URL | `https://couchdb.yourdomain.com` |
| Username | `alice` |
| Password | the password from Step 2 |
| Database name | `alicevault` |
| Encryption passphrase | (see below) |

### About the encryption passphrase

The encryption passphrase is set by the user inside the LiveSync wizard, not by you when creating the account. CouchDB never sees the passphrase, only the encrypted blobs the user uploads.

So the workflow is:

1. You create the database, user, and security document on the server (this guide).
2. You give the user the four credentials above.
3. The user runs the LiveSync wizard on their first device, sets a passphrase of their choosing, and saves it to their own password manager.
4. The user follows the same passphrase rules on every other device they want to add: paste exactly, never retype.

If two people share the same vault (collaborative use), they need to agree on a passphrase out of band and both enter it during their respective wizards.

## Sharing a Vault Between Multiple Users

If you want two or more people to both have access to the same vault, you have two options.

### Option A: Multiple users, one shared `_security` document

Add multiple usernames to the `members.names` list:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT "http://localhost:5984/sharedvault/_security" \
  -H "Content-Type: application/json" \
  -d '{"admins":{"names":[],"roles":[]},"members":{"names":["alice","bob"],"roles":[]}}'
```

Now both `alice` and `bob` can read and write `sharedvault`. Each has their own login and their own password, but both can revoke independently by removing one from the list.

Both users still need to use the same encryption passphrase since the data on the server is encrypted with one key. They must agree on it out of band.

### Option B: One shared user account

Create one user account and give the password to everyone who needs access:

```bash
SHARED_USER='teamuser'
SHARED_PW='shared-team-passphrase'
```

Simpler but with downsides. You cannot revoke one person's access without changing the password for everyone, and there is no audit trail of who did what (CouchDB only sees `teamuser`, not which human typed it).

Option A is preferred for shared vaults unless the team is small and trusted.

## Removing a User

To revoke access for a user without deleting their data:

```bash
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)

# Get the user's current revision
USER_REV=$(curl -s -u "$ADMIN_USER:$ADMIN_PW" "http://localhost:5984/_users/org.couchdb.user:alice" | grep -oE '"_rev":"[^"]+"' | cut -d'"' -f4)

# Delete the user document
curl -u "$ADMIN_USER:$ADMIN_PW" -X DELETE "http://localhost:5984/_users/org.couchdb.user:alice?rev=$USER_REV"
```

Their database (`alicevault`) is still intact and can be reassigned to another user by updating its `_security` document. Or you can delete the database too if it is no longer needed:

```bash
curl -u "$ADMIN_USER:$ADMIN_PW" -X DELETE http://localhost:5984/alicevault
```

## Resetting a User's Password

If a user forgets their password, the admin can reset it. You need their current document revision:

```bash
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)

NEW_PW='new-password-here'

# Get current document
USER_DOC=$(curl -s -u "$ADMIN_USER:$ADMIN_PW" "http://localhost:5984/_users/org.couchdb.user:alice")
USER_REV=$(echo "$USER_DOC" | grep -oE '"_rev":"[^"]+"' | cut -d'"' -f4)

# Update with new password
curl -u "$ADMIN_USER:$ADMIN_PW" -X PUT \
  "http://localhost:5984/_users/org.couchdb.user:alice" \
  -H "Content-Type: application/json" \
  -d '{"_rev":"'"$USER_REV"'","name":"alice","password":"'"$NEW_PW"'","roles":[],"type":"user"}'
```

CouchDB automatically rehashes the new password on save.

The user's encryption passphrase is unaffected by this since it lives only on their devices. They can keep using their existing devices with the new CouchDB password and the same passphrase.

## What You Have Now

- A new isolated vault on the same CouchDB instance
- A user account that can only access that one vault
- Verified isolation against system databases and other vaults
- Knowledge of how to share vaults between users, remove users, and reset passwords

## Next Step

Proceed to **[08 - Monitoring and Maintenance](08-monitoring.md)** for the day to day operations of your CouchDB instance: checking sizes, compacting databases, backing up data, and inspecting the system.