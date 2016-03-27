#!/bin/sh
set -e

root_dir=/var/www/lychee
chown -R www-data:www-data ${root_dir}

if [ -f $root_dir/data/config.php ]; then
    #ip=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' $(docker ps | grep toybox_lychee.docker-toybox.com-lychee_1 | awk '{print $1}'))
    ip=''
    sed -i -e "s/^\$dbHost = '.*\..*\..*\..*'/\$dbHost = '${LYCHEE_MYSQL_PORT_3306_TCP_ADDR}'/g" ${root_dir}/data/config.php
fi

supervisord -c /etc/supervisor/supervisord.conf

exec "$@"

