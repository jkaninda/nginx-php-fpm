### 🐳 **Docker Image: Nginx PHP-FPM**  

A **ready-to-use container** designed for running PHP-based applications, including Laravel microservices. This Docker image combines **Nginx** and **PHP-FPM**, offering a robust foundation for your projects with built-in support for essential extensions and configurations.  

[![Build](https://github.com/jkaninda/nginx-php-fpm/actions/workflows/build.yml/badge.svg)](https://github.com/jkaninda/nginx-php-fpm/actions/workflows/build.yml)
[![Tests](https://github.com/jkaninda/nginx-php-fpm/actions/workflows/tests.yml/badge.svg)](https://github.com/jkaninda/nginx-php-fpm/actions/workflows/tests.yml)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/jkaninda/nginx-php-fpm?style=flat-square)
![Docker Pulls](https://img.shields.io/docker/pulls/jkaninda/nginx-php-fpm?style=flat-square)


#### **Features**  
- **PHP Application Support**: Optimized to run Laravel or any PHP-based applications.  
- **Nginx and PHP-FPM in one container**, managed by Supervisord.  
- **Integrated Extensions**:  
  - **Database**: MySQL and PostgreSQL.  
  - **Caching**: Redis and Memcached.  
  - **Messaging**: Kafka for event-driven architecture.  
  - **Task Scheduling**: Laravel Scheduler and Queue Worker started automatically.  
- **Custom Configuration**: Pre-configured with sensible defaults, tunable through environment variables.  
- **Debian and Alpine variants**, multi-arch (`linux/amd64`, `linux/arm64`).  
- **Production-ready**: healthcheck, graceful shutdown, OPcache, logs on stdout, `supervisorctl` support.  
- **Optimized for Microservices**: Built with modern PHP microservices in mind.  

This image is ideal for developers looking for a streamlined, high-performance solution to deploy PHP applications with essential tools already integrated.

---
## **Links**  
- [Docker Hub](https://hub.docker.com/r/jkaninda/nginx-php-fpm)  
- [GitHub Repository](https://github.com/jkaninda/nginx-php-fpm)  

## **Supported PHP Versions & Tags**

| PHP | Debian tag | Alpine tag |
|-----|------------|------------|
| 8.5 | `8.5`, `latest` | `8.5-alpine`, `alpine` |
| 8.4 | `8.4` | `8.4-alpine` |
| 8.3 | `8.3` | `8.3-alpine` |
| 8.2 | `8.2` | `8.2-alpine` |

Legacy images (PHP is end-of-life, no longer rebuilt automatically or tested): `8.1`, `8.1-alpine`, `8.0`, `7.4`, `7.3`, `7.2`.

---

## **Specifications**

### **PHP Extensions**
- Composer 2  
- OpenSSL  
- XML  
- PDO (MySQL, PostgreSQL and SQLite)  
- Rdkafka  
- Redis  
- Mbstring  
- Intl  
- Exif  
- PCNTL  
- ZIP  
- GD (FreeType, JPEG, PNG, WebP)  
- BCMath  
- Memcached  
- Opcache  

### **Additional Features**
- Nginx  
- Laravel Scheduler  
- Laravel Queue Worker  
- Supervisord  
- Node.js 24 LTS and NPM  
- Git, Zip/Unzip, SQLite CLI  

---

## **Basic Usage with Docker Compose**

### **Example `docker-compose.yml`**
```yaml
services:
  app:
    image: jkaninda/nginx-php-fpm:8.5
    container_name: app
    restart: unless-stopped
    volumes:
      # Project root
      - ./src:/var/www/html
    ports:
      - "80:80"
```

### **Commands**  

#### Start the service:
```sh
docker compose up -d
```

#### Create a new Laravel project:
```sh
docker compose exec -u www-data app composer create-project --prefer-dist laravel/laravel .
```

#### Generate application key:
```sh
docker compose exec -u www-data app php artisan key:generate
```

#### Create a storage symlink:
```sh
docker compose exec -u www-data app php artisan storage:link
```

#### Fix storage and cache permissions:
```sh
docker compose exec app chown -R www-data:www-data storage bootstrap/cache
```

#### Run Laravel migrations:
```sh
docker compose exec -u www-data app php artisan migrate
```

#### Access the container shell:
```sh
docker exec -it app bash
```

#### Run a one-off command (Nginx and PHP-FPM are not started):
```sh
docker run --rm -v "$PWD:/var/www/html" jkaninda/nginx-php-fpm composer install
```

#### Restart the queue workers after a deployment:
```sh
docker compose exec app supervisorctl restart Laravel-worker:*
```

---

## **Environment Variables**

### Nginx

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCUMENT_ROOT` | `$APP_DIR/public` if it exists, otherwise `$APP_DIR` | Nginx web root |
| `DOMAIN` | `_` | Nginx `server_name` |
| `CLIENT_MAX_BODY_SIZE` | `15M` | Nginx `client_max_body_size` |

### Laravel

| Variable | Default | Description |
|----------|---------|-------------|
| `LARAVEL_SCHEDULER_ENABLED` | `true` | Run `php artisan schedule:run` every minute |
| `LARAVEL_QUEUE_WORKER_ENABLED` | `true` | Run `php artisan queue:work` |
| `LARAVEL_QUEUE_OPTIONS` | `--sleep=3 --tries=3` | Options passed to `queue:work` (e.g. `redis --queue=high,default`) |
| `LARAVEL_PROCS_NUMBER` | `1` | Number of queue worker processes |
| `APP_DIR` | `/var/www/html` | Application directory (where `artisan` is looked up) |

The scheduler and queue worker are only started when an `artisan` file is found in `APP_DIR`.

### PHP

| Variable | Default |
|----------|---------|
| `PHP_MEMORY_LIMIT` | `256M` |
| `PHP_UPLOAD_MAX_FILESIZE` | `80M` |
| `PHP_POST_MAX_SIZE` | `80M` |
| `PHP_MAX_EXECUTION_TIME` | `30` |
| `PHP_DATE_TIMEZONE` | `UTC` |
| `PHP_DISPLAY_ERRORS` | `Off` |

### OPcache

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_OPCACHE_ENABLE` | `1` | |
| `PHP_OPCACHE_ENABLE_CLI` | `0` | |
| `PHP_OPCACHE_MEMORY_CONSUMPTION` | `512` | MB |
| `PHP_OPCACHE_MAX_ACCELERATED_FILES` | `50000` | |
| `PHP_OPCACHE_VALIDATE_TIMESTAMPS` | `0` | Set to `1` in development so code changes are picked up |
| `PHP_OPCACHE_REVALIDATE_FREQ` | `0` | |

### PHP-FPM

| Variable | Default |
|----------|---------|
| `PHP_FPM_PM` | `dynamic` |
| `PHP_FPM_PM_MAX_CHILDREN` | `20` |
| `PHP_FPM_PM_START_SERVERS` | `2` |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | `1` |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | `3` |
| `PHP_FPM_PM_MAX_REQUESTS` | `500` |

Container environment variables (e.g. `DB_HOST`, `APP_KEY`) are passed to PHP-FPM workers (`clear_env = no`).

### Development example

```yaml
services:
  app:
    image: jkaninda/nginx-php-fpm:8.5
    ports:
      - "80:80"
    environment:
      PHP_OPCACHE_VALIDATE_TIMESTAMPS: 1
      PHP_DISPLAY_ERRORS: "On"
      CLIENT_MAX_BODY_SIZE: 20M
      LARAVEL_QUEUE_OPTIONS: "redis --sleep=3 --tries=3"
      LARAVEL_PROCS_NUMBER: 2
    volumes:
      - ./:/var/www/html
```

---

## **Custom Build Example**

### **Dockerfile**
```Dockerfile
FROM jkaninda/nginx-php-fpm:8.5
# Copy Laravel project files
COPY . /var/www/html
# Storage Volume
VOLUME /var/www/html/storage

WORKDIR /var/www/html

# Fix permissions
RUN chown -R www-data:www-data /var/www/html
```

---

## **Custom Nginx Configuration**

To use custom Nginx configurations, add the following files to your project:  
- `conf/nginx/nginx.conf`: replaces `/etc/nginx/nginx.conf`  
- `conf/nginx/nginx-site.conf`: replaces the generated server block. PHP-FPM listens on `127.0.0.1:9000`.  

---

## **Custom PHP Configuration**

Most common settings can be changed with [environment variables](#environment-variables).
For anything else, either:

- mount or copy your own `.ini` file into `/usr/local/etc/php/conf.d/`, or
- place a `php.ini` file at `conf/php/php.ini` in your project; it is copied into `conf.d` at startup.

---

## **Supervisord Integration**

Supervisord can be used to manage tasks or processes within the container.  
Place your programs in `conf/worker/supervisor.conf` in your project, or mount them into `/etc/supervisor/conf.d/`.

### **Example Configuration for Kafka Consumer**
```conf
[program:kafkaconsume-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan kafka:consumer
autostart=true
autorestart=true
numprocs=1
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/kafka.log
```

---

## **Fixing Storage Permissions**  

`www-data` has UID/GID `1000` in both Debian and Alpine variants. If you encounter permission issues, run:  

```sh
docker compose exec app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
docker compose exec app chmod -R 775 /var/www/html/storage
```

To match your host user, rebuild with `--build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)`.

---

## **Building & Testing Locally**

```sh
make build-8.5          # Debian image
make build-8.5-alpine   # Alpine image
make test               # Integration test (Laravel + MySQL)
```

---

### Explore Another Project: Goma Gateway

Are you building a microservices architecture?
Do you need a powerful yet lightweight API Gateway or a high-performance reverse proxy to secure and manage your services effortlessly?

Check out my other project — **[Goma Gateway](https://github.com/jkaninda/goma-gateway)**.

**Goma Gateway** is a high-performance, declarative API Gateway built for modern microservices. It comes with a rich set of built-in middleware, including:

* Basic, JWT, OAuth2, LDAP, and ForwardAuth authentication
* Caching and rate limiting
* Bot detection
* Built-in load balancing
* Simple configuration with minimal overhead
* ...and more!

**Protocol support:** REST, GraphQL, gRPC, TCP, and UDP

**Security:** Automatic HTTPS via Let’s Encrypt or use your own TLS certificates

Whether you're managing internal APIs or exposing public endpoints, **Goma Gateway** helps you do it efficiently, securely, and with minimal complexity.

---

## ⭐️ **Support the Project**  
If this project helped you, do not skip on giving it a star. Thanks!
