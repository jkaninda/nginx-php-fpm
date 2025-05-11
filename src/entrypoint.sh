#!/bin/sh

set -e

echo ""
echo "***********************************************************"
echo " Starting NGINX PHP-FPM Docker Container                   "
echo "***********************************************************"

# Logging functions
info()    { echo "[INFO] $*"; }
warning() { echo "[WARNING] $*"; }
fatal()   { echo "[ERROR] $*" >&2; exit 1; }

ARTISAN_FILE="/var/www/html/artisan"
SUPERVISOR_CONF_DIR="/etc/supervisor/conf.d"
NGINX_CONF_DIR="/etc/nginx/conf.d"
CUSTOM_NGINX_CONF="/var/www/html/conf/nginx"
CUSTOM_SUPERVISOR_CONF="/var/www/html/conf/worker/supervisor.conf"
DOCUMENT_ROOT="/var/www/html/public"

# Laravel Supervisor Setup
setup_laravel_supervisor() {
  info "Artisan file found, creating Laravel supervisor config"
  export DOCUMENT_ROOT

  cat > "$SUPERVISOR_CONF_DIR/laravel-worker.conf" <<EOF
[program:Laravel-scheduler]
process_name=%(program_name)s_%(process_num)02d
command=/bin/sh -c "while true; do (php /var/www/html/artisan schedule:run --verbose --no-interaction &); sleep 60; done"
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

  info "Laravel supervisor config created"
}

# Nginx Config Setup
setup_nginx_config() {
  if [ -f "$CUSTOM_NGINX_CONF/nginx.conf" ]; then
    cp "$CUSTOM_NGINX_CONF/nginx.conf" /etc/nginx/nginx.conf
    info "Using custom nginx.conf"
  fi

  if [ -f "$CUSTOM_NGINX_CONF/nginx-site.conf" ]; then
    info "Custom nginx site config found"
    rm -f "$NGINX_CONF_DIR/default.conf"
    cp "$CUSTOM_NGINX_CONF/nginx-site.conf" "$NGINX_CONF_DIR/default.conf"
    info "Start nginx with custom server config..."
  else
    info "nginx-site.conf not found"
    info "If you want to use custom configs, create it at $CUSTOM_NGINX_CONF/nginx-site.conf"
    info "Start nginx with default config..."

    cat > "$NGINX_CONF_DIR/default.conf" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name $DOMAIN;
    root $DOCUMENT_ROOT;
    index index.php index.html index.htm;

    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;

    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    client_max_body_size $CLIENT_MAX_BODY_SIZE;
    server_tokens off;

    fastcgi_hide_header X-Powered-By;
    fastcgi_hide_header X-CF-Powered-By;
    fastcgi_hide_header X-Runtime;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
        gzip_static on;
    }

    location ~ \.css\$ { add_header Content-Type text/css; }
    location ~ \.js\$ { add_header Content-Type application/x-javascript; }

    location ~ /\.ht { deny all; }
    location ~ /\.(svn|git|hg|bzr)/ { deny all; }
}
EOF
  fi
}

# Load custom supervisor config if exists
load_custom_supervisor_config() {
  if [ -f "$CUSTOM_SUPERVISOR_CONF" ]; then
    info "Custom supervisor config found"
    cp "$CUSTOM_SUPERVISOR_CONF" "$SUPERVISOR_CONF_DIR/supervisor.conf"
  fi
}

# Main Execution
[ -f "$ARTISAN_FILE" ] && setup_laravel_supervisor || info "artisan file not found"

setup_nginx_config
load_custom_supervisor_config

# Start Supervisor
supervisord -c /etc/supervisor/supervisord.conf
