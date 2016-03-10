#!/bin/sh
set -e

root_dir=/var/www/lychee
chown -R www-data:www-data ${root_dir}

if [ -f $root_dir/data/config.php ]; then
    sed -i -e "s/^\$dbHost = '.*\..*\..*\..*'/\$dbHost = '${LYCHEE_DB_1_PORT_3306_TCP_ADDR}'/g" ${root_dir}/data/config.php
fi

exec "$@"
