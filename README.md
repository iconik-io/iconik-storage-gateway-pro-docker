# ISG Cluster setup via docker

## Overview

The repository contains tools to help with a simple ISG Cluster deployment.

There are two docker compose files:
- `docker-compose.yml` - runs a single ISG Pro node together with the network database services (postgres + pgbouncer).
- `docker-compose.database.yml` - runs only the network database services (postgres + pgbouncer).

Follow this README from top to bottom.

## Prerequisites

- Docker Engine and Docker Compose v2 installed on the host.
- An iconik account with permission to administer ISG clusters.
- Windows is currently not supported.

## Security warnings

- **Change all default values before running in production.** In particular, replace `POSTGRES_PASSWORD=my_password` from `.env.example` with a strong password.
- **Do not expose pgbouncer to the public internet without a firewall.** `PGBOUNCER_HOST=0.0.0.0` will publish it on every interface - only do that behind a firewall.

## Create the ISG cluster in iconik

Before starting the containers, create an ISG cluster at https://app.iconik.io/admin/isg/ and note the main node id - you'll put that into `.env` as `ICONIK_STORAGE_GATEWAY_ID`.

## Environment file

Copy the example:
`cp .env.example .env`

and populate `.env` with real values. Example:
```
POSTGRES_PASSWORD=my_strong_password
POSTGRES_USER=postgres
POSTGRES_DB=isg_db

PGBOUNCER_HOST=0.0.0.0
PGBOUNCER_PORT=6432

NAS_STORAGE_PATH=/Volumes/my_network_storage

ICONIK_APP_ID=9905c5be-268e-11e7-b1c7-6c4008b85488
ICONIK_AUTH_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
ICONIK_URL=https://app.iconik.io/
ICONIK_STORAGE_GATEWAY_ID=05bf723c-272c-11f1-adfe-5aad1d0b1af7
```

What each variable does:
- `POSTGRES_*` - credentials for the embedded postgres database.
- `PGBOUNCER_HOST` / `PGBOUNCER_PORT` - host interface and port on which pgbouncer is published. This is the address other ISG cluster nodes (running elsewhere) connect to.
- `NAS_STORAGE_PATH` - host path bind-mounted to `/mnt/storage` inside the ISG container; this is where iconik will read and write media files.
- `ICONIK_*` - credentials and identifiers for the iconik tenant and the cluster you created in the step above.

## Config.ini template

Edit `config.ini.template` directly to customize ISG node settings. The file is bind-mounted into the container and rendered into the actual `config.ini` at start time, with env vars from `.env` substituted by `envsubst`. For the full list of available knobs, see https://help.iconik.backlight.co/hc/en-us/articles/25304290297239-ISG-Advanced-Options.

If a required env var (e.g. `ICONIK_AUTH_TOKEN`) is missing from `.env`, `envsubst` will render an empty value and ISG will fail to start - check the container logs to spot this.

To apply template changes without rebuilding the image:

`docker compose restart isg-node-main`

## Docker compose (ISG node + database)

Start the ISG cluster node together with the database and connection pooler:

`docker compose --env-file .env up -d`

The image is built automatically on first `up`. Rebuild only when the `Dockerfile` itself changes - edits to `.env` or `config.ini.template` do not require a rebuild:

`docker compose build --no-cache`

Verify everything is healthy:

```
docker compose ps
docker compose logs -f isg-node-main
```

### How the cluster pieces fit together

All ISG nodes - the one running in this compose file and any additional worker nodes you add later - connect to the same network database. That database is how ISG coordinates and distributes jobs across the cluster. The main node is responsible for polling events from iconik and for handling jobs that haven't yet been picked up by a worker.

Worker nodes connect to the database using a standard postgres connection string (see https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING-URIS). Example:

`postgres://postgres:my_strong_password@my_main_host:6432/isg_db`

## Docker compose (database only)

`docker-compose.database.yml` runs only postgres + pgbouncer, with no ISG node. Use this when you want the database to live on its own host and install the ISG node directly on each worker machine (instead of in a container). Refer to iconik's ISG install documentation for how to set up a host-installed node.

Start the database and connection pooler:

`docker compose --env-file .env -f docker-compose.database.yml up -d`

## PgBouncer minimum requirements

A few pgbouncer settings are dictated by how ISG operates and should not be relaxed:

- `POOL_MODE=transaction` - pool mode must be at least transaction-level. Switching to session-level pooling will break the application.
- `MAX_CLIENT_CONN=1000` - the limit must stay high. ISG can open many connections at once (this is expected to improve in future releases). When you add worker nodes, raise `MAX_CLIENT_CONN` accordingly - roughly +50 per worker is a safe starting point, though the exact number depends on worker configuration.
- `AUTH_TYPE=scram-sha-256` - keep `AUTH_TYPE` set to a real authentication method. Do not set it to `trust`, which disables authentication entirely.

## SSL support

By default the connection between client and server is not encrypted. To enable SSL between ISG nodes and the database, see the PostgreSQL docs: https://www.postgresql.org/docs/current/libpq-ssl.html
