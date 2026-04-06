# Desktop Setup (Second Device)

This guide covers adding Obsidian desktop as a second device that syncs with the same CouchDB vault your phone is now pushing to. The same steps apply for laptops, other phones, work machines, or any additional device you want to sync.

> ***Read this entire guide before starting.*** The second device setup looks almost identical to the mobile setup, but one specific choice is different and picking the wrong option will wipe all the data your first device uploaded.

## The Critical Difference

When the wizard asks how to configure the connection situation, the phone picked `I am setting this up for the first time`. That option tells the plugin to treat this device as the master and push its vault up as the source of truth.

On the second device, you must pick `I am adding a device to an existing synchronisation setup` instead. That option tells the plugin to pull content down from the server.

Picking `setting up for the first time` on a second device will overwrite the server with whatever is on the desktop, erasing everything the phone uploaded. You have been warned.

## Before You Start

Have these ready:

- ***All five credentials from the mobile setup:*** URL, username, password, database name, and the End-to-End Encryption passphrase
- ***Password manager open*** so you can copy and paste the passphrase rather than typing it
- ***A decision about which vault to use:*** either create a new empty vault on desktop (cleanest option), or open an existing desktop vault and accept that its contents will merge with what the phone uploaded

### About using an existing desktop vault

If you open an existing vault with local content on it, LiveSync will treat those files as new additions and push them up alongside the phone's content. This is fine if you want both sets of files merged. It can be surprising if you expected the existing vault to get wiped.

If you want a clean state, create a new empty vault dedicated to syncing.

## Step 1: Open or Create a Vault on Desktop

1. Launch Obsidian desktop.
2. Either pick an existing vault or click **Create new vault**, name it, and open it.

## Step 2: Enable Community Plugins

1. Open Settings (gear icon, bottom left).
2. Click **Community plugins** in the left sidebar.
3. Click **Turn on community plugins**.
4. Accept the warning.

## Step 3: Install Self-hosted LiveSync

1. Click **Browse** in the Community plugins screen.
2. Search for `Self-hosted LiveSync`.
3. Click the plugin in the results, then click **Install**.
4. When installation finishes, click **Enable**.
5. Close the Browse dialog. **Self-hosted LiveSync** should now appear in the left sidebar under Community plugins.

## Step 4: Open the Setup Wizard

1. Click **Self-hosted LiveSync** in the left sidebar.
2. Click **Setup Wizard** or the equivalent button on the welcome screen.

## Step 5: Connection Method

Same as on mobile: pick **Enter the server information manually**, not Setup URI.

Click **Proceed with Manual Configuration**.

## Step 6: Server Configuration

Fill in the same values you used on mobile:

| Field | Value |
|---|---|
| URI | `https://couchdb.yourdomain.com` |
| Username | `guestuser` |
| Password | the guestuser password |
| Database name | `sharedvault` |

Click **Test** or **Next**. Expect a green success message.

## Step 7: End to End Encryption (PASTE, DO NOT RETYPE)

1. ***Check the End-to-End Encryption box.***
2. ***Paste*** the passphrase from your password manager into the passphrase field. Do not retype it. A single character mismatch with the phone's passphrase breaks sync silently with no error message.
3. ***Check the Obfuscate Properties box.*** Must match whatever you picked on the phone (you set it to on, so set it to on here).

> ***Common trap:*** typing the passphrase instead of pasting it. Even if you are careful, mobile keyboards and desktop keyboards interpret things differently (smart quotes, autocorrect, caps). Paste is the only safe way.

Click **Proceed**.

## Step 8: Decision Required - Pick "Adding a Device"

This is the critical screen. You will see something titled **Mostly Complete: Decision Required** or similar with three options:

- ***I am setting up a new server for the first time / I want to reset my existing server.*** Overwrites server with this device's vault. DO NOT PICK THIS.
- ***My remote server is already set up. I want to join this device.*** ← PICK THIS ONE. Joins as a secondary and pulls server content down.
- ***The remote is already set up, and the configuration is compatible.*** Skips the rebuild step. Requires that this device's local sync state is already aligned with the server, which it isn't for a fresh install. Do not pick this.

Select the middle option and continue.

## Step 9: Reset Synchronisation on This Device

A screen titled **Reset Synchronisation on This Device** appears with options describing your vault's current state. Pick the one that matches:

- ***The files in this Vault are almost identical to the server's.*** Only pick this if you just restored from a backup that matches what is on the server. Rare.
- ***This Vault is empty, or contains only new files that are not on the server.*** The most common pick. Use this for a fresh empty vault, or when your desktop has files the server doesn't have yet.
- ***There may be differences between the files in this Vault and the server.*** Creates conflict markers for every file so you can manually review. Only pick this if both sides have important divergent content.

