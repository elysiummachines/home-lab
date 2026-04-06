# Password and Secret Generation

A quick reference for generating random passwords, tokens, and keys for CouchDB (and most other self hosted services). Covers what strengths to use for what jobs and the common gotchas around special characters in URLs.

## The Base Command

```bash
openssl rand -base64 N
```

Generates `N` random bytes and base64 encodes them. The output length is always longer than `N` because base64 expands data at a 4 to 3 ratio.

## Reference Table

| Command | Random bytes | Output length | Entropy (bits) | Use case |
|---|---|---|---|---|
| `openssl rand -base64 24` | 24 | 32 chars | 192 | Admin passwords, user passwords, Basic Auth credentials |
| `openssl rand -base64 36` | 36 | 48 chars | 288 | API tokens, service secrets, longer lived credentials |
| `openssl rand -base64 44` | 44 | 60 chars | 352 | Encryption keys, JWT signing keys, paranoid territory |
| `openssl rand -base64 54` | 54 | 72 chars | 432 | Master keys, root encryption keys, key derivation input |

For context: 128 bits of entropy is considered cryptographically strong for essentially anything. 256 bits is overkill for almost every use case but provides future proofing against emerging attack models.

## Which One to Pick

### 24 bytes (~32 character output)

The sweet spot for anything a human might interact with: admin passwords you paste into a browser login, CouchDB user passwords, database credentials in config files.

Use when:

- Generating `COUCHDB_PASSWORD` for `.env`
- Creating user passwords for non admin accounts
- Anything that ends up in HTTP Basic Auth

### 36 bytes (~48 character output)

One notch stronger without being unwieldy. Good for credentials that live long term and are accessed programmatically rather than typed.

Use when:

- Generating API tokens for service to service calls
- Webhook secrets
- Long lived integration credentials

### 44 bytes (~60 character output)

Appropriate for actual cryptographic key material where algorithms spec out 256 bit or 384 bit keys.

Use when:

- Generating AES 256 key material
- JWT signing secrets for production apps
- Anything where you genuinely want cryptographic strength, not just a strong password

### 54 bytes (~72 character output)

Territory where you pick this because you want the biggest reasonable number, not because the use case requires it. Diminishing returns from here up.

Use when:

- Root keys that feed into key derivation functions
- Master secrets that unlock other secrets
- You want to not think about rotation for decades

## The URL Encoding Gotcha

Base64 output can contain these three characters that break URLs:

- ***`+`*** (plus) gets interpreted as a space in query strings
- ***`/`*** (forward slash) gets interpreted as a path separator
- ***`=`*** (equals) is valid in URLs but ugly when used for Basic Auth

This bites when you try to use a password in a URL embedded auth string:

```
http://admin:SUHUC3ddjSkqPbgqROR++GqQUWvjhZtJ@host/db
                                 ^^ breaks parsing
```

Some tools handle this fine by URL encoding the password automatically. Others (including a lot of `curl` invocations written by humans) just concatenate and hit errors.

### The fix: strip problem characters

```bash
openssl rand -base64 24 | tr -d '/+='
```

This strips `/`, `+`, and `=` from the output. You lose a few characters of length (usually 5 to 8), but:

- The remaining characters still carry plenty of entropy (around 140 bits from a 24 byte source after stripping)
- The resulting string works cleanly in URLs, config files, environment variables, and shell commands
- No special casing needed when passing the password to different tools

### When you do NOT need to strip

If the password only ever goes into:

- `.env` files read by Docker Compose
- HTTP `Authorization` headers constructed by curl via `-u user:pass`
- Password manager fields
- Any context where it is not being parsed as a URL

Then the `+`, `/`, `=` characters are fine to keep. They only cause issues when something tries to build a URL like `http://user:pass@host` from the password.

## Alternative Generators

### pwgen (if installed)

Generates easier to type passwords with mixed characters:

```bash
pwgen -s 32 1
```

The `-s` flag means "secure" (fully random). Without it, pwgen biases toward pronounceable patterns.

### Passphrase style from system wordlist

Generate memorable multi word passphrases for use cases where a human types them often (LiveSync encryption passphrases, for example):

