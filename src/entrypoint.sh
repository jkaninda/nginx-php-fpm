#!/bin/sh

set -e

# Logging functions
log() {
    level=$1
    shift
    echo "[$level] $*"
}

info() {
    log "INFO" "$@"
}

warning() {
    log "WARNING" "$@"
}

fatal() {
    log "ERROR" "$@" >&2
    exit 1
}

is_true() {
    case "$1" in
        1|true|TRUE|True|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

APP_DIR="${APP_DIR:-/var/www/html}"
USER_NAME="${USER_NAME:-www-data}"
DOMAIN="${DOMAIN:-_}"
CLIENT_MAX_BODY_SIZE="${CLIENT_MAX_BODY_SIZE:-15M}"
LARAVEL_PROCS_NUMBER="${LARAVEL_PROCS_NUMBER:-1}"
LARAVEL_QUEUE_OPTIONS="${LARAVEL_QUEUE_OPTIONS:---sleep=3 --tries=3}"

# Default to the Laravel public directory when it exists
if [ -z "$DOCUMENT_ROOT" ]; then
    if [ -d "$APP_DIR/public" ]; then
        DOCUMENT_ROOT="$APP_DIR/public"
    else
        DOCUMENT_ROOT="$APP_DIR"
    fi
fi

NGINX_CONF_DIR="/etc/nginx/conf.d"
CUSTOM_NGINX_CONF="$APP_DIR/conf/nginx"
CUSTOM_SUPERVISOR_CONF="$APP_DIR/conf/worker/supervisor.conf"
SUPERVISOR_CONF_DIR="/etc/supervisor/conf.d"

# Check if custom php.ini file exists
PHP_INI_SOURCE="$APP_DIR/conf/php/php.ini"
PHP_INI_TARGET="$PHP_INI_DIR/conf.d/php.ini"

if [ -f "$PHP_INI_SOURCE" ]; then
    cp "$PHP_INI_SOURCE" "$PHP_INI_TARGET"
    info "Custom php.ini file found and copied to $PHP_INI_TARGET"
fi

# Run any other command (e.g. "php artisan migrate", "composer install", "bash")
if [ $# -gt 0 ] && [ "$1" != "entrypoint" ] && [ "$1" != "supervisord" ]; then
    exec "$@"
fi

# Banner
echo ""
echo "***********************************************************"
echo "   Starting NGINX PHP-FPM Container                        "
echo "***********************************************************"

# Nginx configuration
if [ -f "$CUSTOM_NGINX_CONF/nginx.conf" ]; then
    cp "$CUSTOM_NGINX_CONF/nginx.conf" /etc/nginx/nginx.conf
    info "Using custom nginx.conf"
fi

if [ -f "$CUSTOM_NGINX_CONF/nginx-site.conf" ]; then
    cp "$CUSTOM_NGINX_CONF/nginx-site.conf" "$NGINX_CONF_DIR/default.conf"
    info "Using custom nginx site config $CUSTOM_NGINX_CONF/nginx-site.conf"
else
    cat > "$NGINX_CONF_DIR/default.conf" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name $DOMAIN;
    root $DOCUMENT_ROOT;
    index index.php index.html index.htm;

    access_log /dev/stdout;
    error_log  /dev/stderr warn;

    client_max_body_size $CLIENT_MAX_BODY_SIZE;
    server_tokens off;

    fastcgi_hide_header X-Powered-By;
    fastcgi_hide_header X-CF-Powered-By;
    fastcgi_hide_header X-Runtime;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
        gzip_static on;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location ~ /\.(ht|svn|git|hg|bzr) { deny all; }
}
EOF
    info "Nginx serving $DOCUMENT_ROOT (server_name $DOMAIN)"
    info "To use a custom config, create $CUSTOM_NGINX_CONF/nginx-site.conf"
fi

# Check if the artisan file exists
ARTISAN_PATH="$APP_DIR/artisan"
SUPERVISOR_TASK="$SUPERVISOR_CONF_DIR/laravel-worker.conf"
if [ -f "$ARTISAN_PATH" ]; then
    info "Artisan file found, creating Laravel supervisor config..."
    : > "$SUPERVISOR_TASK"

    if is_true "${LARAVEL_SCHEDULER_ENABLED:-true}"; then
        cat >> "$SUPERVISOR_TASK" <<EOF
[program:Laravel-scheduler]
process_name=%(program_name)s_%(process_num)02d
command=/bin/sh -c "while true; do php $ARTISAN_PATH schedule:run --verbose --no-interaction & sleep 60; done"
autostart=true
autorestart=true
numprocs=1
user=$USER_NAME
stdout_logfile=/var/log/laravel_scheduler.out.log
redirect_stderr=true

EOF
        info "Laravel scheduler enabled"
    fi

    if is_true "${LARAVEL_QUEUE_WORKER_ENABLED:-true}"; then
        cat >> "$SUPERVISOR_TASK" <<EOF
[program:Laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php $ARTISAN_PATH queue:work $LARAVEL_QUEUE_OPTIONS
autostart=true
autorestart=true
; Keep retrying while the database/queue backend is not ready yet
startretries=20
stopwaitsecs=3600
numprocs=$LARAVEL_PROCS_NUMBER
user=$USER_NAME
redirect_stderr=true
stdout_logfile=/var/log/laravel_worker.log
EOF
        info "Laravel queue worker enabled ($LARAVEL_PROCS_NUMBER process(es))"
    fi

    info "Laravel supervisor config created at $SUPERVISOR_TASK"
else
    rm -f "$SUPERVISOR_TASK" 2>/dev/null || true
    info "Artisan file not found at $ARTISAN_PATH"
fi

# Custom supervisor programs
if [ -f "$CUSTOM_SUPERVISOR_CONF" ]; then
    cp "$CUSTOM_SUPERVISOR_CONF" "$SUPERVISOR_CONF_DIR/supervisor.conf"
    info "Custom supervisor config found and copied"
fi

# Start Supervisor (programs drop privileges to $USER_NAME themselves)
if [ "$(id -u)" = "0" ]; then
    exec supervisord -c /etc/supervisor/supervisord.conf -u root
fi
exec supervisord -c /etc/supervisor/supervisord.conf
