# Dovecot

Dovecot mail services for a virtual-mail deployment, built on
[`ghcr.io/nforceroh/alpine-base:3.24`](https://github.com/nforceroh/alpine-base)
and supervised by s6-overlay. The image includes IMAP, POP3, LMTP, submission,
ManageSieve, SQL authentication, and the Pigeonhole/Flatcurve plugins.

## Services and ports

| Port | Protocol | Purpose |
| --- | --- | --- |
| `24` | TCP | LMTP delivery |
| `110` | TCP | POP3 |
| `143` | TCP | IMAP |
| `993` | TCP | IMAPS |
| `3333` | TCP | doveadm service |
| `4190` | TCP | ManageSieve |
| `12345` | TCP | SASL authentication endpoint for Postfix |

The image health check verifies that IMAP is listening on port `143`.

## Storage and TLS

- `/data` is a Docker volume for mail and Sieve data.
- The default certificate paths are `/etc/dovecot/certs/tls.crt` and
  `/etc/dovecot/certs/tls.key`. Mount certificates there before starting the
  service.
- Optional DH parameters are read from `/etc/postfix/dh4096.pem`.
- Configuration is included in the image under `/etc/dovecot`; inspect and
  override it with a bind mount when your deployment requires different
  listeners or authentication behavior.

## Configuration

The following variables are declared by the Dockerfile:

| Variable | Image default | Description |
| --- | --- | --- |
| `LANG`, `LC_ALL` | `C.UTF-8` | Process locale |
| `UMASK` | `000` | Default file-creation mask |
| `PUID`, `PGID` | `3001`, `3000` | Base-image app-user settings |
| `TZ` | `America/New_York` | Container timezone |
| `DB_HOST` | `mariadb` | SQL server hostname |
| `DB_PORT` | `3306` | SQL server port |
| `DB_NAME` | `mail` | Mail database name |
| `DB_USER` | `user` | SQL account |
| `DB_PASS` | `password` | SQL password; replace with a runtime secret |
| `VMAIL_UID`, `VMAIL_GID` | `5000`, `12` | UID/GID returned for virtual-mail users |
| `FQDN` | `mail.example.com` | Declared value; not consumed by the bundled init script, which uses `HOSTNAME` |
| `RSPAMD_HOST` | `rspamd-svc` | Rspamd host used by the bundled Sieve learning scripts |
| `SKIP_FTS` | `n` | Set to `y` to skip enabling Flatcurve full-text search |
| `DEBUG` | `0` | Set above `0` for debug logging during initialization |

The initialization script also supports `HOSTNAME`, `POSTMASTER`,
`LOG_LEVEL`, `LOG_PATH`, `LOG_DEBUG_PATH`, `LOG_INFO_PATH`, `GREETING_TEXT`,
`SSL_CRT_FILENAME`, `SSL_KEY_FILENAME`, `DH_FILENAME`, `FTS_HEAP`,
`FTS_PROCS`, `DOVEADM_PASSWORD`, and `PASS_SCHEME`. Their script defaults are
used if they are omitted; see `content/s6-overlay/s6-rc.d/init-dovecot/run` for
the exact defaults and behavior.

The SQL authentication configuration expects the mail database schema,
including the `mailbox` table. Supply the database and TLS settings appropriate
to your deployment; the image defaults are examples, not production
credentials.

## Usage

Build and run locally:

```sh
make build
make run
```

For a deployment, provide the database credentials, mount the certificates and
persist mail data. This example publishes the service ports; restrict them to
the mail network and firewall as appropriate:

```sh
docker run -d --name dovecot \
  --restart unless-stopped \
  -p 24:24 -p 110:110 -p 143:143 -p 993:993 \
  -p 3333:3333 -p 4190:4190 -p 12345:12345 \
  -v dovecot-data:/data \
  -v "$PWD/certs:/etc/dovecot/certs:ro" \
  -e DB_HOST=mariadb \
  -e DB_NAME=mail \
  -e DB_USER=dovecot \
  -e DB_PASS='replace-with-a-secret' \
  -e HOSTNAME=mail.example.com \
  ghcr.io/nforceroh/dovecot:latest
```

Use your platform's secret mechanism instead of placing real passwords in
shell history or committed Compose files.

## Local development

```sh
make build   # build ghcr.io/nforceroh/dovecot:dev
make test    # build and run tests/run_tests.sh
make run     # publish the mail ports
```

The test harness covers image structure and initialization helpers; its TLS
fixture setup requires the test host's OpenSSL tooling. CI publishing is
handled by the shared workflow in
[`nforceroh/.github`](https://github.com/nforceroh/.github).
