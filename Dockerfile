FROM php:7.2-fpm
ENV WORKDIR=/var/www/html
ENV STORAGE_DIR=${WORKDIR}/storage
ENV DOCUMENT_ROOT=${WORKDIR}
ENV LARAVEL_PROCS_NUMBER=2
ENV DOMAIN=_
ENV CLIENT_MAX_BODY_SIZE=15M
# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmemcached-dev \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    librdkafka-dev \
    libpq-dev \
    openssh-server \
    zip \
    unzip \
    supervisor \
    sqlite3  \
    nano \
    cron
# Install nginx 
RUN apt-get update && apt-get install -y nginx

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions zip, mbstring, exif, bcmath, intl
RUN docker-php-ext-configure gd
RUN docker-php-ext-install  zip mbstring exif pcntl bcmath -j$(nproc) gd intl

# Install Redis and enable it
RUN pecl install redis  && docker-php-ext-enable redis



# Install the php memcached extension
RUN pecl install memcached && docker-php-ext-enable memcached

# Install the PHP pdo_mysql extention
RUN docker-php-ext-install pdo_mysql

# Install the PHP pdo_pgsql extention
RUN docker-php-ext-install pdo_pgsql


# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Laravel Envoy
RUN composer global require "laravel/envoy=~1.0"

# Set working directory
WORKDIR $WORKDIR

# nginx site conf
RUN rm -Rf /var/www/* && \
mkdir /var/www/html/

ADD src/index.php $WORKDIR/index.php
ADD src/conf/nginx/default.conf /etc/nginx/sites-available/default
ADD src/php.ini $PHP_INI_DIR/conf.d/

COPY ./entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN ln -s /usr/local/bin/entrypoint.sh /

ENTRYPOINT ["entrypoint.sh"]



RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data

RUN chmod -R 755 $WORKDIR
RUN chown -R www-data:www-data $WORKDIR
EXPOSE 9000
CMD [ "entrypoint" ]
