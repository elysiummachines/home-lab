# Mobile Setup (First Device)

This guide covers installing the Self-hosted LiveSync plugin on Obsidian mobile and connecting it to your CouchDB backend. This first device becomes the "master" that uploads its vault contents to the server. Every subsequent device will join as a secondary and pull those contents down.

The mobile Obsidian app is available for both iOS and Android. The setup flow is nearly identical on both platforms.

## Before You Start

Have these ready:

- ***The Cloudflare Tunnel URL*** from the previous guide, for example `https://couchdb.yourdomain.com`
- ***The vault database name*** you created in the user setup guide, for example `sharedvault`
- ***The user credentials*** for that vault, for example username `guestuser` and its password
- ***A password manager*** open and ready. You will generate an encryption passphrase during setup that must be saved safely and copied exactly to every other device later.
- ***A notes app on the phone*** for temporarily holding the passphrase so you can paste it instead of typing it.

## Step 1: Create or Open a Vault in Obsidian Mobile

When you first open the Obsidian app, it shows a screen with three big cards: Sync, iCloud, and Other. These are Obsidian's paid cloud offerings and the iOS specific option. Ignore all three.

Look for a smaller link or button labeled **Create new vault**. It is usually below the big cards or in a corner. Tap it.

1. Name the vault something meaningful, for example `MyVault`.
2. Choose a location if prompted. Defaults are fine.
3. Tap **Create**.

You will land in an empty vault. This is where LiveSync will install into.

## Step 2: Enable Community Plugins

1. Tap the gear icon to open Settings.
2. Scroll down to **Community plugins** in the left sidebar.
3. Tap **Turn on community plugins**.
4. Accept the warning that appears. Community plugins run third party code, so the warning is just standard due diligence.

## Step 3: Install Self-hosted LiveSync

1. Still in Community plugins, tap **Browse**.
2. Search for `Self-hosted LiveSync`.
3. Tap it in the results.
4. Tap **Install**.
5. When installation finishes, tap **Enable**.

The plugin is now loaded. Back out to the main Settings screen. You should see **Self-hosted LiveSync** as a new entry in the left sidebar.

## Step 4: Open the Setup Wizard

1. Tap **Self-hosted LiveSync** in the left sidebar.
2. You will see a welcome screen. Tap **Setup Wizard** or follow the prompt that says `I am setting this up for the first time`.

The wizard walks through several screens. Each is covered below.

## Step 5: Connection Method

The wizard asks how you want to configure the connection:

- ***Use a Setup URI (Recommended):*** This option expects a pre generated blob from LiveSync's own installation script. We did not use that script, so this does not apply.
- ***Enter the server information manually:*** Pick this one.

Tap **Proceed with Manual Configuration**.

## Step 6: Server Configuration

Fill in the fields exactly as shown:

| Field | Value |
|---|---|
| URI | `https://couchdb.yourdomain.com` (no trailing slash) |
| Username | `guestuser` |
| Password | the password you set for guestuser |
| Database name | `sharedvault` |

Tap **Test Connection** or **Next**.

Expected result: a green success message. If it fails, jump to the troubleshooting guide. The most common cause is a typo in one of the fields.

## Step 7: End to End Encryption (CRITICAL)

This screen is the single most important step in the entire setup. Pay attention.

1. ***Check the End-to-End Encryption box.***
2. ***Enter a passphrase in the text field that appears.*** Pick something strong but memorable. A four word random passphrase works well, for example `anchor-blanket-rocket-pepper`.
3. ***Check the Obfuscate Properties box.*** Also called Property Encryption. This encrypts filenames, paths, and timestamps so the server only sees opaque hashes, not note titles or folder structure.

### Save the passphrase NOW

Before tapping Proceed, save the passphrase to a password manager. Right now. Not later.

Why this matters:

- ***The passphrase is unrecoverable.*** It never leaves your devices. If you lose it, every encrypted document on the server becomes permanently unreadable garbage.
- ***Every future device needs the exact same passphrase.*** A single character mismatch causes sync to silently fail. The plugin does not throw a clear error. It just encrypts everything with the wrong key and your files stop appearing on the broken device.

### Best practice for entering the passphrase

Type the passphrase into a notes app on your phone first. Then copy it from that notes app and paste it into the LiveSync passphrase field. Also paste it into your password manager right now. This ensures all three copies match exactly with no risk of an autocorrect or typo.

Tap **Proceed** when the passphrase is saved.

## Step 8: Confirm Master Copy Overwrite

The next screen warns about overwriting server data. It says something like:

> The synchronisation data on the server will be built based on the current data on this device. After restarting, the data on this device will be uploaded to the server as the 'master copy'. Please be aware that any unintended data currently on the server will be completely overwritten.

This sounds scary but is correct and expected for a first device setup. The CouchDB database is empty, so there is nothing to overwrite. Your phone's vault becomes the authoritative source.

Tap **Restart and Initialize Server** (or similar).

## Step 9: Final Confirmation Checkboxes

A second confirmation screen appears with several checkboxes:

- ☑️ `I understand that all changes made on other smartphones or computers possibly could be lost.`
- ☑️ `I understand that other devices will no longer be able to synchronise, and will need to be reset.`
- ☑️ `I understand that this action is irreversible once performed.`

