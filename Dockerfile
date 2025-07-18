# FrankenPHP + PHP extensions only
FROM dunglas/frankenphp:php8.4

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

# Use entrypoint to fix permissions then launch FrankenPHP
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
