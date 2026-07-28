#!/usr/bin/env bash
# Start as root: ensure runtime dirs + app user exist, then run FrankenPHP as HOST_UID:HOST_GID.
# WordPress bind-mount ownership is NOT rewritten on every start (use `make fix-perms` if needed).
set -e

HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"

if ! [[ "$HOST_UID" =~ ^[0-9]+$ && "$HOST_GID" =~ ^[0-9]+$ ]]; then
  echo "Invalid HOST_UID/HOST_GID ('${HOST_UID}:${HOST_GID}'); falling back to 1000:1000" >&2
  HOST_UID="1000"
  HOST_GID="1000"
fi

# Create matching group/user when missing (IDs must match the host developer account).
if ! getent group "${HOST_GID}" >/dev/null 2>&1; then
  groupadd --gid "${HOST_GID}" apphost
fi

if ! getent passwd "${HOST_UID}" >/dev/null 2>&1; then
  useradd --uid "${HOST_UID}" --gid "${HOST_GID}" --no-create-home \
    --home-dir /app --shell /usr/sbin/nologin appuser
fi

# Caddy/FrankenPHP state must be writable by the app user.
mkdir -p /data/caddy /config/caddy
chown -R "${HOST_UID}:${HOST_GID}" /data /config

# Optional escape hatch: FORCE_CHOWN=1 docker compose up … (or in .env)
if [ "${FORCE_CHOWN:-0}" = "1" ] && [ -d /app/public ]; then
  echo "FORCE_CHOWN=1: chown -R /app/public to ${HOST_UID}:${HOST_GID} ..."
  chown -R "${HOST_UID}:${HOST_GID}" /app/public || true
fi

if [ -d /app/public ] && ! gosu "${HOST_UID}:${HOST_GID}" test -w /app/public; then
  echo "Warning: /app/public is not writable by ${HOST_UID}:${HOST_GID}." >&2
  echo "         On the host run: make fix-perms" >&2
fi

echo "Starting FrankenPHP as ${HOST_UID}:${HOST_GID} ..."
exec gosu "${HOST_UID}:${HOST_GID}" frankenphp run --config /etc/caddy/Caddyfile "$@"
