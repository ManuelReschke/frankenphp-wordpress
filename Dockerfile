# Custom FrankenPHP + WordPress image
# --------------------------------------------------
# Based on the official FrankenPHP image but with
# WordPress core and all required PHP extensions baked in.
# This speeds-up container start-up and guarantees all
# dependencies are present in every environment.
# --------------------------------------------------

# 1. Base layer: FrankenPHP with PHP 8.4
FROM dunglas/frankenphp:php8.4 AS base

# 2. Install system dependencies for ImageMagick
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

# 2. Install WordPress-required PHP extensions
#    https://make.wordpress.org/hosting/handbook/server-environment/#php-extensions
RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    intl \
    mysqli \
    zip \
    opcache

# 3. Copy WordPress core files from the official upstream image
FROM wordpress:php8.4-fpm AS wordpress

FROM base AS final

# Copy configuration snippets and entrypoint from the WordPress image
COPY --from=wordpress /usr/local/etc/php/conf.d/* /usr/local/etc/php/conf.d/
COPY --from=wordpress /usr/local/bin/docker-entrypoint.sh /usr/local/bin/
COPY --from=wordpress --chown=root:root /usr/src/wordpress /usr/src/wordpress

# Application source lives here
WORKDIR /var/www/html
VOLUME /var/www/html

# Adjust permissions so that the non-root runtime user can manage Caddy/FrankenPHP storage
ARG USER=www-data
RUN chown -R ${USER}:${USER} /data/caddy && \
    chown -R ${USER}:${USER} /config/caddy

# Patch the standard WordPress entrypoint to use FrankenPHP
RUN sed -i \
    -e 's/\[ "$1" = '\''php-fpm'\'' \]/[[ "$1" == frankenphp* ]]/g' \
    -e 's/php-fpm/frankenphp/g' \
    /usr/local/bin/docker-entrypoint.sh

# Adapt the default Caddyfile so that the root path matches our WORKDIR
RUN sed -i \
    -e 's#root \* public/#root \* /var/www/html/#g' \
    /etc/caddy/Caddyfile

USER ${USER}

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
