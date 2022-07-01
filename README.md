![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/jkaninda/nginx-php-fpm?style=flat-square)
![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/jkaninda/nginx-php-fpm?style=flat-square)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/jkaninda/nginx-php-fpm?style=flat-square)
![Docker Pulls](https://img.shields.io/docker/pulls/jkaninda/nginx-php-fpm?style=flat-square)

# Nginx PHP-FPM Docker image

> 🐳 Docker image for Nginx PHP-FPM container crafted to run Laravel or any php based applications.

- [Docker Hub](https://hub.docker.com/r/jkaninda/nginx-php-fpm)

## Specifications:

* PHP 8.1 / 8.0 / 7.4 / 7.2
* Composer
* OpenSSL PHP Extension
* XML PHP Extension
* PDO PHP Extension
* Rdkafka PHP Extension
* Redis PHP Extension
* Mbstring PHP Extension
* PCNTL PHP Extension
* ZIP PHP Extension
* GD PHP Extension
* BCMath PHP Extension
* Memcached
* Laravel Cron Job
* Laravel Schedule
* Laravel Envoy
* Supervisord

## Simple docker-compose usage:

```yml
version: '3'
services:
    php-fpm:
        image: jkaninda/nginx-php-fpm:latest
        container_name: php-fpm
        restart: unless-stopped      
        volumes:
        #Project root
            - ./:/var/www/html
        ports:
           - "80:80"
        networks:
            - default #if you're using networks between containers

```
## Laravel `artisan` command usage:
### Open php-fpm
```sh
docker-compose exec php-fpm /bin/bash

```

### Laravel migration
```sh
php atisan  migrate

```

## Advanced Nignx-php-fpm:
### docker-compose.yml
```yml
version: '3'
services:
    php-fpm:
        image: jkaninda/nginx-php-fpm
        container_name: php-fpm
        working_dir: /var/www/html #Optional, If you want to use  a custom directory
        restart: unless-stopped 
        ports:
           - "80:80"    
        volumes:
        #Project root
            - ./:/var/www/html
            - ~/.ssh:/root/.ssh # If you use private CVS
            - ./supervisord:/etc/supervisor/conf.d/ # Supervisor directory, if you want to add more supervisor process config file
            - ./php.ini:/usr/local/etc/php/conf.d/php.ini # Optional, your custom php init file
            -  storage-data:/var/www/html/storage/app #Optional, your custom storage data
        environment:
           - APP_ENV=development # Optional, or production
           - WORKDIR=/var/www/html #Optional, If you want to use  a custom directory
           - LARAVEL_PROCS_NUMBER=3 # Optional, Laravel queue:work process number
           - CLIENT_MAX_BODY_SIZE=20M
           - DOMAIN=example.com 
volumes:
 storage-data: 
```

## Docker run
```sh
 docker-compose up -d

```
## Nginx custom config:
### Enable custom nginx config files if they exist
> /var/www/html/conf/nginx/nginx.conf
> /var/www/html/conf/nginx/nginx-site.conf


> P.S. please give a star if you like it :wink:


