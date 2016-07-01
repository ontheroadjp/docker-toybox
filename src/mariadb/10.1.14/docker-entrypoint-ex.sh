#!/bin/bash

usermod -u ${TOYBOX_UID} mysql
groupmod -g ${TOYBOX_GID} mysql

exec /docker-entrypoint.sh mysqld --user=mysql --console
