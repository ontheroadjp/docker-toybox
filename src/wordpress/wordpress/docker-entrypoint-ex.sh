#!/bin/bash
set -e

usermod -u ${TOYBOX_WWW_DATA_UID} www-data
groupmod -g ${TOYBOX_WWW_DATA_GID} www-data
chown -R www-data:root /var/run/apache2/
chown -R www-data:www-data /usr/src/wordpress

exec /entrypoint.sh apache2-foreground
