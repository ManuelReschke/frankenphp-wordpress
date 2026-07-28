# Repository Guidelines

FrankenPHP + WordPress boilerplate: Docker stack with FrankenPHP (PHP 8.5), MariaDB, Dragonfly (Redis-compatible), and phpMyAdmin. Prefer Makefile targets over raw `docker compose` commands.

## Project Structure
- `docker-compose.dev.yml`, `docker-compose.prod.yml`: Compose templates. `docker-compose.yml` is generated via `make init-dev` / `make init-prod` and is gitignored.
- `Dockerfile`, `entrypoint.sh`: Image build and startup. Entrypoint drops to `HOST_UID:HOST_GID`, then runs FrankenPHP (no recursive chown on every start).
- `caddy/`: Caddy/FrankenPHP config (`Caddyfile`, `*.caddyfile`, `opcache.ini`). Site snippets use the `.caddyfile` suffix.
- `wordpress/`: WordPress source from `make install-wp` (gitignored). Do not commit local WP core changes unless intentional.
- `.env.example`: Env defaults; copy to `.env` (gitignored) and adjust.
- `Makefile`: Primary developer workflow entry point.
- `README.md`: User-facing docs (German).

## Stack & Ports (dev defaults)
| Service | Role | Port |
|---------|------|------|
| frankenphp | PHP 8.5 + Caddy (`dunglas/frankenphp:php8.5`) | 8080→80, 8443→443 |
| db | MariaDB 12 | 3306 |
| dragonfly | Redis-compatible object cache | 6379 |
| phpmyadmin | DB UI | 8081→80 |

WordPress install wizard: database host is `db` (not `localhost`).

## Build, Test, and Development Commands
Typical first-time / reset flow:
```bash
cp .env.example .env   # adjust credentials if needed
make install-wp        # fetch German WP (de_DE) into ./wordpress
make init-dev          # or: make init-prod
make build
make up
```

Common day-to-day targets:
```bash
make up              # start detached; print service URLs
make logs            # follow logs
make down            # stop/remove containers (volumes kept)
make restart
make clean           # full reset: containers, images, volumes, orphans
make fix-perms       # recovery: chown wordpress/ to HOST_UID/GID
make fix-perms-host  # write current user to .env HOST_* + fix-perms
make set-fs-direct   # inject FS_METHOD=direct into wp-config.php (container)
make urls            # print service URLs
make help            # list all targets
```

Also available: `make start`, `make stop`, `make build-no-cache`.

Smoke-check after changes:
- WordPress: `http://localhost:8080`
- phpMyAdmin: `http://localhost:8081` (credentials from `.env`)

No automated test framework is configured. If you add tests, document how to run them here.

## Coding Style & Naming Conventions
- YAML: 2-space indentation (match existing Compose files).
- Shell: Bash with `#!/usr/bin/env bash` and `set -e` (see `entrypoint.sh`).
- Filenames: lowercase with hyphens or dots (e.g. `docker-compose.dev.yml`, `site.caddyfile`).
- Prefer small, single-purpose changes to `entrypoint.sh`, Compose templates, and Caddy configs.
- Edit `docker-compose.dev.yml` / `docker-compose.prod.yml`, not a local generated `docker-compose.yml`, when changing the stack for the repo.

## Commit & Pull Request Guidelines
- Prefer Conventional Commits (`feat:`, `docs:`, `fix:`, …); recent history follows this style.
- PRs should include:
  - Brief summary and rationale
  - Verification commands (e.g. `make up`, `make logs`)
  - Updates to `README.md` or `.env.example` when user-facing config changes

## Security & Configuration
- Never commit `.env` or real credentials; keep defaults in `.env.example`.
- `wordpress/` and `docker-compose.yml` are gitignored.
- Permissions model: FrankenPHP/PHP runs as `HOST_UID`/`HOST_GID` from `.env` (match `id -u` / `id -g`). Bind-mounted `wordpress/` stays host-editable; new files (uploads, plugins) get that ownership. No recursive chown on every start. Recovery: `make fix-perms` or `FORCE_CHOWN=1` once.
- `make install-wp` pulls from `de.wordpress.org` (German locale) and leaves files owned by the current user.