```bash
shuf -n 4 /usr/share/dict/words | tr '\n' '-' | sed 's/-$//'
```

Produces something like `anchor-blanket-rocket-pepper`. Four random dictionary words gives roughly 50 bits of entropy, which is stronger than most 10 character passwords and dramatically easier to type and read aloud.

Strong choice for: the LiveSync E2E encryption passphrase, where you will type it on a mobile keyboard at least once.

### From /dev/urandom directly

If you want specific character classes:

```bash
tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 ; echo
```

Produces a 32 character alphanumeric string with no special characters at all. Nothing to strip, nothing to escape.

## Practical Examples for This Stack

### Admin CouchDB password (`.env`)

```bash
openssl rand -base64 24 | tr -d '/+='
```

Strip the URL problem characters because you might curl with `http://user:pass@localhost` during setup.

### Guest user password (shared with end users)

```bash
# Clean alphanumeric, easy to paste
tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20 ; echo

# Or memorable passphrase if they will type it often
shuf -n 4 /usr/share/dict/words | tr '\n' '-' | sed 's/-$//'
```

### LiveSync encryption passphrase

```bash
shuf -n 4 /usr/share/dict/words | tr '\n' '-' | sed 's/-$//'
```

Passphrase style wins here. You will need to paste it into multiple devices, and if your password manager ever fails you, a four word passphrase is much more recoverable than a 32 character random string.

### Cloudflare Tunnel service tokens, API keys, webhook secrets

```bash
openssl rand -base64 36 | tr -d '/+='
```

More entropy than user passwords because these often live a long time and are rarely rotated.

## Bcrypt Hashes for BasicAuth (htpasswd)

Some services expect credentials as a pre hashed string rather than plaintext. The most common case is Traefik's BasicAuth middleware, but the same applies to nginx `auth_basic`, Apache `.htpasswd` files, and any service that reads `htpasswd` style format.

### The base command

```bash
htpasswd -nB username
```

- ***`-n`*** prints the result to stdout instead of writing to a file
- ***`-B`*** uses bcrypt (strongest option, and what most modern services expect)
- ***`username`*** is the login name the hash will be associated with

You will be prompted for a password interactively. Output looks like:

```
username:$2y$05$abc123...xyzDEF
```

The colon separates the username from the bcrypt hash. This whole string is what downstream services consume.

### Non interactive variant

If you need to pass the password on the command line instead of being prompted:

```bash
htpasswd -nbB username 'your-plaintext-password'
```

- ***`-b`*** means "batch mode", take the password from the argument

Convenient for scripting, but the password ends up in your shell history. If you use this form, clean up afterward:

```bash
history -d $(history | tail -5 | grep 'htpasswd' | awk '{print $1}')
```

Or use the interactive `-nB` form and avoid the problem entirely.

### Installing htpasswd

If the command is missing, install it:

```bash
# Debian, Ubuntu
sudo apt install apache2-utils

# RHEL, Fedora, CentOS
sudo dnf install httpd-tools

# Alpine
apk add apache2-utils
```

### The Docker Compose escape trick

When pasting a bcrypt hash directly into a `docker-compose.yaml` label, every dollar sign must be escaped as a double dollar sign. Docker Compose performs variable substitution at parse time, so any single dollar sign followed by letters gets interpreted as an attempted variable reference, which mangles the hash.

The canonical one liner that generates the hash and escapes it in one step:

```bash
echo $(htpasswd -nB username) | sed -e 's/\$/\$\$/g'
```

Breaking it down:

- ***`htpasswd -nB username`*** generates the hash and prompts for the password
- ***`echo $(...)`*** captures the output (the `echo` is mildly redundant but convenient)
- ***`sed -e 's/\$/\$\$/g'`*** doubles every dollar sign so Docker Compose treats them as literal

Output looks like:

```
username:$$2y$$05$$abc123...xyzDEF
```

Paste that directly into a compose label:

```yaml
labels:
  "traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_DASHBOARD_CREDENTIALS}"
```

### When you need the escape and when you do not

