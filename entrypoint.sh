#!/usr/bin/env bash
# small entrypoint: fix permissions on mounted WordPress volume, then launch FrankenPHP
set -e

# Default to www-data (33:33) unless the host overrides via env
HOST_UID="${HOST_UID:-33}"
HOST_GID="${HOST_GID:-33}"
if ! [[ "$HOST_UID" =~ ^[0-9]+$ && "$HOST_GID" =~ ^[0-9]+$ ]]; then
  echo "Invalid HOST_UID/HOST_GID; falling back to 33:33" >&2
  HOST_UID="33"
  HOST_GID="33"
fi

if [ -d /app/public ]; then
  echo "Fixing ownership of /app/public (WordPress volume) to ${HOST_UID}:${HOST_GID} ..."
  chown -R "${HOST_UID}:${HOST_GID}" /app/public || true
fi

# hand off to FrankenPHP (Caddy) – pass through any additional args
exec frankenphp run --config /etc/caddy/Caddyfile "$@"
