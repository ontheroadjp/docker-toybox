#!/bin/bash
set -e

if [ ! -e '/var/www/html/version.php' ]; then
	tar cf - --one-file-system -C /usr/src/owncloud . | tar xf -
	chown -R www-data /var/www/html
fi

root_dir="/var/www/html"
chown -R www-data:www-data ${root_dir}

sleep 15
cd ${root_dir}

if [ -f "${root_dir}/config/config.php" ]; then
    sed -i -e "s/'dbhost' => '.*\..*\..*\..*'/'dbhost' => '${MYSQL_PORT_3306_TCP_ADDR}'/g" ${root_dir}/config/config.php
else
    sudo -u www-data php /usr/src/owncloud/occ maintenance:install \
        --database "mysql" \
        --database-host ${MYSQL_PORT_3306_TCP_ADDR}\
        --database-name ${MYSQL_ENV_MYSQL_DATABASE} \
        --database-user ${MYSQL_ENV_MYSQL_USER} \
        --database-pass ${MYSQL_ENV_MYSQL_PASSWORD} \
        --admin-user "toybox" \
        --admin-pass "toybox"

    sudo -u www-data php /usr/src/owncloud/occ config:system:set trusted_domains \
        0 --value ${VIRTUAL_HOST}

    sudo -u www-data php /usr/src/owncloud/occ config:system:set logtimezone \
        --value=${TIMEZONE}

    sudo -u www-data php /usr/src/owncloud/occ config:system:set memcache.local \
        --value="\OC\Memcache\APCu"

    sudo -u www-data php /usr/src/owncloud/occ config:system:set memcache.locking \
        --value="\OC\Memcache\Redis"

    sudo -u www-data php /usr/src/owncloud/occ config:system:set redis \
        'host' --value redis

    sudo -u www-data php /usr/src/owncloud/occ config:system:set redis \
        'port' --value 6379

    #sed -i -e "/  'installed' => true,/a \ \ )," config/config.php
    #sed -i -e "/  'installed' => true,/a \ \ \ \ \ \ 'port' => '6379'," config/config.php
    #sed -i -e "/  'installed' => true,/a \ \ \ \ \ \ 'host' => 'redis'," config/config.php
    #sed -i -e "/  'installed' => true,/a \ \ 'redis' => array ( " config/config.php
    #sed -i -e "/  'installed' => true,/a \ \ 'memcache.locking' => '\\\OC\\\Memcache\\\Redis'," config/config.php
    #sed -i -e "/  'installed' => true,/a \ \ 'memcache.local' => '\\\OC\\\Memcache\\\APCu'," config/config.php

fi

exec "$@"
