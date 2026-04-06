# Prerequisites

Before setting up CouchDB for Obsidian sync, make sure you have the following in place. Missing any of these will cause you to hit walls partway through the setup.

## Host Requirements

- ***Linux server or VM*** - Anything that can run Docker works. A small VM (2 vCPU, 2 GB RAM, 20 GB disk) is more than enough for personal use with multiple vaults.
- ***Docker + Docker Compose*** - Docker Engine 20.10 or newer with the Compose v2 plugin. Verify with `docker --version` and `docker compose version`.
- ***Port 5984 free*** - CouchDB's default port. Check with `ss -tlnp | grep 5984` to make sure nothing else is bound to it.
- ***Disk space*** - Minimum 1 GB free for the container and data directory. Vault size depends on your content; plan for at least 5 GB for growth.

## Network Requirements

- ***Cloudflare account*** - Free tier is fine. You need a domain already on Cloudflare so you can add a tunnel hostname to it.
- ***Cloudflare Tunnel*** - Either already set up on your host, or you are willing to set one up. This guide assumes `cloudflared` is running somewhere that can reach your CouchDB container (same host is simplest).
- ***Outbound HTTPS to Cloudflare*** - Your host needs to be able to make outbound connections to `*.cloudflare.com` on port 443 for the tunnel to establish.

## Client Requirements

- ***Obsidian installed*** - On each device you want to sync (phone, desktop, laptop). Free from [obsidian.md](https://obsidian.md/) or your own KSM Docker compose instance. 
- ***Community plugins enabled*** - You will install the Self-hosted LiveSync plugin later; community plugins must be enabled inside each vault.

## Knowledge Prerequisites

You should be comfortable with:

- Running shell commands as a non-root user on a Linux host
- Editing files with `nano` or `vim`
- Basic Docker concepts (containers, volumes, ports, environment variables)
- Reading container logs to diagnose issues
- Using `curl` to make HTTP requests with authentication

You do NOT need to know anything about CouchDB, Erlang, NoSQL databases, or Obsidian's internals. This setup is purely declarative and every step is documented.

## What You Will NOT Need

- ***Reverse proxy (Traefik, nginx, Caddy)*** - Cloudflare Tunnel replaces the need for one entirely.
- ***Let's Encrypt certificates*** - Cloudflare handles TLS at the edge.
- ***Public DNS records*** - The tunnel creates its own DNS entry.
- ***Firewall port forwarding*** - The tunnel dials out from your host; no inbound ports need to be opened.
- ***Obsidian Sync subscription*** - This entire stack replaces it.

## Recommended Tooling

- ***Password manager*** - Bitwarden, 1Password, KeePass, or equivalent. You will generate several passwords and one critical encryption passphrase; storing them safely is mandatory.
- ***SSH client*** - Needed to reach the host where CouchDB runs.
- ***A notes app on your phone*** - For pasting the encryption passphrase during setup. Typing it manually on a mobile keyboard is the single most common cause of broken sync.

## Directory Layout

This guide assumes you will place the CouchDB stack at `/compose/couchdb/` on the host. If your convention is different (e.g. `/opt/docker/` or `~/docker/`), substitute accordingly throughout the docs.

```
/compose/couchdb/
├── docker-compose.yaml
├── .env
├── config/
│   └── local.ini
└── data/
    └── (CouchDB's internal state - created automatically)
```

## Next Step

Once the above is in place, proceed to **[02 - Server Setup](02-server-setup.md)** to create the container, configure CouchDB, and run the one-time cluster initialization.