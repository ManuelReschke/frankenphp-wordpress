#!/usr/bin/env bash
# small entrypoint: fix permissions on mounted WordPress volume, then launch FrankenPHP
set -e

# UID/GID 33 corresponds to www-data inside the container
if [ -d /app/public ]; then
  echo "Fixing ownership of /app/public (WordPress volume) ..."
  chown -R 33:33 /app/public || true
fi

# hand off to FrankenPHP (Caddy) – pass through any additional args
exec frankenphp run --config /etc/caddy/Caddyfile "$@"
