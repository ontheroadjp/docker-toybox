#!/bin/sh
set -e

usermod -u ${TOYBOX_UID} www-data
groupmod -g ${TOYBOX_GID} www-data

docroot=/var/www/html

config="${docroot}/data/config.php"

if [ -f ${config} ]; then
    rm -rf ${config}
fi

echo "<?php" >> ${config}
echo "" >> ${config}
echo "// Database configuration" >> ${config}
echo '$dbHost = '"'${MARIADB_PORT_3306_TCP_ADDR}'; // Host of the database" >> ${config}
echo '$dbUser = '"'${MARIADB_ENV_MYSQL_USER}'; // Username of the database" >> ${config}
echo '$dbPassword = '"'${MARIADB_ENV_MYSQL_PASSWORD}'; // Password of the database" >> ${config}
echo '$dbName = '"'${MARIADB_ENV_MYSQL_DATABASE}'; // Database name" >> ${config}
echo '$dbTablePrefix = '"''; // Table prefix" >> ${config}
echo "" >> ${config}
echo "?>" >> ${config}

chown -R www-data:www-data ${docroot}

exec "$@"
