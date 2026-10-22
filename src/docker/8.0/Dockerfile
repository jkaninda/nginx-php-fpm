FROM php:8.0-fpm
ARG WORKDIR=/var/www/html
ENV LARAVEL_PROCS_NUMBER=1
ENV APP_DIR=/var/www/html \
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
    PHP_OPCACHE_REVALIDATE_FREQ=0
ENV DOMAIN=_
ENV CLIENT_MAX_BODY_SIZE=15M
ENV NODE_VERSION=17.x
ARG GROUP_ID=1000
ARG USER_ID=1000
ENV USER_NAME=www-data
ARG GROUP_NAME=www-data
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

RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -
 # Install Node    
RUN apt-get install -y nodejs     
# Install nginx 
RUN apt-get update && apt-get install -y nginx

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
# Install Kafka 
RUN git clone https://github.com/arnaud-lb/php-rdkafka.git\
    && cd php-rdkafka \
    && phpize \
    && ./configure \
    && make all -j 5 \
    && make install 

# Install Rdkafka and enable it
RUN docker-php-ext-enable rdkafka \
     && cd .. \
    && rm -rf /php-rdkafka

# Install PHP extensions zip, mbstring, exif, bcmath, intl
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install  zip mbstring exif pcntl bcmath -j$(nproc) gd intl

# Install Redis and enable it
RUN pecl install redis  && docker-php-ext-enable redis



# Install the php memcached extension
RUN pecl install memcached && docker-php-ext-enable memcached

# Install the PHP pdo_mysql extention
RUN docker-php-ext-install pdo_mysql

# Install the PHP pdo_pgsql extention
RUN docker-php-ext-install pdo_pgsql
# Install PHP Opcache extention
RUN docker-php-ext-install opcache

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR $WORKDIR

RUN rm -Rf /var/www/* && \
mkdir -p /var/www/html

ADD src/index.php $WORKDIR/index.php
ADD src/php.ini $PHP_INI_DIR/conf.d/
ADD src/opcache.ini $PHP_INI_DIR/conf.d/
ADD src/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

COPY src/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN ln -s /usr/local/bin/entrypoint.sh /

RUN rm -rf /etc/nginx/conf.d/default.conf
RUN rm -rf /etc/nginx/sites-enabled/default
RUN rm -rf /etc/nginx/sites-available/default

RUN rm -rf /etc/nginx/nginx.conf

COPY src/nginx.conf /etc/nginx/nginx.conf

RUN usermod -u ${USER_ID} ${USER_NAME}
RUN groupmod -g ${USER_ID} ${GROUP_NAME}

RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/log/nginx
RUN mkdir -p /var/cache/nginx

RUN chown -R ${USER_NAME}:${GROUP_NAME} /var/www && \
  chown -R ${USER_NAME}:${GROUP_NAME} /var/log/ && \
  chown -R ${USER_NAME}:${GROUP_NAME} /etc/supervisor/conf.d/ && \
  chown -R ${USER_NAME}:${GROUP_NAME} $PHP_INI_DIR/conf.d/ && \
  touch /var/run/nginx.pid && \
  chown -R $USER_NAME:$USER_NAME /var/cache/nginx && \
  chown -R $USER_NAME:$USER_NAME /var/lib/nginx/ && \
  chown -R $USER_NAME:$USER_NAME /var/run/nginx.pid && \
  chown -R $USER_NAME:$USER_NAME /var/log/supervisor && \
  chown -R $USER_NAME:$USER_NAME /etc/nginx/nginx.conf && \
  chown -R $USER_NAME:$USER_NAME /etc/nginx/conf.d/ && \
  chown -R ${USER_NAME}:${GROUP_NAME} /tmp


#USER ${USER_NAME}
EXPOSE 80
ENTRYPOINT ["entrypoint.sh"]