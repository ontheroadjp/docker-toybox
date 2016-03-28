#!/bin/bash
set -e

if [ ! -e '/var/www/html/version.php' ]; then
	tar cf - --one-file-system -C /usr/src/owncloud . | tar xf -
	chown -R www-data /var/www/html
fi

root_dir="/var/www/html"
if [ -f "${root_dir}/config/config.php" ]; then
    sed -i -e "s/'dbhost' => '.*\..*\..*\..*'/'dbhost' => '${MYSQL_PORT_3306_TCP_ADDR}'/g" ${root_dir}/config/config.php
fi

exec "$@"
