# syntax=docker/dockerfile:1
ARG phpVersion=8.5
FROM composer:2 AS composer

FROM php:${phpVersion}-fpm
ARG WORKDIR=/var/www/html
ARG GROUP_ID=1000
ARG USER_ID=1000
ARG GROUP_NAME=www-data
ARG NODE_MAJOR=24

LABEL org.opencontainers.image.title="nginx-php-fpm" \
      org.opencontainers.image.description="Nginx and PHP-FPM image for Laravel and PHP applications" \
      org.opencontainers.image.source="https://github.com/jkaninda/nginx-php-fpm" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.authors="Jonas Kaninda"

ENV APP_DIR=${WORKDIR} \
    USER_NAME=www-data \
    NODE_MAJOR=${NODE_MAJOR} \
    DOMAIN=_ \
    CLIENT_MAX_BODY_SIZE=15M \
    LARAVEL_PROCS_NUMBER=1 \
    LARAVEL_QUEUE_WORKER_ENABLED=true \
    LARAVEL_QUEUE_OPTIONS="--sleep=3 --tries=3" \
    LARAVEL_SCHEDULER_ENABLED=true \
    PHP_DATE_TIMEZONE=UTC \
    PHP_DISPLAY_ERRORS=Off \
    PHP_MEMORY_LIMIT=256M \
    PHP_UPLOAD_MAX_FILESIZE=80M \
    PHP_POST_MAX_SIZE=80M \
    PHP_MAX_EXECUTION_TIME=30 \
    PHP_OPCACHE_ENABLE=1 \
    PHP_OPCACHE_ENABLE_CLI=0 \
    PHP_OPCACHE_MEMORY_CONSUMPTION=512 \
    PHP_OPCACHE_MAX_ACCELERATED_FILES=50000 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
    PHP_OPCACHE_REVALIDATE_FREQ=0 \
    PHP_FPM_PM=dynamic \
    PHP_FPM_PM_MAX_CHILDREN=20 \
    PHP_FPM_PM_START_SERVERS=2 \
    PHP_FPM_PM_MIN_SPARE_SERVERS=1 \
    PHP_FPM_PM_MAX_SPARE_SERVERS=3 \
    PHP_FPM_PM_MAX_REQUESTS=500

# Runtime tools, Nginx and Node.js
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg git openssh-client unzip zip \
        nginx supervisor cron sqlite3 nano; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends nodejs; \
    rm -rf /var/lib/apt/lists/*

# PHP extensions (build dependencies are purged, runtime libraries are kept)
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev \
        libicu-dev libmemcached-dev libonig-dev libpq-dev librdkafka-dev \
        libxml2-dev libzip-dev zlib1g-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j"$(nproc)" bcmath exif gd intl mbstring pcntl pdo_mysql pdo_pgsql zip; \
    pecl install redis memcached rdkafka; \
    docker-php-ext-enable redis memcached rdkafka; \
    # OPcache is always compiled in since PHP 8.5
    if ! php -m | grep -qi '^zend opcache$'; then docker-php-ext-install opcache; fi; \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark > /dev/null; \
    find /usr/local -type f \( -executable -o -name '*.so' \) -exec ldd '{}' ';' 2>/dev/null \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
        | sort -u | xargs -r dpkg-query --search | awk -F: '!/^diversion/ { print $1 }' | sort -u | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/* /tmp/pear ~/.pearrc; \
    ! php -m 2>&1 | grep -iE 'warning|unable to load'

COPY --from=composer /usr/bin/composer /usr/local/bin/composer

WORKDIR $WORKDIR

RUN rm -Rf /var/www/* /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default /etc/nginx/conf.d/default.conf && \
    mkdir -p ${WORKDIR} /etc/supervisor/conf.d /var/log/supervisor /var/log/nginx /var/cache/nginx /etc/nginx/conf.d

COPY src/index.php $WORKDIR/index.php
COPY src/php.ini src/opcache.ini $PHP_INI_DIR/conf.d/
COPY src/php-fpm.d/zz-nginx-php-fpm.conf /usr/local/etc/php-fpm.d/zz-nginx-php-fpm.conf
COPY src/nginx.conf /etc/nginx/nginx.conf
COPY src/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY --chmod=755 src/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN ln -s /usr/local/bin/entrypoint.sh /entrypoint.sh

RUN usermod -u ${USER_ID} ${USER_NAME} && \
    groupmod -g ${GROUP_ID} ${GROUP_NAME} && \
    touch /var/run/nginx.pid && \
    chown -R ${USER_NAME}:${GROUP_NAME} /var/www /var/log /tmp $PHP_INI_DIR/conf.d \
        /etc/supervisor/conf.d /etc/nginx/nginx.conf /etc/nginx/conf.d \
        /var/cache/nginx /var/lib/nginx /var/run/nginx.pid

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --start-interval=2s --retries=3 \
    CMD php -r 'exit(@fsockopen("127.0.0.1", 9000) && @fsockopen("127.0.0.1", 80) ? 0 : 1);'

EXPOSE 80
ENTRYPOINT ["entrypoint.sh"]
CMD ["entrypoint"]
