###############################
# Build FrankenPHP with Caddy plugins
###############################
FROM dunglas/frankenphp:1.13.0-builder-php8.5 AS caddy-builder

# Copy xcaddy from the official Caddy builder image
COPY --from=caddy:builder /usr/bin/xcaddy /usr/bin/xcaddy

# Build FrankenPHP with the Cloudflare DNS provider.
# Builder and runtime stay on the same PHP 8.5 tag so the binary matches libphp.
RUN CGO_ENABLED=1 \
    XCADDY_SETCAP=1 \
    XCADDY_GO_BUILD_FLAGS="-ldflags='-w -s' -tags=nobadger,nomysql,nopgx" \
    CGO_CFLAGS="$(php-config --includes)" \
    CGO_LDFLAGS="$(php-config --ldflags) $(php-config --libs)" \
    xcaddy build \
      --output /usr/local/bin/frankenphp \
      --with github.com/dunglas/frankenphp/caddy \
      --with github.com/caddy-dns/cloudflare \
      --with github.com/dunglas/caddy-cbrotli

###############################
# Runtime image with PHP + FrankenPHP
###############################
FROM dunglas/frankenphp:1.13.0-php8.5

# Replace the FrankenPHP binary with the plugin-enabled build
COPY --from=caddy-builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp

# System libs for GD, gosu (drop privileges), libcap2-bin (setcap for :80/:443)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    curl \
    gosu \
    libcap2-bin \
    && rm -rf /var/lib/apt/lists/* \
    && setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp \
    && gosu nobody true

RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

# Install required PHP extensions for WordPress
RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    intl \
    mysqli \
    zip \
    opcache \
    redis

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Entrypoint starts as root, then drops to HOST_UID:HOST_GID
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
