#!/bin/bash
set -e

usermod -u ${TOYBOX_UID} mysql
groupmod -g ${TOYBOX_GID} mysql
chown -R mysql:root /var/run/mysqld

exec /docker-entrypoint.sh mysqld --user=mysql --console
