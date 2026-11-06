#!/bin/sh
set -e

mkdir -p /var/www/config /var/www/files /var/www/html/public

# Primer arranque: los bind mounts llegan vacios.
if [ ! -e /var/www/config/config.inc.php ]; then
    php /usr/local/lib/ojs/init-config.php \
        /var/www/html/config.TEMPLATE.inc.php /var/www/config/config.inc.php
fi
if [ -z "$(ls -A /var/www/html/public)" ]; then
    cp -a /usr/local/lib/ojs/public-default/. /var/www/html/public/
fi

chown -R www-data:www-data /var/www/config /var/www/files /var/www/html/public
chmod 640 /var/www/config/config.inc.php

exec docker-php-entrypoint "$@"
