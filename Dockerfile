# FrankenPHP + PHP extensions only
FROM dunglas/frankenphp:php8.5

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