### Decision guide

- Fresh empty vault on desktop: pick **"This Vault is empty"**
- Existing desktop vault, want to keep its contents and merge with phone: pick **"This Vault is empty"** (LiveSync will treat local files as new and upload them)
- Restoring a backup on a new machine: pick **"almost identical to the server's"**
- Two diverged copies you want to reconcile carefully: pick **"There may be differences"**

For most first time second device setups, **"This Vault is empty, or contains only new files that are not on the server"** is correct.

Click **Proceed**.

## Step 10: Wizard Confirmations

The rest of the wizard mirrors the phone setup:

- ***Send all chunks before replication:*** tap **Yes** before the countdown expires.
- ***Fetch Remote Configuration Failed:*** tap **Skip and proceed** if it appears (it might not on a second device since the config doc now exists on the server).
- ***Optional features disabled:*** tap OK.
- ***Database size notification:*** tap **No, never warn please**.

## Step 11: Set Sync Mode to LiveSync

Same critical step as on mobile. If skipped, sync will be flaky.

1. Settings > Self-hosted LiveSync.
2. Click the **Sync Settings** tab (circular arrows icon).
3. Under **Synchronization Method**, find the **Sync Mode** dropdown.
4. Set it to **LiveSync**.

When LiveSync mode is active, the event based toggles (Sync on Save, Sync on Editor Save, etc.) vanish from the settings because they are no longer needed. The persistent WebSocket connection is always watching for changes.

## Step 12: Initial Sync Down

LiveSync now pulls the entire contents of `sharedvault` from the server into your desktop vault. This happens automatically after the wizard completes.

Watch the sync indicator in the top right. You should see the down arrow tick up (something like `↓28`) as documents are pulled, then return to `↓0 ↑0` when complete.

After initial sync completes, check the file tree on desktop. You should see all the folders and notes that were on the phone.

## Step 13: Verify Bidirectional Sync

This is the proof that everything is wired up correctly.

### Test 1: Desktop receives edits from phone

1. On phone, open any note.
2. Add a line of text like `hello from phone, cross device test`.
3. Tap away from the note to trigger save.
4. Watch the desktop. Within 2 to 3 seconds, the note should update with the new line.

### Test 2: Phone receives edits from desktop

1. On desktop, open the same note.
2. Add another line like `hello back from desktop`.
3. Save with `Ctrl+S` (or just click away, desktop auto saves on blur).
4. Watch the phone. Within 2 to 3 seconds, the note should update.

### Test 3: Create new file from desktop

1. On desktop, create a new note called `desktop-created.md`.
2. Type something.
3. Check the phone. The new file should appear in the file tree.

If all three tests pass, you have a fully functional bidirectional sync between phone and desktop.

## What to Do If Files Do Not Appear

Before troubleshooting, confirm two things:

1. Both devices show **Sync Mode: LiveSync** in their settings.
2. The encryption passphrase on desktop matches the passphrase on phone exactly.

If either is wrong, nothing below matters. Fix those first.

If both are correct and sync still does not work, jump to the troubleshooting guide. The most common cause is still a passphrase typo.

## What You Have Now

- Desktop Obsidian synced with CouchDB through the same `sharedvault` database as the phone
- Real time bidirectional sync verified working
- All vault changes on either device propagate to the other in about one second
- End to end encrypted content the server cannot read
- Zero reliance on Obsidian Sync subscription

## Adding More Devices

Every additional device (another phone, another laptop, a tablet, a work machine) follows the same pattern as this guide:

1. Install Obsidian
2. Install Self-hosted LiveSync plugin
3. Wizard → **Enter the server information manually**
4. Same URL, username, password, database name
5. **Paste** the encryption passphrase (never retype)
6. Set Obfuscate Properties to **true**
7. Wizard → **I am adding a device to an existing synchronisation setup**
8. Pick the correct reset sync option for that device's state (usually "Vault is empty")
9. Set Sync Mode to **LiveSync** after setup
10. Verify with a round trip edit test

Per vault access control lives in CouchDB's `_security` documents, so adding a new device for an existing user is just a matter of running the LiveSync wizard with their existing credentials. No new user needs to be created.

## Next Step

Proceed to **[07 - Adding More Users and Vaults](07-adding-users.md)** if you want to share vaults with other people while keeping each vault isolated.

If sync is working across all your devices and you do not need additional users, you can skip ahead to the **[troubleshooting guide](troubleshooting.md)** for reference, or **[08 - Monitoring and Maintenance](08-monitoring.md)** for ongoing care.