| Destination for the hash | Need the dollar sign escape? |
|---|---|
| Docker Compose label (inline) | Yes |
| Docker Compose `.env` file referenced via a variable | Yes (escape inside the `.env` value) |
| Traefik file provider config (`config.yml`, `dynamic.yml`) | No |
| nginx `.htpasswd` file referenced via `auth_basic_user_file` | No |
| Kubernetes Secret (stringData field) | No |
| Plain shell variable assignment | No |

The pattern: if Docker Compose will parse the value, escape the dollar signs. Everywhere else, use the raw `htpasswd` output.

### Example: Traefik BasicAuth in Docker Compose

Full flow from zero to working BasicAuth middleware:

```bash
# Generate the hash (prompts for password, you will paste output into compose)
echo $(htpasswd -nB admin) | sed -e 's/\$/\$\$/g'
```

Copy the output and use it as a compose label:

```yaml
services:
  myservice:
    image: someimage
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.example.com`)"
      - "traefik.http.routers.myservice.middlewares=myservice-auth"
      - "traefik.http.middlewares.myservice-auth.basicauth.users=admin:$$2y$$05$$...your-hash-here..."
```

### Example: Traefik BasicAuth via .env file

Same principle, but the hash goes in `.env`:

```bash
# .env
TRAEFIK_DASHBOARD_CREDENTIALS=admin:$$2y$$05$$...your-hash-here...
```

And the compose label references it:

```yaml
labels:
  - "traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_DASHBOARD_CREDENTIALS}"
```

The escape still applies in the `.env` file because Compose substitutes the variable and then processes the result, at which point the doubled dollars collapse to single dollars.

### Example: Traefik file provider (no escape)

When using Traefik's file provider instead of Docker labels, the hash is in a regular YAML or TOML config file that Compose never touches. Use the raw output:

```bash
# No sed needed, no dollar sign escape
htpasswd -nB admin
```

Paste into `config.yml`:

```yaml
http:
  middlewares:
    admin-auth:
      basicAuth:
        users:
          - "admin:$2y$05$...your-hash-here..."
```

Single dollar signs are correct here because Traefik reads the file directly without any interpolation layer.

### Why bcrypt specifically

`htpasswd` supports several hash algorithms (MD5, SHA, bcrypt, crypt). Use bcrypt (`-B`):

- ***MD5 and SHA1*** are cryptographically broken and fast to brute force
- ***crypt*** uses DES which is extremely weak
- ***bcrypt*** is designed to be slow, configurable via work factor, and is the current standard for password storage

There is no reason to use anything other than bcrypt for new deployments.

## Saving Generated Secrets

Every secret you generate should immediately go to one of these places:

- ***Password manager*** for anything you will need to paste again (admin password, user passwords, encryption passphrases)
- ***`.env` file with `chmod 600`*** for secrets consumed by local services
- ***Secret manager*** (Vault, Bitwarden, 1Password CLI, Doppler, etc.) for production or shared environments

Never commit secrets to a git repo, even a private one. Use `.gitignore` to exclude `.env` files and always double check `git status` before committing.

## Verifying a Password Survived Round Trip

After generating and storing, confirm the password works before needing it under pressure:

```bash
# Generate
PW=$(openssl rand -base64 24 | tr -d '/+=')
echo "$PW"

# Save to password manager, .env file, etc.

# Test authentication
curl -u "admin:$PW" http://localhost:5984/

# Unset and clear history when done
unset PW
history -c
```

If the curl succeeds, the password is correctly stored and usable. Better to catch a typo now than at 2am when something breaks.

## Summary

For almost every self hosted scenario:

```bash
openssl rand -base64 24 | tr -d '/+='
```

Strong enough, clean enough, short enough. Only reach for longer when the job specifically calls for cryptographic key material rather than a password.

For user facing passphrases where typing matters:

```bash
shuf -n 4 /usr/share/dict/words | tr '\n' '-' | sed 's/-$//'
```

Stronger than most typed passwords and dramatically more usable.

For BasicAuth credentials consumed by Traefik, nginx, or similar:

```bash
# In Docker Compose (escape dollar signs)
echo $(htpasswd -nB username) | sed -e 's/\$/\$\$/g'

# Anywhere else (raw output)
htpasswd -nB username
```