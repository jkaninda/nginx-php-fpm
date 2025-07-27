### 🐳 **Docker Image: Nginx PHP-FPM**  

A **ready-to-use container** designed for running PHP-based applications, including Laravel microservices. This Docker image combines **Nginx** and **PHP-FPM**, offering a robust foundation for your projects with built-in support for essential extensions and configurations.  

[![Build](https://github.com/jkaninda/nginx-php-fpm/actions/workflows/build.yml/badge.svg)](https://github.com/jkaninda/nginx-php-fpm/actions/workflows/build.yml)
[![Tests](https://github.com/jkaninda/nginx-php-fpm/actions/workflows/tests.yml/badge.svg)](https://github.com/jkaninda/nginx-php-fpm/actions/workflows/tests.yml)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/jkaninda/nginx-php-fpm?style=flat-square)
![Docker Pulls](https://img.shields.io/docker/pulls/jkaninda/nginx-php-fpm?style=flat-square)


#### **Features**  
- **PHP Application Support**: Optimized to run Laravel or any PHP-based applications.  
- **Integrated Extensions**:  
  - **Database**: MySQL and PostgreSQL.  
  - **Caching**: Redis and Memcached.  
  - **Messaging**: Kafka for event-driven architecture.  
  - **Task Scheduling**: Laravel Scheduler and Cron jobs support.  
- **Custom Configuration**: Pre-configured with sensible defaults, allowing seamless customization.  
- **Event Handling**: Support for advanced event-driven processes.  
- **Optimized for Microservices**: Built with modern PHP microservices in mind.  

This image is ideal for developers looking for a streamlined, high-performance solution to deploy PHP applications with essential tools already integrated.

---
## **Links**  
- [Docker Hub](https://hub.docker.com/r/jkaninda/nginx-php-fpm)  
- [GitHub Repository](https://github.com/jkaninda/nginx-php-fpm)  

## **Supported PHP Versions**  
- 8.4  
- 8.3  
- 8.2  
- 8.1  
- 8.0  
- 7.4  
- 7.2  

## **Specifications**  
This Docker image comes pre-installed with the following:  
- **PHP Extensions**:  
  - Composer  
  - OpenSSL  
  - XML  
  - PDO  
  - Rdkafka  
  - Redis  
  - Mbstring  
  - PCNTL  
  - ZIP  
  - GD  
  - BCMath  
  - Memcached  

- **Additional Features**:  
  - Laravel Cron Jobs & Scheduler  
  - Supervisord  
  - Node.js & NPM  

## **Basic Usage with Docker Compose**

### **Example `docker-compose.yml`**
```yaml
services:
  app:
    image: jkaninda/nginx-php-fpm:8.3
    container_name: app
    restart: unless-stopped
    user: www-data # Optional for production
    volumes:
      # Project root
      - ./src:/var/www/html
    ports:
      - "80:80"
    networks:
      - default
```

### **Commands**  

#### Start the service:
```sh
docker compose up -d
```

#### Create a new Laravel project:
```sh
docker compose exec app composer create-project --prefer-dist laravel/laravel .
```

#### Generate application key:
```sh
docker compose exec app php artisan key:generate
```

#### Create a storage symlink:
```sh
docker compose exec app php artisan storage:link
```

#### Fix storage and cache permissions:
```sh
docker compose exec app chmod -R 777 storage bootstrap/cache
```

#### Run Laravel migrations:
```sh
docker compose exec app php artisan migrate
```

#### Access the container shell:
```sh
docker exec -it app bash
```

---

## **Advanced Nginx PHP-FPM Setup**

### **Extended `docker-compose.yml` Example**
```yaml
version: '3'
services:
  app:
    image: jkaninda/nginx-php-fpm
    container_name: app
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      # Project root
      - ./:/var/www/html
      - ~/.ssh:/root/.ssh # Use private CVS if needed
      # Optional custom PHP config
      # - ./php.ini:/usr/local/etc/php/conf.d/php.ini
    environment:
      - APP_ENV=development # or production
      - LARAVEL_PROCS_NUMBER=2 # Optional: Queue worker processes
      # - CLIENT_MAX_BODY_SIZE=20M # Optional
      # - DOMAIN=example.com # Optional
      - DOCUMENT_ROOT=/var/www/html # Optional
```

### **Default Web Root**  
```
/var/www/html
```

---

## **Custom Build Example**

### **Dockerfile**
```Dockerfile
FROM jkaninda/nginx-php-fpm:8.3
# Copy Laravel project files
COPY . /var/www/html
# Storage Volume
VOLUME /var/www/html/storage

WORKDIR /var/www/html

# Fix permissions
RUN chown -R www-data:www-data /var/www/html

USER www-data
```

---

## **Custom Nginx Configuration**

To enable custom Nginx configurations, use the following files:  
- `/var/www/html/conf/nginx/nginx.conf`  
- `/var/www/html/conf/nginx/nginx-site.conf`  

---

## **Supervisord Integration**

Supervisord can be used to manage tasks or processes within the container.  

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

If you encounter storage permission issues, run the following commands:  

```sh
docker compose exec php-fpm /bin/bash
```

Then inside the container:  
```sh
chown -R www-data:www-data /var/www/html/
chmod -R 775 /var/www/html/storage
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


