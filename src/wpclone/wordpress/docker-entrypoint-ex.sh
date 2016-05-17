#!/bin/bash
set -e

usermod -u ${TOYBOX_WWW_DATA_UID} www-data
groupmod -g ${TOYBOX_WWW_DATA_GID} www-data
chown -R www-data:root /var/run/apache2/
chown -R www-data:www-data /usr/src/wordpress

#exe_replace_db="php /var/www/html/Search-Replace-DB/srdb.cli.php -h='mysql' -u='toybox' -p='toybox' -n='toybox_wordpress' -s='dev.ontheroad.jp' -r='wpclone.docker-toybox.com'"
#sed -i -e "$ i ${exe_replace_db}" /entrypoint.sh

exec /entrypoint.sh apache2-foreground
