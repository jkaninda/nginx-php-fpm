#!/bin/sh
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
echo ""
echo "***********************************************************"
echo " Starting LARAVEL NGINX PHP-FPM Docker Container                 "
echo "***********************************************************"

set -e

## Create PHP-FPM worker process
TASK=/etc/supervisor/conf.d/php-fpm.conf
touch $TASK
cat > "$TASK" <<EOF
[supervisord]
nodaemon=true
user=root
[program:php-fpm]
command=/usr/local/sbin/php-fpm
numprocs=1
autostart=true
autorestart=true
stderr_logfile=/var/log/php-fpm_consumer.err.log
stdout_logfile=/var/log/php-fpm_consumer.out.log
user=root
priority=100
EOF
## Check if the artisan file exists
if [ -f $WORKDIR/artisan ]; then
    echo "${Green} artisan file found, creating laravel supervisor config"
    # Set DocumentRoot to the Laravel project directory
    export DOCUMENT_ROOT=$WORKDIR/public
    ##Create Laravel Scheduler process
    TASK=/etc/supervisor/conf.d/laravel-worker.conf
    touch $TASK
    cat > "$TASK" <<EOF
    [supervisord]
    nodaemon=true
    user=root
    [program:Laravel-scheduler]
    process_name=%(program_name)s_%(process_num)02d
    command=/bin/sh -c "while [ true ]; do (php $WORKDIR/artisan schedule:run --verbose --no-interaction &); sleep 60; done"
    autostart=true
    autorestart=true
    numprocs=1
    user=root
    stdout_logfile=/var/log/laravel_scheduler.out.log
    redirect_stderr=true
    
    [program:Laravel-worker]
    process_name=%(program_name)s_%(process_num)02d
    command=php $WORKDIR/artisan queue:work --sleep=3 --tries=3
    autostart=true
    autorestart=true
    numprocs=$LARAVEL_PROCS_NUMBER
    user=root
    redirect_stderr=true
    stdout_logfile=/var/log/laravel_worker.log
EOF
echo  "${Green} Laravel supervisor config created"
else
    echo  "${Red} artisan file not found"
fi
#check if storage directory exists
echo "Checking if storage directory exists"
    if [ -d "$STORAGE_DIR" ]; then
        echo "Directory $STORAGE_DIR  exist. Fixing permissions..."
        chown -R www-data:www-data $STORAGE_DIR
        chmod -R 775 $STORAGE_DIR
        echo  "${Green}Permissions fixed"

    else
        echo "${Red} Directory $STORAGE_DIR does not exist"
    fi

# Enable custom nginx config files if they exist
if [ -f /var/www/html/conf/nginx/nginx.conf ]; then
  cp /var/www/html/conf/nginx/nginx.conf /etc/nginx/nginx.conf
  echo "Using custom nginx.conf"
fi

if [ -f /var/www/html/conf/nginx/nginx-site.conf ]; then
  echo "Custom nginx site config found"
  rm /etc/nginx/sites-enabled/default
  cp /var/www/html/conf/nginx/nginx-site.conf /etc/nginx/sites-enabled/default
  else
  echo "${Red} nginx-site.conf not found"
  echo "${Green} If you want to use custom configs, create config file in /var/www/html/conf/nginx/nginx-site.conf"
  echo "${Green} Start nginx with default config..."
   rm -f /etc/nginx/sites-enabled/default
   TASK=/etc/nginx/sites-enabled/default
   touch $TASK
   cat > "$TASK"  <<EOF
   server {
    listen 80 default_server;
    listen [::]:80 default_server;  
    server_name $DOMAIN;
    # Add index.php to setup Nginx, PHP & PHP-FPM config
    index index.php index.html index.htm index.nginx-debian.html;    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root $DOCUMENT_ROOT;
    # pass PHP scripts on Nginx to FastCGI (PHP-FPM) server
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        # Nginx php-fpm config:
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        
    }
    client_max_body_size $CLIENT_MAX_BODY_SIZE;
    server_tokens off;

     # Hide PHP headers 
    fastcgi_hide_header X-Powered-By; 
    fastcgi_hide_header X-CF-Powered-By;
    fastcgi_hide_header X-Runtime;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        gzip_static on;
    }
  # deny access to Apache .htaccess on Nginx with PHP, 
  # if Apache and Nginx document roots concur
  location ~ /\.ht {
    deny all;
  }
  location ~ .*\.(?!htaccess).* {
    deny all;
  }
}
EOF


fi

TASK=/etc/supervisor/conf.d/nginx.conf
touch $TASK
cat > "$TASK" <<EOF
[supervisord]
nodaemon=true
user=root
[program:ginx]
command=/usr/sbin/nginx -g "daemon off;"
numprocs=1
autostart=true
autorestart=true
stderr_logfile=/var/log/ngnix.err.log
stdout_logfile=/var/log/ngnix.out.log
EOF

echo ""
echo "**********************************"
echo "     Starting Supervisord...     "
echo "***********************************"
supervisord -c /etc/supervisor/supervisord.conf

