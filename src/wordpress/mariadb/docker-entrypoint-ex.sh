#!/bin/bash
set -e

usermod -u ${TOYBOX_MYSQL_UID} mysql
groupmod -g ${TOYBOX_MYSQL_GID} mysql
chown -R mysql:root /var/run/mysqld

exec /docker-entrypoint.sh mysqld --user=mysql --console
