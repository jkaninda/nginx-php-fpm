#!/bin/sh

echo ""
echo "***********************************************************"
echo " Starting NGINX PHP-FPM Docker Container                   "
echo "***********************************************************"

set -e
set -e
info() {
    { set +x; } 2> /dev/null
    echo '[INFO] ' "$@"
}
warning() {
    { set +x; } 2> /dev/null
    echo '[WARNING] ' "$@"
}
fatal() {
    { set +x; } 2> /dev/null
    echo '[ERROR] ' "$@" >&2
    exit 1
}
## Check if the artisan file exists
if [ -f /var/www/html/artisan ]; then
    info "Artisan file found, creating laravel supervisor config"
    # Set DocumentRoot to the Laravel project directory
    export DOCUMENT_ROOT=/var/www/html/public
    ##Create Laravel Scheduler process
    TASK=/etc/supervisor/conf.d/laravel-worker.conf
    touch $TASK
    cat > "$TASK" <<EOF
    [program:Laravel-scheduler]
    process_name=%(program_name)s_%(process_num)02d
    command=/bin/sh -c "while [ true ]; do (php /var/www/html/artisan schedule:run --verbose --no-interaction &); sleep 60; done"
    autostart=true
    autorestart=true
    numprocs=1
    user=$USER_NAME
    stdout_logfile=/var/log/laravel_scheduler.out.log
    redirect_stderr=true
    
    [program:Laravel-worker]
    process_name=%(program_name)s_%(process_num)02d
    command=php /var/www/html/artisan queue:work --sleep=3 --tries=3
    autostart=true
    autorestart=true
    numprocs=$LARAVEL_PROCS_NUMBER
    user=$USER_NAME
    redirect_stderr=true
    stdout_logfile=/var/log/laravel_worker.log
EOF
  info  "Laravel supervisor config created"
else
    info  "artisan file not found"
fi

# Enable custom nginx config files if they exist
if [ -f /var/www/html/conf/nginx/nginx.conf ]; then
  cp /var/www/html/conf/nginx/nginx.conf /etc/nginx/nginx.conf
  info "Using custom nginx.conf"
fi

if [ -f /var/www/html/conf/nginx/nginx-site.conf ]; then
  info "Custom nginx site config found"
  rm /etc/nginx/conf.d/default.conf
  cp /var/www/html/conf/nginx/nginx-site.conf /etc/nginx/conf.d/default.conf
  info "Start nginx with custom server config..."
  else
  info "nginx-site.conf not found"
  info "If you want to use custom configs, create config file in /var/www/html/conf/nginx/nginx-site.conf"
  info "Start nginx with default config..."
   rm -f /etc/nginx/conf.d/default.conf
   TASK=/etc/nginx/conf.d/default.conf
   touch $TASK
   cat > "$TASK"  <<EOF
   server {
    listen 80 default_server;
    listen [::]:80 default_server;  
    server_name $DOMAIN;
    # Add index.php to setup Nginx, PHP & PHP-FPM config
    index index.php index.html index.htm index.nginx-debian.html;
    error_log  /var/log/nginx/error.log;
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
        try_files \$uri \$uri/ /index.php\$is_args\$args;
        gzip_static on;
    }
    location ~ \.css {
    add_header  Content-Type    text/css;
    }
    location ~ \.js {
    add_header  Content-Type    application/x-javascript;
    }
  # deny access to Apache .htaccess on Nginx with PHP, 
  # if Apache and Nginx document roots concur
  location ~ /\.ht    {deny all;}
	location ~ /\.svn/  {deny all;}
	location ~ /\.git/  {deny all;}
	location ~ /\.hg/   {deny all;}
	location ~ /\.bzr/  {deny all;}
}
EOF
fi
## Check if the supervisor config file exists
if [ -f /var/www/html/conf/worker/supervisor.conf ]; then
    info "Custom supervisor config found"
    cp /var/www/html/conf/worker/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
fi
## Start Supervisord
supervisord -c /etc/supervisor/supervisord.conf

