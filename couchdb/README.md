## CouchDB Wiki:

**Apache CouchDB is an open-source, document-oriented NoSQL database that stores data as JSON documents and exposes every operation over a plain HTTP API**. Unlike relational databases that organize data into tables and rows, CouchDB treats each record as a self-contained JSON document with a unique ID and a full revision history, making it especially well-suited for distributed and offline-first applications.

**CouchDB is written in Erlang and was built from the ground up around multi-master replication, meaning any CouchDB instance can sync with any other instance, including mobile devices running PouchDB, its JavaScript sibling**. Licensed under `Apache-2.0` CouchDB is maintained by the Apache Software Foundation and has a long track record of production use in applications that require reliable peer-to-peer data sync.

**CouchDB stands out due to its robust replication model, eventual consistency guarantees, and its "Couch Replication Protocol" which allows seamless data synchronization between servers, browsers, and mobile apps even across unreliable networks**. Its HTTP-native interface means every operation is a standard `GET`, `PUT`, `POST`, or `DELETE` request. No special drivers, no proprietary protocols, no complex client libraries. This makes CouchDB trivial to put behind a reverse proxy, tunnel, or load balancer, and uniquely positions it as the backend of choice for self-hosted Obsidian sync via the Self-hosted LiveSync plugin.

## Security & Compliance:

- ***HTTP Basic Authentication*** - CouchDB uses standard HTTP Basic Auth for all requests, with passwords stored as salted PBKDF2 hashes in the internal `_users` system database.
- ***Per-Database Access Control*** - Each database has a `_security` document that defines which users and roles can read or write, enabling strict isolation where one user can be granted access to their vault and blocked from all others.
- ***TLS Termination at the Edge*** - When exposed via Cloudflare Tunnel, all external traffic is encrypted in transit and TLS certificates are managed automatically by Cloudflare, with no ports opened on the host firewall.
- ***Client-Side End-to-End Encryption*** - When paired with the LiveSync plugin, vault data is encrypted on the client before being sent to CouchDB, so even a full database compromise exposes only opaque encrypted blobs.
- ***Audit-Friendly Revision History*** - Every document in CouchDB retains its full revision chain, which aids in debugging, conflict resolution, and recovery from accidental changes.

## Important Note:

- (`Do NOT`) expose CouchDB to the public internet without authentication enabled (`require_valid_user = true` in `local.ini`). An open CouchDB instance is trivially discoverable and will be compromised within hours. Always enable HTTP Basic Auth, set a strong admin password, and lock individual databases with `_security` documents so authenticated users only see the data they are explicitly granted access to.

## Key Features:

- ***Document-Oriented Storage*** - Each record is a self-contained JSON document, eliminating the need for schemas, migrations, or rigid table structures.
- ***Multi-Master Replication*** - Built-in bidirectional replication between any CouchDB instance (or PouchDB client), with automatic conflict detection and resolution.
- ***HTTP API*** - Every operation is a standard REST call, making CouchDB easy to integrate with any language, tool, or reverse proxy without special drivers.
- ***Fauxton Web UI*** - A browser-based admin interface at `/_utils/` for managing databases, documents, users, and replication tasks.
- ***MVCC Concurrency*** - Multi-Version Concurrency Control means readers and writers never block each other, and every change creates a new document revision with full history.
- ***Offline-First Design*** - Clients can work offline and sync changes later; the replication protocol handles merge and conflict cases gracefully.

## Best Practices:

- ***Enable CORS for Browser/Mobile Clients*** - Mobile Obsidian and other browser-based PouchDB clients require CORS to be configured in `local.ini` with the correct origins before the first boot of the container.
- ***Use Per-User Databases*** - Give each user their own database and lock it down with a `_security` document. Do not share a single database across multiple independent users unless they are explicitly collaborating on the same data.
- ***Run Compaction Periodically*** - CouchDB retains old revisions indefinitely by default; run `_compact` on large databases periodically to reclaim disk space.
- ***Avoid Special Characters in Admin Passwords*** - Characters like `+`, `/`, `=`, `@`, and `:` can break URL-embedded authentication; use `-u user:pass` with curl, or strip those characters when generating the password.
- ***Back Up the Data Directory*** - The entire state of CouchDB lives in its `data` directory; a simple rsync or snapshot of this folder (with the container stopped) is a valid backup.
- ***Don't Use `curl` in Healthchecks*** - The official `couchdb:3` image does not ship with `curl`; use the bash `/dev/tcp` built-in instead to avoid false-negative unhealthy containers.


##
> One cool thing about CouchDB is its replication-first architecture. Unlike most databases where replication is an optional add-on, CouchDB was designed around the assumption that data will live in many places and need to stay in sync, whether those places are other servers, web browsers, or mobile devices. The same Couch Replication Protocol that syncs two servers across a data center also syncs your phone's Obsidian vault with your desktop through a Cloudflare Tunnel. This makes CouchDB uniquely suited for offline-first and edge-distributed applications, where clients need to keep working without a connection and reconcile their state later. For self-hosted Obsidian users, this turns a database server into a real-time, conflict-aware sync engine without any custom code.