Tick all three. On a fresh setup these warnings do not apply to you because there are no other devices yet.

Below the checkboxes, pick a backup option:

- ***I have created a backup of my Vault:*** pick this if you want to be safe. Close the wizard, copy your vault folder somewhere safe, then come back and pick this.
- ***I understand the risks and will proceed without a backup:*** fine for a fresh or empty vault where you have nothing to lose. This is what most first time setups use.

Leave the **Prevent fetching configuration from server** checkbox unchecked.

Tap **I Understand, Overwrite Server**.

## Step 10: Send Chunks Before Replication

A dialog appears asking:

> Do you want to send all chunks before replication?

The dialog has a countdown timer defaulting to No. Tap **Yes** before the countdown reaches zero.

What this means: LiveSync splits vault contents into metadata documents (one per file) and content chunks (the actual encrypted data, deduplicated). When Yes, chunks are uploaded first, then metadata. This guarantees that when metadata docs land on the server, all the chunks they reference already exist. Cleaner for a fresh master upload.

## Step 11: Fetch Remote Configuration

You will see a dialog titled **Fetch Remote Configuration Failed** with a message like:

> Could not fetch configuration from remote. If you are new to the Self-hosted LiveSync, this might be expected.

This is normal. LiveSync stores a shared config document inside the database so future devices can pick up your settings automatically. On a brand new database, that document does not exist yet. Your phone is about to create it.

Tap **Skip and proceed**. Do not tap Retry, it will just fail again for the same reason.

## Step 12: Optional Features Disabled

A notice appears telling you that two optional features are disabled:

- ***Customization Sync:*** syncs your Obsidian app settings and enabled plugins across devices
- ***Hidden File Sync:*** syncs the full `.obsidian/` folder including workspace layouts and plugin configs

Leave both disabled for now. You can turn them on later from the LiveSync settings once core sync is confirmed working. Enabling them during initial setup is a common source of weird cross device behavior.

Tap **OK**.

## Step 13: Database Size Notification

A dialog asks whether you want a warning when the server database exceeds a size threshold. Options include 800MB, 2GB, and others.

Those thresholds exist for people using hosted CouchDB services with free tier quotas (like Cloudant or fly.io). You are self hosting on disk you own, so none of them apply.

Tap **No, never warn please**.

## Step 14: Set Sync Mode to LiveSync (Critical Step)

This step is easy to miss and if skipped, sync will be flaky.

The wizard drops you in the LiveSync settings. Find the tab with a pair of circular arrows icon (Sync Settings). Tap it.

Under **Synchronization Method**, find the **Sync Mode** dropdown.

Set it to **LiveSync**.

What this does: LiveSync mode establishes a persistent WebSocket connection to CouchDB. Changes propagate in roughly one second both ways. When LiveSync mode is active, the event based toggles (Sync on Save, Sync on Startup, etc.) disappear from the settings because they are no longer relevant. The persistent connection is always watching.

Without this step, sync runs in event based mode by default, which relies on explicit triggers (save events, app startup, etc.) and is flaky on mobile where Obsidian does not always fire those events when you expect.

## Step 15: Verify Sync Is Working

Look at the top right of the Obsidian interface. You should see a sync status indicator showing something like `Sync: 🟢 ↑0 ↓0` with a filled or green circle indicating the WebSocket is connected.

Create a test note:

1. Tap the **new note** icon (usually a pencil or plus button).
2. Name it `test-sync`.
3. Type something in the body like `hello from my phone`.
4. Tap elsewhere or switch to another note to trigger a save.

Watch the sync indicator. You should briefly see the up arrow count increment (like `↑3` for a moment) then return to `↑0 ↓0` when the push completes.

### Verify on the server

On the CouchDB host, check that the database doc count went up:

```bash
cd /compose/couchdb
ADMIN_USER=$(grep COUCHDB_USER .env | cut -d= -f2)
ADMIN_PW=$(grep COUCHDB_PASSWORD .env | cut -d= -f2)
curl -u "$ADMIN_USER:$ADMIN_PW" http://localhost:5984/sharedvault | grep -oE '"doc_count":[0-9]+'
```

Expected: something greater than zero. Typical values after one small test note are between 3 and 10 because LiveSync stores metadata docs, chunks, and a config document.

If the number is greater than zero, your phone is successfully pushing data to CouchDB. Sync is working.

## What You Have Now

- Obsidian mobile with LiveSync installed and configured
- End to end encryption enabled with a passphrase saved in your password manager
- Property obfuscation enabled so the server sees no filenames or paths
- Sync Mode set to LiveSync for real time propagation
- First test note successfully pushed to CouchDB
- A working foundation for adding more devices

## Credentials to Save Before Moving On

Make absolutely sure these are saved in a password manager before setting up your next device:

- ***CouchDB URL:*** `https://couchdb.yourdomain.com`
- ***Username:*** `guestuser`
- ***Password:*** the guestuser password
- ***Database name:*** `sharedvault`
- ***End-to-End Encryption passphrase:*** the passphrase you set in Step 7

Every future device needs all five of these, with the passphrase matching exactly.

## Next Step

Proceed to **[06 - Desktop Setup](06-desktop-setup.md)** to add your desktop or laptop as a second device. The setup is similar but differs in one critical place: the second device joins as a client, not a master. Picking the wrong option there wipes the data you just uploaded.